%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(color_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

color_red_test() ->
    0.0 = color:red(?COLOR_BLACK),
    1.0 = color:red(?COLOR_WHITE),
    1.0 = color:red(?COLOR_RED),
    0.0 = color:red(?COLOR_GREEN),
    0.0 = color:red(?COLOR_BLUE),
    1.0 = color:red(?COLOR_YELLOW),
    0.0 = color:red(?COLOR_CYAN),
    1.0 = color:red(?COLOR_MAGENTA),
    0.0 = color:red(?COLOR_TRANSPARENT),

    ok.

color_green_test() ->
    0.0 = color:green(?COLOR_BLACK),
    1.0 = color:green(?COLOR_WHITE),
    0.0 = color:green(?COLOR_RED),
    1.0 = color:green(?COLOR_GREEN),
    0.0 = color:green(?COLOR_BLUE),
    1.0 = color:green(?COLOR_YELLOW),
    1.0 = color:green(?COLOR_CYAN),
    0.0 = color:green(?COLOR_MAGENTA),
    0.0 = color:green(?COLOR_TRANSPARENT),

    ok.

color_blue_test() ->
    0.0 = color:blue(?COLOR_BLACK),
    1.0 = color:blue(?COLOR_WHITE),
    0.0 = color:blue(?COLOR_RED),
    0.0 = color:blue(?COLOR_GREEN),
    1.0 = color:blue(?COLOR_BLUE),
    0.0 = color:blue(?COLOR_YELLOW),
    1.0 = color:blue(?COLOR_CYAN),
    1.0 = color:blue(?COLOR_MAGENTA),
    0.0 = color:blue(?COLOR_TRANSPARENT),

    ok.

color_alpha_test() ->
    1.0 = color:alpha(?COLOR_BLACK),
    1.0 = color:alpha(?COLOR_WHITE),
    1.0 = color:alpha(?COLOR_RED),
    1.0 = color:alpha(?COLOR_GREEN),
    1.0 = color:alpha(?COLOR_BLUE),
    1.0 = color:alpha(?COLOR_YELLOW),
    1.0 = color:alpha(?COLOR_CYAN),
    1.0 = color:alpha(?COLOR_MAGENTA),
    0.0 = color:alpha(?COLOR_TRANSPARENT),

    ok.

color_rgb_test() ->
    ?COLOR_BLACK = color:rgb(0.0, 0.0, 0.0),
    ?COLOR_WHITE = color:rgb(1.0, 1.0, 1.0),
    ?COLOR_RED = color:rgb(1.0, 0.0, 0.0),
    ?COLOR_GREEN = color:rgb(0.0, 1.0, 0.0),
    ?COLOR_BLUE = color:rgb(0.0, 0.0, 1.0),
    ?COLOR_YELLOW = color:rgb(1.0, 1.0, 0.0),
    ?COLOR_CYAN = color:rgb(0.0, 1.0, 1.0),
    ?COLOR_MAGENTA = color:rgb(1.0, 0.0, 1.0),

    ok.

color_rgba_test() ->
    ?COLOR_BLACK = color:rgba(0.0, 0.0, 0.0, 1.0),
    ?COLOR_WHITE = color:rgba(1.0, 1.0, 1.0, 1.0),
    ?COLOR_RED = color:rgba(1.0, 0.0, 0.0, 1.0),
    ?COLOR_GREEN = color:rgba(0.0, 1.0, 0.0, 1.0),
    ?COLOR_BLUE = color:rgba(0.0, 0.0, 1.0, 1.0),
    ?COLOR_YELLOW = color:rgba(1.0, 1.0, 0.0, 1.0),
    ?COLOR_CYAN = color:rgba(0.0, 1.0, 1.0, 1.0),
    ?COLOR_MAGENTA = color:rgba(1.0, 0.0, 1.0, 1.0),
    ?COLOR_TRANSPARENT = color:rgba(0.0, 0.0, 0.0, 0.0),

    ok.

color_from_bytes_test() ->
    ?COLOR_BLACK = color:from_bytes(0, 0, 0),
    ?COLOR_WHITE = color:from_bytes(255, 255, 255),
    ?COLOR_RED = color:from_bytes(255, 0, 0),
    ?COLOR_GREEN = color:from_bytes(0, 255, 0),
    ?COLOR_BLUE = color:from_bytes(0, 0, 255),
    ?COLOR_YELLOW = color:from_bytes(255, 255, 0),
    ?COLOR_CYAN = color:from_bytes(0, 255, 255),
    ?COLOR_MAGENTA = color:from_bytes(255, 0, 255),
    ?COLOR_TRANSPARENT = color:from_bytes(0, 0, 0, 0),
    ?COLOR_BLACK = color:from_bytes(0, 0, 0, 255),

    ok.

color_to_bytes_test() ->
    {0, 0, 0, 255} = color:to_bytes(?COLOR_BLACK),
    {255, 255, 255, 255} = color:to_bytes(?COLOR_WHITE),
    {255, 0, 0, 255} = color:to_bytes(?COLOR_RED),
    {0, 255, 0, 255} = color:to_bytes(?COLOR_GREEN),
    {0, 0, 255, 255} = color:to_bytes(?COLOR_BLUE),
    {255, 255, 0, 255} = color:to_bytes(?COLOR_YELLOW),
    {0, 255, 255, 255} = color:to_bytes(?COLOR_CYAN),
    {255, 0, 255, 255} = color:to_bytes(?COLOR_MAGENTA),
    {0, 0, 0, 0} = color:to_bytes(?COLOR_TRANSPARENT),
    {0, 255, 0, 255} = color:to_bytes({-1.0, 2.0, 0.0, 1.0}),
    {128, 128, 128, 128} = color:to_bytes({0.5, 0.5, 0.5, 0.5}),

    ok.

color_to_integer_test() ->
    16#000000FF = color:to_integer(?COLOR_BLACK),
    16#FFFFFFFF = color:to_integer(?COLOR_WHITE),
    16#FF0000FF = color:to_integer(?COLOR_RED),
    16#00FF00FF = color:to_integer(?COLOR_GREEN),
    16#0000FFFF = color:to_integer(?COLOR_BLUE),
    16#FFFF00FF = color:to_integer(?COLOR_YELLOW),
    16#00FFFFFF = color:to_integer(?COLOR_CYAN),
    16#FF00FFFF = color:to_integer(?COLOR_MAGENTA),
    16#00000000 = color:to_integer(?COLOR_TRANSPARENT),

    ok.

color_from_integer_test() ->
    ?COLOR_BLACK = color:from_integer(16#000000FF),
    ?COLOR_WHITE = color:from_integer(16#FFFFFFFF),
    ?COLOR_RED = color:from_integer(16#FF0000FF),
    ?COLOR_GREEN = color:from_integer(16#00FF00FF),
    ?COLOR_BLUE = color:from_integer(16#0000FFFF),
    ?COLOR_YELLOW = color:from_integer(16#FFFF00FF),
    ?COLOR_CYAN = color:from_integer(16#00FFFFFF),
    ?COLOR_MAGENTA = color:from_integer(16#FF00FFFF),
    ?COLOR_TRANSPARENT = color:from_integer(16#00000000),

    ok.

color_is_equal_to_test() ->
    true = color:is_equal_to(?COLOR_RED, ?COLOR_RED),
    true = color:is_equal_to({+0.0, -0.0, +0.0, -0.0}, {-0.0, +0.0, -0.0, +0.0}),
    false = color:is_equal_to(?COLOR_RED, ?COLOR_GREEN),
    true = color:is_equal_to({1.0, 0.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0000001}, ?EPS),
    false = color:is_equal_to({1.0, 0.0, 0.0, 1.0}, {1.0, 0.1, 0.0, 1.0}, ?EPS),

    ok.

color_lerp_test() ->
    {1.0, 0.0, 0.0, 1.0} = color:lerp(?COLOR_RED, ?COLOR_BLUE, 0.0),
    {0.0, 0.0, 1.0, 1.0} = color:lerp(?COLOR_RED, ?COLOR_BLUE, 1.0),
    {0.5, 0.0, 0.5, 1.0} = color:lerp(?COLOR_RED, ?COLOR_BLUE, 0.5),
    {-1.0, 0.0, 2.0, 1.0} = color:lerp(?COLOR_RED, ?COLOR_BLUE, 2.0),

    ok.

color_multiply_test() ->
    ?COLOR_RED = color:multiply(?COLOR_RED, ?COLOR_WHITE),
    ?COLOR_BLACK = color:multiply(?COLOR_RED, ?COLOR_BLACK),
    {0.5, 0.0, 0.0, 1.0} = color:multiply(?COLOR_RED, {0.5, 0.5, 0.5, 1.0}),
    {0.25, 0.25, 0.25, 0.25} = color:multiply(
        {0.5, 0.5, 0.5, 0.5},
        {0.5, 0.5, 0.5, 0.5}
    ),

    ok.
