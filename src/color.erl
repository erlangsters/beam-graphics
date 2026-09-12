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
Color

A color is a quadruplet of numbers that is typically used to represent the
red, green, blue, and alpha channels of a pixel, a vertex, or a clear value.

The data structure of a color simply is a tuple of 4 floats where the first
component is red, the second is green, the third is blue, and the fourth is
alpha. Therefore, colors can be naturally created with the tuple syntax.

```erlang
C = {1.0, 0.0, 0.0, 1.0}.
```

To access the red component of a color, use the `red/1` function, to access
the green component, use the `green/1` function, to access the blue
component, use the `blue/1` function, and to access the alpha component, use
the `alpha/1` function.

```erlang
1.0 = color:red(C).
0.0 = color:green(C).
0.0 = color:blue(C).
1.0 = color:alpha(C).
```

`rgb/3` constructs a color from three channels and sets alpha to 1.0.
`rgba/4` is the four-channel form of the tuple.

```erlang
{1.0, 0.0, 0.0, 1.0} = color:rgb(1.0, 0.0, 0.0).
```

Macros are also defined for the common named colors. (The `graphics.hrl`
header must be included.)

```erlang
{1.0, 0.0, 0.0, 1.0} = ?COLOR_RED
```

An 8-bit representation is available for hex values and image bytes.
`from_bytes/3` and `from_bytes/4` take integers typically in 0 to 255.
`to_bytes/1` returns that form. `from_integer/1` and `to_integer/1` pack the
same bytes as an unsigned `16#RRGGBBAA` integer. Named colors round-trip
through 8-bit. Arbitrary floats do not.

```erlang
{1.0, 0.0, 0.0, 1.0} = color:from_bytes(255, 0, 0).
16#FF0000FF = color:to_integer(?COLOR_RED).
```

Two colors can be linearly interpolated with `lerp/3`, and multiplied
component-wise with `multiply/2` (tint or modulate). `multiply/2` multiplies
two colors, not a color and a scalar.

Beware that a well-formed color always contains floats, not integers.
""".

-export_type([
    channel/0
]).
-export([
    red/1, green/1, blue/1, alpha/1
]).
-export([
    rgb/3,
    rgba/4
]).
-export([
    from_bytes/3, from_bytes/4,
    to_bytes/1
]).
-export([
    from_integer/1,
    to_integer/1
]).
-export([
    is_equal_to/2, is_equal_to/3
]).
-export([
    lerp/3,
    multiply/2
]).

-compile({inline, [
    red/1, green/1, blue/1, alpha/1,
    rgb/3,
    rgba/4,
    from_bytes/3, from_bytes/4,
    is_equal_to/2, is_equal_to/3,
    lerp/3,
    multiply/2
]}).

-doc """
A color channel.

A float typically in the range 0.0 to 1.0.
""".
-type channel() :: float().

-doc """
The red component of a color.

It returns the red component of the color.
""".
-spec red(graphics:color()) -> channel().
red({Red, _, _, _}) ->
    Red.

-doc """
The green component of a color.

It returns the green component of the color.
""".
-spec green(graphics:color()) -> channel().
green({_, Green, _, _}) ->
    Green.

-doc """
The blue component of a color.

It returns the blue component of the color.
""".
-spec blue(graphics:color()) -> channel().
blue({_, _, Blue, _}) ->
    Blue.

-doc """
The alpha component of a color.

It returns the alpha component of the color.
""".
-spec alpha(graphics:color()) -> channel().
alpha({_, _, _, Alpha}) ->
    Alpha.

-doc """
A color from RGB channels.

It constructs a color from the given red, green, and blue channels. The alpha
channel is set to 1.0.

```erlang
{1.0, 0.0, 0.0, 1.0} = color:rgb(1.0, 0.0, 0.0).
```
""".
-spec rgb(channel(), channel(), channel()) -> graphics:color().
rgb(Red, Green, Blue) ->
    {Red, Green, Blue, 1.0}.

-doc """
A color from RGBA channels.

It constructs a color from the given red, green, blue, and alpha channels.

```erlang
{1.0, 0.0, 0.0, 0.5} = color:rgba(1.0, 0.0, 0.0, 0.5).
```
""".
-spec rgba(channel(), channel(), channel(), channel()) -> graphics:color().
rgba(Red, Green, Blue, Alpha) ->
    {Red, Green, Blue, Alpha}.

-doc """
A color from 8-bit RGB channels.

It constructs a color from three integers typically in the range 0 to 255.
The alpha channel is set to 255. Each byte is divided by 255.0.

It's equivalent to `from_bytes(Red, Green, Blue, 255)`.
""".
-spec from_bytes(integer(), integer(), integer()) -> graphics:color().
from_bytes(Red, Green, Blue) ->
    from_bytes(Red, Green, Blue, 255).

-doc """
A color from 8-bit RGBA channels.

It constructs a color from four integers typically in the range 0 to 255.
Each byte is divided by 255.0.

```erlang
{1.0, 0.0, 0.0, 1.0} = color:from_bytes(255, 0, 0, 255).
```
""".
-spec from_bytes(integer(), integer(), integer(), integer()) ->
    graphics:color().
from_bytes(Red, Green, Blue, Alpha) ->
    {Red / 255.0, Green / 255.0, Blue / 255.0, Alpha / 255.0}.

-doc """
The 8-bit channels of a color.

It converts each channel to an integer in the range 0 to 255. Channels
outside `[0.0, 1.0]` are clamped. Named colors round-trip through 8-bit.
Arbitrary floats do not.
""".
-spec to_bytes(graphics:color()) ->
    {integer(), integer(), integer(), integer()}.
to_bytes({Red, Green, Blue, Alpha}) ->
    {
        channel_to_byte(Red),
        channel_to_byte(Green),
        channel_to_byte(Blue),
        channel_to_byte(Alpha)
    }.

-doc """
A color from a packed integer.

It constructs a color from an unsigned 32-bit integer in `16#RRGGBBAA`
format.

```erlang
{1.0, 0.0, 0.0, 1.0} = color:from_integer(16#FF0000FF).
```
""".
-spec from_integer(integer()) -> graphics:color().
from_integer(Integer) ->
    <<Red:8, Green:8, Blue:8, Alpha:8>> = <<Integer:32>>,
    from_bytes(Red, Green, Blue, Alpha).

-doc """
Convert a color to a packed integer.

It converts a color to an unsigned 32-bit integer in `16#RRGGBBAA` format.
The conversion goes through `to_bytes/1`.

```erlang
16#FF0000FF = color:to_integer({1.0, 0.0, 0.0, 1.0}).
```
""".
-spec to_integer(graphics:color()) -> integer().
to_integer(Color) ->
    {Red, Green, Blue, Alpha} = to_bytes(Color),
    <<Integer:32>> = <<Red:8, Green:8, Blue:8, Alpha:8>>,
    Integer.

-doc """
Check whether two colors are equal.

It returns `true` when all four channels compare equal. The values `+0.0`
and `-0.0` are treated as equal.
""".
-spec is_equal_to(graphics:color(), graphics:color()) -> boolean().
is_equal_to({R1, G1, B1, A1}, {R2, G2, B2, A2}) ->
    R1 == R2 andalso G1 == G2 andalso B1 == B2 andalso A1 == A2.

-doc """
Check whether two colors are equal within an epsilon.

It returns `true` when each pair of corresponding channels differs by at
most `Epsilon`.
""".
-spec is_equal_to(graphics:color(), graphics:color(), float()) -> boolean().
is_equal_to({R1, G1, B1, A1}, {R2, G2, B2, A2}, Epsilon) ->
    erlang:abs(R1 - R2) =< Epsilon
        andalso erlang:abs(G1 - G2) =< Epsilon
        andalso erlang:abs(B1 - B2) =< Epsilon
        andalso erlang:abs(A1 - A2) =< Epsilon.

-doc """
Linearly interpolate two colors.

It interpolates from the first color to the second using `T`. When `T` is
0.0 the result is the first color, and when `T` is 1.0 the result is the
second. `T` is not clamped, so values outside `[0.0, 1.0]` extrapolate.
""".
-spec lerp(graphics:color(), graphics:color(), float()) -> graphics:color().
lerp({R1, G1, B1, A1}, {R2, G2, B2, A2}, T) ->
    {
        R1 + T * (R2 - R1),
        G1 + T * (G2 - G1),
        B1 + T * (B2 - B1),
        A1 + T * (A2 - A1)
    }.

-doc """
Multiply two colors.

It multiplies two colors component-wise. If the colors are denoted C1 and
C2, each channel of the result is the product of the corresponding channels.
This is tinting or modulating. It is not multiplication by a scalar.
""".
-spec multiply(graphics:color(), graphics:color()) -> graphics:color().
multiply({R1, G1, B1, A1}, {R2, G2, B2, A2}) ->
    {R1 * R2, G1 * G2, B1 * B2, A1 * A2}.

channel_to_byte(Channel) when Channel =< 0.0 ->
    0;
channel_to_byte(Channel) when Channel >= 1.0 ->
    255;
channel_to_byte(Channel) ->
    round(Channel * 255.0).
