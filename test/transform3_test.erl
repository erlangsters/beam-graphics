%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(transform3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

transform3_translation_test() ->
    true = vector3:is_equal_to(
        transform3:transform_point(
            transform3:translation({10.0, 20.0, 30.0}),
            {1.0, 2.0, 3.0}
        ),
        {11.0, 22.0, 33.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(
            transform3:translation({0.0, 0.0, 0.0}),
            {3.0, 4.0, 5.0}
        ),
        {3.0, 4.0, 5.0},
        ?EPS
    ),
    ok.

transform3_rotation_test() ->
    true = vector3:is_equal_to(
        transform3:transform_point(
            transform3:rotation(?ANGLE_90, {0.0, 0.0, 1.0}),
            {1.0, 0.0, 0.0}
        ),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(
            transform3:rotation(?ANGLE_90, {1.0, 0.0, 0.0}),
            {0.0, 1.0, 0.0}
        ),
        {0.0, 0.0, 1.0},
        ?EPS
    ),
    Point = {3.0, 4.0, 5.0},
    Axis = {1.0, 2.0, 3.0},
    true = vector3:is_equal_to(
        transform3:transform_point(transform3:rotation(?ANGLE_45, Axis), Point),
        vector3:rotate(Point, ?ANGLE_45, Axis),
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(
            transform3:rotation(0.0, {0.0, 0.0, 1.0}),
            Point
        ),
        Point,
        ?EPS
    ),
    try transform3:rotation(1.0, {0.0, 0.0, 0.0}) of
        ZeroAxis ->
            true = lists:any(
                fun(Value) -> Value /= Value end,
                tuple_to_list(ZeroAxis)
            )
    catch
        error:badarith ->
            ok
    end,
    ok.

transform3_scale_test() ->
    true = vector3:is_equal_to(
        transform3:transform_point(transform3:scale({2.0, 3.0, 4.0}), {1.0, 2.0, 3.0}),
        {2.0, 6.0, 12.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(transform3:scale({1.0, 1.0, 1.0}), {5.0, 7.0, 9.0}),
        {5.0, 7.0, 9.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(transform3:scale({-2.0, 4.0, 0.5}), {1.0, 2.0, 8.0}),
        {-2.0, 8.0, 4.0},
        ?EPS
    ),
    ok.

transform3_translate_test() ->
    true = matrix4:is_equal_to(
        transform3:translate(matrix4:identity(), {10.0, 20.0, 30.0}),
        transform3:translation({10.0, 20.0, 30.0}),
        ?EPS
    ),
    M = transform3:rotation(?ANGLE_90, {0.0, 0.0, 1.0}),
    true = matrix4:is_equal_to(
        transform3:translate(M, {10.0, 0.0, 0.0}),
        matrix4:multiply(M, transform3:translation({10.0, 0.0, 0.0})),
        ?EPS
    ),
    ok.

transform3_rotate_test() ->
    true = matrix4:is_equal_to(
        transform3:rotate(matrix4:identity(), ?ANGLE_90, {0.0, 0.0, 1.0}),
        transform3:rotation(?ANGLE_90, {0.0, 0.0, 1.0}),
        ?EPS
    ),
    M = transform3:translation({10.0, 0.0, 0.0}),
    true = matrix4:is_equal_to(
        transform3:rotate(M, ?ANGLE_90, {0.0, 1.0, 0.0}),
        matrix4:multiply(M, transform3:rotation(?ANGLE_90, {0.0, 1.0, 0.0})),
        ?EPS
    ),
    ok.

transform3_scale_combinator_test() ->
    true = matrix4:is_equal_to(
        transform3:scale(matrix4:identity(), {2.0, 3.0, 4.0}),
        transform3:scale({2.0, 3.0, 4.0}),
        ?EPS
    ),
    M = transform3:translation({10.0, 20.0, 30.0}),
    true = matrix4:is_equal_to(
        transform3:scale(M, {2.0, 3.0, 4.0}),
        matrix4:multiply(M, transform3:scale({2.0, 3.0, 4.0})),
        ?EPS
    ),
    ok.

transform3_compose3_test() ->
    Position = {10.0, 20.0, 30.0},
    Rotation = {?ANGLE_90, {0.0, 0.0, 1.0}},
    Scale = {2.0, 3.0, 4.0},
    {Angle, Axis} = Rotation,
    Expected = matrix4:multiply(
        transform3:translation(Position),
        matrix4:multiply(
            transform3:rotation(Angle, Axis),
            transform3:scale(Scale)
        )
    ),
    true = matrix4:is_equal_to(
        transform3:compose(Position, Rotation, Scale),
        Expected,
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(
            transform3:compose(Position, Rotation, Scale),
            {1.0, 0.0, 0.0}
        ),
        {10.0, 22.0, 30.0},
        ?EPS
    ),
    ok.

transform3_compose4_test() ->
    Origin = {1.0, 0.0, 0.0},
    M = transform3:compose(
        Origin,
        {0.0, 0.0, 0.0},
        {?ANGLE_90, {0.0, 0.0, 1.0}},
        {1.0, 1.0, 1.0}
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(M, {1.0, 0.0, 0.0}),
        {0.0, 0.0, 0.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(M, {2.0, 0.0, 0.0}),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    true = matrix4:is_equal_to(
        transform3:compose({3.0, 4.0, 5.0}, {0.5, {0.0, 1.0, 0.0}}, {2.0, 3.0, 4.0}),
        transform3:compose(
            {0.0, 0.0, 0.0},
            {3.0, 4.0, 5.0},
            {0.5, {0.0, 1.0, 0.0}},
            {2.0, 3.0, 4.0}
        ),
        ?EPS
    ),
    ok.

transform3_transform_point_test() ->
    M = transform3:compose(
        {5.0, 7.0, 9.0},
        {?ANGLE_45, {0.0, 1.0, 0.0}},
        {2.0, 3.0, 4.0}
    ),
    Point = {1.0, 2.0, 3.0},
    true = vector3:is_equal_to(
        transform3:transform_point(M, Point),
        matrix4:multiply_vector(M, Point),
        ?EPS
    ),
    Projective = matrix4:from_rows(
        {1.0, 0.0, 0.0, 0.0},
        {0.0, 1.0, 0.0, 0.0},
        {0.0, 0.0, 1.0, 0.0},
        {0.0, 0.0, 0.0, 2.0}
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(Projective, {2.0, 4.0, 6.0}),
        matrix4:multiply_vector(Projective, {2.0, 4.0, 6.0}),
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(Projective, {2.0, 4.0, 6.0}),
        {1.0, 2.0, 3.0},
        ?EPS
    ),
    ok.

transform3_transform_direction_test() ->
    true = vector3:is_equal_to(
        transform3:transform_direction(
            transform3:translation({100.0, 50.0, 25.0}),
            {1.0, 0.0, 0.0}
        ),
        {1.0, 0.0, 0.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_direction(
            transform3:rotation(?ANGLE_90, {0.0, 0.0, 1.0}),
            {1.0, 0.0, 0.0}
        ),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    M = transform3:compose(
        {100.0, 50.0, 25.0},
        {?ANGLE_90, {0.0, 0.0, 1.0}},
        {1.0, 1.0, 1.0}
    ),
    true = vector3:is_equal_to(
        transform3:transform_direction(M, {1.0, 0.0, 0.0}),
        {0.0, 1.0, 0.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        transform3:transform_point(M, {1.0, 0.0, 0.0}),
        {100.0, 51.0, 25.0},
        ?EPS
    ),
    ok.

transform3_transform_vertex_test() ->
    Vertex = {{1.0, 2.0, 3.0}, ?COLOR_RED, 0.25, 0.75},
    {Position, Color, U, V} = transform3:transform_vertex(
        transform3:translation({10.0, 20.0, 30.0}),
        Vertex
    ),
    true = vector3:is_equal_to(Position, {11.0, 22.0, 33.0}, ?EPS),
    Color = ?COLOR_RED,
    0.25 = U,
    0.75 = V,
    ok.

transform3_transform_box_test() ->
    Box = {{-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}},
    {{MinX, MinY, MinZ}, {MaxX, MaxY, MaxZ}} = transform3:transform_box(
        transform3:rotation(?ANGLE_45, {0.0, 0.0, 1.0}),
        Box
    ),
    true = MinX < -1.0,
    true = MinY < -1.0,
    true = MaxX > 1.0,
    true = MaxY > 1.0,
    Sqrt2 = math:sqrt(2.0),
    true = vector3:is_equal_to({MinX, MinY, MinZ}, {-Sqrt2, -Sqrt2, -1.0}, ?EPS),
    true = vector3:is_equal_to({MaxX, MaxY, MaxZ}, {Sqrt2, Sqrt2, 1.0}, ?EPS),
    Translated = transform3:transform_box(
        transform3:translation({10.0, 20.0, 30.0}),
        {{0.0, 0.0, 0.0}, {1.0, 2.0, 3.0}}
    ),
    true = vector3:is_equal_to(element(1, Translated), {10.0, 20.0, 30.0}, ?EPS),
    true = vector3:is_equal_to(element(2, Translated), {11.0, 22.0, 33.0}, ?EPS),
    ok.
