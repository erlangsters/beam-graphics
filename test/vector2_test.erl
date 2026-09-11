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

-define(EPS, 1.0e-6).

vector2_test() ->
    V = {1.0, 2.0},
    1.0 = vector2:x(V),
    2.0 = vector2:y(V),
    ok.

vector2_zero_test() ->
    {0.0, 0.0} = vector2:zero(),
    {0.0, 0.0} = ?VECTOR2_ZERO,
    ok.

vector2_is_zero_test() ->
    true = vector2:is_zero(vector2:zero()),
    true = vector2:is_zero(?VECTOR2_ZERO),
    false = vector2:is_zero({1.0, 0.0}),
    false = vector2:is_zero({0.0, 1.0}),
    false = vector2:is_zero({1.0, 1.0}),
    true = vector2:is_zero({+0.0, +0.0}),
    true = vector2:is_zero({-0.0, -0.0}),
    true = vector2:is_zero({+0.0, -0.0}),
    true = vector2:is_zero({-0.0, +0.0}),
    ok.

vector2_is_unit_test() ->
    true = vector2:is_unit({1.0, 0.0}),
    true = vector2:is_unit({0.0, -1.0}),
    true = vector2:is_unit(vector2:normalize({3.0, 4.0})),
    false = vector2:is_unit({0.0, 0.0}),
    false = vector2:is_unit({2.0, 0.0}),
    ok.

vector2_length_test() ->
    5.0 = vector2:length({3.0, 4.0}),
    0.0 = vector2:length(vector2:zero()),
    ok.

vector2_length_squared_test() ->
    25.0 = vector2:length_squared({3.0, 4.0}),
    0.0 = vector2:length_squared(vector2:zero()),
    ok.

vector2_normalize_test() ->
    {0.6, 0.8} = vector2:normalize({3.0, 4.0}),
    ok.

vector2_perpendicular_test() ->
    {-4.0, 3.0} = vector2:perpendicular({3.0, 4.0}),
    true = vector2:is_equal_to(vector2:perpendicular({1.0, 0.0}), {0.0, 1.0}),
    ok.

vector2_dot_product_test() ->
    11.0 = vector2:dot_product({1.0, 2.0}, {3.0, 4.0}),
    ok.

vector2_cross_product_test() ->
    -2.0 = vector2:cross_product({1.0, 2.0}, {3.0, 4.0}),
    1.0 = vector2:cross_product({1.0, 0.0}, {0.0, 1.0}),
    ok.

vector2_distance_test() ->
    5.0 = vector2:distance({0.0, 0.0}, {3.0, 4.0}),
    5.0 = vector2:distance({1.0, 1.0}, {4.0, 5.0}),
    ok.

vector2_distance_squared_test() ->
    25.0 = vector2:distance_squared({0.0, 0.0}, {3.0, 4.0}),
    ok.

vector2_direction_test() ->
    {0.6, 0.8} = vector2:direction({0.0, 0.0}, {3.0, 4.0}),
    {-1.0, 0.0} = vector2:direction({1.0, 0.0}, {0.0, 0.0}),
    ok.

vector2_angle_test() ->
    true = erlang:abs(vector2:angle({1.0, 0.0}, {0.0, 1.0}) - ?ANGLE_90) =< ?EPS,
    true = erlang:abs(vector2:angle({0.0, 1.0}, {1.0, 0.0}) + ?ANGLE_90) =< ?EPS,
    true = erlang:abs(vector2:angle({1.0, 0.0}, {1.0, 0.0})) =< ?EPS,
    ok.

vector2_project_test() ->
    {3.0, 0.0} = vector2:project({3.0, 4.0}, {1.0, 0.0}),
    {0.0, 4.0} = vector2:project({3.0, 4.0}, {0.0, 2.0}),
    {0.0, 0.0} = vector2:project({1.0, 0.0}, {0.0, 1.0}),
    ok.

vector2_rotate_test() ->
    true = vector2:is_equal_to(vector2:rotate({1.0, 0.0}, ?ANGLE_90), {0.0, 1.0}, ?EPS),
    true = vector2:is_equal_to(vector2:rotate({0.0, 1.0}, ?ANGLE_90), {-1.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(vector2:rotate({1.0, 0.0}, 0.0), {1.0, 0.0}, ?EPS),
    ok.

vector2_reflect_test() ->
    {1.0, 1.0} = vector2:reflect({1.0, -1.0}, {0.0, 1.0}),
    {-1.0, 1.0} = vector2:reflect({1.0, 1.0}, {1.0, 0.0}),
    ok.

vector2_clamp_length_test() ->
    {3.0, 4.0} = vector2:clamp_length({3.0, 4.0}, 0.0, 10.0),
    true = vector2:is_equal_to(
        vector2:clamp_length({3.0, 4.0}, 0.0, 1.0),
        {0.6, 0.8},
        ?EPS
    ),
    {6.0, 8.0} = vector2:clamp_length({3.0, 4.0}, 10.0, 20.0),
    {0.0, 0.0} = vector2:clamp_length({0.0, 0.0}, 1.0, 2.0),
    ok.

vector2_add_test() ->
    {4.0, 6.0} = vector2:add({1.0, 2.0}, {3.0, 4.0}),
    ok.

vector2_subtract_test() ->
    {-1.0, 1.0} = vector2:subtract({1.0, 2.0}, {2.0, 1.0}),
    ok.

vector2_multiply_test() ->
    {2.0, 4.0} = vector2:multiply({1.0, 2.0}, 2.0),
    ok.

vector2_divide_test() ->
    {0.5, 1.0} = vector2:divide({1.0, 2.0}, 2.0),
    ok.

vector2_negate_test() ->
    {-1.0, 2.0} = vector2:negate({1.0, -2.0}),
    ok.

vector2_is_equal_to_test() ->
    true = vector2:is_equal_to({1.0, 2.0}, {1.0, 2.0}),
    true = vector2:is_equal_to({+0.0, -0.0}, {-0.0, +0.0}),
    false = vector2:is_equal_to({1.0, 2.0}, {1.0, 2.1}),
    true = vector2:is_equal_to({1.0, 2.0}, {1.0, 2.0000001}, ?EPS),
    false = vector2:is_equal_to({1.0, 2.0}, {1.0, 2.1}, ?EPS),
    ok.

vector2_to_vector3_test() ->
    {1.0, 2.0, 0.0} = vector2:to_vector3({1.0, 2.0}),
    ok.

vector2_min_test() ->
    {1.0, 2.0} = vector2:min({1.0, 4.0}, {3.0, 2.0}),
    ok.

vector2_max_test() ->
    {3.0, 4.0} = vector2:max({1.0, 4.0}, {3.0, 2.0}),
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
    true = erlang:abs(vector2:to_angle({1.0, 0.0})) =< ?EPS,
    true = erlang:abs(vector2:to_angle({0.0, 1.0}) - ?ANGLE_90) =< ?EPS,
    true = erlang:abs(vector2:to_angle({-1.0, 0.0}) - ?ANGLE_180) =< ?EPS,
    0.0 = vector2:to_angle({0.0, 0.0}),
    ok.

vector2_from_angle_test() ->
    true = vector2:is_equal_to(vector2:from_angle(0.0), {1.0, 0.0}, ?EPS),
    true = vector2:is_equal_to(vector2:from_angle(?ANGLE_90), {0.0, 1.0}, ?EPS),
    true = vector2:is_equal_to(
        vector2:from_angle(vector2:to_angle({3.0, 4.0})),
        vector2:normalize({3.0, 4.0}),
        ?EPS
    ),
    ok.

vector2_lerp_test() ->
    {1.0, 2.0} = vector2:lerp({1.0, 2.0}, {5.0, 6.0}, 0.0),
    {5.0, 6.0} = vector2:lerp({1.0, 2.0}, {5.0, 6.0}, 1.0),
    {3.0, 4.0} = vector2:lerp({1.0, 2.0}, {5.0, 6.0}, 0.5),
    {9.0, 10.0} = vector2:lerp({1.0, 2.0}, {5.0, 6.0}, 2.0),
    ok.

vector2_smooth_lerp_test() ->
    {1.0, 2.0} = vector2:smooth_lerp({1.0, 2.0}, {5.0, 6.0}, 0.0),
    {5.0, 6.0} = vector2:smooth_lerp({1.0, 2.0}, {5.0, 6.0}, 1.0),
    {3.0, 4.0} = vector2:smooth_lerp({1.0, 2.0}, {5.0, 6.0}, 0.5),
    Mid = vector2:smooth_lerp({0.0, 0.0}, {10.0, 0.0}, 0.25),
    true = vector2:x(Mid) < 2.5,
    ok.
