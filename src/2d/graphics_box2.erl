%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_box2).
-moduledoc """
2D Box

A 2D box is a pair of 2D vectors that is typically used to represent an
axis-aligned rectangle in the Euclidean plane.

The data structure of a 2D box simply is a tuple of two 2D vectors where the
first vector is the minimum corner and the second vector is the maximum corner.
Therefore, 2D boxes can be naturally created with the tuple syntax.

```erlang
Box = {{0.0, 0.0}, {10.0, 20.0}}.
```

To access the minimum corner of a 2D box, use the `min/1` function, and to
access the maximum corner, use the `max/1` function.

```erlang
{0.0, 0.0} = graphics_box2:min(Box).
{10.0, 20.0} = graphics_box2:max(Box).
```

A 2D box can also be constructed from a list of points, from the positions of
a list of 2D vertices, or from a center and a size.

```erlang
{{1.0, 2.0}, {5.0, 6.0}} = graphics_box2:from_points([{1.0, 2.0}, {5.0, 6.0}]).
{{-5.0, -10.0}, {5.0, 10.0}} = graphics_box2:from_center_size({0.0, 0.0}, {10.0, 20.0}).
```

The geometrical operations with 2D boxes are implemented. You can test whether
a point is inside a box, whether two boxes intersect, and compute their
intersection or union.

```erlang
true = graphics_box2:contains({{0.0, 0.0}, {10.0, 10.0}}, {5.0, 5.0}).
true = graphics_box2:intersects({{0.0, 0.0}, {2.0, 2.0}}, {{1.0, 1.0}, {3.0, 3.0}}).
```

To transform a 2D box with a 3x3 matrix, see the `graphics_transform2:transform_box/2`
function. A rotated box is a larger axis-aligned box, not a rotated rectangle.

Finally, a 2D box can be augmented to a 3D box with the `to_box3/1` function.

Beware that a well-formed 2D box always contains floats, not integers.
""".

-export([
    min/1, max/1
]).
-export([
    from_points/1,
    from_vertices/1,
    from_center_size/2
]).
-export([
    center/1,
    size/1,
    area/1,
    corners/1
]).
-export([
    contains/2,
    intersects/2,
    intersection/2
]).
-export([
    union/2,
    expand/2,
    translate/2
]).
-export([
    is_equal_to/2, is_equal_to/3
]).
-export([
    to_box3/1
]).

-compile({inline, [
    min/1, max/1
]}).

-doc """
The minimum corner of a 2D box.

It returns the minimum corner of the 2D box.
""".
-spec min(graphics:box2()) -> graphics:vector2().
min({Min, _}) ->
    Min.

-doc """
The maximum corner of a 2D box.

It returns the maximum corner of the 2D box.
""".
-spec max(graphics:box2()) -> graphics:vector2().
max({_, Max}) ->
    Max.

-doc """
A 2D box from a list of points.

It computes the axis-aligned bounding box of the given 2D points. The list
must contain at least one point. A single point yields a point box.

```erlang
{{1.0, 2.0}, {5.0, 6.0}} = graphics_box2:from_points([
    {1.0, 2.0},
    {5.0, 6.0},
    {3.0, 4.0}
]).
```
""".
-spec from_points([graphics:vector2()]) -> graphics:box2().
from_points([FirstPoint | RestPoints]) ->
    lists:foldl(fun(Point, {Min, Max}) ->
        {graphics_vector2:min(Min, Point), graphics_vector2:max(Max, Point)}
    end, {FirstPoint, FirstPoint}, RestPoints).

-doc """
A 2D box from a list of vertices.

It computes the axis-aligned bounding box of the positions of the given 2D
vertices. The list must contain at least one vertex. Color and UV coordinates
are ignored.
""".
-spec from_vertices([graphics:vertex2()]) -> graphics:box2().
from_vertices(Vertices) ->
    from_points(lists:map(fun({Position, _, _, _}) -> Position end, Vertices)).

-doc """
A 2D box from a center and a size.

It constructs a 2D box centered at the given 2D vector with the given size. The
size is the full width and height, not the half-extents. Negative size
components are taken in absolute value.

```erlang
{{-5.0, -10.0}, {5.0, 10.0}} = graphics_box2:from_center_size(
    {0.0, 0.0},
    {10.0, 20.0}
).
```
""".
-spec from_center_size(graphics:vector2(), graphics:vector2()) ->
    graphics:box2().
from_center_size(Center, Size) ->
    Half = graphics_vector2:multiply(graphics_vector2:abs(Size), 0.5),
    {graphics_vector2:subtract(Center, Half), graphics_vector2:add(Center, Half)}.

-doc """
The center of a 2D box.

It returns the center of a 2D box, which is the midpoint of the minimum and
maximum corners.
""".
-spec center(graphics:box2()) -> graphics:vector2().
center({Min, Max}) ->
    graphics_vector2:multiply(graphics_vector2:add(Min, Max), 0.5).

-doc """
The size of a 2D box.

It returns the size of a 2D box as a 2D vector whose components are the width
and the height.
""".
-spec size(graphics:box2()) -> graphics:vector2().
size({Min, Max}) ->
    graphics_vector2:subtract(Max, Min).

-doc """
The area of a 2D box.

It computes the area of a 2D box.
""".
-spec area(graphics:box2()) -> float().
area(Box) ->
    {Width, Height} = ?MODULE:size(Box),
    Width * Height.

-doc """
The corners of a 2D box.

It returns the four corners of a 2D box. The X component varies fastest, then
the Y component: `{MinX, MinY}`, `{MaxX, MinY}`, `{MinX, MaxY}`, `{MaxX, MaxY}`.
""".
-spec corners(graphics:box2()) -> [graphics:vector2()].
corners({{MinX, MinY}, {MaxX, MaxY}}) ->
    [
        {MinX, MinY}, {MaxX, MinY},
        {MinX, MaxY}, {MaxX, MaxY}
    ].

-doc """
Check whether a 2D box contains a point.

It returns `true` when the point is inside the box or on its boundary.
""".
-spec contains(graphics:box2(), graphics:vector2()) -> boolean().
contains({{MinX, MinY}, {MaxX, MaxY}}, {X, Y}) ->
    X >= MinX andalso X =< MaxX andalso Y >= MinY andalso Y =< MaxY.

-doc """
Check whether two 2D boxes intersect.

It returns `true` when the two 2D boxes overlap or touch.
""".
-spec intersects(graphics:box2(), graphics:box2()) -> boolean().
intersects({{MinX1, MinY1}, {MaxX1, MaxY1}}, {{MinX2, MinY2}, {MaxX2, MaxY2}}) ->
    not (MaxX1 < MinX2 orelse MinX1 > MaxX2 orelse MaxY1 < MinY2 orelse MinY1 > MaxY2).

-doc """
The intersection of two 2D boxes.

It returns `{ok, Box}` when the two 2D boxes overlap or touch, and
`{error, disjoint}` when they are disjoint. Boxes that touch at an edge or a
corner return a degenerate box with zero area.
""".
-spec intersection(graphics:box2(), graphics:box2()) ->
    {ok, graphics:box2()} | {error, disjoint}.
intersection({Min1, Max1}, {Min2, Max2}) ->
    Min = graphics_vector2:max(Min1, Min2),
    Max = graphics_vector2:min(Max1, Max2),
    {MinX, MinY} = Min,
    {MaxX, MaxY} = Max,
    case MinX =< MaxX andalso MinY =< MaxY of
        true ->
            {ok, {Min, Max}};
        false ->
            {error, disjoint}
    end.

-doc """
The union of two 2D boxes.

It returns the smallest 2D box that contains both 2D boxes.
""".
-spec union(graphics:box2(), graphics:box2()) -> graphics:box2().
union({Min1, Max1}, {Min2, Max2}) ->
    {graphics_vector2:min(Min1, Min2), graphics_vector2:max(Max1, Max2)}.

-doc """
Expand a 2D box to include a point.

It returns a 2D box that contains both the given 2D box and the given 2D
point.
""".
-spec expand(graphics:box2(), graphics:vector2()) -> graphics:box2().
expand({Min, Max}, Point) ->
    {graphics_vector2:min(Min, Point), graphics_vector2:max(Max, Point)}.

-doc """
Translate a 2D box.

It translates a 2D box by the given 2D vector. Both corners are translated.
""".
-spec translate(graphics:box2(), graphics:vector2()) -> graphics:box2().
translate({Min, Max}, Vector) ->
    {graphics_vector2:add(Min, Vector), graphics_vector2:add(Max, Vector)}.

-doc """
Check whether two 2D boxes are equal.

It returns `true` when both corners compare equal. The values `+0.0` and
`-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:box2(), graphics:box2()) -> boolean().
is_equal_to({Min1, Max1}, {Min2, Max2}) ->
    graphics_vector2:is_equal_to(Min1, Min2) andalso graphics_vector2:is_equal_to(Max1, Max2).

-doc """
Check whether two 2D boxes are equal within an epsilon.

It returns `true` when each pair of corresponding corner components differs by
at most `Epsilon`.
""".
-spec is_equal_to(graphics:box2(), graphics:box2(), float()) -> boolean().
is_equal_to({Min1, Max1}, {Min2, Max2}, Epsilon) ->
    graphics_vector2:is_equal_to(Min1, Min2, Epsilon)
        andalso graphics_vector2:is_equal_to(Max1, Max2, Epsilon).

-doc """
Augment a 2D box.

It augments a 2D box to a 3D box. The Z component of both corners is set to
0.0.
""".
-spec to_box3(graphics:box2()) -> graphics:box3().
to_box3({{MinX, MinY}, {MaxX, MaxY}}) ->
    {{MinX, MinY, 0.0}, {MaxX, MaxY, 0.0}}.
