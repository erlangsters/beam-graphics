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
    triangle_wires/4
]).
-export([
    rectangle/3,
    rectangle_outline/4
]).
-export([
    circle/3, circle/4,
    circle_outline/4, circle_outline/5
]).
-export([
    rectangle_wires/3,
    circle_wires/3, circle_wires/4
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
-compile({inline, [
    triangle_wires/4
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DEFAULT_CIRCLE_SEGMENTS, 32).

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
-spec triangle_wires(
    graphics:vector2(),
    graphics:vector2(),
    graphics:vector2(),
    graphics:color()
) ->
    graphics:shape2()
.
triangle_wires(A, B, C, Color) ->
    {ok, Mesh} = mesh2:with_vertices([
        ?VERTEX2(A, Color),
        ?VERTEX2(B, Color),
        ?VERTEX2(C, Color)
    ]),
    shape2:with_mesh(Mesh, line_loop, 3).

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
    Center :: graphics:vector2(),
    Radius :: float(),
    Color :: graphics:color()
) -> graphics:shape2().
circle(Center, Radius, Color) ->
    circle(Center, Radius, ?DEFAULT_CIRCLE_SEGMENTS, Color).

-doc """
To be written.

To be written.
""".
-spec circle(
    Center :: graphics:vector2(),
    Radius :: float(),
    Segments :: non_neg_integer(),
    Color :: graphics:color()
) -> graphics:shape2().
circle({X, Y}, Radius, Segments, Color) ->
    AngleStep = (2 * math:pi()) / Segments,
    Vertices = [
        ?VERTEX2({X, Y}, Color)  % Center vertex for triangle fan
        | [
            ?VERTEX2(
                {X + Radius * math:cos(AngleStep * I), Y + Radius * math:sin(AngleStep * I)},
                Color
            )
            || I <- lists:seq(0, Segments)
        ]
    ],
    {ok, Mesh} = mesh2:with_vertices(Vertices),
    shape2:with_mesh(Mesh, triangle_fan, Segments + 2).

-doc """
To be written.

To be written.
""".
-spec circle_outline(
    Center :: graphics:vector2(),
    Radius :: float(),
    Thickness :: float(),
    Color :: graphics:color()
) -> graphics:shape2().
circle_outline(Center, Radius, Thickness, Color) ->
    circle_outline(Center, Radius, ?DEFAULT_CIRCLE_SEGMENTS, Thickness, Color).

-doc """
To be written.

To be written.
""".
-spec circle_outline(
    Center :: graphics:vector2(),
    Radius :: float(),
    Segments :: non_neg_integer(),
    Thickness :: float(),
    Color :: graphics:color()
) -> graphics:shape2().
circle_outline({X, Y}, Radius, Segments, Thickness, Color) ->
    AbsT = erlang:abs(Thickness),
    InnerRadius = Radius - AbsT,
    AngleStep = (2 * math:pi()) / Segments,
    % Build vertices for a triangle strip: outer, inner, outer, inner, ...
    Vertices = lists:flatten([
        [
            ?VERTEX2(
                {X + Radius * math:cos(AngleStep * I), Y + Radius * math:sin(AngleStep * I)},
                Color
            ),
            ?VERTEX2(
                {X + InnerRadius * math:cos(AngleStep * I), Y + InnerRadius * math:sin(AngleStep * I)},
                Color
            )
        ]
        || I <- lists:seq(0, Segments)
    ]),
    % Close the strip by repeating the first two vertices
    VerticesClosed = Vertices ++ [
        ?VERTEX2({X + Radius * math:cos(0), Y + Radius * math:sin(0)}, Color),
        ?VERTEX2({X + InnerRadius * math:cos(0), Y + InnerRadius * math:sin(0)}, Color)
    ],
    {ok, Mesh} = mesh2:with_vertices(VerticesClosed),
    shape2:with_mesh(Mesh, triangle_strip, length(VerticesClosed)).

-doc """
To be written.

To be written.
""".
-spec rectangle_wires(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Color :: graphics:color()
) -> graphics:shape2().
rectangle_wires({X, Y}, {Width, Height}, Color) ->
    % Rectangle corners in order: TL, TR, BR, BL
    Vertices = [
        ?VERTEX2({X,         Y},          Color), % Top-left
        ?VERTEX2({X + Width, Y},          Color), % Top-right
        ?VERTEX2({X + Width, Y + Height}, Color), % Bottom-right
        ?VERTEX2({X,         Y + Height}, Color)  % Bottom-left
    ],
    {ok, Mesh} = mesh2:with_vertices(Vertices),
    % Use line_loop to connect all corners and close the rectangle
    shape2:with_mesh(Mesh, line_loop, 4).

-doc """
To be written.

To be written.
""".
-spec circle_wires(
    Center :: graphics:vector2(),
    Radius :: float(),
    Color :: graphics:color()
) -> graphics:shape2().
circle_wires(Center, Radius, Color) ->
    circle_wires(Center, Radius, ?DEFAULT_CIRCLE_SEGMENTS, Color).

-doc """
To be written.

To be written.
""".
-spec circle_wires(
    Center :: graphics:vector2(),
    Radius :: float(),
    Segments :: non_neg_integer(),
    Color :: graphics:color()
) -> graphics:shape2().
circle_wires({X, Y}, Radius, Segments, Color) ->
    AngleStep = (2 * math:pi()) / Segments,
    Vertices = [
        ?VERTEX2(
            {X + Radius * math:cos(AngleStep * I), Y + Radius * math:sin(AngleStep * I)},
            Color
        )
        || I <- lists:seq(0, Segments - 1)
    ],
    {ok, Mesh} = mesh2:with_vertices(Vertices),
    shape2:with_mesh(Mesh, line_loop, Segments).
