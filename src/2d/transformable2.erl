%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(transformable2).
-moduledoc """
To be written.

To be written.
""".

-export([

    % origin/1,
    % set_origin/2
]).

% -opaque object() :: {
%     origin :: graphics:vector2(),
%     position :: graphics:vector2(),
%     rotation :: graphics:angle(),
%     scale :: graphics:vector2(),
%     matrix3 :: graphics:matrix3()
% }.

% -spec origin(object()) -> graphics:vector2().
% origin(Transformable) ->
%     ok.


% %%
% %% Copyright (c) 2025, Byteplug LLC.
% %%
% %% This source file is part of a project made by the Erlangsters community and
% %% is released under the MIT license. Please refer to the LICENSE.md file that
% %% can be found at the root of the project repository.
% %%
% %% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
% %%
% -module(transform2).
% -moduledoc """
% 2D transformation operations using 3x3 matrices.

% This module provides a high-level interface for working with 2D transformations
% represented as 3x3 matrices. It builds upon the `matrix3` module to offer
% convenient functions for common 2D graphics operations including translation,
% rotation, scaling, shearing, and composition of transformations.

% ## Transformation Matrices
% 2D transformations are represented as 3x3 matrices in homogeneous coordinates,
% allowing affine transformations to be expressed as matrix multiplications.
% The matrix format is:
% ```
% [ a, b, tx ]
% [ c, d, ty ]
% [ 0, 0, 1  ]
% ```
% Where:
% - `a, b, c, d` form the 2x2 linear transformation matrix
% - `tx, ty` represent translation
% - The bottom row is always `[0, 0, 1]` for affine transformations

% ## Coordinate Systems
% All transformations assume a right-handed coordinate system where:
% - Positive X points right
% - Positive Y points down
% - Positive rotation is clockwise
% - Angles are specified in radians
% """.
% -export([
%     translate/2,
%     translation/1,
%     rotate/2,
%     rotation/1,
%     scale/2,
%     scale/1
% ]).
% -export([
%     compose/3,
%     decompose/1
% ]).
% -export([
%     shear/2
% ]).
% -export([
%     combine/2
% ]).
% -export([
%     transform_point/2,
%     transform_direction/2,
%     transform_box/2
% ]).

% -doc """
% To be written.

% To be written.
% """.
% -spec translate(graphics:matrix3(), graphics:vector2()) -> graphics:matrix3().
% translate(Matrix, {Tx, Ty}) ->
%     T = {
%         1.0, 0.0, 0.0,
%         0.0, 1.0, 0.0,
%         Tx,  Ty,  1.0
%     },
%     combine(Matrix, T).

% -doc """
% To be written.

% To be written.
% """.
% -spec translation(graphics:matrix3()) -> graphics:vector2().
% translation({_, _, _, _, _, _, Tx, Ty, _}) ->
%     {Tx, Ty}.

% -doc """
% To be written.

% To be written.
% """.
% -spec rotate(graphics:matrix3(), graphics:angle()) -> graphics:matrix3().
% rotate(Matrix, Angle) ->
%     CosA = math:cos(Angle),
%     SinA = math:sin(Angle),
%     R = {
%         CosA, -SinA, 0.0,
%         SinA,  CosA, 0.0,
%         0.0,   0.0,  1.0
%     },
%     combine(Matrix, R).

% -doc """
% To be written.

% To be written.
% """.
% -spec rotation(graphics:matrix3()) -> graphics:angle().
% rotation({M11, _, _, M12, _, _, _, _, _}) ->
%     math:atan2(M12, M11).

% -doc """
% To be written.

% To be written.
% """.
% -spec scale(graphics:matrix3(), graphics:vector2()) -> graphics:matrix3().
% scale(Matrix, {Sx, Sy}) ->
%     S = {
%         Sx, 0.0, 0.0,
%         0.0, Sy, 0.0,
%         0.0, 0.0, 1.0
%     },
%     combine(Matrix, S).

% -doc """
% To be written.

% To be written.
% """.
% -spec scale(graphics:matrix3()) -> graphics:vector2().
% scale({M00, M10, _, M01, M11, _, _, _, _}) ->
%     Sx = math:sqrt(M00 * M00 + M10 * M10),
%     Sy = math:sqrt(M01 * M01 + M11 * M11),
%     % Preserve sign of Sy using determinant
%     Det = M00 * M11 - M01 * M10,
%     SySigned = if Det < 0 -> -Sy; true -> Sy end,
%     {Sx, SySigned}.

% -doc """
% To be written.

% To be written.
% """.
% -spec compose(graphics:vector2(), graphics:angle(), graphics:vector2()) ->
%     graphics:matrix3().
% compose({Tx, Ty}, Angle, {Sx, Sy}) ->
%     CosA = math:cos(Angle),
%     SinA = math:sin(Angle),
%     {
%         Sx * CosA, Sy * -SinA, 0.0,
%         Sx * SinA, Sy * CosA,  0.0,
%         Tx,        Ty,         1.0
%     }.

% -doc """
% To be written.

% To be written.
% """.
% -spec decompose(graphics:matrix3()) ->
%     {graphics:vector2(), graphics:angle(), graphics:vector2()}.
% decompose(Matrix) ->
%     Translation = translation(Matrix),
%     Rotation = rotation(Matrix),
%     Scale = scale(Matrix),
%     {Translation, Rotation, Scale}.

% -doc """
% To be written.

% To be written.
% """.
% -spec shear(graphics:matrix3(), graphics:vector2()) -> graphics:matrix3().
% shear(Matrix, {Shx, Shy}) ->
%     Sh = {
%         1.0, Shy, 0.0,
%         Shx, 1.0, 0.0,
%         0.0, 0.0, 1.0
%     },
%     combine(Matrix, Sh).

% -doc """
% To be written.

% To be written.
% """.
% -spec combine(graphics:matrix3(), graphics:matrix3()) -> graphics:matrix3().
% combine(M1, M2) ->
%     matrix3:multiply(M1, M2).

% -doc """
% To be written.

% To be written.
% """.
% -spec transform_point(graphics:matrix3(), graphics:vector2()) -> graphics:vector2().
% transform_point({M00, M10, _, M01, M11, _, Tx, Ty, _}, {Px, Py}) ->
%     {
%         M00 * Px + M01 * Py + Tx,
%         M10 * Px + M11 * Py + Ty
%     }.

% -doc """
% To be written.

% To be written.
% """.
% -spec transform_direction(graphics:matrix3(), graphics:vector2()) -> graphics:vector2().
% transform_direction({M00, M10, _, M01, M11, _, _, _, _}, {Dx, Dy}) ->
%     {
%         M00 * Dx + M01 * Dy,
%         M10 * Dx + M11 * Dy
%     }.

% -doc """
% To be written.

% To be written.
% """.
% -spec transform_box(graphics:matrix3(), graphics:box2()) -> graphics:box2().
% transform_box(_M, _Box) ->
%     42.
