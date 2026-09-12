%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape2).
-moduledoc """
2D Shape

A 2D shape is a collection of 2D meshes, a model matrix, and an optional
texture that is typically used for rendering.

A 2D shape is a value wrapper around GPU meshes, not a GPU object. It is
created with the `with_mesh` and `with_meshes` functions, or with the primitive
constructors, and disposed with the `destroy/1` function. Copying the term does
not copy the GPU buffers.

The data structure of a 2D shape is the `#shape2{}` record (see
`graphics.hrl`). The fields are a list of `{Mesh, PrimitiveType, VertexCount}`
tuples, a 3x3 model matrix, and `no_texture` or a texture. Prefer the accessors
over matching the record. The vertex count of each tuple is the draw count
passed to `graphics_frame:draw_mesh2/4` or `graphics_surface:draw_mesh2/4`; it is not
necessarily `graphics_mesh2:vertex_count/1`.

```erlang
{ok, Shape} = graphics_shape2:triangle(
    {0.0, 0.0},
    {1.0, 0.0},
    {0.0, 1.0},
    ?COLOR_RED
).
ok = graphics_surface:draw_shape2(Surface, Shape).
ok = graphics_shape2:destroy(Shape).
```

The primitive type and the texture live on the shape, not on the mesh. Several
meshes share one matrix and one texture. `destroy/1` destroys the meshes and
does not destroy the texture.

Generated primitives are solid color. Their vertices use UV coordinates
`(0.0, 0.0)`. A texture bound with `set_texture/2` therefore samples a single
texel. Textured quads are built with `with_mesh/4` or `graphics_sprite:from_texture`.

A rectangle is positioned by its minimum corner. A circle is positioned by its
center. Outline thickness is signed: positive grows inwards, negative grows
outwards. Circle tessellation defaults to 32 segments.

Beware that a well-formed 2D shape always uses floats, not integers, for
positions, sizes, radii, and colors.
""".

-export([
    with_mesh/3, with_mesh/4,
    with_meshes/1, with_meshes/2,
    destroy/1
]).
-export([
    meshes/1,
    matrix/1, set_matrix/2,
    texture/1, set_texture/2
]).
-export([
    point/2,
    line/3,
    triangle/4,
    triangle_wires/4
]).
-export([
    rectangle/3,
    rectangle_outline/4,
    rectangle_wires/3
]).
-export([
    circle/3, circle/4,
    circle_outline/4, circle_outline/5,
    circle_wires/3, circle_wires/4
]).

-compile({inline, [
    with_mesh/3, with_mesh/4,
    with_meshes/1, with_meshes/2
]}).
-compile({inline, [
    meshes/1,
    matrix/1, set_matrix/2,
    texture/1, set_texture/2
]}).
-compile({inline, [
    point/2,
    line/3,
    triangle/4,
    triangle_wires/4
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DEFAULT_CIRCLE_SEGMENTS, 32).

-doc """
A 2D shape from a 2D mesh.

It constructs a 2D shape that draws the given 2D mesh with the given primitive
type and vertex count. There is no texture. The model matrix is the identity.

It's equivalent to `with_mesh(Mesh, PrimitiveType, VertexCount, no_texture)`.
""".
-spec with_mesh(
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count()
) ->
    graphics:shape2()
.
with_mesh(Mesh, PrimitiveType, VertexCount) ->
    with_mesh(Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
A 2D shape from a 2D mesh and a texture.

It constructs a 2D shape that draws the given 2D mesh with the given primitive
type, vertex count, and texture. The model matrix is the identity.

```erlang
Shape = graphics_shape2:with_mesh(Mesh, triangles, 3, Texture).
```
""".
-spec with_mesh(
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) ->
    graphics:shape2()
.
with_mesh(Mesh, PrimitiveType, VertexCount, Texture) ->
    #shape2{
        meshes = [{Mesh, PrimitiveType, VertexCount}],
        texture = Texture
    }.

-doc """
A 2D shape from a list of 2D meshes.

It constructs a 2D shape that draws the given 2D meshes. There is no texture.
The model matrix is the identity. An empty list is allowed.

It's equivalent to `with_meshes(Meshes, no_texture)`.
""".
-spec with_meshes(
    [{graphics:mesh2(), graphics:primitive_type(), graphics:vertex_count()}]
) ->
    graphics:shape2()
.
with_meshes(Meshes) ->
    with_meshes(Meshes, no_texture).

-doc """
A 2D shape from a list of 2D meshes and a texture.

It constructs a 2D shape that draws the given 2D meshes with the given texture.
The model matrix is the identity. An empty list is allowed.
""".
-spec with_meshes(
    [{graphics:mesh2(), graphics:primitive_type(), graphics:vertex_count()}],
    no_texture | graphics:texture()
) ->
    graphics:shape2()
.
with_meshes(Meshes, Texture) ->
    #shape2{
        meshes = Meshes,
        texture = Texture
    }.

-doc """
Destroy a 2D shape.

It destroys every 2D mesh of the 2D shape. The texture is not destroyed. Using
the shape after it is destroyed has undefined behavior. Destroying the same
shape twice is invalid.
""".
-spec destroy(graphics:shape2()) -> ok.
destroy(#shape2{meshes = Meshes}) ->
    lists:foreach(fun({Mesh, _PrimitiveType, _VertexCount}) ->
        graphics_mesh2:destroy(Mesh)
    end, Meshes).

-doc """
The meshes of a 2D shape.

It returns the list of `{Mesh, PrimitiveType, VertexCount}` tuples of the 2D
shape.
""".
-spec meshes(graphics:shape2()) ->
    [{graphics:mesh2(), graphics:primitive_type(), graphics:vertex_count()}]
.
meshes(#shape2{meshes = Meshes}) ->
    Meshes.

-doc """
The model matrix of a 2D shape.

It returns the 3x3 model matrix of the 2D shape.
""".
-spec matrix(graphics:shape2()) -> graphics:matrix3().
matrix(#shape2{matrix = Matrix}) ->
    Matrix.

-doc """
Set the model matrix of a 2D shape.

It returns a new 2D shape with the given 3x3 model matrix. The meshes and the
texture are unchanged. The GPU buffers are not copied or modified.

```erlang
Moved = graphics_shape2:set_matrix(Shape, graphics_transform2:translation({10.0, 20.0})).
```
""".
-spec set_matrix(graphics:shape2(), graphics:matrix3()) -> graphics:shape2().
set_matrix(Shape, Matrix) ->
    Shape#shape2{matrix = Matrix}.

-doc """
The texture of a 2D shape.

It returns `no_texture` or the texture of the 2D shape.
""".
-spec texture(graphics:shape2()) -> no_texture | graphics:texture().
texture(#shape2{texture = Texture}) ->
    Texture.

-doc """
Set the texture of a 2D shape.

It returns a new 2D shape with the given texture. The meshes and the model
matrix are unchanged. The GPU buffers are not copied or modified. The previous
texture is not destroyed.
""".
-spec set_texture(
    graphics:shape2(),
    no_texture | graphics:texture()
) ->
    graphics:shape2()
.
set_texture(Shape, Texture) ->
    Shape#shape2{texture = Texture}.

-doc """
A 2D point.

It constructs a 2D shape that draws a point at the given position with the
given color.
""".
-spec point(graphics:vector2(), graphics:color()) ->
    {ok, graphics:shape2()} | out_of_memory
.
point(Position, Color) ->
    shape_from_vertices([?VERTEX2(Position, Color)], points).

-doc """
A 2D line.

It constructs a 2D shape that draws a line from the first point to the second
point with the given color.
""".
-spec line(
    graphics:vector2(),
    graphics:vector2(),
    graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
line(From, To, Color) ->
    shape_from_vertices([
        ?VERTEX2(From, Color),
        ?VERTEX2(To, Color)
    ], lines).

-doc """
A 2D triangle.

It constructs a 2D shape that draws a filled triangle with the given corners
and color.
""".
-spec triangle(
    graphics:vector2(),
    graphics:vector2(),
    graphics:vector2(),
    graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
triangle(A, B, C, Color) ->
    shape_from_vertices([
        ?VERTEX2(A, Color),
        ?VERTEX2(B, Color),
        ?VERTEX2(C, Color)
    ], triangles).

-doc """
A 2D triangle wireframe.

It constructs a 2D shape that draws the outline of a triangle with the given
corners and color, as a line loop.
""".
-spec triangle_wires(
    graphics:vector2(),
    graphics:vector2(),
    graphics:vector2(),
    graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
triangle_wires(A, B, C, Color) ->
    shape_from_vertices([
        ?VERTEX2(A, Color),
        ?VERTEX2(B, Color),
        ?VERTEX2(C, Color)
    ], line_loop).

-doc """
A 2D rectangle.

It constructs a 2D shape that draws a filled axis-aligned rectangle. `Position`
is the minimum corner. `Size` is the full width and height. The rectangle
extends in `+X` and `+Y`.

```erlang
{ok, Shape} = graphics_shape2:rectangle({0.0, 0.0}, {100.0, 50.0}, ?COLOR_RED).
```
""".
-spec rectangle(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
rectangle({X, Y}, {Width, Height}, Color) ->
    shape_from_vertices([
        ?VERTEX2({X,         Y},          Color),
        ?VERTEX2({X + Width, Y},          Color),
        ?VERTEX2({X + Width, Y + Height}, Color),
        ?VERTEX2({X,         Y + Height}, Color)
    ], triangle_fan).

-doc """
A 2D rectangle outline.

It constructs a 2D shape that draws a filled border of an axis-aligned
rectangle. `Position` is the minimum corner. `Size` is the full width and
height. Positive `Thickness` grows inwards (the outer edge stays the original
rectangle). Negative `Thickness` grows outwards.
""".
-spec rectangle_outline(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
rectangle_outline({X, Y}, {Width, Height}, Thickness, Color) ->
    OuterX0 = X,
    OuterY0 = Y,
    OuterX1 = X + Width,
    OuterY1 = Y + Height,
    InnerX0 = X + Thickness,
    InnerY0 = Y + Thickness,
    InnerX1 = X + Width - Thickness,
    InnerY1 = Y + Height - Thickness,
    shape_from_vertices([
        ?VERTEX2({OuterX0, OuterY0}, Color),
        ?VERTEX2({InnerX0, InnerY0}, Color),
        ?VERTEX2({OuterX1, OuterY0}, Color),
        ?VERTEX2({InnerX1, InnerY0}, Color),
        ?VERTEX2({OuterX1, OuterY1}, Color),
        ?VERTEX2({InnerX1, InnerY1}, Color),
        ?VERTEX2({OuterX0, OuterY1}, Color),
        ?VERTEX2({InnerX0, InnerY1}, Color),
        ?VERTEX2({OuterX0, OuterY0}, Color),
        ?VERTEX2({InnerX0, InnerY0}, Color)
    ], triangle_strip).

-doc """
A 2D rectangle wireframe.

It constructs a 2D shape that draws the edges of an axis-aligned rectangle as a
line loop. `Position` is the minimum corner. `Size` is the full width and
height.
""".
-spec rectangle_wires(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
rectangle_wires({X, Y}, {Width, Height}, Color) ->
    shape_from_vertices([
        ?VERTEX2({X,         Y},          Color),
        ?VERTEX2({X + Width, Y},          Color),
        ?VERTEX2({X + Width, Y + Height}, Color),
        ?VERTEX2({X,         Y + Height}, Color)
    ], line_loop).

-doc """
A 2D circle.

It constructs a 2D shape that draws a filled circle centered at the given
point. The tessellation is 32 segments.

It's equivalent to `circle(Center, Radius, 32, Color)`.
""".
-spec circle(
    Center :: graphics:vector2(),
    Radius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
circle(Center, Radius, Color) ->
    circle(Center, Radius, ?DEFAULT_CIRCLE_SEGMENTS, Color).

-doc """
A 2D circle with a segment count.

It constructs a 2D shape that draws a filled circle centered at the given
point, tessellated with the given number of segments. `Segments` is a positive
integer.
""".
-spec circle(
    Center :: graphics:vector2(),
    Radius :: float(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
circle({X, Y}, Radius, Segments, Color) ->
    AngleStep = (2.0 * math:pi()) / Segments,
    Vertices = [
        ?VERTEX2({X, Y}, Color)
        | [
            ?VERTEX2(
                {
                    X + Radius * math:cos(AngleStep * I),
                    Y + Radius * math:sin(AngleStep * I)
                },
                Color
            )
            || I <- lists:seq(0, Segments)
        ]
    ],
    shape_from_vertices(Vertices, triangle_fan).

-doc """
A 2D circle outline.

It constructs a 2D shape that draws a filled ring centered at the given point.
The tessellation is 32 segments. Positive `Thickness` grows inwards (the outer
radius stays `Radius`). Negative `Thickness` grows outwards.

It's equivalent to `circle_outline(Center, Radius, 32, Thickness, Color)`.
""".
-spec circle_outline(
    Center :: graphics:vector2(),
    Radius :: float(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
circle_outline(Center, Radius, Thickness, Color) ->
    circle_outline(
        Center,
        Radius,
        ?DEFAULT_CIRCLE_SEGMENTS,
        Thickness,
        Color
    ).

-doc """
A 2D circle outline with a segment count.

It constructs a 2D shape that draws a filled ring centered at the given point,
tessellated with the given number of segments. `Segments` is a positive
integer. Positive `Thickness` grows inwards. Negative `Thickness` grows
outwards.
""".
-spec circle_outline(
    Center :: graphics:vector2(),
    Radius :: float(),
    Segments :: pos_integer(),
    Thickness :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
circle_outline({X, Y}, Radius, Segments, Thickness, Color) ->
    InnerRadius = Radius - Thickness,
    AngleStep = (2.0 * math:pi()) / Segments,
    Rim = fun(I, R) ->
        Angle = AngleStep * I,
        ?VERTEX2({X + R * math:cos(Angle), Y + R * math:sin(Angle)}, Color)
    end,
    Pairs = lists:append([
        [Rim(I, Radius), Rim(I, InnerRadius)]
        || I <- lists:seq(0, Segments - 1)
    ]),
    Vertices = Pairs ++ [Rim(0, Radius), Rim(0, InnerRadius)],
    shape_from_vertices(Vertices, triangle_strip).

-doc """
A 2D circle wireframe.

It constructs a 2D shape that draws the circumference of a circle as a line
loop. The tessellation is 32 segments.

It's equivalent to `circle_wires(Center, Radius, 32, Color)`.
""".
-spec circle_wires(
    Center :: graphics:vector2(),
    Radius :: float(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
circle_wires(Center, Radius, Color) ->
    circle_wires(Center, Radius, ?DEFAULT_CIRCLE_SEGMENTS, Color).

-doc """
A 2D circle wireframe with a segment count.

It constructs a 2D shape that draws the circumference of a circle as a line
loop, tessellated with the given number of segments. `Segments` is a positive
integer.
""".
-spec circle_wires(
    Center :: graphics:vector2(),
    Radius :: float(),
    Segments :: pos_integer(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
circle_wires({X, Y}, Radius, Segments, Color) ->
    AngleStep = (2.0 * math:pi()) / Segments,
    Vertices = [
        ?VERTEX2(
            {
                X + Radius * math:cos(AngleStep * I),
                Y + Radius * math:sin(AngleStep * I)
            },
            Color
        )
        || I <- lists:seq(0, Segments - 1)
    ],
    shape_from_vertices(Vertices, line_loop).

shape_from_vertices(Vertices, PrimitiveType) ->
    case graphics_mesh2:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.
