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
To be written.

To be written.
""".

-export([
    orthographic/6, % Orthographic projection (left, right, bottom, top, near, far)
    perspective/4,  % Perspective (fov_y, aspect, near, far)
    look_at/3       % View matrix (eye, target, up vectors)
]).
-export([
    frustum/6
]).

-doc """
To be written.

To be written.
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
    % Calculate matrix components
    Tx = -(Right + Left) / (Right - Left),
    Ty = -(Top + Bottom) / (Top - Bottom),
    Tz = -(Far + Near) / (Far - Near),

    % Column-major order matrix
    {
        2.0 / (Right - Left), 0.0, 0.0, 0.0,
        0.0, 2.0 / (Top - Bottom), 0.0, 0.0,
        0.0, 0.0, -2.0 / (Far - Near), 0.0,
        Tx, Ty, Tz, 1.0
    }.

-doc """
To be written.

To be written.
""".
-spec perspective(
    FovY :: float(),
    Aspect :: float(),
    Near :: float(),
    Far :: float()
) -> graphics:matrix4().
perspective(FovY, Aspect, Near, Far) ->
    % Calculate the focal length (f) from vertical FOV
    F = 1.0 / math:tan(FovY / 2.0),

    % Depth calculation components
    RangeInv = 1.0 / (Near - Far),

    % Column-major order matrix
    {
        F / Aspect, 0.0, 0.0,                          0.0,
        0.0,        F,   0.0,                          0.0,
        0.0,        0.0, (Far + Near) * RangeInv,      -1.0,
        0.0,        0.0, 2.0 * Far * Near * RangeInv,  0.0
    }.

-doc """
To be written.

To be written.
""".
-spec look_at(
    Eye :: graphics:vector3(),
    Target :: graphics:vector3(),
    Up :: graphics:vector3()
) -> graphics:matrix4().
look_at(Eye, Target, Up) ->
    % Calculate the forward vector (z-axis) and normalize it
    {X, Y, Z} = vector3:subtract(Eye, Target),
    ZAxis = vector3:normalize({X, Y, Z}),

    % Calculate the right vector (x-axis)
    XAxis = vector3:normalize(vector3:cross_product(Up, ZAxis)),

    % Recalculate the orthonormal up vector (y-axis)
    YAxis = vector3:cross_product(ZAxis, XAxis),

    % Create the rotation/translation matrix
    % Translation is -dot(eye, x), -dot(eye, y), -dot(eye, z)
    NegEyeX = -vector3:dot_product(Eye, XAxis),
    NegEyeY = -vector3:dot_product(Eye, YAxis),
    NegEyeZ = -vector3:dot_product(Eye, ZAxis),

    % Column-major order matrix
    {
        element(1, XAxis), element(1, YAxis), element(1, ZAxis), 0.0,
        element(2, XAxis), element(2, YAxis), element(2, ZAxis), 0.0,
        element(3, XAxis), element(3, YAxis), element(3, ZAxis), 0.0,
        NegEyeX,           NegEyeY,           NegEyeZ,           1.0
    }.

-doc """
To be written.

To be written.
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
    ok.
