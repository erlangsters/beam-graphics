%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_box3).
-moduledoc """
3D Box

A 3D box is a pair of 3D vectors that is typically used to represent an
axis-aligned rectangular prism in the Euclidean space.

The data structure of a 3D box simply is a tuple of two 3D vectors where the
first vector is the minimum corner and the second vector is the maximum corner.
Therefore, 3D boxes can be naturally created with the tuple syntax.

```erlang
Box = {{0.0, 0.0, 0.0}, {10.0, 20.0, 30.0}}.
```

To access the minimum corner of a 3D box, use the `min/1` function, and to
access the maximum corner, use the `max/1` function.

```erlang
{0.0, 0.0, 0.0} = graphics_box3:min(Box).
{10.0, 20.0, 30.0} = graphics_box3:max(Box).
```

A 3D box can also be constructed from a list of points, from the positions of
a list of 3D vertices, or from a center and a size.

```erlang
{{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}} = graphics_box3:from_points([
    {1.0, 2.0, 3.0},
    {5.0, 6.0, 7.0}
]).
{{-5.0, -10.0, -15.0}, {5.0, 10.0, 15.0}} = graphics_box3:from_center_size(
    {0.0, 0.0, 0.0},
    {10.0, 20.0, 30.0}
).
```

The geometrical operations with 3D boxes are implemented. You can test whether
a point is inside a box, whether two boxes intersect, and compute their
intersection or union.

```erlang
true = graphics_box3:contains({{0.0, 0.0, 0.0}, {10.0, 10.0, 10.0}}, {5.0, 5.0, 5.0}).
true = graphics_box3:intersects(
    {{0.0, 0.0, 0.0}, {2.0, 2.0, 2.0}},
    {{1.0, 1.0, 1.0}, {3.0, 3.0, 3.0}}
).
```

To transform a 3D box with a 4x4 matrix, see the `graphics_transform3:transform_box/2`
function. A rotated box is a larger axis-aligned box, not a rotated rectangular
prism.

Finally, a 3D box can be reduced to a 2D box with the `to_box2/1` function.

Beware that a well-formed 3D box always contains floats, not integers.
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
    volume/1,
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
    to_box2/1
]).

-compile({inline, [
    min/1, max/1
]}).

-doc """
The minimum corner of a 3D box.

It returns the minimum corner of the 3D box.
""".
-spec min(graphics:box3()) -> graphics:vector3().
min({Min, _}) ->
    Min.

-doc """
The maximum corner of a 3D box.

It returns the maximum corner of the 3D box.
""".
-spec max(graphics:box3()) -> graphics:vector3().
max({_, Max}) ->
    Max.

-doc """
A 3D box from a list of points.

It computes the axis-aligned bounding box of the given 3D points. The list
must contain at least one point. A single point yields a point box.

```erlang
{{1.0, 2.0, 3.0}, {5.0, 6.0, 7.0}} = graphics_box3:from_points([
    {1.0, 2.0, 3.0},
    {5.0, 6.0, 7.0},
    {3.0, 4.0, 5.0}
]).
```
""".
-spec from_points([graphics:vector3()]) -> graphics:box3().
from_points([FirstPoint | RestPoints]) ->
    lists:foldl(fun(Point, {Min, Max}) ->
        {graphics_vector3:min(Min, Point), graphics_vector3:max(Max, Point)}
    end, {FirstPoint, FirstPoint}, RestPoints).

-doc """
A 3D box from a list of vertices.

It computes the axis-aligned bounding box of the positions of the given 3D
vertices. The list must contain at least one vertex. Color and UV coordinates
are ignored.
""".
-spec from_vertices([graphics:vertex3()]) -> graphics:box3().
from_vertices(Vertices) ->
    from_points(lists:map(fun({Position, _, _, _}) -> Position end, Vertices)).

-doc """
A 3D box from a center and a size.

It constructs a 3D box centered at the given 3D vector with the given size. The
size is the full width, height, and depth, not the half-extents. Negative size
components are taken in absolute value.

```erlang
{{-5.0, -10.0, -15.0}, {5.0, 10.0, 15.0}} = graphics_box3:from_center_size(
    {0.0, 0.0, 0.0},
    {10.0, 20.0, 30.0}
).
```
""".
-spec from_center_size(graphics:vector3(), graphics:vector3()) ->
    graphics:box3().
from_center_size(Center, Size) ->
    Half = graphics_vector3:multiply(graphics_vector3:abs(Size), 0.5),
    {graphics_vector3:subtract(Center, Half), graphics_vector3:add(Center, Half)}.

-doc """
The center of a 3D box.

It returns the center of a 3D box, which is the midpoint of the minimum and
maximum corners.
""".
-spec center(graphics:box3()) -> graphics:vector3().
center({Min, Max}) ->
    graphics_vector3:multiply(graphics_vector3:add(Min, Max), 0.5).

-doc """
The size of a 3D box.

It returns the size of a 3D box as a 3D vector whose components are the width,
the height, and the depth.
""".
-spec size(graphics:box3()) -> graphics:vector3().
size({Min, Max}) ->
    graphics_vector3:subtract(Max, Min).

-doc """
The volume of a 3D box.

It computes the volume of a 3D box.
""".
-spec volume(graphics:box3()) -> float().
volume(Box) ->
    {Width, Height, Depth} = ?MODULE:size(Box),
    Width * Height * Depth.

-doc """
The corners of a 3D box.

It returns the eight corners of a 3D box. The X component varies fastest, then
the Y component, then the Z component.
""".
-spec corners(graphics:box3()) -> [graphics:vector3()].
corners({{MinX, MinY, MinZ}, {MaxX, MaxY, MaxZ}}) ->
    [
        {MinX, MinY, MinZ}, {MaxX, MinY, MinZ},
        {MinX, MaxY, MinZ}, {MaxX, MaxY, MinZ},
        {MinX, MinY, MaxZ}, {MaxX, MinY, MaxZ},
        {MinX, MaxY, MaxZ}, {MaxX, MaxY, MaxZ}
    ].

-doc """
Check whether a 3D box contains a point.

It returns `true` when the point is inside the box or on its boundary.
""".
-spec contains(graphics:box3(), graphics:vector3()) -> boolean().
contains({{MinX, MinY, MinZ}, {MaxX, MaxY, MaxZ}}, {X, Y, Z}) ->
    X >= MinX andalso X =< MaxX
        andalso Y >= MinY andalso Y =< MaxY
        andalso Z >= MinZ andalso Z =< MaxZ.

-doc """
Check whether two 3D boxes intersect.

It returns `true` when the two 3D boxes overlap or touch.
""".
-spec intersects(graphics:box3(), graphics:box3()) -> boolean().
intersects(
    {{MinX1, MinY1, MinZ1}, {MaxX1, MaxY1, MaxZ1}},
    {{MinX2, MinY2, MinZ2}, {MaxX2, MaxY2, MaxZ2}}
) ->
    not (
        MaxX1 < MinX2 orelse MinX1 > MaxX2
            orelse MaxY1 < MinY2 orelse MinY1 > MaxY2
            orelse MaxZ1 < MinZ2 orelse MinZ1 > MaxZ2
    ).

-doc """
The intersection of two 3D boxes.

It returns `{ok, Box}` when the two 3D boxes overlap or touch, and
`{error, disjoint}` when they are disjoint. Boxes that touch at a face, an
edge, or a corner return a degenerate box with zero volume.
""".
-spec intersection(graphics:box3(), graphics:box3()) ->
    {ok, graphics:box3()} | {error, disjoint}.
intersection({Min1, Max1}, {Min2, Max2}) ->
    Min = graphics_vector3:max(Min1, Min2),
    Max = graphics_vector3:min(Max1, Max2),
    {MinX, MinY, MinZ} = Min,
    {MaxX, MaxY, MaxZ} = Max,
    case MinX =< MaxX andalso MinY =< MaxY andalso MinZ =< MaxZ of
        true ->
            {ok, {Min, Max}};
        false ->
            {error, disjoint}
    end.

-doc """
The union of two 3D boxes.

It returns the smallest 3D box that contains both 3D boxes.
""".
-spec union(graphics:box3(), graphics:box3()) -> graphics:box3().
union({Min1, Max1}, {Min2, Max2}) ->
    {graphics_vector3:min(Min1, Min2), graphics_vector3:max(Max1, Max2)}.

-doc """
Expand a 3D box to include a point.

It returns a 3D box that contains both the given 3D box and the given 3D
point.
""".
-spec expand(graphics:box3(), graphics:vector3()) -> graphics:box3().
expand({Min, Max}, Point) ->
    {graphics_vector3:min(Min, Point), graphics_vector3:max(Max, Point)}.

-doc """
Translate a 3D box.

It translates a 3D box by the given 3D vector. Both corners are translated.
""".
-spec translate(graphics:box3(), graphics:vector3()) -> graphics:box3().
translate({Min, Max}, Vector) ->
    {graphics_vector3:add(Min, Vector), graphics_vector3:add(Max, Vector)}.

-doc """
Check whether two 3D boxes are equal.

It returns `true` when both corners compare equal. The values `+0.0` and
`-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:box3(), graphics:box3()) -> boolean().
is_equal_to({Min1, Max1}, {Min2, Max2}) ->
    graphics_vector3:is_equal_to(Min1, Min2) andalso graphics_vector3:is_equal_to(Max1, Max2).

-doc """
Check whether two 3D boxes are equal within an epsilon.

It returns `true` when each pair of corresponding corner components differs by
at most `Epsilon`.
""".
-spec is_equal_to(graphics:box3(), graphics:box3(), float()) -> boolean().
is_equal_to({Min1, Max1}, {Min2, Max2}, Epsilon) ->
    graphics_vector3:is_equal_to(Min1, Min2, Epsilon)
        andalso graphics_vector3:is_equal_to(Max1, Max2, Epsilon).

-doc """
Reduce a 3D box.

It reduces a 3D box to a 2D box. The Z component of both corners is discarded.
""".
-spec to_box2(graphics:box3()) -> graphics:box2().
to_box2({{MinX, MinY, _}, {MaxX, MaxY, _}}) ->
    {{MinX, MinY}, {MaxX, MaxY}}.
