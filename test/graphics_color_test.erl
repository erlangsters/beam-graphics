%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_color_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(EPS, 1.0e-6).

color_red_test() ->
    0.0 = graphics_color:red(?COLOR_BLACK),
    1.0 = graphics_color:red(?COLOR_WHITE),
    1.0 = graphics_color:red(?COLOR_RED),
    0.0 = graphics_color:red(?COLOR_GREEN),
    0.0 = graphics_color:red(?COLOR_BLUE),
    1.0 = graphics_color:red(?COLOR_YELLOW),
    0.0 = graphics_color:red(?COLOR_CYAN),
    1.0 = graphics_color:red(?COLOR_MAGENTA),
    0.0 = graphics_color:red(?COLOR_TRANSPARENT),

    ok.

color_green_test() ->
    0.0 = graphics_color:green(?COLOR_BLACK),
    1.0 = graphics_color:green(?COLOR_WHITE),
    0.0 = graphics_color:green(?COLOR_RED),
    1.0 = graphics_color:green(?COLOR_GREEN),
    0.0 = graphics_color:green(?COLOR_BLUE),
    1.0 = graphics_color:green(?COLOR_YELLOW),
    1.0 = graphics_color:green(?COLOR_CYAN),
    0.0 = graphics_color:green(?COLOR_MAGENTA),
    0.0 = graphics_color:green(?COLOR_TRANSPARENT),

    ok.

color_blue_test() ->
    0.0 = graphics_color:blue(?COLOR_BLACK),
    1.0 = graphics_color:blue(?COLOR_WHITE),
    0.0 = graphics_color:blue(?COLOR_RED),
    0.0 = graphics_color:blue(?COLOR_GREEN),
    1.0 = graphics_color:blue(?COLOR_BLUE),
    0.0 = graphics_color:blue(?COLOR_YELLOW),
    1.0 = graphics_color:blue(?COLOR_CYAN),
    1.0 = graphics_color:blue(?COLOR_MAGENTA),
    0.0 = graphics_color:blue(?COLOR_TRANSPARENT),

    ok.

color_alpha_test() ->
    1.0 = graphics_color:alpha(?COLOR_BLACK),
    1.0 = graphics_color:alpha(?COLOR_WHITE),
    1.0 = graphics_color:alpha(?COLOR_RED),
    1.0 = graphics_color:alpha(?COLOR_GREEN),
    1.0 = graphics_color:alpha(?COLOR_BLUE),
    1.0 = graphics_color:alpha(?COLOR_YELLOW),
    1.0 = graphics_color:alpha(?COLOR_CYAN),
    1.0 = graphics_color:alpha(?COLOR_MAGENTA),
    0.0 = graphics_color:alpha(?COLOR_TRANSPARENT),

    ok.

color_rgb_test() ->
    ?COLOR_BLACK = graphics_color:rgb(0.0, 0.0, 0.0),
    ?COLOR_WHITE = graphics_color:rgb(1.0, 1.0, 1.0),
    ?COLOR_RED = graphics_color:rgb(1.0, 0.0, 0.0),
    ?COLOR_GREEN = graphics_color:rgb(0.0, 1.0, 0.0),
    ?COLOR_BLUE = graphics_color:rgb(0.0, 0.0, 1.0),
    ?COLOR_YELLOW = graphics_color:rgb(1.0, 1.0, 0.0),
    ?COLOR_CYAN = graphics_color:rgb(0.0, 1.0, 1.0),
    ?COLOR_MAGENTA = graphics_color:rgb(1.0, 0.0, 1.0),

    ok.

color_rgba_test() ->
    ?COLOR_BLACK = graphics_color:rgba(0.0, 0.0, 0.0, 1.0),
    ?COLOR_WHITE = graphics_color:rgba(1.0, 1.0, 1.0, 1.0),
    ?COLOR_RED = graphics_color:rgba(1.0, 0.0, 0.0, 1.0),
    ?COLOR_GREEN = graphics_color:rgba(0.0, 1.0, 0.0, 1.0),
    ?COLOR_BLUE = graphics_color:rgba(0.0, 0.0, 1.0, 1.0),
    ?COLOR_YELLOW = graphics_color:rgba(1.0, 1.0, 0.0, 1.0),
    ?COLOR_CYAN = graphics_color:rgba(0.0, 1.0, 1.0, 1.0),
    ?COLOR_MAGENTA = graphics_color:rgba(1.0, 0.0, 1.0, 1.0),
    ?COLOR_TRANSPARENT = graphics_color:rgba(0.0, 0.0, 0.0, 0.0),

    ok.

color_from_bytes_test() ->
    ?COLOR_BLACK = graphics_color:from_bytes(0, 0, 0),
    ?COLOR_WHITE = graphics_color:from_bytes(255, 255, 255),
    ?COLOR_RED = graphics_color:from_bytes(255, 0, 0),
    ?COLOR_GREEN = graphics_color:from_bytes(0, 255, 0),
    ?COLOR_BLUE = graphics_color:from_bytes(0, 0, 255),
    ?COLOR_YELLOW = graphics_color:from_bytes(255, 255, 0),
    ?COLOR_CYAN = graphics_color:from_bytes(0, 255, 255),
    ?COLOR_MAGENTA = graphics_color:from_bytes(255, 0, 255),
    ?COLOR_TRANSPARENT = graphics_color:from_bytes(0, 0, 0, 0),
    ?COLOR_BLACK = graphics_color:from_bytes(0, 0, 0, 255),

    ok.

color_to_bytes_test() ->
    {0, 0, 0, 255} = graphics_color:to_bytes(?COLOR_BLACK),
    {255, 255, 255, 255} = graphics_color:to_bytes(?COLOR_WHITE),
    {255, 0, 0, 255} = graphics_color:to_bytes(?COLOR_RED),
    {0, 255, 0, 255} = graphics_color:to_bytes(?COLOR_GREEN),
    {0, 0, 255, 255} = graphics_color:to_bytes(?COLOR_BLUE),
    {255, 255, 0, 255} = graphics_color:to_bytes(?COLOR_YELLOW),
    {0, 255, 255, 255} = graphics_color:to_bytes(?COLOR_CYAN),
    {255, 0, 255, 255} = graphics_color:to_bytes(?COLOR_MAGENTA),
    {0, 0, 0, 0} = graphics_color:to_bytes(?COLOR_TRANSPARENT),
    {0, 255, 0, 255} = graphics_color:to_bytes({-1.0, 2.0, 0.0, 1.0}),
    {128, 128, 128, 128} = graphics_color:to_bytes({0.5, 0.5, 0.5, 0.5}),

    ok.

color_to_integer_test() ->
    16#000000FF = graphics_color:to_integer(?COLOR_BLACK),
    16#FFFFFFFF = graphics_color:to_integer(?COLOR_WHITE),
    16#FF0000FF = graphics_color:to_integer(?COLOR_RED),
    16#00FF00FF = graphics_color:to_integer(?COLOR_GREEN),
    16#0000FFFF = graphics_color:to_integer(?COLOR_BLUE),
    16#FFFF00FF = graphics_color:to_integer(?COLOR_YELLOW),
    16#00FFFFFF = graphics_color:to_integer(?COLOR_CYAN),
    16#FF00FFFF = graphics_color:to_integer(?COLOR_MAGENTA),
    16#00000000 = graphics_color:to_integer(?COLOR_TRANSPARENT),

    ok.

color_from_integer_test() ->
    ?COLOR_BLACK = graphics_color:from_integer(16#000000FF),
    ?COLOR_WHITE = graphics_color:from_integer(16#FFFFFFFF),
    ?COLOR_RED = graphics_color:from_integer(16#FF0000FF),
    ?COLOR_GREEN = graphics_color:from_integer(16#00FF00FF),
    ?COLOR_BLUE = graphics_color:from_integer(16#0000FFFF),
    ?COLOR_YELLOW = graphics_color:from_integer(16#FFFF00FF),
    ?COLOR_CYAN = graphics_color:from_integer(16#00FFFFFF),
    ?COLOR_MAGENTA = graphics_color:from_integer(16#FF00FFFF),
    ?COLOR_TRANSPARENT = graphics_color:from_integer(16#00000000),

    ok.

color_is_equal_to_test() ->
    true = graphics_color:is_equal_to(?COLOR_RED, ?COLOR_RED),
    true = graphics_color:is_equal_to({+0.0, -0.0, +0.0, -0.0}, {-0.0, +0.0, -0.0, +0.0}),
    false = graphics_color:is_equal_to(?COLOR_RED, ?COLOR_GREEN),
    true = graphics_color:is_equal_to({1.0, 0.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0000001}, ?EPS),
    false = graphics_color:is_equal_to({1.0, 0.0, 0.0, 1.0}, {1.0, 0.1, 0.0, 1.0}, ?EPS),

    ok.

color_lerp_test() ->
    {1.0, 0.0, 0.0, 1.0} = graphics_color:lerp(?COLOR_RED, ?COLOR_BLUE, 0.0),
    {0.0, 0.0, 1.0, 1.0} = graphics_color:lerp(?COLOR_RED, ?COLOR_BLUE, 1.0),
    {0.5, 0.0, 0.5, 1.0} = graphics_color:lerp(?COLOR_RED, ?COLOR_BLUE, 0.5),
    {-1.0, 0.0, 2.0, 1.0} = graphics_color:lerp(?COLOR_RED, ?COLOR_BLUE, 2.0),

    ok.

color_multiply_test() ->
    ?COLOR_RED = graphics_color:multiply(?COLOR_RED, ?COLOR_WHITE),
    ?COLOR_BLACK = graphics_color:multiply(?COLOR_RED, ?COLOR_BLACK),
    {0.5, 0.0, 0.0, 1.0} = graphics_color:multiply(?COLOR_RED, {0.5, 0.5, 0.5, 1.0}),
    {0.25, 0.25, 0.25, 0.25} = graphics_color:multiply(
        {0.5, 0.5, 0.5, 0.5},
        {0.5, 0.5, 0.5, 0.5}
    ),

    ok.
