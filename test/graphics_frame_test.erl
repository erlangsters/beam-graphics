%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_frame_test).
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
    graphics_view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).

frame_test() ->
    ok = run_graphics(),

    {ok, Frame} = graphics_frame:with_size(?FRAME_SIZE),
    ?FRAME_SIZE = graphics_frame:size(Frame),
    {0, 0, ?FRAME_WIDTH, ?FRAME_HEIGHT} = graphics_frame:viewport(Frame),
    ?MATRIX4_IDENTITY = graphics_frame:view_matrix(Frame),
    DefaultProjection = default_projection(?FRAME_WIDTH, ?FRAME_HEIGHT),
    DefaultProjection = graphics_frame:projection_matrix(Frame),
    none = graphics_frame:blend_mode(Frame),
    enabled = graphics_frame:depth_test(Frame),

    Texture = graphics_frame:texture(Frame),
    ?FRAME_SIZE = graphics_texture:size(Texture),
    linear = graphics_texture:color_space(Texture),
    linear = graphics_texture:minification_filter(Texture),
    linear = graphics_texture:magnification_filter(Texture),
    clamp_to_edge = graphics_texture:wrap_mode(Texture, horizontal),
    clamp_to_edge = graphics_texture:wrap_mode(Texture, vertical),
    undefined = graphics_texture:local_image(Texture),
    false = graphics_texture:has_local_copy(Texture),
    ?BLACK_IMAGE = graphics_texture:remote_image(Texture),

    ok = graphics_frame:destroy(Frame),
    ok.

frame_with_size_test() ->
    ok = run_graphics(),

    {ok, Frame1} = graphics_frame:with_size({1, 1}),
    {1, 1} = graphics_frame:size(Frame1),
    {0, 0, 1, 1} = graphics_frame:viewport(Frame1),
    {1, 1, [?COLOR_BLACK]} = graphics_texture:remote_image(graphics_frame:texture(Frame1)),
    ok = graphics_frame:destroy(Frame1),

    ?assertError(function_clause, graphics_frame:with_size({0, 1})),
    ?assertError(function_clause, graphics_frame:with_size({1, 0})),

    ok.

frame_destroy_test() ->
    ok = run_graphics(),

    {ok, Frame} = graphics_frame:with_size(?FRAME_SIZE),
    Framebuffer = graphics_frame:gl_object(Frame),
    GlTexture = graphics_texture:gl_object(graphics_frame:texture(Frame)),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_framebuffer(Framebuffer)
    end),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok = graphics_frame:destroy(Frame),

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_framebuffer(Framebuffer)
    end),
    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok.

frame_resize_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = graphics_frame:set_view_matrix(Frame0, ?VIEW_MATRIX),
    {ok, Frame2} = graphics_frame:set_viewport(Frame1, {0, 0, 1, 1}),
    {ok, Frame3} = graphics_frame:set_projection_matrix(Frame2, ?MATRIX4_IDENTITY),
    {ok, Frame3a} = graphics_frame:set_blend_mode(Frame3, alpha),
    {ok, Frame3b} = graphics_frame:set_depth_test(Frame3a, disabled),
    Framebuffer = graphics_frame:gl_object(Frame3b),
    GlTexture = graphics_texture:gl_object(graphics_frame:texture(Frame3b)),
    ok = graphics_frame:clear(Frame3b, ?COLOR_RED),

    {ok, Frame4} = graphics_frame:resize(Frame3b, {4, 3}),
    {4, 3} = graphics_frame:size(Frame4),
    {4, 3} = graphics_texture:size(graphics_frame:texture(Frame4)),
    {0, 0, 4, 3} = graphics_frame:viewport(Frame4),
    ?VIEW_MATRIX = graphics_frame:view_matrix(Frame4),
    ?MATRIX4_IDENTITY = graphics_frame:projection_matrix(Frame4),
    alpha = graphics_frame:blend_mode(Frame4),
    disabled = graphics_frame:depth_test(Frame4),
    Framebuffer = graphics_frame:gl_object(Frame4),
    GlTexture = graphics_texture:gl_object(graphics_frame:texture(Frame4)),
    {1, 1, ?COLOR_BLACK} = graphics_texture:remote_pixel(graphics_frame:texture(Frame4), 0, 0),
    {4, 3, ?COLOR_BLACK} = graphics_texture:remote_pixel(graphics_frame:texture(Frame4), -1, -1),

    ?assertError(function_clause, graphics_frame:resize(Frame4, {0, 1})),
    ?assertError(function_clause, graphics_frame:resize(Frame4, {1, 0})),

    ok = graphics_frame:destroy(Frame4),
    ok.

frame_viewport_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {0, 0, ?FRAME_WIDTH, ?FRAME_HEIGHT} = graphics_frame:viewport(Frame0),

    {ok, Frame1} = graphics_frame:set_viewport(Frame0, {1, 0, 1, 2}),
    {0, 0, ?FRAME_WIDTH, ?FRAME_HEIGHT} = graphics_frame:viewport(Frame0),
    {1, 0, 1, 2} = graphics_frame:viewport(Frame1),

    ok = graphics_frame:destroy(Frame1),
    ok.

frame_view_projection_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    DefaultProjection = default_projection(?FRAME_WIDTH, ?FRAME_HEIGHT),
    Identity = ?MATRIX4_IDENTITY,
    Identity = graphics_frame:view_matrix(Frame0),
    DefaultProjection = graphics_frame:projection_matrix(Frame0),

    {ok, Frame1} = graphics_frame:set_view_matrix(Frame0, ?VIEW_MATRIX),
    ?MATRIX4_IDENTITY = graphics_frame:view_matrix(Frame0),
    ?VIEW_MATRIX = graphics_frame:view_matrix(Frame1),
    DefaultProjection = graphics_frame:projection_matrix(Frame1),

    {ok, Frame2} = graphics_frame:set_projection_matrix(Frame1, ?MATRIX4_IDENTITY),
    ?VIEW_MATRIX = graphics_frame:view_matrix(Frame2),
    DefaultProjection = graphics_frame:projection_matrix(Frame1),
    ?MATRIX4_IDENTITY = graphics_frame:projection_matrix(Frame2),

    ok = graphics_frame:destroy(Frame2),
    ok.

frame_clear_test() ->
    ok = run_graphics(),

    {ok, Frame} = graphics_frame:with_size(?FRAME_SIZE),
    ?BLACK_IMAGE = graphics_texture:remote_image(graphics_frame:texture(Frame)),

    ok = graphics_frame:clear(Frame, ?COLOR_RED),
    ?RED_IMAGE = graphics_texture:remote_image(graphics_frame:texture(Frame)),

    ok = graphics_frame:clear(Frame, ?COLOR_WHITE),
    {2, 2, [
        ?COLOR_WHITE, ?COLOR_WHITE,
        ?COLOR_WHITE, ?COLOR_WHITE
    ]} = graphics_texture:remote_image(graphics_frame:texture(Frame)),

    ok = graphics_frame:destroy(Frame),
    ok.

frame_draw_mesh2_test() ->
    ok = run_graphics(),

    {ok, Frame} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Mesh} = graphics_mesh2:with_vertices([
        {{0.0, 0.0}, ?COLOR_RED, 0.0, 0.0},
        {{2.0, 0.0}, ?COLOR_RED, 1.0, 0.0},
        {{2.0, 2.0}, ?COLOR_RED, 1.0, 1.0},
        {{0.0, 2.0}, ?COLOR_RED, 0.0, 1.0}
    ]),
    ok = graphics_frame:clear(Frame, ?COLOR_BLACK),
    ok = graphics_frame:draw_mesh2(Frame, Mesh, triangle_fan, 4),
    ?RED_IMAGE = graphics_texture:remote_image(graphics_frame:texture(Frame)),

    ok = graphics_mesh2:destroy(Mesh),
    ok = graphics_frame:destroy(Frame),
    ok.

frame_gl_object_test() ->
    ok = run_graphics(),

    {ok, Frame} = graphics_frame:with_size(?FRAME_SIZE),
    Framebuffer = graphics_frame:gl_object(Frame),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_framebuffer(Framebuffer)
    end),

    ok = graphics_frame:destroy(Frame),
    ok.

frame_blend_depth_term_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    none = graphics_frame:blend_mode(Frame0),
    enabled = graphics_frame:depth_test(Frame0),

    {ok, Frame1} = graphics_frame:set_blend_mode(Frame0, alpha),
    none = graphics_frame:blend_mode(Frame0),
    alpha = graphics_frame:blend_mode(Frame1),
    enabled = graphics_frame:depth_test(Frame1),

    {ok, Frame2} = graphics_frame:set_depth_test(Frame1, disabled),
    enabled = graphics_frame:depth_test(Frame1),
    disabled = graphics_frame:depth_test(Frame2),
    alpha = graphics_frame:blend_mode(Frame2),

    {ok, Frame3} = graphics_frame:set_blend_mode(Frame2, add),
    add = graphics_frame:blend_mode(Frame3),
    {ok, Frame4} = graphics_frame:set_blend_mode(Frame3, multiply),
    multiply = graphics_frame:blend_mode(Frame4),
    {ok, Frame5} = graphics_frame:set_blend_mode(Frame4, none),
    none = graphics_frame:blend_mode(Frame5),

    ?assertError(function_clause, graphics_frame:set_blend_mode(Frame5, replace)),
    ?assertError(function_clause, graphics_frame:set_depth_test(Frame5, on)),

    ok = graphics_frame:destroy(Frame5),
    ok.

frame_depth_keeps_first_test() ->
    ok = run_graphics(),

    {ok, Frame} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Red} = full_quad(?COLOR_RED),
    {ok, Blue} = full_quad(?COLOR_BLUE),
    ok = graphics_frame:clear(Frame, ?COLOR_BLACK),
    ok = graphics_frame:draw_mesh2(Frame, Red, triangle_fan, 4),
    ok = graphics_frame:draw_mesh2(Frame, Blue, triangle_fan, 4),
    assert_image(?RED_IMAGE, graphics_texture:remote_image(graphics_frame:texture(Frame))),

    ok = graphics_mesh2:destroy(Red),
    ok = graphics_mesh2:destroy(Blue),
    ok = graphics_frame:destroy(Frame),
    ok.

frame_depth_disabled_replace_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Frame} = graphics_frame:set_depth_test(Frame0, disabled),
    {ok, Red} = full_quad(?COLOR_RED),
    {ok, Blue} = full_quad(?COLOR_BLUE),
    ok = graphics_frame:clear(Frame, ?COLOR_BLACK),
    ok = graphics_frame:draw_mesh2(Frame, Red, triangle_fan, 4),
    ok = graphics_frame:draw_mesh2(Frame, Blue, triangle_fan, 4),
    {2, 2, [
        ?COLOR_BLUE, ?COLOR_BLUE,
        ?COLOR_BLUE, ?COLOR_BLUE
    ]} = graphics_texture:remote_image(graphics_frame:texture(Frame)),

    ok = graphics_mesh2:destroy(Red),
    ok = graphics_mesh2:destroy(Blue),
    ok = graphics_frame:destroy(Frame),
    ok.

frame_blend_alpha_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = graphics_frame:set_depth_test(Frame0, disabled),
    {ok, Frame} = graphics_frame:set_blend_mode(Frame1, alpha),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    ok = graphics_frame:clear(Frame, ?COLOR_BLUE),
    ok = graphics_frame:draw_mesh2(Frame, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = graphics_texture:remote_image(graphics_frame:texture(Frame)),
    assert_pixels({0.5, 0.0, 0.5, 0.75}, Pixels),

    ok = graphics_mesh2:destroy(Overlay),
    ok = graphics_frame:destroy(Frame),
    ok.

frame_blend_add_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = graphics_frame:set_depth_test(Frame0, disabled),
    {ok, Frame} = graphics_frame:set_blend_mode(Frame1, add),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    ok = graphics_frame:clear(Frame, ?COLOR_BLUE),
    ok = graphics_frame:draw_mesh2(Frame, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = graphics_texture:remote_image(graphics_frame:texture(Frame)),
    assert_pixels({0.5, 0.0, 1.0, 1.0}, Pixels),

    ok = graphics_mesh2:destroy(Overlay),
    ok = graphics_frame:destroy(Frame),
    ok.

frame_blend_multiply_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = graphics_frame:set_depth_test(Frame0, disabled),
    {ok, Frame} = graphics_frame:set_blend_mode(Frame1, multiply),
    {ok, Overlay} = full_quad(?COLOR_RED),
    ok = graphics_frame:clear(Frame, ?COLOR_BLUE),
    ok = graphics_frame:draw_mesh2(Frame, Overlay, triangle_fan, 4),
    {2, 2, Pixels} = graphics_texture:remote_image(graphics_frame:texture(Frame)),
    assert_pixels(?COLOR_BLACK, Pixels),

    ok = graphics_mesh2:destroy(Overlay),
    ok = graphics_frame:destroy(Frame),
    ok.

frame_blend_none_disables_test() ->
    ok = run_graphics(),

    {ok, Frame0} = graphics_frame:with_size(?FRAME_SIZE),
    {ok, Frame1} = graphics_frame:set_depth_test(Frame0, disabled),
    {ok, Frame2} = graphics_frame:set_blend_mode(Frame1, alpha),
    {ok, Overlay} = full_quad({1.0, 0.0, 0.0, 0.5}),
    {ok, Green} = full_quad(?COLOR_GREEN),
    ok = graphics_frame:clear(Frame2, ?COLOR_BLUE),
    ok = graphics_frame:draw_mesh2(Frame2, Overlay, triangle_fan, 4),
    {ok, Frame3} = graphics_frame:set_blend_mode(Frame2, none),
    ok = graphics_frame:draw_mesh2(Frame3, Green, triangle_fan, 4),
    {2, 2, [
        ?COLOR_GREEN, ?COLOR_GREEN,
        ?COLOR_GREEN, ?COLOR_GREEN
    ]} = graphics_texture:remote_image(graphics_frame:texture(Frame3)),

    ok = graphics_mesh2:destroy(Overlay),
    ok = graphics_mesh2:destroy(Green),
    ok = graphics_frame:destroy(Frame3),
    ok.

full_quad(Color) ->
    graphics_mesh2:with_vertices([
        {{0.0, 0.0}, Color, 0.0, 0.0},
        {{2.0, 0.0}, Color, 1.0, 0.0},
        {{2.0, 2.0}, Color, 1.0, 1.0},
        {{0.0, 2.0}, Color, 0.0, 1.0}
    ]).

assert_image(Expected, Expected) ->
    ok.

assert_pixels(Expected, Pixels) ->
    lists:foreach(fun(Pixel) ->
        true = graphics_color:is_equal_to(Expected, Pixel, 1.0 / 255.0)
    end, Pixels).
