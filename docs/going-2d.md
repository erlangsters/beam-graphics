# 2D Rendering

This document covers in details how to use the BEAM graphics library for 2D
rendering.

Familiarity with 3D rendering and its mathematical are not immeidately needed
but will make the reading less heavy than it should be

**Table of Contents**

- The 2D-related primitives
  - The 2D vector
  - The 3x3 matrix
  - The 2D vertex
  - The 2D box
  - The 2D transformations
  - The 2D view
- Drawing a 2D object
- Transforming a 2D object
- Adjusting the 2D view
- Optimizing the drawing.
- Advanced custom 2D rendering
- Bonus: rendering an image

Note that 2D rendering is nothing but 3D rendering with a view constrainted to a
certain position, and restricting teh geomery to Z = 0.

The API provides, for conveninence, 2D primitives where you don't have to deal
with the 3D component. It results in reduced verbose code.

## The 2D-related primitives

If you plan to render 2D objects exclusively and do not need advanced
rendering (going low-level with OpenGL directly), you'll be using the following
primitives.

- `vector2`
- `matrix3`
- `vertex2`
- `box2`
- `transform2`
- `view2`

Any experienced graphics programmer are already familiar with them. Let's cover
them one by one.

### The 2D vector

It's just the classical 2-component vectors needed in many sceneraios.
To describe
It supports common operations.
There data structure simply is a tuple of floats.

```erlang
-type vector2() :: {float(), float()}.
```

To be written.

```erlang
vector2:length({4, 2}).
```

```erlang
vector2:normalize({4, 2}).
```

See the the API reference for more info.

### The 3x3 matrix

The 3x3 matrix is a raw mathematical concept that allows the common 2D
transformation such as translation, rotation, skewing, etc.

They're not intuitive and hard to use, however, it's an essential part in 2D
rendering.

Many part of the API naturally expects a matrix, such as when you draw
vertices or when setting the view of a surface.

However, to make it easy, `transform2` constructs 3x3 matrices for common
translation, rotation, and scale operations.

```erlang
matrix3:new().
```

To be written.

### The 2D vertex

The only drawable primitives is a list of vertices describing the geometry of
objects.

A vertex describes

- the 2D position
- a color
- a 2D coordinate called UV

Later, combined into a list, and by specifying a drawing primitives.

### The 2D box

In a 2D plane, it's frequently needed to define the box that contains a number
of objects.

The 2D box simply describes this rectangle and provides operations.

```erlang
box2:from_vertices(V).

```

To be written.

```erlang
box2:intersects(B1, B2).
```

To be written.

### The 2D transformations

At some point 2D transformation must be specified. The raw solution to this is
a 3x3 matrix. `transform2` constructs those matrices for common operations.

```erlang
M = transform2:translate(matrix3:identity(), {50.0, -100.0}).
```

### The 2D view


To be written.


## Drawing a 2D object

Whether you're rendering 2D or 3D objects, rendering is always done on a
surface which represents the resulting 2D image. Therefore a surface must first
be created.

```erlang
S = surface:new:({640, 480}).
```

Before drawing anything on it, let's clear out the surface with a solid color.
How about a black so we can display a nice tricolor triangle.

```erlang
ok = surface:clear(S, ?COLOR_BLACK).
```

You can only render vertices, using one of the 5 drawing primitives.

- POINTS
- LINE_STRIP
- LINE_LOOP
- LINES
- TRIANGLE_STRIP,
- TRIANGLE_FAN
- TRIANGLES

How to render advanced 2D objects using those drawing primtives is outside
the scope of this documentation. For that, refer to some OpenGL tutorials.

For this demo, we'll draw a simple triangle.

```erlang
V = [
    #vertex2{pos={3, 2}, color=?COLOR_RED},
    #vertex2{pos={3, 2}, color=?COLOR_RED},
    #vertex2{pos={3, 2}, color=?COLOR_RED}
]
surface:draw(V, ?TRIANGLE).
```

To finalize the rendering, the `swap/0` function must be called

```erlang
surface:swap(S).
```

It will wait until the rendering is finished.

## Transforming a 2D object

You will want to describe the vertices of many 2D objects but it's
inconvenient to describe them relative to each other. What if you want to draw
the same object twice but at different positions.

Instead, you want to describe them independently of each other and specify an
additional parameter when drawing in order 'transform' them. One of the
`draw/x` function supports a matrix parameter which specifies the 2D
transformations to apply.

```erlang
Matrix = compute_transform_matrix(),
surface:draw(S, V, P, Matrix).
```

However, to the average programmer, it's hard to
compute the 3x3 matrix by hand, instead use `transform2`.

```erlang
T1 = transform2:translation({50.0, 100.0}).
surface:draw(S, V, T1).
T2 = transform2:compose({100.0, 50.0}, math:pi() / 4.0, {2.0, 2.0}).
surface:draw(S, V, T2).
```

To be written.

## Adjusting the 2D view

Alternatively, you may also adjust the view of the surface before the
rendering.

The view of the surface was omitted until now because it was conveniently set
to fit the area of the surface and use the coordinate we used until now.

See it as a camera that you may device to move using the
`surface:set_view_matrix/x` function.
Once more time, it expects a 3x3 matrix which is difficult to calculate. Instead
we use the `view2`.

```erlang
V = view2:new({360, 240}, {360, 240}).
surface:set_view(view2:matrix(V)).
```

To be written.

## Optimizing the drawing.

To be written.

## Advanced custom 2D rendering

To be written.

## Bonus: rendering an image

To be written.