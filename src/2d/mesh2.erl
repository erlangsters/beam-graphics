%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(mesh2).
-moduledoc """
2D Mesh

A 2D mesh is a collection of 2D vertices which are used for rendering. Each 2D
vertex specifies a position in 2D space, a color and texture coordinates. They
are rendered on a surface by using one of the following rendering primitives,
and an optional texture.

For instance, the following will render a colored triangle.

```erlang
Mesh = mesh:with_vertices([
    {100.0, 100.0, ?COLOR_RED, 0.0, 0.0},
    {700.0, 100.00, ?COLOR_GREEN, 0.0, 0.0},
    {700.0, 500.00, ?COLOR_BLUE, 0.0, 0.0}
]).
surface:render(Surface, Mesh, triangle_fan, no_texture).
```

> How vertices are used to produce a visual output depends on the rendering
> primitive which is described in the OpenGL documentation.

> Together with 3D meshes, meshes are the only mean for rendering. Anything
> else (.e.g., sprites, text, shapes, etc.) is a higher-level abstraction that
> indirectly uses meshes for rendering.

Mesh vertices must live in the GPU memory in order to be used for rendering,
and therefore, reading and updating vertices have an associated cost. Avoid
those operations as much as possible, and if frequent reading is required,
pixels can be cached locally with the `keep_copy` option. It explains the
local/remote semantics in the API. For instance, `local_vertices/1` will read
the vertices from a local copy (if it exists), while `remote_image/1` will read
the vertices from the GPU memory (which is more expensive).

While updating a 2D mesh should be avoided when not necessary, it's acceptable
to frequently update its vertices. To help the GPU with handling the data in
the most optimal way, you can specify a usage hint when setting the vertices.








To empty the mesh, you can call `set_vertices(Mesh, [])`.
If you need to "pre-allocate" the mesh. Fill it with "zero" vertices.



**OpenGL Internals**

It wraps a buffer object.
To be written.

Use the `handle/1` function to retrieve the OpenGL buffer ID.
It's created by the root context, which you can retrieve with the
`graphics_context:inner_context/0` function.

```
XXX: The slice:offset in update_vertices and vertex functions is weird.
XXX: Clarify what happens if destroyed twice ?
XXX: Implement a merge/x or combine/x function to concatenate two meshes.
XXX: Update vertices functions are to be implemented.
XXX: Implement transfer "ownership".
XXX: Consider vector2() instead of X, Y.
XXX: Consider adding a sort of "normalized_float()" type for U V components.
XXX: Should it expose the other usage hint (OpenGL defines more than that).
XXX: Consider combining `no_copy | keep_copy` and usage_hint() into an "options".
XXX: Consider implementing:

-spec set_position(mesh3(), index(), vector3()) -> ok.
-spec set_color(mesh3(), index(), color_rgba()) -> ok.
-spec set_texcoord(mesh3(), index(), vector2()) -> ok.


XXX: About usage hints:

OpenGL Usage Hint	Meaning
GL_STATIC_DRAW (default)	Data set once, used many times (e.g., level geometry)
GL_DYNAMIC_DRAW	Data modified occasionally, used many times (e.g., animated meshes)
GL_STREAM_DRAW	Data modified every frame (e.g., particle systems)
GL_STATIC_READ	Data written by GPU (e.g., compute shader output)
GL_DYNAMIC_READ	Data occasionally written by GPU, read by CPU
GL_STREAM_READ	Data written by GPU every frame, read by CPU
GL_STATIC_COPY	Data written by GPU, used by GPU (rare)
GL_DYNAMIC_COPY	Data occasionally written by GPU, used by GPU
GL_STREAM_COPY	Data written by GPU every frame, used by GPU
```
""".

-export_type([
    vertex/0,
    vertices/0,
    usage_hint/0
]).
-export_type([
    object/0
]).
-export([
    with_vertices/1, with_vertices/2, with_vertices/3,
    destroy/1,
    set_vertices/2, set_vertices/3, set_vertices/4,
    vertex_count/1,
    usage_hint/1,
    local_vertices/1, local_vertices/2,
    remote_vertices/1, remote_vertices/2,
    local_vertex/2,
    remote_vertex/2,
    update_vertices/2, update_vertices/3,
    update_vertex/3
]).
-export([
    % update_from_mesh/2
]).
-export([
    gl_object/1
]).
-export([
    % has_local_copy/1,
    % keep_local_copy/1,
    % release_local_copy/1
]).

% By default, the usage hint is "static".
-define(DEFAULT_USAGE_HINT, static).

% By default, no local copy is kept.
-define(DEFAULT_KEEP_COPY, no_copy).

% Vertex stride in bytes.
-define(VERTEX_STRIDE, 20).

-doc """
To be written.
""".
-type vertex() :: {
    X :: float(),
    Y :: float(),
    Color :: graphics:color(),
    U :: float(),
    V :: float()
}.

-doc """
To be written.
""".
-type vertices() :: [vertex()].

-doc """
To be written.
""".
-type usage_hint() ::
    static |
    dynamic |
    stream
.

-doc """
To be written.
""".
-type keep_copy() :: no_copy | keep_copy.

-doc """
A 2D mesh object.

It wraps the OpenGL buffer ID and possibly a local copy of the vertices.
""".
-opaque object() :: {
    ResourceId :: {mesh2, gl:buffer()},
    VertexCount :: non_neg_integer(),
    UsageHint :: usage_hint(),
    LocalVertices :: undefined | vertices()
}.

-doc """
To be written.

To be written.
""".
-spec with_vertices(vertices()) -> {ok, object()}.
with_vertices(Vertices) ->
    with_vertices(Vertices, ?DEFAULT_USAGE_HINT).

-doc """
To be written.

To be written.
""".
-spec with_vertices(vertices(), usage_hint()) -> {ok, object()}.
with_vertices(Vertices, UsageHint) ->
    with_vertices(Vertices, UsageHint, ?DEFAULT_KEEP_COPY).

-doc """
To be written.

To be written.
""".
-spec with_vertices(vertices(), usage_hint(), keep_copy()) -> {ok, object()}.
with_vertices(Vertices, UsageHint, KeepCopy) ->
    UsageHintRaw = to_usage_hint_raw(UsageHint),
    Data = vertices_to_data(Vertices),
    VertexCount = length(Vertices),
    case acquire_mesh(Data, UsageHintRaw) of
        {error, out_of_memory} ->
            out_of_memory;
        {ok, ResourceId} ->
            Mesh = case KeepCopy of
                no_copy ->
                    {ResourceId, VertexCount, UsageHint, undefined};
                keep_copy ->
                    {ResourceId, VertexCount, UsageHint, Vertices}
            end,
            {ok, Mesh}
    end.

-doc """
To be written.

To be written.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId, _VertexCount, _UsageHint, _LocalVertices}) ->
    ok = release_mesh(ResourceId),
    ok.

-doc """
Set the vertices of the mesh.

It sets the vertices foobar.

It's equivalent to `set_vertices(Mesh, Vertices, static)`.

See `set_vertices/3` for more details.
""".
-spec set_vertices(object(), vertices()) -> {ok, object()} | out_of_memory.
set_vertices(Mesh, Vertices) ->
    set_vertices(Mesh, Vertices, ?DEFAULT_USAGE_HINT).

-doc """
Set the vertices of the mesh.

It sets the vertices.

It's equivalent to `set_vertices(Mesh, Vertices, UsageHint, no_copy)`.

See `set_vertices/3` for more details.
""".
-spec set_vertices(object(), vertices(), usage_hint()) ->
    {ok, object()} | out_of_memory
.
set_vertices(Mesh, Vertices, UsageHint) ->
    set_vertices(Mesh, Vertices, UsageHint, ?DEFAULT_KEEP_COPY).

-doc """
Set the vertices of the mesh.

It sets the vertices foobar.
""".
-spec set_vertices(object(), vertices(), usage_hint(), keep_copy()) ->
    {ok, object()} | out_of_memory
.
set_vertices(
    {ResourceId, _VertexCount, _UsageHint, _LocalVertices},
    Vertices,
    UsageHint,
    KeepCopy
) ->
    UsageHintRaw = to_usage_hint_raw(UsageHint),
    Data = vertices_to_data(Vertices),
    VertexCount = length(Vertices),

    {mesh2, Buffer} = ResourceId,
    case set_mesh_data(Buffer, Data, UsageHintRaw) of
        ok ->
            NewMesh = case KeepCopy of
                no_copy ->
                    {ResourceId, VertexCount, UsageHint, undefined};
                keep_copy ->
                    {ResourceId, VertexCount, UsageHint, Vertices}
            end,
            {ok, NewMesh};
        out_of_memory ->
            out_of_memory
    end.

-doc """
The number of vertices in the mesh.

It returns the number of vertices that are currently set in the mesh,
as set by `set_vertices/2`.
""".
-spec vertex_count(object()) -> non_neg_integer().
vertex_count({_ResourceId, VertexCount, _UsageHint, _LocalVertices}) ->
    VertexCount.

-doc """
The usage hint of the mesh.

To be written.
as set by `set_vertices/2`.
""".
-spec usage_hint(object()) -> usage_hint().
usage_hint({_ResourceId, _VertexCount, UsageHint, _LocalVertices}) ->
    UsageHint.

-doc """
The locally cached vertices of the mesh.

It returns the local copy of the vertices that are currently set in the mesh,
if a copy was with the set`

If no local vertex data is cached, it returns `undefined`.

Use `local_vertices/2` to only retrieve a subset of the vertices using the
slice notation.

It returns `undefined` if no local copy is kept.
By default, no local copy is kept
""".
-spec local_vertices(object()) -> undefined | vertices().
local_vertices({_ResourceId, _VertexCount, _UsageHint, undefined}) ->
    undefined;
local_vertices({_ResourceId, _VertexCount, _UsageHint, LocalVertices}) ->
    LocalVertices.

-doc """
A slice of the locally cached vertices of the mesh.

It returns the local copy of the vertices that are currently set in the mesh,
if a copy was with the set`

It returns `undefined` if no local copy is kept.
By default, no local copy is kept
""".
-spec local_vertices(object(), slice:range()) ->
    undefined | no_range | {slice:offset(), vertices()}
.
local_vertices({_ResourceId, _VertexCount, _UsageHint, undefined}, _Range) ->
    undefined;
local_vertices({_ResourceId, VertexCount, _UsageHint, LocalVertices}, Range) ->
    case slice:range(VertexCount, Range) of
        no_range ->
            no_range;
        {Offset, Length} ->
            Vertices = lists:sublist(LocalVertices, Offset, Length),
            {Offset, Vertices}
    end.

-doc """
To be written.

To be written.
""".
-spec remote_vertices(object()) -> vertices().
remote_vertices({_ResourceId, 0, _UsageHint, _LocalVertices}) ->
    [];
remote_vertices({ResourceId, VertexCount, _UsageHint, _LocalVertices}) ->
    {mesh2, Buffer} = ResourceId,
    Data = mesh_data(Buffer, 0, VertexCount * ?VERTEX_STRIDE),
    data_to_vertices(Data).

-doc """
To be written.

To be written.
""".
-spec remote_vertices(object(), slice:range()) ->
    no_range | {slice:offset(), vertices()}.
remote_vertices({ResourceId, VertexCount, _UsageHint, _LocalVertices}, Range) ->
    case slice:range(VertexCount, Range) of
        no_range ->
            no_range;
        {Offset, Length} ->
            {mesh2, Buffer} = ResourceId,
            Data = mesh_data(
                Buffer,
                (Offset-1) * ?VERTEX_STRIDE,
                Length * ?VERTEX_STRIDE
            ),
            Vertices = data_to_vertices(Data),
            {Offset, Vertices}
    end.

-doc """
A vertex of the mesh.

It returns a specific vertex of the mesh, identified by a slice index.

```erlang
Vertices = [
    {0.0, 0.0, ?COLOR_RED, 0.0, 0.0},
    {1.0, 0.0, ?COLOR_GREEN, 1.0, 0.0},
    {0.0, 0.0, ?COLOR_BLUE, 0.0, 0.0}
].
Mesh = mesh:with_vertices(Vertices, with_copy).

{0.0, 0.0, ?COLOR_RED, 0.0, 0.0} = mesh:local_vertices(Mesh, 0).
{0.0, 0.0, ?COLOR_BLUE, 0.0, 0.0} = mesh:local_vertices(Mesh, -1).
```

It returns `undefined` if no local copy is kept. If the index is out of range,
it returns `out_of_range`.
""".
-spec local_vertex(object(), slice:index()) ->
    undefined | out_of_range | {slice:offset(), vertex()}.
local_vertex({_ResourceId, _VertexCount, _UsageHint, undefined}, _Index) ->
    undefined;
local_vertex({_ResourceId, VertexCount, _UsageHint, LocalVertices}, Index) ->
    case slice:index(VertexCount, Index) of
        out_of_range ->
            out_of_range;
        Offset ->
            Vertex = lists:nth(Offset, LocalVertices),
            {Offset, Vertex}
    end.

-doc """
To be written.

To be written.
""".
-spec remote_vertex(object(), slice:index()) ->
    out_of_range | {slice:offset(), vertex()}.
remote_vertex(
    {ResourceId, VertexCount, _UsageHint, _LocalVertices},
    Index
) ->
    case slice:index(VertexCount, Index) of
        out_of_range ->
            out_of_range;
        Offset ->
            {mesh2, Buffer} = ResourceId,
            Data = mesh_data(
                Buffer,
                (Offset-1) * ?VERTEX_STRIDE,
                ?VERTEX_STRIDE
            ),
            [Vertex] = data_to_vertices(Data),
            {Offset, Vertex}
    end.

-doc """
To be written.

To be written.
""".
-spec update_vertices(object(), vertices()) -> {ok, object()}.
update_vertices(_Mesh, _Vertices) ->
    update_vertices(_Mesh, _Vertices, 1).

-doc """
To be written.

To be written.
""".
-spec update_vertices(object(), vertices(), slice:offset()) ->
    {ok, object()} | out_of_range.
update_vertices(
    {ResourceId, VertexCount, UsageHint, LocalVertices},
    Vertices,
    Offset
) ->
    case (Offset-1) + length(Vertices) > VertexCount of
        true ->
            out_of_range;
        false ->
            Data = vertices_to_data(Vertices),
            {mesh2, Buffer} = ResourceId,
            ok = update_mesh_data(
                Buffer,
                (Offset-1) * ?VERTEX_STRIDE,
                Data
            ),
            NewMesh = case LocalVertices of
                undefined ->
                    {ResourceId, VertexCount, UsageHint, undefined};
                _ when length(Vertices) =:= VertexCount ->
                    % If the number of vertices is the same, we can just
                    % replace the local vertices.
                    {ResourceId, VertexCount, UsageHint, Vertices};
                _ ->
                    {LeftVertices, _} = lists:split((Offset-1), LocalVertices),
                    {_, RightVertices} = lists:split((Offset-1) + length(Vertices), LocalVertices),
                    NewLocalVertices =
                        LeftVertices ++ Vertices ++ RightVertices,
                    {ResourceId, VertexCount, UsageHint, NewLocalVertices}
            end,
            {ok, NewMesh}
    end.

-doc """
To be written.

To be written.
""".
-spec update_vertex(object(), vertex(), slice:offset()) -> ok.
update_vertex(Mesh, Vertex, Offset) ->
    update_vertices(Mesh, [Vertex], Offset).

-doc """
To be written.

To be written.
""".
-spec gl_object(object()) -> gl:buffer().
gl_object({{mesh2, Buffer}, _VertexCount, _UsageHint, _LocalVertices}) ->
    Buffer.

to_usage_hint_raw(UsageHint) ->
    case UsageHint of
        static -> static_draw;
        dynamic -> dynamic_draw;
        stream -> stream_draw
    end.

vertices_to_data(Vertices) ->
    lists:foldl(
        fun({{X, Y}, {R, G, B, A}, U, V}, Acc) ->
            <<
                Acc/binary,
                X:32/float-little,
                Y:32/float-little,
                R:32/float-little,
                G:32/float-little,
                B:32/float-little,
                A:32/float-little,
                U:32/float-little,
                V:32/float-little
            >>
        end,
        <<>>,
        Vertices
    ).

data_to_vertices(Data) ->
    data_to_vertices(Data, []).

data_to_vertices(<<>>, Vertices) ->
    lists:reverse(Vertices);
data_to_vertices(Data, Vertices) ->
    <<
        X:32/float-little,
        Y:32/float-little,
        R:32/float-little,
        G:32/float-little,
        B:32/float-little,
        A:32/float-little,
        U:32/float-little,
        V:32/float-little,
        DataRest/binary
    >> = Data,
    Vertex = {{X, Y}, {R, G, B, A}, U, V},
    data_to_vertices(DataRest, [Vertex | Vertices]).

acquire_mesh(Data, UsageHint) ->
    ReleaseFun = fun({mesh2, Buffer}) ->
        ok = gl:delete_buffers(1, [Buffer]),
        ok
    end,
    AcquireFun = fun() ->
        {ok, [Buffer]} = gl:gen_buffers(1),
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:buffer_data(array_buffer, size(Data), Data, UsageHint),
        case gl:get_error() of
            no_error ->
                ok = gl:bind_buffer(array_buffer, 0),
                {ok, {mesh2, Buffer}, ReleaseFun};
            out_of_memory ->
                % XXX: unit test this behavior
                ok = gl:delete_buffers(1, [Buffer]),
                {error, out_of_memory}
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

release_mesh(ResourceId) ->
    graphics_context:release_resource(ResourceId).

set_mesh_data(Buffer, Data, UsageHint) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:buffer_data(array_buffer, size(Data), Data, UsageHint),
        case gl:get_error() of
            no_error ->
                ok;
            out_of_memory ->
                % XXX: unit test this behavior
                out_of_memory
        end
    end).

mesh_data(Buffer, Start, Length) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_buffer(array_buffer, Buffer),
        {ok, Data} = gl:get_buffer_sub_data(array_buffer, Start, Length),
        ok = gl:bind_buffer(array_buffer, 0),
        Data
    end).

update_mesh_data(Buffer, Offset, Data) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:buffer_sub_data(array_buffer, Offset, size(Data), Data),
        ok = gl:bind_buffer(array_buffer, 0),
        ok
    end).
