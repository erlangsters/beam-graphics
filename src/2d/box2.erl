%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(box2).
-moduledoc """
2D Axis-aligned Bounding Box (AABB).

To be written.
""".

-export([
    from_points/1,
    from_vertices/1
]).
-export([
    contains/2,
    intersects/2
    % find_intersection/2,
    % center/1
]).

-doc """
Creates a 2D box from a list of points.

It computes the minimum and maximum points of the list of points and returns
the bounding box that contains all the points.
""".
-spec from_points([graphics:vector2()]) -> graphics:box2().
from_points([FirstPoint | RestPoints]) ->
    lists:foldl(fun(Point, {Min, Max}) ->
        {vector2:min(Min, Point), vector2:max(Max, Point)}
    end, {FirstPoint, FirstPoint}, RestPoints).

-doc """
Creates a 2D box from a list of vertices.

Same from `from_points/1` but it extracts the position of the vertices.
""".
-spec from_vertices([graphics:vertex2()]) -> graphics:box2().
from_vertices(Vertices) ->
    Points = lists:map(fun(Vertex) -> vertex2:position(Vertex) end, Vertices),
    from_points(Points).

-doc """
Checks if a point is inside a box.

It returns true if the point is inside the box, false otherwise.
""".
-spec contains(graphics:box2(), graphics:vector2()) -> boolean().
contains({{MinX, MinY}, {MaxX, MaxY}}, {X, Y}) ->
    X >= MinX andalso X =< MaxX andalso Y >= MinY andalso Y =< MaxY.

-doc """
Checks if two boxes intersect.

It returns true if the two boxes intersect, false otherwise.
""".
-spec intersects(graphics:box2(), graphics:box2()) -> boolean().
intersects({{MinX1, MinY1}, {MaxX1, MaxY1}}, {{MinX2, MinY2}, {MaxX2, MaxY2}}) ->
    not (MaxX1 < MinX2 orelse MinX1 > MaxX2 orelse MaxY1 < MinY2 orelse MinY1 > MaxY2).
