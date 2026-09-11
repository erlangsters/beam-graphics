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

-define(EPS, 1.0e-6).

matrix4_test() ->
    Matrix = {
        1.0, 2.0, 3.0, 4.0,
        5.0, 6.0, 7.0, 8.0,
        9.0, 10.0, 11.0, 12.0,
        13.0, 14.0, 15.0, 16.0
    },
    1.0 = matrix4:element(Matrix, 1, 1),
    4.0 = matrix4:element(Matrix, 4, 1),
    5.0 = matrix4:element(Matrix, 1, 2),
    16.0 = matrix4:element(Matrix, 4, 4),
    {1.0, 5.0, 9.0, 13.0} = matrix4:row(Matrix, 1),
    {4.0, 8.0, 12.0, 16.0} = matrix4:row(Matrix, 4),
    {1.0, 2.0, 3.0, 4.0} = matrix4:column(Matrix, 1),
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
    Zero = matrix4:zero(),
    Zero = ?MATRIX4_ZERO,
    true = matrix4:is_zero(Zero),
    false = matrix4:is_zero(matrix4:identity()),
    ok.

matrix4_identity_test() ->
    Identity = matrix4:identity(),
    Identity = ?MATRIX4_IDENTITY,
    true = matrix4:is_identity(Identity),
    false = matrix4:is_identity(matrix4:zero()),
    ok.

matrix4_from_rows_test() ->
    {
        1.0, 5.0, 9.0, 13.0,
        2.0, 6.0, 10.0, 14.0,
        3.0, 7.0, 11.0, 15.0,
        4.0, 8.0, 12.0, 16.0
    } = matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    ),
    ok.

matrix4_from_columns_test() ->
    {
        1.0, 2.0, 3.0, 4.0,
        5.0, 6.0, 7.0, 8.0,
        9.0, 10.0, 11.0, 12.0,
        13.0, 14.0, 15.0, 16.0
    } = matrix4:from_columns(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    ),
    ok.

matrix4_transpose_test() ->
    Matrix = matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    ),
    Transpose = matrix4:from_rows(
        {1.0, 5.0, 9.0, 13.0},
        {2.0, 6.0, 10.0, 14.0},
        {3.0, 7.0, 11.0, 15.0},
        {4.0, 8.0, 12.0, 16.0}
    ),
    Transpose = matrix4:transpose(Matrix),
    ok.

matrix4_inverse_test() ->
    {ok, Identity} = matrix4:inverse(matrix4:identity()),
    true = matrix4:is_equal_to(Identity, matrix4:identity(), ?EPS),
    Scale = matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 3.0, 0.0, 0.0},
        {0.0, 0.0, 4.0, 0.0},
        {0.0, 0.0, 0.0, 5.0}
    ),
    {ok, InverseScale} = matrix4:inverse(Scale),
    true = matrix4:is_equal_to(
        InverseScale,
        matrix4:from_rows(
            {0.5, 0.0, 0.0, 0.0},
            {0.0, 1.0 / 3.0, 0.0, 0.0},
            {0.0, 0.0, 0.25, 0.0},
            {0.0, 0.0, 0.0, 0.2}
        ),
        ?EPS
    ),
    Rotation = matrix4:from_rows(
        {0.0, 1.0, 0.0, 0.0},
        {-1.0, 0.0, 0.0, 0.0},
        {0.0, 0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    ),
    {ok, InverseRotation} = matrix4:inverse(Rotation),
    true = matrix4:is_equal_to(InverseRotation, matrix4:transpose(Rotation), ?EPS),
    Translation = matrix4:from_rows(
        {1.0, 0.0, 0.0, 5.0},
        {0.0, 1.0, 0.0, 10.0},
        {0.0, 0.0, 1.0, 15.0},
        {0.0, 0.0, 0.0, 1.0}
    ),
    {ok, InverseTranslation} = matrix4:inverse(Translation),
    true = matrix4:is_equal_to(
        InverseTranslation,
        matrix4:from_rows(
            {1.0, 0.0, 0.0, -5.0},
            {0.0, 1.0, 0.0, -10.0},
            {0.0, 0.0, 1.0, -15.0},
            {0.0, 0.0, 0.0, 1.0}
        ),
        ?EPS
    ),
    Upper = matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {0.0, 5.0, 6.0, 7.0},
        {0.0, 0.0, 8.0, 9.0},
        {0.0, 0.0, 0.0, 10.0}
    ),
    {ok, InverseUpper} = matrix4:inverse(Upper),
    true = matrix4:is_equal_to(matrix4:multiply(Upper, InverseUpper), matrix4:identity(), ?EPS),
    {error, singular} = matrix4:inverse(matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    )),
    ok.

matrix4_determinant_test() ->
    1.0 = matrix4:determinant(matrix4:identity()),
    0.0 = matrix4:determinant(matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {5.0, 6.0, 7.0, 8.0},
        {9.0, 10.0, 11.0, 12.0},
        {13.0, 14.0, 15.0, 16.0}
    )),
    120.0 = matrix4:determinant(matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 3.0, 0.0, 0.0},
        {0.0, 0.0, 4.0, 0.0},
        {0.0, 0.0, 0.0, 5.0}
    )),
    1.0 = matrix4:determinant(matrix4:from_rows(
        {0.0, 1.0, 0.0, 0.0},
        {-1.0, 0.0, 0.0, 0.0},
        {0.0, 0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    )),
    1.0 = matrix4:determinant(matrix4:from_rows(
        {1.0, 0.0, 0.0, 5.0},
        {0.0, 1.0, 0.0, 10.0},
        {0.0, 0.0, 1.0, 15.0},
        {0.0, 0.0, 0.0, 1.0}
    )),
    -1.0 = matrix4:determinant(matrix4:from_rows(
        {-1.0, 0.0, 0.0, 0.0},
        {0.0, 1.0, 0.0, 0.0},
        {0.0, 0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    )),
    400.0 = matrix4:determinant(matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {0.0, 5.0, 6.0, 7.0},
        {0.0, 0.0, 8.0, 9.0},
        {0.0, 0.0, 0.0, 10.0}
    )),
    ok.

matrix4_is_orthogonal_test() ->
    true = matrix4:is_orthogonal(matrix4:identity()),
    true = matrix4:is_orthogonal(matrix4:from_rows(
        {0.0, 1.0, 0.0, 0.0},
        {-1.0, 0.0, 0.0, 0.0},
        {0.0, 0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    )),
    false = matrix4:is_orthogonal(matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 3.0, 0.0, 0.0},
        {0.0, 0.0, 4.0, 0.0},
        {0.0, 0.0, 0.0, 5.0}
    )),
    ok.

matrix4_is_symmetric_test() ->
    true = matrix4:is_symmetric(matrix4:identity()),
    false = matrix4:is_symmetric(matrix4:from_rows(
        {1.0, 2.0, 3.0, 4.0},
        {0.0, 5.0, 6.0, 7.0},
        {0.0, 0.0, 8.0, 9.0},
        {0.0, 0.0, 0.0, 10.0}
    )),
    ok.

matrix4_add_test() ->
    A = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 2.0, 0.0, 0.0},
        {0.0, 0.0, 3.0, 0.0},
        {0.0, 0.0, 0.0, 4.0}
    ),
    B = matrix4:from_rows(
        {4.0, 0.0, 0.0, 0.0},
        {0.0, 3.0, 0.0, 0.0},
        {0.0, 0.0, 2.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    ),
    Expected = matrix4:from_rows(
        {5.0, 0.0, 0.0, 0.0},
        {0.0, 5.0, 0.0, 0.0},
        {0.0, 0.0, 5.0, 0.0},
        {0.0, 0.0, 0.0, 5.0}
    ),
    Expected = matrix4:add(A, B),
    ok.

matrix4_subtract_test() ->
    A = matrix4:from_rows(
        {5.0, 0.0, 0.0, 0.0},
        {0.0, 5.0, 0.0, 0.0},
        {0.0, 0.0, 5.0, 0.0},
        {0.0, 0.0, 0.0, 5.0}
    ),
    B = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 2.0, 0.0, 0.0},
        {0.0, 0.0, 3.0, 0.0},
        {0.0, 0.0, 0.0, 4.0}
    ),
    Expected = matrix4:from_rows(
        {4.0, 0.0, 0.0, 0.0},
        {0.0, 3.0, 0.0, 0.0},
        {0.0, 0.0, 2.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    ),
    Expected = matrix4:subtract(A, B),
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
    {3.0, 4.0, 5.0} = matrix4:multiply_vector(matrix4:identity(), {3.0, 4.0, 5.0}),
    Translation = matrix4:from_rows(
        {1.0, 0.0, 0.0, 1.0},
        {0.0, 1.0, 0.0, 2.0},
        {0.0, 0.0, 1.0, 3.0},
        {0.0, 0.0, 0.0, 1.0}
    ),
    {4.0, 6.0, 8.0} = matrix4:multiply_vector(Translation, {3.0, 4.0, 5.0}),
    Scale = matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 3.0, 0.0, 0.0},
        {0.0, 0.0, 4.0, 0.0},
        {0.0, 0.0, 0.0, 1.0}
    ),
    {6.0, 12.0, 20.0} = matrix4:multiply_vector(Scale, {3.0, 4.0, 5.0}),
    Perspective = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 1.0, 0.0, 0.0},
        {0.0, 0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0, 2.0}
    ),
    {0.5, 1.0, 1.5} = matrix4:multiply_vector(Perspective, {1.0, 2.0, 3.0}),
    ok.

matrix4_scale_test() ->
    A = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 2.0, 0.0, 0.0},
        {0.0, 0.0, 3.0, 0.0},
        {0.0, 0.0, 0.0, 4.0}
    ),
    Expected = matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 4.0, 0.0, 0.0},
        {0.0, 0.0, 6.0, 0.0},
        {0.0, 0.0, 0.0, 8.0}
    ),
    Expected = matrix4:scale(A, 2.0),
    ok.

matrix4_divide_test() ->
    A = matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 4.0, 0.0, 0.0},
        {0.0, 0.0, 6.0, 0.0},
        {0.0, 0.0, 0.0, 8.0}
    ),
    Expected = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 2.0, 0.0, 0.0},
        {0.0, 0.0, 3.0, 0.0},
        {0.0, 0.0, 0.0, 4.0}
    ),
    Expected = matrix4:divide(A, 2.0),
    ok.

matrix4_is_equal_to_test() ->
    true = matrix4:is_equal_to(matrix4:identity(), matrix4:identity()),
    false = matrix4:is_equal_to(matrix4:identity(), matrix4:zero()),
    true = matrix4:is_equal_to(
        matrix4:identity(),
        matrix4:add(matrix4:identity(), matrix4:scale(matrix4:identity(), 1.0e-7)),
        ?EPS
    ),
    ok.

matrix4_to_matrix3_test() ->
    M3 = matrix3:from_rows({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}),
    M3 = matrix4:to_matrix3(matrix3:to_matrix4(M3)),
    ok.

matrix4_lerp_test() ->
    A = matrix4:zero(),
    B = matrix4:from_rows(
        {2.0, 0.0, 0.0, 0.0},
        {0.0, 4.0, 0.0, 0.0},
        {0.0, 0.0, 6.0, 0.0},
        {0.0, 0.0, 0.0, 8.0}
    ),
    A = matrix4:lerp(A, B, 0.0),
    B = matrix4:lerp(A, B, 1.0),
    Half = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 2.0, 0.0, 0.0},
        {0.0, 0.0, 3.0, 0.0},
        {0.0, 0.0, 0.0, 4.0}
    ),
    Half = matrix4:lerp(A, B, 0.5),
    ok.

matrix4_smooth_lerp_test() ->
    A = matrix4:zero(),
    B = matrix4:from_rows(
        {10.0, 0.0, 0.0, 0.0},
        {0.0, 0.0, 0.0, 0.0},
        {0.0, 0.0, 0.0, 0.0},
        {0.0, 0.0, 0.0, 0.0}
    ),
    A = matrix4:smooth_lerp(A, B, 0.0),
    B = matrix4:smooth_lerp(A, B, 1.0),
    Mid = matrix4:smooth_lerp(A, B, 0.25),
    true = matrix4:element(Mid, 1, 1) < 2.5,
    ok.
