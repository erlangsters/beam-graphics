%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).
-define(VERTEX_1, {{0.0, 0.0, 0.0}, ?COLOR_RED, 0.0, 0.0}).
-define(VERTEX_2, {{1.0, 0.0, 0.0}, ?COLOR_GREEN, 1.0, 0.0}).
-define(VERTEX_3, {{0.0, 1.0, 0.0}, ?COLOR_BLUE, 0.0, 1.0}).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

positions(Vertices) ->
    [Position || {Position, _Color, _U, _V} <- Vertices].

shape_mesh(Shape) ->
    [{Mesh, PrimitiveType, VertexCount}] = shape3:meshes(Shape),
    {Mesh, PrimitiveType, VertexCount}.

has_point(Positions, Point) ->
    lists:any(fun(Position) ->
        vector3:is_equal_to(Position, Point, ?EPS)
    end, Positions).

no_zero_segments([]) ->
    true;
no_zero_segments([A, B | Rest]) ->
    (not vector3:is_equal_to(A, B, ?EPS)) andalso no_zero_segments(Rest).

shape3_test() ->
    ok = run_graphics(),

    {ok, Mesh} = mesh3:with_vertices([?VERTEX_1]),
    Shape = shape3:with_mesh(Mesh, points, 1),
    [{Mesh, points, 1}] = shape3:meshes(Shape),
    ?MATRIX4_IDENTITY = shape3:matrix(Shape),
    no_texture = shape3:texture(Shape),

    ok = shape3:destroy(Shape),
    ok.

shape3_with_mesh_test() ->
    ok = run_graphics(),

    {ok, Mesh} = mesh3:with_vertices([?VERTEX_1, ?VERTEX_2, ?VERTEX_3]),
    Shape1 = shape3:with_mesh(Mesh, triangles, 3),
    [{Mesh, triangles, 3}] = shape3:meshes(Shape1),
    ?MATRIX4_IDENTITY = shape3:matrix(Shape1),
    no_texture = shape3:texture(Shape1),

    {ok, Texture} = texture:with_color(?COLOR_WHITE, {1, 1}),
    Shape2 = shape3:with_mesh(Mesh, triangles, 3, Texture),
    [{Mesh, triangles, 3}] = shape3:meshes(Shape2),
    Texture = shape3:texture(Shape2),

    ok = mesh3:destroy(Mesh),
    ok = texture:destroy(Texture),
    ok.

shape3_with_meshes_test() ->
    ok = run_graphics(),

    Empty = shape3:with_meshes([]),
    [] = shape3:meshes(Empty),
    ?MATRIX4_IDENTITY = shape3:matrix(Empty),
    no_texture = shape3:texture(Empty),
    ok = shape3:destroy(Empty),

    {ok, Mesh1} = mesh3:with_vertices([?VERTEX_1]),
    {ok, Mesh2} = mesh3:with_vertices([?VERTEX_2, ?VERTEX_3]),
    Meshes = [{Mesh1, points, 1}, {Mesh2, lines, 2}],
    Shape = shape3:with_meshes(Meshes),
    Meshes = shape3:meshes(Shape),
    no_texture = shape3:texture(Shape),

    {ok, Texture} = texture:with_color(?COLOR_RED, {1, 1}),
    Textured = shape3:with_meshes(Meshes, Texture),
    Meshes = shape3:meshes(Textured),
    Texture = shape3:texture(Textured),

    ok = shape3:destroy(Shape),
    ok = texture:destroy(Texture),
    ok.

shape3_set_matrix_test() ->
    ok = run_graphics(),

    {ok, Mesh} = mesh3:with_vertices([?VERTEX_1]),
    Shape = shape3:with_mesh(Mesh, points, 1),
    Matrix = transform3:translation({10.0, 20.0, 30.0}),
    Moved = shape3:set_matrix(Shape, Matrix),

    Matrix = shape3:matrix(Moved),
    ?MATRIX4_IDENTITY = shape3:matrix(Shape),
    [{Mesh, points, 1}] = shape3:meshes(Moved),
    true = Mesh =:= element(1, hd(shape3:meshes(Shape))),
    no_texture = shape3:texture(Moved),

    ok = shape3:destroy(Shape),
    ok.

shape3_set_texture_test() ->
    ok = run_graphics(),

    {ok, Mesh} = mesh3:with_vertices([?VERTEX_1]),
    Shape = shape3:with_mesh(Mesh, points, 1),
    {ok, Texture} = texture:with_color(?COLOR_BLUE, {1, 1}),
    Textured = shape3:set_texture(Shape, Texture),

    Texture = shape3:texture(Textured),
    no_texture = shape3:texture(Shape),
    [{Mesh, points, 1}] = shape3:meshes(Textured),
    true = Mesh =:= element(1, hd(shape3:meshes(Shape))),

    Cleared = shape3:set_texture(Textured, no_texture),
    no_texture = shape3:texture(Cleared),

    ok = shape3:destroy(Shape),
    ok = texture:destroy(Texture),
    ok.

shape3_point_test() ->
    ok = run_graphics(),

    Position = {3.0, 4.0, 5.0},
    {ok, Shape} = shape3:point(Position, ?COLOR_RED),
    {Mesh, points, 1} = shape_mesh(Shape),
    [{Position, ?COLOR_RED, 0.0, 0.0}] = mesh3:remote_vertices(Mesh),
    ?MATRIX4_IDENTITY = shape3:matrix(Shape),
    no_texture = shape3:texture(Shape),

    ok = shape3:destroy(Shape),
    ok.

shape3_line_test() ->
    ok = run_graphics(),

    From = {0.0, 0.0, 0.0},
    To = {5.0, 7.0, 9.0},
    {ok, Shape} = shape3:line(From, To, ?COLOR_GREEN),
    {Mesh, lines, 2} = shape_mesh(Shape),
    [
        {From, ?COLOR_GREEN, 0.0, 0.0},
        {To, ?COLOR_GREEN, 0.0, 0.0}
    ] = mesh3:remote_vertices(Mesh),

    ok = shape3:destroy(Shape),
    ok.

shape3_triangle_test() ->
    ok = run_graphics(),

    A = {0.0, 0.0, 0.0},
    B = {1.0, 0.0, 0.0},
    C = {0.0, 1.0, 0.0},
    {ok, Shape} = shape3:triangle(A, B, C, ?COLOR_BLUE),
    {Mesh, triangles, 3} = shape_mesh(Shape),
    [
        {A, ?COLOR_BLUE, 0.0, 0.0},
        {B, ?COLOR_BLUE, 0.0, 0.0},
        {C, ?COLOR_BLUE, 0.0, 0.0}
    ] = mesh3:remote_vertices(Mesh),

    ok = shape3:destroy(Shape),
    ok.

shape3_triangle_wires_test() ->
    ok = run_graphics(),

    A = {0.0, 0.0, 0.0},
    B = {1.0, 0.0, 0.0},
    C = {0.0, 1.0, 0.0},
    {ok, Shape} = shape3:triangle_wires(A, B, C, ?COLOR_YELLOW),
    {Mesh, line_loop, 3} = shape_mesh(Shape),
    [
        {A, ?COLOR_YELLOW, 0.0, 0.0},
        {B, ?COLOR_YELLOW, 0.0, 0.0},
        {C, ?COLOR_YELLOW, 0.0, 0.0}
    ] = mesh3:remote_vertices(Mesh),

    ok = shape3:destroy(Shape),
    ok.

shape3_cube_test() ->
    ok = run_graphics(),

    Center = {1.0, 2.0, 3.0},
    Size = {2.0, 4.0, 6.0},
    {ok, Shape} = shape3:cube(Center, Size, ?COLOR_RED),
    {Mesh, triangles, 36} = shape_mesh(Shape),
    Vertices = mesh3:remote_vertices(Mesh),
    36 = length(Vertices),
    Positions = positions(Vertices),
    Corners = box3:corners(box3:from_center_size(Center, Size)),
    lists:foreach(fun(Corner) ->
        true = has_point(Positions, Corner)
    end, Corners),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, Vertices),

    [A, B, C | _] = Positions,
    Normal = vector3:cross_product(
        vector3:subtract(B, A),
        vector3:subtract(C, A)
    ),
    true = vector3:z(Normal) > 0.0,

    ok = shape3:destroy(Shape),
    ok.

shape3_cube_wires_test() ->
    ok = run_graphics(),

    Center = {0.0, 0.0, 0.0},
    Size = {2.0, 4.0, 6.0},
    {ok, Shape} = shape3:cube_wires(Center, Size, ?COLOR_RED),
    {Mesh, lines, 24} = shape_mesh(Shape),
    Positions = positions(mesh3:remote_vertices(Mesh)),
    24 = length(Positions),
    Corners = box3:corners(box3:from_center_size(Center, Size)),
    lists:foreach(fun(Corner) ->
        true = has_point(Positions, Corner)
    end, Corners),
    true = no_zero_segments(Positions),

    ok = shape3:destroy(Shape),
    ok.

shape3_sphere_test() ->
    ok = run_graphics(),

    {ok, Default} = shape3:sphere({0.0, 0.0, 0.0}, 1.0, ?COLOR_RED),
    {_Mesh0, triangles, 1440} = shape_mesh(Default),

    Center = {1.0, 2.0, 3.0},
    Radius = 4.0,
    Rings = 4,
    Slices = 8,
    {ok, Shape} = shape3:sphere(Center, Radius, Rings, Slices, ?COLOR_RED),
    ExpectedCount = 6 * Slices * (Rings - 1),
    {Mesh, triangles, ExpectedCount} = shape_mesh(Shape),
    Vertices = mesh3:remote_vertices(Mesh),
    ExpectedCount = length(Vertices),
    Positions = positions(Vertices),
    North = {1.0, 2.0 + Radius, 3.0},
    South = {1.0, 2.0 - Radius, 3.0},
    true = has_point(Positions, North),
    true = has_point(Positions, South),
    lists:foreach(fun({_Position, Color, U, V}) ->
        ?COLOR_RED = Color,
        0.0 = U,
        0.0 = V
    end, Vertices),

    ok = shape3:destroy(Default),
    ok = shape3:destroy(Shape),
    ok.

shape3_sphere_wires_test() ->
    ok = run_graphics(),

    {ok, Default} = shape3:sphere_wires({0.0, 0.0, 0.0}, 1.0, ?COLOR_RED),
    {_Mesh0, lines, 992} = shape_mesh(Default),

    Center = {1.0, 2.0, 3.0},
    Radius = 4.0,
    Rings = 4,
    Slices = 8,
    {ok, Shape} = shape3:sphere_wires(Center, Radius, Rings, Slices, ?COLOR_RED),
    ExpectedCount = 2 * Slices * (2 * Rings - 1),
    {Mesh, lines, ExpectedCount} = shape_mesh(Shape),
    Positions = positions(mesh3:remote_vertices(Mesh)),
    ExpectedCount = length(Positions),
    true = has_point(Positions, {1.0, 2.0 + Radius, 3.0}),
    true = has_point(Positions, {1.0, 2.0 - Radius, 3.0}),
    true = no_zero_segments(Positions),

    ok = shape3:destroy(Default),
    ok = shape3:destroy(Shape),
    ok.
