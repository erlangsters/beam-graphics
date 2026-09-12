%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_matrix3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

matrix3_test() ->
    Matrix = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0},
    1.0 = graphics_matrix3:element(Matrix, 1, 1),
    2.0 = graphics_matrix3:element(Matrix, 2, 1),
    3.0 = graphics_matrix3:element(Matrix, 3, 1),
    4.0 = graphics_matrix3:element(Matrix, 1, 2),
    5.0 = graphics_matrix3:element(Matrix, 2, 2),
    6.0 = graphics_matrix3:element(Matrix, 3, 2),
    7.0 = graphics_matrix3:element(Matrix, 1, 3),
    8.0 = graphics_matrix3:element(Matrix, 2, 3),
    9.0 = graphics_matrix3:element(Matrix, 3, 3),
    {1.0, 4.0, 7.0} = graphics_matrix3:row(Matrix, 1),
    {2.0, 5.0, 8.0} = graphics_matrix3:row(Matrix, 2),
    {3.0, 6.0, 9.0} = graphics_matrix3:row(Matrix, 3),
    {1.0, 2.0, 3.0} = graphics_matrix3:column(Matrix, 1),
    {4.0, 5.0, 6.0} = graphics_matrix3:column(Matrix, 2),
    {7.0, 8.0, 9.0} = graphics_matrix3:column(Matrix, 3),
    {
        {1.0, 4.0, 7.0},
        {2.0, 5.0, 8.0},
        {3.0, 6.0, 9.0}
    } = graphics_matrix3:rows(Matrix),
    {
        {1.0, 2.0, 3.0},
        {4.0, 5.0, 6.0},
        {7.0, 8.0, 9.0}
    } = graphics_matrix3:columns(Matrix),
    ok.

matrix3_zero_test() ->
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = graphics_matrix3:zero(),
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} = ?MATRIX3_ZERO,
    true = graphics_matrix3:is_zero(graphics_matrix3:zero()),
    true = graphics_matrix3:is_zero({+0.0, -0.0, +0.0, -0.0, +0.0, -0.0, +0.0, -0.0, +0.0}),
    false = graphics_matrix3:is_zero(graphics_matrix3:identity()),
    ok.

matrix3_identity_test() ->
    {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = graphics_matrix3:identity(),
    {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0} = ?MATRIX3_IDENTITY,
    true = graphics_matrix3:is_identity(graphics_matrix3:identity()),
    false = graphics_matrix3:is_identity(graphics_matrix3:zero()),
    ok.

matrix3_from_rows_test() ->
    {1.0, 4.0, 7.0, 2.0, 5.0, 8.0, 3.0, 6.0, 9.0} =
        graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    ok.

matrix3_from_columns_test() ->
    {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0} =
        graphics_matrix3:from_columns({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    ok.

matrix3_transpose_test() ->
    Matrix = graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    Transpose = graphics_matrix3:from_rows({1.0, 4.0, 7.0}, {2.0, 5.0, 8.0}, {3.0, 6.0, 9.0}),
    Transpose = graphics_matrix3:transpose(Matrix),
    ok.

matrix3_inverse_test() ->
    {ok, Identity} = graphics_matrix3:inverse(graphics_matrix3:identity()),
    true = graphics_matrix3:is_equal_to(Identity, graphics_matrix3:identity(), ?EPS),
    Scale = graphics_matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 4.0}),
    {ok, InverseScale} = graphics_matrix3:inverse(Scale),
    true = graphics_matrix3:is_equal_to(
        InverseScale,
        graphics_matrix3:from_rows({0.5, 0.0, 0.0}, {0.0, 1.0 / 3.0, 0.0}, {0.0, 0.0, 0.25}),
        ?EPS
    ),
    Rotation = graphics_matrix3:from_rows({0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0}),
    {ok, InverseRotation} = graphics_matrix3:inverse(Rotation),
    true = graphics_matrix3:is_equal_to(InverseRotation, graphics_matrix3:transpose(Rotation), ?EPS),
    Translation = graphics_matrix3:from_rows({1.0, 0.0, 5.0}, {0.0, 1.0, 10.0}, {0.0, 0.0, 1.0}),
    {ok, InverseTranslation} = graphics_matrix3:inverse(Translation),
    true = graphics_matrix3:is_equal_to(
        InverseTranslation,
        graphics_matrix3:from_rows({1.0, 0.0, -5.0}, {0.0, 1.0, -10.0}, {0.0, 0.0, 1.0}),
        ?EPS
    ),
    Upper = graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {0.0, 4.0, 5.0}, {0.0, 0.0, 6.0}),
    {ok, InverseUpper} = graphics_matrix3:inverse(Upper),
    true = graphics_matrix3:is_equal_to(
        graphics_matrix3:multiply(Upper, InverseUpper),
        graphics_matrix3:identity(),
        ?EPS
    ),
    {error, singular} = graphics_matrix3:inverse(
        graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0})
    ),
    ok.

matrix3_determinant_test() ->
    1.0 = graphics_matrix3:determinant(graphics_matrix3:identity()),
    0.0 = graphics_matrix3:determinant(graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0})),
    24.0 = graphics_matrix3:determinant(graphics_matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 4.0})),
    1.0 = graphics_matrix3:determinant(graphics_matrix3:from_rows({0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0})),
    24.0 = graphics_matrix3:determinant(graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {0.0, 4.0, 5.0}, {0.0, 0.0, 6.0})),
    -1.0 = graphics_matrix3:determinant(graphics_matrix3:from_rows({-1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0})),
    ok.

matrix3_is_orthogonal_test() ->
    true = graphics_matrix3:is_orthogonal(graphics_matrix3:identity()),
    true = graphics_matrix3:is_orthogonal(graphics_matrix3:from_rows({0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0})),
    false = graphics_matrix3:is_orthogonal(graphics_matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 4.0})),
    ok.

matrix3_is_symmetric_test() ->
    true = graphics_matrix3:is_symmetric(graphics_matrix3:identity()),
    true = graphics_matrix3:is_symmetric(graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {2.0, 4.0, 5.0}, {3.0, 5.0, 6.0})),
    false = graphics_matrix3:is_symmetric(graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {0.0, 4.0, 5.0}, {0.0, 0.0, 6.0})),
    ok.

matrix3_add_test() ->
    Sum = graphics_matrix3:add(
        graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
        graphics_matrix3:from_rows({9.0, 8.0, 7.0}, {6.0, 5.0, 4.0}, {3.0, 2.0, 1.0})
    ),
    Expected = graphics_matrix3:from_rows({10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}),
    Expected = Sum,
    ok.

matrix3_subtract_test() ->
    Difference = graphics_matrix3:subtract(
        graphics_matrix3:from_rows({9.0, 8.0, 7.0}, {6.0, 5.0, 4.0}, {3.0, 2.0, 1.0}),
        graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0})
    ),
    Expected = graphics_matrix3:from_rows({8.0, 6.0, 4.0}, {2.0, 0.0, -2.0}, {-4.0, -6.0, -8.0}),
    Expected = Difference,
    ok.

matrix3_multiply_test() ->
    Matrix1 = graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    Matrix2 = graphics_matrix3:from_rows({9.0, 8.0, 7.0}, {6.0, 5.0, 4.0}, {3.0, 2.0, 1.0}),
    Result1 = graphics_matrix3:from_rows({30.0, 24.0, 18.0}, {84.0, 69.0, 54.0}, {138.0, 114.0, 90.0}),
    Result2 = graphics_matrix3:from_rows({90.0, 114.0, 138.0}, {54.0, 69.0, 84.0}, {18.0, 24.0, 30.0}),
    Result1 = graphics_matrix3:multiply(Matrix1, Matrix2),
    Result2 = graphics_matrix3:multiply(Matrix2, Matrix1),
    ok.

matrix3_multiply_vector_test() ->
    {3.0, 4.0} = graphics_matrix3:multiply_vector(graphics_matrix3:identity(), {3.0, 4.0}),
    Translation = graphics_matrix3:from_rows({1.0, 0.0, 5.0}, {0.0, 1.0, 10.0}, {0.0, 0.0, 1.0}),
    {8.0, 14.0} = graphics_matrix3:multiply_vector(Translation, {3.0, 4.0}),
    Scale = graphics_matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 3.0, 0.0}, {0.0, 0.0, 1.0}),
    {6.0, 12.0} = graphics_matrix3:multiply_vector(Scale, {3.0, 4.0}),
    Homography = graphics_matrix3:from_rows({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 2.0}),
    {0.5, 1.0} = graphics_matrix3:multiply_vector(Homography, {1.0, 2.0}),
    ok.

matrix3_scale_test() ->
    Scaled = graphics_matrix3:scale(
        graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
        2.0
    ),
    Expected = graphics_matrix3:from_rows({2.0, 4.0, 6.0}, {8.0, 10.0, 12.0}, {14.0, 16.0, 18.0}),
    Expected = Scaled,
    ok.

matrix3_divide_test() ->
    Divided = graphics_matrix3:divide(
        graphics_matrix3:from_rows({2.0, 4.0, 6.0}, {8.0, 10.0, 12.0}, {14.0, 16.0, 18.0}),
        2.0
    ),
    Expected = graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    Expected = Divided,
    ok.

matrix3_is_equal_to_test() ->
    M = graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    true = graphics_matrix3:is_equal_to(M, M),
    false = graphics_matrix3:is_equal_to(M, graphics_matrix3:identity()),
    true = graphics_matrix3:is_equal_to(M, graphics_matrix3:add(M, graphics_matrix3:scale(graphics_matrix3:identity(), 1.0e-7)), ?EPS),
    ok.

matrix3_to_matrix4_test() ->
    M3 = graphics_matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    M4 = graphics_matrix3:to_matrix4(M3),
    M3 = graphics_matrix4:to_matrix3(M4),
    1.0 = graphics_matrix4:element(M4, 1, 1),
    5.0 = graphics_matrix4:element(M4, 2, 2),
    1.0 = graphics_matrix4:element(M4, 3, 3),
    9.0 = graphics_matrix4:element(M4, 4, 4),
    0.0 = graphics_matrix4:element(M4, 3, 1),
    0.0 = graphics_matrix4:element(M4, 1, 3),
    ok.

matrix3_lerp_test() ->
    A = graphics_matrix3:zero(),
    B = graphics_matrix3:from_rows({2.0, 0.0, 0.0}, {0.0, 4.0, 0.0}, {0.0, 0.0, 6.0}),
    A = graphics_matrix3:lerp(A, B, 0.0),
    B = graphics_matrix3:lerp(A, B, 1.0),
    Half = graphics_matrix3:from_rows({1.0, 0.0, 0.0}, {0.0, 2.0, 0.0}, {0.0, 0.0, 3.0}),
    Half = graphics_matrix3:lerp(A, B, 0.5),
    ok.

matrix3_smooth_lerp_test() ->
    A = graphics_matrix3:zero(),
    B = graphics_matrix3:from_rows({10.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}),
    A = graphics_matrix3:smooth_lerp(A, B, 0.0),
    B = graphics_matrix3:smooth_lerp(A, B, 1.0),
    Mid = graphics_matrix3:smooth_lerp(A, B, 0.25),
    true = graphics_matrix3:element(Mid, 1, 1) < 2.5,
    ok.
