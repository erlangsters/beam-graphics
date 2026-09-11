%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(camera2).
-moduledoc """
2D Camera

A 2D camera is a center, a rotation, and a zoom that is typically used to
represent an observer in the Euclidean plane.

The data structure of a 2D camera simply is a tuple of a 2D vector, an angle,
and a float. Therefore, 2D cameras can be naturally created with the tuple
syntax.

```erlang
Camera = {{0.0, 0.0}, 0.0, 1.0}.
```

To access the center of a 2D camera, use the `center/1` function, to access
the rotation, use the `rotation/1` function, and to access the zoom, use the
`zoom/1` function.

```erlang
{0.0, 0.0} = camera2:center(Camera).
0.0 = camera2:rotation(Camera).
1.0 = camera2:zoom(Camera).
```

A 2D camera can also be constructed from a center, or from a center, a
rotation, and a zoom. `from_center/1` uses a rotation of `0.0` and a zoom of
`1.0`. Rotation is counter-clockwise in the world, matching `vector2:rotate/2`.
Zoom greater than `1.0` makes objects appear larger.

```erlang
{{10.0, 20.0}, 0.0, 1.0} = camera2:from_center({10.0, 20.0}).
```

The view matrix of a 2D camera is constructed with the `view_matrix/1`
function. Combined with a 2D view (see `view2`), it maps world space to clip
space.

Beware that a well-formed 2D camera always contains floats, not integers.
""".

-export([
    from_center/1, from_center/3
]).
-export([
    center/1, rotation/1, zoom/1
]).
-export([
    view_matrix/1
]).
-export([
    translate/2
]).
-export([
    is_equal_to/2, is_equal_to/3
]).

-compile({inline, [
    center/1, rotation/1, zoom/1
]}).

-doc """
A 2D camera from a center.

It constructs a 2D camera centered at the given 2D vector, with no rotation
and a zoom of `1.0`.
""".
-spec from_center(graphics:vector2()) -> graphics:camera2().
from_center(Center) ->
    from_center(Center, 0.0, 1.0).

-doc """
A 2D camera from a center, a rotation, and a zoom.

It constructs a 2D camera centered at the given 2D vector, with the given
rotation in radians and the given zoom. Rotation is counter-clockwise in the
world. Zoom greater than `1.0` makes objects appear larger.
""".
-spec from_center(graphics:vector2(), graphics:angle(), float()) ->
    graphics:camera2().
from_center(Center, Rotation, Zoom) ->
    {Center, Rotation, Zoom}.

-doc """
The center of a 2D camera.

It returns the center of the 2D camera, which is the world point that maps to
the origin of view space.
""".
-spec center(graphics:camera2()) -> graphics:vector2().
center({Center, _, _}) ->
    Center.

-doc """
The rotation of a 2D camera.

It returns the rotation of the 2D camera in radians.
""".
-spec rotation(graphics:camera2()) -> graphics:angle().
rotation({_, Rotation, _}) ->
    Rotation.

-doc """
The zoom of a 2D camera.

It returns the zoom of the 2D camera.
""".
-spec zoom(graphics:camera2()) -> float().
zoom({_, _, Zoom}) ->
    Zoom.

-doc """
The view matrix of a 2D camera.

It constructs the 3x3 view matrix of the 2D camera. The center is mapped to
the origin, then rotated by the opposite of the camera rotation, then scaled
by the zoom.
""".
-spec view_matrix(graphics:camera2()) -> graphics:matrix3().
view_matrix({Center, Rotation, Zoom}) ->
    matrix3:multiply(
        transform2:scale({Zoom, Zoom}),
        matrix3:multiply(
            transform2:rotation(-Rotation),
            transform2:translation(vector2:negate(Center))
        )
    ).

-doc """
Translate a 2D camera.

It translates a 2D camera by the given 2D vector. The center is translated.
The rotation and the zoom are left unchanged.
""".
-spec translate(graphics:camera2(), graphics:vector2()) -> graphics:camera2().
translate({Center, Rotation, Zoom}, Vector) ->
    {vector2:add(Center, Vector), Rotation, Zoom}.

-doc """
Check whether two 2D cameras are equal.

It returns `true` when the center, the rotation, and the zoom compare equal.
The values `+0.0` and `-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:camera2(), graphics:camera2()) -> boolean().
is_equal_to({Center1, Rotation1, Zoom1}, {Center2, Rotation2, Zoom2}) ->
    vector2:is_equal_to(Center1, Center2)
        andalso Rotation1 == Rotation2
        andalso Zoom1 == Zoom2.

-doc """
Check whether two 2D cameras are equal within an epsilon.

It returns `true` when the centers differ by at most `Epsilon` per component
and the rotations and zooms each differ by at most `Epsilon`.
""".
-spec is_equal_to(graphics:camera2(), graphics:camera2(), float()) -> boolean().
is_equal_to({Center1, Rotation1, Zoom1}, {Center2, Rotation2, Zoom2}, Epsilon) ->
    vector2:is_equal_to(Center1, Center2, Epsilon)
        andalso abs(Rotation1 - Rotation2) =< Epsilon
        andalso abs(Zoom1 - Zoom2) =< Epsilon.
