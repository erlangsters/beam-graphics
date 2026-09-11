%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(view2_test).
-include_lib("eunit/include/eunit.hrl").

-define(EPS, 1.0e-6).

view2_orthographic_identity_test() ->
    M = view2:orthographic(-1.0, 1.0, -1.0, 1.0),
    true = matrix3:is_identity(M),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {0.5, -0.25}),
        {0.5, -0.25},
        ?EPS
    ),
    ok.

view2_orthographic_pixel_test() ->
    W = 800.0,
    H = 600.0,
    M = view2:orthographic(0.0, W, 0.0, H),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {0.0, 0.0}),
        {-1.0, -1.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {W, H}),
        {1.0, 1.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {W / 2.0, H / 2.0}),
        {0.0, 0.0},
        ?EPS
    ),
    ok.

view2_orthographic_y_down_test() ->
    W = 800.0,
    H = 600.0,
    M = view2:orthographic(0.0, W, H, 0.0),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {0.0, 0.0}),
        {-1.0, 1.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {W, H}),
        {1.0, -1.0},
        ?EPS
    ),
    ok.

view2_orthographic_box_test() ->
    Box = {{0.0, 0.0}, {800.0, 600.0}},
    {MinX, MinY} = box2:min(Box),
    {MaxX, MaxY} = box2:max(Box),
    true = matrix3:is_equal_to(
        view2:orthographic(Box),
        view2:orthographic(MinX, MaxX, MinY, MaxY),
        ?EPS
    ),
    ok.

view2_orthographic_center_size_test() ->
    Box = box2:from_center_size({0.0, 0.0}, {32.0, 18.0}),
    M = view2:orthographic(Box),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {-16.0, -9.0}),
        {-1.0, -1.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {16.0, 9.0}),
        {1.0, 1.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        matrix3:multiply_vector(M, {0.0, 0.0}),
        {0.0, 0.0},
        ?EPS
    ),
    ok.
