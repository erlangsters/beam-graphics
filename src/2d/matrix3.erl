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
transformations in the Euclidean plane.

> While 3x3 matrices are powerful, manually constructing them for
> transformations can be error-prone. For common 2D operations
> (e.g., translation, rotation), prefer the `transform2` API, which wraps a
> 3x3 matrix in a more ergonomic interface.

The data structure of a 3x3 matrix simply is a flat tuple of 9 floats in
column-major order (top-to-bottom, left-to-right). Therefore, 3x3 matrices can
naturally be created with the tuple syntax.

```erlang
M = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0}.
```

To access the elements of a 3x3 matrix, use the `element/3` function with a
1-based row and column. Use `row/2` and `column/2` to extract a whole row or
column, and `from_rows/3` or `from_columns/3` to build a matrix from vectors.

```erlang
1.0 = matrix3:element(M, 1, 1).
3.0 = matrix3:element(M, 3, 1).
7.0 = matrix3:element(M, 1, 3).
```

A 3x3 matrix where all the elements are set to zero is called a zero matrix,
which can be conveniently created with the `zero/0` function. A 3x3 matrix with
1.0 on the diagonal and 0.0 elsewhere is called an identity matrix, which can
be conveniently created with the `identity/0` function.

```erlang
{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = matrix3:zero().
{1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = matrix3:identity().
```

Macros are also defined to represent the zero and identity 3x3 matrices. (The
`graphics.hrl` header must be included.)

```erlang
{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = ?MATRIX3_ZERO.
{1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = ?MATRIX3_IDENTITY.
```

The common mathematical operations are also implemented. `multiply/2` is the
matrix product. `scale/2` multiplies every element by a scalar. To transform a
2D point, use `multiply_vector/2`.
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
    multiply_vector/2,
    scale/2,
    divide/2
]).
-export([
    is_equal_to/2, is_equal_to/3
]).
-export([
    to_matrix4/1
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-define(EPSILON, 1.0e-6).
-define(SINGULAR_EPSILON, 1.0e-10).

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
Check whether a 3x3 matrix is zero.

It returns `true` when every element is zero. The values `+0.0` and `-0.0` are
treated as equal.
""".
-spec is_zero(graphics:matrix3()) -> boolean().
is_zero(Matrix) ->
    is_equal_to(Matrix, zero()).

-doc """
The identity 3x3 matrix.

It constructs a 3x3 identity matrix.

```erlang
{1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = matrix3:identity().
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
Check whether a 3x3 matrix is the identity.

It returns `true` when the matrix equals the identity matrix within 1.0e-6.
""".
-spec is_identity(graphics:matrix3()) -> boolean().
is_identity(Matrix) ->
    is_equal_to(Matrix, identity(), ?EPSILON).

-doc """
Create a 3x3 matrix from rows.

It constructs a 3x3 matrix from three row vectors. The first argument is the
top row.
""".
-spec from_rows(graphics:vector3(), graphics:vector3(), graphics:vector3()) ->
    graphics:matrix3().
from_rows(Row1, Row2, Row3) ->
    {
        element(1, Row1), element(1, Row2), element(1, Row3),
        element(2, Row1), element(2, Row2), element(2, Row3),
        element(3, Row1), element(3, Row2), element(3, Row3)
    }.

-doc """
Create a 3x3 matrix from columns.

It constructs a 3x3 matrix from three column vectors. The first argument is the
left column.
""".
-spec from_columns(graphics:vector3(), graphics:vector3(), graphics:vector3()) ->
    graphics:matrix3().
from_columns(Column1, Column2, Column3) ->
    {
        element(1, Column1), element(2, Column1), element(3, Column1),
        element(1, Column2), element(2, Column2), element(3, Column2),
        element(1, Column3), element(2, Column3), element(3, Column3)
    }.

-doc """
An element of a 3x3 matrix.

It returns the element at the given 1-based row and column.
""".
-spec element(graphics:matrix3(), 1..3, 1..3) -> float().
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
A row of a 3x3 matrix.

It returns the row at the given 1-based index as a 3D vector.
""".
-spec row(graphics:matrix3(), 1..3) -> graphics:vector3().
row(Matrix, Index) ->
    case Index of
        1 -> {element(1, Matrix), element(4, Matrix), element(7, Matrix)};
        2 -> {element(2, Matrix), element(5, Matrix), element(8, Matrix)};
        3 -> {element(3, Matrix), element(6, Matrix), element(9, Matrix)}
    end.

-doc """
A column of a 3x3 matrix.

It returns the column at the given 1-based index as a 3D vector.
""".
-spec column(graphics:matrix3(), 1..3) -> graphics:vector3().
column(Matrix, Index) ->
    case Index of
        1 -> {element(1, Matrix), element(2, Matrix), element(3, Matrix)};
        2 -> {element(4, Matrix), element(5, Matrix), element(6, Matrix)};
        3 -> {element(7, Matrix), element(8, Matrix), element(9, Matrix)}
    end.

-doc """
The rows of a 3x3 matrix.

It returns the three row vectors of the 3x3 matrix as a tuple, from top to
bottom.
""".
-spec rows(graphics:matrix3()) ->
    {graphics:vector3(), graphics:vector3(), graphics:vector3()}.
rows(Matrix) ->
    {row(Matrix, 1), row(Matrix, 2), row(Matrix, 3)}.

-doc """
The columns of a 3x3 matrix.

It returns the three column vectors of the 3x3 matrix as a tuple, from left to
right.
""".
-spec columns(graphics:matrix3()) ->
    {graphics:vector3(), graphics:vector3(), graphics:vector3()}.
columns(Matrix) ->
    {column(Matrix, 1), column(Matrix, 2), column(Matrix, 3)}.

-doc """
Transpose a 3x3 matrix.

It returns the transpose of a 3x3 matrix: rows become columns and columns
become rows.
""".
-spec transpose(graphics:matrix3()) -> graphics:matrix3().
transpose(Matrix) ->
    {
        element(1, Matrix), element(4, Matrix), element(7, Matrix),
        element(2, Matrix), element(5, Matrix), element(8, Matrix),
        element(3, Matrix), element(6, Matrix), element(9, Matrix)
    }.

-doc """
Invert a 3x3 matrix.

It returns `{ok, Inverse}` when the 3x3 matrix is invertible, and
`{error, singular}` when `abs(det) < 1.0e-10`.
""".
-spec inverse(graphics:matrix3()) -> {ok, graphics:matrix3()} | {error, singular}.
inverse(Matrix) ->
    Det = determinant(Matrix),
    case erlang:abs(Det) < ?SINGULAR_EPSILON of
        true ->
            {error, singular};
        false ->
            C11 = element(5, Matrix) * element(9, Matrix) - element(6, Matrix) * element(8, Matrix),
            C12 = -(element(4, Matrix) * element(9, Matrix) - element(6, Matrix) * element(7, Matrix)),
            C13 = element(4, Matrix) * element(8, Matrix) - element(5, Matrix) * element(7, Matrix),

            C21 = -(element(2, Matrix) * element(9, Matrix) - element(3, Matrix) * element(8, Matrix)),
            C22 = element(1, Matrix) * element(9, Matrix) - element(3, Matrix) * element(7, Matrix),
            C23 = -(element(1, Matrix) * element(8, Matrix) - element(2, Matrix) * element(7, Matrix)),

            C31 = element(2, Matrix) * element(6, Matrix) - element(3, Matrix) * element(5, Matrix),
            C32 = -(element(1, Matrix) * element(6, Matrix) - element(3, Matrix) * element(4, Matrix)),
            C33 = element(1, Matrix) * element(5, Matrix) - element(2, Matrix) * element(4, Matrix),

            InvDet = 1.0 / Det,
            {ok, {
                C11 * InvDet, C21 * InvDet, C31 * InvDet,
                C12 * InvDet, C22 * InvDet, C32 * InvDet,
                C13 * InvDet, C23 * InvDet, C33 * InvDet
            }}
    end.

-doc """
Compute the determinant of a 3x3 matrix.

It computes the determinant of a 3x3 matrix.
""".
-spec determinant(graphics:matrix3()) -> float().
determinant(Matrix) ->
    element(Matrix, 1, 1) * (element(Matrix, 2, 2) * element(Matrix, 3, 3) - element(Matrix, 2, 3) * element(Matrix, 3, 2)) -
    element(Matrix, 1, 2) * (element(Matrix, 2, 1) * element(Matrix, 3, 3) - element(Matrix, 2, 3) * element(Matrix, 3, 1)) +
    element(Matrix, 1, 3) * (element(Matrix, 2, 1) * element(Matrix, 3, 2) - element(Matrix, 2, 2) * element(Matrix, 3, 1)).

-doc """
Check whether a 3x3 matrix is orthogonal.

It returns `true` when `transpose(M) * M` equals the identity matrix within
1.0e-6.
""".
-spec is_orthogonal(graphics:matrix3()) -> boolean().
is_orthogonal(Matrix) ->
    is_equal_to(multiply(transpose(Matrix), Matrix), identity(), ?EPSILON).

-doc """
Check whether a 3x3 matrix is symmetric.

It returns `true` when the matrix equals its transpose within 1.0e-6.
""".
-spec is_symmetric(graphics:matrix3()) -> boolean().
is_symmetric(Matrix) ->
    is_equal_to(Matrix, transpose(Matrix), ?EPSILON).

-doc """
Add a 3x3 matrix to another 3x3 matrix.

It adds the corresponding elements of two 3x3 matrices.
""".
-spec add(graphics:matrix3(), graphics:matrix3()) -> graphics:matrix3().
add(
    {A11, A21, A31, A12, A22, A32, A13, A23, A33},
    {B11, B21, B31, B12, B22, B32, B13, B23, B33}
) ->
    {
        A11 + B11, A21 + B21, A31 + B31,
        A12 + B12, A22 + B22, A32 + B32,
        A13 + B13, A23 + B23, A33 + B33
    }.

-doc """
Subtract a 3x3 matrix from another 3x3 matrix.

It subtracts the corresponding elements of the second 3x3 matrix from the
first.
""".
-spec subtract(graphics:matrix3(), graphics:matrix3()) -> graphics:matrix3().
subtract(
    {A11, A21, A31, A12, A22, A32, A13, A23, A33},
    {B11, B21, B31, B12, B22, B32, B13, B23, B33}
) ->
    {
        A11 - B11, A21 - B21, A31 - B31,
        A12 - B12, A22 - B22, A32 - B32,
        A13 - B13, A23 - B23, A33 - B33
    }.

-doc """
Multiply two 3x3 matrices.

It computes the matrix product of two 3x3 matrices. If the first matrix is
denoted A and the second is B, it does `A * B`. The operation is not
commutative.
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
Multiply a 3x3 matrix by a 2D point.

It transforms a 2D point by a 3x3 matrix. The point is treated as a homogeneous
vector `{X, Y, 1.0}`. If the resulting W component is not 1.0, the XY result is
divided by W.

To transform a direction (`W = 0.0`), use `transform2:transform_direction/2`.
""".
-spec multiply_vector(graphics:matrix3(), graphics:vector2()) ->
    graphics:vector2().
multiply_vector({M11, M21, M31, M12, M22, M32, M13, M23, M33}, {X, Y}) ->
    X2 = M11 * X + M12 * Y + M13,
    Y2 = M21 * X + M22 * Y + M23,
    W2 = M31 * X + M32 * Y + M33,
    case W2 of
        1.0 ->
            {X2, Y2};
        _ ->
            {X2 / W2, Y2 / W2}
    end.

-doc """
Scale a 3x3 matrix by a scalar.

It multiplies every element of a 3x3 matrix by a scalar.
""".
-spec scale(graphics:matrix3(), float()) -> graphics:matrix3().
scale({M11, M21, M31, M12, M22, M32, M13, M23, M33}, Scalar) ->
    {
        M11 * Scalar, M21 * Scalar, M31 * Scalar,
        M12 * Scalar, M22 * Scalar, M32 * Scalar,
        M13 * Scalar, M23 * Scalar, M33 * Scalar
    }.

-doc """
Divide a 3x3 matrix by a scalar.

It divides every element of a 3x3 matrix by a scalar. Dividing by zero yields
IEEE `inf` or `NaN`.
""".
-spec divide(graphics:matrix3(), float()) -> graphics:matrix3().
divide(Matrix, Divider) ->
    scale(Matrix, 1.0 / Divider).

-doc """
Check whether two 3x3 matrices are equal.

It returns `true` when every pair of corresponding elements compares equal. The
values `+0.0` and `-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:matrix3(), graphics:matrix3()) -> boolean().
is_equal_to(
    {A11, A21, A31, A12, A22, A32, A13, A23, A33},
    {B11, B21, B31, B12, B22, B32, B13, B23, B33}
) ->
    A11 == B11 andalso A21 == B21 andalso A31 == B31
        andalso A12 == B12 andalso A22 == B22 andalso A32 == B32
        andalso A13 == B13 andalso A23 == B23 andalso A33 == B33.

-doc """
Check whether two 3x3 matrices are equal within an epsilon.

It returns `true` when each pair of corresponding elements differs by at most
`Epsilon`.
""".
-spec is_equal_to(graphics:matrix3(), graphics:matrix3(), float()) ->
    boolean().
is_equal_to(
    {A11, A21, A31, A12, A22, A32, A13, A23, A33},
    {B11, B21, B31, B12, B22, B32, B13, B23, B33},
    Epsilon
) ->
    erlang:abs(A11 - B11) =< Epsilon
        andalso erlang:abs(A21 - B21) =< Epsilon
        andalso erlang:abs(A31 - B31) =< Epsilon
        andalso erlang:abs(A12 - B12) =< Epsilon
        andalso erlang:abs(A22 - B22) =< Epsilon
        andalso erlang:abs(A32 - B32) =< Epsilon
        andalso erlang:abs(A13 - B13) =< Epsilon
        andalso erlang:abs(A23 - B23) =< Epsilon
        andalso erlang:abs(A33 - B33) =< Epsilon.

-doc """
Embed a 3x3 matrix in a 4x4 matrix.

It embeds a 3x3 matrix into the XY affine block of a 4x4 matrix. The Z column
and row become the identity axis.

`to_matrix3(to_matrix4(M))` returns `M`.
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
Linearly interpolate two 3x3 matrices.

It interpolates corresponding elements from the first 3x3 matrix to the second
using `T`. This is component-wise interpolation, not rigid-transform
interpolation. `T` is not clamped.
""".
-spec lerp(graphics:matrix3(), graphics:matrix3(), float()) -> graphics:matrix3().
lerp(Matrix1, Matrix2, T) ->
    add(Matrix1, scale(subtract(Matrix2, Matrix1), T)).

-doc """
Smoothly interpolate two 3x3 matrices.

It interpolates corresponding elements using the Hermite smoothstep
`T * T * (3.0 - 2.0 * T)`, then `lerp/3`. `T` is not clamped.
""".
-spec smooth_lerp(graphics:matrix3(), graphics:matrix3(), float()) ->
    graphics:matrix3().
smooth_lerp(Matrix1, Matrix2, T) ->
    lerp(Matrix1, Matrix2, T * T * (3.0 - 2.0 * T)).
