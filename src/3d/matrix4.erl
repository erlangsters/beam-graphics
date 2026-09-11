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

> While 4x4 matrices are powerful, manually constructing them for
> transformations can be error-prone. For common 3D operations
> (e.g., translation, rotation, scale), prefer the `transform3` API, which
> constructs 4x4 matrices for those operations.

The data structure of a 4x4 matrix simply is a flat tuple of 16 floats in
column-major order (top-to-bottom, left-to-right). Therefore, 4x4 matrices can
naturally be created with the tuple syntax.

```erlang
M = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0}.
```

To access the elements of a 4x4 matrix, use the `element/3` function with a
1-based row and column. Use `row/2` and `column/2` to extract a whole row or
column, and `from_rows/4` or `from_columns/4` to build a matrix from vectors.

```erlang
1.0 = matrix4:element(M, 1, 1).
4.0 = matrix4:element(M, 4, 1).
13.0 = matrix4:element(M, 1, 4).
```

A 4x4 matrix where all the elements are set to zero is called a zero matrix,
which can be conveniently created with the `zero/0` function. A 4x4 matrix with
1.0 on the diagonal and 0.0 elsewhere is called an identity matrix, which can
be conveniently created with the `identity/0` function.

```erlang
{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = matrix4:zero().
{1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0} = matrix4:identity().
```

Macros are also defined to represent the zero and identity 4x4 matrices. (The
`graphics.hrl` header must be included.)

```erlang
{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = ?MATRIX4_ZERO.
{1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0} = ?MATRIX4_IDENTITY.
```

The common mathematical operations are also implemented. `multiply/2` is the
matrix product. `scale/2` multiplies every element by a scalar. To transform a
3D point, use `multiply_vector/2`.
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
    to_matrix3/1
]).
-export([
    lerp/3,
    smooth_lerp/3
]).

-define(EPSILON, 1.0e-6).
-define(SINGULAR_EPSILON, 1.0e-10).

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
Check whether a 4x4 matrix is zero.

It returns `true` when every element is zero. The values `+0.0` and `-0.0` are
treated as equal.
""".
-spec is_zero(graphics:matrix4()) -> boolean().
is_zero(Matrix) ->
    is_equal_to(Matrix, zero()).

-doc """
The identity 4x4 matrix.

It constructs a 4x4 identity matrix.

```erlang
{1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0} =
    matrix4:identity().
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
Check whether a 4x4 matrix is the identity.

It returns `true` when the matrix equals the identity matrix within 1.0e-6.
""".
-spec is_identity(graphics:matrix4()) -> boolean().
is_identity(Matrix) ->
    is_equal_to(Matrix, identity(), ?EPSILON).

-doc """
Create a 4x4 matrix from rows.

It constructs a 4x4 matrix from four row vectors. The first argument is the
top row.
""".
-spec from_rows(graphics:vector4(), graphics:vector4(), graphics:vector4(), graphics:vector4()) ->
    graphics:matrix4().
from_rows(Row1, Row2, Row3, Row4) ->
    {
        element(1, Row1), element(1, Row2), element(1, Row3), element(1, Row4),
        element(2, Row1), element(2, Row2), element(2, Row3), element(2, Row4),
        element(3, Row1), element(3, Row2), element(3, Row3), element(3, Row4),
        element(4, Row1), element(4, Row2), element(4, Row3), element(4, Row4)
    }.

-doc """
Create a 4x4 matrix from columns.

It constructs a 4x4 matrix from four column vectors. The first argument is the
left column.
""".
-spec from_columns(graphics:vector4(), graphics:vector4(), graphics:vector4(), graphics:vector4()) ->
    graphics:matrix4().
from_columns(Column1, Column2, Column3, Column4) ->
    {
        element(1, Column1), element(2, Column1), element(3, Column1), element(4, Column1),
        element(1, Column2), element(2, Column2), element(3, Column2), element(4, Column2),
        element(1, Column3), element(2, Column3), element(3, Column3), element(4, Column3),
        element(1, Column4), element(2, Column4), element(3, Column4), element(4, Column4)
    }.

-doc """
An element of a 4x4 matrix.

It returns the element at the given 1-based row and column.
""".
-spec element(graphics:matrix4(), 1..4, 1..4) -> float().
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
A row of a 4x4 matrix.

It returns the row at the given 1-based index as a 4-tuple.
""".
-spec row(graphics:matrix4(), 1..4) -> graphics:vector4().
row(Matrix, Row) ->
    case Row of
        1 -> {element(1, Matrix), element(5, Matrix), element(9, Matrix), element(13, Matrix)};
        2 -> {element(2, Matrix), element(6, Matrix), element(10, Matrix), element(14, Matrix)};
        3 -> {element(3, Matrix), element(7, Matrix), element(11, Matrix), element(15, Matrix)};
        4 -> {element(4, Matrix), element(8, Matrix), element(12, Matrix), element(16, Matrix)}
    end.

-doc """
A column of a 4x4 matrix.

It returns the column at the given 1-based index as a 4-tuple.
""".
-spec column(graphics:matrix4(), 1..4) -> graphics:vector4().
column(Matrix, Column) ->
    case Column of
        1 -> {element(1, Matrix), element(2, Matrix), element(3, Matrix), element(4, Matrix)};
        2 -> {element(5, Matrix), element(6, Matrix), element(7, Matrix), element(8, Matrix)};
        3 -> {element(9, Matrix), element(10, Matrix), element(11, Matrix), element(12, Matrix)};
        4 -> {element(13, Matrix), element(14, Matrix), element(15, Matrix), element(16, Matrix)}
    end.

-doc """
The rows of a 4x4 matrix.

It returns the four row vectors of the 4x4 matrix as a tuple, from top to
bottom.
""".
-spec rows(graphics:matrix4()) ->
    {graphics:vector4(), graphics:vector4(), graphics:vector4(), graphics:vector4()}.
rows(Matrix) ->
    {row(Matrix, 1), row(Matrix, 2), row(Matrix, 3), row(Matrix, 4)}.

-doc """
The columns of a 4x4 matrix.

It returns the four column vectors of the 4x4 matrix as a tuple, from left to
right.
""".
-spec columns(graphics:matrix4()) ->
    {graphics:vector4(), graphics:vector4(), graphics:vector4(), graphics:vector4()}.
columns(Matrix) ->
    {column(Matrix, 1), column(Matrix, 2), column(Matrix, 3), column(Matrix, 4)}.

-doc """
Transpose a 4x4 matrix.

It returns the transpose of a 4x4 matrix: rows become columns and columns
become rows.
""".
-spec transpose(graphics:matrix4()) -> graphics:matrix4().
transpose(Matrix) ->
    {
        element(1, Matrix), element(5, Matrix), element(9, Matrix), element(13, Matrix),
        element(2, Matrix), element(6, Matrix), element(10, Matrix), element(14, Matrix),
        element(3, Matrix), element(7, Matrix), element(11, Matrix), element(15, Matrix),
        element(4, Matrix), element(8, Matrix), element(12, Matrix), element(16, Matrix)
    }.

-doc """
Invert a 4x4 matrix.

It returns `{ok, Inverse}` when the 4x4 matrix is invertible, and
`{error, singular}` when `abs(det) < 1.0e-10`.
""".
-spec inverse(graphics:matrix4()) -> {ok, graphics:matrix4()} | {error, singular}.
inverse({
    M11, M21, M31, M41,
    M12, M22, M32, M42,
    M13, M23, M33, M43,
    M14, M24, M34, M44
}) ->
    C11 = det3(M22, M23, M24, M32, M33, M34, M42, M43, M44),
    C12 = -det3(M21, M23, M24, M31, M33, M34, M41, M43, M44),
    C13 = det3(M21, M22, M24, M31, M32, M34, M41, M42, M44),
    C14 = -det3(M21, M22, M23, M31, M32, M33, M41, M42, M43),
    C21 = -det3(M12, M13, M14, M32, M33, M34, M42, M43, M44),
    C22 = det3(M11, M13, M14, M31, M33, M34, M41, M43, M44),
    C23 = -det3(M11, M12, M14, M31, M32, M34, M41, M42, M44),
    C24 = det3(M11, M12, M13, M31, M32, M33, M41, M42, M43),
    C31 = det3(M12, M13, M14, M22, M23, M24, M42, M43, M44),
    C32 = -det3(M11, M13, M14, M21, M23, M24, M41, M43, M44),
    C33 = det3(M11, M12, M14, M21, M22, M24, M41, M42, M44),
    C34 = -det3(M11, M12, M13, M21, M22, M23, M41, M42, M43),
    C41 = -det3(M12, M13, M14, M22, M23, M24, M32, M33, M34),
    C42 = det3(M11, M13, M14, M21, M23, M24, M31, M33, M34),
    C43 = -det3(M11, M12, M14, M21, M22, M24, M31, M32, M34),
    C44 = det3(M11, M12, M13, M21, M22, M23, M31, M32, M33),
    Det = M11 * C11 + M12 * C12 + M13 * C13 + M14 * C14,
    case erlang:abs(Det) < ?SINGULAR_EPSILON of
        true ->
            {error, singular};
        false ->
            InvDet = 1.0 / Det,
            {ok, {
                C11 * InvDet, C12 * InvDet, C13 * InvDet, C14 * InvDet,
                C21 * InvDet, C22 * InvDet, C23 * InvDet, C24 * InvDet,
                C31 * InvDet, C32 * InvDet, C33 * InvDet, C34 * InvDet,
                C41 * InvDet, C42 * InvDet, C43 * InvDet, C44 * InvDet
            }}
    end.

-doc """
Compute the determinant of a 4x4 matrix.

It computes the determinant of a 4x4 matrix.
""".
-spec determinant(graphics:matrix4()) -> float().
determinant({
    M11, M21, M31, M41,
    M12, M22, M32, M42,
    M13, M23, M33, M43,
    M14, M24, M34, M44
}) ->
    M11 * det3(M22, M23, M24, M32, M33, M34, M42, M43, M44) -
    M12 * det3(M21, M23, M24, M31, M33, M34, M41, M43, M44) +
    M13 * det3(M21, M22, M24, M31, M32, M34, M41, M42, M44) -
    M14 * det3(M21, M22, M23, M31, M32, M33, M41, M42, M43).

-doc """
Check whether a 4x4 matrix is orthogonal.

It returns `true` when `transpose(M) * M` equals the identity matrix within
1.0e-6.
""".
-spec is_orthogonal(graphics:matrix4()) -> boolean().
is_orthogonal(Matrix) ->
    is_equal_to(multiply(transpose(Matrix), Matrix), identity(), ?EPSILON).

-doc """
Check whether a 4x4 matrix is symmetric.

It returns `true` when the matrix equals its transpose within 1.0e-6.
""".
-spec is_symmetric(graphics:matrix4()) -> boolean().
is_symmetric(Matrix) ->
    is_equal_to(Matrix, transpose(Matrix), ?EPSILON).

-doc """
Add a 4x4 matrix to another 4x4 matrix.

It adds the corresponding elements of two 4x4 matrices.
""".
-spec add(graphics:matrix4(), graphics:matrix4()) -> graphics:matrix4().
add(
    {A11, A21, A31, A41, A12, A22, A32, A42, A13, A23, A33, A43, A14, A24, A34, A44},
    {B11, B21, B31, B41, B12, B22, B32, B42, B13, B23, B33, B43, B14, B24, B34, B44}
) ->
    {
        A11 + B11, A21 + B21, A31 + B31, A41 + B41,
        A12 + B12, A22 + B22, A32 + B32, A42 + B42,
        A13 + B13, A23 + B23, A33 + B33, A43 + B43,
        A14 + B14, A24 + B24, A34 + B34, A44 + B44
    }.

-doc """
Subtract a 4x4 matrix from another 4x4 matrix.

It subtracts the corresponding elements of the second 4x4 matrix from the
first.
""".
-spec subtract(graphics:matrix4(), graphics:matrix4()) -> graphics:matrix4().
subtract(
    {A11, A21, A31, A41, A12, A22, A32, A42, A13, A23, A33, A43, A14, A24, A34, A44},
    {B11, B21, B31, B41, B12, B22, B32, B42, B13, B23, B33, B43, B14, B24, B34, B44}
) ->
    {
        A11 - B11, A21 - B21, A31 - B31, A41 - B41,
        A12 - B12, A22 - B22, A32 - B32, A42 - B42,
        A13 - B13, A23 - B23, A33 - B33, A43 - B43,
        A14 - B14, A24 - B24, A34 - B34, A44 - B44
    }.

-doc """
Multiply two 4x4 matrices.

It computes the matrix product of two 4x4 matrices. If the first matrix is
denoted A and the second is B, it does `A * B`. The operation is not
commutative.
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
Multiply a 4x4 matrix by a 3D point.

It transforms a 3D point by a 4x4 matrix. The point is treated as a homogeneous
vector `{X, Y, Z, 1.0}`. If the resulting W component is not 1.0, the XYZ
result is divided by W.

To transform a direction (`W = 0.0`), use `transform3:transform_direction/2`.
""".
-spec multiply_vector(graphics:matrix4(), graphics:vector3()) ->
    graphics:vector3().
multiply_vector({
    M11, M21, M31, M41,
    M12, M22, M32, M42,
    M13, M23, M33, M43,
    M14, M24, M34, M44
}, {X, Y, Z}) ->
    X2 = M11 * X + M12 * Y + M13 * Z + M14,
    Y2 = M21 * X + M22 * Y + M23 * Z + M24,
    Z2 = M31 * X + M32 * Y + M33 * Z + M34,
    W2 = M41 * X + M42 * Y + M43 * Z + M44,
    case W2 of
        1.0 ->
            {X2, Y2, Z2};
        _ ->
            {X2 / W2, Y2 / W2, Z2 / W2}
    end.

-doc """
Scale a 4x4 matrix by a scalar.

It multiplies every element of a 4x4 matrix by a scalar.
""".
-spec scale(graphics:matrix4(), float()) -> graphics:matrix4().
scale({
    M11, M21, M31, M41,
    M12, M22, M32, M42,
    M13, M23, M33, M43,
    M14, M24, M34, M44
}, Scalar) ->
    {
        M11 * Scalar, M21 * Scalar, M31 * Scalar, M41 * Scalar,
        M12 * Scalar, M22 * Scalar, M32 * Scalar, M42 * Scalar,
        M13 * Scalar, M23 * Scalar, M33 * Scalar, M43 * Scalar,
        M14 * Scalar, M24 * Scalar, M34 * Scalar, M44 * Scalar
    }.

-doc """
Divide a 4x4 matrix by a scalar.

It divides every element of a 4x4 matrix by a scalar. Dividing by zero yields
IEEE `inf` or `NaN`.
""".
-spec divide(graphics:matrix4(), float()) -> graphics:matrix4().
divide(Matrix, Divider) ->
    scale(Matrix, 1.0 / Divider).

-doc """
Check whether two 4x4 matrices are equal.

It returns `true` when every pair of corresponding elements compares equal. The
values `+0.0` and `-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:matrix4(), graphics:matrix4()) -> boolean().
is_equal_to(
    {A11, A21, A31, A41, A12, A22, A32, A42, A13, A23, A33, A43, A14, A24, A34, A44},
    {B11, B21, B31, B41, B12, B22, B32, B42, B13, B23, B33, B43, B14, B24, B34, B44}
) ->
    A11 == B11 andalso A21 == B21 andalso A31 == B31 andalso A41 == B41
        andalso A12 == B12 andalso A22 == B22 andalso A32 == B32 andalso A42 == B42
        andalso A13 == B13 andalso A23 == B23 andalso A33 == B33 andalso A43 == B43
        andalso A14 == B14 andalso A24 == B24 andalso A34 == B34 andalso A44 == B44.

-doc """
Check whether two 4x4 matrices are equal within an epsilon.

It returns `true` when each pair of corresponding elements differs by at most
`Epsilon`.
""".
-spec is_equal_to(graphics:matrix4(), graphics:matrix4(), float()) ->
    boolean().
is_equal_to(
    {A11, A21, A31, A41, A12, A22, A32, A42, A13, A23, A33, A43, A14, A24, A34, A44},
    {B11, B21, B31, B41, B12, B22, B32, B42, B13, B23, B33, B43, B14, B24, B34, B44},
    Epsilon
) ->
    erlang:abs(A11 - B11) =< Epsilon
        andalso erlang:abs(A21 - B21) =< Epsilon
        andalso erlang:abs(A31 - B31) =< Epsilon
        andalso erlang:abs(A41 - B41) =< Epsilon
        andalso erlang:abs(A12 - B12) =< Epsilon
        andalso erlang:abs(A22 - B22) =< Epsilon
        andalso erlang:abs(A32 - B32) =< Epsilon
        andalso erlang:abs(A42 - B42) =< Epsilon
        andalso erlang:abs(A13 - B13) =< Epsilon
        andalso erlang:abs(A23 - B23) =< Epsilon
        andalso erlang:abs(A33 - B33) =< Epsilon
        andalso erlang:abs(A43 - B43) =< Epsilon
        andalso erlang:abs(A14 - B14) =< Epsilon
        andalso erlang:abs(A24 - B24) =< Epsilon
        andalso erlang:abs(A34 - B34) =< Epsilon
        andalso erlang:abs(A44 - B44) =< Epsilon.

-doc """
Extract a 3x3 matrix from a 4x4 matrix.

It extracts the XY affine block of a 4x4 matrix. This is the inverse of
`matrix3:to_matrix4/1` and is lossless in that direction.
""".
-spec to_matrix3(graphics:matrix4()) -> graphics:matrix3().
to_matrix3({
    M11, M21, _M31, M41,
    M12, M22, _M32, M42,
    _M13, _M23, _M33, _M43,
    M14, M24, _M34, M44
}) ->
    {
        M11, M21, M41,
        M12, M22, M42,
        M14, M24, M44
    }.

-doc """
Linearly interpolate two 4x4 matrices.

It interpolates corresponding elements from the first 4x4 matrix to the second
using `T`. This is component-wise interpolation, not rigid-transform
interpolation. `T` is not clamped.
""".
-spec lerp(graphics:matrix4(), graphics:matrix4(), float()) -> graphics:matrix4().
lerp(Matrix1, Matrix2, T) ->
    add(Matrix1, scale(subtract(Matrix2, Matrix1), T)).

-doc """
Smoothly interpolate two 4x4 matrices.

It interpolates corresponding elements using the Hermite smoothstep
`T * T * (3.0 - 2.0 * T)`, then `lerp/3`. `T` is not clamped.
""".
-spec smooth_lerp(graphics:matrix4(), graphics:matrix4(), float()) ->
    graphics:matrix4().
smooth_lerp(Matrix1, Matrix2, T) ->
    lerp(Matrix1, Matrix2, T * T * (3.0 - 2.0 * T)).

det3(A11, A12, A13, A21, A22, A23, A31, A32, A33) ->
    A11 * (A22 * A33 - A23 * A32) -
    A12 * (A21 * A33 - A23 * A31) +
    A13 * (A21 * A32 - A22 * A31).
