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

color_red_test() ->
    0 = color:red(?COLOR_BLACK),
    255 = color:red(?COLOR_WHITE),
    255 = color:red(?COLOR_RED),
    0 = color:red(?COLOR_GREEN),
    0 = color:red(?COLOR_BLUE),
    255 = color:red(?COLOR_YELLOW),
    0 = color:red(?COLOR_CYAN),
    255 = color:red(?COLOR_MAGENTA),
    0 = color:red(?COLOR_TRANSPARENT),

    ok.

color_green_test() ->
    0 = color:green(?COLOR_BLACK),
    255 = color:green(?COLOR_WHITE),
    0 = color:green(?COLOR_RED),
    255 = color:green(?COLOR_GREEN),
    0 = color:green(?COLOR_BLUE),
    255 = color:green(?COLOR_YELLOW),
    255 = color:green(?COLOR_CYAN),
    0 = color:green(?COLOR_MAGENTA),
    0 = color:green(?COLOR_TRANSPARENT),

    ok.

color_blue_test() ->
    0 = color:blue(?COLOR_BLACK),
    255 = color:blue(?COLOR_WHITE),
    0 = color:blue(?COLOR_RED),
    0 = color:blue(?COLOR_GREEN),
    255 = color:blue(?COLOR_BLUE),
    0 = color:blue(?COLOR_YELLOW),
    255 = color:blue(?COLOR_CYAN),
    255 = color:blue(?COLOR_MAGENTA),
    0 = color:blue(?COLOR_TRANSPARENT),

    ok.

color_alpha_test() ->
    255 = color:alpha(?COLOR_BLACK),
    255 = color:alpha(?COLOR_WHITE),
    255 = color:alpha(?COLOR_RED),
    255 = color:alpha(?COLOR_GREEN),
    255 = color:alpha(?COLOR_BLUE),
    255 = color:alpha(?COLOR_YELLOW),
    255 = color:alpha(?COLOR_CYAN),
    255 = color:alpha(?COLOR_MAGENTA),
    0 = color:alpha(?COLOR_TRANSPARENT),

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

color_rgb_test() ->
    ?COLOR_BLACK = color:rgb(0, 0, 0),
    ?COLOR_WHITE = color:rgb(255, 255, 255),
    ?COLOR_RED = color:rgb(255, 0, 0),
    ?COLOR_GREEN = color:rgb(0, 255, 0),
    ?COLOR_BLUE = color:rgb(0, 0, 255),
    ?COLOR_YELLOW = color:rgb(255, 255, 0),
    ?COLOR_CYAN = color:rgb(0, 255, 255),
    ?COLOR_MAGENTA = color:rgb(255, 0, 255),

    ok.

color_rgba_test() ->
    ?COLOR_BLACK = color:rgba(0, 0, 0, 255),
    ?COLOR_WHITE = color:rgba(255, 255, 255, 255),
    ?COLOR_RED = color:rgba(255, 0, 0, 255),
    ?COLOR_GREEN = color:rgba(0, 255, 0, 255),
    ?COLOR_BLUE = color:rgba(0, 0, 255, 255),
    ?COLOR_YELLOW = color:rgba(255, 255, 0, 255),
    ?COLOR_CYAN = color:rgba(0, 255, 255, 255),
    ?COLOR_MAGENTA = color:rgba(255, 0, 255, 255),
    ?COLOR_TRANSPARENT = color:rgba(0, 0, 0, 0),

    ok.

color_argb_test() ->
    ?COLOR_BLACK = color:argb(255, 0, 0, 0),
    ?COLOR_WHITE = color:argb(255, 255, 255, 255),
    ?COLOR_RED = color:argb(255, 255, 0, 0),
    ?COLOR_GREEN = color:argb(255, 0, 255, 0),
    ?COLOR_BLUE = color:argb(255, 0, 0, 255),
    ?COLOR_YELLOW = color:argb(255, 255, 255, 0),
    ?COLOR_CYAN = color:argb(255, 0, 255, 255),
    ?COLOR_MAGENTA = color:argb(255, 255, 0, 255),
    ?COLOR_TRANSPARENT = color:argb(0, 0, 0, 0),

    ok.
