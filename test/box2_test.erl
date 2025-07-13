%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(box2_test).
-include_lib("eunit/include/eunit.hrl").

box2_test() ->
    % B = #box2{},
    % {0.0, 0.0} = B#box2.min,
    % {0.0, 0.0} = B#box2.max,

    ok.

box2_from_points_test() ->
    % Points = [
    %     {1.0, 2.0},
    %     {3.0, 4.0},
    %     {5.0, 6.0}
    % ],
    % Box = box2:from_points(Points),
    % {1.0, 2.0} = Box#box2.min,
    % {5.0, 6.0} = Box#box2.max,

    ok.

box2_from_vertices_test() ->
    % Vertices = [
    %     #vertex2{position = {1.0, 2.0}},
    %     #vertex2{position = {3.0, 4.0}},
    %     #vertex2{position = {5.0, 6.0}}
    % ],
    % Box = box2:from_vertices(Vertices),
    % {1.0, 2.0} = Box#box2.min,
    % {5.0, 6.0} = Box#box2.max,

    ok.

box2_contains_test() ->
    % B = #box2{min={0.0, 0.0}, max={1.0, 1.0}},
    % true = box2:contains(B, {0.0, 0.0}),
    % true = box2:contains(B, {1.0, 1.0}),
    % true = box2:contains(B, {0.5, 0.5}),
    % false = box2:contains(B, {-1.0, 0.0}),
    % false = box2:contains(B, {0.0, -1.0}),
    % false = box2:contains(B, {2.0, 0.0}),
    % false = box2:contains(B, {0.0, 2.0}),
    % false = box2:contains(B, {2.0, 2.0}),
    % false = box2:contains(B, {-1.0, -1.0}),
    % false = box2:contains(B, {2.0, 2.0}),

    ok.

box2_intersects_test() ->
    % B1 = #box2{min={0.0, 0.0}, max={1.0, 1.0}},
    % B2 = #box2{min={0.5, 0.5}, max={1.5, 1.5}},
    % true = box2:intersects(B1, B2),
    % true = box2:intersects(B2, B1),

    ok.
