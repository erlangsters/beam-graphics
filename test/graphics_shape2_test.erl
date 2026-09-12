%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_shape2_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).
-define(VERTEX_1, {{0.0, 0.0}, ?COLOR_RED, 0.0, 0.0}).
-define(VERTEX_2, {{1.0, 0.0}, ?COLOR_GREEN, 1.0, 0.0}).
-define(VERTEX_3, {{0.0, 1.0}, ?COLOR_BLUE, 0.0, 1.0}).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

positions(Vertices) ->
    [Position || {Position, _Color, _U, _V} <- Vertices].

shape_mesh(Shape) ->
    [{Mesh, PrimitiveType, VertexCount}] = graphics_shape2:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

shape2_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh2:with_vertices([?VERTEX_1]),
    Shape = graphics_shape2:with_mesh(Mesh, points, 1),
    [{Mesh, points, 1}] = graphics_shape2:meshes(Shape),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Shape),
    no_texture = graphics_shape2:texture(Shape),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_with_mesh_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh2:with_vertices([?VERTEX_1, ?VERTEX_2, ?VERTEX_3]),
    Shape1 = graphics_shape2:with_mesh(Mesh, triangles, 3),
    [{Mesh, triangles, 3}] = graphics_shape2:meshes(Shape1),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Shape1),
    no_texture = graphics_shape2:texture(Shape1),

    {ok, Texture} = graphics_texture:with_color(?COLOR_WHITE, {1, 1}),
    Shape2 = graphics_shape2:with_mesh(Mesh, triangles, 3, Texture),
    [{Mesh, triangles, 3}] = graphics_shape2:meshes(Shape2),
    Texture = graphics_shape2:texture(Shape2),

    ok = graphics_mesh2:destroy(Mesh),
    ok = graphics_texture:destroy(Texture),
    ok.

shape2_with_meshes_test() ->
    ok = run_graphics(),

    Empty = graphics_shape2:with_meshes([]),
    [] = graphics_shape2:meshes(Empty),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Empty),
    no_texture = graphics_shape2:texture(Empty),
    ok = graphics_shape2:destroy(Empty),

    {ok, Mesh1} = graphics_mesh2:with_vertices([?VERTEX_1]),
    {ok, Mesh2} = graphics_mesh2:with_vertices([?VERTEX_2, ?VERTEX_3]),
    Meshes = [{Mesh1, points, 1}, {Mesh2, lines, 2}],
    Shape = graphics_shape2:with_meshes(Meshes),
    Meshes = graphics_shape2:meshes(Shape),
    no_texture = graphics_shape2:texture(Shape),

    {ok, Texture} = graphics_texture:with_color(?COLOR_RED, {1, 1}),
    Textured = graphics_shape2:with_meshes(Meshes, Texture),
    Meshes = graphics_shape2:meshes(Textured),
    Texture = graphics_shape2:texture(Textured),

    ok = graphics_shape2:destroy(Shape),
    ok = graphics_texture:destroy(Texture),
    ok.

shape2_set_matrix_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh2:with_vertices([?VERTEX_1]),
    Shape = graphics_shape2:with_mesh(Mesh, points, 1),
    Matrix = graphics_transform2:translation({10.0, 20.0}),
    Moved = graphics_shape2:set_matrix(Shape, Matrix),

    Matrix = graphics_shape2:matrix(Moved),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Shape),
    [{Mesh, points, 1}] = graphics_shape2:meshes(Moved),
    true = Mesh =:= element(1, hd(graphics_shape2:meshes(Shape))),
    no_texture = graphics_shape2:texture(Moved),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_set_texture_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh2:with_vertices([?VERTEX_1]),
    Shape = graphics_shape2:with_mesh(Mesh, points, 1),
    {ok, Texture} = graphics_texture:with_color(?COLOR_BLUE, {1, 1}),
    Textured = graphics_shape2:set_texture(Shape, Texture),

    Texture = graphics_shape2:texture(Textured),
    no_texture = graphics_shape2:texture(Shape),
    [{Mesh, points, 1}] = graphics_shape2:meshes(Textured),
    true = Mesh =:= element(1, hd(graphics_shape2:meshes(Shape))),

    Cleared = graphics_shape2:set_texture(Textured, no_texture),
    no_texture = graphics_shape2:texture(Cleared),

    ok = graphics_shape2:destroy(Shape),
    ok = graphics_texture:destroy(Texture),
    ok.

shape2_point_test() ->
    ok = run_graphics(),

    Position = {3.0, 4.0},
    {ok, Shape} = graphics_shape2:point(Position, ?COLOR_RED),
    {Mesh, points, 1} = shape_mesh(Shape),
    [{Position, ?COLOR_RED, 0.0, 0.0}] = graphics_mesh2:remote_vertices(Mesh),
    ?MATRIX3_IDENTITY = graphics_shape2:matrix(Shape),
    no_texture = graphics_shape2:texture(Shape),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_line_test() ->
    ok = run_graphics(),

    From = {0.0, 0.0},
    To = {5.0, 7.0},
    {ok, Shape} = graphics_shape2:line(From, To, ?COLOR_GREEN),
    {Mesh, lines, 2} = shape_mesh(Shape),
    [
        {From, ?COLOR_GREEN, 0.0, 0.0},
        {To, ?COLOR_GREEN, 0.0, 0.0}
    ] = graphics_mesh2:remote_vertices(Mesh),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_triangle_test() ->
    ok = run_graphics(),

    A = {0.0, 0.0},
    B = {1.0, 0.0},
    C = {0.0, 1.0},
    {ok, Shape} = graphics_shape2:triangle(A, B, C, ?COLOR_BLUE),
    {Mesh, triangles, 3} = shape_mesh(Shape),
    [
        {A, ?COLOR_BLUE, 0.0, 0.0},
        {B, ?COLOR_BLUE, 0.0, 0.0},
        {C, ?COLOR_BLUE, 0.0, 0.0}
    ] = graphics_mesh2:remote_vertices(Mesh),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_triangle_wires_test() ->
    ok = run_graphics(),

    A = {0.0, 0.0},
    B = {1.0, 0.0},
    C = {0.0, 1.0},
    {ok, Shape} = graphics_shape2:triangle_wires(A, B, C, ?COLOR_YELLOW),
    {Mesh, line_loop, 3} = shape_mesh(Shape),
    [
        {A, ?COLOR_YELLOW, 0.0, 0.0},
        {B, ?COLOR_YELLOW, 0.0, 0.0},
        {C, ?COLOR_YELLOW, 0.0, 0.0}
    ] = graphics_mesh2:remote_vertices(Mesh),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_rectangle_test() ->
    ok = run_graphics(),

    {ok, Shape} = graphics_shape2:rectangle({1.0, 2.0}, {10.0, 20.0}, ?COLOR_RED),
    {Mesh, triangle_fan, 4} = shape_mesh(Shape),
    [
        {{1.0, 2.0}, ?COLOR_RED, 0.0, 0.0},
        {{11.0, 2.0}, ?COLOR_RED, 0.0, 0.0},
        {{11.0, 22.0}, ?COLOR_RED, 0.0, 0.0},
        {{1.0, 22.0}, ?COLOR_RED, 0.0, 0.0}
    ] = graphics_mesh2:remote_vertices(Mesh),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_rectangle_wires_test() ->
    ok = run_graphics(),

    {ok, Shape} = graphics_shape2:rectangle_wires({1.0, 2.0}, {10.0, 20.0}, ?COLOR_RED),
    {Mesh, line_loop, 4} = shape_mesh(Shape),
    [
        {{1.0, 2.0}, ?COLOR_RED, 0.0, 0.0},
        {{11.0, 2.0}, ?COLOR_RED, 0.0, 0.0},
        {{11.0, 22.0}, ?COLOR_RED, 0.0, 0.0},
        {{1.0, 22.0}, ?COLOR_RED, 0.0, 0.0}
    ] = graphics_mesh2:remote_vertices(Mesh),

    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_rectangle_outline_test() ->
    ok = run_graphics(),

    {ok, Inward} = graphics_shape2:rectangle_outline(
        {0.0, 0.0},
        {10.0, 8.0},
        1.0,
        ?COLOR_RED
    ),
    {Mesh1, triangle_strip, 10} = shape_mesh(Inward),
    InwardPositions = positions(graphics_mesh2:remote_vertices(Mesh1)),
    [
        {0.0, 0.0}, {1.0, 1.0},
        {10.0, 0.0}, {9.0, 1.0},
        {10.0, 8.0}, {9.0, 7.0},
        {0.0, 8.0}, {1.0, 7.0},
        {0.0, 0.0}, {1.0, 1.0}
    ] = InwardPositions,

    {ok, Outward} = graphics_shape2:rectangle_outline(
        {0.0, 0.0},
        {10.0, 8.0},
        -1.0,
        ?COLOR_RED
    ),
    {Mesh2, triangle_strip, 10} = shape_mesh(Outward),
    OutwardPositions = positions(graphics_mesh2:remote_vertices(Mesh2)),
    [
        {0.0, 0.0}, {-1.0, -1.0},
        {10.0, 0.0}, {11.0, -1.0},
        {10.0, 8.0}, {11.0, 9.0},
        {0.0, 8.0}, {-1.0, 9.0},
        {0.0, 0.0}, {-1.0, -1.0}
    ] = OutwardPositions,

    ok = graphics_shape2:destroy(Inward),
    ok = graphics_shape2:destroy(Outward),
    ok.

shape2_circle_test() ->
    ok = run_graphics(),

    Center = {2.0, 3.0},
    Radius = 5.0,
    {ok, Default} = graphics_shape2:circle(Center, Radius, ?COLOR_RED),
    {_Mesh0, triangle_fan, 34} = shape_mesh(Default),

    {ok, Shape} = graphics_shape2:circle(Center, Radius, 8, ?COLOR_RED),
    {Mesh, triangle_fan, 10} = shape_mesh(Shape),
    [CenterVertex | Rim] = positions(graphics_mesh2:remote_vertices(Mesh)),
    true = graphics_vector2:is_equal_to(CenterVertex, Center, ?EPS),
    true = graphics_vector2:is_equal_to(hd(Rim), lists:last(Rim), ?EPS),
    false = graphics_vector2:is_equal_to(hd(Rim), Center, ?EPS),
    true = graphics_vector2:is_equal_to(
        hd(Rim),
        {2.0 + Radius, 3.0},
        ?EPS
    ),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, graphics_mesh2:remote_vertices(Mesh)),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_circle_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape2:circle_wires({0.0, 0.0}, 1.0, ?COLOR_RED),
    {_Mesh0, line_loop, 32} = shape_mesh(Default),

    {ok, Shape} = graphics_shape2:circle_wires({0.0, 0.0}, 4.0, 8, ?COLOR_RED),
    {Mesh, line_loop, 8} = shape_mesh(Shape),
    8 = length(graphics_mesh2:remote_vertices(Mesh)),
    true = graphics_vector2:is_equal_to(
        hd(positions(graphics_mesh2:remote_vertices(Mesh))),
        {4.0, 0.0},
        ?EPS
    ),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Shape),
    ok.

shape2_circle_outline_test() ->
    ok = run_graphics(),

    {ok, Default} = graphics_shape2:circle_outline({0.0, 0.0}, 5.0, 1.0, ?COLOR_RED),
    {_Mesh0, triangle_strip, 66} = shape_mesh(Default),

    {ok, Inward} = graphics_shape2:circle_outline({0.0, 0.0}, 10.0, 8, 2.0, ?COLOR_RED),
    {Mesh1, triangle_strip, 18} = shape_mesh(Inward),
    [Outer0, Inner0 | _] = positions(graphics_mesh2:remote_vertices(Mesh1)),
    true = graphics_vector2:is_equal_to(Outer0, {10.0, 0.0}, ?EPS),
    true = graphics_vector2:is_equal_to(Inner0, {8.0, 0.0}, ?EPS),

    {ok, Outward} = graphics_shape2:circle_outline({0.0, 0.0}, 10.0, 8, -2.0, ?COLOR_RED),
    {Mesh2, triangle_strip, 18} = shape_mesh(Outward),
    [Outer1, Inner1 | _] = positions(graphics_mesh2:remote_vertices(Mesh2)),
    true = graphics_vector2:is_equal_to(Outer1, {10.0, 0.0}, ?EPS),
    true = graphics_vector2:is_equal_to(Inner1, {12.0, 0.0}, ?EPS),

    ok = graphics_shape2:destroy(Default),
    ok = graphics_shape2:destroy(Inward),
    ok = graphics_shape2:destroy(Outward),
    ok.
