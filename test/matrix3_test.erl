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

-define(EPS, 1.0e-6).

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
    true = matrix3:is_zero(matrix3:zero()),
    true = matrix3:is_zero({+0.0, -0.0, +0.0, -0.0, +0.0, -0.0, +0.0, -0.0, +0.0}),
    false = matrix3:is_zero(matrix3:identity()),
    ok.

matrix3_identity_test() ->
    {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = matrix3:identity(),
    {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = ?MATRIX3_IDENTITY,
    true = matrix3:is_identity(matrix3:identity()),
    false = matrix3:is_identity(matrix3:zero()),
    ok.

matrix3_from_rows_test() ->
    {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0} =
        matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    ok.

matrix3_from_columns_test() ->
    {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0} =
        matrix3:from_columns({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    ok.

matrix3_transpose_test() ->
    Matrix = matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    Transpose = matrix3:from_rows({1.0, 4.0, 7.0}, {2.0, 5.0, 8.0}, {3.0, 6.0, 9.0}),
    Transpose = matrix3:transpose(Matrix),
    ok.

matrix3_inverse_test() ->
    {ok, Identity} = matrix3:inverse(matrix3:identity()),
    true = matrix3:is_equal_to(Identity, matrix3:identity(), ?EPS),
    Scale = matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 4.0}),
    {ok, InverseScale} = matrix3:inverse(Scale),
    true = matrix3:is_equal_to(
        InverseScale,
        matrix3:from_rows({0.5, 0.0, 0.0}, {0.0, 1.0 / 3.0, 0.0}, {0.0, 0.0, 0.25}),
        ?EPS
    ),
    Rotation = matrix3:from_rows({0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0}),
    {ok, InverseRotation} = matrix3:inverse(Rotation),
    true = matrix3:is_equal_to(InverseRotation, matrix3:transpose(Rotation), ?EPS),
    Translation = matrix3:from_rows({1.0, 0.0, 5.0}, {0.0, 1.0, 10.0}, {0.0, 0.0, 1.0}),
    {ok, InverseTranslation} = matrix3:inverse(Translation),
    true = matrix3:is_equal_to(
        InverseTranslation,
        matrix3:from_rows({1.0, 0.0, -5.0}, {0.0, 1.0, -10.0}, {0.0, 0.0, 1.0}),
        ?EPS
    ),
    Upper = matrix3:from_rows({1.0, 2.0, 3.0}, {0.0, 4.0, 5.0}, {0.0, 0.0, 6.0}),
    {ok, InverseUpper} = matrix3:inverse(Upper),
    true = matrix3:is_equal_to(
        matrix3:multiply(Upper, InverseUpper),
        matrix3:identity(),
        ?EPS
    ),
    {error, singular} = matrix3:inverse(
        matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0})
    ),
    ok.

matrix3_determinant_test() ->
    1.0 = matrix3:determinant(matrix3:identity()),
    0.0 = matrix3:determinant(matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0})),
    24.0 = matrix3:determinant(matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 4.0})),
    1.0 = matrix3:determinant(matrix3:from_rows({0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0})),
    24.0 = matrix3:determinant(matrix3:from_rows({1.0, 2.0, 3.0}, {0.0, 4.0, 5.0}, {0.0, 0.0, 6.0})),
    -1.0 = matrix3:determinant(matrix3:from_rows({-1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0})),
    ok.

matrix3_is_orthogonal_test() ->
    true = matrix3:is_orthogonal(matrix3:identity()),
    true = matrix3:is_orthogonal(matrix3:from_rows({0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0})),
    false = matrix3:is_orthogonal(matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 4.0})),
    ok.

matrix3_is_symmetric_test() ->
    true = matrix3:is_symmetric(matrix3:identity()),
    true = matrix3:is_symmetric(matrix3:from_rows({1.0, 2.0, 3.0}, {2.0, 4.0, 5.0}, {3.0, 5.0, 6.0})),
    false = matrix3:is_symmetric(matrix3:from_rows({1.0, 2.0, 3.0}, {0.0, 4.0, 5.0}, {0.0, 0.0, 6.0})),
    ok.

matrix3_add_test() ->
    Sum = matrix3:add(
        matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
        matrix3:from_rows({9.0, 8.0, 7.0}, {6.0, 5.0, 4.0}, {3.0, 2.0, 1.0})
    ),
    Expected = matrix3:from_rows({10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}),
    Expected = Sum,
    ok.

matrix3_subtract_test() ->
    Difference = matrix3:subtract(
        matrix3:from_rows({9.0, 8.0, 7.0}, {6.0, 5.0, 4.0}, {3.0, 2.0, 1.0}),
        matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0})
    ),
    Expected = matrix3:from_rows({8.0, 6.0, 4.0}, {2.0, 0.0, -2.0}, {-4.0, -6.0, -8.0}),
    Expected = Difference,
    ok.

matrix3_multiply_test() ->
    Matrix1 = matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    Matrix2 = matrix3:from_rows({9.0, 8.0, 7.0}, {6.0, 5.0, 4.0}, {3.0, 2.0, 1.0}),
    Result1 = matrix3:from_rows({30.0, 24.0, 18.0}, {84.0, 69.0, 54.0}, {138.0, 114.0, 90.0}),
    Result2 = matrix3:from_rows({90.0, 114.0, 138.0}, {54.0, 69.0, 84.0}, {18.0, 24.0, 30.0}),
    Result1 = matrix3:multiply(Matrix1, Matrix2),
    Result2 = matrix3:multiply(Matrix2, Matrix1),
    ok.

matrix3_multiply_vector_test() ->
    {3.0, 4.0} = matrix3:multiply_vector(matrix3:identity(), {3.0, 4.0}),
    Translation = matrix3:from_rows({1.0, 0.0, 5.0}, {0.0, 1.0, 10.0}, {0.0, 0.0, 1.0}),
    {8.0, 14.0} = matrix3:multiply_vector(Translation, {3.0, 4.0}),
    Scale = matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 1.0}),
    {6.0, 12.0} = matrix3:multiply_vector(Scale, {3.0, 4.0}),
    Homography = matrix3:from_rows({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 2.0}),
    {0.5, 1.0} = matrix3:multiply_vector(Homography, {1.0, 2.0}),
    ok.

matrix3_scale_test() ->
    Scaled = matrix3:scale(
        matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
        2.0
    ),
    Expected = matrix3:from_rows({2.0, 4.0, 6.0}, {8.0, 10.0, 12.0}, {14.0, 16.0, 18.0}),
    Expected = Scaled,
    ok.

matrix3_divide_test() ->
    Divided = matrix3:divide(
        matrix3:from_rows({2.0, 4.0, 6.0}, {8.0, 10.0, 12.0}, {14.0, 16.0, 18.0}),
        2.0
    ),
    Expected = matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    Expected = Divided,
    ok.

matrix3_is_equal_to_test() ->
    M = matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    true = matrix3:is_equal_to(M, M),
    false = matrix3:is_equal_to(M, matrix3:identity()),
    true = matrix3:is_equal_to(M, matrix3:add(M, matrix3:scale(matrix3:identity(), 1.0e-7)), ?EPS),
    ok.

matrix3_to_matrix4_test() ->
    M3 = matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    M4 = matrix3:to_matrix4(M3),
    M3 = matrix4:to_matrix3(M4),
    1.0 = matrix4:element(M4, 1, 1),
    5.0 = matrix4:element(M4, 2, 2),
    1.0 = matrix4:element(M4, 3, 3),
    9.0 = matrix4:element(M4, 4, 4),
    0.0 = matrix4:element(M4, 3, 1),
    0.0 = matrix4:element(M4, 1, 3),
    ok.

matrix3_lerp_test() ->
    A = matrix3:zero(),
    B = matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 4.0, 0.0}, {0.0, 0.0, 6.0}),
    A = matrix3:lerp(A, B, 0.0),
    B = matrix3:lerp(A, B, 1.0),
    Half = matrix3:from_rows({1.0, 0.0, 0.0}, {0.0, 2.0, 0.0}, {0.0, 0.0, 3.0}),
    Half = matrix3:lerp(A, B, 0.5),
    ok.

matrix3_smooth_lerp_test() ->
    A = matrix3:zero(),
    B = matrix3:from_rows({10.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}),
    A = matrix3:smooth_lerp(A, B, 0.0),
    B = matrix3:smooth_lerp(A, B, 1.0),
    Mid = matrix3:smooth_lerp(A, B, 0.25),
    true = matrix3:element(Mid, 1, 1) < 2.5,
    ok.
