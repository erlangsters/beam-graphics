%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_vector3).
-moduledoc """
3D Vector

A 3D vector is a triplet of numbers that is typically used to represent 3D
positions and directions in the Euclidean space.

The data structure of a 3D vector simply is a tuple of 3 floats where the first
component is called X, the second component is called Y and the third component
is called Z. Therefore, 3D vectors can be naturally created with the tuple
syntax.

```erlang
V = {1.0, 2.0, 3.0}.
```

To access the X component of a 3D vector, use the `x/1` function, to access
the Y component, use the `y/1` function, and to access the Z component, use the
`z/1` function.

```erlang
1.0 = graphics_vector3:x(V).
2.0 = graphics_vector3:y(V).
3.0 = graphics_vector3:z(V).
```

A 3D vector where X, Y and Z are set to zero is called a zero vector, which
can be conveniently created with the `zero/0` function.

```erlang
{0.0, 0.0, 0.0} = graphics_vector3:zero().
```

A macro is also defined to represent the zero 3D vector. (The `graphics.hrl`
header must be included.)

```erlang
{0.0, 0.0, 0.0} = ?VECTOR3_ZERO
```

The geometrical operations with 3D vectors are implemented. You can normalize
them and compute their length (also called magnitude). You can also compute the
dot product and cross product with other 3D vectors.

```erlang
7.0710678118654755 = graphics_vector3:length({3.0, 4.0, 5.0}).
{0.4242640687119285, 0.565685424949238, 0.7071067811865475} = graphics_vector3:normalize({3.0, 4.0, 5.0}).
32.0 = graphics_vector3:dot_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
{-3.0, 6.0, -3.0} = graphics_vector3:cross_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
```

The regular mathematical operations are implemented too. You can add and
subtract with other 3D vectors as well as multiply with scalars. To transform a
3D point with a 4x4 matrix, see the `graphics_matrix4:multiply_vector/2` function.

```erlang
{5.0, 7.0, 9.0} = graphics_vector3:add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
{-3.0, -3.0, -3.0} = graphics_vector3:subtract({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
{2.0, 4.0, 6.0} = graphics_vector3:multiply({1.0, 2.0, 3.0}, 2.0).
```

Finally, a 3D vector can be reduced to a 2D vector with the `to_vector2/1`
function.

Beware that a well-formed 3D vector always contains floats, not integers.
""".

-export([
    x/1, y/1, z/1
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
    dot_product/2,
    cross_product/2
]).
-export([
    distance/2,
    distance_squared/2,
    direction/2,
    angle/2, angle/3
]).
-export([
    project/2,
    rotate/3,
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
    to_vector2/1
]).
-export([
    min/2, max/2,
    abs/1,
    floor/1, ceil/1, round/1
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-compile({inline, [
    zero/0,
    x/1, y/1, z/1,
    length_squared/1,
    dot_product/2,
    cross_product/2,
    add/2,
    subtract/2,
    multiply/2,
    divide/2,
    negate/1,
    to_vector2/1,
    min/2, max/2,
    abs/1,
    floor/1, ceil/1, round/1
]}).

-define(EPSILON, 1.0e-6).

-doc """
The X component of a 3D vector.

It returns the X component of the 3D vector.
""".
-spec x(graphics:vector3()) -> float().
x({X, _, _}) ->
    X.

-doc """
The Y component of a 3D vector.

It returns the Y component of the 3D vector.
""".
-spec y(graphics:vector3()) -> float().
y({_, Y, _}) ->
    Y.

-doc """
The Z component of a 3D vector.

It returns the Z component of the 3D vector.
""".
-spec z(graphics:vector3()) -> float().
z({_, _, Z}) ->
    Z.

-doc """
The zero 3D vector.

It constructs a zero 3D vector (all components set to 0.0).

```erlang
{0.0, 0.0, 0.0} = graphics_vector3:zero().
```

Note that the `?VECTOR3_ZERO` macro can be used instead.
""".
-spec zero() -> graphics:vector3().
zero() ->
    {0.0, 0.0, 0.0}.

-doc """
Check whether a 3D vector is zero.

It returns `true` when all components are zero. The values `+0.0` and `-0.0`
are treated as equal.
""".
-spec is_zero(graphics:vector3()) -> boolean().
is_zero(Vector) ->
    is_equal_to(Vector, zero()).

-doc """
Check whether a 3D vector is a unit vector.

It returns `true` when the length of the vector differs from 1.0 by at most
1.0e-6.
""".
-spec is_unit(graphics:vector3()) -> boolean().
is_unit(Vector) ->
    erlang:abs(?MODULE:length(Vector) - 1.0) =< ?EPSILON.

-doc """
Compute the length of a 3D vector.

It computes the length of a 3D vector. The length of a vector is the distance
between its origin and its end point.

Note that it's also called the magnitude of the vector.
""".
-spec length(graphics:vector3()) -> float().
length(Vector) ->
    math:sqrt(length_squared(Vector)).

-doc """
Compute the squared length of a 3D vector.

It computes the squared length of a 3D vector. This avoids a square root and is
the preferred form when only comparing lengths.
""".
-spec length_squared(graphics:vector3()) -> float().
length_squared(Vector) ->
    dot_product(Vector, Vector).

-doc """
Normalize a 3D vector.

It normalizes a 3D vector. The length of the vector is computed and the vector
is divided by this length. The result is a vector with the same direction but
with a length of 1.0.

Normalizing a zero vector yields IEEE `inf` or `NaN`.
""".
-spec normalize(graphics:vector3()) -> graphics:vector3().
normalize({X, Y, Z} = Vector) ->
    Length = ?MODULE:length(Vector),
    {X / Length, Y / Length, Z / Length}.

-doc """
Compute the dot product of two 3D vectors.

It computes the dot product of two 3D vectors. The dot product is a scalar
value that is the result of the sum of the products of the corresponding
components of the two vectors.

Note that this operation is also called the inner product.
""".
-spec dot_product(graphics:vector3(), graphics:vector3()) -> float().
dot_product({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    X1 * X2 + Y1 * Y2 + Z1 * Z2.

-doc """
Compute the cross product of two 3D vectors.

It computes the cross product of two 3D vectors. The result is a 3D vector
perpendicular to both arguments. Its direction follows the right-hand rule.
""".
-spec cross_product(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
cross_product({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {Y1 * Z2 - Z1 * Y2, Z1 * X2 - X1 * Z2, X1 * Y2 - Y1 * X2}.

-doc """
Compute the distance between two 3D vectors.

It computes the Euclidean distance between two 3D points.
""".
-spec distance(graphics:vector3(), graphics:vector3()) -> float().
distance(V1, V2) ->
    ?MODULE:length(subtract(V2, V1)).

-doc """
Compute the squared distance between two 3D vectors.

It computes the squared Euclidean distance between two 3D points. This avoids a
square root and is the preferred form when only comparing distances.
""".
-spec distance_squared(graphics:vector3(), graphics:vector3()) -> float().
distance_squared(V1, V2) ->
    length_squared(subtract(V2, V1)).

-doc """
Compute the direction from one 3D vector to another.

It returns the unit vector pointing from the first 3D vector to the second. If
the two vectors are equal, the result is IEEE `inf` or `NaN`.
""".
-spec direction(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
direction(From, To) ->
    normalize(subtract(To, From)).

-doc """
Compute the unsigned angle between two 3D vectors.

It computes the unsigned angle in radians between two 3D vectors. The result
is in `[0, pi]`.
""".
-spec angle(graphics:vector3(), graphics:vector3()) -> graphics:angle().
angle(V1, V2) ->
    N1 = normalize(V1),
    N2 = normalize(V2),
    Dot = erlang:max(-1.0, erlang:min(1.0, dot_product(N1, N2))),
    math:acos(Dot).

-doc """
Compute the signed angle from one 3D vector to another around an axis.

It computes the signed angle in radians from the first 3D vector to the second,
oriented around `Axis`. The result is in `[-pi, pi]`. The sign is positive
when the shortest rotation follows the right-hand rule around `Axis`.
""".
-spec angle(graphics:vector3(), graphics:vector3(), graphics:vector3()) ->
    graphics:angle().
angle(V1, V2, Axis) ->
    Unsigned = angle(V1, V2),
    case dot_product(Axis, cross_product(V1, V2)) < 0.0 of
        true ->
            -Unsigned;
        false ->
            Unsigned
    end.

-doc """
Project a 3D vector onto another 3D vector.

It projects the first 3D vector onto the second. The second vector does not
need to be a unit vector. Projecting onto a zero vector yields IEEE `inf` or
`NaN`.
""".
-spec project(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
project(Vector, Onto) ->
    multiply(Onto, dot_product(Vector, Onto) / length_squared(Onto)).

-doc """
Rotate a 3D vector around an axis.

It rotates a 3D vector around `Axis` by the given angle in radians, using
Rodrigues' rotation formula. `Axis` is normalized internally. A zero axis
yields IEEE `inf` or `NaN`.
""".
-spec rotate(graphics:vector3(), graphics:angle(), graphics:vector3()) ->
    graphics:vector3().
rotate(Vector, Angle, Axis) ->
    Cos = math:cos(Angle),
    Sin = math:sin(Angle),
    K = normalize(Axis),
    D = dot_product(K, Vector),
    add(
        add(multiply(Vector, Cos), multiply(cross_product(K, Vector), Sin)),
        multiply(K, D * (1.0 - Cos))
    ).

-doc """
Reflect a 3D vector.

It reflects a 3D vector against a unit normal. The second argument is assumed
to have length 1.0.
""".
-spec reflect(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
reflect(Vector, Normal) ->
    subtract(Vector, multiply(Normal, 2.0 * dot_product(Vector, Normal))).

-doc """
Clamp the length of a 3D vector.

It returns a 3D vector with the same direction whose length is clamped between
`Min` and `Max`. `Min` and `Max` are non-negative and `Min =< Max`.

A zero vector is returned unchanged, because it has no direction to scale.
""".
-spec clamp_length(graphics:vector3(), float(), float()) -> graphics:vector3().
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
Add a 3D vector to another 3D vector.

It adds the second 3D vector to the first 3D vector. Because the operation is
commutative, the order has no importance. If the first vector is denoted V1 and
the second is V2, it does `V1 + V2`.

Note that this operation is also called translation.
""".
-spec add(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
add({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {X1 + X2, Y1 + Y2, Z1 + Z2}.

-doc """
Subtract a 3D vector from another 3D vector.

It subtracts the second 3D vector from the first 3D vector. Because the
operation is not commutative, the order has importance. If the first vector is
denoted V1 and the second is V2, it does `V1 - V2`.

Note that this operation is also called translation.
""".
-spec subtract(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
subtract({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {X1 - X2, Y1 - Y2, Z1 - Z2}.

-doc """
Multiply a 3D vector with a scalar.

It multiplies a 3D vector with a scalar. If the vector is denoted V and the
scalar S, it does `S * V`. Because this operation is commutative, it's also
equivalent to `V * S`.

Note that this operation is also called scaling.
""".
-spec multiply(graphics:vector3(), float()) -> graphics:vector3().
multiply({X, Y, Z}, Factor) ->
    {Factor * X, Factor * Y, Factor * Z}.

-doc """
Divide a 3D vector by a scalar.

It divides each component of a 3D vector by a scalar. Dividing by zero yields
IEEE `inf` or `NaN`.
""".
-spec divide(graphics:vector3(), float()) -> graphics:vector3().
divide({X, Y, Z}, Divider) ->
    {X / Divider, Y / Divider, Z / Divider}.

-doc """
Negate a 3D vector.

It returns the opposite of a 3D vector: `{X, Y, Z}` becomes `{-X, -Y, -Z}`.
""".
-spec negate(graphics:vector3()) -> graphics:vector3().
negate({X, Y, Z}) ->
    {-X, -Y, -Z}.

-doc """
Check whether two 3D vectors are equal.

It returns `true` when all components compare equal. The values `+0.0` and
`-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:vector3(), graphics:vector3()) -> boolean().
is_equal_to({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    X1 == X2 andalso Y1 == Y2 andalso Z1 == Z2.

-doc """
Check whether two 3D vectors are equal within an epsilon.

It returns `true` when each pair of corresponding components differs by at
most `Epsilon`.
""".
-spec is_equal_to(graphics:vector3(), graphics:vector3(), float()) -> boolean().
is_equal_to({X1, Y1, Z1}, {X2, Y2, Z2}, Epsilon) ->
    erlang:abs(X1 - X2) =< Epsilon
        andalso erlang:abs(Y1 - Y2) =< Epsilon
        andalso erlang:abs(Z1 - Z2) =< Epsilon.

-doc """
Reduce a 3D vector.

It reduces a 3D vector to a 2D vector. The Z component is discarded.
""".
-spec to_vector2(graphics:vector3()) -> graphics:vector2().
to_vector2({X, Y, _}) ->
    {X, Y}.

-doc """
Compute the minimum of two 3D vectors.

It computes the minimum of two 3D vectors. The minimum of two vectors is the
vector where each component is the minimum of the corresponding components of
the two vectors.
""".
-spec min(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
min({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {erlang:min(X1, X2), erlang:min(Y1, Y2), erlang:min(Z1, Z2)}.

-doc """
Compute the maximum of two 3D vectors.

It computes the maximum of two 3D vectors. The maximum of two vectors is the
vector where each component is the maximum of the corresponding components of
the two vectors.
""".
-spec max(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
max({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {erlang:max(X1, X2), erlang:max(Y1, Y2), erlang:max(Z1, Z2)}.

-doc """
Compute the absolute value of a 3D vector.

It returns the 3D vector where each component is replaced by its absolute
value.
""".
-spec abs(graphics:vector3()) -> graphics:vector3().
abs({X, Y, Z}) ->
    {erlang:abs(X), erlang:abs(Y), erlang:abs(Z)}.

-doc """
Compute the floor of a 3D vector.

It returns the 3D vector where each component is replaced by the greatest
integer less than or equal to that component, as a float.
""".
-spec floor(graphics:vector3()) -> graphics:vector3().
floor({X, Y, Z}) ->
    {
        erlang:float(erlang:floor(X)),
        erlang:float(erlang:floor(Y)),
        erlang:float(erlang:floor(Z))
    }.

-doc """
Compute the ceiling of a 3D vector.

It returns the 3D vector where each component is replaced by the least integer
greater than or equal to that component, as a float.
""".
-spec ceil(graphics:vector3()) -> graphics:vector3().
ceil({X, Y, Z}) ->
    {
        erlang:float(erlang:ceil(X)),
        erlang:float(erlang:ceil(Y)),
        erlang:float(erlang:ceil(Z))
    }.

-doc """
Round a 3D vector.

It returns the 3D vector where each component is rounded to the nearest
integer, as a float.
""".
-spec round(graphics:vector3()) -> graphics:vector3().
round({X, Y, Z}) ->
    {
        erlang:float(erlang:round(X)),
        erlang:float(erlang:round(Y)),
        erlang:float(erlang:round(Z))
    }.

-doc """
Linearly interpolate two 3D vectors.

It interpolates from the first 3D vector to the second using `T`. When `T` is
0.0 the result is the first vector, and when `T` is 1.0 the result is the
second. `T` is not clamped, so values outside `[0.0, 1.0]` extrapolate.
""".
-spec lerp(graphics:vector3(), graphics:vector3(), float()) -> graphics:vector3().
lerp({X1, Y1, Z1}, {X2, Y2, Z2}, T) ->
    {
        X1 + T * (X2 - X1),
        Y1 + T * (Y2 - Y1),
        Z1 + T * (Z2 - Z1)
    }.

-doc """
Smoothly interpolate two 3D vectors.

It interpolates from the first 3D vector to the second using the Hermite
smoothstep `T * T * (3.0 - 2.0 * T)`, then `lerp/3`. `T` is not clamped.
""".
-spec smooth_lerp(graphics:vector3(), graphics:vector3(), float()) ->
    graphics:vector3().
smooth_lerp(Vector1, Vector2, T) ->
    lerp(Vector1, Vector2, T * T * (3.0 - 2.0 * T)).
