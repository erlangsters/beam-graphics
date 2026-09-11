%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(camera3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

camera3_look_at_test() ->
    Position = {0.0, 0.0, 5.0},
    Target = {0.0, 0.0, 0.0},
    Default = camera3:look_at(Position, Target),
    Explicit = camera3:look_at(Position, Target, {0.0, 1.0, 0.0}),
    true = camera3:is_equal_to(Default, Explicit),
    Position = camera3:position(Default),
    Target = camera3:target(Default),
    {0.0, 1.0, 0.0} = camera3:up(Default),
    ok.

camera3_look_to_test() ->
    Position = {1.0, 2.0, 3.0},
    Direction = {0.0, 0.0, -4.0},
    true = camera3:is_equal_to(
        camera3:look_to(Position, Direction),
        camera3:look_at(Position, vector3:add(Position, Direction))
    ),
    Up = {0.0, 0.0, 1.0},
    true = camera3:is_equal_to(
        camera3:look_to(Position, Direction, Up),
        camera3:look_at(Position, vector3:add(Position, Direction), Up)
    ),
    ok.

camera3_view_matrix_test() ->
    Camera = camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}),
    M = camera3:view_matrix(Camera),
    true = vector3:is_equal_to(
        transform3:transform_point(M, {0.0, 0.0, 0.0}),
        {0.0, 0.0, -5.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_direction(M, {0.0, 1.0, 0.0}),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_direction(M, {1.0, 0.0, 0.0}),
        {1.0, 0.0, 0.0},
        ?EPS
    ),
    ok.

camera3_translate_test() ->
    Camera = camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}),
    Delta = {1.0, 2.0, 3.0},
    Translated = camera3:translate(Camera, Delta),
    true = camera3:is_equal_to(
        Translated,
        camera3:look_at({1.0, 2.0, 8.0}, {1.0, 2.0, 3.0})
    ),
    M1 = camera3:view_matrix(Camera),
    M2 = camera3:view_matrix(Translated),
    Point = {4.0, 5.0, 6.0},
    true = vector3:is_equal_to(
        transform3:transform_point(M1, Point),
        transform3:transform_point(M2, vector3:add(Point, Delta)),
        ?EPS
    ),
    ok.

camera3_is_equal_to_test() ->
    Camera = {{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
    true = camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}
    ),
    true = camera3:is_equal_to(
        {{+0.0, -0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        {{-0.0, +0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}
    ),
    false = camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 6.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}
    ),
    true = camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 5.0 + 1.0e-7}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        ?EPS
    ),
    false = camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 5.0 + 1.0e-5}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        ?EPS
    ),
    ok.
