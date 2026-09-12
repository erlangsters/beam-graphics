# 2D Rendering

This document covers how to use the BEAM graphics library for 2D rendering.

2D and 3D share draw targets, textures, and programs. They do not share
vectors, matrices, meshes, or shapes. The 3D counterpart is
[3D Rendering](going-3d.md).

The stock pipeline treats a 2D position as a 3D position with Z set to `0.0`.
The 2D modules exist so that path does not have to be written by hand.

Include `graphics.hrl` for the named color and matrix macros used below.

```erlang
-include_lib("beam_graphics/include/graphics.hrl").
```

**Table of Contents**

- [Values](#values)
- [View and camera](#view-and-camera)
- [Draw target](#draw-target)
- [Drawing with shapes](#drawing-with-shapes)
- [Drawing with meshes](#drawing-with-meshes)
- [Transforming](#transforming)
- [Adjusting the view](#adjusting-the-view)
- [Next steps](#next-steps)

## Values

A well-formed 2D value uses floats, not integers. Invalid tuple shape is
`function_clause`.

### The 2D vector

A 2D vector is a pair of floats. Tuple syntax is the constructor.

```erlang
V = {3.0, 4.0}.
3.0 = vector2:x(V).
4.0 = vector2:y(V).
5.0 = vector2:length(V).
{0.6, 0.8} = vector2:normalize(V).
```

`vector2:multiply/2` is scalar multiplication. The 2D cross product is a
scalar. Rotation is counter-clockwise around the origin. Polar conversion
(`to_angle/1`, `from_angle/1`) is 2D-only.

See the `vector2` module.

### The 3x3 matrix

A 3x3 matrix is a flat 9-float tuple in column-major order. It is the 2D
transform type. Prefer `transform2` for translation, rotation, and scale.

```erlang
I = matrix3:identity().
{11.0, 22.0} = matrix3:multiply_vector(
    transform2:translation({10.0, 20.0}),
    {1.0, 2.0}
).
```

`matrix3:multiply/2` is the matrix product. `matrix3:scale/2` is scalar
multiplication. `matrix3:multiply_vector/2` treats the vector as a point
(homogeneous `w = 1.0`). Embed a 3x3 as a 4x4 with `matrix3:to_matrix4/1`
when a surface or frame needs a view or projection matrix.

See the `matrix3` module.

### Color

A color is `{Red, Green, Blue, Alpha}`. Channels are floats, typically in
`[0.0, 1.0]`. There is one color type for 2D and 3D.

```erlang
{1.0, 0.0, 0.0, 1.0} = color:rgb(1.0, 0.0, 0.0).
?COLOR_RED = {1.0, 0.0, 0.0, 1.0}.
```

See the `color` module.

### The 2D vertex

A 2D vertex is `{Position, Color, U, V}`. There is no `vertex2` module.

```erlang
{{100.0, 100.0}, ?COLOR_RED, 0.0, 0.0}.
```

`U` and `V` are texture coordinates. Generated solid shapes use `{0.0, 0.0}`.
Textured quads use the unit square; see [Texturing](texturing.md).

### The 2D box

A 2D box is `{Min, Max}`. `Min =< Max` per component. Tuple syntax is the
constructor.

```erlang
Box = {{0.0, 0.0}, {10.0, 20.0}}.
{5.0, 10.0} = box2:center(Box).
true = box2:contains(Box, {5.0, 5.0}).
```

`from_center_size/2` uses full width and height, not half-extents. A rotated
box is a larger axis-aligned box; that rebuild lives on
`transform2:transform_box/2`.

See the `box2` module.

### The 2D transform

There is no transform type. `transform2` constructs and applies 3x3 matrices.

Nouns construct (`translation/1`, `rotation/1`, `scale/1`). Verbs combine
(`translate/2`, `rotate/2`, `scale/2`) by post-multiplying, so the new
operation runs in local space.

```erlang
M = transform2:compose({100.0, 50.0}, math:pi() / 4.0, {2.0, 2.0}).
{110.0, 70.0} = transform2:transform_point(
    transform2:translation({10.0, 20.0}),
    {100.0, 50.0}
).
```

`compose/3` is translate after rotate after scale, with a zero origin.
`compose/4` inserts `T(-Origin)` first. `decompose/1` is 2D-only and assumes
no shear.

See the `transform2` module.

## View and camera

A 2D view is a 3x3 projection matrix. A 2D camera is an observer pose. They
are separate on purpose: the view is `uProjection`, the camera is `uView`.

There is no view wrapper type. `view2:orthographic/4` maps a rectangle of
view space to clip space. Y increases upward when Bottom is less than Top.

```erlang
P = view2:orthographic(0.0, 640.0, 0.0, 480.0).
P = view2:orthographic({{0.0, 0.0}, {640.0, 480.0}}).
```

A 2D camera is `{Center, Rotation, Zoom}`.

```erlang
Camera = camera2:from_center({320.0, 240.0}).
{{320.0, 240.0}, 0.0, 1.0} = Camera.
V = camera2:view_matrix(Camera).
```

Rotation is counter-clockwise in the world. Zoom greater than `1.0` makes
objects appear larger. A 2D camera does not convert to a 3D camera.

See the `view2` and `camera2` modules.

## Draw target

Rendering needs a running graphics context and a draw target.

```erlang
Display = egl:get_display(default_display),
{ok, {_, _}} = egl:initialize(Display),
ok = graphics:initialize(Display).
```

A **surface** presents. A pbuffer is created with `surface:with_size/2`. A
window is created with `surface:with_window/3`; see
[Display on a Window](display-window.md). `image/1` reads CPU pixels.
`display/1` presents.

A **frame** is offscreen. Its result is a GPU texture, with no presentation
and no CPU round-trip. See [Texturing](texturing.md).

There is no `surface2` or `frame2`. The same draw target accepts 2D and 3D
draws.

```erlang
{ok, Surface} = surface:with_size(Display, {640, 480}),
ok = surface:clear(Surface, ?COLOR_BLACK).
```

Defaults: view identity, projection an orthographic map of the pixel size
(`0` to width, `0` to height, Y up), viewport the full size, blend mode
`none`, depth test `enabled`. Overlapping 2D draws share Z, so disable the
depth test. Transparent 2D also needs blend mode `alpha`.

```erlang
{ok, Surface} = surface:set_depth_test(Surface, disabled).
```

Viewport, blend, depth, view, and projection live on the Erlang term. Setters
return `{ok, NewTarget}`. Rebind the variable. The GPU sees the new values
on the next `clear` or `draw`.

When the image is ready:

```erlang
Image = surface:image(Surface),
ok = surface:destroy(Surface),
ok = graphics:terminate().
```

On a window, call `surface:display/1` instead of (or before) reading pixels.
After `display/1`, the window back buffer is undefined.

See the `surface`, `frame`, and `graphics_context` modules.

## Drawing with shapes

A 2D shape is the usual drawable: one or more meshes, a 3x3 model matrix, and
an optional texture. Primitive constructors allocate a mesh.

```erlang
{ok, Triangle} = shape2:triangle(
    {320.0, 360.0},
    {220.0, 120.0},
    {420.0, 120.0},
    ?COLOR_RED
),
ok = surface:draw_shape2(Surface, Triangle),
ok = shape2:destroy(Triangle).
```

Shared primitives: `point/2`, `line/3`, `triangle/4`, `triangle_wires/4`.

2D-only primitives:

- `rectangle/3`, `rectangle_outline/4`, `rectangle_wires/3` — minimum corner
  and full size, extending `+X` / `+Y`
- `circle/3,4`, `circle_outline/4,5`, `circle_wires/3,4` — center and radius,
  default 32 segments

Outline thickness is signed. Positive grows inwards. Negative grows outwards.
There is no 3D outline.

Generated vertices use UV `{0.0, 0.0}`. Binding a texture therefore samples
one texel. A textured rectangle is `sprite:from_texture/3`; see
[Texturing](texturing.md).

`destroy/1` destroys the meshes. It does not destroy the texture. Destroying
the same shape twice is invalid.

See the `shape2` module.

## Drawing with meshes

A 2D mesh is a GPU buffer of 2D vertices. Together with 3D meshes, meshes are
the only means for rendering. Shapes, sprites, and text are wrappers around
meshes.

The primitive type and the texture are draw arguments, not mesh state.

```erlang
{ok, Mesh} = mesh2:with_vertices([
    {{100.0, 100.0}, ?COLOR_RED, 0.0, 0.0},
    {{300.0, 100.0}, ?COLOR_GREEN, 0.0, 0.0},
    {{200.0, 250.0}, ?COLOR_BLUE, 0.0, 0.0}
]),
ok = surface:draw_mesh2(Surface, Mesh, triangles, 3),
ok = mesh2:destroy(Mesh).
```

Primitive types: `points`, `lines`, `line_strip`, `line_loop`, `triangles`,
`triangle_strip`, `triangle_fan`.

Wrap a mesh as a shape when several draws should share a matrix and a
texture:

```erlang
Shape = shape2:with_mesh(Mesh, triangles, 3).
```

`with_mesh` does not allocate. The vertex count is the draw count. It is not
required to equal `mesh2:vertex_count/1`.

The default usage hint is `static`. The default copy policy is `no_copy`.
See [Graphical Resources](graphical-resources.md) for usage hints, local
copies, and ownership.

See the `mesh2` module.

## Transforming

Describe geometry in its own space. Move it with a model matrix.

On a shape, `set_matrix/2` returns a new shape. The GPU buffers are not
copied.

```erlang
{ok, Rect} = shape2:rectangle({-50.0, -25.0}, {100.0, 50.0}, ?COLOR_RED),
Moved = shape2:set_matrix(Rect, transform2:translation({320.0, 240.0})),
ok = surface:draw_shape2(Surface, Moved).
```

`compose/3` and `compose/4` cover origin, position, rotation, and scale:

```erlang
M = transform2:compose(
    {50.0, 25.0},
    {320.0, 240.0},
    math:pi() / 8.0,
    {1.0, 1.0}
),
Rotated = shape2:set_matrix(Rect, M).
```

`draw_mesh2/6` takes the 3x3 model matrix directly. Combinators post-multiply:

```erlang
M1 = transform2:translate(matrix3:identity(), {320.0, 240.0}),
M2 = transform2:rotate(M1, math:pi() / 4.0),
ok = surface:draw_mesh2(Surface, Mesh, triangles, 3, no_texture, M2).
```

See the `transform2` module.

## Adjusting the view

The default projection already maps pixel coordinates `(0, 0)` ..
`(Width, Height)` with Y up and the view set to identity. Many 2D programs
never change it.

To choose a visible rectangle, set the projection from `view2`. To move the
observer, set the view from `camera2`. Both matrices are 3x3. A surface and
a frame store 4x4 view and projection uniforms; embed with
`matrix3:to_matrix4/1`.

```erlang
{ok, Surface} = surface:set_projection_matrix(
    Surface,
    matrix3:to_matrix4(view2:orthographic(0.0, 640.0, 0.0, 480.0))
),
Camera = camera2:from_center({320.0, 240.0}, 0.0, 1.0),
{ok, Surface} = surface:set_view_matrix(
    Surface,
    matrix3:to_matrix4(camera2:view_matrix(Camera))
).
```

Swap Bottom and Top in `orthographic/4` to flip Y. A well-formed `box2`
cannot represent that flip; use the four-argument form.

Draw-target state is applied at clear and draw time:

- `set_viewport/2` — lower-left origin, pixel units
- `set_blend_mode/2` — `none | alpha | add | multiply`, default `none`
- `set_depth_test/2` — `enabled | disabled`, default `enabled`

Clearing writes the clear color directly. Blending does not affect `clear/2`.

See the `view2`, `camera2`, and `surface` modules.

## Next steps

- [Texturing](texturing.md) — textures, sprites, and frames as textures
- [Graphical Resources](graphical-resources.md) — ownership, `destroy/1`,
  local copies
- [Going Native](going-native.md) — custom programs and OpenGL commands
- [3D Rendering](going-3d.md) — the same outline in three dimensions
- [Fancy Shapes](fancy-shapes.md) and [Text Rendering](text-rendering.md) —
  companion libraries
