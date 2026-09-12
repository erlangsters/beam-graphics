%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(sprite).
-moduledoc """
Sprite

A sprite is a textured 2D rectangle that is typically used for displaying an
image.

There is no extra data structure. This module constructs a 2D shape for that
case. The shape is a `graphics:shape2()` value; see the `shape2` module.

```erlang
{ok, Sprite} = sprite:from_texture({0.0, 0.0}, {64.0, 64.0}, Texture).
ok = surface:draw_shape2(Surface, Sprite).
ok = shape2:destroy(Sprite).
```

`Position` is the minimum corner. `Size` is the full width and height. The
rectangle extends in `+X` and `+Y`, matching `shape2:rectangle/3`. Vertex UVs
span `(0.0, 0.0)` to `(1.0, 1.0)` so the texture is mapped onto the rectangle.
Vertex color defaults to white so the texture is unmodulated. Pass a color to
tint it.

The texture is not owned. `shape2:destroy/1` destroys the mesh and does not
destroy the texture. The model matrix is the identity.

There is no `sprite3`. A sprite is a 2D rectangle. Textured 3D geometry is
built with `shape3:with_mesh/4`.

Beware that a well-formed sprite always uses floats, not integers, for
position, size, and color.
""".

-export([
    from_texture/3, from_texture/4
]).

-compile({inline, [
    from_texture/3
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-doc """
A sprite from a texture.

It constructs a 2D shape that draws the given texture on an axis-aligned
rectangle. Vertex color is white.

It's equivalent to `from_texture(Position, Size, Texture, ?COLOR_WHITE)`.
""".
-spec from_texture(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Texture :: graphics:texture()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
from_texture(Position, Size, Texture) ->
    from_texture(Position, Size, Texture, ?COLOR_WHITE).

-doc """
A sprite from a texture and a color.

It constructs a 2D shape that draws the given texture on an axis-aligned
rectangle. `Position` is the minimum corner. `Size` is the full width and
height. The rectangle extends in `+X` and `+Y`, matching `shape2:rectangle/3`.
Vertex UVs span `(0.0, 0.0)` to `(1.0, 1.0)` so the texture is mapped onto
the rectangle. `Color` tints the texture.

The texture is not owned. The model matrix is the identity.

```erlang
{ok, Sprite} = sprite:from_texture(
    {0.0, 0.0},
    {100.0, 50.0},
    Texture,
    ?COLOR_WHITE
).
```
""".
-spec from_texture(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Texture :: graphics:texture(),
    Color :: graphics:color()
) ->
    {ok, graphics:shape2()} | out_of_memory
.
from_texture({X, Y}, {Width, Height}, Texture, Color) ->
    Vertices = [
        {{X,         Y},          Color, 0.0, 0.0},
        {{X + Width, Y},          Color, 1.0, 0.0},
        {{X + Width, Y + Height}, Color, 1.0, 1.0},
        {{X,         Y + Height}, Color, 0.0, 1.0}
    ],
    case mesh2:with_vertices(Vertices) of
        {ok, Mesh} ->
            {ok, shape2:with_mesh(Mesh, triangle_fan, 4, Texture)};
        out_of_memory ->
            out_of_memory
    end.
