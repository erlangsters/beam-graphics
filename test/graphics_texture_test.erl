%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_texture_test).
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
-define(IMAGE, {?IMAGE_WIDTH, ?IMAGE_HEIGHT, ?IMAGE_PIXELS}).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

texture_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_image(?IMAGE),

    {?IMAGE_WIDTH, ?IMAGE_HEIGHT} = graphics_texture:size(Texture),
    linear = graphics_texture:color_space(Texture),
    undefined = graphics_texture:local_image(Texture),
    false = graphics_texture:has_local_copy(Texture),
    ?IMAGE = graphics_texture:remote_image(Texture),

    ok = graphics_texture:destroy(Texture),

    ok.

texture_with_image_test() ->
    ok = run_graphics(),

    {ok, Texture1} = graphics_texture:with_image(?IMAGE),
    {?IMAGE_WIDTH, ?IMAGE_HEIGHT} = graphics_texture:size(Texture1),
    linear = graphics_texture:color_space(Texture1),
    linear = graphics_texture:minification_filter(Texture1),
    linear = graphics_texture:magnification_filter(Texture1),
    clamp_to_edge = graphics_texture:wrap_mode(Texture1, horizontal),
    clamp_to_edge = graphics_texture:wrap_mode(Texture1, vertical),
    undefined = graphics_texture:local_image(Texture1),
    false = graphics_texture:has_local_copy(Texture1),
    ?IMAGE = graphics_texture:remote_image(Texture1),

    {1, 1, ?PIXEL_11} = graphics_texture:remote_pixel(Texture1, 0, 0),
    {2, 1, ?PIXEL_21} = graphics_texture:remote_pixel(Texture1, 1, 0),
    {3, 1, ?PIXEL_31} = graphics_texture:remote_pixel(Texture1, 2, 0),
    {1, 2, ?PIXEL_12} = graphics_texture:remote_pixel(Texture1, 0, 1),
    {2, 2, ?PIXEL_22} = graphics_texture:remote_pixel(Texture1, 1, 1),
    {3, 2, ?PIXEL_32} = graphics_texture:remote_pixel(Texture1, 2, 1),
    {3, 2, ?PIXEL_32} = graphics_texture:remote_pixel(Texture1, -1, -1),
    out_of_range = graphics_texture:remote_pixel(Texture1, 0, 2),
    out_of_range = graphics_texture:remote_pixel(Texture1, 3, 0),

    ok = graphics_texture:destroy(Texture1),

    Pixel13 = ?COLOR_BLACK,
    Pixel23 = ?COLOR_WHITE,
    ImageSrgb = {2, 3, [
        ?PIXEL_11, ?PIXEL_21,
        ?PIXEL_12, ?PIXEL_22,
        Pixel13, Pixel23
    ]},
    {ok, Texture2} = graphics_texture:with_image(ImageSrgb, srgb),
    {2, 3} = graphics_texture:size(Texture2),
    srgb = graphics_texture:color_space(Texture2),
    ImageSrgb = graphics_texture:remote_image(Texture2),
    {1, 3, Pixel13} = graphics_texture:remote_pixel(Texture2, 0, 2),
    {2, 3, Pixel23} = graphics_texture:remote_pixel(Texture2, 1, 2),
    out_of_range = graphics_texture:remote_pixel(Texture2, 2, 0),

    ok = graphics_texture:destroy(Texture2),

    {ok, Texture3} = graphics_texture:with_image(?IMAGE, linear, keep_copy),
    true = graphics_texture:has_local_copy(Texture3),
    ?IMAGE = graphics_texture:local_image(Texture3),
    ?IMAGE = graphics_texture:remote_image(Texture3),

    ok = graphics_texture:destroy(Texture3),

    ok.

texture_with_color_test() ->
    ok = run_graphics(),

    {ok, Texture1} = graphics_texture:with_color(?COLOR_BLACK, {3, 2}),
    {3, 2} = graphics_texture:size(Texture1),
    linear = graphics_texture:color_space(Texture1),
    {1, 1, ?COLOR_BLACK} = graphics_texture:remote_pixel(Texture1, 0, 0),
    {3, 2, ?COLOR_BLACK} = graphics_texture:remote_pixel(Texture1, 2, 1),
    out_of_range = graphics_texture:remote_pixel(Texture1, 0, 2),

    ok = graphics_texture:destroy(Texture1),

    {ok, Texture2} = graphics_texture:with_color(?COLOR_WHITE, {2, 3}, srgb, keep_copy),
    {2, 3} = graphics_texture:size(Texture2),
    srgb = graphics_texture:color_space(Texture2),
    true = graphics_texture:has_local_copy(Texture2),
    {2, 3, [
        ?COLOR_WHITE, ?COLOR_WHITE,
        ?COLOR_WHITE, ?COLOR_WHITE,
        ?COLOR_WHITE, ?COLOR_WHITE
    ]} = graphics_texture:local_image(Texture2),
    {1, 1, ?COLOR_WHITE} = graphics_texture:remote_pixel(Texture2, 0, 0),
    {2, 3, ?COLOR_WHITE} = graphics_texture:remote_pixel(Texture2, 1, 2),

    ok = graphics_texture:destroy(Texture2),

    ok.

texture_destroy_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_image(?IMAGE),
    GlTexture = graphics_texture:gl_object(Texture),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok = graphics_texture:destroy(Texture),

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_texture(GlTexture)
    end),

    ok.

texture_set_image_test() ->
    ok = run_graphics(),

    {ok, Texture1} = graphics_texture:with_image(?IMAGE, srgb),
    Buffer = graphics_texture:gl_object(Texture1),
    {ok, Texture1F} = graphics_texture:set_minification_filter(Texture1, nearest),
    {ok, Texture1W} = graphics_texture:set_wrap_mode(Texture1F, horizontal, repeat),

    NewImage = {2, 3, [
        ?PIXEL_12, ?PIXEL_31,
        ?PIXEL_22, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_21
    ]},
    {ok, Texture2} = graphics_texture:set_image(Texture1W, NewImage),
    {2, 3} = graphics_texture:size(Texture2),
    srgb = graphics_texture:color_space(Texture2),
    nearest = graphics_texture:minification_filter(Texture2),
    repeat = graphics_texture:wrap_mode(Texture2, horizontal),
    clamp_to_edge = graphics_texture:wrap_mode(Texture2, vertical),
    undefined = graphics_texture:local_image(Texture2),
    Buffer = graphics_texture:gl_object(Texture2),
    NewImage = graphics_texture:remote_image(Texture2),

    {ok, Texture3} = graphics_texture:keep_local_copy(Texture2),
    NewImage2 = {3, 3, [
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31,
        ?PIXEL_12, ?PIXEL_22, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31
    ]},
    {ok, Texture4} = graphics_texture:set_image(Texture3, NewImage2, linear),
    {3, 3} = graphics_texture:size(Texture4),
    linear = graphics_texture:color_space(Texture4),
    nearest = graphics_texture:minification_filter(Texture4),
    true = graphics_texture:has_local_copy(Texture4),
    NewImage2 = graphics_texture:local_image(Texture4),
    NewImage2 = graphics_texture:remote_image(Texture4),
    Buffer = graphics_texture:gl_object(Texture4),

    ok = graphics_texture:destroy(Texture4),

    ok.

texture_resize_test() ->
    ok = run_graphics(),

    {ok, Texture1} = graphics_texture:with_image(?IMAGE, srgb, keep_copy),
    Buffer = graphics_texture:gl_object(Texture1),
    {ok, Texture1F} = graphics_texture:set_magnification_filter(Texture1, nearest),

    {ok, Texture2} = graphics_texture:resize(Texture1F, {2, 4}),
    {2, 4} = graphics_texture:size(Texture2),
    srgb = graphics_texture:color_space(Texture2),
    nearest = graphics_texture:magnification_filter(Texture2),
    linear = graphics_texture:minification_filter(Texture2),
    Buffer = graphics_texture:gl_object(Texture2),
    true = graphics_texture:has_local_copy(Texture2),
    BlackImage = {2, 4, [
        ?COLOR_BLACK, ?COLOR_BLACK,
        ?COLOR_BLACK, ?COLOR_BLACK,
        ?COLOR_BLACK, ?COLOR_BLACK,
        ?COLOR_BLACK, ?COLOR_BLACK
    ]},
    BlackImage = graphics_texture:local_image(Texture2),
    {1, 1, ?COLOR_BLACK} = graphics_texture:remote_pixel(Texture2, 0, 0),
    {2, 4, ?COLOR_BLACK} = graphics_texture:remote_pixel(Texture2, 1, 3),

    {ok, Texture3} = graphics_texture:resize(Texture2, {1, 1}, ?COLOR_WHITE),
    {1, 1} = graphics_texture:size(Texture3),
    srgb = graphics_texture:color_space(Texture3),
    {1, 1, [?COLOR_WHITE]} = graphics_texture:local_image(Texture3),
    {1, 1, ?COLOR_WHITE} = graphics_texture:remote_pixel(Texture3, 0, 0),
    Buffer = graphics_texture:gl_object(Texture3),

    ok = graphics_texture:destroy(Texture3),

    ok.

texture_local_image_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_image(?IMAGE),
    undefined = graphics_texture:local_image(Texture),
    undefined = graphics_texture:local_pixel(Texture, 0, 0),
    undefined = graphics_texture:local_image(Texture, {undefined, 1}, {undefined, 1}),

    {ok, Texture1} = graphics_texture:with_image(?IMAGE, linear, no_copy),
    undefined = graphics_texture:local_image(Texture1),

    {ok, Texture2} = graphics_texture:with_image(?IMAGE, linear, keep_copy),
    ?IMAGE = graphics_texture:local_image(Texture2),

    {1, 1, ?PIXEL_11} = graphics_texture:local_pixel(Texture2, 0, 0),
    {2, 1, ?PIXEL_21} = graphics_texture:local_pixel(Texture2, 1, 0),
    {3, 2, ?PIXEL_32} = graphics_texture:local_pixel(Texture2, -1, -1),
    out_of_range = graphics_texture:local_pixel(Texture2, 3, 0),
    out_of_range = graphics_texture:local_pixel(Texture2, 0, 2),

    {1, 1, {2, 1, [?PIXEL_11, ?PIXEL_21]}} =
        graphics_texture:local_image(Texture2, {undefined, 2}, {undefined, 1}),
    {2, 1, {2, 1, [?PIXEL_21, ?PIXEL_31]}} =
        graphics_texture:local_image(Texture2, {-2, undefined}, {undefined, 1}),
    {2, 2, {2, 1, [?PIXEL_22, ?PIXEL_32]}} =
        graphics_texture:local_image(Texture2, {-2, undefined}, {-1, undefined}),
    {1, 2, {2, 1, [?PIXEL_12, ?PIXEL_22]}} =
        graphics_texture:local_image(Texture2, {undefined, 2}, {-1, undefined}),
    {1, 1, {1, 2, [?PIXEL_11, ?PIXEL_12]}} =
        graphics_texture:local_image(Texture2, {0, 1}, {0, 2}),
    {2, 1, {1, 1, [?PIXEL_21]}} =
        graphics_texture:local_image(Texture2, {1, -1}, {undefined, 1}),
    no_range = graphics_texture:local_image(Texture2, {1, 1}, {undefined, 1}),

    ok = graphics_texture:destroy(Texture),
    ok = graphics_texture:destroy(Texture1),
    ok = graphics_texture:destroy(Texture2),

    ok.

texture_remote_image_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_image(?IMAGE),
    ?IMAGE = graphics_texture:remote_image(Texture),

    {1, 1, ?PIXEL_11} = graphics_texture:remote_pixel(Texture, 0, 0),
    {3, 2, ?PIXEL_32} = graphics_texture:remote_pixel(Texture, -1, -1),
    out_of_range = graphics_texture:remote_pixel(Texture, 3, 0),

    {1, 1, {2, 1, [?PIXEL_11, ?PIXEL_21]}} =
        graphics_texture:remote_image(Texture, {undefined, 2}, {undefined, 1}),
    {2, 2, {2, 1, [?PIXEL_22, ?PIXEL_32]}} =
        graphics_texture:remote_image(Texture, {-2, undefined}, {-1, undefined}),
    no_range = graphics_texture:remote_image(Texture, {1, 1}, {0, 1}),

    ok = graphics_texture:destroy(Texture),

    ok.

texture_update_image_test() ->
    ok = run_graphics(),

    {ok, TextureNoCopy} = graphics_texture:with_image(?IMAGE),
    NewImage = {3, 2, [
        ?PIXEL_12, ?PIXEL_31, ?PIXEL_22,
        ?PIXEL_11, ?PIXEL_32, ?PIXEL_21
    ]},
    {ok, TextureNoCopy1} = graphics_texture:update_image(TextureNoCopy, NewImage),
    {3, 2} = graphics_texture:size(TextureNoCopy1),
    linear = graphics_texture:color_space(TextureNoCopy1),
    undefined = graphics_texture:local_image(TextureNoCopy1),
    NewImage = graphics_texture:remote_image(TextureNoCopy1),

    out_of_range = graphics_texture:update_image(TextureNoCopy1, {4, 1, [
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_31, ?PIXEL_12
    ]}),

    Patch = {2, 1, [?PIXEL_11, ?PIXEL_32]},
    {ok, TextureNoCopy2} = graphics_texture:update_image(TextureNoCopy1, Patch, 1, 0),
    {3, 2, [
        ?PIXEL_12, ?PIXEL_11, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_32, ?PIXEL_21
    ]} = graphics_texture:remote_image(TextureNoCopy2),

    {ok, TextureNoCopy3} = graphics_texture:update_pixel(TextureNoCopy2, ?PIXEL_31, 0, 0),
    {1, 1, ?PIXEL_31} = graphics_texture:remote_pixel(TextureNoCopy3, 0, 0),
    {ok, TextureNoCopy4} = graphics_texture:update_pixel(TextureNoCopy3, ?PIXEL_12, -1, -1),
    {3, 2, ?PIXEL_12} = graphics_texture:remote_pixel(TextureNoCopy4, -1, -1),
    out_of_range = graphics_texture:update_pixel(TextureNoCopy4, ?PIXEL_11, 3, 0),
    out_of_range = graphics_texture:update_image(TextureNoCopy4, {2, 2, [
        ?PIXEL_11, ?PIXEL_21, ?PIXEL_12, ?PIXEL_22
    ]}, 2, 0),

    ok = graphics_texture:destroy(TextureNoCopy4),

    {ok, TextureKeep} = graphics_texture:with_image(?IMAGE, linear, keep_copy),
    {ok, TextureKeep1} = graphics_texture:update_image(TextureKeep, NewImage),
    NewImage = graphics_texture:local_image(TextureKeep1),
    NewImage = graphics_texture:remote_image(TextureKeep1),

    {ok, TextureKeep2} = graphics_texture:update_image(TextureKeep1, Patch, 1, 0),
    Expected = {3, 2, [
        ?PIXEL_12, ?PIXEL_11, ?PIXEL_32,
        ?PIXEL_11, ?PIXEL_32, ?PIXEL_21
    ]},
    Expected = graphics_texture:local_image(TextureKeep2),
    Expected = graphics_texture:remote_image(TextureKeep2),

    {ok, TextureKeep3} = graphics_texture:update_pixel(TextureKeep2, ?PIXEL_31, 0, 1),
    {1, 2, ?PIXEL_31} = graphics_texture:local_pixel(TextureKeep3, 0, 1),
    {1, 2, ?PIXEL_31} = graphics_texture:remote_pixel(TextureKeep3, 0, 1),

    ok = graphics_texture:destroy(TextureKeep3),

    ok.

texture_update_from_color_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_image(?IMAGE, linear, keep_copy),
    {ok, Texture1} = graphics_texture:update_from_color(Texture, ?COLOR_WHITE),
    {3, 2} = graphics_texture:size(Texture1),
    linear = graphics_texture:color_space(Texture1),
    WhiteImage = {3, 2, [
        ?COLOR_WHITE, ?COLOR_WHITE, ?COLOR_WHITE,
        ?COLOR_WHITE, ?COLOR_WHITE, ?COLOR_WHITE
    ]},
    WhiteImage = graphics_texture:local_image(Texture1),
    {1, 1, ?COLOR_WHITE} = graphics_texture:remote_pixel(Texture1, 0, 0),
    {3, 2, ?COLOR_WHITE} = graphics_texture:remote_pixel(Texture1, 2, 1),

    ok = graphics_texture:destroy(Texture1),

    ok.

texture_update_from_texture_test() ->
    ok = run_graphics(),

    {ok, Dest} = graphics_texture:with_color(?COLOR_BLACK, {3, 2}, linear, keep_copy),
    SrcImage = {2, 1, [?PIXEL_11, ?PIXEL_22]},
    {ok, Src} = graphics_texture:with_image(SrcImage),

    {ok, Dest1} = graphics_texture:update_from_texture(Dest, Src),
    {3, 2, [
        ?PIXEL_11, ?PIXEL_22, ?COLOR_BLACK,
        ?COLOR_BLACK, ?COLOR_BLACK, ?COLOR_BLACK
    ]} = graphics_texture:local_image(Dest1),
    {1, 1, ?PIXEL_11} = graphics_texture:remote_pixel(Dest1, 0, 0),
    {2, 1, ?PIXEL_22} = graphics_texture:remote_pixel(Dest1, 1, 0),
    {3, 2, ?COLOR_BLACK} = graphics_texture:remote_pixel(Dest1, 2, 1),

    {ok, Dest2} = graphics_texture:update_from_texture(Dest1, Src, 1, 1),
    {3, 2, [
        ?PIXEL_11, ?PIXEL_22, ?COLOR_BLACK,
        ?COLOR_BLACK, ?PIXEL_11, ?PIXEL_22
    ]} = graphics_texture:local_image(Dest2),
    {2, 2, ?PIXEL_11} = graphics_texture:remote_pixel(Dest2, 1, 1),
    {3, 2, ?PIXEL_22} = graphics_texture:remote_pixel(Dest2, 2, 1),

    out_of_range = graphics_texture:update_from_texture(Dest2, Src, 2, 0),

    {ok, FullSrc} = graphics_texture:with_image(?IMAGE),
    {ok, Dest3} = graphics_texture:update_from_texture(Dest2, FullSrc),
    ?IMAGE = graphics_texture:local_image(Dest3),
    ?IMAGE = graphics_texture:remote_image(Dest3),
    linear = graphics_texture:color_space(Dest3),

    ok = graphics_texture:destroy(Dest3),
    ok = graphics_texture:destroy(Src),
    ok = graphics_texture:destroy(FullSrc),

    ok.

texture_filters_test() ->
    ok = run_graphics(),

    {ok, Texture0} = graphics_texture:with_image(?IMAGE),
    GlTexture = graphics_texture:gl_object(Texture0),

    linear = graphics_texture:minification_filter(Texture0),
    {ok, [?GL_LINEAR]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture1} = graphics_texture:set_minification_filter(Texture0, nearest),
    nearest = graphics_texture:minification_filter(Texture1),
    {ok, [?GL_NEAREST]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture2} = graphics_texture:set_minification_filter(
        Texture1, nearest_mipmap_nearest
    ),
    nearest_mipmap_nearest = graphics_texture:minification_filter(Texture2),
    {ok, [?GL_NEAREST_MIPMAP_NEAREST]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture3} = graphics_texture:set_minification_filter(
        Texture2, nearest_mipmap_linear
    ),
    nearest_mipmap_linear = graphics_texture:minification_filter(Texture3),
    {ok, [?GL_NEAREST_MIPMAP_LINEAR]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture4} = graphics_texture:set_minification_filter(
        Texture3, linear_mipmap_nearest
    ),
    linear_mipmap_nearest = graphics_texture:minification_filter(Texture4),
    {ok, [?GL_LINEAR_MIPMAP_NEAREST]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    {ok, Texture5} = graphics_texture:set_minification_filter(
        Texture4, linear_mipmap_linear
    ),
    linear_mipmap_linear = graphics_texture:minification_filter(Texture5),
    {ok, [?GL_LINEAR_MIPMAP_LINEAR]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_min_filter, 1)
    end),

    ok = graphics_texture:destroy(Texture5),

    ok.

texture_magnification_filter_test() ->
    ok = run_graphics(),

    {ok, Texture0} = graphics_texture:with_image(?IMAGE),
    GlTexture = graphics_texture:gl_object(Texture0),

    linear = graphics_texture:magnification_filter(Texture0),
    {ok, [?GL_LINEAR]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_mag_filter, 1)
    end),

    {ok, Texture1} = graphics_texture:set_magnification_filter(Texture0, nearest),
    nearest = graphics_texture:magnification_filter(Texture1),
    {ok, [?GL_NEAREST]} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        gl:get_tex_parameter(i, texture_2d, texture_mag_filter, 1)
    end),

    ok = graphics_texture:destroy(Texture1),

    ok.

texture_wrap_mode_test() ->
    ok = run_graphics(),

    {ok, Texture0} = graphics_texture:with_image(?IMAGE),
    GlTexture = graphics_texture:gl_object(Texture0),

    clamp_to_edge = graphics_texture:wrap_mode(Texture0, horizontal),
    clamp_to_edge = graphics_texture:wrap_mode(Texture0, vertical),
    {?GL_CLAMP_TO_EDGE, ?GL_CLAMP_TO_EDGE} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        {ok, [WrapS]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_s, 1),
        {ok, [WrapT]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_t, 1),
        {WrapS, WrapT}
    end),

    {ok, Texture1} = graphics_texture:set_wrap_mode(Texture0, horizontal, repeat),
    repeat = graphics_texture:wrap_mode(Texture1, horizontal),
    clamp_to_edge = graphics_texture:wrap_mode(Texture1, vertical),
    {?GL_REPEAT, ?GL_CLAMP_TO_EDGE} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        {ok, [WrapS]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_s, 1),
        {ok, [WrapT]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_t, 1),
        {WrapS, WrapT}
    end),

    {ok, Texture2} = graphics_texture:set_wrap_mode(Texture1, vertical, mirrored_repeat),
    repeat = graphics_texture:wrap_mode(Texture2, horizontal),
    mirrored_repeat = graphics_texture:wrap_mode(Texture2, vertical),
    {?GL_REPEAT, ?GL_MIRRORED_REPEAT} = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        {ok, [WrapS]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_s, 1),
        {ok, [WrapT]} = gl:get_tex_parameter(i, texture_2d, texture_wrap_t, 1),
        {WrapS, WrapT}
    end),

    ok = graphics_texture:destroy(Texture2),

    ok.

texture_generate_mipmap_test() ->
    ok = run_graphics(),

    {ok, Texture} = graphics_texture:with_image(?IMAGE),
    ok = graphics_texture:generate_mipmap(Texture),
    ?IMAGE = graphics_texture:remote_image(Texture),
    ok = graphics_texture:destroy(Texture),

    ok.

texture_local_copy_test() ->
    ok = run_graphics(),

    {ok, Texture0} = graphics_texture:with_image(?IMAGE),

    false = graphics_texture:has_local_copy(Texture0),
    undefined = graphics_texture:local_image(Texture0),

    {ok, Texture1} = graphics_texture:keep_local_copy(Texture0),
    true = graphics_texture:has_local_copy(Texture1),
    ?IMAGE = graphics_texture:local_image(Texture1),
    ?IMAGE = graphics_texture:remote_image(Texture1),

    already_local_copy = graphics_texture:keep_local_copy(Texture1),

    {ok, Texture2} = graphics_texture:release_local_copy(Texture1),
    false = graphics_texture:has_local_copy(Texture2),
    undefined = graphics_texture:local_image(Texture2),
    ?IMAGE = graphics_texture:remote_image(Texture2),

    no_local_copy = graphics_texture:release_local_copy(Texture2),

    ok = graphics_texture:destroy(Texture2),

    ok.
