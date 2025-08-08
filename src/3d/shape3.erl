%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3).
-moduledoc """
To be written.

To be written.
""".

-export([
    with_mesh/3, with_mesh/4,
    with_meshes/1, with_meshes/2,
    destroy/1
]).
-export([
    point/2,
    line/3,
    triangle/4
]).
-export([
    cube/3,
    cube_wires/3
]).
-export([
    sphere/3, sphere/5,
    sphere_wires/3, sphere_wires/5
]).

-compile({inline, [
    with_mesh/3, with_mesh/4,
    with_meshes/1, with_meshes/2
]}).
-compile({inline, [
    point/2,
    line/3,
    triangle/4
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-doc """
To be written.

To be written.
""".
-spec with_mesh(
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count()
) ->
    graphics:shape3()
.
with_mesh(Mesh, PrimitiveType, VertexCount) ->
    with_mesh(Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
To be written.

To be written.
""".
-spec with_mesh(
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
with_mesh(Mesh, PrimitiveType, VertexCount, Texture) ->
    #shape3{
        meshes = [{Mesh, PrimitiveType, VertexCount}],
        texture = Texture
    }.

-doc """
To be written.

To be written.
""".
-spec with_meshes(
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}]
) ->
    graphics:shape3()
.
with_meshes(Meshes) ->
    with_meshes(Meshes, no_texture).

-doc """
To be written.

To be written.
""".
-spec with_meshes(
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}],
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
with_meshes(Meshes, Texture) ->
    #shape3{
        meshes = Meshes,
        texture = Texture
    }.

-doc """
To be written.

To be written.
""".
-spec destroy(graphics:shape3()) -> ok.
destroy(#shape3{meshes = Meshes}) ->
    lists:foreach(fun({Mesh, _PrimitiveType, _VertexCount}) ->
        mesh3:destroy(Mesh)
    end, Meshes).

-doc """
To be written.

To be written.
""".
-spec point(graphics:vector3(), graphics:color()) -> graphics:shape3().
point(Position, Color) ->
    {ok, Mesh} = mesh3:with_vertices([?VERTEX3(Position, Color)]),
    shape3:with_mesh(Mesh, points, 1).

-doc """
To be written.

To be written.
""".
-spec line(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    graphics:shape3()
.
line(From, To, Color) ->
    {ok, Mesh} = mesh3:with_vertices([
        ?VERTEX3(From, Color),
        ?VERTEX3(To, Color)
    ]),
    shape3:with_mesh(Mesh, lines, 2).

-doc """
To be written.

To be written.
""".
-spec triangle(
    graphics:vector3(),
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    graphics:shape3()
.
triangle(A, B, C, Color) ->
    {ok, Mesh} = mesh3:with_vertices([
        ?VERTEX3(A, Color),
        ?VERTEX3(B, Color),
        ?VERTEX3(C, Color)
    ]),
    shape3:with_mesh(Mesh, triangles, 3).

-doc """
To be written.

To be written.
""".
-spec cube(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    graphics:shape3()
.
cube({X, Y, Z}, {Width, Height, Length}, Color) ->
    Vertices = [
        % Front face
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Left

        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Right

        % Back face
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom Left
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom Right

        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Right
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Left

        % Top face
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Left
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Bottom Left
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Bottom Right

        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Left
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Bottom Right

        % Bottom face
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Top Left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Left

        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Top Right
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Top Left

        % Right face
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Right
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Left

        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Left

        % Left face
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom Right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Left
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top Right

        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom Left
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top Left
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color) % Bottom Right
    ],
    {ok, Mesh} = mesh3:with_vertices(Vertices),
    VertexCount = length(Vertices),
    shape3:with_mesh(Mesh, triangles, VertexCount).

-doc """
To be written.

To be written.
""".
-spec cube_wires(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    graphics:shape3()
.
cube_wires({X, Y, Z}, {Width, Height, Length}, Color) ->

    Vertices = [
        % Front face
        %------------------------------------------------------------------
        % Bottom line
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom right
        % Left line
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom right
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top right
        % Top line
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top left
        % Right line
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top left
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Bottom left

        % Back face
        %------------------------------------------------------------------
        % Bottom line
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom left
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom right
        % Left line
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom right
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top right
        % Top line
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top right
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top left
        % Right line
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top left
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Bottom left

        % Top face
        %------------------------------------------------------------------
        % Left line
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top left front
        ?VERTEX3({X - Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top left back
        % Right line
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z + Length/2.0}, Color), % Top right front
        ?VERTEX3({X + Width/2.0, Y + Height/2.0, Z - Length/2.0}, Color), % Top right back

        % Bottom face
        %------------------------------------------------------------------
        % Left line
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Top left front
        ?VERTEX3({X - Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color), % Top left back
        % Right line
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z + Length/2.0}, Color), % Top right front
        ?VERTEX3({X + Width/2.0, Y - Height/2.0, Z - Length/2.0}, Color)  % Top right back
    ],

    {ok, Mesh} = mesh3:with_vertices(Vertices),
    VertexCount = length(Vertices),
    shape3:with_mesh(Mesh, lines, VertexCount).

-doc """
To be written.

To be written.
""".
-spec sphere(
    graphics:vector3(),
    float(),
    graphics:color()
) ->
    graphics:shape3()
.
sphere(Center, Radius, Color) ->
    sphere(Center, Radius, 16, 16, Color).

-doc """
To be written.

To be written.
""".
-spec sphere(
    graphics:vector3(),
    float(),
    non_neg_integer(),
    non_neg_integer(),
    graphics:color()
) ->
    graphics:shape3()
.
sphere(Center, Radius, Rings, Slices, Color) ->
    % Angle between latitudinal parallels.
    RingAngle = ?ANGLE_180 / (Rings + 1),
    % Angle between longitudinal meridians.
    SliceAngle = ?ANGLE_360 / Slices,

    CosRing = math:cos(RingAngle),
    SinRing = math:sin(RingAngle),

    CosSlice = math:cos(SliceAngle),
    SinSlice = math:sin(SliceAngle),

    VertexA = {0.0, 0.0, 0.0},
    VertexB = {0.0, 0.0, 0.0},
    VertexC = {0.0, 1.0, 0.0},
    VertexD = {SinRing, CosRing, 0.0},

    {_, Vertices0} = lists:foldl(fun(_I, {{VertexA1, VertexB1, VertexC1, VertexD1}, Vertices1}) ->

        Result = lists:foldl(fun(_J, {{_VertexA2, _VertexB2, VertexC2, VertexD2}, Vertices2}) ->

            % Rotate around y axis to set up vertices for next face.
            NewVertexA2 = VertexC2,
            NewVertexB2 = VertexD2,
            % Rotation matrix around y axis.
            NewVertexC2 = {
                CosSlice*vector3:x(VertexC2) - SinSlice*vector3:z(VertexC2),
                vector3:y(VertexC2),
                SinSlice*vector3:x(VertexC2) + CosSlice*vector3:z(VertexC2)
            },
            NewVertexD2 = {
                CosSlice*vector3:x(VertexD2) - SinSlice*vector3:z(VertexD2),
                vector3:y(VertexD2),
                SinSlice*vector3:x(VertexD2) + CosSlice*vector3:z(VertexD2)
            },

            PickColor1 = many_colors:pick(),
            PickColor2 = many_colors:pick(),
            NewVertices2 = [
                ?VERTEX3(NewVertexA2, PickColor1),
                ?VERTEX3(NewVertexD2, PickColor1),
                ?VERTEX3(NewVertexB2, PickColor1),
                ?VERTEX3(NewVertexA2, PickColor2),
                ?VERTEX3(NewVertexC2, PickColor2),
                ?VERTEX3(NewVertexD2, PickColor2)
            |Vertices2],
            {{NewVertexA2, NewVertexB2, NewVertexC2, NewVertexD2}, NewVertices2}

        end, {{VertexA1, VertexB1, VertexC1, VertexD1}, Vertices1}, lists:seq(1, Slices)),
        {{VertexA3, VertexB3, _VertexC3, VertexD3}, Vertices3} = Result,

        % Rotate around z axis to set up  starting vertices for next ring.
        NewVertexC3 = VertexD3,

        % Rotation matrix around z axis.
        NewVertexD3 = {
            CosRing*vector3:x(VertexD3) + SinRing*vector3:y(VertexD3),
            -SinRing*vector3:x(VertexD3) + CosRing*vector3:y(VertexD3),
            vector3:z(VertexD3)
        },

        {{VertexA3, VertexB3, NewVertexC3, NewVertexD3}, Vertices3}
    end, {{VertexA, VertexB, VertexC, VertexD}, []}, lists:seq(1, Rings)),

    % XXX: The following can be optimized by combining matrices first.

    % Apply scale.
    ScaleMatrix = transform3:scale({Radius, Radius, Radius}),
    Vertices1 = lists:map(fun(Vertex) ->
        transform3:transform_vertex3(ScaleMatrix, Vertex)
    end, Vertices0),

    % Apply translation.
    TranslationMatrix = transform3:translation(Center),
    Vertices2 = lists:map(fun(Vertex) ->
        transform3:transform_vertex3(TranslationMatrix, Vertex)
    end, Vertices1),

    {ok, Mesh} = mesh3:with_vertices(lists:reverse(Vertices2)),
    VertexCount = length(Vertices2),
    shape3:with_mesh(Mesh, triangles, VertexCount).

-doc """
To be written.

To be written.
""".
-spec sphere_wires(
    graphics:vector3(),
    float(),
    graphics:color()
) -> #shape3{}.
sphere_wires(Center, Radius, Color) ->
    sphere_wires(Center, Radius, 16, 16, Color).

-doc """
To be written.

To be written.
""".
-spec sphere_wires(
    graphics:vector3(),
    float(),
    non_neg_integer(),
    non_neg_integer(),
    graphics:color()
) ->
    graphics:shape3()
.
sphere_wires(Center, Radius, Rings, Slices, Color) ->
    Vertices0 = lists:foldl(fun(I, Vertices1) ->
        lists:foldl(fun(J, Vertices2) ->
            VertexA1 = {
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*I) * math:sin(?ANGLE_360*J/Slices),
                math:sin(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*I),
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*I) * math:cos(?ANGLE_360*J/Slices)
            },
            VertexB1 = {
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:sin(?ANGLE_360*(J + 1)/Slices),
                math:sin(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)),
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:cos(?ANGLE_360*(J + 1)/Slices)
            },
            VertexC1 = {
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:sin(?ANGLE_360*(J + 1)/Slices),
                math:sin(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)),
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:cos(?ANGLE_360*(J + 1)/Slices)
            },
            VertexA2 = {
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:sin(?ANGLE_360*J/Slices),
                math:sin(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)),
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:cos(?ANGLE_360*J/Slices)
            },
            VertexB2 = {
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:sin(?ANGLE_360*J/Slices),
                math:sin(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)),
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*(I + 1)) * math:cos(?ANGLE_360*J/Slices)
            },
            VertexC2 = {
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*I) * math:sin(?ANGLE_360*J/Slices),
                math:sin(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*I),
                math:cos(?ANGLE_270 + (?ANGLE_180/(Rings + 1))*I) * math:cos(?ANGLE_360*J/Slices)
            },
            [
                ?VERTEX3(VertexA1, Color),
                ?VERTEX3(VertexB1, Color),
                ?VERTEX3(VertexC1, Color),
                ?VERTEX3(VertexA2, Color),
                ?VERTEX3(VertexB2, Color),
                ?VERTEX3(VertexC2, Color)
            | Vertices2]
        end, Vertices1, lists:seq(0, Slices-1))
    end, [], lists:seq(0, Rings+1)),

    % XXX: The following can be optimized by combining matrices first.

    % Apply scale.
    ScaleMatrix = transform3:scale({Radius, Radius, Radius}),
    Vertices1 = lists:map(fun(Vertex) ->
        transform3:transform_vertex3(ScaleMatrix, Vertex)
    end, Vertices0),

    % Apply translation.
    TranslationMatrix = transform3:translation(Center),
    Vertices2 = lists:map(fun(Vertex) ->
        transform3:transform_vertex3(TranslationMatrix, Vertex)
    end, Vertices1),

    {ok, Mesh} = mesh3:with_vertices(lists:reverse(Vertices2)),
    VertexCount = length(Vertices2),
    shape3:with_mesh(Mesh, lines, VertexCount).
