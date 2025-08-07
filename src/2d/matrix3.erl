%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(matrix3).
-moduledoc """
3x3 Matrix

A 3x3 matrix is a grid of numbers that is typically used to represent 2D
transformations in the Euclidean plane. Because it can also be seen as a 2x3
matrix by ignoring the third row and assuming its value is [0, 0, 1]
(also called the homogeneous coordinates), it defines operations with 2D
vectors.

> While 3x3 matrices are powerful, manually constructing them for
> transformations can be error-prone. For common 2D operations
> (e.g., translation, rotation), prefer the transform2 API, which wraps a 3x3
> matrix in a more ergonomic interface.

The matrix is stored as a flat tuple of 9 floats in column-major order (top-to-bottom, left-to-right):

The data structure of a 3x3 matrix simply is a flat tuple of 9 floats win
column-major order (top-to-bottom, left-to-right). Therefore, 3x3 matrices can
naturally be created with the tuple syntax.

```
M = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0}.
```

> If snippets of code showcasing matrices never split their elements over
> multiple lines (for readability), this is to avoid confusion with the usual
> mathematical notation which uses the row-major layout.

To access the elements of a 3x3 matrix, use either the `element/2` or
`element/3` function.

```
1.0 = matrix3:elem(M, 1).
4.0 = matrix3:elem(M, 4).
1.0 = matrix3:element(M, 1, 1).
3.0 = matrix3:element(M, 3, 1).
7.0 = matrix3:element(M, 1, 3).
```
A 3x3 matrix where all the elements are set to zero is called a zero matrix,
which can be conveniently created with the zero/0 function. Also a zero 3x3
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
Constants are also defined to represent the zero and identity 3x3 matrix.
You must include the `beam_graphics.hrl` header to use them.
```
{
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0
} = ?MATRIX_3X3_ZERO.
{
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0
} = ?MATRIX_3X3_IDENTITY.
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
    from_rows/3,
    from_columns/3
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
    is_orthogonal/1,
    is_symmetric/1
]).
-export([
    add/2,
    subtract/2,
    multiply/2,
    multiply_vector/2
]).
-export([
    to_matrix4/1
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-type vector3() :: graphics:vector3().

-doc """
The zero 3x3 matrix.

It constructs a zero 3x3 matrix.

```erlang
{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = matrix3:zero().
```

Note that the `?MATRIX3_ZERO` macro can be used instead.
""".
-spec zero() -> graphics:matrix3().
zero() ->
    {
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0
    }.

-doc """
To be written.

To be written.
""".
-spec is_zero(graphics:matrix3()) -> boolean().
is_zero(_Matrix) ->
    % XXX

    ok.

-doc """
The identity 3x3 matrix.

It constructs a zero 3x3 matrix.

```erlang
{1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = matrix3:zero().
```

Note that the `?MATRIX3_IDENTITY` macro can be used instead.
""".
-spec identity() -> graphics:matrix3().
identity() ->
    {
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
    }.

-doc """
To be written.

To be written.
""".
-spec is_identity(graphics:matrix3()) -> boolean().
is_identity(_Matrix) ->
    % XXX

    ok.

-doc """
To be written.

To be written.
""".
-spec from_rows(vector3(), vector3(), vector3()) -> graphics:matrix3().
from_rows(Row1, Row2, Row3) ->
    {
        element(1, Row1), element(1, Row2), element(1, Row3),
        element(2, Row1), element(2, Row2), element(2, Row3),
        element(3, Row1), element(3, Row2), element(3, Row3)
    }.

-doc """
To be written.

To be written.
""".
-spec from_columns(vector3(), vector3(), vector3()) -> graphics:matrix3().
from_columns(Column1, Column2, Column3) ->
    {
        element(1, Column1), element(2, Column1), element(3, Column1),
        element(1, Column2), element(2, Column2), element(3, Column2),
        element(1, Column3), element(2, Column3), element(3, Column3)
    }.

-doc """
To be written.

To be written.
""".
-spec element(graphics:matrix3(), integer(), integer()) -> float().
element(Matrix, Row, Column) ->
    case {Row, Column} of
        {1, 1} -> element(1, Matrix);
        {2, 1} -> element(2, Matrix);
        {3, 1} -> element(3, Matrix);
        {1, 2} -> element(4, Matrix);
        {2, 2} -> element(5, Matrix);
        {3, 2} -> element(6, Matrix);
        {1, 3} -> element(7, Matrix);
        {2, 3} -> element(8, Matrix);
        {3, 3} -> element(9, Matrix)
    end.

-doc """
To be written.

To be written.
""".
-spec row(graphics:matrix3(), Index :: 1..3) -> graphics:vector3().
row(Matrix, Index) ->
    case Index of
        1 -> {element(1, Matrix), element(4, Matrix), element(7, Matrix)};
        2 -> {element(2, Matrix), element(5, Matrix), element(8, Matrix)};
        3 -> {element(3, Matrix), element(6, Matrix), element(9, Matrix)}
    end.

-doc """
To be written.

To be written.
""".
-spec column(graphics:matrix3(), Index :: 1..3) -> graphics:vector3().
column(Matrix, Index) ->
    case Index of
        1 -> {element(1, Matrix), element(2, Matrix), element(3, Matrix)};
        2 -> {element(4, Matrix), element(5, Matrix), element(6, Matrix)};
        3 -> {element(7, Matrix), element(8, Matrix), element(9, Matrix)}
    end.

-doc """
To be written.

To be written.
""".
-spec rows(graphics:matrix3()) ->
    {graphics:vector3(), graphics:vector3(), graphics:vector3()}.
rows(Matrix) ->
    {row(Matrix, 1), row(Matrix, 2), row(Matrix, 3)}.

-doc """
To be written.

To be written.
""".
-spec columns(graphics:matrix3()) ->
    {graphics:vector3(), graphics:vector3(), graphics:vector3()}.
columns(Matrix) ->
    {column(Matrix, 1), column(Matrix, 2), column(Matrix, 3)}.

-doc """
To be written.

To be written.
""".
-spec transpose(graphics:matrix3()) -> graphics:matrix3().
transpose(Matrix) ->
    {
        element(1, Matrix), element(4, Matrix), element(7, Matrix),
        element(2, Matrix), element(5, Matrix), element(8, Matrix),
        element(3, Matrix), element(6, Matrix), element(9, Matrix)
    }.

-doc """
To be written.

To be written.
""".
-spec inverse(graphics:matrix3()) -> {ok, graphics:matrix3()} | {error, singular}.
inverse(Matrix) ->
    Det = determinant(Matrix),
    case abs(Det) < 1.0e-10 of
        true ->
            {error, singular};
        false ->
            % Calculate the cofactor matrix
            C11 = element(5, Matrix) * element(9, Matrix) - element(6, Matrix) * element(8, Matrix),
            C12 = -(element(4, Matrix) * element(9, Matrix) - element(6, Matrix) * element(7, Matrix)),
            C13 = element(4, Matrix) * element(8, Matrix) - element(5, Matrix) * element(7, Matrix),

            C21 = -(element(2, Matrix) * element(9, Matrix) - element(3, Matrix) * element(8, Matrix)),
            C22 = element(1, Matrix) * element(9, Matrix) - element(3, Matrix) * element(7, Matrix),
            C23 = -(element(1, Matrix) * element(8, Matrix) - element(2, Matrix) * element(7, Matrix)),

            C31 = element(2, Matrix) * element(6, Matrix) - element(3, Matrix) * element(5, Matrix),
            C32 = -(element(1, Matrix) * element(6, Matrix) - element(3, Matrix) * element(4, Matrix)),
            C33 = element(1, Matrix) * element(5, Matrix) - element(2, Matrix) * element(4, Matrix),

            % Transpose the cofactor matrix and divide by determinant to get the inverse
            InvDet = 1.0 / Det,
            {ok, {
                C11 * InvDet, C21 * InvDet, C31 * InvDet,
                C12 * InvDet, C22 * InvDet, C32 * InvDet,
                C13 * InvDet, C23 * InvDet, C33 * InvDet
            }}
    end.

-doc """
To be written.

To be written.
""".
-spec determinant(graphics:matrix3()) -> float().
determinant(Matrix) ->
    element(Matrix, 1, 1) * (element(Matrix, 2, 2) * element(Matrix, 3, 3) - element(Matrix, 2, 3) * element(Matrix, 3, 2)) -
    element(Matrix, 1, 2) * (element(Matrix, 2, 1) * element(Matrix, 3, 3) - element(Matrix, 2, 3) * element(Matrix, 3, 1)) +
    element(Matrix, 1, 3) * (element(Matrix, 2, 1) * element(Matrix, 3, 2) - element(Matrix, 2, 2) * element(Matrix, 3, 1)).

-doc """
To be written.

To be written.
""".
-spec is_orthogonal(graphics:matrix3()) -> boolean().
is_orthogonal(_Matrix) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec is_symmetric(graphics:matrix3()) -> boolean().
is_symmetric(_Matrix) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec add(graphics:matrix3(), graphics:matrix3()) -> graphics:matrix3().
add(_Matrix1, _Matrix2) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec subtract(graphics:matrix3(), graphics:matrix3()) -> graphics:matrix3().
subtract(_Matrix1, _Matrix2) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec multiply(graphics:matrix3(), graphics:matrix3()) -> graphics:matrix3().
multiply(Matrix1, Matrix2) ->
    C11 = element(1, Matrix1) * element(1, Matrix2) +
          element(4, Matrix1) * element(2, Matrix2) +
          element(7, Matrix1) * element(3, Matrix2),
    C21 = element(2, Matrix1) * element(1, Matrix2) +
          element(5, Matrix1) * element(2, Matrix2) +
          element(8, Matrix1) * element(3, Matrix2),
    C31 = element(3, Matrix1) * element(1, Matrix2) +
          element(6, Matrix1) * element(2, Matrix2) +
          element(9, Matrix1) * element(3, Matrix2),

    C12 = element(1, Matrix1) * element(4, Matrix2) +
          element(4, Matrix1) * element(5, Matrix2) +
          element(7, Matrix1) * element(6, Matrix2),
    C22 = element(2, Matrix1) * element(4, Matrix2) +
          element(5, Matrix1) * element(5, Matrix2) +
          element(8, Matrix1) * element(6, Matrix2),
    C32 = element(3, Matrix1) * element(4, Matrix2) +
          element(6, Matrix1) * element(5, Matrix2) +
          element(9, Matrix1) * element(6, Matrix2),

    C13 = element(1, Matrix1) * element(7, Matrix2) +
          element(4, Matrix1) * element(8, Matrix2) +
          element(7, Matrix1) * element(9, Matrix2),
    C23 = element(2, Matrix1) * element(7, Matrix2) +
          element(5, Matrix1) * element(8, Matrix2) +
          element(8, Matrix1) * element(9, Matrix2),
    C33 = element(3, Matrix1) * element(7, Matrix2) +
          element(6, Matrix1) * element(8, Matrix2) +
          element(9, Matrix1) * element(9, Matrix2),

    {C11, C21, C31, C12, C22, C32, C13, C23, C33}.

-doc """
To be written.

To be written.
""".
-spec multiply_vector(graphics:matrix3(), graphics:vector2()) ->
    graphics:matrix3().
multiply_vector(_Matrix, _Vector) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec to_matrix4(graphics:matrix3()) -> graphics:matrix4().
to_matrix4({M11, M21, M31, M12, M22, M32, M13, M23, M33}) ->
    {
        M11, M21, 0.0, M31,
        M12, M22, 0.0, M32,
        0.0, 0.0, 1.0, 0.0,
        M13, M23, 0.0, M33
    }.

-doc """
To be written.

To be written.
""".
-spec lerp(graphics:matrix3(), graphics:matrix3(), float()) -> graphics:matrix3().
lerp(_Matrix1, _Matrix2, _T) ->
    % XXX

    ok.

-doc """
To be written.

To be written.
""".
-spec smooth_lerp(graphics:matrix3(), graphics:matrix3(), float()) -> graphics:matrix3().
smooth_lerp(Matrix1, Matrix2, T) ->
    lerp(Matrix1, Matrix2, T * T * (3.0 - 2.0 * T)).
