%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(transform3).
-moduledoc """
3D Transform

A 3D transform is a 4x4 matrix that is typically used to represent translation,
rotation, and scale in the Euclidean space.

There is no extra data structure. This module constructs 4x4 matrices for those
operations and applies them to points, directions, vertices, and boxes. The
matrix itself is a `graphics:matrix4()` value; see the `matrix4` module for
linear algebra.

```erlang
M = transform3:translation({10.0, 20.0, 30.0}).
{11.0, 22.0, 33.0} = transform3:transform_point(M, {1.0, 2.0, 3.0}).
```

To compose several operations, either multiply matrices or use the combinators,
which post-multiply so the new operation runs in local space.

```erlang
M1 = transform3:translate(matrix4:identity(), {10.0, 0.0, 0.0}),
M2 = transform3:rotate(M1, math:pi() / 2.0, {0.0, 0.0, 1.0}).
```

For the common origin, position, rotation, and scale case, use `compose/3` or
`compose/4`. A point is first moved so the origin is at zero, then scaled, then
rotated, then moved to the position. Rotation is `{Angle, Axis}`.

Rotation uses Rodrigues' formula around the given axis, matching
`vector3:rotate/3`. The axis is normalized internally. A zero axis yields IEEE
`inf` or `NaN`. `rotation_x/1`, `rotation_y/1`, and `rotation_z/1` are the
principal-axis constructors. Angles are in radians.

Beware that a well-formed 4x4 matrix always contains floats, not integers.
""".

-export([
    translation/1,
    rotation/2,
    rotation_x/1, rotation_y/1, rotation_z/1,
    scale/1
]).
-export([
    translate/2,
    rotate/3,
    scale/2
]).
-export([
    compose/3, compose/4
]).
-export([
    transform_point/2,
    transform_direction/2
]).
-export([
    transform_vertex/2,
    transform_box/2
]).

-doc """
A translation 4x4 matrix.

It constructs a 4x4 matrix that translates by the given 3D vector.

```erlang
{11.0, 22.0, 33.0} = transform3:transform_point(
    transform3:translation({10.0, 20.0, 30.0}),
    {1.0, 2.0, 3.0}
).
```
""".
-spec translation(graphics:vector3()) -> graphics:matrix4().
translation({X, Y, Z}) ->
    {
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        X,   Y,   Z,   1.0
    }.

-doc """
A rotation 4x4 matrix.

It constructs a 4x4 matrix that rotates around `Axis` by the given angle in
radians, using Rodrigues' rotation formula. `Axis` is normalized internally. A
zero axis yields IEEE `inf` or `NaN`. The rotation matches `vector3:rotate/3`.
""".
-spec rotation(graphics:angle(), graphics:vector3()) -> graphics:matrix4().
rotation(Angle, Axis) ->
    Cos = math:cos(Angle),
    Sin = math:sin(Angle),
    T = 1.0 - Cos,
    {Kx, Ky, Kz} = vector3:normalize(Axis),
    R11 = T * Kx * Kx + Cos,
    R12 = T * Kx * Ky - Sin * Kz,
    R13 = T * Kx * Kz + Sin * Ky,
    R21 = T * Kx * Ky + Sin * Kz,
    R22 = T * Ky * Ky + Cos,
    R23 = T * Ky * Kz - Sin * Kx,
    R31 = T * Kx * Kz - Sin * Ky,
    R32 = T * Ky * Kz + Sin * Kx,
    R33 = T * Kz * Kz + Cos,
    {
        R11, R21, R31, 0.0,
        R12, R22, R32, 0.0,
        R13, R23, R33, 0.0,
        0.0, 0.0, 0.0, 1.0
    }.

-doc """
A rotation 4x4 matrix around the X axis.

It constructs a 4x4 matrix that rotates around the X axis by the given angle in
radians. It is the same as `rotation(Angle, {1.0, 0.0, 0.0})`.
""".
-spec rotation_x(graphics:angle()) -> graphics:matrix4().
rotation_x(Angle) ->
    rotation(Angle, {1.0, 0.0, 0.0}).

-doc """
A rotation 4x4 matrix around the Y axis.

It constructs a 4x4 matrix that rotates around the Y axis by the given angle in
radians. It is the same as `rotation(Angle, {0.0, 1.0, 0.0})`.
""".
-spec rotation_y(graphics:angle()) -> graphics:matrix4().
rotation_y(Angle) ->
    rotation(Angle, {0.0, 1.0, 0.0}).

-doc """
A rotation 4x4 matrix around the Z axis.

It constructs a 4x4 matrix that rotates around the Z axis by the given angle in
radians. It is the same as `rotation(Angle, {0.0, 0.0, 1.0})`.
""".
-spec rotation_z(graphics:angle()) -> graphics:matrix4().
rotation_z(Angle) ->
    rotation(Angle, {0.0, 0.0, 1.0}).

-doc """
A scale 4x4 matrix.

It constructs a 4x4 matrix that scales by the given 3D vector.

```erlang
{2.0, 6.0, 12.0} = transform3:transform_point(
    transform3:scale({2.0, 3.0, 4.0}),
    {1.0, 2.0, 3.0}
).
```
""".
-spec scale(graphics:vector3()) -> graphics:matrix4().
scale({X, Y, Z}) ->
    {
        X,   0.0, 0.0, 0.0,
        0.0, Y,   0.0, 0.0,
        0.0, 0.0, Z,   0.0,
        0.0, 0.0, 0.0, 1.0
    }.

-doc """
Translate a 4x4 matrix.

It post-multiplies a 4x4 matrix by a translation. The translation runs in the
matrix's local space.
""".
-spec translate(graphics:matrix4(), graphics:vector3()) -> graphics:matrix4().
translate(Matrix, Vector) ->
    matrix4:multiply(Matrix, translation(Vector)).

-doc """
Rotate a 4x4 matrix.

It post-multiplies a 4x4 matrix by a rotation around `Axis`. The rotation runs
in the matrix's local space and matches `vector3:rotate/3`.
""".
-spec rotate(graphics:matrix4(), graphics:angle(), graphics:vector3()) ->
    graphics:matrix4().
rotate(Matrix, Angle, Axis) ->
    matrix4:multiply(Matrix, rotation(Angle, Axis)).

-doc """
Scale a 4x4 matrix.

It post-multiplies a 4x4 matrix by a scale transform. The scale runs in the
matrix's local space.
""".
-spec scale(graphics:matrix4(), graphics:vector3()) -> graphics:matrix4().
scale(Matrix, Vector) ->
    matrix4:multiply(Matrix, scale(Vector)).

-doc """
Compose a 3D transform from position, rotation, and scale.

It constructs the 4x4 matrix that scales, then rotates, then translates. The
origin is `{0.0, 0.0, 0.0}`. Rotation is `{Angle, Axis}`.
""".
-spec compose(
    graphics:vector3(),
    {graphics:angle(), graphics:vector3()},
    graphics:vector3()
) -> graphics:matrix4().
compose(Position, Rotation, Scale) ->
    compose(vector3:zero(), Position, Rotation, Scale).

-doc """
Compose a 3D transform from origin, position, rotation, and scale.

It constructs the 4x4 matrix `T(Position) * R * S * T(-Origin)`. A point is
first moved so the origin is at zero, then scaled, then rotated, then moved to
the position. Rotation is `{Angle, Axis}`.
""".
-spec compose(
    graphics:vector3(),
    graphics:vector3(),
    {graphics:angle(), graphics:vector3()},
    graphics:vector3()
) -> graphics:matrix4().
compose(Origin, Position, {Angle, Axis}, Scale) ->
    matrix4:multiply(
        translation(Position),
        matrix4:multiply(
            rotation(Angle, Axis),
            matrix4:multiply(
                scale(Scale),
                translation(vector3:negate(Origin))
            )
        )
    ).

-doc """
Transform a 3D point.

It transforms a 3D point by a 4x4 matrix. The point is treated as a homogeneous
vector `{X, Y, Z, 1.0}`. If the resulting W component is not 1.0, the XYZ
result is divided by W.

This is the same computation as `matrix4:multiply_vector/2`.
""".
-spec transform_point(graphics:matrix4(), graphics:vector3()) ->
    graphics:vector3().
transform_point(Matrix, Point) ->
    matrix4:multiply_vector(Matrix, Point).

-doc """
Transform a 3D direction.

It transforms a 3D direction by the linear part of a 4x4 matrix. Translation is
ignored. This is not a correct normal transform when the scale is non-uniform.
""".
-spec transform_direction(graphics:matrix4(), graphics:vector3()) ->
    graphics:vector3().
transform_direction({
    M11, M21, M31, _,
    M12, M22, M32, _,
    M13, M23, M33, _,
    _, _, _, _
}, {X, Y, Z}) ->
    {
        M11 * X + M12 * Y + M13 * Z,
        M21 * X + M22 * Y + M23 * Z,
        M31 * X + M32 * Y + M33 * Z
    }.

-doc """
Transform a 3D vertex.

It transforms the position of a 3D vertex by a 4x4 matrix. The color and UV
coordinates are left unchanged.
""".
-spec transform_vertex(graphics:matrix4(), graphics:vertex3()) ->
    graphics:vertex3().
transform_vertex(Matrix, {Position, Color, U, V}) ->
    {transform_point(Matrix, Position), Color, U, V}.

-doc """
Transform a 3D box.

It transforms every corner of a 3D box as a point and returns the axis-aligned
bounding box of the result. A rotated box is a larger axis-aligned box, not a
rotated rectangular prism.
""".
-spec transform_box(graphics:matrix4(), graphics:box3()) ->
    graphics:box3().
transform_box(Matrix, {{MinX, MinY, MinZ}, {MaxX, MaxY, MaxZ}}) ->
    Corners = [
        {MinX, MinY, MinZ}, {MaxX, MinY, MinZ},
        {MinX, MaxY, MinZ}, {MaxX, MaxY, MinZ},
        {MinX, MinY, MaxZ}, {MaxX, MinY, MaxZ},
        {MinX, MaxY, MaxZ}, {MaxX, MaxY, MaxZ}
    ],
    [First | Rest] = [transform_point(Matrix, Corner) || Corner <- Corners],
    lists:foldl(fun(Point, {Min, Max}) ->
        {vector3:min(Min, Point), vector3:max(Max, Point)}
    end, {First, First}, Rest).
