%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(camera3).
-moduledoc """
3D Camera

A 3D camera is a position, a target, and an up vector that is typically used
to represent an observer in the Euclidean space.

The data structure of a 3D camera simply is a tuple of three 3D vectors.
Therefore, 3D cameras can be naturally created with the tuple syntax.

```erlang
Camera = {{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}}.
```

To access the position of a 3D camera, use the `position/1` function, to
access the target, use the `target/1` function, and to access the up vector,
use the `up/1` function.

```erlang
{0.0, 0.0, 5.0} = camera3:position(Camera).
{0.0, 0.0, 0.0} = camera3:target(Camera).
{0.0, 1.0, 0.0} = camera3:up(Camera).
```

A 3D camera can also be constructed from a position and a target, or from a
position, a target, and an up vector. `look_at/2` uses the up vector
`{0.0, 1.0, 0.0}`. `look_to/2` and `look_to/3` take a direction instead of a
target.

```erlang
{{0.0, 0.0, 5.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}} = camera3:look_at(
    {0.0, 0.0, 5.0},
    {0.0, 0.0, 0.0}
).
```

The view matrix of a 3D camera is constructed with the `view_matrix/1`
function. Combined with a 3D view (see `view3`), it maps world space to clip
space. The camera looks down the negative Z axis in view space.

Beware that a well-formed 3D camera always contains floats, not integers.
""".

-export([
    look_at/2, look_at/3,
    look_to/2, look_to/3
]).
-export([
    position/1, target/1, up/1
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
    position/1, target/1, up/1
]}).

-doc """
A 3D camera looking at a target.

It constructs a 3D camera at `Position` looking at `Target`. The up vector is
`{0.0, 1.0, 0.0}`.
""".
-spec look_at(graphics:vector3(), graphics:vector3()) -> graphics:camera3().
look_at(Position, Target) ->
    look_at(Position, Target, {0.0, 1.0, 0.0}).

-doc """
A 3D camera looking at a target with an up vector.

It constructs a 3D camera at `Position` looking at `Target` with the given up
vector. The up vector need not be unit or orthogonal to the look direction;
`view_matrix/1` orthonormalizes it.
""".
-spec look_at(graphics:vector3(), graphics:vector3(), graphics:vector3()) ->
    graphics:camera3().
look_at(Position, Target, Up) ->
    {Position, Target, Up}.

-doc """
A 3D camera looking along a direction.

It constructs a 3D camera at `Position` looking along `Direction`. The target
is `Position` plus `Direction`. The up vector is `{0.0, 1.0, 0.0}`.
""".
-spec look_to(graphics:vector3(), graphics:vector3()) -> graphics:camera3().
look_to(Position, Direction) ->
    look_to(Position, Direction, {0.0, 1.0, 0.0}).

-doc """
A 3D camera looking along a direction with an up vector.

It constructs a 3D camera at `Position` looking along `Direction` with the
given up vector. The target is `Position` plus `Direction`.
""".
-spec look_to(graphics:vector3(), graphics:vector3(), graphics:vector3()) ->
    graphics:camera3().
look_to(Position, Direction, Up) ->
    look_at(Position, vector3:add(Position, Direction), Up).

-doc """
The position of a 3D camera.

It returns the position of the 3D camera, which is the eye point.
""".
-spec position(graphics:camera3()) -> graphics:vector3().
position({Position, _, _}) ->
    Position.

-doc """
The target of a 3D camera.

It returns the target of the 3D camera, which is the point the camera looks
at.
""".
-spec target(graphics:camera3()) -> graphics:vector3().
target({_, Target, _}) ->
    Target.

-doc """
The up vector of a 3D camera.

It returns the up vector of the 3D camera.
""".
-spec up(graphics:camera3()) -> graphics:vector3().
up({_, _, Up}) ->
    Up.

-doc """
The view matrix of a 3D camera.

It constructs the 4x4 view matrix of the 3D camera. The camera looks down the
negative Z axis in view space. The up vector is orthonormalized.
""".
-spec view_matrix(graphics:camera3()) -> graphics:matrix4().
view_matrix({Position, Target, Up}) ->
    ZAxis = vector3:normalize(vector3:subtract(Position, Target)),
    XAxis = vector3:normalize(vector3:cross_product(Up, ZAxis)),
    YAxis = vector3:cross_product(ZAxis, XAxis),
    NegEyeX = -vector3:dot_product(Position, XAxis),
    NegEyeY = -vector3:dot_product(Position, YAxis),
    NegEyeZ = -vector3:dot_product(Position, ZAxis),
    {
        vector3:x(XAxis), vector3:x(YAxis), vector3:x(ZAxis), 0.0,
        vector3:y(XAxis), vector3:y(YAxis), vector3:y(ZAxis), 0.0,
        vector3:z(XAxis), vector3:z(YAxis), vector3:z(ZAxis), 0.0,
        NegEyeX, NegEyeY, NegEyeZ, 1.0
    }.

-doc """
Translate a 3D camera.

It translates a 3D camera by the given 3D vector. The position and the target
are translated. The up vector is left unchanged.
""".
-spec translate(graphics:camera3(), graphics:vector3()) -> graphics:camera3().
translate({Position, Target, Up}, Vector) ->
    {vector3:add(Position, Vector), vector3:add(Target, Vector), Up}.

-doc """
Check whether two 3D cameras are equal.

It returns `true` when the position, the target, and the up vector compare
equal. The values `+0.0` and `-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:camera3(), graphics:camera3()) -> boolean().
is_equal_to({Position1, Target1, Up1}, {Position2, Target2, Up2}) ->
    vector3:is_equal_to(Position1, Position2)
        andalso vector3:is_equal_to(Target1, Target2)
        andalso vector3:is_equal_to(Up1, Up2).

-doc """
Check whether two 3D cameras are equal within an epsilon.

It returns `true` when each pair of corresponding pose vectors differs by at
most `Epsilon` per component.
""".
-spec is_equal_to(graphics:camera3(), graphics:camera3(), float()) -> boolean().
is_equal_to({Position1, Target1, Up1}, {Position2, Target2, Up2}, Epsilon) ->
    vector3:is_equal_to(Position1, Position2, Epsilon)
        andalso vector3:is_equal_to(Target1, Target2, Epsilon)
        andalso vector3:is_equal_to(Up1, Up2, Epsilon).
