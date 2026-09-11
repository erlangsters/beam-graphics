%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(texture).
-moduledoc """
Texture

A texture is a 2D array of pixels that is typically used for rendering.

A texture is an opaque object that wraps GPU image data. It is created with
the `with_image` and `with_color` functions and disposed with the `destroy/1`
function. Copying the term does not copy the GPU texture.

The CPU-side payload is an `image()`: a width, a height, and a row-major list
of RGBA colors (see `graphics:image()`). Textures are sampled when a 2D or 3D
mesh is drawn with a texture argument. The primitive type and the texture are
not part of the mesh; they are arguments of `surface:draw_mesh2/5`,
`surface:draw_mesh3/5`, and of `shape2` / `shape3`.

```erlang
{ok, Texture} = texture:with_image({2, 2, [
    ?COLOR_RED, ?COLOR_GREEN,
    ?COLOR_BLUE, ?COLOR_WHITE
]}).
{ok, Mesh} = mesh2:with_vertices([
    {{100.0, 100.0}, ?COLOR_WHITE, 0.0, 0.0},
    {{700.0, 100.0}, ?COLOR_WHITE, 1.0, 0.0},
    {{700.0, 500.0}, ?COLOR_WHITE, 1.0, 1.0},
    {{100.0, 500.0}, ?COLOR_WHITE, 0.0, 1.0}
]).
ok = surface:draw_mesh2(Surface, Mesh, triangle_fan, 4, Texture).
```

There is one texture module for both 2D and 3D drawing. A texture is a 2D
image; it is not split into `texture2` and `texture3`.

Pixel data must live in GPU memory in order to be used for rendering, so
reading and updating pixels have an associated cost. Avoid those operations
when they are not needed. If frequent reading is required, pixels can be
cached locally with the `keep_copy` option at construction, or later with
`keep_local_copy/1`. `local_image/1` reads the local copy when it exists.
`remote_image/1` reads from GPU memory, which is more expensive. By default,
no local copy is kept.

An empty texture is not allowed. Width and height must be at least 1.

Pixels are row-major: X varies fastest, then Y. Slice index `(0, 0)` is the
first pixel in the list and UV `(0, 0)`. Texture does not flip the image on
upload or download.

Color space is `linear` or `srgb` and is needed when the GPU storage is
allocated. The default is `linear`. CPU colors are float channels in
`graphics:color()`. GPU storage is 8-bit RGBA.

Sampling properties (minification filter, magnification filter, wrap mode)
live on the texture. They default to `linear` and `clamp_to_edge`. They are
changed with setters after construction. `generate_mipmap/1` builds mipmaps
on the GPU. A mipmap minification filter without `generate_mipmap/1` is an
incomplete texture.

Beware that a well-formed color always contains floats, not integers.

**OpenGL Internals**

A texture wraps an OpenGL texture object. Use `gl_object/1` to retrieve the
texture id.
""".

-export_type([
    width/0,
    height/0,
    pixels/0,
    image/0
]).
-export_type([
    color_space/0,
    keep_copy/0
]).
-export_type([
    minification_filter/0,
    magnification_filter/0
]).
-export_type([
    wrap_mode/0
]).
-export_type([
    object/0
]).
-export([
    with_image/1, with_image/2, with_image/3,
    with_color/2, with_color/3, with_color/4,
    destroy/1,
    set_image/2, set_image/3,
    resize/2, resize/3,
    size/1,
    color_space/1,
    local_image/1, local_image/3,
    remote_image/1, remote_image/3,
    local_pixel/3,
    remote_pixel/3,
    update_image/2, update_image/4,
    update_pixel/4
]).
-export([
    update_from_color/2,
    update_from_texture/2, update_from_texture/4
]).
-export([
    minification_filter/1,
    set_minification_filter/2,
    magnification_filter/1,
    set_magnification_filter/2
]).
-export([
    wrap_mode/2,
    set_wrap_mode/3
]).
-export([
    generate_mipmap/1
]).
-export([
    has_local_copy/1,
    keep_local_copy/1,
    release_local_copy/1
]).
-export([
    gl_object/1
]).

-compile({inline, [
    with_image/1, with_image/2,
    with_color/2, with_color/3,
    set_image/2,
    resize/2,
    size/1,
    color_space/1,
    local_image/1,
    update_image/2,
    update_from_texture/2,
    minification_filter/1,
    magnification_filter/1,
    wrap_mode/2,
    has_local_copy/1,
    gl_object/1
]}).

-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

% By default, the fill color is black.
-define(DEFAULT_COLOR, ?COLOR_BLACK).

% By default, the color space is linear.
-define(DEFAULT_COLOR_SPACE, linear).

% By default, the minification and magnification filters are linear.
-define(DEFAULT_MINIFICATION_FILTER, linear).
-define(DEFAULT_MAGNIFICATION_FILTER, linear).

% By default, the wrap mode is clamp to edge.
-define(DEFAULT_WRAP_MODE, clamp_to_edge).

% By default, no local copy is kept.
-define(DEFAULT_KEEP_COPY, no_copy).

-doc """
A texture width in pixels.

It is at least 1.
""".
-type width() :: pos_integer().

-doc """
A texture height in pixels.

It is at least 1.
""".
-type height() :: pos_integer().

-doc """
A row-major list of RGBA colors.

X varies fastest, then Y. The first color is slice index `(0, 0)` and UV
`(0, 0)`.
""".
-type pixels() :: [graphics:color()].

-doc """
A texture image.

A width, a height, and a row-major list of RGBA colors. `length(Pixels)` must
equal `Width * Height`.
""".
-type image() :: {
    Width :: width(),
    Height :: height(),
    Pixels :: pixels()
}.

-doc """
A texture color space.

`linear` stores 8-bit RGBA sampled as linear (`rgba8`). `srgb` stores 8-bit
RGBA sampled as sRGB (`srgb8_alpha8`). CPU colors are float channels;
conversion to and from 8-bit happens at upload and download.
""".
-type color_space() :: linear | srgb.

-doc """
A texture copy policy.

`no_copy` keeps no CPU copy of the pixels. `keep_copy` keeps a local copy.
""".
-type keep_copy() :: no_copy | keep_copy.

-doc """
A texture minification filter.

`nearest` and `linear` sample level 0. The mipmap filters require
`generate_mipmap/1`.
""".
-type minification_filter() ::
    nearest |
    linear |
    nearest_mipmap_nearest |
    linear_mipmap_nearest |
    nearest_mipmap_linear |
    linear_mipmap_linear
.

-doc """
A texture magnification filter.
""".
-type magnification_filter() ::
    nearest |
    linear
.

-doc """
A texture wrap mode.

It is set independently on the horizontal and vertical axes.
""".
-type wrap_mode() ::
    repeat |
    clamp_to_edge |
    mirrored_repeat
.

-doc """
A texture object.

It wraps an OpenGL texture id, the size, the color space, the sampling
properties, and an optional local copy of the pixels.
""".
-opaque object() :: {
    ResourceId :: {texture, gl:texture()},
    Size :: {width(), height()},
    ColorSpace :: color_space(),
    MinificationFilter :: minification_filter(),
    MagnificationFilter :: magnification_filter(),
    WrapMode :: {wrap_mode(), wrap_mode()},
    LocalPixels :: undefined | pixels()
}.

-doc """
A texture from an image.

It constructs a texture from the given image. The color space is `linear` and
no local copy is kept.

It's equivalent to `with_image(Image, linear)`.
""".
-spec with_image(image()) -> {ok, object()} | out_of_memory.
with_image(Image) ->
    with_image(Image, ?DEFAULT_COLOR_SPACE).

-doc """
A texture from an image and a color space.

It constructs a texture from the given image with the given color space. No
local copy is kept.

It's equivalent to `with_image(Image, ColorSpace, no_copy)`.
""".
-spec with_image(image(), color_space()) -> {ok, object()} | out_of_memory.
with_image(Image, ColorSpace) ->
    with_image(Image, ColorSpace, ?DEFAULT_KEEP_COPY).

-doc """
A texture from an image, a color space, and a copy policy.

It constructs a texture from the given image with the given color space.
When `KeepCopy` is `keep_copy`, a local copy of the pixels is kept. When it
is `no_copy`, there is no local copy.

Width and height must be at least 1, and `length(Pixels)` must equal
`Width * Height`. It returns `out_of_memory` when the GPU cannot allocate the
texture.
""".
-spec with_image(image(), color_space(), keep_copy()) ->
    {ok, object()} | out_of_memory
.
with_image({Width, Height, Pixels}, ColorSpace, KeepCopy)
        when Width > 0, Height > 0, length(Pixels) =:= Width * Height ->
    Data = pixels_to_data(Pixels),
    InternalFormat = color_space_to_internal_format(ColorSpace),
    case acquire_texture(Width, Height, Data, InternalFormat) of
        {error, out_of_memory} ->
            out_of_memory;
        {ok, ResourceId} ->
            LocalPixels = case KeepCopy of
                no_copy ->
                    undefined;
                keep_copy ->
                    Pixels
            end,
            Texture = {
                ResourceId,
                {Width, Height},
                ColorSpace,
                ?DEFAULT_MINIFICATION_FILTER,
                ?DEFAULT_MAGNIFICATION_FILTER,
                {?DEFAULT_WRAP_MODE, ?DEFAULT_WRAP_MODE},
                LocalPixels
            },
            {ok, Texture}
    end.

-doc """
A texture filled with a color.

It constructs a texture of the given size filled with the given color. The
color space is `linear` and no local copy is kept.

It's equivalent to `with_color(Color, Size, linear)`.
""".
-spec with_color(graphics:color(), {width(), height()}) ->
    {ok, object()} | out_of_memory
.
with_color(Color, Size) ->
    with_color(Color, Size, ?DEFAULT_COLOR_SPACE).

-doc """
A texture filled with a color and a color space.

It constructs a texture of the given size filled with the given color, with
the given color space. No local copy is kept.

It's equivalent to `with_color(Color, Size, ColorSpace, no_copy)`.
""".
-spec with_color(graphics:color(), {width(), height()}, color_space()) ->
    {ok, object()} | out_of_memory
.
with_color(Color, Size, ColorSpace) ->
    with_color(Color, Size, ColorSpace, ?DEFAULT_KEEP_COPY).

-doc """
A texture filled with a color, a color space, and a copy policy.

It constructs a texture of the given size filled with the given color. Width
and height must be at least 1.

It's equivalent to `with_image({Width, Height, lists:duplicate(Width * Height, Color)}, ColorSpace, KeepCopy)`.
""".
-spec with_color(
    graphics:color(),
    {width(), height()},
    color_space(),
    keep_copy()
) -> {ok, object()} | out_of_memory.
with_color(Color, {Width, Height}, ColorSpace, KeepCopy)
        when Width > 0, Height > 0 ->
    Image = {Width, Height, lists:duplicate(Width * Height, Color)},
    with_image(Image, ColorSpace, KeepCopy).

-doc """
Destroy a texture.

It releases the GPU texture. Using the texture after it is destroyed has
undefined behavior. Destroying the same texture twice is invalid.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId, _, _, _, _, _, _}) ->
    ok = release_texture(ResourceId),
    ok.

-doc """
Set the image of a texture.

It replaces the image of the texture. The color space, the sampling
properties, and the copy policy of the texture are preserved. The OpenGL
texture id is unchanged.

It's equivalent to `set_image(Texture, Image, color_space(Texture))`.
""".
-spec set_image(object(), image()) -> {ok, object()} | out_of_memory.
set_image(Texture, Image) ->
    set_image(Texture, Image, color_space(Texture)).

-doc """
Set the image of a texture with a color space.

It replaces the image of the texture and sets the color space. The sampling
properties and the copy policy of the texture are preserved. The OpenGL
texture id is unchanged.

Width and height must be at least 1, and `length(Pixels)` must equal
`Width * Height`. It returns `out_of_memory` when the GPU cannot allocate the
new data store.
""".
-spec set_image(object(), image(), color_space()) ->
    {ok, object()} | out_of_memory
.
set_image(
    {
        ResourceId,
        _Size,
        _ColorSpace,
        MinificationFilter,
        MagnificationFilter,
        WrapMode,
        LocalPixels
    },
    {Width, Height, Pixels},
    ColorSpace
) when Width > 0, Height > 0, length(Pixels) =:= Width * Height ->
    Data = pixels_to_data(Pixels),
    InternalFormat = color_space_to_internal_format(ColorSpace),
    {texture, GlTexture} = ResourceId,
    case set_texture_data(GlTexture, Width, Height, Data, InternalFormat) of
        ok ->
            NewLocalPixels = case LocalPixels of
                undefined ->
                    undefined;
                _ ->
                    Pixels
            end,
            NewTexture = {
                ResourceId,
                {Width, Height},
                ColorSpace,
                MinificationFilter,
                MagnificationFilter,
                WrapMode,
                NewLocalPixels
            },
            {ok, NewTexture};
        out_of_memory ->
            out_of_memory
    end.

-doc """
Resize a texture.

It reallocates the texture to the given size and fills it with black. The
color space, the sampling properties, and the copy policy are preserved. The
OpenGL texture id is unchanged. Existing pixels are discarded.

It's equivalent to `resize(Texture, Size, {0.0, 0.0, 0.0, 1.0})`.
""".
-spec resize(object(), {width(), height()}) -> {ok, object()} | out_of_memory.
resize(Texture, Size) ->
    resize(Texture, Size, ?DEFAULT_COLOR).

-doc """
Resize a texture and fill it with a color.

It reallocates the texture to the given size and fills it with the given
color. The color space, the sampling properties, and the copy policy are
preserved. The OpenGL texture id is unchanged. Existing pixels are discarded.

Width and height must be at least 1.
""".
-spec resize(object(), {width(), height()}, graphics:color()) ->
    {ok, object()} | out_of_memory
.
resize(Texture, {Width, Height}, Color) when Width > 0, Height > 0 ->
    Image = {Width, Height, lists:duplicate(Width * Height, Color)},
    set_image(Texture, Image).

-doc """
The size of a texture.

It returns the width and height currently stored in the texture.
""".
-spec size(object()) -> {width(), height()}.
size({_, Size, _, _, _, _, _}) ->
    Size.

-doc """
The color space of a texture.

It returns the color space last set when constructing or setting the image
of the texture.
""".
-spec color_space(object()) -> color_space().
color_space({_, _, ColorSpace, _, _, _, _}) ->
    ColorSpace.

-doc """
The locally cached image of a texture.

It returns the local copy of the image when a copy is kept. It returns
`undefined` when no local copy is kept.

Use `local_image/3` to retrieve a slice of the local copy.
""".
-spec local_image(object()) -> undefined | image().
local_image({_, _, _, _, _, _, undefined}) ->
    undefined;
local_image({_, {Width, Height}, _, _, _, _, LocalPixels}) ->
    {Width, Height, LocalPixels}.

-doc """
A slice of the locally cached image of a texture.

It returns a slice of the local copy using slice range notation on X and Y.
It returns `undefined` when no local copy is kept, and `no_range` when either
range is empty.

```erlang
{ok, Texture} = texture:with_image(Image, linear, keep_copy),
{2, 1, {1, 1, [Second]}} = texture:local_image(Texture, {1, -1}, {undefined, 1}).
```
""".
-spec local_image(object(), slice:range(), slice:range()) ->
    undefined | no_range | {slice:offset(), slice:offset(), image()}
.
local_image({_, _, _, _, _, _, undefined}, _RangeX, _RangeY) ->
    undefined;
local_image({_, {Width, Height}, _, _, _, _, LocalPixels}, RangeX, RangeY) ->
    slice_image(Width, Height, LocalPixels, RangeX, RangeY).

-doc """
The GPU image of a texture.

It reads the pixels from GPU memory. This is more expensive than
`local_image/1`.
""".
-spec remote_image(object()) -> image().
remote_image({ResourceId, {Width, Height}, _, _, _, _, _LocalPixels}) ->
    {texture, GlTexture} = ResourceId,
    Data = texture_data(GlTexture, Width, Height),
    Pixels = data_to_pixels(Data),
    {Width, Height, Pixels}.

-doc """
A slice of the GPU image of a texture.

It reads a slice of the pixels from GPU memory using slice range notation on
X and Y. It returns `no_range` when either range is empty.

This may read the whole texture and then slice it. OpenGL below 4.5 has no
cheap sub-rectangle read.
""".
-spec remote_image(object(), slice:range(), slice:range()) ->
    no_range | {slice:offset(), slice:offset(), image()}
.
remote_image(
    {_ResourceId, {Width, Height}, _, _, _, _, _LocalPixels} = Texture,
    RangeX,
    RangeY
) ->
    case {slice:range(Width, RangeX), slice:range(Height, RangeY)} of
        {no_range, _} ->
            no_range;
        {_, no_range} ->
            no_range;
        {_SliceX, _SliceY} ->
            {_Width, _Height, Pixels} = remote_image(Texture),
            slice_image(Width, Height, Pixels, RangeX, RangeY)
    end.

-doc """
A locally cached pixel of a texture.

It returns a pixel of the local copy, identified by slice indices. The
indices are 0-based and may be negative.

```erlang
{ok, Texture} = texture:with_image(Image, linear, keep_copy),
{1, 1, Color} = texture:local_pixel(Texture, 0, 0),
{Width, Height, ColorLast} = texture:local_pixel(Texture, -1, -1).
```

It returns `undefined` when no local copy is kept, and `out_of_range` when an
index is out of range. The offsets in the result are 1-based.
""".
-spec local_pixel(object(), slice:index(), slice:index()) ->
    undefined | out_of_range | {slice:offset(), slice:offset(), graphics:color()}
.
local_pixel({_, _, _, _, _, _, undefined}, _IndexX, _IndexY) ->
    undefined;
local_pixel({_, {Width, Height}, _, _, _, _, LocalPixels}, IndexX, IndexY) ->
    pixel_at(Width, Height, LocalPixels, IndexX, IndexY).

-doc """
A GPU pixel of a texture.

It reads a pixel from GPU memory, identified by slice indices. The indices
are 0-based and may be negative. It returns `out_of_range` when an index is
out of range. The offsets in the result are 1-based.

This may read the whole texture and then pick the pixel. OpenGL below 4.5
has no cheap sub-rectangle read.
""".
-spec remote_pixel(object(), slice:index(), slice:index()) ->
    out_of_range | {slice:offset(), slice:offset(), graphics:color()}
.
remote_pixel(
    {_, {Width, Height}, _, _, _, _, _LocalPixels} = Texture,
    IndexX,
    IndexY
) ->
    case {slice:index(Width, IndexX), slice:index(Height, IndexY)} of
        {out_of_range, _} ->
            out_of_range;
        {_, out_of_range} ->
            out_of_range;
        {_OffsetX, _OffsetY} ->
            {_Width, _Height, Pixels} = remote_image(Texture),
            pixel_at(Width, Height, Pixels, IndexX, IndexY)
    end.

-doc """
Update the image of a texture from the origin.

It writes the given image starting at slice index `(0, 0)`. The texture size
is unchanged. It returns `out_of_range` when the image would not fit.

It's equivalent to `update_image(Texture, Image, 0, 0)`.
""".
-spec update_image(object(), image()) -> {ok, object()} | out_of_range.
update_image(Texture, Image) ->
    update_image(Texture, Image, 0, 0).

-doc """
Update the image of a texture from an index.

It writes the given image starting at the given slice indices. The indices
are 0-based and may be negative. The texture size is unchanged. It returns
`out_of_range` when an index is invalid or the write would not fit.

Width and height of the image must be at least 1, and `length(Pixels)` must
equal `Width * Height`.
""".
-spec update_image(object(), image(), slice:index(), slice:index()) ->
    {ok, object()} | out_of_range
.
update_image(
    {ResourceId, {TexWidth, TexHeight}, ColorSpace, MinificationFilter,
     MagnificationFilter, WrapMode, LocalPixels},
    {ImgWidth, ImgHeight, Pixels},
    IndexX,
    IndexY
) when ImgWidth > 0, ImgHeight > 0, length(Pixels) =:= ImgWidth * ImgHeight ->
    case slice:index(TexWidth, IndexX) of
        out_of_range ->
            out_of_range;
        OffsetX ->
            case slice:index(TexHeight, IndexY) of
                out_of_range ->
                    out_of_range;
                OffsetY ->
                    Fits = OffsetX - 1 + ImgWidth =< TexWidth
                        andalso OffsetY - 1 + ImgHeight =< TexHeight,
                    case Fits of
                        false ->
                            out_of_range;
                        true ->
                            Data = pixels_to_data(Pixels),
                            {texture, GlTexture} = ResourceId,
                            ok = update_texture_data(
                                GlTexture,
                                ImgWidth,
                                ImgHeight,
                                Data,
                                OffsetX - 1,
                                OffsetY - 1
                            ),
                            NewLocalPixels = case LocalPixels of
                                undefined ->
                                    undefined;
                                _ when
                                        OffsetX =:= 1,
                                        OffsetY =:= 1,
                                        ImgWidth =:= TexWidth,
                                        ImgHeight =:= TexHeight ->
                                    Pixels;
                                _ ->
                                    patch_pixels(
                                        TexWidth,
                                        LocalPixels,
                                        OffsetX,
                                        OffsetY,
                                        ImgWidth,
                                        ImgHeight,
                                        Pixels
                                    )
                            end,
                            NewTexture = {
                                ResourceId,
                                {TexWidth, TexHeight},
                                ColorSpace,
                                MinificationFilter,
                                MagnificationFilter,
                                WrapMode,
                                NewLocalPixels
                            },
                            {ok, NewTexture}
                    end
            end
    end.

-doc """
Update a pixel of a texture.

It writes the given color at the given slice indices. The indices are
0-based and may be negative.

It's equivalent to `update_image(Texture, {1, 1, [Color]}, IndexX, IndexY)`.
""".
-spec update_pixel(object(), graphics:color(), slice:index(), slice:index()) ->
    {ok, object()} | out_of_range
.
update_pixel(Texture, Color, IndexX, IndexY) ->
    update_image(Texture, {1, 1, [Color]}, IndexX, IndexY).

-doc """
Fill a texture with a color.

It writes the given color to every pixel. The texture size is unchanged.
""".
-spec update_from_color(object(), graphics:color()) ->
    {ok, object()} | out_of_range
.
update_from_color({_, {Width, Height}, _, _, _, _, _} = Texture, Color) ->
    Image = {Width, Height, lists:duplicate(Width * Height, Color)},
    update_image(Texture, Image).

-doc """
Update a texture from another texture.

It copies all of the source texture into the destination starting at
`(0, 0)`. The destination size is unchanged. It returns `out_of_range` when
the source would not fit.

It's equivalent to `update_from_texture(Dest, Src, 0, 0)`.
""".
-spec update_from_texture(object(), object()) -> {ok, object()} | out_of_range.
update_from_texture(Dest, Src) ->
    update_from_texture(Dest, Src, 0, 0).

-doc """
Update a texture from another texture at an index.

It copies all of the source texture into the destination starting at the
given slice indices. The indices are 0-based and may be negative. The
destination size is unchanged. It does not copy sampler state or color space.
It returns `out_of_range` when an index is invalid or the write would not
fit.
""".
-spec update_from_texture(object(), object(), slice:index(), slice:index()) ->
    {ok, object()} | out_of_range
.
update_from_texture(Dest, Src, IndexX, IndexY) ->
    Image = remote_image(Src),
    update_image(Dest, Image, IndexX, IndexY).

-doc """
The minification filter of a texture.

It returns the minification filter last set on the texture.
""".
-spec minification_filter(object()) -> minification_filter().
minification_filter({_, _, _, MinificationFilter, _, _, _}) ->
    MinificationFilter.

-doc """
Set the minification filter of a texture.

It sets the minification filter. Mipmap filters require `generate_mipmap/1`.
""".
-spec set_minification_filter(object(), minification_filter()) ->
    {ok, object()}
.
set_minification_filter(
    {{texture, GlTexture}, _, _, _, _, _, _} = Texture,
    Filter
) ->
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:tex_min_filter(texture_2d, Filter),
        ok = gl:bind_texture(texture_2d, none),
        ok
    end),
    {ok, erlang:setelement(4, Texture, Filter)}.

-doc """
The magnification filter of a texture.

It returns the magnification filter last set on the texture.
""".
-spec magnification_filter(object()) -> magnification_filter().
magnification_filter({_, _, _, _, MagnificationFilter, _, _}) ->
    MagnificationFilter.

-doc """
Set the magnification filter of a texture.

It sets the magnification filter.
""".
-spec set_magnification_filter(object(), magnification_filter()) ->
    {ok, object()}
.
set_magnification_filter(
    {{texture, GlTexture}, _, _, _, _, _, _} = Texture,
    Filter
) ->
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:tex_mag_filter(texture_2d, Filter),
        ok = gl:bind_texture(texture_2d, none),
        ok
    end),
    {ok, erlang:setelement(5, Texture, Filter)}.

-doc """
The wrap mode of a texture axis.

It returns the wrap mode of the horizontal or vertical axis.
""".
-spec wrap_mode(object(), horizontal | vertical) -> wrap_mode().
wrap_mode({_, _, _, _, _, {WrapMode, _}, _}, horizontal) ->
    WrapMode;
wrap_mode({_, _, _, _, _, {_, WrapMode}, _}, vertical) ->
    WrapMode.

-doc """
Set the wrap mode of a texture axis.

It sets the wrap mode of the horizontal or vertical axis.
""".
-spec set_wrap_mode(object(), horizontal | vertical, wrap_mode()) ->
    {ok, object()}
.
set_wrap_mode(
    {{texture, GlTexture}, _, _, _, _, {WrapModeX, WrapModeY}, _} = Texture,
    Axis,
    Mode
) ->
    NewWrapMode = case Axis of
        horizontal ->
            {Mode, WrapModeY};
        vertical ->
            {WrapModeX, Mode}
    end,
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        case Axis of
            horizontal ->
                ok = gl:tex_wrap_s(texture_2d, Mode);
            vertical ->
                ok = gl:tex_wrap_t(texture_2d, Mode)
        end,
        ok = gl:bind_texture(texture_2d, none),
        ok
    end),
    {ok, erlang:setelement(6, Texture, NewWrapMode)}.

-doc """
Generate the mipmaps of a texture.

It generates mipmap levels from level 0. The Erlang term is unchanged. A
mipmap minification filter without this call is an incomplete texture.
""".
-spec generate_mipmap(object()) -> ok.
generate_mipmap({{texture, GlTexture}, _, _, _, _, _, _}) ->
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:generate_mipmap(texture_2d),
        ok = gl:bind_texture(texture_2d, none),
        ok
    end).

-doc """
Check whether a texture keeps a local copy.

It returns `true` when a local copy of the pixels is kept, otherwise
`false`.
""".
-spec has_local_copy(object()) -> boolean().
has_local_copy({_, _, _, _, _, _, undefined}) ->
    false;
has_local_copy({_, _, _, _, _, _, _}) ->
    true.

-doc """
Keep a local copy of a texture.

It reads the pixels from GPU memory and keeps them as a local copy. It
returns `already_local_copy` when a local copy is already kept.
""".
-spec keep_local_copy(object()) -> {ok, object()} | already_local_copy.
keep_local_copy({_, _, _, _, _, _, undefined} = Texture) ->
    {_Width, _Height, Pixels} = remote_image(Texture),
    {ok, erlang:setelement(7, Texture, Pixels)};
keep_local_copy({_, _, _, _, _, _, _}) ->
    already_local_copy.

-doc """
Release the local copy of a texture.

It drops the local copy of the pixels. The GPU texture is unchanged. It
returns `no_local_copy` when there is no local copy.
""".
-spec release_local_copy(object()) -> {ok, object()} | no_local_copy.
release_local_copy({_, _, _, _, _, _, undefined}) ->
    no_local_copy;
release_local_copy(Texture) ->
    {ok, erlang:setelement(7, Texture, undefined)}.

-doc """
The OpenGL texture of a texture.

It returns the OpenGL texture id wrapped by the texture.
""".
-spec gl_object(object()) -> gl:texture().
gl_object({{texture, GlTexture}, _, _, _, _, _, _}) ->
    GlTexture.

color_space_to_internal_format(linear) ->
    rgba8;
color_space_to_internal_format(srgb) ->
    srgb8_alpha8.

channel_to_byte(Channel) when Channel =< 0.0 ->
    0;
channel_to_byte(Channel) when Channel >= 1.0 ->
    255;
channel_to_byte(Channel) ->
    round(Channel * 255.0).

byte_to_channel(Byte) ->
    Byte / 255.0.

pixels_to_data(Pixels) ->
    iolist_to_binary(lists:map(
        fun({R, G, B, A}) ->
            <<
                (channel_to_byte(R)):8,
                (channel_to_byte(G)):8,
                (channel_to_byte(B)):8,
                (channel_to_byte(A)):8
            >>
        end,
        Pixels
    )).

data_to_pixels(Data) ->
    data_to_pixels(Data, []).

data_to_pixels(<<>>, Pixels) ->
    lists:reverse(Pixels);
data_to_pixels(<<R:8, G:8, B:8, A:8, DataRest/binary>>, Pixels) ->
    Color = {
        byte_to_channel(R),
        byte_to_channel(G),
        byte_to_channel(B),
        byte_to_channel(A)
    },
    data_to_pixels(DataRest, [Color | Pixels]).

slice_image(Width, Height, Pixels, RangeX, RangeY) ->
    case slice:range(Width, RangeX) of
        no_range ->
            no_range;
        {OffsetX, LengthX} ->
            case slice:range(Height, RangeY) of
                no_range ->
                    no_range;
                {OffsetY, LengthY} ->
                    Image = image_area(
                        Width, Pixels, OffsetX, LengthX, OffsetY, LengthY
                    ),
                    {OffsetX, OffsetY, Image}
            end
    end.

pixel_at(Width, Height, Pixels, IndexX, IndexY) ->
    case slice:index(Width, IndexX) of
        out_of_range ->
            out_of_range;
        OffsetX ->
            case slice:index(Height, IndexY) of
                out_of_range ->
                    out_of_range;
                OffsetY ->
                    Pixel = image_pixel(Width, Pixels, OffsetX, OffsetY),
                    {OffsetX, OffsetY, Pixel}
            end
    end.

image_area(Width, Pixels, OffsetX, LengthX, OffsetY, LengthY) ->
    AreaPixels = lists:append([
        lists:sublist(Pixels, (Row - 1) * Width + OffsetX, LengthX)
     || Row <- lists:seq(OffsetY, OffsetY + LengthY - 1)
    ]),
    {LengthX, LengthY, AreaPixels}.

image_pixel(Width, Pixels, OffsetX, OffsetY) ->
    lists:nth((OffsetY - 1) * Width + OffsetX, Pixels).

split_rows(_Width, []) ->
    [];
split_rows(Width, Pixels) ->
    {Row, Rest} = lists:split(Width, Pixels),
    [Row | split_rows(Width, Rest)].

patch_pixels(
    TexWidth, LocalPixels, OffsetX, OffsetY, ImgWidth, ImgHeight, ImgPixels
) ->
    SrcRows = split_rows(ImgWidth, ImgPixels),
    {Top, Rest} = lists:split(OffsetY - 1, split_rows(TexWidth, LocalPixels)),
    {Mid, Bottom} = lists:split(ImgHeight, Rest),
    NewMid = lists:zipwith(
        fun(DestRow, SrcRow) ->
            {Left, RestRow} = lists:split(OffsetX - 1, DestRow),
            {_, Right} = lists:split(ImgWidth, RestRow),
            Left ++ SrcRow ++ Right
        end,
        Mid,
        SrcRows
    ),
    lists:append(Top ++ NewMid ++ Bottom).

acquire_texture(Width, Height, Data, InternalFormat) ->
    ReleaseFun = fun({texture, GlTexture}) ->
        ok = gl:bind_texture(texture_2d, none),
        ok = gl:delete_textures([GlTexture]),
        ok
    end,
    AcquireFun = fun() ->
        {ok, [GlTexture]} = gl:gen_textures(1),
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:tex_min_filter(texture_2d, ?DEFAULT_MINIFICATION_FILTER),
        ok = gl:tex_mag_filter(texture_2d, ?DEFAULT_MAGNIFICATION_FILTER),
        ok = gl:tex_wrap_s(texture_2d, ?DEFAULT_WRAP_MODE),
        ok = gl:tex_wrap_t(texture_2d, ?DEFAULT_WRAP_MODE),
        ok = gl:pixel_store(unpack_alignment, 1),
        ok = gl:pixel_store(pack_alignment, 1),
        ok = gl:tex_image_2d(
            texture_2d, 0, InternalFormat,
            Width, Height, 0,
            rgba, unsigned_byte,
            Data
        ),
        case gl:get_error() of
            {ok, no_error} ->
                ok = gl:bind_texture(texture_2d, none),
                {ok, {texture, GlTexture}, ReleaseFun};
            {ok, out_of_memory} ->
                ok = gl:bind_texture(texture_2d, none),
                ok = gl:delete_textures([GlTexture]),
                {error, out_of_memory}
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

release_texture(ResourceId) ->
    graphics_context:release_resource(ResourceId).

set_texture_data(GlTexture, Width, Height, Data, InternalFormat) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:pixel_store(unpack_alignment, 1),
        ok = gl:tex_image_2d(
            texture_2d, 0, InternalFormat,
            Width, Height, 0,
            rgba, unsigned_byte,
            Data
        ),
        case gl:get_error() of
            {ok, no_error} ->
                ok = gl:bind_texture(texture_2d, none),
                ok;
            {ok, out_of_memory} ->
                ok = gl:bind_texture(texture_2d, none),
                out_of_memory
        end
    end).

texture_data(GlTexture, Width, Height) ->
    Size = Width * Height * 4,
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:pixel_store(pack_alignment, 1),
        {ok, Data} = gl:get_tex_image(
            texture_2d, 0,
            rgba, unsigned_byte,
            Size
        ),
        ok = gl:bind_texture(texture_2d, none),
        Data
    end).

update_texture_data(GlTexture, Width, Height, Data, OffsetX, OffsetY) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:pixel_store(unpack_alignment, 1),
        ok = gl:tex_sub_image_2d(
            texture_2d, 0,
            OffsetX, OffsetY,
            Width, Height,
            rgba, unsigned_byte,
            Data
        ),
        ok = gl:bind_texture(texture_2d, none),
        ok
    end).
