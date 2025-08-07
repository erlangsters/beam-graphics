%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(vector3).
-moduledoc """
3D Vector

A 3D vector is a triplet of numbers that is typically used to represent 3D
positions and directions in the Euclidean space. Because it can also be seen as
a 4D vector and a 4x1 matrix if we assume an invisible fourth component set to
0.0 (also called the homogeneous coordinate), it defines operations with 4x4
matrices.

The data structure of a 3D vector simply is a tuple of 3 floats where the first
component is called X, the second component is called Y and the third component
is called Z. Therefore, 3D vectors can be naturally created with the tuple
syntax.

```erlang
V = {1.0, 2.0, 3.0}.
```

To access the X components of a 3D vector, use the `x/1` function, to access
the Y component, use the `y/1` function, and to access the Z component, use the
`z/1` function.

```erlang
1.0 = vector3:x(V).
2.0 = vector3:y(V).
3.0 = vector3:z(V).
```

A 3D vector where X, Y and Z are set to zero is called a zero vector, which
can be conveniently created with the `zero/0` function.

```erlang
{0.0, 0.0, 0.0} = vector3:zero().
```

A macro is also defined to represent the zero 3D vector. (The `graphics.hrl`
header must be included.)

```erlang
{0, 0} = ?VECTOR3_ZERO
```

The geometrical operations with 3D vectors are implemented. You can normalize
them and compute their length (also called magnitude). You can also compute the
dot product and cross product with other 3D vectors.

```erlang
7.0710678118654755 = vector3:length({3.0, 4.0, 5.0}).
{0.4242640687119285, 0.565685424949238, 0.7071067811865475} = vector3:normalize({3.0, 4.0, 5.0})
32.0 = vector3:dot_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
{-3.0, 6.0, -3.0} = vector3:cross_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
```

The regular mathematical operations are implemented too. You can add and
subtract with other 3D vectors as well as multiply with scalars. Note that if
you need to multiply with a 4x4 matrix, see the `matrix4:dot_vector/2`
function.

```erlang
{5.0, 7.0, 9.0} = vector3:add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
{-3.0, -3.0, -3.0} = vector3:subtract({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}).
{2.0, 4.0, 6.0} = vector3:multiply({1.0, 2.0, 3.0}, 2.0).
 ```

Finally, the 3D vector can be reduced to a 2D vector with the `to_vector2/1`
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
    unit/1,
    is_unit/1
]).
-export([
    length/1,
    normalize/1
]).
-export([
    dot_product/2,
    cross_product/2
]).
-export([
    distance/2,
    direction/2,
    angle/3
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
    multiply/2
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
    to_angle/2,
    from_angle/2
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-compile({inline, [
    zero/0,
    x/1, y/1, z/1,
    dot_product/2,
    cross_product/2,
    add/2,
    subtract/2,
    multiply/2,
    to_vector2/1,
    min/2, max/2,
    abs/1,
    floor/1, ceil/1, round/1
]}).

-doc """
The X component of the 3D vector.

It returns the X component of the 3D vector.
""".
-spec x(graphics:vector3()) -> float().
x({X, _, _}) ->
    X.

-doc """
The Y component of the 3D vector.

It returns the Y component of the 3D vector.
""".
-spec y(graphics:vector3()) -> float().
y({_, Y, _}) ->
    Y.

-doc """
The Z component of the 3D vector.

It returns the Z component of the 3D vector.
""".
-spec z(graphics:vector3()) -> float().
z({_, _, Z}) ->
    Z.

-doc """
A zero 3D vector.

It constructs a zero 3D vector.
""".
-spec zero() -> graphics:vector3().
zero() ->
    {0.0, 0.0, 0.0}.

-doc """
To be written.
""".
-spec is_zero(graphics:vector3()) -> boolean().
is_zero({+0.0, +0.0, +0.0}) ->
    true;
is_zero({+0.0, +0.0, -0.0}) ->
    true;
is_zero({+0.0, -0.0, +0.0}) ->
    true;
is_zero({+0.0, -0.0, -0.0}) ->
    true;
is_zero({-0.0, +0.0, +0.0}) ->
    true;
is_zero({-0.0, +0.0, -0.0}) ->
    true;
is_zero({-0.0, -0.0, +0.0}) ->
    true;
is_zero({-0.0, -0.0, -0.0}) ->
    true;
is_zero(_Vector) ->
    false.

-doc """
To be written.
""".
-spec unit(graphics:vector3()) -> graphics:vector3().
unit(_Vector) ->
    ok.

-doc """
To be written.
""".
-spec is_unit(graphics:vector3()) -> boolean().
is_unit(_Vector) ->
    ok.

-doc """
Compute the length of a 3D vector.

It computes the length of a 3D vector. The length of a vector is the distance
between its origin and its end point.

Note that it's also called the magnitude of the vector.
""".
-spec length(graphics:vector3()) -> float().
length(Vector) ->
    math:sqrt(dot_product(Vector, Vector)).

-doc """
Normalize a 3D vector.

It normalizes a 3D vector. The length of the vector is computed and the vector
is divided by this length. The result is a vector with the same direction but
with a length of 1.0.
""".
-spec normalize(graphics:vector3()) -> graphics:vector3().
normalize({X, Y, Z} = Vector) ->
    Length = vector3:length(Vector),
    {X/Length, Y/Length, Z/Length}.

-doc """
Compute the dot product of two 3D vectors.

It computes the dot product of two 3D vectors. The dot product is a scalar
value that is the result of the sum of the products of the corresponding
components of the two vectors.

Note that this operation is also called the inner product.
""".
-spec dot_product(graphics:vector3(), graphics:vector3()) -> float().
dot_product({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    X1*X2 + Y1*Y2 + Z1*Z2.

-doc """
Compute the cross product of two 3D vectors.

It computes the cross product of two 3D vectors. The cross product is a vector
that is perpendicular to the two vectors. The cross product is computed by
multiplying the corresponding components of the two vectors and subtracting the
result of the products of the other corresponding components.
""".
-spec cross_product(graphics:vector3(), graphics:vector3()) ->
    graphics:vector2()
.
cross_product({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {Y1*Z2 - Z1*Y2, Z1*X2 - X1*Z2, X1*Y2 - Y1*X2}.

-doc """
To be written.
""".
-spec distance(graphics:vector3(), graphics:vector3()) -> float().
distance(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec direction(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
direction(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec angle(graphics:vector3(), graphics:vector3(), graphics:vector3()) ->
    graphics:angle().
angle(_V1, _V2, _Axis) ->
    ok.

-doc """
To be written.
""".
-spec project(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
project(_Vector, _Onto) ->
    ok.

-doc """
To be written.
""".
-spec rotate(graphics:vector3(), graphics:angle(), graphics:vector3()) ->
    graphics:vector3().
rotate(_Vector, _Angle, _Axis) ->
    ok.

-doc """
To be written.
""".
-spec reflect(graphics:vector3(), graphics:vector3()) -> graphics:vector3().
reflect(_Vector, _Axis) ->
    ok.

-doc """
To be written.
""".
-spec clamp_length(graphics:vector3(), float(), float()) -> graphics:vector3().
clamp_length(_Vector, _Min, _Max) ->
    ok.

-doc """
Add a 3D vector to another 3D vector.

It adds the second 3D vector to the first 3D vector. Because the operation is
commutative, the order has no importance. If the first vector is denoted V1 and
the second is V2, it does `V1 + V2`.

Note that this operation is also called translation.
""".
-spec add(graphics:vector3(), graphics:vector3()) ->
    graphics:vector3()
.
add({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {X1 + X2, Y1 + Y2, Z1 + Z2}.

-doc """
Subtract a 3D vector from another 3D vector.

It subtracts the second 3D vector from the first 3D vector. Because the
operation is not commutative, the order has importance. If the first vector is
denoted V1 and the second is V2, it does `V1 - V2`.

Note that this operation is also called translation.
""".
-spec subtract(graphics:vector3(), graphics:vector3()) ->
    graphics:vector3()
.
subtract({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {X1 - X2, Y1 - Y2, Z1 - Z2}.

-doc """
Multiply a 3D vector with a scalar.

It multiplies a 3D vector with a scalar. If the vector is noted V and the
scalar V, it does `S . V`. Because this operation is commutative, it's also
equivalent to `V . S`.

Note that this operation is also called scaling.
""".
-spec multiply(graphics:vector3(), float()) -> graphics:vector3().
multiply({X, Y, Z}, Factor) ->
    {Factor * X, Factor * Y, Factor * Z}.

-doc """
To be written.
""".
-spec is_equal_to(graphics:vector3(), graphics:vector3()) -> boolean().
is_equal_to(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec is_equal_to(graphics:vector3(), graphics:vector3(), float()) -> boolean().
is_equal_to(_V1, _V2, _Epsilon) ->
    ok.

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
-spec min(graphics:vector3(), graphics:vector3()) ->
    graphics:vector3()
.
min({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {erlang:min(X1, X2), erlang:min(Y1, Y2), erlang:min(Z1, Z2)}.

-doc """
Compute the maximum of two 3D vectors.

It computes the maximum of two 3D vectors. The maximum of two vectors is the
vector where each component is the maximum of the corresponding components of
the two vectors.
""".
-spec max(graphics:vector3(), graphics:vector3()) ->
    graphics:vector3()
.
max({X1, Y1, Z1}, {X2, Y2, Z2}) ->
    {erlang:max(X1, X2), erlang:max(Y1, Y2), erlang:max(Z1, Z2)}.

-doc """
To be written.
""".
-spec abs(graphics:vector3()) -> graphics:vector3().
abs({X, Y, Z}) ->
    {erlang:abs(X), erlang:abs(Y), erlang:abs(Z)}.

-doc """
To be written.
""".
-spec floor(graphics:vector3()) -> graphics:vector3().
floor({X, Y, Z}) ->
    {
        erlang:float(erlang:floor(X)),
        erlang:float(erlang:floor(Y)),
        erlang:float(erlang:floor(Z))
    }.

-doc """
To be written.
""".
-spec ceil(graphics:vector3()) -> graphics:vector3().
ceil({X, Y, Z}) ->
    {
        erlang:float(erlang:ceil(X)),
        erlang:float(erlang:ceil(Y)),
        erlang:float(erlang:ceil(Z))
    }.

-doc """
To be written.
""".
-spec round(graphics:vector3()) -> graphics:vector3().
round({X, Y, Z}) ->
    {
        erlang:float(erlang:round(X)),
        erlang:float(erlang:round(Y)),
        erlang:float(erlang:round(Z))
    }.

-doc """
To be written.
""".
-spec to_angle(graphics:vector3(), graphics:vector3()) -> graphics:angle().
to_angle({_X, _Y, _Z}, _Axis) ->
    ok.

-doc """
To be written.
""".
-spec from_angle(graphics:angle(), graphics:vector3()) -> graphics:vector3().
from_angle(_Angle, _Axis) ->
    ok.

-doc """
To be written.
""".
-spec lerp(graphics:vector3(), graphics:vector3(), float()) -> graphics:vector3().
lerp({X1, Y1, Z1}, {X2, Y2, Z2}, T) ->
    {
        X1 + T * (X2 - X1),
        Y1 + T * (Y2 - Y1),
        Z1 + T * (Z2 - Z1)
    }.

-doc """
To be written.
""".
-spec smooth_lerp(graphics:vector3(), graphics:vector3(), float()) -> graphics:vector3().
smooth_lerp(V1, V2, T) ->
    smooth_lerp(V1, V2, T * T * (3.0 - 2.0 * T)).
