-module(sprite).
-export([]).

-export([sprite/3]).

-include_lib("beam_graphics/include/graphics.hrl").

-spec sprite(
    Position :: graphics:vector2(),
    Size :: graphics:vector2(),
    Texture :: graphics:texture()
) ->
    graphics:shape2()
.
sprite({X, Y}, {Width, Height}, Texture) ->
    {ok, Mesh} = mesh2:with_vertices([
        {{X,         Y},          ?COLOR_WHITE, 0.0, 0.0},
        {{X + Width, Y},          ?COLOR_WHITE, 1.0, 0.0},
        {{X + Width, Y + Height}, ?COLOR_WHITE, 1.0, 1.0},
        {{X,         Y + Height}, ?COLOR_WHITE, 0.0, 1.0}
    ]),
    shape2:with_mesh(Mesh, triangle_fan, 4, Texture).
