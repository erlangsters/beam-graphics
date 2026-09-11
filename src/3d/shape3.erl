%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3).
-moduledoc """
3D Shape

A 3D shape is a collection of 3D meshes, a model matrix, and an optional
texture that is typically used for rendering.

A 3D shape is a value wrapper around GPU meshes, not a GPU object. It is
created with the `with_mesh` and `with_meshes` functions, or with the primitive
constructors, and disposed with the `destroy/1` function. Copying the term does
not copy the GPU buffers.

The data structure of a 3D shape is the `#shape3{}` record (see
`graphics.hrl`). The fields are a list of `{Mesh, PrimitiveType, VertexCount}`
tuples, a 4x4 model matrix, and `no_texture` or a texture. Prefer the accessors
over matching the record. The vertex count of each tuple is the draw count
passed to `surface:draw_mesh3/4`; it is not necessarily `mesh3:vertex_count/1`.

```erlang
{ok, Shape} = shape3:triangle(
    {0.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, 1.0, 0.0},
    ?COLOR_RED
).
ok = surface:draw_shape3(Surface, Shape).
ok = shape3:destroy(Shape).
```

The primitive type and the texture live on the shape, not on the mesh. Several
meshes share one matrix and one texture. `destroy/1` destroys the meshes and
does not destroy the texture.

Generated primitives are solid color. Their vertices use UV coordinates
`(0.0, 0.0)`. A texture bound with `set_texture/2` therefore samples a single
texel. Textured geometry is built with `with_mesh/4`.

A cube is a rectangular box positioned by its center. `Size` is the full width,
height, and length, matching `box3:from_center_size/2`. A sphere is positioned
by its center. Sphere tessellation defaults to 16 rings and 16 slices. There is
no 3D outline; a shell with thickness belongs in the companion catalog.

Beware that a well-formed 3D shape always uses floats, not integers, for
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
    cube/3,
    cube_wires/3
]).
-export([
    sphere/3, sphere/5,
    sphere_wires/3, sphere_wires/5
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

-define(DEFAULT_SPHERE_RINGS, 16).
-define(DEFAULT_SPHERE_SLICES, 16).

-doc """
A 3D shape from a 3D mesh.

It constructs a 3D shape that draws the given 3D mesh with the given primitive
type and vertex count. There is no texture. The model matrix is the identity.

It's equivalent to `with_mesh(Mesh, PrimitiveType, VertexCount, no_texture)`.
""".
-spec with_mesh(
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count()
) ->
    graphics:shape3()
.
with_mesh(Mesh, PrimitiveType, VertexCount) ->
    with_mesh(Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
A 3D shape from a 3D mesh and a texture.

It constructs a 3D shape that draws the given 3D mesh with the given primitive
type, vertex count, and texture. The model matrix is the identity.

```erlang
Shape = shape3:with_mesh(Mesh, triangles, 3, Texture).
```
""".
-spec with_mesh(
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
with_mesh(Mesh, PrimitiveType, VertexCount, Texture) ->
    #shape3{
        meshes = [{Mesh, PrimitiveType, VertexCount}],
        texture = Texture
    }.

-doc """
A 3D shape from a list of 3D meshes.

It constructs a 3D shape that draws the given 3D meshes. There is no texture.
The model matrix is the identity. An empty list is allowed.

It's equivalent to `with_meshes(Meshes, no_texture)`.
""".
-spec with_meshes(
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}]
) ->
    graphics:shape3()
.
with_meshes(Meshes) ->
    with_meshes(Meshes, no_texture).

-doc """
A 3D shape from a list of 3D meshes and a texture.

It constructs a 3D shape that draws the given 3D meshes with the given texture.
The model matrix is the identity. An empty list is allowed.
""".
-spec with_meshes(
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}],
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
with_meshes(Meshes, Texture) ->
    #shape3{
        meshes = Meshes,
        texture = Texture
    }.

-doc """
Destroy a 3D shape.

It destroys every 3D mesh of the 3D shape. The texture is not destroyed. Using
the shape after it is destroyed has undefined behavior. Destroying the same
shape twice is invalid.
""".
-spec destroy(graphics:shape3()) -> ok.
destroy(#shape3{meshes = Meshes}) ->
    lists:foreach(fun({Mesh, _PrimitiveType, _VertexCount}) ->
        mesh3:destroy(Mesh)
    end, Meshes).

-doc """
The meshes of a 3D shape.

It returns the list of `{Mesh, PrimitiveType, VertexCount}` tuples of the 3D
shape.
""".
-spec meshes(graphics:shape3()) ->
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}]
.
meshes(#shape3{meshes = Meshes}) ->
    Meshes.

-doc """
The model matrix of a 3D shape.

It returns the 4x4 model matrix of the 3D shape.
""".
-spec matrix(graphics:shape3()) -> graphics:matrix4().
matrix(#shape3{matrix = Matrix}) ->
    Matrix.

-doc """
Set the model matrix of a 3D shape.

It returns a new 3D shape with the given 4x4 model matrix. The meshes and the
texture are unchanged. The GPU buffers are not copied or modified.

```erlang
Moved = shape3:set_matrix(Shape, transform3:translation({10.0, 20.0, 30.0})).
```
""".
-spec set_matrix(graphics:shape3(), graphics:matrix4()) -> graphics:shape3().
set_matrix(Shape, Matrix) ->
    Shape#shape3{matrix = Matrix}.

-doc """
The texture of a 3D shape.

It returns `no_texture` or the texture of the 3D shape.
""".
-spec texture(graphics:shape3()) -> no_texture | graphics:texture().
texture(#shape3{texture = Texture}) ->
    Texture.

-doc """
Set the texture of a 3D shape.

It returns a new 3D shape with the given texture. The meshes and the model
matrix are unchanged. The GPU buffers are not copied or modified. The previous
texture is not destroyed.
""".
-spec set_texture(
    graphics:shape3(),
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
set_texture(Shape, Texture) ->
    Shape#shape3{texture = Texture}.

-doc """
A 3D point.

It constructs a 3D shape that draws a point at the given position with the
given color.
""".
-spec point(graphics:vector3(), graphics:color()) ->
    {ok, graphics:shape3()} | out_of_memory
.
point(Position, Color) ->
    shape_from_vertices([?VERTEX3(Position, Color)], points).

-doc """
A 3D line.

It constructs a 3D shape that draws a line from the first point to the second
point with the given color.
""".
-spec line(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
line(From, To, Color) ->
    shape_from_vertices([
        ?VERTEX3(From, Color),
        ?VERTEX3(To, Color)
    ], lines).

-doc """
A 3D triangle.

It constructs a 3D shape that draws a filled triangle with the given corners
and color.
""".
-spec triangle(
    graphics:vector3(),
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
triangle(A, B, C, Color) ->
    shape_from_vertices([
        ?VERTEX3(A, Color),
        ?VERTEX3(B, Color),
        ?VERTEX3(C, Color)
    ], triangles).

-doc """
A 3D triangle wireframe.

It constructs a 3D shape that draws the outline of a triangle with the given
corners and color, as a line loop.
""".
-spec triangle_wires(
    graphics:vector3(),
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
triangle_wires(A, B, C, Color) ->
    shape_from_vertices([
        ?VERTEX3(A, Color),
        ?VERTEX3(B, Color),
        ?VERTEX3(C, Color)
    ], line_loop).

-doc """
A 3D cube.

It constructs a 3D shape that draws a filled rectangular box. `Center` is the
center. `Size` is the full width, height, and length, matching
`box3:from_center_size/2`. The name is conventional; the extents need not be
equal.
""".
-spec cube(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
cube({X, Y, Z}, {Width, Height, Length}, Color) ->
    HalfW = Width / 2.0,
    HalfH = Height / 2.0,
    HalfL = Length / 2.0,
    X0 = X - HalfW,
    X1 = X + HalfW,
    Y0 = Y - HalfH,
    Y1 = Y + HalfH,
    Z0 = Z - HalfL,
    Z1 = Z + HalfL,
    shape_from_vertices([
        % Front (+Z)
        ?VERTEX3({X0, Y0, Z1}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color),
        ?VERTEX3({X0, Y1, Z1}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color),
        ?VERTEX3({X0, Y1, Z1}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color),

        % Back (-Z)
        ?VERTEX3({X0, Y0, Z0}, Color),
        ?VERTEX3({X0, Y1, Z0}, Color),
        ?VERTEX3({X1, Y0, Z0}, Color),
        ?VERTEX3({X1, Y1, Z0}, Color),
        ?VERTEX3({X1, Y0, Z0}, Color),
        ?VERTEX3({X0, Y1, Z0}, Color),

        % Top (+Y)
        ?VERTEX3({X0, Y1, Z0}, Color),
        ?VERTEX3({X0, Y1, Z1}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color),
        ?VERTEX3({X1, Y1, Z0}, Color),
        ?VERTEX3({X0, Y1, Z0}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color),

        % Bottom (-Y)
        ?VERTEX3({X0, Y0, Z0}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color),
        ?VERTEX3({X0, Y0, Z1}, Color),
        ?VERTEX3({X1, Y0, Z0}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color),
        ?VERTEX3({X0, Y0, Z0}, Color),

        % Right (+X)
        ?VERTEX3({X1, Y0, Z0}, Color),
        ?VERTEX3({X1, Y1, Z0}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color),
        ?VERTEX3({X1, Y0, Z0}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color),

        % Left (-X)
        ?VERTEX3({X0, Y0, Z0}, Color),
        ?VERTEX3({X0, Y1, Z1}, Color),
        ?VERTEX3({X0, Y1, Z0}, Color),
        ?VERTEX3({X0, Y0, Z1}, Color),
        ?VERTEX3({X0, Y1, Z1}, Color),
        ?VERTEX3({X0, Y0, Z0}, Color)
    ], triangles).

-doc """
A 3D cube wireframe.

It constructs a 3D shape that draws the 12 edges of a rectangular box as
lines. `Center` is the center. `Size` is the full width, height, and length.
""".
-spec cube_wires(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
cube_wires({X, Y, Z}, {Width, Height, Length}, Color) ->
    HalfW = Width / 2.0,
    HalfH = Height / 2.0,
    HalfL = Length / 2.0,
    X0 = X - HalfW,
    X1 = X + HalfW,
    Y0 = Y - HalfH,
    Y1 = Y + HalfH,
    Z0 = Z - HalfL,
    Z1 = Z + HalfL,
    shape_from_vertices([
        % Front
        ?VERTEX3({X0, Y0, Z1}, Color), ?VERTEX3({X1, Y0, Z1}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color), ?VERTEX3({X1, Y1, Z1}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color), ?VERTEX3({X0, Y1, Z1}, Color),
        ?VERTEX3({X0, Y1, Z1}, Color), ?VERTEX3({X0, Y0, Z1}, Color),

        % Back
        ?VERTEX3({X0, Y0, Z0}, Color), ?VERTEX3({X1, Y0, Z0}, Color),
        ?VERTEX3({X1, Y0, Z0}, Color), ?VERTEX3({X1, Y1, Z0}, Color),
        ?VERTEX3({X1, Y1, Z0}, Color), ?VERTEX3({X0, Y1, Z0}, Color),
        ?VERTEX3({X0, Y1, Z0}, Color), ?VERTEX3({X0, Y0, Z0}, Color),

        % Front to back
        ?VERTEX3({X0, Y1, Z1}, Color), ?VERTEX3({X0, Y1, Z0}, Color),
        ?VERTEX3({X1, Y1, Z1}, Color), ?VERTEX3({X1, Y1, Z0}, Color),
        ?VERTEX3({X0, Y0, Z1}, Color), ?VERTEX3({X0, Y0, Z0}, Color),
        ?VERTEX3({X1, Y0, Z1}, Color), ?VERTEX3({X1, Y0, Z0}, Color)
    ], lines).

-doc """
A 3D sphere.

It constructs a 3D shape that draws a filled sphere centered at the given
point. The tessellation is 16 rings and 16 slices.

It's equivalent to `sphere(Center, Radius, 16, 16, Color)`.
""".
-spec sphere(
    graphics:vector3(),
    float(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
sphere(Center, Radius, Color) ->
    sphere(Center, Radius, ?DEFAULT_SPHERE_RINGS, ?DEFAULT_SPHERE_SLICES, Color).

-doc """
A 3D sphere with ring and slice counts.

It constructs a 3D shape that draws a filled sphere centered at the given
point, tessellated with the given number of latitudinal rings and longitudinal
slices. `Rings` and `Slices` are positive integers. Rings are bands from the
north pole to the south pole. Y is up.
""".
-spec sphere(
    graphics:vector3(),
    float(),
    pos_integer(),
    pos_integer(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
sphere(Center, Radius, Rings, Slices, Color) ->
    Vertices = sphere_world_vertices(
        Center,
        Radius,
        sphere_solid_vertices(Rings, Slices, Color)
    ),
    shape_from_vertices(Vertices, triangles).

-doc """
A 3D sphere wireframe.

It constructs a 3D shape that draws the latitude rings and meridians of a
sphere as lines. The tessellation is 16 rings and 16 slices.

It's equivalent to `sphere_wires(Center, Radius, 16, 16, Color)`.
""".
-spec sphere_wires(
    graphics:vector3(),
    float(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
sphere_wires(Center, Radius, Color) ->
    sphere_wires(
        Center,
        Radius,
        ?DEFAULT_SPHERE_RINGS,
        ?DEFAULT_SPHERE_SLICES,
        Color
    ).

-doc """
A 3D sphere wireframe with ring and slice counts.

It constructs a 3D shape that draws the latitude rings and meridians of a
sphere as lines, tessellated with the given number of rings and slices.
`Rings` and `Slices` are positive integers.
""".
-spec sphere_wires(
    graphics:vector3(),
    float(),
    pos_integer(),
    pos_integer(),
    graphics:color()
) ->
    {ok, graphics:shape3()} | out_of_memory
.
sphere_wires(Center, Radius, Rings, Slices, Color) ->
    Vertices = sphere_world_vertices(
        Center,
        Radius,
        sphere_wire_vertices(Rings, Slices, Color)
    ),
    shape_from_vertices(Vertices, lines).

shape_from_vertices(Vertices, PrimitiveType) ->
    case mesh3:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, with_mesh(Mesh, PrimitiveType, length(Vertices))};
        out_of_memory ->
            out_of_memory
    end.

sphere_world_vertices(Center, Radius, Vertices) ->
    Matrix = matrix4:multiply(
        transform3:translation(Center),
        transform3:scale({Radius, Radius, Radius})
    ),
    [transform3:transform_vertex(Matrix, Vertex) || Vertex <- Vertices].

sphere_solid_vertices(Rings, Slices, Color) ->
    North = lists:append([
        [
            sphere_vertex(0, 0, Rings, Slices, Color),
            sphere_vertex(1, J, Rings, Slices, Color),
            sphere_vertex(1, J + 1, Rings, Slices, Color)
        ]
        || J <- lists:seq(0, Slices - 1)
    ]),
    Middle = lists:append([
        [
            sphere_vertex(I, J, Rings, Slices, Color),
            sphere_vertex(I + 1, J, Rings, Slices, Color),
            sphere_vertex(I + 1, J + 1, Rings, Slices, Color),
            sphere_vertex(I, J, Rings, Slices, Color),
            sphere_vertex(I + 1, J + 1, Rings, Slices, Color),
            sphere_vertex(I, J + 1, Rings, Slices, Color)
        ]
        || I <- lists:seq(1, Rings - 2),
           J <- lists:seq(0, Slices - 1)
    ]),
    South = lists:append([
        [
            sphere_vertex(Rings - 1, J, Rings, Slices, Color),
            sphere_vertex(Rings, 0, Rings, Slices, Color),
            sphere_vertex(Rings - 1, J + 1, Rings, Slices, Color)
        ]
        || J <- lists:seq(0, Slices - 1)
    ]),
    North ++ Middle ++ South.

sphere_wire_vertices(Rings, Slices, Color) ->
    Latitudes = lists:append([
        [
            sphere_vertex(I, J, Rings, Slices, Color),
            sphere_vertex(I, J + 1, Rings, Slices, Color)
        ]
        || I <- lists:seq(1, Rings - 1),
           J <- lists:seq(0, Slices - 1)
    ]),
    Meridians = lists:append([
        [
            sphere_vertex(I, J, Rings, Slices, Color),
            sphere_vertex(I + 1, J, Rings, Slices, Color)
        ]
        || J <- lists:seq(0, Slices - 1),
           I <- lists:seq(0, Rings - 1)
    ]),
    Latitudes ++ Meridians.

sphere_vertex(I, J, Rings, Slices, Color) ->
    ?VERTEX3(unit_sphere_point(I, J, Rings, Slices), Color).

unit_sphere_point(0, _J, _Rings, _Slices) ->
    {0.0, 1.0, 0.0};
unit_sphere_point(I, _J, Rings, _Slices) when I =:= Rings ->
    {0.0, -1.0, 0.0};
unit_sphere_point(I, J, Rings, Slices) ->
    Theta = math:pi() * I / Rings,
    Phi = (2.0 * math:pi()) * J / Slices,
    SinTheta = math:sin(Theta),
    {
        SinTheta * math:sin(Phi),
        math:cos(Theta),
        SinTheta * math:cos(Phi)
    }.
