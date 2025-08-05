%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape2).
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
    rectangle/3,
    rectangle_outline/4
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
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count()
) ->
    graphics:shape2()
.
with_mesh(Mesh, PrimitiveType, VertexCount) ->
    with_mesh(Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
To be written.

To be written.
""".
-spec with_mesh(
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) ->
    graphics:shape2()
.
with_mesh(Mesh, PrimitiveType, VertexCount, Texture) ->
    #shape2{
        meshes = [{Mesh, PrimitiveType, VertexCount}],
        texture = Texture
    }.

-doc """
To be written.

To be written.
""".
-spec with_meshes(
    [{graphics:mesh2(), graphics:primitive_type(), graphics:vertex_count()}]
) ->
    graphics:shape2()
.
with_meshes(Meshes) ->
    with_meshes(Meshes, no_texture).

-doc """
To be written.

To be written.
""".
-spec with_meshes(
    [{graphics:mesh2(), graphics:primitive_type(), graphics:vertex_count()}],
    no_texture | graphics:texture()
) ->
    graphics:shape2()
.
with_meshes(Meshes, Texture) ->
    #shape2{
        meshes = Meshes,
        texture = Texture
    }.

-doc """
To be written.

To be written.
""".
-spec destroy(graphics:shape2()) -> ok.
destroy(#shape2{meshes = Meshes}) ->
    lists:foreach(fun({Mesh, _PrimitiveType, _VertexCount}) ->
        mesh2:destroy(Mesh)
    end, Meshes).

-doc """
To be written.

To be written.
""".
-spec point(graphics:vector2(), graphics:color()) -> graphics:shape2().
point(Position, Color) ->
    {ok, Mesh} = mesh2:with_vertices([?VERTEX2(Position, Color)]),
    shape2:with_mesh(Mesh, points, 1).

-doc """
To be written.

To be written.
""".
-spec line(
    graphics:vector2(),
    graphics:vector2(),
    graphics:color()
) ->
    graphics:shape2()
.
line(From, To, Color) ->
    {ok, Mesh} = mesh2:with_vertices([
        ?VERTEX2(From, Color),
        ?VERTEX2(To, Color)
    ]),
    shape2:with_mesh(Mesh, lines, 2).

-doc """
To be written.

To be written.
""".
-spec triangle(
    graphics:vector2(),
    graphics:vector2(),
    graphics:vector2(),
    graphics:color()
) ->
    graphics:shape2()
.
triangle(A, B, C, Color) ->
    {ok, Mesh} = mesh2:with_vertices([
        ?VERTEX2(A, Color),
        ?VERTEX2(B, Color),
        ?VERTEX2(C, Color)
    ]),
    shape2:with_mesh(Mesh, triangles, 3).

-doc """
To be written.

To be written.
""".
-spec rectangle(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Color :: graphics:color()
) -> graphics:shape2().
rectangle({X, Y}, {Width, Height}, Color) ->
    {ok, Mesh} = mesh2:with_vertices([
        ?VERTEX2({X,         Y},          Color),
        ?VERTEX2({X + Width, Y},          Color),
        ?VERTEX2({X + Width, Y + Height}, Color),
        ?VERTEX2({X,         Y + Height}, Color)
    ]),
    shape2:with_mesh(Mesh, triangle_fan, 4).

-doc """
To be written.

To be written.
""".
-spec rectangle_outline(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Thickness :: float(),
    Color :: graphics:color()
) -> graphics:shape2().
rectangle_outline({X, Y}, {Width, Height}, Thickness, Color) ->
    % XXX: The outline points inwards (regardless of the sign of the thickness.
    %      Should it support both directions?
    OuterX0 = X,
    OuterY0 = Y,
    OuterX1 = X + Width,
    OuterY1 = Y + Height,

    % Determine direction of thickness
    Sign = if Thickness > 0 -> 1; true -> -1 end,
    AbsT = erlang:abs(Thickness),

    % For positive thickness, outline grows "outwards" (Y+AbsT), for negative "inwards" (Y-AbsT)
    InnerX0 = X + Sign * AbsT,
    InnerY0 = Y + Sign * AbsT,
    InnerX1 = X + Width - Sign * AbsT,
    InnerY1 = Y + Height - Sign * AbsT,

    % Vertices for the outline as a triangle strip (8 vertices, 4 corners, 2 per corner)
    {ok, Mesh} = mesh2:with_vertices([
        ?VERTEX2({OuterX0, OuterY0}, Color), % Outer TL
        ?VERTEX2({InnerX0, InnerY0}, Color), % Inner TL

        ?VERTEX2({OuterX1, OuterY0}, Color), % Outer TR
        ?VERTEX2({InnerX1, InnerY0}, Color), % Inner TR

        ?VERTEX2({OuterX1, OuterY1}, Color), % Outer BR
        ?VERTEX2({InnerX1, InnerY1}, Color), % Inner BR

        ?VERTEX2({OuterX0, OuterY1}, Color), % Outer BL
        ?VERTEX2({InnerX0, InnerY1}, Color), % Inner BL

        ?VERTEX2({OuterX0, OuterY0}, Color), % Repeat Outer TL
        ?VERTEX2({InnerX0, InnerY0}, Color)  % Repeat Inner TL
    ]),

    % Use triangle_strip for the outline
    shape2:with_mesh(Mesh, triangle_strip, 10).

-doc """
To be written.

To be written.
""".
-spec circle(
) -> graphics:shape2().
circle() ->
    ok.

-doc """
To be written.

To be written.
""".
-spec circle_outline(
) -> graphics:shape2().
circle_outline() ->
    ok.

-doc """
To be written.

To be written.
""".
-spec rectangle_wire(
) -> graphics:shape2().
rectangle_wire() ->
    ok.

-doc """
To be written.

To be written.
""".
-spec circle_wire(
) -> graphics:shape2().
circle_wire() ->
    ok.
