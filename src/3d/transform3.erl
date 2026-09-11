%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(transform3).
-moduledoc """
To be written.

To be written.
""".
-export([
    translation/1,
    rotation/2,
    scale/1
]).
-export([
    transform_point/2,
    transform_direction/2
]).
-export([
    transform_vertex/2,
    transform_box/2
]).

-doc """
To be written.

To be written.
""".
-spec translation(graphics:vector3()) -> graphics:matrix4().
translation({OffsetX, OffsetY, OffsetZ}) ->
    {
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        OffsetX, OffsetY, OffsetZ, 1.0
    }.

-doc """
To be written.

To be written.
""".
-spec rotation(graphics:angle(), graphics:vector3()) -> graphics:matrix4().
rotation(_Angle, _Axis) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec scale(graphics:vector3()) -> graphics:matrix4().
scale({FactorX, FactorY, FactorZ}) ->
    {
        FactorX, 0.0, 0.0, 0.0,
        0.0, FactorY, 0.0, 0.0,
        0.0, 0.0, FactorZ, 0.0,
        0.0, 0.0, 0.0, 1.0
    }.

-doc """
To be written.

To be written.
""".
-spec transform_point(graphics:matrix4(), graphics:vector3()) ->
    graphics:vector3().
transform_point(_Matrix, _Point) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec transform_direction(graphics:matrix4(), graphics:vector3()) ->
    graphics:vector3().
transform_direction(_Matrix, _Direction) ->
    ok.

-doc """
To be written.

To be written.
""".
-spec transform_vertex(graphics:matrix4(), graphics:vertex3()) ->
    graphics:vertex3().
transform_vertex(Matrix, {{X, Y, Z}, Color, U, V}) ->
    W = 1, % Homogeneous coordinate
    
    % Matrix is in column-major order, so we access elements accordingly
    X2 = X*element(1, Matrix) + Y*element(5, Matrix) + Z*element(9, Matrix) + W*element(13, Matrix),
    Y2 = X*element(2, Matrix) + Y*element(6, Matrix) + Z*element(10, Matrix) + W*element(14, Matrix),
    Z2 = X*element(3, Matrix) + Y*element(7, Matrix) + Z*element(11, Matrix) + W*element(15, Matrix),
    W2 = X*element(4, Matrix) + Y*element(8, Matrix) + Z*element(12, Matrix) + W*element(16, Matrix),
    
    % Perspective division if W2 is not 1
    {NewX, NewY, NewZ} = if
        W2 =:= 1.0 ->
            {X2, Y2, Z2};
        true ->
            {X2/W2, Y2/W2, Z2/W2}
    end,
    {{NewX, NewY, NewZ}, Color, U, V}.

-doc """
To be written.

To be written.
""".
-spec transform_box(graphics:matrix4(), graphics:box3()) ->
    graphics:box3().
transform_box(_Matrix, _Box) ->
    ok.
