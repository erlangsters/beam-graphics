%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_default_program_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("gl/include/gl.hrl").

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

default_program_test() ->
    ok = run_graphics(),

    {ok, Program} = graphics_default_program:new(),
    GlProgram = graphics_program:gl_object(Program),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_program(GlProgram)
    end),

    ok = graphics_program:destroy(Program),
    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_program(GlProgram)
    end),

    ok.

default_program_uniforms_test() ->
    ok = run_graphics(),

    {ok, Program} = graphics_default_program:new(),
    [
        {"uModel", matrix4},
        {"uProjection", matrix4},
        {"uTexture", sampler2d},
        {"uUseTexture", bool},
        {"uView", matrix4}
    ] = graphics_program:uniforms(Program),

    true = graphics_program:has_uniform(Program, "uModel"),
    true = graphics_program:has_uniform(Program, "uView"),
    true = graphics_program:has_uniform(Program, "uProjection"),
    true = graphics_program:has_uniform(Program, "uTexture"),
    true = graphics_program:has_uniform(Program, "uUseTexture"),
    false = graphics_program:has_uniform(Program, "uMissing"),

    GlProgram = graphics_program:gl_object(Program),
    {ok, [0]} = read_uniform(i, GlProgram, "uTexture", 1),
    {ok, [0]} = read_uniform(i, GlProgram, "uUseTexture", 1),

    ok = graphics_program:destroy(Program),

    ok.

read_uniform(Type, GlProgram, Name, Count) ->
    graphics_context:execute_commands(fun() ->
        {ok, Location} = gl:get_uniform_location(GlProgram, Name),
        gl:get_uniform(Type, GlProgram, Location, Count)
    end).
