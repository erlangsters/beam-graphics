%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(vector2_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

vector2_test() ->
    V = {1.0, 2.0},
    1.0 = vector2:x(V),
    2.0 = vector2:y(V),

    ok.

vector2_zero_test() ->
    {0.0, 0.0} = vector2:zero(),
    {0.0, 0.0} = ?VECTOR2_ZERO,

    ok.

vector2_length_test() ->
    V = {3.0, 4.0},
    5.0 = vector2:length(V),

    ok.

vector2_normalize_test() ->
    V = {3.0, 4.0},
    {0.6, 0.8} = vector2:normalize(V),

    ok.

vector2_perpendicular_test() ->
    % XXX

    ok.

vector2_dot_product_test() ->
    V1 = {1.0, 2.0},
    V2 = {3.0, 4.0},
    11.0 = vector2:dot_product(V1, V2),

    ok.

vector2_cross_product_test() ->
    V1 = {1.0, 2.0},
    V2 = {3.0, 4.0},
    -2.0 = vector2:cross_product(V1, V2),

    ok.

vector2_distance_test() ->
    % XXX

    ok.

vector2_direction_test() ->
    % XXX

    ok.

vector2_project_test() ->
    % XXX

    ok.

vector2_rotate_test() ->
    % XXX

    ok.

vector2_reflect_test() ->
    % XXX

    ok.

vector2_clamp_length_test() ->
    % XXX

    ok.

vector2_add_test() ->
    V1 = {1.0, 2.0},
    V2 = {3.0, 4.0},
    {4.0, 6.0} = vector2:add(V1, V2),

    ok.

vector2_subtract_test() ->
    V1 = {1.0, 2.0},
    V2 = {2.0, 1.0},
    {-1.0, 1.0} = vector2:subtract(V1, V2),

    ok.

vector2_multiply_test() ->
    V = {1.0, 2.0},
    {2.0, 4.0} = vector2:multiply(V, 2.0),

    ok.

vector2_to_vector3_test() ->
    V = {1.0, 2.0},
    {1.0, 2.0, 0.0} = vector2:to_vector3(V),

    ok.

vector2_min_test() ->
    V1 = {1.0, 4.0},
    V2 = {3.0, 2.0},
    {1.0, 2.0} = vector2:min(V1, V2),

    ok.

vector2_max_test() ->
    V1 = {1.0, 4.0},
    V2 = {3.0, 2.0},
    {3.0, 4.0} = vector2:max(V1, V2),

    ok.

vector2_abs_test() ->
    {1.0, 2.0} = vector2:abs({-1.0, 2.0}),
    {1.0, 2.0} = vector2:abs({1.0, -2.0}),

    ok.

vector2_floor_test() ->
    {2.0, 2.0} = vector2:floor({2.4, 2.6}),

    ok.

vector2_ceil_test() ->
    {3.0, 3.0} = vector2:ceil({2.4, 2.6}),

    ok.

vector2_round_test() ->
    {2.0, 3.0} = vector2:round({2.4, 2.6}),

    ok.

vector2_to_angle_test() ->
    % XXX

    ok.

vector2_from_angle_test() ->
    % XXX

    ok.

vector2_lerp_test() ->
    % XXX

    ok.

vector2_smooth_lerp_test() ->
    % XXX

    ok.
