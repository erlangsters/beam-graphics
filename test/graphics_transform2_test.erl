%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_transform2_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

transform2_translation_test() ->
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:translation({10.0, 20.0}), {1.0, 2.0}),
        {11.0, 22.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:translation({0.0, 0.0}), {3.0, 4.0}),
        {3.0, 4.0},
        ?EPS
    ),
    ok.

transform2_rotation_test() ->
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:rotation(?ANGLE_90), {1.0, 0.0}),
        {0.0, 1.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:rotation(?ANGLE_90), {0.0, 1.0}),
        {-1.0, 0.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:rotation(0.0), {1.0, 2.0}),
        {1.0, 2.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:rotation(?ANGLE_90), {3.0, 4.0}),
        graphics_vector2:rotate({3.0, 4.0}, ?ANGLE_90),
        ?EPS
    ),
    ok.

transform2_scale_test() ->
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:scale({2.0, 3.0}), {1.0, 2.0}),
        {2.0, 6.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:scale({1.0, 1.0}), {5.0, 7.0}),
        {5.0, 7.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(graphics_transform2:scale({-2.0, 4.0}), {1.0, 2.0}),
        {-2.0, 8.0},
        ?EPS
    ),
    ok.

transform2_translate_test() ->
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:translate(graphics_matrix3:identity(), {10.0, 20.0}),
        graphics_transform2:translation({10.0, 20.0}),
        ?EPS
    ),
    M = graphics_transform2:rotate(graphics_matrix3:identity(), ?ANGLE_90),
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:translate(M, {10.0, 0.0}),
        graphics_matrix3:multiply(M, graphics_transform2:translation({10.0, 0.0})),
        ?EPS
    ),
    ok.

transform2_rotate_test() ->
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:rotate(graphics_matrix3:identity(), ?ANGLE_90),
        graphics_transform2:rotation(?ANGLE_90),
        ?EPS
    ),
    M = graphics_transform2:translation({10.0, 0.0}),
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:rotate(M, ?ANGLE_90),
        graphics_matrix3:multiply(M, graphics_transform2:rotation(?ANGLE_90)),
        ?EPS
    ),
    ok.

transform2_scale_combinator_test() ->
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:scale(graphics_matrix3:identity(), {2.0, 3.0}),
        graphics_transform2:scale({2.0, 3.0}),
        ?EPS
    ),
    M = graphics_transform2:translation({10.0, 20.0}),
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:scale(M, {2.0, 3.0}),
        graphics_matrix3:multiply(M, graphics_transform2:scale({2.0, 3.0})),
        ?EPS
    ),
    ok.

transform2_compose3_test() ->
    Position = {10.0, 20.0},
    Rotation = ?ANGLE_90,
    Scale = {2.0, 3.0},
    Expected = graphics_matrix3:multiply(
        graphics_transform2:translation(Position),
        graphics_matrix3:multiply(graphics_transform2:rotation(Rotation), graphics_transform2:scale(Scale))
    ),
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:compose(Position, Rotation, Scale),
        Expected,
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(
            graphics_transform2:compose(Position, Rotation, Scale),
            {1.0, 0.0}
        ),
        {10.0, 22.0},
        ?EPS
    ),
    ok.

transform2_compose4_test() ->
    Origin = {1.0, 0.0},
    M = graphics_transform2:compose(Origin, {0.0, 0.0}, ?ANGLE_90, {1.0, 1.0}),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(M, {1.0, 0.0}),
        {0.0, 0.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(M, {2.0, 0.0}),
        {0.0, 1.0},
        ?EPS
    ),
    true = graphics_matrix3:is_equal_to(
        graphics_transform2:compose({3.0, 4.0}, 0.5, {2.0, 3.0}),
        graphics_transform2:compose({0.0, 0.0}, {3.0, 4.0}, 0.5, {2.0, 3.0}),
        ?EPS
    ),
    ok.

transform2_decompose_test() ->
    Position = {10.0, 20.0},
    Rotation = math:pi() / 6.0,
    Scale = {2.0, 3.0},
    M = graphics_transform2:compose(Position, Rotation, Scale),
    {Dt, Dr, Ds} = graphics_transform2:decompose(M),
    true = graphics_vector2:is_equal_to(Dt, Position, ?EPS),
    true = erlang:abs(Dr - Rotation) =< ?EPS,
    true = graphics_vector2:is_equal_to(Ds, Scale, ?EPS),
    true = graphics_matrix3:is_equal_to(graphics_transform2:compose(Dt, Dr, Ds), M, ?EPS),
    MNeg = graphics_transform2:compose({1.0, 2.0}, 0.3, {2.0, -3.0}),
    {Nt, Nr, Ns} = graphics_transform2:decompose(MNeg),
    true = graphics_matrix3:is_equal_to(graphics_transform2:compose(Nt, Nr, Ns), MNeg, ?EPS),
    {ZeroT, ZeroR, ZeroS} = graphics_transform2:decompose(graphics_matrix3:identity()),
    true = graphics_vector2:is_equal_to(ZeroT, {0.0, 0.0}, ?EPS),
    true = erlang:abs(ZeroR) =< ?EPS,
    true = graphics_vector2:is_equal_to(ZeroS, {1.0, 1.0}, ?EPS),
    ok.

transform2_transform_point_test() ->
    M = graphics_transform2:compose({5.0, 7.0}, ?ANGLE_45, {2.0, 3.0}),
    Point = {1.0, 2.0},
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(M, Point),
        graphics_matrix3:multiply_vector(M, Point),
        ?EPS
    ),
    Projective = graphics_matrix3:from_rows(
        {1.0, 0.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 0.0, 2.0}
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(Projective, {2.0, 4.0}),
        graphics_matrix3:multiply_vector(Projective, {2.0, 4.0}),
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(Projective, {2.0, 4.0}),
        {1.0, 2.0},
        ?EPS
    ),
    ok.

transform2_transform_direction_test() ->
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_direction(graphics_transform2:translation({100.0, 50.0}), {1.0, 0.0}),
        {1.0, 0.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_direction(graphics_transform2:rotation(?ANGLE_90), {1.0, 0.0}),
        {0.0, 1.0},
        ?EPS
    ),
    M = graphics_transform2:compose({100.0, 50.0}, ?ANGLE_90, {1.0, 1.0}),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_direction(M, {1.0, 0.0}),
        {0.0, 1.0},
        ?EPS
    ),
    true = graphics_vector2:is_equal_to(
        graphics_transform2:transform_point(M, {1.0, 0.0}),
        {100.0, 51.0},
        ?EPS
    ),
    ok.

transform2_transform_vertex_test() ->
    Vertex = {{1.0, 2.0}, ?COLOR_RED, 0.25, 0.75},
    {Position, Color, U, V} = graphics_transform2:transform_vertex(
        graphics_transform2:translation({10.0, 20.0}),
        Vertex
    ),
    true = graphics_vector2:is_equal_to(Position, {11.0, 22.0}, ?EPS),
    Color = ?COLOR_RED,
    0.25 = U,
    0.75 = V,
    ok.

transform2_transform_box_test() ->
    Box = {{-1.0, -1.0}, {1.0, 1.0}},
    {{MinX, MinY}, {MaxX, MaxY}} = graphics_transform2:transform_box(
        graphics_transform2:rotation(?ANGLE_45),
        Box
    ),
    true = MinX < -1.0,
    true = MinY < -1.0,
    true = MaxX > 1.0,
    true = MaxY > 1.0,
    Sqrt2 = math:sqrt(2.0),
    true = graphics_vector2:is_equal_to({MinX, MinY}, {-Sqrt2, -Sqrt2}, ?EPS),
    true = graphics_vector2:is_equal_to({MaxX, MaxY}, {Sqrt2, Sqrt2}, ?EPS),
    Translated = graphics_transform2:transform_box(
        graphics_transform2:translation({10.0, 20.0}),
        {{0.0, 0.0}, {1.0, 2.0}}
    ),
    true = graphics_vector2:is_equal_to(element(1, Translated), {10.0, 20.0}, ?EPS),
    true = graphics_vector2:is_equal_to(element(2, Translated), {11.0, 22.0}, ?EPS),
    ok.
