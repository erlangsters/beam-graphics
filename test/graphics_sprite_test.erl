%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_sprite_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

shape_mesh(Shape) ->
    [{Mesh, PrimitiveType, VertexCount}] = graphics_shape2:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

sprite_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_color(?COLOR_GREEN, {2, 2}),
    {ok, Shape} = graphics_sprite:from_texture({1.0, 2.0}, {10.0, 20.0}, Texture),
    {Mesh, triangle_fan, 4} = shape_mesh(Shape),
    [
        {{1.0, 2.0}, ?COLOR_WHITE, 0.0, 0.0},
        {{11.0, 2.0}, ?COLOR_WHITE, 1.0, 0.0},
        {{11.0, 22.0}, ?COLOR_WHITE, 1.0, 1.0},
        {{1.0, 22.0}, ?COLOR_WHITE, 0.0, 1.0}
    ] = graphics_mesh2:remote_vertices(Mesh),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Shape),
    Texture = graphics_shape2:texture(Shape),

    ok = graphics_shape2:destroy(Shape),
    {2, 2} = graphics_texture:size(Texture),
    ok = graphics_texture:destroy(Texture),
    ok.

sprite_from_texture_color_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_color(?COLOR_BLUE, {1, 1}),
    {ok, Shape} = graphics_sprite:from_texture(
        {0.0, 0.0},
        {4.0, 3.0},
        Texture,
        ?COLOR_RED
    ),
    {Mesh, triangle_fan, 4} = shape_mesh(Shape),
    [
        {{0.0, 0.0}, ?COLOR_RED, 0.0, 0.0},
        {{4.0, 0.0}, ?COLOR_RED, 1.0, 0.0},
        {{4.0, 3.0}, ?COLOR_RED, 1.0, 1.0},
        {{0.0, 3.0}, ?COLOR_RED, 0.0, 1.0}
    ] = graphics_mesh2:remote_vertices(Mesh),
    Texture = graphics_shape2:texture(Shape),

    ok = graphics_shape2:destroy(Shape),
    ok = graphics_texture:destroy(Texture),
    ok.
