%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_view2).
-moduledoc """
2D View

A 2D view is a 3x3 matrix that is typically used to represent an orthographic
projection in the Euclidean plane.

There is no extra data structure. This module constructs 3x3 matrices that map
a rectangle of view space to clip space. The matrix itself is a
`graphics:matrix3()` value.

```erlang
M = graphics_view2:orthographic(0.0, 800.0, 0.0, 600.0).
{-1.0, -1.0} = graphics_matrix3:multiply_vector(M, {0.0, 0.0}).
{1.0, 1.0} = graphics_matrix3:multiply_vector(M, {800.0, 600.0}).
```

A 2D view can also be constructed from a 2D box. The box is the visible
rectangle when Y increases upward. To flip Y, use `orthographic/4` with Bottom
greater than Top; a well-formed box cannot represent that.

The observer that chooses where that rectangle sits in the world is a separate
value; see the `graphics_camera2` module.

Beware that a well-formed 3x3 matrix always contains floats, not integers.
""".

-export([
    orthographic/1, orthographic/4
]).

-doc """
An orthographic 3x3 matrix from a 2D box.

It constructs a 3x3 matrix that maps the given 2D box to clip space. It is the
same as `orthographic(MinX, MaxX, MinY, MaxY)`.

```erlang
M = graphics_view2:orthographic({{0.0, 0.0}, {800.0, 600.0}}).
{-1.0, -1.0} = graphics_matrix3:multiply_vector(M, {0.0, 0.0}).
```
""".
-spec orthographic(graphics:box2()) -> graphics:matrix3().
orthographic({{MinX, MinY}, {MaxX, MaxY}}) ->
    orthographic(MinX, MaxX, MinY, MaxY).

-doc """
An orthographic 3x3 matrix.

It constructs a 3x3 matrix that maps the rectangle `Left` to `Right` and
`Bottom` to `Top` to clip space. Y increases upward when `Bottom` is less than
`Top`. Swap `Bottom` and `Top` to flip Y.

```erlang
{-1.0, 1.0} = graphics_matrix3:multiply_vector(
    graphics_view2:orthographic(0.0, 800.0, 600.0, 0.0),
    {0.0, 0.0}
).
```
""".
-spec orthographic(float(), float(), float(), float()) -> graphics:matrix3().
orthographic(Left, Right, Bottom, Top) ->
    Tx = -(Right + Left) / (Right - Left),
    Ty = -(Top + Bottom) / (Top - Bottom),
    {
        2.0 / (Right - Left), 0.0, 0.0,
        0.0, 2.0 / (Top - Bottom), 0.0,
        Tx, Ty, 1.0
    }.
