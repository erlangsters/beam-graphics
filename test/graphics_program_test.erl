%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_program_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(VERTEX_SHADER, """
#version 460 core
layout(location = 0) in vec3 aPos;
void main() {
    gl_Position = vec4(aPos, 1.0);
}
""").

-define(FRAGMENT_SHADER, """
#version 460 core
out vec4 FragColor;
void main() {
    FragColor = vec4(1.0);
}
""").

-define(INVALID_VERTEX_SHADER, """
#version 460 core
layout(location = 0) in vec3 aPos
void main() {
    gl_Position = vec4(aPos, 1.0);
}
""").

-define(INVALID_FRAGMENT_SHADER, """
#version 460 core
out vec4 FragColor
void main() {
    FragColor = vec4(1.0);
}
""").

-define(LINK_VERTEX_SHADER, """
#version 460 core
layout(location = 0) in vec3 aPos;
out vec4 vColor;
void main() {
    gl_Position = vec4(aPos, 1.0);
    vColor = vec4(1.0);
}
""").

-define(LINK_FRAGMENT_SHADER, """
#version 460 core
in vec3 vColor;
out vec4 FragColor;
void main() {
    FragColor = vec4(vColor, 1.0);
}
""").

-define(UNIFORM_VERTEX_SHADER, """
#version 460 core
layout(location = 0) in vec3 aPos;
uniform bool uBool;
uniform int uInt;
uniform float uFloat;
uniform vec2 uVector2;
uniform vec3 uVector3;
uniform vec4 uVector4;
uniform mat3 uMatrix3;
uniform mat4 uMatrix4;
uniform sampler2D uSampler;
void main() {
    vec4 extra = vec4(float(uBool), float(uInt), uFloat, 1.0);
    extra.xy += uVector2;
    extra.xyz += uVector3;
    extra += uVector4;
    extra.xyz += uMatrix3 * vec3(1.0);
    extra.x += float(texture(uSampler, vec2(0.0)).r);
    gl_Position = uMatrix4 * vec4(aPos, 1.0) + extra;
}
""").

-define(UNIFORM_FRAGMENT_SHADER, """
#version 460 core
out vec4 FragColor;
void main() {
    FragColor = vec4(1.0);
}
""").

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

program_test() ->
    ok = run_graphics(),

    {ok, Program} = graphics_program:with_shaders(?VERTEX_SHADER, ?FRAGMENT_SHADER),
    [] = graphics_program:uniforms(Program),
    false = graphics_program:has_uniform(Program, "uModel"),
    GlProgram = graphics_program:gl_object(Program),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_program(GlProgram)
    end),

    ok = graphics_program:destroy(Program),
    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_program(GlProgram)
    end),

    ok.

program_with_shaders_test() ->
    ok = run_graphics(),

    {ok, Program} = graphics_program:with_shaders(?VERTEX_SHADER, ?FRAGMENT_SHADER),
    [] = graphics_program:uniforms(Program),
    ok = graphics_program:destroy(Program),

    {compile_error, vertex, VertexLog} =
        graphics_program:with_shaders(?INVALID_VERTEX_SHADER, ?FRAGMENT_SHADER),
    true = is_list(VertexLog),
    true = length(VertexLog) > 0,

    {compile_error, fragment, FragmentLog} =
        graphics_program:with_shaders(?VERTEX_SHADER, ?INVALID_FRAGMENT_SHADER),
    true = is_list(FragmentLog),
    true = length(FragmentLog) > 0,

    {link_error, LinkLog} =
        graphics_program:with_shaders(?LINK_VERTEX_SHADER, ?LINK_FRAGMENT_SHADER),
    true = is_list(LinkLog),
    true = length(LinkLog) > 0,

    ok.

program_uniforms_test() ->
    ok = run_graphics(),

    {ok, Program} = graphics_program:with_shaders(
        ?UNIFORM_VERTEX_SHADER, ?UNIFORM_FRAGMENT_SHADER
    ),
    [
        {"uBool", bool},
        {"uFloat", float},
        {"uInt", int},
        {"uMatrix3", matrix3},
        {"uMatrix4", matrix4},
        {"uSampler", sampler2d},
        {"uVector2", vector2},
        {"uVector3", vector3},
        {"uVector4", vector4}
    ] = graphics_program:uniforms(Program),

    true = graphics_program:has_uniform(Program, "uFloat"),
    true = graphics_program:has_uniform(Program, "uSampler"),
    false = graphics_program:has_uniform(Program, "uMissing"),
    false = graphics_program:has_uniform(Program, "uDoesNotExist"),

    ok = graphics_program:destroy(Program),

    ok.

program_set_uniform_test() ->
    ok = run_graphics(),

    {ok, Program} = graphics_program:with_shaders(
        ?UNIFORM_VERTEX_SHADER, ?UNIFORM_FRAGMENT_SHADER
    ),
    GlProgram = graphics_program:gl_object(Program),

    no_uniform = graphics_program:set_uniform(Program, "uMissing", 1.0),

    ok = graphics_program:set_uniform(Program, "uBool", true),
    ok = graphics_program:set_uniform(Program, "uInt", 7),
    ok = graphics_program:set_uniform(Program, "uFloat", 0.5),
    ok = graphics_program:set_uniform(Program, "uVector2", {1.0, 2.0}),
    ok = graphics_program:set_uniform(Program, "uVector3", {1.0, 2.0, 3.0}),
    ok = graphics_program:set_uniform(Program, "uVector4", {1.0, 2.0, 3.0, 4.0}),
    ok = graphics_program:set_uniform(Program, "uMatrix3", ?MATRIX3_IDENTITY),
    ok = graphics_program:set_uniform(Program, "uMatrix4", ?MATRIX4_IDENTITY),
    ok = graphics_program:set_uniform(Program, "uSampler", 3),

    {ok, [1]} = read_uniform(i, GlProgram, "uBool", 1),
    {ok, [7]} = read_uniform(i, GlProgram, "uInt", 1),
    {ok, [0.5]} = read_uniform(f, GlProgram, "uFloat", 1),
    {ok, [1.0, 2.0]} = read_uniform(f, GlProgram, "uVector2", 2),
    {ok, [1.0, 2.0, 3.0]} = read_uniform(f, GlProgram, "uVector3", 3),
    {ok, [1.0, 2.0, 3.0, 4.0]} = read_uniform(f, GlProgram, "uVector4", 4),
    {ok, Matrix3} = read_uniform(f, GlProgram, "uMatrix3", 9),
    true = Matrix3 == [
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
    ],
    {ok, Matrix4} = read_uniform(f, GlProgram, "uMatrix4", 16),
    true = Matrix4 == [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    ],
    {ok, [3]} = read_uniform(i, GlProgram, "uSampler", 1),

    ok = graphics_program:set_uniform(Program, "uBool", false),
    {ok, [0]} = read_uniform(i, GlProgram, "uBool", 1),

    type_mismatch = graphics_program:set_uniform(Program, "uFloat", 1),
    type_mismatch = graphics_program:set_uniform(Program, "uFloat", ?MATRIX4_IDENTITY),
    type_mismatch = graphics_program:set_uniform(Program, "uBool", 1),
    type_mismatch = graphics_program:set_uniform(Program, "uSampler", 1.0),
    type_mismatch = graphics_program:set_uniform(Program, "uVector2", {1.0, 2.0, 3.0}),
    type_mismatch = graphics_program:set_uniform(Program, "uMatrix3", ?MATRIX4_IDENTITY),

    ?assertError(
        function_clause,
        graphics_program:set_uniform(Program, "uFloat", {1, 2})
    ),
    ?assertError(
        function_clause,
        graphics_program:set_uniform(Program, "uFloat", not_a_value)
    ),

    ok = graphics_program:destroy(Program),

    ok.

program_binary_test() ->
    ok = run_graphics(),

    {ok, Program1} = graphics_program:with_shaders(?VERTEX_SHADER, ?FRAGMENT_SHADER),
    case graphics_program:binary(Program1) of
        no_binary ->
            ok = graphics_program:destroy(Program1);
        {Format, Data} ->
            true = is_integer(Format),
            true = byte_size(Data) > 0,
            {ok, Program2} = graphics_program:with_binary({Format, Data}),
            [] = graphics_program:uniforms(Program2),
            GlProgram2 = graphics_program:gl_object(Program2),
            {ok, true} = graphics_context:execute_commands(fun() ->
                gl:is_program(GlProgram2)
            end),
            ok = graphics_program:destroy(Program2),
            ok = graphics_program:destroy(Program1)
    end,

    {link_error, Log} = graphics_program:with_binary({0, <<"not-a-program">>}),
    true = is_list(Log),
    ?assertError(function_clause, graphics_program:with_binary(<<>>)),

    ok.

program_binary_uniforms_test() ->
    ok = run_graphics(),

    {ok, Program1} = graphics_program:with_shaders(
        ?UNIFORM_VERTEX_SHADER, ?UNIFORM_FRAGMENT_SHADER
    ),
    case graphics_program:binary(Program1) of
        no_binary ->
            ok = graphics_program:destroy(Program1);
        Payload ->
            {ok, Program2} = graphics_program:with_binary(Payload),
            Uniforms1 = graphics_program:uniforms(Program1),
            Uniforms2 = graphics_program:uniforms(Program2),
            Uniforms1 = Uniforms2,
            ok = graphics_program:set_uniform(Program2, "uFloat", 0.25),
            GlProgram2 = graphics_program:gl_object(Program2),
            {ok, [0.25]} = read_uniform(f, GlProgram2, "uFloat", 1),
            ok = graphics_program:destroy(Program2),
            ok = graphics_program:destroy(Program1)
    end,

    ok.

read_uniform(Type, GlProgram, Name, Count) ->
    graphics_context:execute_commands(fun() ->
        {ok, Location} = gl:get_uniform_location(GlProgram, Name),
        gl:get_uniform(Type, GlProgram, Location, Count)
    end).
