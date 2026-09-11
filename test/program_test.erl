%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(program_test).
-include_lib("eunit/include/eunit.hrl").

-define(VERTEX_SHADER, """
#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aColor;

uniform mat4 uProjection;

out vec4 vColor;

void main() {
    vec4 scenePos = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = uProjection * scenePos;
    vColor = aColor / 255.0;
}
""").

-define(INVALID_VERTEX_SHADER, """
#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aColor

uniform mat4 uProjection;

out vec4vColor;

void main() {
    vec4 scenePos = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = uProjection * scenePos;
    vColor = aColor / 255.0;
}
""").

-define(FRAGMENT_SHADER, """
#version 460 core
in vec4 vColor;
out vec4 FragColor;
void main() {
    FragColor = vColor;
}
""").

-define(INVALID_FRAGMENT_SHADER, """
#version 460 core
in vec4 vColor
out vec4FragColor;
void main() {
    FragColor = vColor;
}
""").

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),

    ok.

program_test() ->
    ok = run_graphics(),

    {ok, Program} = program:with_shaders(?VERTEX_SHADER, ?FRAGMENT_SHADER),
    
    Object = program:gl_object(Program),
    graphics_context:execute_commands(fun() ->
        % gl:use_program(Object),
        {ok, [ActiveUniforms]} = gl:get_program(Object, active_uniforms, 1),
        io:format(user, "Active uniforms: ~p~n", [ActiveUniforms]),

        {ok, [ProgramBinaryLength]} = gl:get_program(Object, program_binary_length, 1),
        io:format(user, "Binary length: ~p~n", [ProgramBinaryLength]),
        ok
    end),

    % {ok, Program} = program:with_shaders(?INVALID_VERTEX_SHADER, ?INVALID_FRAGMENT_SHADER),

    ok.
