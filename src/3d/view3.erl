%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(view3).
-moduledoc """
3D View

A 3D view is a 4x4 matrix that is typically used to represent an orthographic
or perspective projection in the Euclidean space.

There is no extra data structure. This module constructs 4x4 matrices that map
a view-space volume to clip space. The matrix itself is a `graphics:matrix4()`
value.

```erlang
M = view3:perspective(math:pi() / 4.0, 16.0 / 9.0, 0.1, 100.0).
```

The projection is right-handed with clip Z in `[-1, 1]`. `perspective/4` takes
a vertical field of view in radians and an aspect ratio of width over height.
`frustum/6` is the general asymmetric perspective. Y increases upward when
Bottom is less than Top. Swap Bottom and Top to flip Y.

The observer that chooses where that volume sits in the world is a separate
value; see the `camera3` module.

Beware that a well-formed 4x4 matrix always contains floats, not integers.
""".

-export([
    orthographic/6,
    perspective/4,
    frustum/6
]).

-doc """
An orthographic 4x4 matrix.

It constructs a 4x4 matrix that maps the box `Left` to `Right`, `Bottom` to
`Top`, and `-Near` to `-Far` in view space to clip space. Y increases upward
when `Bottom` is less than `Top`. Swap `Bottom` and `Top` to flip Y.
""".
-spec orthographic(
    Left :: float(),
    Right :: float(),
    Bottom :: float(),
    Top :: float(),
    Near :: float(),
    Far :: float()
) -> graphics:matrix4().
orthographic(Left, Right, Bottom, Top, Near, Far) ->
    Tx = -(Right + Left) / (Right - Left),
    Ty = -(Top + Bottom) / (Top - Bottom),
    Tz = -(Far + Near) / (Far - Near),
    {
        2.0 / (Right - Left), 0.0, 0.0, 0.0,
        0.0, 2.0 / (Top - Bottom), 0.0, 0.0,
        0.0, 0.0, -2.0 / (Far - Near), 0.0,
        Tx, Ty, Tz, 1.0
    }.

-doc """
A perspective 4x4 matrix.

It constructs a 4x4 matrix from a vertical field of view in radians, an aspect
ratio of width over height, and the near and far distances. The projection is
right-handed with clip Z in `[-1, 1]`.
""".
-spec perspective(
    FovY :: graphics:angle(),
    Aspect :: float(),
    Near :: float(),
    Far :: float()
) -> graphics:matrix4().
perspective(FovY, Aspect, Near, Far) ->
    F = 1.0 / math:tan(FovY / 2.0),
    RangeInv = 1.0 / (Near - Far),
    {
        F / Aspect, 0.0, 0.0, 0.0,
        0.0, F, 0.0, 0.0,
        0.0, 0.0, (Far + Near) * RangeInv, -1.0,
        0.0, 0.0, 2.0 * Far * Near * RangeInv, 0.0
    }.

-doc """
A frustum 4x4 matrix.

It constructs a 4x4 perspective matrix from the near-plane bounds `Left`,
`Right`, `Bottom`, and `Top`, and the near and far distances. The projection
is right-handed with clip Z in `[-1, 1]`. A symmetric frustum matches
`perspective/4` for the equivalent field of view and aspect ratio.
""".
-spec frustum(
    Left :: float(),
    Right :: float(),
    Bottom :: float(),
    Top :: float(),
    Near :: float(),
    Far :: float()
) -> graphics:matrix4().
frustum(Left, Right, Bottom, Top, Near, Far) ->
    A = 2.0 * Near / (Right - Left),
    B = 2.0 * Near / (Top - Bottom),
    C = (Right + Left) / (Right - Left),
    D = (Top + Bottom) / (Top - Bottom),
    E = -(Far + Near) / (Far - Near),
    F = -2.0 * Far * Near / (Far - Near),
    {
        A, 0.0, 0.0, 0.0,
        0.0, B, 0.0, 0.0,
        C, D, E, -1.0,
        0.0, 0.0, F, 0.0
    }.
