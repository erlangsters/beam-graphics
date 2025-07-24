%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(texture_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(PIXEL_11, ?COLOR_RED).
-define(PIXEL_21, ?COLOR_GREEN).
-define(PIXEL_31, ?COLOR_BLUE).
-define(PIXEL_12, ?COLOR_YELLOW).
-define(PIXEL_22, ?COLOR_CYAN).
-define(PIXEL_32, ?COLOR_MAGENTA).

-define(IMAGE_WIDTH, 3).
-define(IMAGE_HEIGHT, 2).
-define(IMAGE_PIXELS, [
    ?PIXEL_11, ?PIXEL_21, ?PIXEL_31,
    ?PIXEL_12, ?PIXEL_22, ?PIXEL_32
]).

-define(IMAGE, {
    ?IMAGE_WIDTH, ?IMAGE_HEIGHT, ?IMAGE_PIXELS
}).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),

    ok.

texture_test() ->
    % Just a canonical test.
    ok = run_graphics(),

    % XXX: It needs to be updated.

    {ok, Texture} = texture:with_image(?IMAGE, keep_copy),

    ?IMAGE_WIDTH = texture:width(Texture),
    ?IMAGE_HEIGHT = texture:height(Texture),
    ?IMAGE = texture:local_image(Texture),
    ?IMAGE = texture:remote_image(Texture),

    {1, 1, {2, 1, [?PIXEL_11, ?PIXEL_21]}} =
        texture:local_image(Texture, {undefined, 2}, {undefined, 1}),
    {2, 1, {2, 1, [?PIXEL_21, ?PIXEL_31]}} =
        texture:local_image(Texture, {-2, undefined}, {undefined, 1}),
    {2, 2, {2, 1, [?PIXEL_22, ?PIXEL_32]}} =
        texture:local_image(Texture, {-2, undefined}, {-1, undefined}),
    {1, 2, {2, 1, [?PIXEL_12, ?PIXEL_22]}} =
        texture:local_image(Texture, {undefined, 2}, {-1, undefined}),

    {1, 1, {1, 2, [?PIXEL_11, ?PIXEL_12]}} =
        texture:local_image(Texture, {0, 1}, {0, 2}),
    {2, 1, {1, 2, [?PIXEL_21, ?PIXEL_22]}} =
        texture:local_image(Texture, {1, 2}, {0, 2}),
    {3, 1, {1, 2, [?PIXEL_31, ?PIXEL_32]}} =
        texture:local_image(Texture, {2, 3}, {0, 2}),


    {1, 1, ?PIXEL_11} = texture:local_pixel(Texture, 0, 0),
    {2, 1, ?PIXEL_21} = texture:local_pixel(Texture, 1, 0),
    {3, 1, ?PIXEL_31} = texture:local_pixel(Texture, 2, 0),
    {1, 2, ?PIXEL_12} = texture:local_pixel(Texture, 0, 1),
    {2, 2, ?PIXEL_22} = texture:local_pixel(Texture, 1, 1),
    {3, 2, ?PIXEL_32} = texture:local_pixel(Texture, 2, 1),

    {1, 1, ?PIXEL_11} = texture:remote_pixel(Texture, 0, 0),
    {2, 1, ?PIXEL_21} = texture:remote_pixel(Texture, 1, 0),
    {3, 1, ?PIXEL_31} = texture:remote_pixel(Texture, 2, 0),
    {1, 2, ?PIXEL_12} = texture:remote_pixel(Texture, 0, 1),
    {2, 2, ?PIXEL_22} = texture:remote_pixel(Texture, 1, 1),
    {3, 2, ?PIXEL_32} = texture:remote_pixel(Texture, 2, 1),

    NewPixels = [
        ?PIXEL_12, ?PIXEL_31, ?PIXEL_22,
        ?PIXEL_11, ?PIXEL_32, ?PIXEL_21
    ],
    NewImage = {?IMAGE_WIDTH, ?IMAGE_HEIGHT, NewPixels},

    {ok, Texture1} = texture:update_image(Texture, NewImage),
    ?IMAGE_WIDTH = texture:width(Texture),
    ?IMAGE_HEIGHT = texture:height(Texture),
    % NewImage = texture:local_image(Texture),
    NewImage = texture:remote_image(Texture),

    ok = texture:destroy(Texture),

    ok.

texture_with_image_test() ->
    ok = run_graphics(),

    % The first texture is a 3x2 image using linear color space.
    {ok, Texture1} = texture:with_image(?IMAGE),
    {?IMAGE_WIDTH, ?IMAGE_HEIGHT} = texture:size(Texture1),
    linear = texture:color_space(Texture1),
    linear = texture:minification_filter(Texture1),
    linear = texture:magnification_filter(Texture1),
    clamp_to_edge = texture:wrap_mode(Texture1, horizontal),
    clamp_to_edge = texture:wrap_mode(Texture1, vertical),

    {1, 1, ?PIXEL_11} = texture:remote_pixel(Texture1, 0, 0),
    {2, 1, ?PIXEL_21} = texture:remote_pixel(Texture1, 1, 0),
    {3, 1, ?PIXEL_31} = texture:remote_pixel(Texture1, 2, 0),
    {1, 2, ?PIXEL_12} = texture:remote_pixel(Texture1, 0, 1),
    {2, 2, ?PIXEL_22} = texture:remote_pixel(Texture1, 1, 1),
    {3, 2, ?PIXEL_32} = texture:remote_pixel(Texture1, 2, 1),
    out_of_range = texture:remote_pixel(Texture1, 0, 2),
    out_of_range = texture:remote_pixel(Texture1, 1, 2),
    out_of_range = texture:remote_pixel(Texture1, 2, 2),

    ok = texture:destroy(Texture1),

    % The second texture is a 2x3 image using sRGB color space.
    Pixel13 = ?COLOR_BLACK,
    Pixel23 = ?COLOR_WHITE,
    Pixels = [
        ?PIXEL_11, ?PIXEL_21,
        ?PIXEL_12, ?PIXEL_22,
        Pixel13, Pixel23
    ],
    Image = {2, 3, Pixels},

    {ok, Texture2} = texture:with_image(Image, s_rgb),
    {2, 3} = texture:size(Texture2),
    s_rgb = texture:color_space(Texture2),
    linear = texture:minification_filter(Texture2),
    linear = texture:magnification_filter(Texture2),
    clamp_to_edge = texture:wrap_mode(Texture2, horizontal),
    clamp_to_edge = texture:wrap_mode(Texture2, vertical),

    {1, 1, ?PIXEL_11} = texture:remote_pixel(Texture2, 0, 0),
    {2, 1, ?PIXEL_21} = texture:remote_pixel(Texture2, 1, 0),
    out_of_range = texture:remote_pixel(Texture2, 2, 0),
    {1, 2, ?PIXEL_12} = texture:remote_pixel(Texture2, 0, 1),
    {2, 2, ?PIXEL_22} = texture:remote_pixel(Texture2, 1, 1),
    out_of_range = texture:remote_pixel(Texture2, 2, 1),
    {1, 3, Pixel13} = texture:remote_pixel(Texture2, 0, 2),
    {2, 3, Pixel23} = texture:remote_pixel(Texture2, 1, 2),
    out_of_range = texture:remote_pixel(Texture2, 2, 2),

    ok = texture:destroy(Texture2),

    ok.

texture_with_color_test() ->
    ok = run_graphics(),

    % The first texture is a black 3x2 image using linear color space.
    {ok, Texture1} = texture:with_color(?COLOR_BLACK, {3, 2}),
    {3, 2} = texture:size(Texture1),
    linear = texture:color_space(Texture1),
    linear = texture:minification_filter(Texture1),
    linear = texture:magnification_filter(Texture1),
    clamp_to_edge = texture:wrap_mode(Texture1, horizontal),
    clamp_to_edge = texture:wrap_mode(Texture1, vertical),

    {1, 1, ?COLOR_BLACK} = texture:remote_pixel(Texture1, 0, 0),
    {2, 1, ?COLOR_BLACK} = texture:remote_pixel(Texture1, 1, 0),
    {3, 1, ?COLOR_BLACK} = texture:remote_pixel(Texture1, 2, 0),
    {1, 2, ?COLOR_BLACK} = texture:remote_pixel(Texture1, 0, 1),
    {2, 2, ?COLOR_BLACK} = texture:remote_pixel(Texture1, 1, 1),
    {3, 2, ?COLOR_BLACK} = texture:remote_pixel(Texture1, 2, 1),
    out_of_range = texture:remote_pixel(Texture1, 0, 2),
    out_of_range = texture:remote_pixel(Texture1, 1, 2),
    out_of_range = texture:remote_pixel(Texture1, 2, 2),

    ok = texture:destroy(Texture1),

    % The second texture is a white 2x3 image using sRGB color space.

    {ok, Texture2} = texture:with_color(?COLOR_WHITE, {2, 3}, s_rgb),
    {2, 3} = texture:size(Texture2),
    s_rgb = texture:color_space(Texture2),
    linear = texture:minification_filter(Texture2),
    linear = texture:magnification_filter(Texture2),
    clamp_to_edge = texture:wrap_mode(Texture2),

    {1, 1, ?COLOR_WHITE} = texture:remote_pixel(Texture2, 0, 0),
    {2, 1, ?COLOR_WHITE} = texture:remote_pixel(Texture2, 1, 0),
    out_of_range = texture:remote_pixel(Texture2, 2, 0),
    {1, 2, ?COLOR_WHITE} = texture:remote_pixel(Texture2, 0, 1),
    {2, 2, ?COLOR_WHITE} = texture:remote_pixel(Texture2, 1, 1),
    out_of_range = texture:remote_pixel(Texture2, 2, 1),
    {1, 3, ?COLOR_WHITE} = texture:remote_pixel(Texture2, 0, 2),
    {2, 3, ?COLOR_WHITE} = texture:remote_pixel(Texture2, 1, 2),
    out_of_range = texture:remote_pixel(Texture2, 2, 2),

    ok = texture:destroy(Texture2),

    ok.

texture_destroy_test() ->
    ok = run_graphics(),

    {ok, Texture} = texture:with_image(?IMAGE),
    GlTexture = texture:gl_object(Texture),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok = texture:destroy(Texture),

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok.

texture_set_image_test() ->
    ok = run_graphics(),

    % Initially, the texture is a 3x2 image using linear color space.
    {ok, Texture1} = texture:with_image(?IMAGE),
    {?IMAGE_WIDTH, ?IMAGE_HEIGHT} = texture:size(Texture1),
    linear = texture:color_space(Texture1),

    {1, 1, ?PIXEL_11} = texture:remote_pixel(Texture1, 0, 0),
    {2, 1, ?PIXEL_21} = texture:remote_pixel(Texture1, 1, 0),
    {3, 1, ?PIXEL_31} = texture:remote_pixel(Texture1, 2, 0),
    {1, 2, ?PIXEL_12} = texture:remote_pixel(Texture1, 0, 1),
    {2, 2, ?PIXEL_22} = texture:remote_pixel(Texture1, 1, 1),
    {3, 2, ?PIXEL_32} = texture:remote_pixel(Texture1, 2, 1),

    % Then we replace it with a 2x3 image using sRGB color space.
    NewImage = {2, 3,  [
        ?PIXEL_12, ?PIXEL_31,
        ?PIXEL_22, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_21
    ]},
    {ok, Texture2} = texture:set_image(Texture1, NewImage, s_rgb),
    {2, 3} = texture:size(Texture2),
    s_rgb = texture:color_space(Texture2),

    undefined = texture:local_image(Texture2),

    {1, 1, ?PIXEL_12} = texture:remote_pixel(Texture2, 0, 0),
    {2, 1, ?PIXEL_31} = texture:remote_pixel(Texture2, 1, 0),
    {1, 2, ?PIXEL_22} = texture:remote_pixel(Texture2, 0, 1),
    {2, 2, ?PIXEL_32} = texture:remote_pixel(Texture2, 1, 1),
    {1, 3, ?PIXEL_11} = texture:remote_pixel(Texture2, 0, 2),
    {2, 3, ?PIXEL_21} = texture:remote_pixel(Texture2, 1, 2),

    % Finally, we replace it with a 3x3 image, but this time with a local copy.
    {ok, Texture3} = texture:keep_local_copy(Texture2),

    NewImage2 = {3, 3, [
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31,
        ?PIXEL_12, ?PIXEL_22, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31
    ]},
    {ok, Texture4} = texture:set_image(Texture3, NewImage2),
    {3, 3} = texture:size(Texture4),
    linear = texture:color_space(Texture4),

    {3, 3, [
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31,
        ?PIXEL_12, ?PIXEL_22, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31
    ]} = texture:local_image(Texture4),

    {1, 1, ?PIXEL_11} = texture:remote_pixel(Texture4, 0, 0),
    {2, 1, ?PIXEL_21} = texture:remote_pixel(Texture4, 1, 0),
    {3, 1, ?PIXEL_31} = texture:remote_pixel(Texture4, 2, 0),
    {1, 2, ?PIXEL_12} = texture:remote_pixel(Texture4, 0, 1),
    {2, 2, ?PIXEL_22} = texture:remote_pixel(Texture4, 1, 1),
    {3, 2, ?PIXEL_32} = texture:remote_pixel(Texture4, 2, 1),
    {1, 3, ?PIXEL_11} = texture:remote_pixel(Texture4, 0, 2),
    {2, 3, ?PIXEL_21} = texture:remote_pixel(Texture4, 1, 2),
    {3, 3, ?PIXEL_31} = texture:remote_pixel(Texture4, 2, 2),

    ok = texture:destroy(Texture4),

    ok.

texture_resize_test() ->
    % The implementation of resize/x functions use set_image/3 internally, so
    % we cut it short here.
    ok = run_graphics(),

    {ok, Texture1} = texture:with_image(?IMAGE),

    {ok, Texture2} = texture:resize(Texture1, {3, 2}, ?COLOR_BLACK, s_rgb),
    {3, 2} = texture:size(Texture2),
    s_rgb = texture:color_space(Texture2),

    {1, 1, ?COLOR_BLACK} = texture:remote_pixel(Texture2, 0, 0),
    {2, 1, ?COLOR_BLACK} = texture:remote_pixel(Texture2, 1, 0),
    {3, 1, ?COLOR_BLACK} = texture:remote_pixel(Texture2, 2, 0),
    {1, 2, ?COLOR_BLACK} = texture:remote_pixel(Texture2, 0, 1),
    {2, 2, ?COLOR_BLACK} = texture:remote_pixel(Texture2, 1, 1),
    {3, 2, ?COLOR_BLACK} = texture:remote_pixel(Texture2, 2, 1),

    ok = texture:destroy(Texture2),

    ok.

texture_color_space_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_local_image_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_remote_image_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_local_pixel_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_remote_pixel_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_update_image_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_update_pixel_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_from_color_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_from_texture_test() ->
    ok = run_graphics(),

    % XXX: To be implemented.

    ok.

texture_filters_test() ->
    ok = run_graphics(),

    {ok, Texture0} = texture:with_image(?IMAGE),
    GlTexture = texture:gl_object(Texture0),

    linear = texture:minification_filter(Texture0),
    {ok, [?GL_LINEAR]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture1} = texture:set_minification_filter(Texture0, nearest),

    nearest = texture:minification_filter(Texture1),
    {ok, [?GL_NEAREST]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture2} = texture:set_minification_filter(Texture1, nearest_mipmap_nearest),

    nearest_mipmap_nearest = texture:minification_filter(Texture2),
    {ok, [?GL_NEAREST_MIPMAP_NEAREST]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture3} = texture:set_minification_filter(Texture2, nearest_mipmap_linear),
    nearest_mipmap_linear = texture:minification_filter(Texture3),

    {ok, [?GL_NEAREST_MIPMAP_LINEAR]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture4} = texture:set_minification_filter(Texture3, linear_mipmap_nearest),
    linear_mipmap_nearest = texture:minification_filter(Texture4),

    {ok, [?GL_LINEAR_MIPMAP_NEAREST]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture5} = texture:set_minification_filter(Texture4, linear_mipmap_linear),
    linear_mipmap_linear = texture:minification_filter(Texture5),
    {ok, [?GL_LINEAR_MIPMAP_LINEAR]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    ok = texture:destroy(Texture5),

    ok.

texture_magnification_filter_test() ->
    ok = run_graphics(),

    {ok, Texture0} = texture:with_image(?IMAGE),
    GlTexture = texture:gl_object(Texture0),

    linear = texture:magnification_filter(Texture0),
    {ok, [?GL_LINEAR]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_mag_filter, 1)
    end),

    {ok, Texture1} = texture:set_magnification_filter(Texture0, nearest),

    nearest = texture:magnification_filter(Texture1),
    {ok, [?GL_NEAREST]} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_mag_filter, 1)
    end),

    ok = texture:destroy(Texture1),

    ok.

texture_wrap_mode_test() ->
    ok = run_graphics(),

    {ok, Texture0} = texture:with_image(?IMAGE),
    GlTexture = texture:gl_object(Texture0),

    clamp_to_edge = texture:wrap_mode(Texture0, horizontal),
    clamp_to_edge = texture:wrap_mode(Texture0, vertical),
    {?GL_CLAMP_TO_EDGE, ?GL_CLAMP_TO_EDGE} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        {ok, [MinFilter]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_s, 1),
        {ok, [MagFilter]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_t, 1),
        {MinFilter, MagFilter}
    end),

    {ok, Texture1} = texture:set_wrap_mode(Texture0, horizontal, repeat),

    repeat = texture:wrap_mode(Texture1, horizontal),
    clamp_to_edge = texture:wrap_mode(Texture1, vertical),
    {?GL_REPEAT, ?GL_CLAMP_TO_EDGE} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        {ok, [MinFilter]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_s, 1),
        {ok, [MagFilter]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_t, 1),
        {MinFilter, MagFilter}
    end),

    {ok, Texture2} = texture:set_wrap_mode(Texture1, vertical, mirrored_repeat),

    repeat = texture:wrap_mode(Texture2, horizontal),
    mirrored_repeat = texture:wrap_mode(Texture2, vertical),
    {?GL_REPEAT, ?GL_MIRRORED_REPEAT} = graphics_context:execute_commands(fun() ->
        gl:bind_texture(texture_2d, GlTexture),
        {ok, [MinFilter]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_s, 1),
        {ok, [MagFilter]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_t, 1),
        {MinFilter, MagFilter}
    end),

    ok = texture:destroy(Texture2),

    ok.

texture_generate_mipmap_test() ->
    ok = run_graphics(),

    {ok, Texture} = texture:with_image(?IMAGE),
    ok = texture:generate_mipmap(Texture),
    ok = texture:destroy(Texture),

    ok.

texture_gl_object_test() ->
    ok = run_graphics(),

    {ok, Texture} = texture:with_image(?IMAGE),
    GlTexture = texture:gl_object(Texture),

    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok = texture:destroy(Texture),

    ok.

texture_local_copy_test() ->
    ok = run_graphics(),

    {ok, Texture0} = texture:with_image(?IMAGE),

    false = texture:has_local_copy(Texture0),
    undefined = texture:local_image(Texture0),

    {ok, Texture1} = texture:keep_local_copy(Texture0),
    true = texture:has_local_copy(Texture1),
    {3, 2, ?IMAGE} = texture:local_image(Texture1),

    already_local_copy = texture:keep_local_copy(Texture1),

    {ok, Texture2} = texture:release_local_copy(Texture1),
    false = texture:has_local_copy(Texture2),
    undefined = texture:local_image(Texture2),

    no_local_copy = texture:release_local_copy(Texture2),

    ok.
