%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(surface_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(SURFACE_WIDTH, 2).
-define(SURFACE_HEIGHT, 2).
-define(SURFACE_SIZE, {?SURFACE_WIDTH, ?SURFACE_HEIGHT}).
-define(RED_IMAGE, {2, 2, [
    ?COLOR_RED, ?COLOR_RED,
    ?COLOR_RED, ?COLOR_RED
]}).
-define(WHITE_IMAGE, {2, 2, [
    ?COLOR_WHITE, ?COLOR_WHITE,
    ?COLOR_WHITE, ?COLOR_WHITE
]}).
-define(VIEW_MATRIX, {
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    1.0, 2.0, 3.0, 1.0
}).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    Display.

default_projection(Width, Height) ->
    view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).

surface_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    ?SURFACE_SIZE = surface:size(Surface),
    {0, 0, ?SURFACE_WIDTH, ?SURFACE_HEIGHT} = surface:viewport(Surface),
    ?MATRIX4_IDENTITY = surface:view_matrix(Surface),
    DefaultProjection = default_projection(?SURFACE_WIDTH, ?SURFACE_HEIGHT),
    DefaultProjection = surface:projection_matrix(Surface),

    ok = surface:destroy(Surface),

    ok.

surface_with_size_test() ->
    Display = run_graphics(),

    {ok, Surface1} = surface:with_size(Display, {1, 1}),
    {1, 1} = surface:size(Surface1),
    {0, 0, 1, 1} = surface:viewport(Surface1),
    ok = surface:clear(Surface1, ?COLOR_BLACK),
    {1, 1, [?COLOR_BLACK]} = surface:image(Surface1),
    ok = surface:destroy(Surface1),

    ?assertError(function_clause, surface:with_size(Display, {0, 1})),
    ?assertError(function_clause, surface:with_size(Display, {1, 0})),

    ok.

surface_destroy_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    ok = surface:destroy(Surface),
    ?assertError(noproc, surface:gl_commands(Surface, fun() -> ok end)),

    ok.

surface_resize_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Surface1} = surface:set_view_matrix(Surface0, ?VIEW_MATRIX),
    {ok, Surface2} = surface:set_viewport(Surface1, {0, 0, 1, 1}),
    {ok, Surface3} = surface:set_projection_matrix(Surface2, ?MATRIX4_IDENTITY),

    {ok, Surface4} = surface:resize(Surface3, {4, 3}),
    {4, 3} = surface:size(Surface4),
    {0, 0, 4, 3} = surface:viewport(Surface4),
    ?VIEW_MATRIX = surface:view_matrix(Surface4),
    ?MATRIX4_IDENTITY = surface:projection_matrix(Surface4),

    ok = surface:clear(Surface4, ?COLOR_RED),
    {4, 3, Pixels} = surface:image(Surface4),
    12 = length(Pixels),
    lists:foreach(fun(Pixel) ->
        ?COLOR_RED = Pixel
    end, Pixels),

    ?assertError(function_clause, surface:resize(Surface4, {0, 1})),
    ?assertError(function_clause, surface:resize(Surface4, {1, 0})),

    ok = surface:destroy(Surface4),

    ok.

surface_viewport_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {0, 0, ?SURFACE_WIDTH, ?SURFACE_HEIGHT} = surface:viewport(Surface0),

    {ok, Surface1} = surface:set_viewport(Surface0, {1, 0, 1, 2}),
    {0, 0, ?SURFACE_WIDTH, ?SURFACE_HEIGHT} = surface:viewport(Surface0),
    {1, 0, 1, 2} = surface:viewport(Surface1),

    ok = surface:destroy(Surface1),

    ok.

surface_view_projection_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    DefaultProjection = default_projection(?SURFACE_WIDTH, ?SURFACE_HEIGHT),
    Identity = ?MATRIX4_IDENTITY,
    Identity = surface:view_matrix(Surface0),
    DefaultProjection = surface:projection_matrix(Surface0),

    {ok, Surface1} = surface:set_view_matrix(Surface0, ?VIEW_MATRIX),
    ?MATRIX4_IDENTITY = surface:view_matrix(Surface0),
    ?VIEW_MATRIX = surface:view_matrix(Surface1),
    DefaultProjection = surface:projection_matrix(Surface1),

    {ok, Surface2} = surface:set_projection_matrix(Surface1, ?MATRIX4_IDENTITY),
    ?VIEW_MATRIX = surface:view_matrix(Surface2),
    DefaultProjection = surface:projection_matrix(Surface1),
    ?MATRIX4_IDENTITY = surface:projection_matrix(Surface2),

    ok = surface:destroy(Surface2),

    ok.

surface_clear_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    ok = surface:clear(Surface, ?COLOR_RED),
    ?RED_IMAGE = surface:image(Surface),

    ok = surface:clear(Surface, ?COLOR_WHITE),
    ?WHITE_IMAGE = surface:image(Surface),

    ok = surface:destroy(Surface),

    ok.

surface_draw_mesh2_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Mesh} = mesh2:with_vertices([
        {{0.0, 0.0}, ?COLOR_RED, 0.0, 0.0},
        {{2.0, 0.0}, ?COLOR_RED, 1.0, 0.0},
        {{2.0, 2.0}, ?COLOR_RED, 1.0, 1.0},
        {{0.0, 2.0}, ?COLOR_RED, 0.0, 1.0}
    ]),
    ok = surface:clear(Surface, ?COLOR_BLACK),
    ok = surface:draw_mesh2(Surface, Mesh, triangle_fan, 4),
    ?RED_IMAGE = surface:image(Surface),

    ok = mesh2:destroy(Mesh),
    ok = surface:destroy(Surface),

    ok.

surface_gl_commands_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, _Version} = surface:gl_commands(Surface, fun() ->
        gl:get_string(version)
    end),
    {error, {exception, error, boom}} = surface:gl_commands(Surface, fun() ->
        error(boom)
    end),
    {ok, _Version2} = surface:gl_commands(Surface, fun() ->
        gl:get_string(version)
    end),

    ok = surface:destroy(Surface),

    ok.

surface_display_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    ok = surface:clear(Surface, ?COLOR_RED),
    ok = surface:display(Surface),

    ok = surface:destroy(Surface),

    ok.
