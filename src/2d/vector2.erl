%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(vector2).
-moduledoc """
2D Vector

A 2D vector is a pair of numbers that is typically used to represent 2D
positions and directions in the Euclidean plane. Because it can also be seen as
a 3D vector and a 3x1 matrix if we assume an invisible third component set to
0.0 (also called the homogeneous coordinate), it defines operations with 3x3
matrices.

The data structure of a 2D vector simply is a tuple of 2 floats where the first
component is called X and the second component is called Y. Therefore, 2D
vectors can be naturally created with the tuple syntax.

```erlang
V = {1.0, 2.0}.
```

To access the X components of a 2D vector, use the `x/1` function, and to
access the Y component, use the `y/1` function.

```erlang
1.0 = vector2:x(V).
2.0 = vector2:y(V).
```

A 2D vector where X and Y are set to zero is called a zero vector, which can
be conveniently created with the `zero/0` function.

```erlang
{0.0, 0.0} = vector2:zero().
```

A macro is also defined to represent the zero 2D vector. (The `graphics.hrl`
header must be included.)

```erlang
{0.0, 0.0} = ?VECTOR2_ZERO
```

The geometrical operations with 2D vectors are implemented. You can normalize
them and compute their length (also called magnitude). You can also compute the
dot product and cross product with other 2D vectors.

```erlang
5.0 = vector2:length({3.0, 4.0}).
{0.6, 0.8} = vector2:normalize({3.0, 4.0}).
11.0 = vector2:dot_product({1.0, 2.0}, {3.0, 4.0}).
-2.0 = vector2:cross_product({1.0, 2.0}, {3.0, 4.0}).
```

The regular mathematical operations are implemented too. You can add and
subtract with other 2D vectors as well as multiply with scalars. Note that if
you need to multiply with a 3x3 matrix, see the `matrix3:dot_vector/2`
function.

```erlang
{4.0, 6.0} = vector2:add({1.0, 2.0}, {3.0, 4.0}).
{-1.0, 1.0} = vector2:subtract({1.0, 2.0}, {2.0, 1.0}).
{2.0, 4.0} = vector2:multiply({1.0, 2.0}, 2.0).
 ```

Finally, the 2D vector can be augmented to a 3D vector with the `to_vector3/1`
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
    unit/1,
    is_unit/1
]).
-export([
    length/1,
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
    multiply/2
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
    dot_product/2,
    cross_product/2,
    add/2,
    subtract/2,
    multiply/2,
    to_vector3/1,
    min/2, max/2,
    abs/1,
    floor/1, ceil/1, round/1
]}).

-doc """
The X component of the 2D vector.

It returns the X component of the 2D vector.
""".
-spec x(graphics:vector2()) -> float().
x({X, _}) ->
    X.

-doc """
The Y component of the 2D vector.

It returns the Y component of the 2D vector.
""".
-spec y(graphics:vector2()) -> float().
y({_, Y}) ->
    Y.

-doc """
The zero 2D vector.

It constructs a zero 2D vector (both components set to 0.0).

```erlang
{0.0, 0.0} = vector2:zero().
```

Note that the `?VECTOR2_ZERO` macro can be used instead.
""".
-spec zero() -> graphics:vector2().
zero() ->
    {0.0, 0.0}.

-doc """
To be written.
""".
-spec is_zero(graphics:vector2()) -> boolean().
is_zero({+0.0, +0.0}) ->
    true;
is_zero({-0.0, -0.0}) ->
    true;
is_zero({+0.0, -0.0}) ->
    true;
is_zero({-0.0, +0.0}) ->
    true;
is_zero(_Vector) ->
    false.

-doc """
To be written.
""".
-spec unit(graphics:vector2()) -> graphics:vector2().
unit(_Vector) ->
    ok.

-doc """
To be written.
""".
-spec is_unit(graphics:vector2()) -> boolean().
is_unit(_Vector) ->
    ok.

-doc """
Compute the length of a 2D vector.

It computes the length of a 2D vector. The length of a vector is the distance
between its origin and its end point.

Note that it's also called the magnitude of the vector.
""".
-spec length(graphics:vector2()) -> float().
length(Vector) ->
    math:sqrt(dot_product(Vector, Vector)).

-doc """
Normalize a 2D vector.

It normalizes a 2D vector. The length of the vector is computed and the vector
is divided by this length. The result is a vector with the same direction but
with a length of 1.0.
""".
-spec normalize(graphics:vector2()) -> graphics:vector2().
normalize({X, Y} = Vector) ->
    Length = vector2:length(Vector),
    {X/Length, Y/Length}.

-doc """
To be written.
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
    X1*X2 + Y1*Y2.

-doc """
Compute the cross product of two 2D vectors.

It computes the cross product of two 2D vectors. The cross product is a vector
that is perpendicular to the plane defined by the two vectors. The cross
product is only defined in 3D space, but it can be computed in 2D space by
augmenting the 2D vectors to 3D vectors with a Z component set to 0.0.
""".
-spec cross_product(graphics:vector2(), graphics:vector2()) -> float().
cross_product({X1, Y1}, {X2, Y2}) ->
    X1*Y2 - Y1*X2.

-doc """
To be written.
""".
-spec distance(graphics:vector2(), graphics:vector2()) -> float().
distance(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec direction(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
direction(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec angle(graphics:vector3(), graphics:vector3()) -> graphics:angle().
angle(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec project(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
project(_Vector, _Onto) ->
    ok.

-doc """
To be written.
""".
-spec rotate(graphics:vector2(), graphics:angle()) -> graphics:vector2().
rotate(_Vector, _Angle) ->
    ok.

-doc """
To be written.
""".
-spec reflect(graphics:vector2(), graphics:vector2()) -> graphics:vector2().
reflect(_Vector, _Axis) ->
    ok.

-doc """
To be written.
""".
-spec clamp_length(graphics:vector2(), float(), float()) -> graphics:vector2().
clamp_length(_Vector, _Min, _Max) ->
    ok.

-doc """
Add a 2D vector to another 2D vector.

It adds the second 2D vector to the first 2D vector. Because the operation is
commutative, the order has no importance. If the first vector is denoted V1 and
the second is V2, it does `V1 + V2`.

Note that this operation is also called translation.
""".
-spec add(graphics:vector2(), graphics:vector2()) ->
    graphics:vector2()
.
add({X1, Y1}, {X2, Y2}) ->
    {X1 + X2, Y1 + Y2}.

-doc """
Subtract a 2D vector from another 2D vector.

It subtracts the second 2D vector from the first 2D vector. Because the
operation is not commutative, the order has importance. If the first vector is
denoted V1 and the second is V2, it does `V1 - V2`.

Note that this operation is also called translation.
""".
-spec subtract(graphics:vector2(), graphics:vector2()) ->
    graphics:vector2()
.
subtract({X1, Y1}, {X2, Y2}) ->
    {X1 - X2, Y1 - Y2}.

-doc """
Multiply a 2D vector with a scalar.

It multiplies a 2D vector with a scalar. If the vector is noted V and the
scalar V, it does `S . V`. Because this operation is commutative, it's also
equivalent to `V . S`.

Note that this operation is also called scaling.
""".
-spec multiply(graphics:vector2(), float()) -> graphics:vector2().
multiply({X, Y}, Factor) ->
    {Factor * X, Factor * Y}.

-doc """
To be written.
""".
-spec is_equal_to(graphics:vector2(), graphics:vector2()) -> boolean().
is_equal_to(_V1, _V2) ->
    ok.

-doc """
To be written.
""".
-spec is_equal_to(graphics:vector2(), graphics:vector2(), float()) -> boolean().
is_equal_to(_V1, _V2, _Epsilon) ->
    ok.

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
-spec min(graphics:vector2(), graphics:vector2()) ->
    graphics:vector2().
min({X1, Y1}, {X2, Y2}) ->
    {erlang:min(X1, X2), erlang:min(Y1, Y2)}.

-doc """
Compute the maximum of two 2D vectors.

It computes the maximum of two 2D vectors. The maximum of two vectors is the
vector where each component is the maximum of the corresponding components of
the two vectors.
""".
-spec max(graphics:vector2(), graphics:vector2()) ->
    graphics:vector2().
max({X1, Y1}, {X2, Y2}) ->
    {erlang:max(X1, X2), erlang:max(Y1, Y2)}.

-doc """
To be written.
""".
-spec abs(graphics:vector2()) -> graphics:vector2().
abs({X, Y}) ->
    {erlang:abs(X), erlang:abs(Y)}.

-doc """
To be written.
""".
-spec floor(graphics:vector2()) -> graphics:vector2().
floor({X, Y}) ->
    {erlang:float(erlang:floor(X)), erlang:float(erlang:floor(Y))}.

-doc """
To be written.
""".
-spec ceil(graphics:vector2()) -> graphics:vector2().
ceil({X, Y}) ->
    {erlang:float(erlang:ceil(X)), erlang:float(erlang:ceil(Y))}.

-doc """
To be written.
""".
-spec round(graphics:vector2()) -> graphics:vector2().
round({X, Y}) ->
    {erlang:float(erlang:round(X)), erlang:float(erlang:round(Y))}.

-doc """
To be written.
""".
-spec to_angle(graphics:vector2()) -> graphics:angle().
to_angle({_X, _Y}) ->
    ok.

-doc """
To be written.
""".
-spec from_angle(graphics:angle()) -> graphics:vector2().
from_angle(_Angle) ->
    ok.

-doc """
To be written.
""".
-spec lerp(graphics:vector2(), graphics:vector2(), float()) -> graphics:vector2().
lerp({X1, Y1}, {X2, Y2}, T) ->
    {
        X1 + T * (X2 - X1),
        Y1 + T * (Y2 - Y1)
    }.

-doc """
To be written.
""".
-spec smooth_lerp(graphics:vector2(), graphics:vector2(), float()) -> graphics:vector2().
smooth_lerp(V1, V2, T) ->
    smooth_lerp(V1, V2, T * T * (3.0 - 2.0 * T)).
