%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(program).
-moduledoc """
To be written.

To be written.
""".

-export_type([
    vertex_shader/0,
    fragment_shader/0
]).
-export_type([
    object/0
]).
-export([
    with_shaders/2,
    with_binary/1,
    destroy/1,
    binary/1
    % uniform/2,
    % set_uniform/3
]).
-export([
    gl_object/1
]).
% -export([
%     default_shader/0
% ]).

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
To be written.

To be written.
""".
-opaque object() :: {
    ResourceId :: graphics_context:resource_id()
}.

-doc """
To be written.

To be written.
""".
-spec with_shaders(vertex_shader(), fragment_shader()) ->
    {ok, object()} |
    {compile_error, vertex | fragment, string()} |
    {link_error, string()}
.
with_shaders(VertexShader, FragmentShader) ->
    case acquire_program_with_shaders(VertexShader, FragmentShader) of
        {ok, ResourceId} ->
            {ok, {ResourceId}};
        {error, Error} ->
            Error
    end.

-doc """
To be written.

To be written.
""".
-spec with_binary(binary()) -> {ok, object()} | error.
with_binary(Binary) ->
    case acquire_program_with_binary(Binary) of
        {ok, ResourceId} ->
            {ok, {ResourceId}};
        error ->
            error
    end.

-doc """
To be written.

To be written.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId}) ->
    ok = release_program(ResourceId),
    ok.

-doc """
To be written.

To be written.
""".
-spec binary(object()) -> binary().
binary({{program, Program}}) ->
    Binary = program_binary(Program),
    Binary.

% -doc """
% To be written.

% To be written.
% """.
% -spec uniform(object(), string()) -> ok.
% uniform({{program, Program}}, Name) ->
%     ok = uniform(Program, Name),
%     ok.

% -doc """
% To be written.

% To be written.
% """.
% -spec set_uniform(object(), string(), term()) -> ok.
% set_uniform({{program, Program}}, Name, Value) ->
%     ok = set_uniform(Program, Name, Value),
%     ok.

-doc """
To be written.

To be written.
""".
-spec gl_object(object()) -> gl:program().
gl_object({{program, Program}}) ->
    Program.

program_release_fun() ->
    fun({program, Program}) ->
        ok = gl:delete_program(Program),
        ok
    end.

acquire_program_with_shaders(VertexShaderSrc, FragmentShaderSrc) ->
    ReleaseFun = program_release_fun(),
    AcquireFun = fun() ->
        VertexShaderResult = compile_vertex_shader(VertexShaderSrc),
        FragmentShaderResult = compile_fragment_shader(FragmentShaderSrc),
        case {VertexShaderResult, FragmentShaderResult} of
            {{ok, VertexShader}, {ok, FragmentShader}} ->
                case link_program(VertexShader, FragmentShader) of
                    {ok, Program} ->
                        ok = gl:delete_shader(VertexShader),
                        ok = gl:delete_shader(FragmentShader),

                        ok = gl:use_program(Program),

                        {ok, {program, Program}, ReleaseFun};
                    {error, InfoLogs} ->
                        {error, {link_error, InfoLogs}}
                end;
            {{error, InfoLogs}, _} ->
                {error, {compile_error, vertex, InfoLogs}};
            {_, {error, InfoLogs}} ->
                {error, {compile_error, fragment, InfoLogs}}
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

acquire_program_with_binary(Binary) ->
    ReleaseFun = program_release_fun(),
    AcquireFun = fun() ->
        {ok, Program} = gl:create_program(),
        ok = gl:program_binary(Program, binary_format, Binary),
        case gl:get_program(i, Program, link_status, 1) of
            {ok, [?GL_TRUE]} ->
                {ok, {program, Program}, ReleaseFun};
            {ok, [?GL_FALSE]} ->
                {error, error}
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

release_program(ResourceId) ->
    graphics_context:release_resource(ResourceId).

compile_shader(ShaderType, ShaderSrc) ->
    {ok, Shader} = gl:create_shader(ShaderType),
    gl:shader_source(Shader, [ShaderSrc]),
    gl:compile_shader(Shader),
    case gl:get_shader(i, Shader, compile_status, 1) of
        {ok, [?GL_TRUE]} ->
            {ok, Shader};
        {ok, [?GL_FALSE]} ->
            {ok, [InfoLogLength]} = gl:get_shader(i, Shader, info_log_length, 1),
            {ok, InfoLogs} = gl:get_shader_info_log(Shader, InfoLogLength),
            {error, InfoLogs}
    end.

compile_vertex_shader(ShaderSrc) ->
    compile_shader(vertex_shader, ShaderSrc).

compile_fragment_shader(ShaderSrc) ->
    compile_shader(fragment_shader, ShaderSrc).

link_program(VertexShader, FragmentShader) ->
    {ok, Program} = gl:create_program(),
    gl:attach_shader(Program, VertexShader),
    gl:attach_shader(Program, FragmentShader),
    gl:link_program(Program),
    case gl:get_program(i, Program, link_status, 1) of
        {ok, [?GL_TRUE]} ->
            {ok, Program};
        {ok, [?GL_FALSE]} ->
            {ok, [InfoLogLength]} = gl:get_program(i, Program, info_log_length, 1),
            {ok, InfoLogs} = gl:get_program_info_log(Program, InfoLogLength),
            {error, InfoLogs}
    end.

program_binary(Program) ->
    graphics_context:execute_commands(fun() ->
        % XXX: Verify implementation.
        {ok, [BinaryLength]} = gl:get_program(i, Program, program_binary_length, 1),
        {ok, Binary} = gl:get_program_binary(Program, BinaryLength),
        Binary
    end).

uniform(Program, Name) ->
    graphics_context:execute_commands(fun() ->
        ok
    end).

set_uniform(Program, Name, Value) ->
    graphics_context:execute_commands(fun() ->
        ok
    end).
