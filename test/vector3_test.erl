%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(vector3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

vector3_test() ->
    V = {1.0, 2.0, 3.0},
    1.0 = vector3:x(V),
    2.0 = vector3:y(V),
    3.0 = vector3:z(V),

    ok.

vector3_zero_test() ->
    {0.0, 0.0, 0.0} = vector3:zero(),
    {0.0, 0.0, 0.0} = ?VECTOR3_ZERO,

    ok.

vector3_length_test() ->
    V = {3.0, 4.0, 5.0},
    7.0710678118654755 = vector3:length(V),

    ok.

vector3_normalize_test() ->
    V = {3.0, 4.0, 5.0},
    {0.4242640687119285, 0.565685424949238, 0.7071067811865475} = vector3:normalize(V),

    ok.

vector3_dot_product_test() ->
    V1 = {1.0, 2.0, 3.0},
    V2 = {4.0, 5.0, 6.0},
    32.0 = vector3:dot_product(V1, V2),

    ok.

vector3_cross_product_test() ->
    V1 = {1.0, 2.0, 3.0},
    V2 = {4.0, 5.0, 6.0},
    {-3.0, 6.0, -3.0} = vector3:cross_product(V1, V2),

    ok.

vector3_add_test() ->
    V1 = {1.0, 2.0, 3.0},
    V2 = {4.0, 5.0, 6.0},
    {5.0, 7.0, 9.0} = vector3:add(V1, V2),

    ok.

vector3_subtract_test() ->
    V1 = {1.0, 2.0, 3.0},
    V2 = {4.0, 5.0, 6.0},
    {-3.0, -3.0, -3.0} = vector3:subtract(V1, V2),

    ok.

vector3_multiply_test() ->
    V = {1.0, 2.0, 3.0},
    {2.0, 4.0, 6.0} = vector3:multiply(V, 2.0),

    ok.

vector3_to_vector2_test() ->
    V = {1.0, 2.0, 3.0},
    {1.0, 2.0} = vector3:to_vector2(V),

    ok.

vector3_min_test() ->
    V1 = {1.0, 5.0, 3.0},
    V2 = {4.0, 2.0, 6.0},
    {1.0, 2.0, 3.0} = vector3:min(V1, V2),

    ok.

vector3_max_test() ->
    V1 = {1.0, 5.0, 3.0},
    V2 = {4.0, 2.0, 6.0},
    {4.0, 5.0, 6.0} = vector3:max(V1, V2),

    ok.
