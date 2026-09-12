%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_vector2).
-moduledoc """
2D Vector

A 2D vector is a pair of numbers that is typically used to represent 2D
positions and directions in the Euclidean plane.

The data structure of a 2D vector simply is a tuple of 2 floats where the first
component is called X and the second component is called Y. Therefore, 2D
vectors can be naturally created with the tuple syntax.

```erlang
V = {1.0, 2.0}.
```

To access the X component of a 2D vector, use the `x/1` function, and to
access the Y component, use the `y/1` function.

```erlang
1.0 = graphics_vector2:x(V).
2.0 = graphics_vector2:y(V).
```

A 2D vector where X and Y are set to zero is called a zero vector, which can
be conveniently created with the `zero/0` function.

```erlang
{0.0, 0.0} = graphics_vector2:zero().
```

A macro is also defined to represent the zero 2D vector. (The `graphics.hrl`
header must be included.)

```erlang
{0.0, 0.0} = ?VECTOR2_ZERO
```

The geometrical operations with 2D vectors are implemented. You can normalize
them and compute their length (also called magnitude). You can also compute the
dot product and the 2D cross product with other 2D vectors.

```erlang
5.0 = graphics_vector2:length({3.0, 4.0}).
{0.6, 0.8} = graphics_vector2:normalize({3.0, 4.0}).
11.0 = graphics_vector2:dot_product({1.0, 2.0}, {3.0, 4.0}).
-2.0 = graphics_vector2:cross_product({1.0, 2.0}, {3.0, 4.0}).
```

The regular mathematical operations are implemented too. You can add and
subtract with other 2D vectors as well as multiply with scalars. To transform a
2D point with a 3x3 matrix, see the `graphics_matrix3:multiply_vector/2` function.

```erlang
{4.0, 6.0} = graphics_vector2:add({1.0, 2.0}, {3.0, 4.0}).
{-1.0, 1.0} = graphics_vector2:subtract({1.0, 2.0}, {2.0, 1.0}).
{2.0, 4.0} = graphics_vector2:multiply({1.0, 2.0}, 2.0).
```

Finally, a 2D vector can be augmented to a 3D vector with the `to_vector3/1`
function.

Beware that a well-formed 2D vector always contains floats, not integers.
""".

-export([
    x/1, y/1
]).
-export([
    zero/0,
    is_zero/1
]).
-export([
    is_unit/1
]).
-export([
    length/1,
    length_squared/1,
    normalize/1
]).
-export([
    perpendicular/1
]).
-export([
    dot_product/2,
    cross_product/2
]).
-export([
    distance/2,
    distance_squared/2,
    direction/2,
    angle/2
]).
-export([
    project/2,
    rotate/2,
    reflect/2
]).
-export([
    clamp_length/3
]).
-export([
    add/2,
    subtract/2,
    multiply/2,
    divide/2
]).
-export([
    negate/1
]).
-export([
    is_equal_to/2, is_equal_to/3
]).
-export([
    to_vector3/1
]).
-export([
    min/2, max/2,
    abs/1,
    floor/1, ceil/1, round/1
]).
-export([
    to_angle/1,
    from_angle/1
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-compile({inline, [
    zero/0,
    x/1, y/1,
    length_squared/1,
    dot_product/2,
    cross_product/2,
    add/2,
    subtract/2,
    multiply/2,
    divide/2,
    negate/1,
    to_vector3/1,
    min/2, max/2,
    abs/1,
    floor/1, ceil/1, round/1
]}).

-define(EPSILON, 1.0e-6).

-doc """
The X component of a 2D vector.

It returns the X component of the 2D vector.
""".
-spec x(graphics:vector2()) -> float().
x({X, _}) ->
    X.

-doc """
The Y component of a 2D vector.

It returns the Y component of the 2D vector.
""".
-spec y(graphics:vector2()) -> float().
y({_, Y}) ->
    Y.

-doc """
The zero 2D vector.

It constructs a zero 2D vector (both components set to 0.0).

```erlang
{0.0, 0.0} = graphics_vector2:zero().
```

Note that the `?VECTOR2_ZERO` macro can be used instead.
""".
-spec zero() -> graphics:vector2().
zero() ->
    {0.0, 0.0}.

-doc """
Check whether a 2D vector is zero.

It returns `true` when both components are zero. The values `+0.0` and `-0.0`
are treated as equal.
""".
-spec is_zero(graphics:vector2()) -> boolean().
is_zero(Vector) ->
    is_equal_to(Vector, zero()).

-doc """
Check whether a 2D vector is a unit vector.

It returns `true` when the length of the vector differs from 1.0 by at most
1.0e-6.
""".
-spec is_unit(graphics:vector2()) -> boolean().
is_unit(Vector) ->
    erlang:abs(?MODULE:length(Vector) - 1.0) =< ?EPSILON.

-doc """
Compute the length of a 2D vector.

It computes the length of a 2D vector. The length of a vector is the distance
between its origin and its end point.

Note that it's also called the magnitude of the vector.
""".
-spec length(graphics:vector2()) -> float().
length(Vector) ->
    math:sqrt(length_squared(Vector)).

-doc """
Compute the squared length of a 2D vector.

It computes the squared length of a 2D vector. This avoids a square root and is
the preferred form when only comparing lengths.
""".
-spec length_squared(graphics:vector2()) -> float().
length_squared(Vector) ->
    dot_product(Vector, Vector).

-doc """
Normalize a 2D vector.

It normalizes a 2D vector. The length of the vector is computed and the vector
is divided by this length. The result is a vector with the same direction but
with a length of 1.0.

Normalizing a zero vector yields IEEE `inf` or `NaN`.
""".
-spec normalize(graphics:vector2()) -> graphics:vector2().
normalize({X, Y} = Vector) ->
    Length = ?MODULE:length(Vector),
    {X / Length, Y / Length}.

-doc """
A perpendicular 2D vector.

It returns the 2D vector rotated 90 degrees counter-clockwise: `{X, Y}` becomes
`{-Y, X}`.
""".
-spec perpendicular(graphics:vector2()) -> graphics:vector2().
perpendicular({X, Y}) ->
    {-Y, X}.

-doc """
Compute the dot product of two 2D vectors.

It computes the dot product of two 2D vectors. The dot product is a scalar
value that is the result of the sum of the products of the corresponding
components of the two vectors.

Note that this operation is also called the inner product.
""".
-spec dot_product(graphics:vector2(), graphics:vector2()) -> float().
dot_product({X1, Y1}, {X2, Y2}) ->
    X1 * X2 + Y1 * Y2.

-doc """
Compute the cross product of two 2D vectors.

It computes the 2D cross product of two 2D vectors. The result is the scalar
`X1 * Y2 - Y1 * X2`, which is the Z component of the 3D cross product after
both vectors are augmented with `Z = 0.0`.

The sign of the result is the signed area of the parallelogram they span: it is
positive when the shortest rotation from the first vector to the second is
counter-clockwise.
""".
-spec cross_product(graphics:vector2(), graphics:vector2()) -> float().
cross_product({X1, Y1}, {X2, Y2}) ->
    X1 * Y2 - Y1 * X2.

-doc """
Compute the distance between two 2D vectors.

It computes the Euclidean distance between two 2D points.
""".
-spec distance(graphics:vector2(), graphics:vector2()) -> float().
distance(V1, V2) ->
    ?MODULE:length(subtract(V2, V1)).

-doc """
Compute the squared distance between two 2D vectors.

It computes the squared Euclidean distance between two 2D points. This avoids a
square root and is the preferred form when only comparing distances.
""".
-spec distance_squared(graphics:vector2(), graphics:vector2()) -> float().
distance_squared(V1, V2) ->
    length_squared(subtract(V2, V1)).

-doc """
Compute the direction from one 2D vector to another.

It returns the unit vector pointing from the first 2D vector to the second. If
the two vectors are equal, the result is IEEE `inf` or `NaN`.
""".
-spec direction(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
direction(From, To) ->
    normalize(subtract(To, From)).

-doc """
Compute the signed angle from one 2D vector to another.

It computes the signed angle in radians from the first 2D vector to the second.
The result is in `(-pi, pi]`. The sign is positive when the shortest rotation
is counter-clockwise.
""".
-spec angle(graphics:vector2(), graphics:vector2()) -> graphics:angle().
angle(V1, V2) ->
    math:atan2(cross_product(V1, V2), dot_product(V1, V2)).

-doc """
Project a 2D vector onto another 2D vector.

It projects the first 2D vector onto the second. The second vector does not
need to be a unit vector. Projecting onto a zero vector yields IEEE `inf` or
`NaN`.
""".
-spec project(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
project(Vector, Onto) ->
    multiply(Onto, dot_product(Vector, Onto) / length_squared(Onto)).

-doc """
Rotate a 2D vector.

It rotates a 2D vector around the origin by the given angle in radians. The
rotation is counter-clockwise.
""".
-spec rotate(graphics:vector2(), graphics:angle()) -> graphics:vector2().
rotate({X, Y}, Angle) ->
    Cos = math:cos(Angle),
    Sin = math:sin(Angle),
    {X * Cos - Y * Sin, X * Sin + Y * Cos}.

-doc """
Reflect a 2D vector.

It reflects a 2D vector against a unit normal. The second argument is assumed
to have length 1.0.
""".
-spec reflect(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
reflect(Vector, Normal) ->
    subtract(Vector, multiply(Normal, 2.0 * dot_product(Vector, Normal))).

-doc """
Clamp the length of a 2D vector.

It returns a 2D vector with the same direction whose length is clamped between
`Min` and `Max`. `Min` and `Max` are non-negative and `Min =< Max`.

A zero vector is returned unchanged, because it has no direction to scale.
""".
-spec clamp_length(graphics:vector2(), float(), float()) -> graphics:vector2().
clamp_length(Vector, Min, Max) ->
    Length = ?MODULE:length(Vector),
    if
        Length == 0.0 ->
            Vector;
        Length < Min ->
            multiply(Vector, Min / Length);
        Length > Max ->
            multiply(Vector, Max / Length);
        true ->
            Vector
    end.

-doc """
Add a 2D vector to another 2D vector.

It adds the second 2D vector to the first 2D vector. Because the operation is
commutative, the order has no importance. If the first vector is denoted V1 and
the second is V2, it does `V1 + V2`.

Note that this operation is also called translation.
""".
-spec add(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
add({X1, Y1}, {X2, Y2}) ->
    {X1 + X2, Y1 + Y2}.

-doc """
Subtract a 2D vector from another 2D vector.

It subtracts the second 2D vector from the first 2D vector. Because the
operation is not commutative, the order has importance. If the first vector is
denoted V1 and the second is V2, it does `V1 - V2`.

Note that this operation is also called translation.
""".
-spec subtract(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
subtract({X1, Y1}, {X2, Y2}) ->
    {X1 - X2, Y1 - Y2}.

-doc """
Multiply a 2D vector with a scalar.

It multiplies a 2D vector with a scalar. If the vector is denoted V and the
scalar S, it does `S * V`. Because this operation is commutative, it's also
equivalent to `V * S`.

Note that this operation is also called scaling.
""".
-spec multiply(graphics:vector2(), float()) -> graphics:vector2().
multiply({X, Y}, Factor) ->
    {Factor * X, Factor * Y}.

-doc """
Divide a 2D vector by a scalar.

It divides each component of a 2D vector by a scalar. Dividing by zero yields
IEEE `inf` or `NaN`.
""".
-spec divide(graphics:vector2(), float()) -> graphics:vector2().
divide({X, Y}, Divider) ->
    {X / Divider, Y / Divider}.

-doc """
Negate a 2D vector.

It returns the opposite of a 2D vector: `{X, Y}` becomes `{-X, -Y}`.
""".
-spec negate(graphics:vector2()) -> graphics:vector2().
negate({X, Y}) ->
    {-X, -Y}.

-doc """
Check whether two 2D vectors are equal.

It returns `true` when both components compare equal. The values `+0.0` and
`-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:vector2(), graphics:vector2()) -> boolean().
is_equal_to({X1, Y1}, {X2, Y2}) ->
    X1 == X2 andalso Y1 == Y2.

-doc """
Check whether two 2D vectors are equal within an epsilon.

It returns `true` when each pair of corresponding components differs by at
most `Epsilon`.
""".
-spec is_equal_to(graphics:vector2(), graphics:vector2(), float()) -> boolean().
is_equal_to({X1, Y1}, {X2, Y2}, Epsilon) ->
    erlang:abs(X1 - X2) =< Epsilon andalso erlang:abs(Y1 - Y2) =< Epsilon.

-doc """
Augment a 2D vector.

It augments a 2D vector to a 3D vector. The Z component is set to 0.0.
""".
-spec to_vector3(graphics:vector2()) -> graphics:vector3().
to_vector3({X, Y}) ->
    {X, Y, 0.0}.

-doc """
Compute the minimum of two 2D vectors.

It computes the minimum of two 2D vectors. The minimum of two vectors is the
vector where each component is the minimum of the corresponding components of
the two vectors.
""".
-spec min(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
min({X1, Y1}, {X2, Y2}) ->
    {erlang:min(X1, X2), erlang:min(Y1, Y2)}.

-doc """
Compute the maximum of two 2D vectors.

It computes the maximum of two 2D vectors. The maximum of two vectors is the
vector where each component is the maximum of the corresponding components of
the two vectors.
""".
-spec max(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
max({X1, Y1}, {X2, Y2}) ->
    {erlang:max(X1, X2), erlang:max(Y1, Y2)}.

-doc """
Compute the absolute value of a 2D vector.

It returns the 2D vector where each component is replaced by its absolute
value.
""".
-spec abs(graphics:vector2()) -> graphics:vector2().
abs({X, Y}) ->
    {erlang:abs(X), erlang:abs(Y)}.

-doc """
Compute the floor of a 2D vector.

It returns the 2D vector where each component is replaced by the greatest
integer less than or equal to that component, as a float.
""".
-spec floor(graphics:vector2()) -> graphics:vector2().
floor({X, Y}) ->
    {erlang:float(erlang:floor(X)), erlang:float(erlang:floor(Y))}.

-doc """
Compute the ceiling of a 2D vector.

It returns the 2D vector where each component is replaced by the least integer
greater than or equal to that component, as a float.
""".
-spec ceil(graphics:vector2()) -> graphics:vector2().
ceil({X, Y}) ->
    {erlang:float(erlang:ceil(X)), erlang:float(erlang:ceil(Y))}.

-doc """
Round a 2D vector.

It returns the 2D vector where each component is rounded to the nearest
integer, as a float.
""".
-spec round(graphics:vector2()) -> graphics:vector2().
round({X, Y}) ->
    {erlang:float(erlang:round(X)), erlang:float(erlang:round(Y))}.

-doc """
Convert a 2D vector to an angle.

It returns the polar angle of a 2D vector in radians, measured
counter-clockwise from the positive X axis. The result is `atan2(Y, X)`, in
`(-pi, pi]`.

The angle of a zero vector is 0.0.
""".
-spec to_angle(graphics:vector2()) -> graphics:angle().
to_angle({X, Y}) ->
    math:atan2(Y, X).

-doc """
Create a 2D unit vector from an angle.

It returns the 2D unit vector `{cos(Angle), sin(Angle)}`. The angle is in
radians, measured counter-clockwise from the positive X axis.
""".
-spec from_angle(graphics:angle()) -> graphics:vector2().
from_angle(Angle) ->
    {math:cos(Angle), math:sin(Angle)}.

-doc """
Linearly interpolate two 2D vectors.

It interpolates from the first 2D vector to the second using `T`. When `T` is
0.0 the result is the first vector, and when `T` is 1.0 the result is the
second. `T` is not clamped, so values outside `[0.0, 1.0]` extrapolate.
""".
-spec lerp(graphics:vector2(), graphics:vector2(), float()) -> graphics:vector2().
lerp({X1, Y1}, {X2, Y2}, T) ->
    {
        X1 + T * (X2 - X1),
        Y1 + T * (Y2 - Y1)
    }.

-doc """
Smoothly interpolate two 2D vectors.

It interpolates from the first 2D vector to the second using the Hermite
smoothstep `T * T * (3.0 - 2.0 * T)`, then `lerp/3`. `T` is not clamped.
""".
-spec smooth_lerp(graphics:vector2(), graphics:vector2(), float()) ->
    graphics:vector2().
smooth_lerp(Vector1, Vector2, T) ->
    lerp(Vector1, Vector2, T * T * (3.0 - 2.0 * T)).
