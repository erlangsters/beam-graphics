%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(matrix4_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

matrix4_test() ->
    Matrix = {
        1.0, 2.0, 3.0, 4.0,
        5.0, 6.0, 7.0, 8.0,
        9.0, 10.0, 11.0, 12.0,
        13.0, 14.0, 15.0, 16.0
    },
    1.0 = matrix4:element(Matrix, 1, 1),
    2.0 = matrix4:element(Matrix, 2, 1),
    3.0 = matrix4:element(Matrix, 3, 1),
    4.0 = matrix4:element(Matrix, 4, 1),
    5.0 = matrix4:element(Matrix, 1, 2),
    6.0 = matrix4:element(Matrix, 2, 2),
    7.0 = matrix4:element(Matrix, 3, 2),
    8.0 = matrix4:element(Matrix, 4, 2),
    9.0 = matrix4:element(Matrix, 1, 3),
    10.0 = matrix4:element(Matrix, 2, 3),
    11.0 = matrix4:element(Matrix, 3, 3),
    12.0 = matrix4:element(Matrix, 4, 3),
    13.0 = matrix4:element(Matrix, 1, 4),
    14.0 = matrix4:element(Matrix, 2, 4),
    15.0 = matrix4:element(Matrix, 3, 4),
    16.0 = matrix4:element(Matrix, 4, 4),

    {1.0, 5.0, 9.0, 13.0} = matrix4:row(Matrix, 1),
    {2.0, 6.0, 10.0, 14.0} = matrix4:row(Matrix, 2),
    {3.0, 7.0, 11.0, 15.0} = matrix4:row(Matrix, 3),
    {4.0, 8.0, 12.0, 16.0} = matrix4:row(Matrix, 4),

    {1.0, 2.0, 3.0, 4.0} = matrix4:column(Matrix, 1),
    {5.0, 6.0, 7.0, 8.0} = matrix4:column(Matrix, 2),
    {9.0, 10.0, 11.0, 12.0} = matrix4:column(Matrix, 3),
    {13.0, 14.0, 15.0, 16.0} = matrix4:column(Matrix, 4),

    {
        {1.0, 5.0, 9.0, 13.0},
        {2.0, 6.0, 10.0, 14.0},
        {3.0, 7.0, 11.0, 15.0},
        {4.0, 8.0, 12.0, 16.0}
    } = matrix4:rows(Matrix),

    {
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    } = matrix4:columns(Matrix),

    ok.

matrix4_zero_test() ->
    {
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0
    } = matrix4:zero(),
    {
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0
    } = ?MATRIX4_ZERO,

    ok.

matrix4_identity_test() ->
    {
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    } = matrix4:identity(),
    {
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    } = ?MATRIX4_IDENTITY,

    ok.

matrix4_from_rows_test() ->
    Row1 = {1.0, 2.0, 3.0, 4.0},
    Row2 = {5.0, 6.0, 7.0, 8.0},
    Row3 = {9.0, 10.0, 11.0, 12.0},
    Row4 = {13.0, 14.0, 15.0, 16.0},
    {
        1.0, 5.0, 9.0, 13.0,
        2.0, 6.0, 10.0, 14.0,
        3.0, 7.0, 11.0, 15.0,
        4.0, 8.0, 12.0, 16.0
    } = matrix4:from_rows(Row1, Row2, Row3, Row4),

    ok.

matrix4_from_columns_test() ->
    Column1 = {1.0, 2.0, 3.0, 4.0},
    Column2 = {5.0, 6.0, 7.0, 8.0},
    Column3 = {9.0, 10.0, 11.0, 12.0},
    Column4 = {13.0, 14.0, 15.0, 16.0},
    {
        1.0, 2.0, 3.0, 4.0,
        5.0, 6.0, 7.0, 8.0,
        9.0, 10.0, 11.0, 12.0,
        13.0, 14.0, 15.0, 16.0
    } = matrix4:from_columns(Column1, Column2, Column3, Column4),

    ok.

matrix4_transpose_test() ->
    Matrix = matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    ),
    TransposeMatrix = matrix4:from_rows(
        {1.0, 5.0, 9.0, 13.0},
        {2.0, 6.0, 10.0, 14.0},
        {3.0, 7.0, 11.0, 15.0},
        {4.0, 8.0, 12.0, 16.0}
    ),
    TransposeMatrix = matrix4:transpose(Matrix),

    ok.

matrix4_inverse_test() ->

    ok.

matrix4_determinant_test() ->
    % matrix4_determinanttest

    % 1. Identity Matrix (Determinant = 1)
    % erlang

    % Matrix = [[1, 0, 0, 0],
    %           [0, 1, 0, 0],
    %           [0, 0, 1, 0],
    %           [0, 0, 0, 1]],
    % Determinant = 1.0.

    % Purpose: Verify the base case (identity matrix has determinant 1).
    % 2. Singular Matrix (Determinant = 0)
    % erlang

    % Matrix = [[1, 2, 3, 4],
    %           [5, 6, 7, 8],
    %           [9, 10, 11, 12],
    %           [13, 14, 15, 16]],  % Rows are linearly dependent (Row4 = Row1 + Row2 + Row3)
    % Determinant = 0.0.

    % Purpose: Test zero-determinant (non-invertible matrix).
    % 3. Scaling Matrix (Determinant = Product of Diagonals)
    % erlang

    % Matrix = [[2, 0, 0, 0],
    %           [0, 3, 0, 0],
    %           [0, 0, 4, 0],
    %           [0, 0, 0, 5]],
    % Determinant = 120.0.  % 2 * 3 * 4 * 5

    % Purpose: Diagonal matrices have trivial determinants.
    % 4. Rotation Matrix (Determinant = 1)
    % erlang

    % % 90-degree rotation around Z-axis (cos(90°)=0, sin(90°)=1)
    % Matrix = [[ 0, 1, 0, 0],
    %           [-1, 0, 0, 0],
    %           [ 0, 0, 1, 0],
    %           [ 0, 0, 0, 1]],
    % Determinant = 1.0.  % Rotations preserve volume (det = 1)

    % Purpose: Orthogonal matrices (e.g., rotations) have determinant ±1.
    % 5. Translation Matrix (Determinant = 1)
    % erlang

    % Matrix = [[1, 0, 0, 5],
    %           [0, 1, 0, 10],
    %           [0, 0, 1, 15],
    %           [0, 0, 0, 1]],
    % Determinant = 1.0.  % Translations do not affect volume

    % Purpose: Affine transformations (with last row [0,0,0,1]) preserve determinant.
    % 6. Negative Determinant (Reflection)
    % erlang

    % Matrix = [[-1, 0, 0, 0],
    %           [ 0, 1, 0, 0],
    %           [ 0, 0, 1, 0],
    %           [ 0, 0, 0, 1]],
    % Determinant = -1.0.  % Reflection flips orientation

    % Purpose: Verify sign handling.
    % 7. Random Invertible Matrix
    % erlang

    % Matrix = [[1, 2, 3, 4],
    %           [0, 5, 6, 7],
    %           [0, 0, 8, 9],
    %           [0, 0, 0, 10]],
    % Determinant = 400.0.  % Upper triangular: 1 * 5 * 8 * 10

    % Purpose: Test non-trivial but computable case.
    % 8. Precision Check (Floating-Point)
    % erlang

    % Matrix = [[1.0, 0.0, 0.0, 0.0],
    %           [0.0, 1.0, 0.0, 0.0],
    %           [0.0, 0.0, 1.0, 0.0],
    %           [0.0, 0.0, 1e-8, 1.0]],
    % Determinant ≈ 1.0.  % Almost-identity matrix

    % Purpose: Ensure floating-point stability (use abs(Result - Expected) < EPSILON).
    ok.

matrix4_add_test() ->
    % XXX

    ok.

matrix4_subtract_test() ->
    % XXX

    ok.

matrix4_multiply_test() ->
    Matrix1 = matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    ),
    Matrix2 = matrix4:from_rows(
        {16.0, 15.0, 14.0, 13.0},
        {12.0, 11.0, 10.0, 9.0},
        {8.0, 7.0, 6.0, 5.0},
        {4.0, 3.0, 2.0, 1.0}
    ),

    Result1 = matrix4:from_rows(
        {80.0, 70.0, 60.0, 50.0},
        {240.0, 214.0, 188.0, 162.0},
        {400.0, 358.0, 316.0, 274.0},
        {560.0, 502.0, 444.0, 386.0}
    ),
    Result2 = matrix4:from_rows(
        {386.0, 444.0, 502.0, 560.0},
        {274.0, 316.0, 358.0, 400.0},
        {162.0, 188.0, 214.0, 240.0},
        {50.0, 60.0, 70.0, 80.0}
    ),
    Result1 = matrix4:multiply(Matrix1, Matrix2),
    Result2 = matrix4:multiply(Matrix2, Matrix1),

    ok.

matrix4_multiply_vector_test() ->
    % XXX

    ok.

matrix4_to_matrix3_test() ->
    ok.

matrix4_lerp_test() ->
    % XXX

    ok.

matrix4_smooth_lerp_test() ->
    % XXX

    ok.
