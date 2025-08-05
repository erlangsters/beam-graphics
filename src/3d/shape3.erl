%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(shape3).
-moduledoc """
To be written.

To be written.
""".

-export([
    with_mesh/3, with_mesh/4,
    with_meshes/1, with_meshes/2,
    destroy/1
]).
-export([
    point/2,
    line/3,
    triangle/4
]).

-compile({inline, [
    with_mesh/3, with_mesh/4,
    with_meshes/1, with_meshes/2
]}).
-compile({inline, [
    point/2,
    line/3,
    triangle/4
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-doc """
To be written.

To be written.
""".
-spec with_mesh(
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count()
) ->
    graphics:shape3()
.
with_mesh(Mesh, PrimitiveType, VertexCount) ->
    with_mesh(Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
To be written.

To be written.
""".
-spec with_mesh(
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
with_mesh(Mesh, PrimitiveType, VertexCount, Texture) ->
    #shape3{
        meshes = [{Mesh, PrimitiveType, VertexCount}],
        texture = Texture
    }.

-doc """
To be written.

To be written.
""".
-spec with_meshes(
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}]
) ->
    graphics:shape3()
.
with_meshes(Meshes) ->
    with_meshes(Meshes, no_texture).

-doc """
To be written.

To be written.
""".
-spec with_meshes(
    [{graphics:mesh3(), graphics:primitive_type(), graphics:vertex_count()}],
    no_texture | graphics:texture()
) ->
    graphics:shape3()
.
with_meshes(Meshes, Texture) ->
    #shape3{
        meshes = Meshes,
        texture = Texture
    }.

-doc """
To be written.

To be written.
""".
-spec destroy(graphics:shape3()) -> ok.
destroy(#shape3{meshes = Meshes}) ->
    lists:foreach(fun({Mesh, _PrimitiveType, _VertexCount}) ->
        mesh3:destroy(Mesh)
    end, Meshes).

-doc """
To be written.

To be written.
""".
-spec point(graphics:vector3(), graphics:color()) -> graphics:shape3().
point(Position, Color) ->
    {ok, Mesh} = mesh3:with_vertices([?VERTEX3(Position, Color)]),
    shape3:with_mesh(Mesh, points, 1).

-doc """
To be written.

To be written.
""".
-spec line(
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    graphics:shape3()
.
line(From, To, Color) ->
    {ok, Mesh} = mesh3:with_vertices([
        ?VERTEX3(From, Color),
        ?VERTEX3(To, Color)
    ]),
    shape3:with_mesh(Mesh, lines, 2).

-doc """
To be written.

To be written.
""".
-spec triangle(
    graphics:vector3(),
    graphics:vector3(),
    graphics:vector3(),
    graphics:color()
) ->
    graphics:shape3()
.
triangle(A, B, C, Color) ->
    {ok, Mesh} = mesh3:with_vertices([
        ?VERTEX3(A, Color),
        ?VERTEX3(B, Color),
        ?VERTEX3(C, Color)
    ]),
    shape3:with_mesh(Mesh, triangles, 3).
