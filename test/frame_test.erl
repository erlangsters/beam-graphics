%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(frame_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(FRAME_WIDTH, 2).
-define(FRAME_HEIGHT, 2).
-define(FRAME_SIZE, {?FRAME_WIDTH, ?FRAME_HEIGHT}).
-define(RED_IMAGE, {2, 2, [
    ?COLOR_RED, ?COLOR_RED,
    ?COLOR_RED, ?COLOR_RED
]}).
-define(BLACK_IMAGE, {2, 2, [
    ?COLOR_BLACK, ?COLOR_BLACK,
    ?COLOR_BLACK, ?COLOR_BLACK
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
    ok.

default_projection(Width, Height) ->
    view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).

frame_test() ->
    ok = run_graphics(),

    {ok, Frame} = frame:with_size(?FRAME_SIZE),
    ?FRAME_SIZE = frame:size(Frame),
    {0, 0, ?FRAME_WIDTH, ?FRAME_HEIGHT} = frame:viewport(Frame),
    ?MATRIX4_IDENTITY = frame:view_matrix(Frame),
    DefaultProjection = default_projection(?FRAME_WIDTH, ?FRAME_HEIGHT),
    DefaultProjection = frame:projection_matrix(Frame),
    none = frame:blend_mode(Frame),
    enabled = frame:depth_test(Frame),

    Texture = frame:texture(Frame),
    ?FRAME_SIZE = texture:size(Texture),
    linear = texture:color_space(Texture),
    linear = texture:minification_filter(Texture),
    linear = texture:magnification_filter(Texture),
    clamp_to_edge = texture:wrap_mode(Texture, horizontal),
    clamp_to_edge = texture:wrap_mode(Texture, vertical),
    undefined = texture:local_image(Texture),
    false = texture:has_local_copy(Texture),
    ?BLACK_IMAGE = texture:remote_image(Texture),

    ok = frame:destroy(Frame),
    ok.

frame_with_size_test() ->
    ok = run_graphics(),

    {ok, Frame1} = frame:with_size({1, 1}),
    {1, 1} = frame:size(Frame1),
    {0, 0, 1, 1} = frame:viewport(Frame1),
    {1, 1, [?COLOR_BLACK]} = texture:remote_image(frame:texture(Frame1)),
    ok = frame:destroy(Frame1),

    ?assertError(function_clause, frame:with_size({0, 1})),
    ?assertError(function_clause, frame:with_size({1, 0})),

    ok.

frame_destroy_test() ->
    ok = run_graphics(),

    {ok, Frame} = frame:with_size(?FRAME_SIZE),
    Framebuffer = frame:gl_object(Frame),
    GlTexture = texture:gl_object(frame:texture(Frame)),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_framebuffer(Framebuffer)
    end),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok = frame:destroy(Frame),

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_framebuffer(Framebuffer)
    end),
    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok.

frame_resize_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = frame:set_view_matrix(Frame0, ?VIEW_MATRIX),
    {ok, Frame2} = frame:set_viewport(Frame1, {0, 0, 1, 1}),
    {ok, Frame3} = frame:set_projection_matrix(Frame2, ?MATRIX4_IDENTITY),
    {ok, Frame3a} = frame:set_blend_mode(Frame3, alpha),
    {ok, Frame3b} = frame:set_depth_test(Frame3a, disabled),
    Framebuffer = frame:gl_object(Frame3b),
    GlTexture = texture:gl_object(frame:texture(Frame3b)),
    ok = frame:clear(Frame3b, ?COLOR_RED),

    {ok, Frame4} = frame:resize(Frame3b, {4, 3}),
    {4, 3} = frame:size(Frame4),
    {4, 3} = texture:size(frame:texture(Frame4)),
    {0, 0, 4, 3} = frame:viewport(Frame4),
    ?VIEW_MATRIX = frame:view_matrix(Frame4),
    ?MATRIX4_IDENTITY = frame:projection_matrix(Frame4),
    alpha = frame:blend_mode(Frame4),
    disabled = frame:depth_test(Frame4),
    Framebuffer = frame:gl_object(Frame4),
    GlTexture = texture:gl_object(frame:texture(Frame4)),
    {1, 1, ?COLOR_BLACK} = texture:remote_pixel(frame:texture(Frame4), 0, 0),
    {4, 3, ?COLOR_BLACK} = texture:remote_pixel(frame:texture(Frame4), -1, -1),

    ?assertError(function_clause, frame:resize(Frame4, {0, 1})),
    ?assertError(function_clause, frame:resize(Frame4, {1, 0})),

    ok = frame:destroy(Frame4),
    ok.

frame_viewport_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {0, 0, ?FRAME_WIDTH, ?FRAME_HEIGHT} = frame:viewport(Frame0),

    {ok, Frame1} = frame:set_viewport(Frame0, {1, 0, 1, 2}),
    {0, 0, ?FRAME_WIDTH, ?FRAME_HEIGHT} = frame:viewport(Frame0),
    {1, 0, 1, 2} = frame:viewport(Frame1),

    ok = frame:destroy(Frame1),
    ok.

frame_view_projection_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    DefaultProjection = default_projection(?FRAME_WIDTH, ?FRAME_HEIGHT),
    Identity = ?MATRIX4_IDENTITY,
    Identity = frame:view_matrix(Frame0),
    DefaultProjection = frame:projection_matrix(Frame0),

    {ok, Frame1} = frame:set_view_matrix(Frame0, ?VIEW_MATRIX),
    ?MATRIX4_IDENTITY = frame:view_matrix(Frame0),
    ?VIEW_MATRIX = frame:view_matrix(Frame1),
    DefaultProjection = frame:projection_matrix(Frame1),

    {ok, Frame2} = frame:set_projection_matrix(Frame1, ?MATRIX4_IDENTITY),
    ?VIEW_MATRIX = frame:view_matrix(Frame2),
    DefaultProjection = frame:projection_matrix(Frame1),
    ?MATRIX4_IDENTITY = frame:projection_matrix(Frame2),

    ok = frame:destroy(Frame2),
    ok.

frame_clear_test() ->
    ok = run_graphics(),

    {ok, Frame} = frame:with_size(?FRAME_SIZE),
    ?BLACK_IMAGE = texture:remote_image(frame:texture(Frame)),

    ok = frame:clear(Frame, ?COLOR_RED),
    ?RED_IMAGE = texture:remote_image(frame:texture(Frame)),

    ok = frame:clear(Frame, ?COLOR_WHITE),
    {2, 2, [
        ?COLOR_WHITE, ?COLOR_WHITE,
        ?COLOR_WHITE, ?COLOR_WHITE
    ]} = texture:remote_image(frame:texture(Frame)),

    ok = frame:destroy(Frame),
    ok.

frame_draw_mesh2_test() ->
    ok = run_graphics(),

    {ok, Frame} = frame:with_size(?FRAME_SIZE),
    {ok, Mesh} = mesh2:with_vertices([
        {{0.0, 0.0}, ?COLOR_RED, 0.0, 0.0},
        {{2.0, 0.0}, ?COLOR_RED, 1.0, 0.0},
        {{2.0, 2.0}, ?COLOR_RED, 1.0, 1.0},
        {{0.0, 2.0}, ?COLOR_RED, 0.0, 1.0}
    ]),
    ok = frame:clear(Frame, ?COLOR_BLACK),
    ok = frame:draw_mesh2(Frame, Mesh, triangle_fan, 4),
    ?RED_IMAGE = texture:remote_image(frame:texture(Frame)),

    ok = mesh2:destroy(Mesh),
    ok = frame:destroy(Frame),
    ok.

frame_gl_object_test() ->
    ok = run_graphics(),

    {ok, Frame} = frame:with_size(?FRAME_SIZE),
    Framebuffer = frame:gl_object(Frame),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_framebuffer(Framebuffer)
    end),

    ok = frame:destroy(Frame),
    ok.

frame_blend_depth_term_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    none = frame:blend_mode(Frame0),
    enabled = frame:depth_test(Frame0),

    {ok, Frame1} = frame:set_blend_mode(Frame0, alpha),
    none = frame:blend_mode(Frame0),
    alpha = frame:blend_mode(Frame1),
    enabled = frame:depth_test(Frame1),

    {ok, Frame2} = frame:set_depth_test(Frame1, disabled),
    enabled = frame:depth_test(Frame1),
    disabled = frame:depth_test(Frame2),
    alpha = frame:blend_mode(Frame2),

    {ok, Frame3} = frame:set_blend_mode(Frame2, add),
    add = frame:blend_mode(Frame3),
    {ok, Frame4} = frame:set_blend_mode(Frame3, multiply),
    multiply = frame:blend_mode(Frame4),
    {ok, Frame5} = frame:set_blend_mode(Frame4, none),
    none = frame:blend_mode(Frame5),

    ?assertError(function_clause, frame:set_blend_mode(Frame5, replace)),
    ?assertError(function_clause, frame:set_depth_test(Frame5, on)),

    ok = frame:destroy(Frame5),
    ok.

frame_depth_keeps_first_test() ->
    ok = run_graphics(),

    {ok, Frame} = frame:with_size(?FRAME_SIZE),
    {ok, Red} = full_quad(?COLOR_RED),
    {ok, Blue} = full_quad(?COLOR_BLUE),
    ok = frame:clear(Frame, ?COLOR_BLACK),
    ok = frame:draw_mesh2(Frame, Red, triangle_fan, 4),
    ok = frame:draw_mesh2(Frame, Blue, triangle_fan, 4),
    assert_image(?RED_IMAGE, texture:remote_image(frame:texture(Frame))),

    ok = mesh2:destroy(Red),
    ok = mesh2:destroy(Blue),
    ok = frame:destroy(Frame),
    ok.

frame_depth_disabled_replace_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {ok, Frame} = frame:set_depth_test(Frame0, disabled),
    {ok, Red} = full_quad(?COLOR_RED),
    {ok, Blue} = full_quad(?COLOR_BLUE),
    ok = frame:clear(Frame, ?COLOR_BLACK),
    ok = frame:draw_mesh2(Frame, Red, triangle_fan, 4),
    ok = frame:draw_mesh2(Frame, Blue, triangle_fan, 4),
    {2, 2, [
        ?COLOR_BLUE, ?COLOR_BLUE,
        ?COLOR_BLUE, ?COLOR_BLUE
    ]} = texture:remote_image(frame:texture(Frame)),

    ok = mesh2:destroy(Red),
    ok = mesh2:destroy(Blue),
    ok = frame:destroy(Frame),
    ok.

frame_blend_alpha_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = frame:set_depth_test(Frame0, disabled),
    {ok, Frame} = frame:set_blend_mode(Frame1, alpha),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    ok = frame:clear(Frame, ?COLOR_BLUE),
    ok = frame:draw_mesh2(Frame, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = texture:remote_image(frame:texture(Frame)),
    assert_pixels({0.5, 0.0, 0.5, 0.75}, Pixels),

    ok = mesh2:destroy(Overlay),
    ok = frame:destroy(Frame),
    ok.

frame_blend_add_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = frame:set_depth_test(Frame0, disabled),
    {ok, Frame} = frame:set_blend_mode(Frame1, add),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    ok = frame:clear(Frame, ?COLOR_BLUE),
    ok = frame:draw_mesh2(Frame, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = texture:remote_image(frame:texture(Frame)),
    assert_pixels({0.5, 0.0, 1.0, 1.0}, Pixels),

    ok = mesh2:destroy(Overlay),
    ok = frame:destroy(Frame),
    ok.

frame_blend_multiply_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = frame:set_depth_test(Frame0, disabled),
    {ok, Frame} = frame:set_blend_mode(Frame1, multiply),
    {ok, Overlay} = full_quad(?COLOR_RED),
    ok = frame:clear(Frame, ?COLOR_BLUE),
    ok = frame:draw_mesh2(Frame, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = texture:remote_image(frame:texture(Frame)),
    assert_pixels(?COLOR_BLACK, Pixels),

    ok = mesh2:destroy(Overlay),
    ok = frame:destroy(Frame),
    ok.

frame_blend_none_disables_test() ->
    ok = run_graphics(),

    {ok, Frame0} = frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = frame:set_depth_test(Frame0, disabled),
    {ok, Frame2} = frame:set_blend_mode(Frame1, alpha),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    {ok, Green} = full_quad(?COLOR_GREEN),
    ok = frame:clear(Frame2, ?COLOR_BLUE),
    ok = frame:draw_mesh2(Frame2, Overlay, triangle_fan, 4),
    {ok, Frame3} = frame:set_blend_mode(Frame2, none),
    ok = frame:draw_mesh2(Frame3, Green, triangle_fan, 4),
    {2, 2, [
        ?COLOR_GREEN, ?COLOR_GREEN,
        ?COLOR_GREEN, ?COLOR_GREEN
    ]} = texture:remote_image(frame:texture(Frame3)),

    ok = mesh2:destroy(Overlay),
    ok = mesh2:destroy(Green),
    ok = frame:destroy(Frame3),
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
