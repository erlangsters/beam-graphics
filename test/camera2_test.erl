%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(camera2_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

camera2_from_center_test() ->
    Camera = camera2:from_center({10.0, 20.0}),
    {10.0, 20.0} = camera2:center(Camera),
    0.0 = camera2:rotation(Camera),
    1.0 = camera2:zoom(Camera),
    Camera = {{10.0, 20.0}, 0.0, 1.0},
    {{1.0, 2.0}, 0.5, 2.0} = camera2:from_center({1.0, 2.0}, 0.5, 2.0),
    ok.

camera2_identity_view_matrix_test() ->
    true = matrix3:is_identity(
        camera2:view_matrix({{0.0, 0.0}, 0.0, 1.0})
    ),
    ok.

camera2_from_center_maps_origin_test() ->
    Center = {10.0, 20.0},
    M = camera2:view_matrix(camera2:from_center(Center)),
    true = vector2:is_equal_to(
        transform2:transform_point(M, Center),
        {0.0, 0.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        transform2:transform_point(M, vector2:add(Center, {1.0, 0.0})),
        {1.0, 0.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        transform2:transform_point(M, vector2:add(Center, {0.0, 1.0})),
        {0.0, 1.0},
        ?EPS
    ),
    ok.

camera2_rotation_test() ->
    M = camera2:view_matrix(camera2:from_center({0.0, 0.0}, ?ANGLE_90, 1.0)),
    true = vector2:is_equal_to(
        transform2:transform_point(M, {1.0, 0.0}),
        {0.0, -1.0},
        ?EPS
    ),
    ok.

camera2_zoom_test() ->
    M = camera2:view_matrix(camera2:from_center({0.0, 0.0}, 0.0, 2.0)),
    true = vector2:is_equal_to(
        transform2:transform_point(M, {1.0, 0.0}),
        {2.0, 0.0},
        ?EPS
    ),
    true = vector2:is_equal_to(
        transform2:transform_point(M, {0.0, 1.5}),
        {0.0, 3.0},
        ?EPS
    ),
    ok.

camera2_translate_test() ->
    Camera = camera2:from_center({1.0, 2.0}, 0.5, 2.0),
    Translated = camera2:translate(Camera, {3.0, 4.0}),
    true = camera2:is_equal_to(
        Translated,
        camera2:from_center({4.0, 6.0}, 0.5, 2.0)
    ),
    ok.

camera2_is_equal_to_test() ->
    Camera = {{0.0, 0.0}, 0.0, 1.0},
    true = camera2:is_equal_to(Camera, {{0.0, 0.0}, 0.0, 1.0}),
    true = camera2:is_equal_to(
        {{+0.0, -0.0}, +0.0, 1.0},
        {{-0.0, +0.0}, -0.0, 1.0}
    ),
    false = camera2:is_equal_to(Camera, {{0.0, 0.0}, 0.0, 2.0}),
    true = camera2:is_equal_to(
        Camera,
        {{0.0, 0.0}, 0.0, 1.0 + 1.0e-7},
        ?EPS
    ),
    false = camera2:is_equal_to(
        Camera,
        {{0.0, 0.0}, 0.0, 1.0 + 1.0e-5},
        ?EPS
    ),
    ok.
