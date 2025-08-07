%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(matrix4).

-moduledoc """
4x4 Matrix

A 4x4 matrix is a grid of numbers that is typically used to represent 3D
transformations in the Euclidean space.

It can also be used as a 2x3 matrix (by ignoring the third
row and assuming its value is [0, 0, 1], also called the homogeneous '
coordinates) and therefore define operations with 2D vectors.

It's an unintuitive mathematical structure that is hard to manipulate
directly. Instead, use the transform2 and view2 modules that provides
higher-level operation to define your 2D transformations. They both wrap a
a 4x4 matrix.
of that, it's recommended to use the transform2 module that provides a more
convenient interface to manipulate 2D transformations.
The data structure of a 4x4 matrix simply is a tuple of 9 floats where the
elements represent the 2D array from top to bottom, left to right. Therefore,
4x4 matrices can naturally be created with the tuple syntax.
```
M = {
    1.0, 2.0, 3.0,
    4.0, 5.0, 6.0,
    7.0, 8.0, 9.0
}.
```
To access the elements of a 4x4 matrix, use either the `element/2` or
`element3` function.
```
1.0 = matrix3:elem(M, 1).
4.0 = matrix3:elem(M, 4).
1.0 = matrix3:element(M, 1, 1).
3.0 = matrix3:element(M, 3, 1).
7.0 = matrix3:element(M, 1, 3).
```
A 4x4 matrix where all the elements are set to zero is called a zero matrix,
which can be conveniently created with the zero/0 function. Also a zero 4x4
matrix with a 1.0 in the bottom right corner is called an identity matrix,
which can be conveniently created with the identity/0 function.
```
{
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0
} = matrix3:zero().
{
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0
} = matrix3:identity().
```
Constants are also defined to represent the zero and identity 4x4 matrix.
You must include the `beam_graphics.hrl` header to use them.
```
{
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0
} = ?MATRIX_4x4_ZERO.
{
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0
} = ?MATRIX_4x4_IDENTITY.
```

The common mathematical operations are also implemented.
""".

-export([
    zero/0,
    is_zero/1
]).
-export([
    identity/0,
    is_identity/1
]).
-export([
    from_rows/4,
    from_columns/4
]).
-export([
    element/3,
    row/2,
    column/2,
    rows/1,
    columns/1
]).
-export([
    transpose/1,
    inverse/1,
    determinant/1
]).
-export([
    add/2,
    subtract/2,
    multiply/2,
    multiply_vector/2
]).
-export([
    to_matrix3/1
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-type vector4() :: {float(), float(), float(), float()}.

-doc """
The zero 4x4 matrix.

It constructs a zero 4x4 matrix.

```erlang
{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} =
    matrix4:zero().
```

Note that the `?MATRIX4_ZERO` macro can be used instead.
""".
-spec zero() -> graphics:matrix4().
zero() ->
    {
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0
    }.

-doc """
To be written.

To be written.
""".
-spec is_zero(graphics:matrix4()) -> boolean().
is_zero(_Matrix) ->
    % XXX

    ok.

-doc """
The identity 4x4 matrix.

It constructs a zero 4x4 matrix.

```erlang
{1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0} =
    matrix3:identity().
```

Note that the `?MATRIX4_IDENTITY` macro can be used instead.
""".
-spec identity() -> graphics:matrix4().
identity() ->
    {
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    }.

-doc """
To be written.

To be written.
""".
-spec is_identity(graphics:matrix4()) -> boolean().
is_identity(_Matrix) ->
    % XXX

    ok.

-doc """
To be written.

To be written.
""".
-spec from_rows(vector4(), vector4(), vector4(), vector4()) -> graphics:matrix4().
from_rows(Row1, Row2, Row3, Row4) ->
    {
        element(1, Row1), element(1, Row2), element(1, Row3), element(1, Row4),
        element(2, Row1), element(2, Row2), element(2, Row3), element(2, Row4),
        element(3, Row1), element(3, Row2), element(3, Row3), element(3, Row4),
        element(4, Row1), element(4, Row2), element(4, Row3), element(4, Row4)
    }.

-doc """
To be written.

To be written.
""".
-spec from_columns(vector4(), vector4(), vector4(), vector4()) -> graphics:matrix4().
from_columns(Column1, Column2, Column3, Column4) ->
    {
        element(1, Column1), element(2, Column1), element(3, Column1), element(4, Column1),
        element(1, Column2), element(2, Column2), element(3, Column2), element(4, Column2),
        element(1, Column3), element(2, Column3), element(3, Column3), element(4, Column3),
        element(1, Column4), element(2, Column4), element(3, Column4), element(4, Column4)
    }.

-doc """
To be written.

To be written.
""".
-spec element(graphics:matrix4(), integer(), integer()) -> float().
element(Matrix, Row, Column) ->
    case {Row, Column} of
        {1, 1} -> element(1, Matrix);
        {2, 1} -> element(2, Matrix);
        {3, 1} -> element(3, Matrix);
        {4, 1} -> element(4, Matrix);
        {1, 2} -> element(5, Matrix);
        {2, 2} -> element(6, Matrix);
        {3, 2} -> element(7, Matrix);
        {4, 2} -> element(8, Matrix);
        {1, 3} -> element(9, Matrix);
        {2, 3} -> element(10, Matrix);
        {3, 3} -> element(11, Matrix);
        {4, 3} -> element(12, Matrix);
        {1, 4} -> element(13, Matrix);
        {2, 4} -> element(14, Matrix);
        {3, 4} -> element(15, Matrix);
        {4, 4} -> element(16, Matrix)
    end.

-doc """
To be written.

To be written.
""".
-spec row(graphics:matrix4(), Index :: 1..4) -> graphics:vector4().
row(Matrix, Row) ->
    case Row of
        1 -> {element(1, Matrix), element(5, Matrix), element(9, Matrix), element(13, Matrix)};
        2 -> {element(2, Matrix), element(6, Matrix), element(10, Matrix), element(14, Matrix)};
        3 -> {element(3, Matrix), element(7, Matrix), element(11, Matrix), element(15, Matrix)};
        4 -> {element(4, Matrix), element(8, Matrix), element(12, Matrix), element(16, Matrix)}
    end.

-doc """
To be written.

To be written.
""".
-spec column(graphics:matrix4(), Index :: 1..4) -> graphics:vector4().
column(Matrix, Column) ->
    case Column of
        1 -> {element(1, Matrix), element(2, Matrix), element(3, Matrix), element(4, Matrix)};
        2 -> {element(5, Matrix), element(6, Matrix), element(7, Matrix), element(8, Matrix)};
        3 -> {element(9, Matrix), element(10, Matrix), element(11, Matrix), element(12, Matrix)};
        4 -> {element(13, Matrix), element(14, Matrix), element(15, Matrix), element(16, Matrix)}
    end.

-doc """
To be written.

To be written.
""".
-spec rows(graphics:matrix4()) ->
    {graphics:vector4(), graphics:vector4(), graphics:vector4(), graphics:vector4()}.
rows(Matrix) ->
    {row(Matrix, 1), row(Matrix, 2), row(Matrix, 3), row(Matrix, 4)}.

-doc """
To be written.

To be written.
""".
-spec columns(graphics:matrix4()) ->
    {graphics:vector4(), graphics:vector4(), graphics:vector4(), graphics:vector4()}.
columns(Matrix) ->
    {column(Matrix, 1), column(Matrix, 2), column(Matrix, 3), column(Matrix, 4)}.

-doc """
To be written.

To be written.
""".
-spec transpose(graphics:matrix4()) -> graphics:matrix4().
transpose(Matrix) ->
    {
        element(1, Matrix), element(5, Matrix), element(9, Matrix),
        element(13, Matrix),
        element(2, Matrix), element(6, Matrix), element(10, Matrix),
        element(14, Matrix),
        element(3, Matrix), element(7, Matrix), element(11, Matrix),
        element(15, Matrix),
        element(4, Matrix), element(8, Matrix), element(12, Matrix),
        element(16, Matrix)
    }.

-doc """
To be written.

To be written.
""".
-spec inverse(graphics:matrix4()) -> graphics:matrix4() | undefined.
inverse(_Matrix) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec determinant(graphics:matrix4()) -> float().
determinant(_Matrix) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec add(graphics:matrix4(), graphics:matrix4()) -> graphics:matrix4().
add(_Matrix1, _Matrix2) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec subtract(graphics:matrix4(), graphics:matrix4()) -> graphics:matrix4().
subtract(_Matrix1, _Matrix2) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec multiply(graphics:matrix4(), graphics:matrix4()) -> graphics:matrix4().
multiply(Matrix1, Matrix2) ->
    C11 = element(1, Matrix1) * element(1, Matrix2) +
          element(5, Matrix1) * element(2, Matrix2) +
          element(9, Matrix1) * element(3, Matrix2) +
          element(13, Matrix1) * element(4, Matrix2),
    C21 = element(2, Matrix1) * element(1, Matrix2) +
          element(6, Matrix1) * element(2, Matrix2) +
          element(10, Matrix1) * element(3, Matrix2) +
          element(14, Matrix1) * element(4, Matrix2),
    C31 = element(3, Matrix1) * element(1, Matrix2) +
          element(7, Matrix1) * element(2, Matrix2) +
          element(11, Matrix1) * element(3, Matrix2) +
          element(15, Matrix1) * element(4, Matrix2),
    C41 = element(4, Matrix1) * element(1, Matrix2) +
          element(8, Matrix1) * element(2, Matrix2) +
          element(12, Matrix1) * element(3, Matrix2) +
          element(16, Matrix1) * element(4, Matrix2),
    C12 = element(1, Matrix1) * element(5, Matrix2) +
          element(5, Matrix1) * element(6, Matrix2) +
          element(9, Matrix1) * element(7, Matrix2) +
          element(13, Matrix1) * element(8, Matrix2),
    C22 = element(2, Matrix1) * element(5, Matrix2) +
          element(6, Matrix1) * element(6, Matrix2) +
          element(10, Matrix1) * element(7, Matrix2) +
          element(14, Matrix1) * element(8, Matrix2),
    C32 = element(3, Matrix1) * element(5, Matrix2) +
          element(7, Matrix1) * element(6, Matrix2) +
          element(11, Matrix1) * element(7, Matrix2) +
          element(15, Matrix1) * element(8, Matrix2),
    C42 = element(4, Matrix1) * element(5, Matrix2) +
          element(8, Matrix1) * element(6, Matrix2) +
          element(12, Matrix1) * element(7, Matrix2) +
          element(16, Matrix1) * element(8, Matrix2),
    C13 = element(1, Matrix1) * element(9, Matrix2) +
          element(5, Matrix1) * element(10, Matrix2) +
          element(9, Matrix1) * element(11, Matrix2) +
          element(13, Matrix1) * element(12, Matrix2),
    C23 = element(2, Matrix1) * element(9, Matrix2) +
          element(6, Matrix1) * element(10, Matrix2) +
          element(10, Matrix1) * element(11, Matrix2) +
          element(14, Matrix1) * element(12, Matrix2),
    C33 = element(3, Matrix1) * element(9, Matrix2) +
          element(7, Matrix1) * element(10, Matrix2) +
          element(11, Matrix1) * element(11, Matrix2) +
          element(15, Matrix1) * element(12, Matrix2),
    C43 = element(4, Matrix1) * element(9, Matrix2) +
          element(8, Matrix1) * element(10, Matrix2) +
          element(12, Matrix1) * element(11, Matrix2) +
          element(16, Matrix1) * element(12, Matrix2),
    C14 = element(1, Matrix1) * element(13, Matrix2) +
          element(5, Matrix1) * element(14, Matrix2) +
          element(9, Matrix1) * element(15, Matrix2) +
          element(13, Matrix1) * element(16, Matrix2),
    C24 = element(2, Matrix1) * element(13, Matrix2) +
          element(6, Matrix1) * element(14, Matrix2) +
          element(10, Matrix1) * element(15, Matrix2) +
          element(14, Matrix1) * element(16, Matrix2),
    C34 = element(3, Matrix1) * element(13, Matrix2) +
          element(7, Matrix1) * element(14, Matrix2) +
          element(11, Matrix1) * element(15, Matrix2) +
          element(15, Matrix1) * element(16, Matrix2),
    C44 = element(4, Matrix1) * element(13, Matrix2) +
          element(8, Matrix1) * element(14, Matrix2) +
          element(12, Matrix1) * element(15, Matrix2) +
          element(16, Matrix1) * element(16, Matrix2),

    {C11, C21, C31, C41, C12, C22, C32, C42, C13, C23, C33, C43, C14, C24, C34, C44}.

-doc """
To be written.

To be written.
""".
-spec multiply_vector(graphics:matrix4(), graphics:vector3()) ->
    graphics:matrix4().
multiply_vector(_Matrix, _Vector) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec to_matrix3(graphics:matrix4()) -> graphics:matrix3().
to_matrix3(_Matrix) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec lerp(graphics:matrix4(), graphics:matrix4(), float()) -> graphics:matrix4().
lerp(_Matrix1, _Matrix2, _T) ->
    % XXX

    ok.

-doc """
To be written.

To be written.
""".
-spec smooth_lerp(graphics:matrix4(), graphics:matrix4(), float()) -> graphics:matrix4().
smooth_lerp(Matrix1, Matrix2, T) ->
    lerp(Matrix1, Matrix2, T * T * (3.0 - 2.0 * T)).
