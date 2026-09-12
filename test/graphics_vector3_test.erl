%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_vector3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

vector3_test() ->
    V = {1.0, 2.0, 3.0},
    1.0 = graphics_vector3:x(V),
    2.0 = graphics_vector3:y(V),
    3.0 = graphics_vector3:z(V),
    ok.

vector3_zero_test() ->
    {0.0, 0.0, 0.0} = graphics_vector3:zero(),
    {0.0, 0.0, 0.0} = ?VECTOR3_ZERO,
    ok.

vector3_is_zero_test() ->
    true = graphics_vector3:is_zero(graphics_vector3:zero()),
    true = graphics_vector3:is_zero({+0.0, -0.0, +0.0}),
    false = graphics_vector3:is_zero({1.0, 0.0, 0.0}),
    false = graphics_vector3:is_zero({0.0, 0.0, 1.0}),
    ok.

vector3_is_unit_test() ->
    true = graphics_vector3:is_unit({1.0, 0.0, 0.0}),
    true = graphics_vector3:is_unit(graphics_vector3:normalize({3.0, 4.0, 5.0})),
    false = graphics_vector3:is_unit({0.0, 0.0, 0.0}),
    false = graphics_vector3:is_unit({2.0, 0.0, 0.0}),
    ok.

vector3_length_test() ->
    7.0710678118654755 = graphics_vector3:length({3.0, 4.0, 5.0}),
    ok.

vector3_length_squared_test() ->
    50.0 = graphics_vector3:length_squared({3.0, 4.0, 5.0}),
    ok.

vector3_normalize_test() ->
    {0.4242640687119285, 0.565685424949238, 0.7071067811865475} =
        graphics_vector3:normalize({3.0, 4.0, 5.0}),
    ok.

vector3_dot_product_test() ->
    32.0 = graphics_vector3:dot_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}),
    ok.

vector3_cross_product_test() ->
    {-3.0, 6.0, -3.0} = graphics_vector3:cross_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}),
    {0.0, 0.0, 1.0} = graphics_vector3:cross_product({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}),
    ok.

vector3_distance_test() ->
    5.0 = graphics_vector3:distance({0.0, 0.0, 0.0}, {0.0, 3.0, 4.0}),
    ok.

vector3_distance_squared_test() ->
    25.0 = graphics_vector3:distance_squared({0.0, 0.0, 0.0}, {0.0, 3.0, 4.0}),
    ok.

vector3_direction_test() ->
    {0.0, 0.6, 0.8} = graphics_vector3:direction({0.0, 0.0, 0.0}, {0.0, 3.0, 4.0}),
    ok.

vector3_angle_test() ->
    true = erlang:abs(graphics_vector3:angle({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}) - ?ANGLE_90) =< ?EPS,
    true = erlang:abs(graphics_vector3:angle({1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}) - ?ANGLE_180) =< ?EPS,
    true = erlang:abs(
        graphics_vector3:angle({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}) -
        graphics_vector3:angle({0.0, 1.0, 0.0}, {1.0, 0.0, 0.0})
    ) =< ?EPS,
    true = erlang:abs(graphics_vector3:angle({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}) - ?ANGLE_90) =< ?EPS,
    true = erlang:abs(graphics_vector3:angle({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, -1.0}) + ?ANGLE_90) =< ?EPS,
    ok.

vector3_project_test() ->
    {3.0, 0.0, 0.0} = graphics_vector3:project({3.0, 4.0, 5.0}, {1.0, 0.0, 0.0}),
    {0.0, 0.0, 0.0} = graphics_vector3:project({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}),
    ok.

vector3_rotate_test() ->
    true = graphics_vector3:is_equal_to(
        graphics_vector3:rotate({1.0, 0.0, 0.0}, ?ANGLE_90, {0.0, 0.0, 1.0}),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    true = graphics_vector3:is_equal_to(
        graphics_vector3:rotate({0.0, 1.0, 0.0}, ?ANGLE_90, {1.0, 0.0, 0.0}),
        {0.0, 0.0, 1.0},
        ?EPS
    ),
    ok.

vector3_reflect_test() ->
    {1.0, 1.0, 0.0} = graphics_vector3:reflect({1.0, -1.0, 0.0}, {0.0, 1.0, 0.0}),
    ok.

vector3_clamp_length_test() ->
    {0.0, 3.0, 4.0} = graphics_vector3:clamp_length({0.0, 3.0, 4.0}, 0.0, 10.0),
    true = graphics_vector3:is_equal_to(
        graphics_vector3:clamp_length({0.0, 3.0, 4.0}, 0.0, 1.0),
        {0.0, 0.6, 0.8},
        ?EPS
    ),
    {0.0, 6.0, 8.0} = graphics_vector3:clamp_length({0.0, 3.0, 4.0}, 10.0, 20.0),
    {0.0, 0.0, 0.0} = graphics_vector3:clamp_length({0.0, 0.0, 0.0}, 1.0, 2.0),
    ok.

vector3_add_test() ->
    {5.0, 7.0, 9.0} = graphics_vector3:add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}),
    ok.

vector3_subtract_test() ->
    {-3.0, -3.0, -3.0} = graphics_vector3:subtract({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}),
    ok.

vector3_multiply_test() ->
    {2.0, 4.0, 6.0} = graphics_vector3:multiply({1.0, 2.0, 3.0}, 2.0),
    ok.

vector3_divide_test() ->
    {0.5, 1.0, 1.5} = graphics_vector3:divide({1.0, 2.0, 3.0}, 2.0),
    ok.

vector3_negate_test() ->
    {-1.0, 2.0, -3.0} = graphics_vector3:negate({1.0, -2.0, 3.0}),
    ok.

vector3_is_equal_to_test() ->
    true = graphics_vector3:is_equal_to({1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}),
    true = graphics_vector3:is_equal_to({+0.0, -0.0, +0.0}, {-0.0, +0.0, -0.0}),
    false = graphics_vector3:is_equal_to({1.0, 2.0, 3.0}, {1.0, 2.1, 3.0}),
    true = graphics_vector3:is_equal_to({1.0, 2.0, 3.0}, {1.0, 2.0000001, 3.0}, ?EPS),
    ok.

vector3_to_vector2_test() ->
    {1.0, 2.0} = graphics_vector3:to_vector2({1.0, 2.0, 3.0}),
    ok.

vector3_min_test() ->
    {1.0, 2.0, 3.0} = graphics_vector3:min({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0}),
    ok.

vector3_max_test() ->
    {4.0, 5.0, 6.0} = graphics_vector3:max({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0}),
    ok.

vector3_abs_test() ->
    {1.0, 2.0, 3.0} = graphics_vector3:abs({-1.0, 2.0, 3.0}),
    {1.0, 2.0, 3.0} = graphics_vector3:abs({1.0, -2.0, -3.0}),
    ok.

vector3_floor_test() ->
    {2.0, 2.0, 2.0} = graphics_vector3:floor({2.4, 2.6, 2.5}),
    ok.

vector3_ceil_test() ->
    {3.0, 3.0, 3.0} = graphics_vector3:ceil({2.4, 2.6, 2.5}),
    ok.

vector3_round_test() ->
    {2.0, 3.0, 2.0} = graphics_vector3:round({2.4, 2.6, 2.4}),
    {2.0, 3.0, 3.0} = graphics_vector3:round({2.4, 2.6, 2.6}),
    ok.

vector3_lerp_test() ->
    {1.0, 2.0, 3.0} = graphics_vector3:lerp({1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}, 0.0),
    {5.0, 6.0, 7.0} = graphics_vector3:lerp({1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}, 1.0),
    {3.0, 4.0, 5.0} = graphics_vector3:lerp({1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}, 0.5),
    ok.

vector3_smooth_lerp_test() ->
    {1.0, 2.0, 3.0} = graphics_vector3:smooth_lerp({1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}, 0.0),
    {5.0, 6.0, 7.0} = graphics_vector3:smooth_lerp({1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}, 1.0),
    {3.0, 4.0, 5.0} = graphics_vector3:smooth_lerp({1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}, 0.5),
    ok.
