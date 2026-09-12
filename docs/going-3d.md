# 3D Rendering

This document covers how to use the BEAM graphics library for 3D rendering.

2D and 3D share draw targets, textures, and programs. They do not share
vectors, matrices, meshes, or shapes. The 2D counterpart is
[2D Rendering](going-2d.md).

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

A well-formed 3D value uses floats, not integers. Invalid tuple shape is
`function_clause`.

### The 3D vector

A 3D vector is a triplet of floats. Tuple syntax is the constructor.

```erlang
V = {1.0, 2.0, 3.0}.
1.0 = vector3:x(V).
2.0 = vector3:y(V).
3.0 = vector3:z(V).
```

`vector3:multiply/2` is scalar multiplication. The 3D cross product is a
vector. `rotate/3` is Rodrigues rotation around an axis. There is no polar
`to_angle` / `from_angle`; that conversion is 2D-only.

See the `vector3` module.

### The 4x4 matrix

A 4x4 matrix is a flat 16-float tuple in column-major order. It is the 3D
transform type. Prefer `transform3` for translation, rotation, and scale.

```erlang
I = matrix4:identity().
{11.0, 22.0, 33.0} = matrix4:multiply_vector(
    transform3:translation({10.0, 20.0, 30.0}),
    {1.0, 2.0, 3.0}
).
```

`matrix4:multiply/2` is the matrix product. `matrix4:scale/2` is scalar
multiplication. `matrix4:multiply_vector/2` treats the vector as a point
(homogeneous `w = 1.0`). Extract the 2D affine block with `matrix4:to_matrix3/1`.

See the `matrix4` module.

### Color

A color is `{Red, Green, Blue, Alpha}`. There is one color type for 2D and 3D.

```erlang
{0.0, 0.0, 1.0, 1.0} = color:rgb(0.0, 0.0, 1.0).
?COLOR_BLUE = {0.0, 0.0, 1.0, 1.0}.
```

See the `color` module.

### The 3D vertex

A 3D vertex is `{Position, Color, U, V}`. There is no `vertex3` module.

```erlang
{{0.0, 1.0, 0.0}, ?COLOR_RED, 0.0, 0.0}.
```

`U` and `V` are still two floats. There are no vertex normals in this API.
Textured 3D geometry is built with `shape3:with_mesh/4`; see
[Texturing](texturing.md).

### The 3D box

A 3D box is `{Min, Max}`. `Min =< Max` per component. Tuple syntax is the
constructor.

```erlang
Box = {{0.0, 0.0, 0.0}, {10.0, 20.0, 30.0}}.
{5.0, 10.0, 15.0} = box3:center(Box).
true = box3:contains(Box, {5.0, 5.0, 5.0}).
```

`from_center_size/2` uses full width, height, and length. `corners/1` returns
eight points. A rotated box is a larger axis-aligned box; that rebuild lives
on `transform3:transform_box/2`.

See the `box3` module.

### The 3D transform

There is no transform type. `transform3` constructs and applies 4x4 matrices.

Nouns construct (`translation/1`, `rotation/2`, `scale/1`). Verbs combine
(`translate/2`, `rotate/3`, `scale/2`) by post-multiplying, so the new
operation runs in local space.

```erlang
M = transform3:compose(
    {0.0, 0.0, 0.0},
    {math:pi() / 4.0, {0.0, 1.0, 0.0}},
    {1.0, 1.0, 1.0}
).
{11.0, 22.0, 33.0} = transform3:transform_point(
    transform3:translation({10.0, 20.0, 30.0}),
    {1.0, 2.0, 3.0}
).
```

3D rotation takes an angle and an axis. `rotation_x/1`, `rotation_y/1`, and
`rotation_z/1` are constructors only; there are no `rotate_x/2` combinators.
`compose/3` rotation is `{Angle, Axis}`. There is no 3D `decompose/1`.

See the `transform3` module.

## View and camera

A 3D view is a 4x4 projection matrix. A 3D camera is an observer pose. They
are separate on purpose: the view is `uProjection`, the camera is `uView`.
`look_at` lives on `camera3`, not on `view3`.

There is no view wrapper type. `view3` constructs orthographic, perspective,
and frustum matrices. The convention is OpenGL right-handed, clip Z in
`[-1, 1]`. Y increases upward when Bottom is less than Top.

```erlang
P = view3:perspective(math:pi() / 4.0, 640.0 / 480.0, 0.1, 100.0).
O = view3:orthographic(-1.0, 1.0, -1.0, 1.0, 0.1, 100.0).
```

`perspective/4` takes a vertical field of view in radians and an aspect ratio
of width over height. `frustum/6` is the general asymmetric perspective.
There is no `orthographic(Box3)`: a box's Z is world Z, not camera near/far.

A 3D camera is `{Position, Target, Up}`.

```erlang
Camera = camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}).
{{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}} = Camera.
V = camera3:view_matrix(Camera).
```

`look_at/2` uses up `{0.0, 1.0, 0.0}`. `look_to/2` sets the target to the
position plus the direction. The camera looks down `-Z` in view space.
Stored `up` need not be unit or orthogonal; `view_matrix/1` orthonormalizes
it. `translate/2` moves position and target together.

See the `view3` and `camera3` modules.

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

There is no `surface3` or `frame3`. The same draw target accepts 2D and 3D
draws.

```erlang
{ok, Surface} = surface:with_size(Display, {640, 480}),
ok = surface:clear(Surface, ?COLOR_BLACK).
```

Defaults: view identity, projection an orthographic map of the pixel size,
viewport the full size, blend mode `none`, depth test `enabled`. That default
projection is a 2D pixel map. 3D work almost always replaces it with
`view3:perspective/4` or `view3:orthographic/6`. Keep the depth test enabled
unless overlapping transparent draws need otherwise.

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

A 3D shape is the usual drawable: one or more meshes, a 4x4 model matrix, and
an optional texture. Primitive constructors allocate a mesh.

```erlang
{ok, Cube} = shape3:cube({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, ?COLOR_RED),
ok = surface:draw_shape3(Surface, Cube),
ok = shape3:destroy(Cube).
```

Shared primitives: `point/2`, `line/3`, `triangle/4`, `triangle_wires/4`.

3D-only primitives:

- `cube/3`, `cube_wires/3` — center and full size. The name is conventional;
  the extents need not be equal
- `sphere/3,5`, `sphere_wires/3,5` — center and radius, default 16 rings and
  16 slices

There is no 3D outline and no 3D quad or plane. A shell with thickness
belongs in the companion catalog. There is no `sprite3`.

Generated vertices use UV `{0.0, 0.0}`. Binding a texture therefore samples
one texel. Textured 3D geometry is built with `with_mesh/4` and explicit UVs.

`destroy/1` destroys the meshes. It does not destroy the texture. Destroying
the same shape twice is invalid.

See the `shape3` module.

## Drawing with meshes

A 3D mesh is a GPU buffer of 3D vertices. Together with 2D meshes, meshes are
the only means for rendering. Shapes are wrappers around meshes.

The primitive type and the texture are draw arguments, not mesh state.

```erlang
{ok, Mesh} = mesh3:with_vertices([
    {{0.0, 0.5, 0.0}, ?COLOR_RED, 0.0, 0.0},
    {{-0.5, -0.5, 0.0}, ?COLOR_GREEN, 0.0, 0.0},
    {{0.5, -0.5, 0.0}, ?COLOR_BLUE, 0.0, 0.0}
]),
ok = surface:draw_mesh3(Surface, Mesh, triangles, 3),
ok = mesh3:destroy(Mesh).
```

Primitive types: `points`, `lines`, `line_strip`, `line_loop`, `triangles`,
`triangle_strip`, `triangle_fan`.

Wrap a mesh as a shape when several draws should share a matrix and a
texture:

```erlang
Shape = shape3:with_mesh(Mesh, triangles, 3).
```

`with_mesh` does not allocate. The vertex count is the draw count. It is not
required to equal `mesh3:vertex_count/1`.

There is no conversion from a 3D mesh to a 2D mesh. GPU conversion is
allocation plus ownership, not a lossless value conversion.

The default usage hint is `static`. The default copy policy is `no_copy`.
See [Graphical Resources](graphical-resources.md) for usage hints, local
copies, and ownership.

See the `mesh3` module.

## Transforming

Describe geometry in its own space. Move it with a model matrix.

On a shape, `set_matrix/2` returns a new shape. The GPU buffers are not
copied.

```erlang
{ok, Cube} = shape3:cube({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, ?COLOR_RED),
Moved = shape3:set_matrix(Cube, transform3:translation({0.0, 0.5, 0.0})),
ok = surface:draw_shape3(Surface, Moved).
```

`compose/3` and `compose/4` cover origin, position, rotation, and scale.
3D rotation is `{Angle, Axis}`:

```erlang
M = transform3:compose(
    {0.0, 0.0, 0.0},
    {0.0, 0.0, 0.0},
    {math:pi() / 6.0, {0.0, 1.0, 0.0}},
    {1.0, 1.0, 1.0}
),
Rotated = shape3:set_matrix(Cube, M).
```

`draw_mesh3/6` takes the 4x4 model matrix directly. Combinators post-multiply:

```erlang
M1 = transform3:translate(matrix4:identity(), {0.0, 0.5, 0.0}),
M2 = transform3:rotate(M1, math:pi() / 4.0, {0.0, 1.0, 0.0}),
ok = surface:draw_mesh3(Surface, Mesh, triangles, 3, no_texture, M2).
```

See the `transform3` module.

## Adjusting the view

Replace the default pixel orthographic projection. Set a perspective (or a
3D orthographic) from `view3`, and a look-at from `camera3`. Both matrices
are already 4x4.

```erlang
{ok, Surface} = surface:set_projection_matrix(
    Surface,
    view3:perspective(math:pi() / 4.0, 640.0 / 480.0, 0.1, 100.0)
),
Camera = camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}),
{ok, Surface} = surface:set_view_matrix(
    Surface,
    camera3:view_matrix(Camera)
).
```

Swap Bottom and Top in `orthographic/6` or `frustum/6` to flip Y.

Draw-target state is applied at clear and draw time:

- `set_viewport/2` — lower-left origin, pixel units
- `set_blend_mode/2` — `none | alpha | add | multiply`, default `none`
- `set_depth_test/2` — `enabled | disabled`, default `enabled`

3D draws usually keep the depth test enabled. Transparent geometry needs
blend mode `alpha` and a draw order; custom blend factors stay on the
OpenGL escape hatch.

Clearing writes the clear color and depth directly. Blending does not affect
`clear/2`.

See the `view3`, `camera3`, and `surface` modules.

## Next steps

- [Texturing](texturing.md) — textures, UV coordinates, and frames as textures
- [Graphical Resources](graphical-resources.md) — ownership, `destroy/1`,
  local copies
- [Going Native](going-native.md) — custom programs and OpenGL commands
- [2D Rendering](going-2d.md) — the same outline in two dimensions
- [Fancy Shapes](fancy-shapes.md) — cylinders, capsules, and the rest of the
  companion catalog
