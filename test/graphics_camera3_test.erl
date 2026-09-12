%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_camera3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

camera3_look_at_test() ->
    Position = {0.0, 0.0, 5.0},
    Target = {0.0, 0.0, 0.0},
    Default = graphics_camera3:look_at(Position, Target),
    Explicit = graphics_camera3:look_at(Position, Target, {0.0, 1.0, 0.0}),
    true = graphics_camera3:is_equal_to(Default, Explicit),
    Position = graphics_camera3:position(Default),
    Target = graphics_camera3:target(Default),
    {0.0, 1.0, 0.0} = graphics_camera3:up(Default),
    ok.

camera3_look_to_test() ->
    Position = {1.0, 2.0, 3.0},
    Direction = {0.0, 0.0, -4.0},
    true = graphics_camera3:is_equal_to(
        graphics_camera3:look_to(Position, Direction),
        graphics_camera3:look_at(Position, graphics_vector3:add(Position, Direction))
    ),
    Up = {0.0, 0.0, 1.0},
    true = graphics_camera3:is_equal_to(
        graphics_camera3:look_to(Position, Direction, Up),
        graphics_camera3:look_at(Position, graphics_vector3:add(Position, Direction), Up)
    ),
    ok.

camera3_view_matrix_test() ->
    Camera = graphics_camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}),
    M = graphics_camera3:view_matrix(Camera),
    true = graphics_vector3:is_equal_to(
        graphics_transform3:transform_point(M, {0.0, 0.0, 0.0}),
        {0.0, 0.0, -5.0},
        ?EPS
    ),
    true = graphics_vector3:is_equal_to(
        graphics_transform3:transform_direction(M, {0.0, 1.0, 0.0}),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    true = graphics_vector3:is_equal_to(
        graphics_transform3:transform_direction(M, {1.0, 0.0, 0.0}),
        {1.0, 0.0, 0.0},
        ?EPS
    ),
    ok.

camera3_translate_test() ->
    Camera = graphics_camera3:look_at({0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}),
    Delta = {1.0, 2.0, 3.0},
    Translated = graphics_camera3:translate(Camera, Delta),
    true = graphics_camera3:is_equal_to(
        Translated,
        graphics_camera3:look_at({1.0, 2.0, 8.0}, {1.0, 2.0, 3.0})
    ),
    M1 = graphics_camera3:view_matrix(Camera),
    M2 = graphics_camera3:view_matrix(Translated),
    Point = {4.0, 5.0, 6.0},
    true = graphics_vector3:is_equal_to(
        graphics_transform3:transform_point(M1, Point),
        graphics_transform3:transform_point(M2, graphics_vector3:add(Point, Delta)),
        ?EPS
    ),
    ok.

camera3_is_equal_to_test() ->
    Camera = {{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
    true = graphics_camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}
    ),
    true = graphics_camera3:is_equal_to(
        {{+0.0, -0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        {{-0.0, +0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}
    ),
    false = graphics_camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 6.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}
    ),
    true = graphics_camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 5.0 + 1.0e-7}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        ?EPS
    ),
    false = graphics_camera3:is_equal_to(
        Camera,
        {{0.0, 0.0, 5.0 + 1.0e-5}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}},
        ?EPS
    ),
    ok.
