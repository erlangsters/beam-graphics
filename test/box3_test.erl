%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(box3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

box3_test() ->
    Box = {{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}},
    {1.0, 2.0, 3.0} = box3:min(Box),
    {5.0, 6.0, 7.0} = box3:max(Box),
    ok.

box3_from_points_test() ->
    {{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}} = box3:from_points([
        {1.0, 2.0, 3.0},
        {5.0, 6.0, 7.0},
        {3.0, 4.0, 5.0}
    ]),
    {{3.0, 4.0, 5.0}, {3.0, 4.0, 5.0}} = box3:from_points([{3.0, 4.0, 5.0}]),
    {{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}} = box3:from_points([
        {5.0, 2.0, 3.0},
        {1.0, 6.0, 7.0}
    ]),
    ok.

box3_from_vertices_test() ->
    Vertices = [
        {{1.0, 2.0, 3.0}, {1.0, 0.0, 0.0, 1.0}, 0.0, 1.0},
        {{5.0, 6.0, 7.0}, {0.0, 1.0, 0.0, 1.0}, 1.0, 0.0},
        {{3.0, 4.0, 5.0}, {0.0, 0.0, 1.0, 1.0}, 0.5, 0.5}
    ],
    {{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}} = box3:from_vertices(Vertices),
    ok.

box3_from_center_size_test() ->
    {{-5.0, -10.0, -15.0}, {5.0, 10.0, 15.0}} = box3:from_center_size(
        {0.0, 0.0, 0.0},
        {10.0, 20.0, 30.0}
    ),
    true = box3:is_equal_to(
        box3:from_center_size({0.0, 0.0, 0.0}, {10.0, 20.0, 30.0}),
        box3:from_center_size({0.0, 0.0, 0.0}, {-10.0, 20.0, 30.0})
    ),
    {{5.0, 6.0, 7.0}, {5.0, 6.0, 7.0}} = box3:from_center_size(
        {5.0, 6.0, 7.0},
        {0.0, 0.0, 0.0}
    ),
    ok.

box3_center_test() ->
    {5.0, 10.0, 15.0} = box3:center({{0.0, 0.0, 0.0}, {10.0, 20.0, 30.0}}),
    {3.0, 4.0, 5.0} = box3:center({{3.0, 4.0, 5.0}, {3.0, 4.0, 5.0}}),
    ok.

box3_size_test() ->
    {10.0, 20.0, 30.0} = box3:size({{0.0, 0.0, 0.0}, {10.0, 20.0, 30.0}}),
    {0.0, 0.0, 0.0} = box3:size({{3.0, 4.0, 5.0}, {3.0, 4.0, 5.0}}),
    ok.

box3_volume_test() ->
    6000.0 = box3:volume({{0.0, 0.0, 0.0}, {10.0, 20.0, 30.0}}),
    0.0 = box3:volume({{3.0, 4.0, 5.0}, {3.0, 4.0, 5.0}}),
    ok.

box3_corners_test() ->
    [
        {1.0, 2.0, 3.0}, {5.0, 2.0, 3.0},
        {1.0, 6.0, 3.0}, {5.0, 6.0, 3.0},
        {1.0, 2.0, 7.0}, {5.0, 2.0, 7.0},
        {1.0, 6.0, 7.0}, {5.0, 6.0, 7.0}
    ] = box3:corners({{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}}),
    Box = {{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}},
    true = box3:is_equal_to(Box, box3:from_points(box3:corners(Box))),
    ok.

box3_contains_test() ->
    Box = {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}},
    true = box3:contains(Box, {0.5, 0.5, 0.5}),
    true = box3:contains(Box, {0.0, 0.0, 0.0}),
    true = box3:contains(Box, {1.0, 1.0, 1.0}),
    true = box3:contains(Box, {0.0, 0.5, 0.5}),
    true = box3:contains(Box, {1.0, 0.5, 0.5}),
    true = box3:contains(Box, {0.5, 0.0, 0.5}),
    true = box3:contains(Box, {0.5, 1.0, 0.5}),
    true = box3:contains(Box, {0.5, 0.5, 0.0}),
    true = box3:contains(Box, {0.5, 0.5, 1.0}),
    false = box3:contains(Box, {-0.1, 0.5, 0.5}),
    false = box3:contains(Box, {1.1, 0.5, 0.5}),
    false = box3:contains(Box, {0.5, -0.1, 0.5}),
    false = box3:contains(Box, {0.5, 1.1, 0.5}),
    false = box3:contains(Box, {0.5, 0.5, -0.1}),
    false = box3:contains(Box, {0.5, 0.5, 1.1}),
    ok.

box3_intersects_test() ->
    Box = {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}},
    true = box3:intersects(Box, Box),
    true = box3:intersects(Box, {{0.5, 0.5, 0.5}, {1.5, 1.5, 1.5}}),
    true = box3:intersects({{0.5, 0.5, 0.5}, {1.5, 1.5, 1.5}}, Box),
    true = box3:intersects(Box, {{1.0, 0.0, 0.0}, {2.0, 1.0, 1.0}}),
    true = box3:intersects(Box, {{1.0, 1.0, 1.0}, {2.0, 2.0, 2.0}}),
    false = box3:intersects(Box, {{2.0, 2.0, 2.0}, {3.0, 3.0, 3.0}}),
    false = box3:intersects(Box, {{1.1, 0.0, 0.0}, {2.0, 1.0, 1.0}}),
    ok.

box3_intersection_test() ->
    {ok, {{1.0, 1.0, 1.0}, {2.0, 2.0, 2.0}}} = box3:intersection(
        {{0.0, 0.0, 0.0}, {2.0, 2.0, 2.0}},
        {{1.0, 1.0, 1.0}, {3.0, 3.0, 3.0}}
    ),
    {ok, {{1.0, 0.0, 0.0}, {1.0, 1.0, 1.0}}} = box3:intersection(
        {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}},
        {{1.0, 0.0, 0.0}, {2.0, 1.0, 1.0}}
    ),
    {ok, {{1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}}} = box3:intersection(
        {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}},
        {{1.0, 1.0, 1.0}, {2.0, 2.0, 2.0}}
    ),
    {error, disjoint} = box3:intersection(
        {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}},
        {{2.0, 2.0, 2.0}, {3.0, 3.0, 3.0}}
    ),
    ok.

box3_union_test() ->
    {{0.0, 0.0, 0.0}, {3.0, 3.0, 3.0}} = box3:union(
        {{0.0, 0.0, 0.0}, {2.0, 2.0, 2.0}},
        {{1.0, 1.0, 1.0}, {3.0, 3.0, 3.0}}
    ),
    ok.

box3_expand_test() ->
    Box = {{0.0, 0.0, 0.0}, {10.0, 10.0, 10.0}},
    true = box3:is_equal_to(Box, box3:expand(Box, {5.0, 5.0, 5.0})),
    {{0.0, 0.0, 0.0}, {12.0, 10.0, 10.0}} = box3:expand(Box, {12.0, 5.0, 5.0}),
    {{-1.0, 0.0, 0.0}, {10.0, 10.0, 10.0}} = box3:expand(Box, {-1.0, 5.0, 5.0}),
    ok.

box3_translate_test() ->
    {{10.0, 20.0, 30.0}, {11.0, 22.0, 33.0}} = box3:translate(
        {{0.0, 0.0, 0.0}, {1.0, 2.0, 3.0}},
        {10.0, 20.0, 30.0}
    ),
    ok.

box3_is_equal_to_test() ->
    Box = {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}},
    true = box3:is_equal_to(Box, {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}}),
    true = box3:is_equal_to(
        {{+0.0, -0.0, +0.0}, {1.0, 1.0, 1.0}},
        {{-0.0, +0.0, -0.0}, {1.0, 1.0, 1.0}}
    ),
    false = box3:is_equal_to(Box, {{0.0, 0.0, 0.0}, {1.0, 1.0, 2.0}}),
    true = box3:is_equal_to(
        Box,
        {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0 + 1.0e-7}},
        ?EPS
    ),
    false = box3:is_equal_to(
        Box,
        {{0.0, 0.0, 0.0}, {1.0, 1.0, 1.0 + 1.0e-5}},
        ?EPS
    ),
    ok.

box3_to_box2_test() ->
    {{0.0, 0.0}, {10.0, 20.0}} = box3:to_box2(
        {{0.0, 0.0, 5.0}, {10.0, 20.0, 30.0}}
    ),
    Box = {{1.0, 2.0}, {3.0, 4.0}},
    true = box2:is_equal_to(Box, box3:to_box2(box2:to_box3(Box))),
    ok.
