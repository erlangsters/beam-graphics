%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(transform2).
-moduledoc """
2D Transform

A 2D transform is a 3x3 matrix that is typically used to represent translation,
rotation, and scale in the Euclidean plane.

There is no extra data structure. This module constructs 3x3 matrices for those
operations and applies them to points, directions, vertices, and boxes. The
matrix itself is a `graphics:matrix3()` value; see the `matrix3` module for
linear algebra.

```erlang
M = transform2:translation({10.0, 20.0}).
{11.0, 22.0} = transform2:transform_point(M, {1.0, 2.0}).
```

To compose several operations, either multiply matrices or use the combinators,
which post-multiply so the new operation runs in local space.

```erlang
M1 = transform2:translate(matrix3:identity(), {10.0, 0.0}),
M2 = transform2:rotate(M1, math:pi() / 2.0).
```

For the common origin, position, rotation, and scale case, use `compose/3` or
`compose/4`. A point is first moved so the origin is at zero, then scaled, then
rotated, then moved to the position.

Rotation is counter-clockwise around the origin, matching `vector2:rotate/2`.
Angles are in radians.

Beware that a well-formed 3x3 matrix always contains floats, not integers.
""".

-export([
    translation/1,
    rotation/1,
    scale/1
]).
-export([
    translate/2,
    rotate/2,
    scale/2
]).
-export([
    compose/3, compose/4,
    decompose/1
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
A translation 3x3 matrix.

It constructs a 3x3 matrix that translates by the given 2D vector.

```erlang
{11.0, 22.0} = transform2:transform_point(
    transform2:translation({10.0, 20.0}),
    {1.0, 2.0}
).
```
""".
-spec translation(graphics:vector2()) -> graphics:matrix3().
translation({X, Y}) ->
    {
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        X,   Y,   1.0
    }.

-doc """
A rotation 3x3 matrix.

It constructs a 3x3 matrix that rotates around the origin by the given angle in
radians. The rotation is counter-clockwise, matching `vector2:rotate/2`.
""".
-spec rotation(graphics:angle()) -> graphics:matrix3().
rotation(Angle) ->
    Cos = math:cos(Angle),
    Sin = math:sin(Angle),
    {
        Cos,  Sin, 0.0,
       -Sin,  Cos, 0.0,
        0.0,  0.0, 1.0
    }.

-doc """
A scale 3x3 matrix.

It constructs a 3x3 matrix that scales by the given 2D vector.

```erlang
{2.0, 6.0} = transform2:transform_point(
    transform2:scale({2.0, 3.0}),
    {1.0, 2.0}
).
```
""".
-spec scale(graphics:vector2()) -> graphics:matrix3().
scale({X, Y}) ->
    {
        X,   0.0, 0.0,
        0.0, Y,   0.0,
        0.0, 0.0, 1.0
    }.

-doc """
Translate a 3x3 matrix.

It post-multiplies a 3x3 matrix by a translation. The translation runs in the
matrix's local space.
""".
-spec translate(graphics:matrix3(), graphics:vector2()) -> graphics:matrix3().
translate(Matrix, Vector) ->
    matrix3:multiply(Matrix, translation(Vector)).

-doc """
Rotate a 3x3 matrix.

It post-multiplies a 3x3 matrix by a rotation. The rotation runs in the
matrix's local space and is counter-clockwise.
""".
-spec rotate(graphics:matrix3(), graphics:angle()) -> graphics:matrix3().
rotate(Matrix, Angle) ->
    matrix3:multiply(Matrix, rotation(Angle)).

-doc """
Scale a 3x3 matrix.

It post-multiplies a 3x3 matrix by a scale transform. The scale runs in the
matrix's local space.
""".
-spec scale(graphics:matrix3(), graphics:vector2()) -> graphics:matrix3().
scale(Matrix, Vector) ->
    matrix3:multiply(Matrix, scale(Vector)).

-doc """
Compose a 2D transform from position, rotation, and scale.

It constructs the 3x3 matrix that scales, then rotates, then translates. The
origin is `{0.0, 0.0}`.
""".
-spec compose(graphics:vector2(), graphics:angle(), graphics:vector2()) ->
    graphics:matrix3().
compose(Position, Rotation, Scale) ->
    compose(vector2:zero(), Position, Rotation, Scale).

-doc """
Compose a 2D transform from origin, position, rotation, and scale.

It constructs the 3x3 matrix `T(Position) * R * S * T(-Origin)`. A point is
first moved so the origin is at zero, then scaled, then rotated, then moved to
the position.
""".
-spec compose(
    graphics:vector2(),
    graphics:vector2(),
    graphics:angle(),
    graphics:vector2()
) -> graphics:matrix3().
compose(Origin, Position, Rotation, Scale) ->
    matrix3:multiply(
        translation(Position),
        matrix3:multiply(
            rotation(Rotation),
            matrix3:multiply(
                scale(Scale),
                translation(vector2:negate(Origin))
            )
        )
    ).

-doc """
Decompose a 2D transform.

It extracts translation, rotation, and scale from a 3x3 matrix. The matrix is
assumed to have no shear. Reflection is stored on the Y scale. This is not
required to recover an arbitrary matrix.
""".
-spec decompose(graphics:matrix3()) ->
    {graphics:vector2(), graphics:angle(), graphics:vector2()}.
decompose({M11, M21, _, M12, M22, _, M13, M23, _}) ->
    Translation = {M13, M23},
    ScaleX = vector2:length({M11, M21}),
    ScaleY = vector2:length({M12, M22}),
    Det = M11 * M22 - M12 * M21,
    ScaleYSigned = if
        Det < 0.0 ->
            -ScaleY;
        true ->
            ScaleY
    end,
    Rotation = math:atan2(M21 / ScaleX, M11 / ScaleX),
    {Translation, Rotation, {ScaleX, ScaleYSigned}}.

-doc """
Transform a 2D point.

It transforms a 2D point by a 3x3 matrix. The point is treated as a homogeneous
vector `{X, Y, 1.0}`. If the resulting W component is not 1.0, the XY result is
divided by W.

This is the same computation as `matrix3:multiply_vector/2`.
""".
-spec transform_point(graphics:matrix3(), graphics:vector2()) ->
    graphics:vector2().
transform_point(Matrix, Point) ->
    matrix3:multiply_vector(Matrix, Point).

-doc """
Transform a 2D direction.

It transforms a 2D direction by the linear part of a 3x3 matrix. Translation is
ignored. This is not a correct normal transform when the scale is non-uniform.
""".
-spec transform_direction(graphics:matrix3(), graphics:vector2()) ->
    graphics:vector2().
transform_direction({M11, M21, _, M12, M22, _, _, _, _}, {X, Y}) ->
    {
        M11 * X + M12 * Y,
        M21 * X + M22 * Y
    }.

-doc """
Transform a 2D vertex.

It transforms the position of a 2D vertex by a 3x3 matrix. The color and UV
coordinates are left unchanged.
""".
-spec transform_vertex(graphics:matrix3(), graphics:vertex2()) ->
    graphics:vertex2().
transform_vertex(Matrix, {Position, Color, U, V}) ->
    {transform_point(Matrix, Position), Color, U, V}.

-doc """
Transform a 2D box.

It transforms every corner of a 2D box as a point and returns the axis-aligned
bounding box of the result. A rotated box is a larger axis-aligned box, not a
rotated rectangle.
""".
-spec transform_box(graphics:matrix3(), graphics:box2()) ->
    graphics:box2().
transform_box(Matrix, {{MinX, MinY}, {MaxX, MaxY}}) ->
    box2:from_points([
        transform_point(Matrix, {MinX, MinY}),
        transform_point(Matrix, {MaxX, MinY}),
        transform_point(Matrix, {MinX, MaxY}),
        transform_point(Matrix, {MaxX, MaxY})
    ]).
