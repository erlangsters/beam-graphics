%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(transform2).
-moduledoc """
To be written.

To be written.
""".
-export([
    translation/1,
    rotation/1,
    scale/1
]).
-export([
    transform_point/2,
    transform_direction/2
]).

-doc """
To be written.

To be written.
""".
-spec translation(graphics:vector2()) -> graphics:matrix3().
translation({Tx, Ty}) ->
    {
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        Tx,  Ty,  1.0
    }.

-doc """
To be written.

To be written.
""".
-spec rotation(graphics:angle()) -> graphics:matrix3().
rotation(Angle) ->
    CosA = math:cos(Angle),
    SinA = math:sin(Angle),
    {
        CosA, -SinA, 0.0,
        SinA,  CosA, 0.0,
        0.0,   0.0,  1.0
    }.

-doc """
To be written.

To be written.
""".
-spec scale(graphics:vector2()) -> graphics:matrix3().
scale({Sx, Sy}) ->
    {
        Sx, 0.0, 0.0,
        0.0, Sy, 0.0,
        0.0, 0.0, 1.0
    }.

-doc """
To be written.

To be written.
""".
-spec transform_point(graphics:matrix3(), graphics:vector2()) ->
    graphics:vector2().
transform_point({M00, M10, _, M01, M11, _, Tx, Ty, _}, {Px, Py}) ->
    {
        M00 * Px + M01 * Py + Tx,
        M10 * Px + M11 * Py + Ty
    }.

-doc """
To be written.

To be written.
""".
-spec transform_direction(graphics:matrix3(), graphics:vector2()) ->
    graphics:vector2().
transform_direction({M00, M10, _, M01, M11, _, _, _, _}, {Dx, Dy}) ->
    {
        M00 * Dx + M01 * Dy,
        M10 * Dx + M11 * Dy
    }.
