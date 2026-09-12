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
    none = surface:blend_mode(Surface),
    enabled = surface:depth_test(Surface),

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
    {ok, Surface3a} = surface:set_blend_mode(Surface3, alpha),
    {ok, Surface3b} = surface:set_depth_test(Surface3a, disabled),

    {ok, Surface4} = surface:resize(Surface3b, {4, 3}),
    {4, 3} = surface:size(Surface4),
    {0, 0, 4, 3} = surface:viewport(Surface4),
    ?VIEW_MATRIX = surface:view_matrix(Surface4),
    ?MATRIX4_IDENTITY = surface:projection_matrix(Surface4),
    alpha = surface:blend_mode(Surface4),
    disabled = surface:depth_test(Surface4),

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

surface_blend_depth_term_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    none = surface:blend_mode(Surface0),
    enabled = surface:depth_test(Surface0),

    {ok, Surface1} = surface:set_blend_mode(Surface0, alpha),
    none = surface:blend_mode(Surface0),
    alpha = surface:blend_mode(Surface1),
    enabled = surface:depth_test(Surface1),

    {ok, Surface2} = surface:set_depth_test(Surface1, disabled),
    enabled = surface:depth_test(Surface1),
    disabled = surface:depth_test(Surface2),
    alpha = surface:blend_mode(Surface2),

    {ok, Surface3} = surface:set_blend_mode(Surface2, add),
    add = surface:blend_mode(Surface3),
    {ok, Surface4} = surface:set_blend_mode(Surface3, multiply),
    multiply = surface:blend_mode(Surface4),
    {ok, Surface5} = surface:set_blend_mode(Surface4, none),
    none = surface:blend_mode(Surface5),

    ?assertError(function_clause, surface:set_blend_mode(Surface5, replace)),
    ?assertError(function_clause, surface:set_depth_test(Surface5, on)),

    ok = surface:destroy(Surface5),
    ok.

surface_depth_keeps_first_test() ->
    Display = run_graphics(),

    {ok, Surface} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Red} = full_quad(?COLOR_RED),
    {ok, Blue} = full_quad(?COLOR_BLUE),
    ok = surface:clear(Surface, ?COLOR_BLACK),
    ok = surface:draw_mesh2(Surface, Red, triangle_fan, 4),
    ok = surface:draw_mesh2(Surface, Blue, triangle_fan, 4),
    assert_image(?RED_IMAGE, surface:image(Surface)),

    ok = mesh2:destroy(Red),
    ok = mesh2:destroy(Blue),
    ok = surface:destroy(Surface),
    ok.

surface_depth_disabled_replace_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Surface} = surface:set_depth_test(Surface0, disabled),
    {ok, Red} = full_quad(?COLOR_RED),
    {ok, Blue} = full_quad(?COLOR_BLUE),
    ok = surface:clear(Surface, ?COLOR_BLACK),
    ok = surface:draw_mesh2(Surface, Red, triangle_fan, 4),
    ok = surface:draw_mesh2(Surface, Blue, triangle_fan, 4),
    {2, 2, [
        ?COLOR_BLUE, ?COLOR_BLUE,
        ?COLOR_BLUE, ?COLOR_BLUE
    ]} = surface:image(Surface),

    ok = mesh2:destroy(Red),
    ok = mesh2:destroy(Blue),
    ok = surface:destroy(Surface),
    ok.

surface_blend_alpha_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Surface1} = surface:set_depth_test(Surface0, disabled),
    {ok, Surface} = surface:set_blend_mode(Surface1, alpha),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    ok = surface:clear(Surface, ?COLOR_BLUE),
    ok = surface:draw_mesh2(Surface, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = surface:image(Surface),
    assert_pixels({0.5, 0.0, 0.5, 0.75}, Pixels),

    ok = mesh2:destroy(Overlay),
    ok = surface:destroy(Surface),
    ok.

surface_blend_add_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Surface1} = surface:set_depth_test(Surface0, disabled),
    {ok, Surface} = surface:set_blend_mode(Surface1, add),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    ok = surface:clear(Surface, ?COLOR_BLUE),
    ok = surface:draw_mesh2(Surface, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = surface:image(Surface),
    assert_pixels({0.5, 0.0, 1.0, 1.0}, Pixels),

    ok = mesh2:destroy(Overlay),
    ok = surface:destroy(Surface),
    ok.

surface_blend_multiply_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Surface1} = surface:set_depth_test(Surface0, disabled),
    {ok, Surface} = surface:set_blend_mode(Surface1, multiply),
    {ok, Overlay} = full_quad(?COLOR_RED),
    ok = surface:clear(Surface, ?COLOR_BLUE),
    ok = surface:draw_mesh2(Surface, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = surface:image(Surface),
    assert_pixels(?COLOR_BLACK, Pixels),

    ok = mesh2:destroy(Overlay),
    ok = surface:destroy(Surface),
    ok.

surface_blend_none_disables_test() ->
    Display = run_graphics(),

    {ok, Surface0} = surface:with_size(Display, ?SURFACE_SIZE),
    {ok, Surface1} = surface:set_depth_test(Surface0, disabled),
    {ok, Surface2} = surface:set_blend_mode(Surface1, alpha),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    {ok, Green} = full_quad(?COLOR_GREEN),
    ok = surface:clear(Surface2, ?COLOR_BLUE),
    ok = surface:draw_mesh2(Surface2, Overlay, triangle_fan, 4),
    {ok, Surface3} = surface:set_blend_mode(Surface2, none),
    ok = surface:draw_mesh2(Surface3, Green, triangle_fan, 4),
    {2, 2, [
        ?COLOR_GREEN, ?COLOR_GREEN,
        ?COLOR_GREEN, ?COLOR_GREEN
    ]} = surface:image(Surface3),

    ok = mesh2:destroy(Overlay),
    ok = mesh2:destroy(Green),
    ok = surface:destroy(Surface3),
    ok.

full_quad(Color) ->
    mesh2:with_vertices([
        {{0.0, 0.0}, Color, 0.0, 0.0},
        {{2.0, 0.0}, Color, 1.0, 0.0},
        {{2.0, 2.0}, Color, 1.0, 1.0},
        {{0.0, 2.0}, Color, 0.0, 1.0}
    ]).

assert_image(Expected, Expected) ->
    ok.

assert_pixels(Expected, Pixels) ->
    lists:foreach(fun(Pixel) ->
        true = color:is_equal_to(Expected, Pixel, 1.0 / 255.0)
    end, Pixels).
