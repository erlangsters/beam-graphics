# Fancy Shapes

This library owns the shape representation, mesh-to-shape constructors, and
tiny primitives: point, line, triangle, plus rectangle and circle in 2D and
cube and sphere in 3D. See [2D Rendering](going-2d.md) and
[3D Rendering](going-3d.md).

The broader catalog lives in
[beam-graphics-shapes](https://github.com/erlangsters/beam-graphics-shapes).
Those modules construct a core `graphics:shape2()` or `graphics:shape3()`.
Draw and destroy them with the core modules.

```erlang
{ok, Ellipse} = graphics_shape2_ellipse:solid({320.0, 240.0}, {80.0, 40.0}, ?COLOR_RED),
ok = graphics_surface:draw_shape2(Surface, Ellipse),
ok = graphics_shape2:destroy(Ellipse).
```

```erlang
{ok, Cylinder} = graphics_shape3_cylinder:solid(
    {0.0, 0.0, 0.0},
    1.0,
    2.0,
    ?COLOR_RED
),
ok = graphics_surface:draw_shape3(Surface, Cylinder),
ok = graphics_shape3:destroy(Cylinder).
```

2D: `graphics_shape2_ellipse`, `graphics_shape2_ring`, `graphics_shape2_rounded_rectangle`.

3D: `graphics_shape3_capsule`, `graphics_shape3_cylinder`, `graphics_shape3_pyramid`, `graphics_shape3_torus`.

Generated vertices use UV `{0.0, 0.0}`, matching the core primitives. Outline
thickness, where it exists, is signed the same way as `graphics_shape2`.
