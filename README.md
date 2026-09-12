# Graphics library for the BEAM

> :construction: This project is under active development. Do not used at the
> moment as it's not ready. Consult the `develop` branch for progress.

[![Erlangsters Repository](https://img.shields.io/badge/erlangsters-beam--graphics-%23a90432)](https://github.com/erlangsters/beam-graphics)
![Supported Erlang/OTP Versions](https://img.shields.io/badge/erlang%2Fotp-28-%23a90432)
![Current Version](https://img.shields.io/badge/version-0.1.0-%23354052)
![License](https://img.shields.io/github/license/erlangsters/beam-graphics)
[![Build Status](https://img.shields.io/github/actions/workflow/status/erlangsters/beam-graphics/workflow.yml)](https://github.com/erlangsters/beam-graphics/actions/workflows/workflow.yml)
[![Documentation Link](https://img.shields.io/badge/documentation-available-yellow)](http://erlangsters.github.io/beam-graphics/)

The missing graphics library of the BEAM ecosystem available for the Erlang and
Elixir programming language.

Inspired by leading multimedia frameworks, it provides a general-purpose API
for graphics rendering. It is built on top of EGL and OpenGL, and all major
platforms are supported.

> It does not provide any window capabilities. You may want to use
> [GLFW](https://github.com/erlangsters/glfw) to display the graphics on
> the screen. See [Display on a Window](docs/display-window.md).

Companion libraries that extend it are also available.

- 2D/3D shapes: https://github.com/erlangsters/beam-graphics-shapes
- Image loader/saver: https://github.com/erlangsters/beam-graphics-image
- Text rendering: https://github.com/erlangsters/beam-graphics-text

For advanced uses, mixing with the underlying OpenGL library is also
possible. See [Going Native](docs/going-native.md).

Written by the Erlangsters [community](https://about.erlangsters.org/) and
released under the MIT [license](https://opensource.org/license/mit).

## Using it in your project

With the **Rebar3** build system, add the following to the `rebar.config` file
of your project.

```erlang
{deps, [
    {beam_graphics, {git, "https://github.com/erlangsters/beam-graphics.git", {tag, "master"}}}
]}.
```

In practice, you want to replace the branch "master" with a specific tag to
avoid breaking your project if incompatible changes are made.

Named colors and matrix macros live in `graphics.hrl`.

```erlang
-include_lib("beam_graphics/include/graphics.hrl").
```

## Getting started

Start an EGL display and the graphics context. Then create a surface, which
is a presentable 2D image used as a render target.

```erlang
Display = egl:get_display(default_display),
{ok, {_, _}} = egl:initialize(Display),
ok = graphics:initialize(Display),

{ok, Surface} = graphics_surface:with_size(Display, {640, 480}).
```

A running graphics context is required. The default projection maps pixel
coordinates with Y up. The default depth test is `enabled`. Overlapping 2D
draws share Z, so disable it before drawing 2D.

```erlang
{ok, Surface} = graphics_surface:set_depth_test(Surface, disabled),
ok = graphics_surface:clear(Surface, ?COLOR_BLACK),

{ok, Triangle} = graphics_shape2:triangle(
    {320.0, 360.0},
    {220.0, 120.0},
    {420.0, 120.0},
    ?COLOR_RED
),
ok = graphics_surface:draw_shape2(Surface, Triangle),
Image = graphics_surface:image(Surface),

ok = graphics_shape2:destroy(Triangle),
ok = graphics_surface:destroy(Surface),
ok = graphics:terminate().
```

A frame is an offscreen target whose result is a texture. Both a surface and
a frame accept 2D and 3D draws. Viewport, blend, depth, view, and projection
live on the draw-target term; setters return `{ok, NewTarget}`. Rebind the
variable.

Beware that a well-formed position, matrix, and color always use floats, not
integers.

The rest of this page continues from a live `Display` and `Surface`. The
guides cover the same ground in more detail:

- [2D Rendering](docs/going-2d.md)
- [3D Rendering](docs/going-3d.md)
- [Texturing](docs/texturing.md)
- [Graphical Resources](docs/graphical-resources.md)

## Going 2D

A 2D shape is the usual drawable. Describe it in its own space and move it
with a model matrix. `set_matrix/2` returns a new shape; the GPU buffers are
not copied.

```erlang
{ok, Rect} = graphics_shape2:rectangle({-50.0, -25.0}, {100.0, 50.0}, ?COLOR_RED),
Moved = graphics_shape2:set_matrix(Rect, graphics_transform2:translation({320.0, 240.0})),
ok = graphics_surface:draw_shape2(Surface, Moved),
ok = graphics_shape2:destroy(Rect).
```

A 2D view is a projection. A 2D camera is an observer. Both are 3x3 matrices.
A surface stores 4x4 view and projection uniforms; embed with
`graphics_matrix3:to_matrix4/1`.

```erlang
{ok, Surface} = graphics_surface:set_projection_matrix(
    Surface,
    graphics_matrix3:to_matrix4(graphics_view2:orthographic(0.0, 640.0, 0.0, 480.0))
),
Camera = graphics_camera2:from_center({320.0, 240.0}),
{ok, Surface} = graphics_surface:set_view_matrix(
    Surface,
    graphics_matrix3:to_matrix4(graphics_camera2:view_matrix(Camera))
).
```

Meshes are the GPU buffers underneath. Primitive type and texture are draw
arguments, not mesh state. See [2D Rendering](docs/going-2d.md).

## Going 3D

Replace the default pixel projection with a perspective view and a look-at
camera. Keep the depth test enabled.

```erlang
{ok, Surface} = graphics_surface:set_depth_test(Surface, enabled),
{ok, Surface} = graphics_surface:set_projection_matrix(
    Surface,
    graphics_view3:perspective(math:pi() / 4.0, 640.0 / 480.0, 0.1, 100.0)
),
Camera = graphics_camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}),
{ok, Surface} = graphics_surface:set_view_matrix(
    Surface,
    graphics_camera3:view_matrix(Camera)
),
{ok, Cube} = graphics_shape3:cube({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, ?COLOR_RED),
ok = graphics_surface:draw_shape3(Surface, Cube),
ok = graphics_shape3:destroy(Cube).
```

A sprite is a 2D rectangle. Textured 3D geometry is built with
`graphics_shape3:with_mesh/4`. See [3D Rendering](docs/going-3d.md).

## Displaying an image

Rendering is done on a surface. This library does not create windows and it
does not encode image files.

To present on a window, create a GLFW window and attach a surface to its EGL
handle. `display/1` presents. After it, the window back buffer is undefined.

```erlang
true = glfw:init(),
{ok, Window} = glfw:create_window(640, 480, "beam-graphics"),
Handle = glfw:window_egl_handle(Window),
{ok, Surface} = graphics_surface:with_window(Display, Handle, {640, 480}),
ok = graphics_surface:clear(Surface, ?COLOR_BLACK),
ok = graphics_surface:draw_shape2(Surface, Shape),
ok = graphics_surface:display(Surface).
```

See [Display on a Window](docs/display-window.md).

To save pixels, read the surface and encode with
[beam-graphics-image](https://github.com/erlangsters/beam-graphics-image).

```erlang
Image = graphics_surface:image(Surface),
ok = graphics_image_png:save(Image, "screenshot.png").
```

An offscreen GPU target with no CPU round-trip is a `graphics_frame`. Sample
`graphics_frame:texture/1` later. See [Texturing](docs/texturing.md).

## Going native

The stock pipeline covers position, color, UV, a model matrix, a view, a
projection, and an optional texture. Draw does not take a program.

To compile your own shaders, build a `graphics_program` and issue OpenGL commands
while the intended context is current. On a surface that is `gl_commands/2`.
On the graphics context, and on a frame, that is `execute_commands/1`.

```erlang
{ok, Program} = graphics_program:with_shaders(VertexSrc, FragmentSrc),
ok = graphics_program:set_uniform(Program, "uModel", graphics_matrix4:identity()),
_ = graphics_surface:gl_commands(Surface, fun() ->
    ok = gl:use_program(graphics_program:gl_object(Program)),
    ok
end),
ok = graphics_program:destroy(Program).
```

Uniform writes through `graphics_program:set_uniform/3` hop to the graphics context.
They are not reliably visible on a surface context. Set uniforms with
`gl:program_uniform*` inside `gl_commands/2` when drawing on a surface.

See [Going Native](docs/going-native.md).

## Companion libraries

Core primitives stay small: point, line, triangle, plus rectangle and circle
in 2D and cube and sphere in 3D. The broader catalog is
[beam-graphics-shapes](https://github.com/erlangsters/beam-graphics-shapes).
Those modules construct a core `graphics:shape2()` or `graphics:shape3()`.

```erlang
{ok, Ellipse} = graphics_shape2_ellipse:solid({320.0, 240.0}, {80.0, 40.0}, ?COLOR_RED),
ok = graphics_surface:draw_shape2(Surface, Ellipse),
ok = graphics_shape2:destroy(Ellipse).
```

See [Fancy Shapes](docs/fancy-shapes.md).

[beam-graphics-image](https://github.com/erlangsters/beam-graphics-image)
decodes and encodes PNG, JPEG, and BMP as a `graphics:image()`. It does not
create a GPU texture.

```erlang
{ok, Image} = graphics_image_png:load("sprite.png"),
{ok, Texture} = graphics_texture:with_image(Image).
```

See [Texturing](docs/texturing.md).

[beam-graphics-text](https://github.com/erlangsters/beam-graphics-text) loads
a font and constructs a `graphics:shape2()` of glyph quads. Draw with blend
mode `alpha`. The font owns the atlas texture; the text shape does not.

```erlang
{ok, Font} = graphics_font:from_file("font.ttf", 32.0),
{ok, Shape} = graphics_text:from_string(Font, {0.0, 0.0}, "Hello", ?COLOR_WHITE),
{ok, Surface} = graphics_surface:set_blend_mode(Surface, alpha),
ok = graphics_surface:draw_shape2(Surface, Shape),
ok = graphics_shape2:destroy(Shape),
ok = graphics_font:destroy(Font).
```

See [Text Rendering](docs/text-rendering.md).
