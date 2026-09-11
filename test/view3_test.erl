%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(view3_test).
-include_lib("eunit/include/eunit.hrl").

-define(EPS, 1.0e-6).

view3_orthographic_test() ->
    Left = -2.0,
    Right = 4.0,
    Bottom = -3.0,
    Top = 5.0,
    Near = 1.0,
    Far = 9.0,
    M = view3:orthographic(Left, Right, Bottom, Top, Near, Far),
    true = vector3:is_equal_to(
        matrix4:multiply_vector(M, {Left, Bottom, -Near}),
        {-1.0, -1.0, -1.0},
        ?EPS
    ),
    true = vector3:is_equal_to(
        matrix4:multiply_vector(M, {Right, Top, -Far}),
        {1.0, 1.0, 1.0},
        ?EPS
    ),
    ok.

view3_perspective_test() ->
    M = view3:perspective(math:pi() / 2.0, 1.0, 1.0, 3.0),
    true = abs(matrix4:element(M, 2, 2) - 1.0) =< ?EPS,
    true = abs(matrix4:element(M, 4, 3) - -1.0) =< ?EPS,
    true = abs(matrix4:element(M, 3, 4) - -3.0) =< ?EPS,
    ok.

view3_frustum_test() ->
    FovY = math:pi() / 2.0,
    Aspect = 1.0,
    Near = 1.0,
    Far = 3.0,
    Top = Near * math:tan(FovY / 2.0),
    Bottom = -Top,
    Right = Top * Aspect,
    Left = -Right,
    true = matrix4:is_equal_to(
        view3:frustum(Left, Right, Bottom, Top, Near, Far),
        view3:perspective(FovY, Aspect, Near, Far),
        ?EPS
    ),
    ok.
