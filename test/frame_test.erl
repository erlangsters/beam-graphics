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
    Framebuffer = frame:gl_object(Frame3),
    GlTexture = texture:gl_object(frame:texture(Frame3)),
    ok = frame:clear(Frame3, ?COLOR_RED),

    {ok, Frame4} = frame:resize(Frame3, {4, 3}),
    {4, 3} = frame:size(Frame4),
    {4, 3} = texture:size(frame:texture(Frame4)),
    {0, 0, 4, 3} = frame:viewport(Frame4),
    ?VIEW_MATRIX = frame:view_matrix(Frame4),
    ?MATRIX4_IDENTITY = frame:projection_matrix(Frame4),
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
