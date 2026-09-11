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

A texture is a 2D array of pixels (or in other words, an image) that can be used
for rendering. They are indirectly rendered on a surface with a 2D or 3D mesh
that specifies texture coordinates for each vertex.

For instance, the following will render an image.

```erlang
Mesh = mesh:with_vertices([
    {100.0, 100.0, 1.0, 0.0},
    {700.0, 100.00, 1.0, 1.0},
    {700.0, 500.00, 0.0, 1.0},
    {700.0, 500.00, 0.0, 0.0}
]).
Texture = texture:with_image({800, 600, load_image("image.png")}).
surface:render(Surface, Mesh, triangle_strip, Texture).
```

Texture pixels must live in the GPU memory in order to be used for rendering,
and therefore, reading and updating pixels have an associated cost. Avoid
those operations as much as possible, and if frequent reading is required,
pixels can be cached locally with the `keep_copy` option. It explains the
local/remote semantics in the API. For instance, `local_image/1` will read the
pixels from a local copy (if it exists), while `remote_image/1` will read the
pixels from the GPU memory (which is more expensive).

---

To create a texture, use the `with_image/1` and `with_image/2` functions.
The texture is later disposed with the `destroy/1` function, which will
remove the texture from the GPU memory and free the associated resources.

> Using a destroyed texture have undefined behavior.

> Note that there cannot be "empty" texture and it must be at least 1x1 pixel
> in size.

> Note that it can return 'out of memory' but in practice it hardly happens
> so you can ignore it. xxx

For convenience, the `with_color/3` and `with_color/4` functions can be used to
create a texture filled with a single color.

To change the image of a texture, which can potentially resize the texture, use
the `set_image/2` function.

> NOTE: The advantage of using `set_image/2` over re-creating another texture
> is that it will keep the internal OpenGL object ID.  Use `update_image/2`
> to update the pixels of a texture without changing its size.

Use the `with/1` and `height/2` functions to retrieve the width and height of
the texture.

To retrieve all the pixels of a texture, or a sub-set of them, use the
`local_image/1`, `local_image/3`, `remote_image/1`, and `remote_image/3`
functions. The "local" version of those functions will read the pixels from a
locally cached pixels, if a copy was requested at creation time with the
`keep_copy` option. The "remote" version will read the pixels from the GPU
memory, which is more expensive.

The `local_pixel/3` and `remote_pixel/3` functions allows to retrieve a single
pixel at a given position in the texture.

> NOTE: Those functions implement the slice API which allows you to easily
> retrieve sub-regions of the texture. For instance, you can you retrieve the
> the bottom-right pixel of a texture with `remote_pixel(Texture, -1, -1)`.

To

**OpenGL Internals**

It wraps a texture OpenGL object.
To be written.


Use the `handle/1` function to retrieve the OpenGL buffer ID.
It's created by the root context, which you can retrieve with the
`graphics_context:inner_context/0` function.


XXX: No possible optimization (like retrieving a sub-region of the texture) unless using OpenGL 4.5 (glGetTextureSubImage).

XXX: Implement copy operations ?
XXX: Investigate any other potential OpenGL texture "properties" I'm not ware
     of (swizzle ? texture compare mode? border color? anisotropic filtering?)., etc
    multisample textures (anti-aliasing), etc.
XXX: Or just add documentation to show how to run the raw opengl contexts to
    switch thowse advanced properties.

XXX: Perhaps swizzle mask and compare mode  could be an interesting property
     to b e exposed.

```
-export([
    set_border_color/2,  % For border handling
    set_swizzle_mask/2,  % Control RGBA channel swizzling
    set_compare_mode/2,  % For shadow mapping
    set_lod_parameters/5,  % LOD bias, min, max
    set_max_anisotropy/2,  % For anisotropic filtering
    create_from_framebuffer/3  % Create texture from current framebuffer
]).
```


separete repo with `cubemap_texture`  ?

```
-export([
    with_array/2,  % Create texture array
    with_cubemap/1,  % Create cubemap texture
    update_cubemap_face/3  % Update specific cubemap face
]).
```


update wrap mode api to suppor thorizontal and vertical

""".

-export_type([
    width/0,
    height/0,
    pixels/0,
    image/0
]).
-export_type([
    color_space/0
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
    resize/2, resize/3, resize/4,
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
    update_from_color/2, update_from_color/3,
    update_from_texture/2, update_from_texture/3,
    update_from_surface/2, update_from_surface/3
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
    gl_object/1
]).
-export([
    has_local_copy/1,
    keep_local_copy/1,
    release_local_copy/1
]).

-compile({inline, [
    with_image/1, with_image/2,
    with_color/2, with_color/3, with_color/4
]}).
-compile({inline, [
    set_image/2,
    resize/2, resize/3,
    size/1,
    color_space/1,
    local_image/1
]}).
-compile({inline, [
    minification_filter/1,
    magnification_filter/1,
    wrap_mode/2
]}).
-compile({inline, [
    gl_object/1
]}).
-compile({inline, [
    has_local_copy/1
]}).

-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

% By default, the fill color is black.
-define(DEFAULT_COLOR, ?COLOR_BLACK).

% By default, the color space is non-sRGB (linear).
-define(DEFAULT_COLOR_SPACE, linear).

% By default, the minification and magnification filters are set to "linear".
-define(DEFAULT_MINIFICATION_FILTER, linear).
-define(DEFAULT_MAGNIFICATION_FILTER, linear).

% By default, the the wrap mode is "clamp to edge".
-define(DEFAULT_WRAP_MODE, clamp_to_edge).

% By default, no local copy is kept.
-define(DEFAULT_KEEP_COPY, no_copy).

-type width() :: non_neg_integer().
-type height() :: non_neg_integer().
-type pixels() :: [graphics:color()].

-doc """
To be written.
""".
-type image() :: {width(), height(), pixels()}.

-doc """
To be written.
""".
-type color_space() :: linear | s_rgb.

-doc """
To be written.
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
To be written.
""".
-type magnification_filter() ::
    nearest |
    linear
.

-doc """
To be written.
""".
-type wrap_mode() ::
    repeat |
    clamp_to_edge |
    mirrored_repeat
.

-doc """
To be written.
""".
-type keep_copy() :: no_copy | keep_copy.

-doc """
To be written.

To be written.
""".
-opaque object() :: {
    ResourceId :: {texture, gl:texture()},
    Size :: {width(), height()},
    ColorSpace :: color_space(),
    MinificationFilter :: minification_filter(),
    MagnificationFilter :: magnification_filter(),
    WrapMode :: wrap_mode(),
    LocalPixels :: undefined | pixels()
}.

-doc """
To be written.

To be written.
""".
-spec with_image(image()) -> {ok, graphics:texture()}.
with_image(Image) ->
    with_image(Image, ?DEFAULT_COLOR_SPACE).

-doc """
To be written.

To be written.
""".
-spec with_image(image(), color_space()) -> {ok, graphics:texture()}.
with_image(Image, ColorSpace) ->
    with_image(Image, ColorSpace, ?DEFAULT_KEEP_COPY).

-doc """
To be written.

To be written.
""".
-spec with_image(image(), color_space(), keep_copy()) ->
    {ok, graphics:texture()}
.
with_image({Width, Height, Pixels}, ColorSpace, KeepCopy) ->
    Data = pixels_to_data(Pixels),
    InternalFormat = color_space_to_internal_format(ColorSpace),
    case acquire_texture(Width, Height, Data, InternalFormat) of
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
            {ok, Texture};
        {error, out_of_memory} ->
            out_of_memory
    end.

-doc """
To be written.

To be written.
""".
-spec with_color(graphics:color(), {width(), height()}) ->
    {ok, graphics:texture()}.
with_color(Color, Size) ->
    with_color(Color, Size, ?DEFAULT_COLOR_SPACE).

-doc """
To be written.

To be written.
""".
-spec with_color(graphics:color(), {width(), height()}, color_space()) ->
    {ok, graphics:texture()}.
with_color(Color, {Width, Height}, ColorSpace) ->
    with_color(Color, {Width, Height}, ColorSpace, ?DEFAULT_KEEP_COPY).

-doc """
To be written.

To be written.
""".
-spec with_color(graphics:color(), {width(), height()}, color_space(), keep_copy()) ->
    {ok, graphics:texture()}.
with_color(Color, {Width, Height}, ColorSpace, KeepCopy) ->
    Image = {Width, Height, lists:duplicate(Width * Height, Color)},
    with_image(Image, ColorSpace, KeepCopy).

-doc """
To be written.

To be written.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId, _, _, _, _, _, _}) ->
    ok = release_texture(ResourceId),
    ok.

-doc """
To be written.

To be written.
""".
-spec set_image(object(), image()) -> {ok, object()} | out_of_memory.
set_image(Texture, Image) ->
    set_image(Texture, Image, ?DEFAULT_COLOR_SPACE).

-doc """
To be written.

To be written.
""".
-spec set_image(object(), image(), color_space()) ->
    {ok, object()} | out_of_memory.
set_image(
    {{texture, GlTexture}, _, _, MinificationFilter, MagnificationFilter, WrapMode, LocalPixels},
    {Width, Height, Pixels},
    ColorSpace
) when Width > 0 andalso Height > 0 ->
    % XXX: Handle out of memory edge case.
    Data = pixels_to_data(Pixels),
    InternalFormat = color_space_to_internal_format(ColorSpace),
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, GlTexture),
        ok = gl:tex_image_2d(
            texture_2d, 0, InternalFormat,
            Width, Height, 0,
            rgba, unsigned_byte,
            Data
        ),
        ok = gl:bind_texture(texture_2d, none),
        ok
    end),
    NewLocalPixels = case LocalPixels of
        undefined ->
            undefined;
        _ ->
            Pixels
    end,
    NewTexture = {
        {texture, GlTexture},
        {Width, Height},
        ColorSpace,
        MinificationFilter,
        MagnificationFilter,
        WrapMode,
        NewLocalPixels
    },
    {ok, NewTexture}.

-doc """
To be written.

To be written.
""".
-spec resize(object(), {width(), height()}) -> {ok, object()}  | out_of_memory.
resize(Texture, Size) ->
    resize(Texture, Size, ?DEFAULT_COLOR).

-doc """
To be written.

To be written.
""".
-spec resize(object(), {width(), height()}, graphics:color()) ->
    {ok, object()} | out_of_memory
.
resize(Texture, Size, Color) ->
    resize(Texture, Size, Color, ?DEFAULT_COLOR_SPACE).

-doc """
To be written.

To be written.
""".
-spec resize(object(), {width(), height()}, graphics:color(), color_space()) ->
    {ok, object()} | out_of_memory
.
resize(Texture, {Width, Height}, Color, ColorSpace) ->
    % XXX: Might be rewritten to keep existing image intact (just fill the new 
    %      space).
    Image = {Width, Height, lists:duplicate(Width * Height, Color)},
    set_image(Texture, Image, ColorSpace).

-doc """
To be written.

To be written.
""".
-spec size(object()) -> {width(), height()}.
size({_, Size, _, _, _, _, _}) ->
    Size.

-doc """
To be written.

To be written.
""".
-spec color_space(object()) -> color_space().
color_space({_, _, ColorSpace, _, _, _, _}) ->
    ColorSpace.

-doc """
To be written.

To be written.
""".
-spec local_image(object()) -> undefined | image().
local_image({_, _, _, _, _, _, undefined}) ->
    undefined;
local_image({ _, {Width, Height}, _, _, _, _, LocalPixels}) ->
    {Width, Height, LocalPixels}.

-doc """
To be written.

To be written.
""".
-spec local_image(object(), slice:range(), slice:range()) ->
    undefined | no_range | {slice:offset(), slice:offset(), image()}.
local_image({_, _, _, _, _, _, undefined}, _RangeX, _RangeY) ->
    undefined;
local_image({_, {Width, Height}, _, _, _, _, LocalPixels}, RangeX, RangeY) ->
    case slice:range(Width, RangeX) of
        no_range ->
            no_range;
        {OffsetX, LengthX} ->
            case slice:range(Height, RangeY) of
                no_range ->
                    no_range;
                {OffsetY, LengthY} ->
                    Image = image_area(Width, Height, LocalPixels, OffsetX, LengthX, OffsetY, LengthY),
                    {OffsetX, OffsetY, Image}
            end
    end.

-doc """
To be written.

To be written.
""".
-spec remote_image(object()) -> image().
remote_image({ResourceId, {Width, Height}, _, _, _, _, _LocalPixels}) ->
    {texture, Texture} = ResourceId,
    Data = texture_data(Texture, Width, Height),
    Pixels = data_to_pixels(Data),
    {Width, Height, Pixels}.

-doc """
To be written.

To be written.
""".
-spec remote_image(object(), slice:range(), slice:range()) ->
    no_range | {slice:offset(), slice:offset(), image()}.
remote_image(
    {_ResourceId, {Width, Height}, _, _, _, _, _LocalPixels} = Texture,
    RangeX,
    RangeY
) ->
    % XXX: No possible optimization (like retrieving a sub-region of the
    %      texture) unless using OpenGL 4.5 (glGetTextureSubImage).
    case slice:range(Width, RangeX) of
        no_range ->
            no_range;
        {OffsetX, LengthX} ->
            case slice:range(Height, RangeY) of
                no_range ->
                    no_range;
                {OffsetY, LengthY} ->
                    {Width, Height, Pixels} = remote_image(Texture),
                    Image = image_area(Width, Height, Pixels, OffsetX, LengthX, OffsetY, LengthY),
                    {OffsetX, OffsetY, Image}
            end
    end.

-doc """
To be written.

To be written.
""".
-spec local_pixel(object(), slice:index(), slice:index()) ->
    undefined | out_of_range | {slice:offset(), slice:offset(), graphics:color()}.
local_pixel({_, _, _, _, _, _, undefined}, _IndexX, _IndexY) ->
    undefined;
local_pixel({_, {Width, Height}, _, _, _, _, LocalPixels}, IndexX, IndexY) ->
    case slice:index(Width, IndexX) of
        out_of_range ->
            out_of_range;
        OffsetX ->
            case slice:index(Height, IndexY) of
                out_of_range ->
                    out_of_range;
                OffsetY ->
                    Pixel = image_pixel(Width, Height, LocalPixels, OffsetX, OffsetY),
                    {OffsetX, OffsetY, Pixel}
            end
    end.

-doc """
To be written.

To be written.
""".
-spec remote_pixel(object(), slice:index(), slice:index()) ->
    out_of_range | {slice:offset(), slice:offset(), graphics:color()}.
remote_pixel(
    {_, {Width, Height}, _, _, _, _, _LocalPixels} = Texture,
    IndexX,
    IndexY
) ->
    % XXX: No possible optimization (like retrieving a sub-region of the
    %      texture) unless using OpenGL 4.5 (glGetTextureSubImage).
    case slice:index(Width, IndexX) of
        out_of_range ->
            out_of_range;
         OffsetX ->
            case slice:index(Height, IndexY) of
                out_of_range ->
                    out_of_range;
                OffsetY ->
                    {Width, Height, Pixels} = remote_image(Texture),
                    Pixel = image_pixel(Width, Height, Pixels, OffsetX, OffsetY),
                    {OffsetX, OffsetY, Pixel}
            end
    end.

-doc """
To be written.

To be written.
""".
-spec update_image(object(), image()) -> {ok, object()}.
update_image(Texture, Image) ->
    update_image(Texture, Image, 0, 0).

-doc """
To be written.

To be written.
""".
-spec update_image(object(), image(), slice:offset(), slice:offset()) -> {ok, object()}.
update_image(
    {ResourceId, _, _, _, _, _, _LocalPixels} = Texture,
    Image,
    OffsetX,
    OffsetY
) ->
    {Width, Height, Pixels} = Image,
    Data = pixels_to_data(Pixels),
    {texture, GlTexture} = ResourceId,
    ok = update_texture_data(GlTexture, Width, Height, Data, OffsetX, OffsetY),
    % x = case LocalPixels of
    %     undefined ->
    %         {ResourceId, Width, Height, undefined};
    %     _ ->
    %         {ResourceId, Width, Height, Pixels}
    % end,
    % NewTexture = {ResourceId, Width, Height, undefined},
    % {ok, NewTexture}.
    {ok, Texture}.


-doc """
To be written.

To be written.
""".
-spec update_pixel(object(), graphics:color(), slice:offset(), slice:offset()) ->
    {ok, object()}.
update_pixel(
    {_ResourceId, {_With, _Height}, _, _, _, _, _LocalPixels},
    _Color,
    _X,
    _Y
) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec update_from_color(object(), graphics:color()) -> {ok, object()}.
update_from_color(Texture, Color) ->
    update_from_color(Texture, Color, {0, 0}).

-doc """
To be written.

To be written.
""".
-spec update_from_color(object(), graphics:color(), {slice:offset(), slice:offset()}) ->
    {ok, object()}.
update_from_color(
    {_ResourceId, {_With, _Height}, _, _, _, _, _LocalPixels},
    _Color,
    {_OffsetX, _OffsetY}
) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec update_from_texture(object(), graphics:texture()) ->
    {ok, object()}.
update_from_texture(Texture1, Texture2) ->
    update_from_texture(Texture1, Texture2, {0, 0}).

-doc """
To be written.

To be written.
""".
-spec update_from_texture(object(), graphics:texture(), {slice:offset(), slice:offset()}) ->
    {ok, object()}.
update_from_texture(
    {_ResourceId, {_With, _Height}, _, _, _, _, _LocalPixels},
    _Texture,
    {_OffsetX, _OffsetY}
) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec update_from_surface(object(), graphics:color()) ->
    {ok, object()}.
update_from_surface(Texture, Surface) ->
    update_from_surface(Texture, Surface, {0, 0}).

-doc """
To be written.

To be written.
""".
-spec update_from_surface(object(), graphics:color(), {slice:offset(), slice:offset()}) ->
    {ok, object()}.
update_from_surface(
    {_ResourceId, {_With, _Height}, _, _, _, _, _LocalPixels},
    _Surface,
    {_OffsetX, _OffsetY}
) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec minification_filter(object()) -> minification_filter().
minification_filter({_, _, _, MinificationFilter, _, _, _}) ->
    MinificationFilter.

-doc """
To be written.

To be written.
""".
-spec set_minification_filter(object(), minification_filter()) -> {ok, object()}.
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
To be written.

To be written.
""".
-spec magnification_filter(object()) -> magnification_filter().
magnification_filter({_, _, _, _, MagnificationFilter, _, _}) ->
    MagnificationFilter.

-doc """
To be written.

To be written.
""".
-spec set_magnification_filter(object(), magnification_filter()) -> {ok, object()}.
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
To be written.

To be written.
""".
-spec wrap_mode(object(), Axis :: horizontal | vertical) -> wrap_mode().
wrap_mode({_, _, _, _, _, {WrapMode, _}, _}, horizontal) ->
    WrapMode;
wrap_mode({_, _, _, _, _, {_, WrapMode}, _}, vertical) ->
    WrapMode.

-doc """
To be written.

To be written.
""".
-spec set_wrap_mode(object(), Axis :: horizontal | vertical, wrap_mode()) ->
    {ok, object()}.
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
To be written.

To be written.
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
To be written.

To be written.
""".
-spec gl_object(object()) -> gl:texture().
gl_object({{texture, Texture}, _, _, _, _, _, _}) ->
    Texture.

-doc """
To be written.

To be written.
""".
-spec has_local_copy(object()) -> boolean().
has_local_copy({_, _, _, _, _, _, undefined}) ->
    false;
has_local_copy({_, _, _, _, _, _, _}) ->
    true.

-doc """
To be written.

To be written.
""".
-spec keep_local_copy(object()) -> {ok, object()} | already_local_copy.
keep_local_copy({_, _, _, _, _, _, undefined} = Texture) ->
    LocalPixels = remote_image(Texture),
    NewTexture = erlang:setelement(7, Texture, LocalPixels),
    {ok, NewTexture};
keep_local_copy({_, _, _, _, _, _, _}) ->
    already_local_copy.

-doc """
To be written.

To be written.
""".
-spec release_local_copy(object()) -> {ok, object()} | no_local_copy.
release_local_copy({_, _, _, _, _, _, undefined}) ->
    no_local_copy;
release_local_copy(Texture) ->
    NewTexture = erlang:setelement(7, Texture, undefined),
    {ok, NewTexture}.

color_space_to_internal_format(linear) ->
    rgba32f;
color_space_to_internal_format(s_rgb) ->
    srgb8_alpha8.

pixels_to_data(Pixels) ->
    lists:foldl(
        fun({R, G, B, A}, Acc) ->
            <<
                Acc/binary,
                R:32/float-little,
                G:32/float-little,
                B:32/float-little,
                A:32/float-little
            >>
        end,
        <<>>,
        Pixels
    ).

data_to_pixels(Data) ->
    data_to_pixels(Data, []).

data_to_pixels(<<>>, Pixels) ->
    lists:reverse(Pixels);
data_to_pixels(Data, Pixels) ->
    <<
        R:32/float-little,
        G:32/float-little,
        B:32/float-little,
        A:32/float-little,
        DataRest/binary
    >> = Data,
    Pixel = {R, G, B, A},
    data_to_pixels(DataRest, [Pixel | Pixels]).

image_area(Width, _Height, LocalPixels, OffsetX, LengthX, OffsetY, LengthY) ->
    io:format(user, "Width: ~p, Height: ~p, OffsetX: ~p, LengthX: ~p, OffsetY: ~p, LengthY: ~p~n",
        [Width, length(LocalPixels) div Width, OffsetX, LengthX, OffsetY, LengthY]),
    % io:format(user, "tesT: ~p~n", [lists:seq(OffsetY, OffsetY + LengthY - 1)]),
    AreaPixels = lists:foldl(fun(Row, Acc) ->
        Offset = (Row-1) * Width,
        io:format(user, "Row: ~p, Offset: ~p, OffsetX: ~p, LengthX: ~p~n", [Row, Offset, OffsetX, LengthX]),
        Acc ++ lists:sublist(LocalPixels, Offset + OffsetX, LengthX)
    end, [], lists:seq(OffsetY, OffsetY + LengthY - 1)),
    {LengthX, LengthY, AreaPixels}.

image_pixel(Width, _Height, LocalPixels, OffsetX, OffsetY) ->
    Offset = (OffsetY-1) * Width,
    lists:nth(Offset + OffsetX, LocalPixels).

acquire_texture(Width, Height, Data, InternalFormat) when Width > 0 andalso Height > 0 ->
    ReleaseFun = fun({texture, Texture}) ->
        ok = gl:bind_texture(texture_2d, none),
        ok = gl:delete_textures([Texture]),
        ok
    end,
    AcquireFun = fun() ->
        {ok, [Texture]} = gl:gen_textures(1),
        ok = gl:bind_texture(texture_2d, Texture),

        ok = gl:tex_min_filter(texture_2d, linear),
        ok = gl:tex_mag_filter(texture_2d, linear),
        ok = gl:tex_wrap_s(texture_2d, clamp_to_edge),
        ok = gl:tex_wrap_t(texture_2d, clamp_to_edge),

        gl:pixel_store(unpack_alignment, 1),
        gl:pixel_store(pack_alignment, 1),

        ok = gl:tex_image_2d(
            texture_2d, 0, InternalFormat,
            Width, Height, 0,
            rgba, float,
            Data
        ),
        ok = gl:flush(),
        
        {ok, {texture, Texture}, ReleaseFun}
    end,
    graphics_context:acquire_resource(AcquireFun).

release_texture(ResourceId) ->
    graphics_context:release_resource(ResourceId).

texture_data(Texture, Width, Height) ->
    Size = Width * Height * 4 * 4, % 4 channels, 4 bytes each

    graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, Texture),
        {ok, Data} = gl:get_tex_image(
            texture_2d, 0,
            rgba, float,
            Size
        ),
        ok = gl:bind_texture(texture_2d, none),
        Data
    end).

update_texture_data(Texture, Width, Height, Data, OffsetX, OffsetY) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_texture(texture_2d, Texture),
        ok = gl:tex_sub_image_2d(
            texture_2d, 0,
            OffsetX, OffsetY,
            Width, Height,
            rgba, float,
            Data
        ),
        ok = gl:flush(),

        ok = gl:bind_texture(texture_2d, none),
        ok
    end).
