%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_program).
-moduledoc """
Program

A program is a GPU shader program that is typically used for rendering.

A program is an opaque object that wraps a linked GPU program. It is created
with the `with_shaders` and `with_binary` functions and disposed with the
`destroy/1` function. Copying the term does not copy the GPU program.

A program is built from a vertex shader and a fragment shader. Uniforms are
set by name with `set_uniform/3`. The program does not need to be bound first.

```erlang
{ok, Program} = graphics_program:with_shaders(VertexSrc, FragmentSrc),
ok = graphics_program:set_uniform(Program, "uModel", graphics_matrix4:identity()),
ok = graphics_program:destroy(Program).
```

There is one program module for both 2D and 3D drawing. It is not split into
`program2` and `program3`.

Meshes upload position, color, and UV at attribute locations 0, 1, and 2. A
custom program that is drawn through `graphics_surface` or `graphics_frame` should match that
layout. `graphics_program` does not enforce it.

`set_uniform/3` writes GPU state and does not change the Erlang term. A
uniform declared in the shader but unused may be optimized out; it then does
not appear in `uniforms/1` and `set_uniform/3` returns `no_uniform`. A
`sampler2d` uniform is a texture unit (an integer). Binding a texture is a
draw concern, not a program concern.

`binary/1` returns the compiled GPU payload. It is vendor-specific and is not
portable across drivers. `no_binary` means the driver has no program binary.

Beware that a well-formed uniform value always uses floats, not integers, for
float, vector, and matrix uniforms.

**OpenGL Internals**

A program wraps an OpenGL program object. Use `gl_object/1` to retrieve the
program id.
""".

-export_type([
    vertex_shader/0,
    fragment_shader/0
]).
-export_type([
    binary_format/0,
    program_binary/0
]).
-export_type([
    uniform_type/0,
    uniform_value/0
]).
-export_type([
    object/0
]).
-export([
    with_shaders/2,
    with_binary/1,
    destroy/1,
    binary/1
]).
-export([
    uniforms/1,
    has_uniform/2,
    set_uniform/3
]).
-export([
    gl_object/1
]).

-compile({inline, [
    destroy/1,
    uniforms/1,
    has_uniform/2,
    gl_object/1
]}).

-include_lib("gl/include/gl.hrl").

-doc """
Source code of a vertex shader.
""".
-type vertex_shader() :: string().

-doc """
Source code of a fragment shader.
""".
-type fragment_shader() :: string().

-doc """
A program binary format.

It is a vendor-specific integer. Callers round-trip it from `binary/1` and do
not construct it.
""".
-type binary_format() :: integer().

-doc """
A compiled program payload.

A vendor-specific format and the compiled binary. It is not portable across
drivers.
""".
-type program_binary() :: {
    Format :: binary_format(),
    Data :: binary()
}.

-doc """
A program uniform type.

`sampler2d` is a texture unit. A `graphics:color()` is a `vector4`.
""".
-type uniform_type() ::
    bool |
    int |
    float |
    vector2 |
    vector3 |
    vector4 |
    matrix3 |
    matrix4 |
    sampler2d
.

-doc """
A program uniform value.

`bool` takes `true` or `false`. `int` and `sampler2d` take an integer. Float,
vector, and matrix values use floats, not integers.
""".
-type uniform_value() ::
    boolean() |
    integer() |
    float() |
    graphics:vector2() |
    graphics:vector3() |
    graphics:vector4() |
    graphics:matrix3() |
    graphics:matrix4()
.

-doc """
A program object.

It wraps an OpenGL program id and the active uniforms gathered after a
successful link.
""".
-opaque object() :: {
    ResourceId :: {program, gl:program()},
    Uniforms :: [{string(), gl:int(), uniform_type()}]
}.

-doc """
A program from vertex and fragment shaders.

It compiles the vertex shader, then the fragment shader, then links them.
If the vertex shader fails to compile, the fragment shader is not compiled.

It returns `out_of_memory` when the GPU cannot allocate the program. Compile
and link failures include the driver info log.
""".
-spec with_shaders(vertex_shader(), fragment_shader()) ->
    {ok, object()} |
    {compile_error, vertex | fragment, string()} |
    {link_error, string()} |
    out_of_memory
.
with_shaders(VertexShader, FragmentShader) ->
    case acquire_program_with_shaders(VertexShader, FragmentShader) of
        {ok, ResourceId} ->
            {ok, {ResourceId, collect_uniforms(ResourceId)}};
        {error, Error} ->
            Error
    end.

-doc """
A program from a compiled binary.

It constructs a program from a payload previously returned by `binary/1`.
The payload is vendor-specific. It returns `{link_error, Log}` when the
driver rejects the binary.
""".
-spec with_binary(program_binary()) ->
    {ok, object()} | {link_error, string()} | out_of_memory
.
with_binary({Format, Data}) when is_integer(Format), is_binary(Data) ->
    case acquire_program_with_binary(Format, Data) of
        {ok, ResourceId} ->
            {ok, {ResourceId, collect_uniforms(ResourceId)}};
        {error, Error} ->
            Error
    end.

-doc """
Destroy a program.

It releases the GPU program. Using the program after it is destroyed has
undefined behavior. Destroying the same program twice is invalid.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId, _Uniforms}) ->
    ok = release_program(ResourceId),
    ok.

-doc """
The compiled binary of a program.

It returns the vendor-specific compiled payload. It returns `no_binary` when
the driver has no program binary.
""".
-spec binary(object()) -> program_binary() | no_binary.
binary({{program, GlProgram}, _Uniforms}) ->
    graphics_context:execute_commands(fun() ->
        {ok, [Length]} = gl:get_program(GlProgram, program_binary_length, 1),
        case Length of
            0 ->
                no_binary;
            _ ->
                {ok, Format, Data} = gl:get_program_binary(GlProgram, Length),
                {Format, Data}
        end
    end).

-doc """
The active uniforms of a program.

It returns the settable uniforms as `{Name, Type}` pairs, sorted by name.
Arrays, uniform blocks, and unsupported types are omitted.
""".
-spec uniforms(object()) -> [{string(), uniform_type()}].
uniforms({_ResourceId, Uniforms}) ->
    [{Name, Type} || {Name, _Location, Type} <- Uniforms].

-doc """
Check whether a program has a uniform.

It returns `true` when the named uniform is active and settable, otherwise
`false`.
""".
-spec has_uniform(object(), string()) -> boolean().
has_uniform({_ResourceId, Uniforms}, Name) ->
    lists:keymember(Name, 1, Uniforms).

-doc """
Set a uniform of a program.

It writes the given value to the named uniform. The Erlang term is unchanged.
The program does not need to be bound.

A missing or optimized-out name is `no_uniform`. A well-formed value of the
wrong kind is `type_mismatch`. A `sampler2d` value is a texture unit, not a
texture object. A color is a `vector4`.
""".
-spec set_uniform(object(), string(), uniform_value()) ->
    ok | no_uniform | type_mismatch
.
set_uniform({ResourceId, Uniforms}, Name, Value) ->
    case lists:keyfind(Name, 1, Uniforms) of
        false ->
            no_uniform;
        {Name, Location, Type} ->
            set_uniform_value(ResourceId, Location, Type, Value)
    end.

-doc """
The OpenGL program of a program.

It returns the OpenGL program id wrapped by the program.
""".
-spec gl_object(object()) -> gl:program().
gl_object({{program, GlProgram}, _Uniforms}) ->
    GlProgram.

set_uniform_value(ResourceId, Location, Type, Value) ->
    ValueType = value_type(Value),
    case compatible(Type, ValueType) of
        true ->
            upload_uniform(ResourceId, Location, Type, Value);
        false ->
            type_mismatch
    end.

value_type(true) ->
    bool;
value_type(false) ->
    bool;
value_type(Value) when is_integer(Value) ->
    int;
value_type(Value) when is_float(Value) ->
    float;
value_type({X, Y}) when is_float(X), is_float(Y) ->
    vector2;
value_type({X, Y, Z}) when is_float(X), is_float(Y), is_float(Z) ->
    vector3;
value_type({X, Y, Z, W})
        when is_float(X), is_float(Y), is_float(Z), is_float(W) ->
    vector4;
value_type({M11, M21, M31, M12, M22, M32, M13, M23, M33})
        when is_float(M11), is_float(M21), is_float(M31),
             is_float(M12), is_float(M22), is_float(M32),
             is_float(M13), is_float(M23), is_float(M33) ->
    matrix3;
value_type({
    M11, M21, M31, M41,
    M12, M22, M32, M42,
    M13, M23, M33, M43,
    M14, M24, M34, M44
}) when is_float(M11), is_float(M21), is_float(M31), is_float(M41),
        is_float(M12), is_float(M22), is_float(M32), is_float(M42),
        is_float(M13), is_float(M23), is_float(M33), is_float(M43),
        is_float(M14), is_float(M24), is_float(M34), is_float(M44) ->
    matrix4.

compatible(Type, Type) ->
    true;
compatible(sampler2d, int) ->
    true;
compatible(_Type, _ValueType) ->
    false.

upload_uniform({program, GlProgram}, Location, Type, Value) ->
    graphics_context:execute_commands(fun() ->
        case Type of
            bool ->
                Int = case Value of
                    true ->
                        1;
                    false ->
                        0
                end,
                ok = gl:program_uniform(i, GlProgram, Location, Int);
            int ->
                ok = gl:program_uniform(i, GlProgram, Location, Value);
            sampler2d ->
                ok = gl:program_uniform(i, GlProgram, Location, Value);
            float ->
                ok = gl:program_uniform(f, GlProgram, Location, Value);
            vector2 ->
                ok = gl:program_uniform(f, GlProgram, Location, Value);
            vector3 ->
                ok = gl:program_uniform(f, GlProgram, Location, Value);
            vector4 ->
                ok = gl:program_uniform(f, GlProgram, Location, Value);
            matrix3 ->
                ok = gl:program_uniform_matrix(
                    f, GlProgram, Location, graphics_matrix3:columns(Value)
                );
            matrix4 ->
                ok = gl:program_uniform_matrix(
                    f, GlProgram, Location, graphics_matrix4:columns(Value)
                )
        end,
        ok
    end).

program_release_fun() ->
    fun({program, GlProgram}) ->
        ok = gl:delete_program(GlProgram),
        ok
    end.

acquire_program_with_shaders(VertexShaderSrc, FragmentShaderSrc) ->
    ReleaseFun = program_release_fun(),
    AcquireFun = fun() ->
        case compile_shader(vertex_shader, VertexShaderSrc) of
            {error, out_of_memory} ->
                {error, out_of_memory};
            {error, Log} ->
                {error, {compile_error, vertex, Log}};
            {ok, VertexShader} ->
                case compile_shader(fragment_shader, FragmentShaderSrc) of
                    {error, out_of_memory} ->
                        ok = gl:delete_shader(VertexShader),
                        {error, out_of_memory};
                    {error, Log} ->
                        ok = gl:delete_shader(VertexShader),
                        {error, {compile_error, fragment, Log}};
                    {ok, FragmentShader} ->
                        case link_program(VertexShader, FragmentShader) of
                            {ok, GlProgram} ->
                                {ok, {program, GlProgram}, ReleaseFun};
                            {error, Error} ->
                                {error, Error}
                        end
                end
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

acquire_program_with_binary(Format, Data) ->
    ReleaseFun = program_release_fun(),
    AcquireFun = fun() ->
        case gl:create_program() of
            {ok, GlProgram} when GlProgram > 0 ->
                ok = gl:program_parameter(
                    GlProgram, program_binary_retrievable_hint, 1
                ),
                case gl:program_binary(GlProgram, Format, Data) of
                    ok ->
                        case gl:get_program(GlProgram, link_status, 1) of
                            {ok, [?GL_TRUE]} ->
                                {ok, {program, GlProgram}, ReleaseFun};
                            {ok, [?GL_FALSE]} ->
                                Log = program_info_log(GlProgram),
                                ok = gl:delete_program(GlProgram),
                                {error, {link_error, Log}}
                        end;
                    {error, _} ->
                        Log = program_info_log(GlProgram),
                        ok = gl:delete_program(GlProgram),
                        {error, {link_error, Log}}
                end;
            _ ->
                {error, out_of_memory}
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

release_program(ResourceId) ->
    graphics_context:release_resource(ResourceId).

compile_shader(ShaderType, ShaderSrc) ->
    case gl:create_shader(ShaderType) of
        {ok, Shader} when Shader > 0 ->
            ok = gl:shader_source(Shader, [ShaderSrc]),
            ok = gl:compile_shader(Shader),
            case gl:get_shader(Shader, compile_status, 1) of
                {ok, [?GL_TRUE]} ->
                    {ok, Shader};
                {ok, [?GL_FALSE]} ->
                    Log = shader_info_log(Shader),
                    ok = gl:delete_shader(Shader),
                    {error, Log}
            end;
        _ ->
            {error, out_of_memory}
    end.

link_program(VertexShader, FragmentShader) ->
    case gl:create_program() of
        {ok, GlProgram} when GlProgram > 0 ->
            ok = gl:program_parameter(
                GlProgram, program_binary_retrievable_hint, 1
            ),
            ok = gl:attach_shader(GlProgram, VertexShader),
            ok = gl:attach_shader(GlProgram, FragmentShader),
            ok = gl:link_program(GlProgram),
            case gl:get_program(GlProgram, link_status, 1) of
                {ok, [?GL_TRUE]} ->
                    ok = gl:detach_shader(GlProgram, VertexShader),
                    ok = gl:detach_shader(GlProgram, FragmentShader),
                    ok = gl:delete_shader(VertexShader),
                    ok = gl:delete_shader(FragmentShader),
                    {ok, GlProgram};
                {ok, [?GL_FALSE]} ->
                    Log = program_info_log(GlProgram),
                    ok = gl:detach_shader(GlProgram, VertexShader),
                    ok = gl:detach_shader(GlProgram, FragmentShader),
                    ok = gl:delete_shader(VertexShader),
                    ok = gl:delete_shader(FragmentShader),
                    ok = gl:delete_program(GlProgram),
                    {error, {link_error, Log}}
            end;
        _ ->
            ok = gl:delete_shader(VertexShader),
            ok = gl:delete_shader(FragmentShader),
            {error, out_of_memory}
    end.

collect_uniforms({program, GlProgram}) ->
    graphics_context:execute_commands(fun() ->
        collect_uniforms_gl(GlProgram)
    end).

collect_uniforms_gl(GlProgram) ->
    {ok, [Count]} = gl:get_program(GlProgram, active_uniforms, 1),
    case Count of
        0 ->
            [];
        _ ->
            {ok, [MaxLength]} =
                gl:get_program(GlProgram, active_uniform_max_length, 1),
            Uniforms = collect_uniforms_gl(
                GlProgram, max(MaxLength, 1), 0, Count, []
            ),
            lists:keysort(1, Uniforms)
    end.

collect_uniforms_gl(_GlProgram, _MaxLength, Index, Count, Acc)
        when Index >= Count ->
    Acc;
collect_uniforms_gl(GlProgram, MaxLength, Index, Count, Acc) ->
    Acc1 = case gl:get_active_uniform(GlProgram, Index, MaxLength) of
        {ok, Size, GlType, NameBin} ->
            case {Size, to_uniform_type(GlType), is_default_block(GlProgram, Index)} of
                {1, {ok, Type}, true} ->
                    Name = name_to_string(NameBin),
                    case gl:get_uniform_location(GlProgram, Name) of
                        {ok, Location} when Location >= 0 ->
                            [{Name, Location, Type} | Acc];
                        _ ->
                            Acc
                    end;
                _ ->
                    Acc
            end;
        _ ->
            Acc
    end,
    collect_uniforms_gl(GlProgram, MaxLength, Index + 1, Count, Acc1).

is_default_block(GlProgram, Index) ->
    case gl:get_active_uniforms(GlProgram, [Index], uniform_block_index) of
        {ok, [BlockIndex]} ->
            BlockIndex =:= -1 orelse BlockIndex =:= 16#FFFFFFFF;
        _ ->
            false
    end.

to_uniform_type(bool) ->
    {ok, bool};
to_uniform_type(int) ->
    {ok, int};
to_uniform_type(float) ->
    {ok, float};
to_uniform_type(float_vec2) ->
    {ok, vector2};
to_uniform_type(float_vec3) ->
    {ok, vector3};
to_uniform_type(float_vec4) ->
    {ok, vector4};
to_uniform_type(float_mat3) ->
    {ok, matrix3};
to_uniform_type(float_mat4) ->
    {ok, matrix4};
to_uniform_type(sampler_2d) ->
    {ok, sampler2d};
to_uniform_type(_GlType) ->
    error.

shader_info_log(Shader) ->
    case gl:get_shader(Shader, info_log_length, 1) of
        {ok, [Length]} when Length > 0 ->
            {ok, Log} = gl:get_shader_info_log(Shader, Length),
            name_to_string(Log);
        _ ->
            ""
    end.

program_info_log(GlProgram) ->
    case gl:get_program(GlProgram, info_log_length, 1) of
        {ok, [Length]} when Length > 0 ->
            {ok, Log} = gl:get_program_info_log(GlProgram, Length),
            name_to_string(Log);
        _ ->
            ""
    end.

name_to_string(Value) when is_list(Value) ->
    Value;
name_to_string(Value) when is_binary(Value) ->
    case binary:split(Value, <<0>>) of
        [Head | _] ->
            binary_to_list(Head);
        [] ->
            ""
    end.
