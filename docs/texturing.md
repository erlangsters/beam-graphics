# Texturing

This document covers textures, UV coordinates, sprites, and using a frame as
a texture. The same texture module is used for 2D and 3D drawing. There is
no `texture2` or `texture3`.

A well-formed color always uses floats, not integers.

**Table of Contents**

- [Images and textures](#images-and-textures)
- [Sampling](#sampling)
- [Drawing with a texture](#drawing-with-a-texture)
- [Sprites](#sprites)
- [Frames as textures](#frames-as-textures)
- [Loading and saving images](#loading-and-saving-images)

## Images and textures

The CPU payload is `graphics:image()`: `{Width, Height, Pixels}`. Width and
height are at least 1. `length(Pixels)` must equal `Width * Height`. Pixels
are row-major: X varies fastest, then Y. Slice index `(0, 0)` is the first
pixel and UV `(0, 0)`. Texture does not Y-flip.

```erlang
{ok, Texture} = graphics_texture:with_image({2, 2, [
    ?COLOR_RED, ?COLOR_GREEN,
    ?COLOR_BLUE, ?COLOR_WHITE
]}).
```

`with_color/2` fills a size with one color. Empty textures are not allowed.

A texture is a GPU object. Copying the term does not copy the GPU texture.
Dispose it with `graphics_texture:destroy/1`. A running graphics context is required.

Color space is `linear` or `srgb` and is chosen when the GPU storage is
allocated. The default is `linear`. CPU colors are float channels. GPU
storage is 8-bit RGBA. Named colors round-trip. Arbitrary floats do not.

See the `graphics_texture` module.

## Sampling

Sampler state lives on the texture. Constructors do not take filters or wrap.

Defaults: minification and magnification `linear`, wrap `clamp_to_edge` on
both axes.

```erlang
{ok, Texture} = graphics_texture:set_minification_filter(Texture, nearest),
{ok, Texture} = graphics_texture:set_magnification_filter(Texture, nearest),
{ok, Texture} = graphics_texture:set_wrap_mode(Texture, horizontal, repeat),
{ok, Texture} = graphics_texture:set_wrap_mode(Texture, vertical, repeat).
```

Wrap axes are `horizontal` and `vertical`. Wrap modes are `repeat`,
`clamp_to_edge`, and `mirrored_repeat`.

`generate_mipmap/1` builds mipmaps on the GPU. A mipmap minification filter
without that call is an incomplete texture.

The stock program modulates vertex color by the bound texture. That is tint,
not framebuffer blending. White vertex color leaves the texture unmodulated.

## Drawing with a texture

The primitive type and the texture are draw arguments, not mesh state.

```erlang
{ok, Mesh} = graphics_mesh2:with_vertices([
    {{100.0, 100.0}, ?COLOR_WHITE, 0.0, 0.0},
    {{700.0, 100.0}, ?COLOR_WHITE, 1.0, 0.0},
    {{700.0, 500.0}, ?COLOR_WHITE, 1.0, 1.0},
    {{100.0, 500.0}, ?COLOR_WHITE, 0.0, 1.0}
]),
ok = graphics_surface:draw_mesh2(Surface, Mesh, triangle_fan, 4, Texture).
```

On a shape, several meshes share one graphics_texture:

```erlang
Shape = graphics_shape2:with_mesh(Mesh, triangle_fan, 4, Texture),
ok = graphics_surface:draw_shape2(Surface, Shape).
```

`graphics_shape2:set_texture/2` returns a new shape. It does not destroy the previous
texture.

Generated solid primitives use UV `{0.0, 0.0}`. Binding a texture on them
samples a single texel. Give the mesh explicit UVs, or use a sprite.

The same calls exist on `graphics_frame` and for `graphics_mesh3` / `graphics_shape3`. There is no
`sprite3`; textured 3D geometry stays on `graphics_shape3:with_mesh/4`.

Transparent texels need blend mode `alpha` on the draw target:

```erlang
{ok, Surface} = graphics_surface:set_blend_mode(Surface, alpha).
```

## Sprites

A sprite is a textured 2D rectangle. There is no sprite type. `graphics_sprite`
constructs a `graphics:shape2()`.

```erlang
{ok, Sprite} = graphics_sprite:from_texture({0.0, 0.0}, {64.0, 64.0}, Texture),
ok = graphics_surface:draw_shape2(Surface, Sprite),
ok = graphics_shape2:destroy(Sprite).
```

`Position` is the minimum corner. `Size` is the full width and height. The
rectangle extends in `+X` and `+Y`, matching `graphics_shape2:rectangle/3`. Vertex UVs
span `(0.0, 0.0)` to `(1.0, 1.0)`. Vertex color defaults to white. Pass a
color as the last argument to tint.

The texture is not owned. `graphics_shape2:destroy/1` destroys the mesh and does not
destroy the texture. Pixel size is not world size; there is no constructor
that reads `graphics_texture:size/1`.

See the `graphics_sprite` module.

## Frames as textures

A frame is an offscreen draw target whose result is a GPU texture. That
avoids a CPU round-trip. A surface presents and can read CPU pixels. A frame
does not present.

```erlang
{ok, Frame} = graphics_frame:with_size({256, 256}),
ok = graphics_frame:clear(Frame, ?COLOR_BLACK),
ok = graphics_frame:draw_shape2(Frame, Shape),
Texture = graphics_frame:texture(Frame),
ok = graphics_surface:draw_mesh2(Surface, Quad, triangle_fan, 4, Texture).
```

The frame owns that texture. `graphics_frame:destroy/1` destroys it. Do not call
`graphics_texture:destroy/1` on it while the frame is alive. Using the texture after
the frame is destroyed has undefined behavior.

Drawing a mesh with `graphics_frame:texture(Frame)` as the texture argument while that
frame is the draw target is undefined.

Read CPU pixels from a frame with `graphics_texture:remote_image(graphics_frame:texture(Frame))`.
Frame has no CPU image function of its own.

See the `graphics_frame` module.

## Loading and saving images

This library does not decode file formats. `beam-graphics-image` loads and
saves PNG, JPEG, and BMP as a `graphics:image()`. Upload with
`graphics_texture:with_image/1`. Save a surface with `graphics_surface:image/1`.

```erlang
{ok, Image} = graphics_image_png:load("sprite.png"),
{ok, Texture} = graphics_texture:with_image(Image).
```

```erlang
Image = graphics_surface:image(Surface),
ok = graphics_image_png:save(Image, "screenshot.png").
```

The codec does not Y-flip. That matches `graphics_texture`.

See [https://github.com/erlangsters/beam-graphics-image](https://github.com/erlangsters/beam-graphics-image).
