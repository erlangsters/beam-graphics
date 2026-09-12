%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics).
-moduledoc """
To be written.

To be written.
""".

-export_type([
    angle/0,
    vector2/0,
    vector3/0,
    vector4/0,
    matrix3/0,
    matrix4/0,
    color/0,
    box2/0,
    box3/0
]).
-export_type([
    vertex2/0, vertex3/0,
    mesh2/0, mesh3/0,
    image/0,
    texture/0,
    program/0
]).
-export_type([
    primitive_type/0,
    vertex_count/0,
    shape2/0, shape3/0
]).
-export_type([
    camera2/0, camera3/0
]).
-export_type([
    surface/0,
    frame/0
]).

-export([
    initialize/1,
    terminate/0
]).

-include_lib("beam_graphics/include/graphics.hrl").

-doc """
An angle in radians.

To be written.
""".
-type angle() :: float().

-doc """
A 2D vector.

A pair of numbers typically used to represent 2D positions and directions in
the Euclidean plane.

Note that `graphics_matrix3:multiply_vector/2` treats a 2D vector as a point by assuming
an invisible third component set to 1.0 (the homogeneous coordinate).
""".
-type vector2() :: {
    X :: float(),
    Y :: float()
}.

-doc """
A 3D vector.

A triplet of numbers typically used to represent 3D positions and directions in
the Euclidean space.

Note that `graphics_matrix4:multiply_vector/2` treats a 3D vector as a point by assuming
an invisible fourth component set to 1.0 (the homogeneous coordinate).
""".
-type vector3() :: {
    X :: float(),
    Y :: float(),
    Z :: float()
}.

-doc """
A 4-tuple of floats.

It is the row and column type of a 4x4 matrix. It is not a general 4D vector
API.
""".
-type vector4() :: {
    X :: float(),
    Y :: float(),
    Z :: float(),
    W :: float()
}.

-doc """
A 3x3 matrix.

A 3x3 grid of numbers typically used to represent 2D transformations in the
Euclidean plane.

The tuple is stored in column-major order (top-to-bottom, left-to-right).
""".
-type matrix3() :: {
    M11 :: float(),
    M21 :: float(),
    M31 :: float(),
    M12 :: float(),
    M22 :: float(),
    M32 :: float(),
    M13 :: float(),
    M23 :: float(),
    M33 :: float()
}.

-doc """
A 4x4 matrix.

A 4x4 grid of numbers typically used to represent 3D transformations in the
Euclidean space.

The tuple is stored in column-major order (top-to-bottom, left-to-right).
""".
-type matrix4() :: {
    M11 :: float(),
    M21 :: float(),
    M31 :: float(),
    M41 :: float(),
    M12 :: float(),
    M22 :: float(),
    M32 :: float(),
    M42 :: float(),
    M13 :: float(),
    M23 :: float(),
    M33 :: float(),
    M43 :: float(),
    M14 :: float(),
    M24 :: float(),
    M34 :: float(),
    M44 :: float()
}.

-doc """
A RGBA color.

A quadruplet of numbers typically used to represent the red, green, blue, and
alpha channels of a pixel, a vertex, or a clear value. Each channel is a
`graphics_color:channel()` float, typically in the range 0.0 to 1.0.

Use the `graphics_color` module to create and manipulate colors.
""".
-type color() :: {
    Red :: graphics_color:channel(),
    Green :: graphics_color:channel(),
    Blue :: graphics_color:channel(),
    Alpha :: graphics_color:channel()
}.

-doc """
A 2D box.

A pair of 2D vectors typically used to represent an axis-aligned rectangle in
the Euclidean plane. The first vector is the minimum corner and the second is
the maximum corner.
""".
-type box2() :: {
    Min :: vector2(),
    Max :: vector2()
}.

-doc """
A 3D box.

A pair of 3D vectors typically used to represent an axis-aligned rectangular
prism in the Euclidean space. The first vector is the minimum corner and the
second is the maximum corner.
""".
-type box3() :: {
    Min :: vector3(),
    Max :: vector3()
}.

-doc """
A 2D vertex.

A 2D position, a color, and UV texture coordinates typically used to describe
a point of 2D geometry.

There is no `vertex2` module. `graphics_box2:from_vertices/1` ignores the color and UV
coordinates. `graphics_transform2:transform_vertex/2` transforms the position and leaves
the color and UV coordinates unchanged.
""".
-type vertex2() :: {
    Position :: vector2(),
    Color :: color(),
    U :: float(),
    V :: float()
}.

-doc """
A 3D vertex.

A 3D position, a color, and UV texture coordinates typically used to describe
a point of 3D geometry.

There is no `vertex3` module. `graphics_box3:from_vertices/1` ignores the color and UV
coordinates. `graphics_transform3:transform_vertex/2` transforms the position and leaves
the color and UV coordinates unchanged.
""".
-type vertex3() :: {
    Position :: vector3(),
    Color :: color(),
    U :: float(),
    V :: float()
}.

-doc """
2D mesh object.

A collection of 2D vertices that can be rendered on a frame or a surface.

Use the `graphics_mesh2` module to create and manipulate 2D meshes.
""".
-type mesh2() :: graphics_mesh2:object().

-doc """
3D mesh object.

A collection of 3D vertices that can be rendered on a frame or a surface.

Use the `graphics_mesh3` module to create and manipulate 3D meshes.
""".
-type mesh3() :: graphics_mesh3:object().

-doc """
A texture image.

A width, a height, and a row-major list of RGBA colors typically used as the
CPU-side payload of a texture.

Use the `graphics_texture` module to create and manipulate textures from an image.
""".
-type image() :: graphics_texture:image().

-doc """
Texture object.

A 2D array of pixels that can be sampled when rendering a mesh.

Use the `graphics_texture` module to create and manipulate textures.
""".
-type texture() :: graphics_texture:object().

-doc """
Program object.

A GPU shader program that can be used for rendering.

Use the `graphics_program` module to create and manipulate programs.
""".
-type program() :: graphics_program:object().

-doc """
A mesh primitive type.

It selects how consecutive vertices are assembled when a mesh is drawn:
points, lines, a line strip, a line loop, triangles, a triangle strip, or a
triangle fan.
""".
-type primitive_type() ::
    points |
    lines |
    line_strip |
    line_loop |
    triangles |
    triangle_strip |
    triangle_fan
.

-doc """
A vertex draw count.

It is the number of vertices consumed by a draw call. On a shape, it is stored
per mesh and is not necessarily `graphics_mesh2:vertex_count/1` or
`graphics_mesh3:vertex_count/1`.
""".
-type vertex_count() :: non_neg_integer().

-doc """
A 2D shape.

A collection of 2D meshes, a 3x3 model matrix, and an optional texture
typically used as a drawable 2D object.

The data structure is the `#shape2{}` record. Use the `graphics_shape2` module to create
and manipulate 2D shapes.
""".
-type shape2() :: #shape2{}.

-doc """
A 3D shape.

A collection of 3D meshes, a 4x4 model matrix, and an optional texture
typically used as a drawable 3D object.

The data structure is the `#shape3{}` record. Use the `graphics_shape3` module to create
and manipulate 3D shapes.
""".
-type shape3() :: #shape3{}.

-doc """
A 2D camera.

A center, a rotation, and a zoom typically used to represent an observer in
the Euclidean plane. Rotation is an angle in radians. Zoom `1.0` is no zoom.
""".
-type camera2() :: {
    Center :: vector2(),
    Rotation :: angle(),
    Zoom :: float()
}.

-doc """
A 3D camera.

A position, a target, and an up vector typically used to represent an observer
in the Euclidean space. The camera sits at the position and looks at the
target.
""".
-type camera3() :: {
    Position :: vector3(),
    Target :: vector3(),
    Up :: vector3()
}.

-doc """
Surface object.

A presentable 2D image that can be used as a render target. The result is
shown with `graphics_surface:display/1` or read back with `graphics_surface:image/1`.

Use the `graphics_surface` module to create and manipulate surfaces.
""".
-type surface() :: graphics_surface:object().

-doc """
Frame object.

An offscreen 2D image that can be used as a render target. The result is a
texture that can be sampled when rendering a mesh.

Use the `graphics_frame` module to create and manipulate frames.
""".
-type frame() :: graphics_frame:object().

-doc """
To be written.

To be written.
""".
-spec initialize(egl:display()) -> ok.
initialize(Display) ->
    graphics_context:start(Display),
    ok.

-doc """
To be written.

To be written.
""".
-spec terminate() -> ok.
terminate() ->
    ok = graphics_context:stop(),
    ok.
