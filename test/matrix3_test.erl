%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(matrix3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

matrix3_test() ->
    Matrix = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0},
    1.0 = matrix3:element(Matrix, 1, 1),
    2.0 = matrix3:element(Matrix, 2, 1),
    3.0 = matrix3:element(Matrix, 3, 1),
    4.0 = matrix3:element(Matrix, 1, 2),
    5.0 = matrix3:element(Matrix, 2, 2),
    6.0 = matrix3:element(Matrix, 3, 2),
    7.0 = matrix3:element(Matrix, 1, 3),
    8.0 = matrix3:element(Matrix, 2, 3),
    9.0 = matrix3:element(Matrix, 3, 3),

    {1.0, 4.0, 7.0} = matrix3:row(Matrix, 1),
    {2.0, 5.0, 8.0} = matrix3:row(Matrix, 2),
    {3.0, 6.0, 9.0} = matrix3:row(Matrix, 3),

    {1.0, 2.0, 3.0} = matrix3:column(Matrix, 1),
    {4.0, 5.0, 6.0} = matrix3:column(Matrix, 2),
    {7.0, 8.0, 9.0} = matrix3:column(Matrix, 3),

    {
        {1.0, 4.0, 7.0},
        {2.0, 5.0, 8.0},
        {3.0, 6.0, 9.0}
    } = matrix3:rows(Matrix),

    {
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0},
        {7.0, 8.0, 9.0}
    } = matrix3:columns(Matrix),

    ok.

matrix3_zero_test() ->
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = matrix3:zero(),
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = ?MATRIX3_ZERO,

    ok.

matrix3_identity_test() ->
    {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = matrix3:identity(),
    {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = ?MATRIX3_IDENTITY,

    ok.

matrix3_from_rows_test() ->
    Row1 = {1.0, 2.0, 3.0},
    Row2 = {4.0, 5.0, 6.0},
    Row3 = {7.0, 8.0, 9.0},
    {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0} =
        matrix3:from_rows(Row1, Row2, Row3),

    ok.

matrix3_from_columns_test() ->
    Column1 = {1.0, 2.0, 3.0},
    Column2 = {4.0, 5.0, 6.0},
    Column3 = {7.0, 8.0, 9.0},
    {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0} =
        matrix3:from_columns(Column1, Column2, Column3),

    ok.

matrix3_transpose_test() ->
    Matrix = matrix3:from_rows(
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0},
        {7.0, 8.0, 9.0}
    ),
    TransposeMatrix = matrix3:from_rows(
        {1.0, 4.0, 7.0},
        {2.0, 5.0, 8.0},
        {3.0, 6.0, 9.0}
    ),
    TransposeMatrix = matrix3:transpose(Matrix),

    ok.

matrix3_inverse_test() ->
    % IdentityMatrix = matrix3:identity(),
    % ?MATRIX3_IDENTITY = matrix3:inverse(IdentityMatrix),

    % ScaleMatrix = matrix3:from_rows(
    %     {2.0, 0.0, 0.0},
    %     {0.0, 3.0, 0.0},
    %     {0.0, 0.0, 4.0}
    % ),
    % InverseScaleMatrix = matrix3:from_rows(
    %     {0.5, 0.0, 0.0},
    %     {0.0, 1.0/3, 0.0},
    %     {0.0, 0.0, 0.25}
    % ),
    % InverseScaleMatrix = matrix3:inverse(ScaleMatrix),

% Purpose: Test diagonal matrix inversion (should reciprocate diagonal entries).
% 3. Rotation Matrix (Inverse = Transpose)
% erlang

% % 90° rotation matrix (transpose = inverse)
% Matrix = [[ 0, 1, 0],
%           [-1, 0, 0],
%           [ 0, 0, 1]],
% Expected = [[0, -1, 0],  % Transpose of original
%             [1,  0, 0],
%             [0,  0, 1]],
% {ok, Result} = matrix3:inverse(Matrix),
% assert_matrix_approx_equal(Expected, Result, 1e-10).

% Purpose: Orthogonal matrices (rotations) satisfy
% inverse(M) = transpose(M).
% 4. Translation Matrix (Inverse = Negative Translation)
% erlang

% Matrix = [[1, 0, 5],   % Translate by (5, 10)
%           [0, 1, 10],
%           [0, 0, 1]],
% Expected = [[1, 0, -5],
%             [0, 1, -10],
%             [0, 0, 1]],
% {ok, Result} = matrix3:inverse(Matrix),
% assert_matrix_approx_equal(Expected, Result, 1e-10).

% Purpose: Verify translation inversion.
% 5. Singular Matrix (Non-Invertible)
% erlang

% Matrix = [[1, 2, 3],
%           [4, 5, 6],
%           [7, 8, 9]],  % Rows are linearly dependent
% {error, singular} = matrix3:inverse(Matrix).

% Purpose: Ensure singular matrices are detected.
% 6. Random Invertible Matrix
% erlang

% Matrix = [[1, 2, 3],
%           [0, 4, 5],
%           [0, 0, 6]],
% Expected = [[1, -0.5, -0.08333],
%             [0,  0.25, -0.20833],
%             [0,  0,     0.16666]],
% {ok, Result} = matrix3:inverse(Matrix),
% assert_matrix_approx_equal(Expected, Result, 1e-5).  % Lower precision for manual calc

% Purpose: Test non-trivial inversion.
% 7. Numerical Stability (Near-Singular)
% erlang

% Matrix = [[1, 0, 0],
%           [0, 1, 0],
%           [0, 0, 1e-10]],  # Almost singular
% {ok, Result} = matrix3:inverse(Matrix),
% Expected = [[1, 0, 0],
%             [0, 1, 0],
%             [0, 0, 1e+10]],
% assert_matrix_approx_equal(Expected, Result, 1e-5).

% Purpose: Check handling of floating-point extremes.
    ok.

matrix3_determinant_test() ->
    IdentityMatrix = matrix3:identity(),
    1.0 = matrix3:determinant(IdentityMatrix),

    SingularMatrix = matrix3:from_rows(
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0},
        {7.0, 8.0, 9.0}
    ),
    0.0 = matrix3:determinant(SingularMatrix),

    ScaleMatrix = matrix3:from_rows(
        {2.0, 0.0, 0.0},
        {0.0, 3.0, 0.0},
        {0.0, 0.0, 4.0}
    ),
    24.0 = matrix3:determinant(ScaleMatrix),

    RotationMatrix = matrix3:from_rows(
        {0.0, 1.0, 0.0},
        {-1.0, 0.0, 0.0},
        {0.0, 0.0, 1.0}
    ),
    1.0 = matrix3:determinant(RotationMatrix),

    RandomInvertibleMatrix = matrix3:from_rows(
        {1.0, 2.0, 3.0},
        {0.0, 4.0, 5.0},
        {0.0, 0.0, 6.0}
    ),
    24.0 = matrix3:determinant(RandomInvertibleMatrix),

    NegativeDeterminantMatrix = matrix3:from_rows(
        {-1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 1.0}
    ),
    -1.0 = matrix3:determinant(NegativeDeterminantMatrix),

    PrecisionCheckMatrix = matrix3:from_rows(
        {1.0, 1.0000001, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 1.0}
    ),
    1.0 = matrix3:determinant(PrecisionCheckMatrix),

    ok.

matrix3_is_orthogonal_test() ->
    % XXX

    ok.

matrix3_is_symmetric_test() ->
    % XXX

    ok.

matrix3_add_test() ->
    % XXX

    ok.

matrix3_subtract_test() ->
    % XXX

    ok.

matrix3_multiply_test() ->
    Matrix1 = matrix3:from_rows(
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0},
        {7.0, 8.0, 9.0}
    ),
    Matrix2 = matrix3:from_rows(
        {9.0, 8.0, 7.0},
        {6.0, 5.0, 4.0},
        {3.0, 2.0, 1.0}
    ),

    Result1 = matrix3:from_rows(
        {30.0, 24.0, 18.0},
        {84.0, 69.0, 54.0},
        {138.0, 114.0, 90.0}
    ),
    Result2 = matrix3:from_rows(
        {90.0, 114.0, 138.0},
        {54.0, 69.0, 84.0},
        {18.0, 24.0, 30.0}
    ),
    Result1 = matrix3:multiply(Matrix1, Matrix2),
    Result2 = matrix3:multiply(Matrix2, Matrix1),

    ok.

matrix3_multiply_vector_test() ->
    % XXX

    ok.

matrix3_is_equal_to_test() ->
    % XXX

    ok.

matrix3_to_matrix4_test() ->
    ok.

matrix3_lerp_test() ->
    % XXX

    ok.

matrix3_smooth_lerp_test() ->
    % XXX

    ok.
