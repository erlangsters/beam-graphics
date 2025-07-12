%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(color).
-moduledoc """
The color API.

It provides functions to create and manipulate colors. Each color is represented
as a tuple of four integers, corresponding to the red, green, blue, and alpha
channels. It defines the RGBA color type, where each channel ranges from 0 to 255.
""".

-export_type([
    channel/0
]).
-export([
    red/1,
    green/1,
    blue/1,
    alpha/1
]).
-export([
    to_integer/1
]).
-export([
    rgb/3,
    rgba/4,
    argb/4
]).

-type channel() :: 1..256.

-doc """
The red component of a color.

It returns the red component of the color, which is an integer ranging from
0 to 255.
""".
-spec red(graphics:color()) -> integer().
red(Color) ->
    element(1, Color).

-doc """
The green component of a color.

It returns the green component of the color, which is an integer ranging from
0 to 255.
""".
-spec green(graphics:color()) -> integer().
green(Color) ->
    element(2, Color).

-doc """
The blue component of a color.

It returns the blue component of the color, which is an integer ranging from
0 to 255.
""".
-spec blue(graphics:color()) -> integer().
blue(Color) ->
    element(3, Color).

-doc """
The alpha component of a color.

It returns the alpha component of the color, which is an integer ranging from
0 to 255.
""".
-spec alpha(graphics:color()) -> integer().
alpha(Color) ->
    element(4, Color).

-doc """
Convert a color to an integer.

It converts a color to a 32-bit integer in 16xRRGGBBAA format.
""".
-spec to_integer(bml:color()) -> integer().
to_integer({R, G, B, A}) ->
    <<Integer:32>> = <<R:8, G:8, B:8, A:8>>,
    Integer.

-doc """
Create a color from RGB components.

It creates a color from three integers representing the red, green and blue
components, each ranging from 0 to 255, and returns a color tuple with alpha
set to 255.
""".
-spec rgb(channel(), channel(), channel()) -> bml:color().
rgb(Red, Green, Blue) ->
    {Red, Green, Blue, 255}.

-doc """
Create a color from RGBA components.

It takes four integers representing the red, green, blue and alpha components
of the color, each ranging from 0 to 255, and returns a color tuple.
""".
-spec rgba(channel(), channel(), channel(), channel()) -> bml:color().
rgba(Red, Green, Blue, Alpha) ->
    {Red, Green, Blue, Alpha}.

-doc """
Create a color from ARGB components.

It takes four integers representing the alpha, red, green and blue components
of the color, each ranging from 0 to 255, and returns a color tuple.
""".
-spec argb(channel(), channel(), channel(), channel()) -> bml:color().
argb(Alpha, Red, Green, Blue) ->
    {Red, Green, Blue, Alpha}.
