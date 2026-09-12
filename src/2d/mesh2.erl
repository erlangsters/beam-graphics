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

A 2D mesh is a collection of 2D vertices that is typically used for rendering.

A 2D mesh is an opaque object that wraps GPU vertex data. It is created with
the `with_vertices` functions and disposed with the `destroy/1` function.
Copying the term does not copy the GPU buffer.

Each 2D vertex is a position, a color, and UV texture coordinates (see
`graphics:vertex2()`). Meshes are rendered on a frame or a surface with a
primitive type and an optional texture. The primitive type and the texture are
not part of the mesh; they are arguments of `frame:draw_mesh2/4`,
`surface:draw_mesh2/4`, and of `shape2`.

```erlang
{ok, Mesh} = mesh2:with_vertices([
    {{100.0, 100.0}, ?COLOR_RED, 0.0, 0.0},
    {{700.0, 100.0}, ?COLOR_GREEN, 0.0, 0.0},
    {{700.0, 500.0}, ?COLOR_BLUE, 0.0, 0.0}
]).
ok = surface:draw_mesh2(Surface, Mesh, triangles, 3).
```

Together with 3D meshes, meshes are the only means for rendering. Anything
else (for example sprites, text, or shapes) is a higher-level abstraction that
indirectly uses meshes.

Vertex data must live in GPU memory in order to be used for rendering, so
reading and updating vertices have an associated cost. Avoid those operations
when they are not needed. If frequent reading is required, vertices can be
cached locally with the `keep_copy` option at construction, or later with
`keep_local_copy/1`. `local_vertices/1` reads the local copy when it exists.
`remote_vertices/1` reads from GPU memory, which is more expensive. By
default, no local copy is kept.

When vertices are updated often, specify a usage hint (`static`, `dynamic`, or
`stream`) so the GPU can handle the data more efficiently. The default is
`static`.

An empty mesh is allowed. `set_vertices(Mesh, [])` clears the vertices.

Beware that a well-formed 2D vertex always contains floats, not integers.

**OpenGL Internals**

A 2D mesh wraps an OpenGL buffer object. Use `gl_object/1` to retrieve the
buffer id.
""".

-export_type([
    usage_hint/0,
    keep_copy/0
]).
-export_type([
    object/0
]).
-export([
    with_vertices/1, with_vertices/2, with_vertices/3,
    destroy/1,
    set_vertices/2, set_vertices/3,
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
    has_local_copy/1,
    keep_local_copy/1,
    release_local_copy/1
]).
-export([
    gl_object/1
]).

-compile({inline, [
    with_vertices/1, with_vertices/2,
    set_vertices/2,
    vertex_count/1,
    usage_hint/1,
    local_vertices/1,
    update_vertices/2,
    update_vertex/3,
    has_local_copy/1,
    gl_object/1
]}).

% By default, the usage hint is "static".
-define(DEFAULT_USAGE_HINT, static).

% By default, no local copy is kept.
-define(DEFAULT_KEEP_COPY, no_copy).

% Vertex stride in bytes: 2 position + 4 color + 2 UV floats.
-define(VERTEX_STRIDE, (4 * (2 + 4 + 2))).

-doc """
A mesh usage hint.

`static` is for data set once and drawn many times. `dynamic` is for data
modified occasionally. `stream` is for data modified every frame.
""".
-type usage_hint() ::
    static |
    dynamic |
    stream
.

-doc """
A mesh copy policy.

`no_copy` keeps no CPU copy of the vertices. `keep_copy` keeps a local copy.
""".
-type keep_copy() :: no_copy | keep_copy.

-doc """
A 2D mesh object.

It wraps an OpenGL buffer id, the vertex count, the usage hint, and an optional
local copy of the vertices.
""".
-opaque object() :: {
    ResourceId :: {mesh2, gl:buffer()},
    VertexCount :: non_neg_integer(),
    UsageHint :: usage_hint(),
    LocalVertices :: undefined | [graphics:vertex2()]
}.

-doc """
A 2D mesh from a list of vertices.

It constructs a 2D mesh from the given 2D vertices. The usage hint is `static`
and no local copy is kept.

It's equivalent to `with_vertices(Vertices, static)`.
""".
-spec with_vertices([graphics:vertex2()]) -> {ok, object()} | out_of_memory.
with_vertices(Vertices) ->
    with_vertices(Vertices, ?DEFAULT_USAGE_HINT).

-doc """
A 2D mesh from a list of vertices and a usage hint.

It constructs a 2D mesh from the given 2D vertices with the given usage hint.
No local copy is kept.

It's equivalent to `with_vertices(Vertices, UsageHint, no_copy)`.
""".
-spec with_vertices([graphics:vertex2()], usage_hint()) ->
    {ok, object()} | out_of_memory
.
with_vertices(Vertices, UsageHint) ->
    with_vertices(Vertices, UsageHint, ?DEFAULT_KEEP_COPY).

-doc """
A 2D mesh from a list of vertices, a usage hint, and a copy policy.

It constructs a 2D mesh from the given 2D vertices with the given usage hint.
When `KeepCopy` is `keep_copy`, a local copy of the vertices is kept. When it
is `no_copy`, there is no local copy.

The list may be empty. It returns `out_of_memory` when the GPU cannot allocate
the buffer.
""".
-spec with_vertices([graphics:vertex2()], usage_hint(), keep_copy()) ->
    {ok, object()} | out_of_memory
.
with_vertices(Vertices, UsageHint, KeepCopy) ->
    UsageHintRaw = to_usage_hint_raw(UsageHint),
    Data = vertices_to_data(Vertices),
    VertexCount = length(Vertices),
    case acquire_mesh(Data, UsageHintRaw) of
        {error, out_of_memory} ->
            out_of_memory;
        {ok, ResourceId} ->
            LocalVertices = case KeepCopy of
                no_copy ->
                    undefined;
                keep_copy ->
                    Vertices
            end,
            {ok, {ResourceId, VertexCount, UsageHint, LocalVertices}}
    end.

-doc """
Destroy a 2D mesh.

It releases the GPU buffer of the 2D mesh. Using the mesh after it is destroyed
has undefined behavior. Destroying the same mesh twice is invalid.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId, _VertexCount, _UsageHint, _LocalVertices}) ->
    ok = release_mesh(ResourceId),
    ok.

-doc """
Set the vertices of a 2D mesh.

It replaces the vertices of the 2D mesh. The usage hint and the copy policy of
the mesh are preserved. The OpenGL buffer id is unchanged.

It's equivalent to `set_vertices(Mesh, Vertices, usage_hint(Mesh))`.
""".
-spec set_vertices(object(), [graphics:vertex2()]) ->
    {ok, object()} | out_of_memory
.
set_vertices(Mesh, Vertices) ->
    set_vertices(Mesh, Vertices, usage_hint(Mesh)).

-doc """
Set the vertices of a 2D mesh with a usage hint.

It replaces the vertices of the 2D mesh and sets the usage hint. The copy
policy of the mesh is preserved. The OpenGL buffer id is unchanged.

The list may be empty. It returns `out_of_memory` when the GPU cannot allocate
the new data store.
""".
-spec set_vertices(object(), [graphics:vertex2()], usage_hint()) ->
    {ok, object()} | out_of_memory
.
set_vertices(
    {ResourceId, _VertexCount, _UsageHint, LocalVertices},
    Vertices,
    UsageHint
) ->
    UsageHintRaw = to_usage_hint_raw(UsageHint),
    Data = vertices_to_data(Vertices),
    VertexCount = length(Vertices),
    {mesh2, Buffer} = ResourceId,
    case set_mesh_data(Buffer, Data, UsageHintRaw) of
        ok ->
            NewLocalVertices = case LocalVertices of
                undefined ->
                    undefined;
                _ ->
                    Vertices
            end,
            {ok, {ResourceId, VertexCount, UsageHint, NewLocalVertices}};
        out_of_memory ->
            out_of_memory
    end.

-doc """
The number of vertices of a 2D mesh.

It returns the number of vertices currently stored in the 2D mesh.
""".
-spec vertex_count(object()) -> non_neg_integer().
vertex_count({_ResourceId, VertexCount, _UsageHint, _LocalVertices}) ->
    VertexCount.

-doc """
The usage hint of a 2D mesh.

It returns the usage hint last set when constructing or setting the vertices
of the 2D mesh.
""".
-spec usage_hint(object()) -> usage_hint().
usage_hint({_ResourceId, _VertexCount, UsageHint, _LocalVertices}) ->
    UsageHint.

-doc """
The locally cached vertices of a 2D mesh.

It returns the local copy of the vertices when a copy is kept. It returns
`undefined` when no local copy is kept. An empty mesh with a local copy
returns `[]`.

Use `local_vertices/2` to retrieve a slice of the local copy.
""".
-spec local_vertices(object()) -> undefined | [graphics:vertex2()].
local_vertices({_ResourceId, _VertexCount, _UsageHint, undefined}) ->
    undefined;
local_vertices({_ResourceId, _VertexCount, _UsageHint, LocalVertices}) ->
    LocalVertices.

-doc """
A slice of the locally cached vertices of a 2D mesh.

It returns a slice of the local copy using slice range notation. It returns
`undefined` when no local copy is kept, and `no_range` when the range is empty.

```erlang
{ok, Mesh} = mesh2:with_vertices(Vertices, static, keep_copy),
{2, [Second]} = mesh2:local_vertices(Mesh, {1, -1}).
```
""".
-spec local_vertices(object(), slice:range()) ->
    undefined | no_range | {slice:offset(), [graphics:vertex2()]}
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
The GPU vertices of a 2D mesh.

It reads the vertices from GPU memory. This is more expensive than
`local_vertices/1`. An empty mesh returns `[]`.
""".
-spec remote_vertices(object()) -> [graphics:vertex2()].
remote_vertices({_ResourceId, 0, _UsageHint, _LocalVertices}) ->
    [];
remote_vertices({ResourceId, VertexCount, _UsageHint, _LocalVertices}) ->
    {mesh2, Buffer} = ResourceId,
    Data = mesh_data(Buffer, 0, VertexCount * ?VERTEX_STRIDE),
    data_to_vertices(Data).

-doc """
A slice of the GPU vertices of a 2D mesh.

It reads a slice of the vertices from GPU memory using slice range notation.
It returns `no_range` when the range is empty.
""".
-spec remote_vertices(object(), slice:range()) ->
    no_range | {slice:offset(), [graphics:vertex2()]}
.
remote_vertices({ResourceId, VertexCount, _UsageHint, _LocalVertices}, Range) ->
    case slice:range(VertexCount, Range) of
        no_range ->
            no_range;
        {Offset, Length} ->
            {mesh2, Buffer} = ResourceId,
            Data = mesh_data(
                Buffer,
                (Offset - 1) * ?VERTEX_STRIDE,
                Length * ?VERTEX_STRIDE
            ),
            Vertices = data_to_vertices(Data),
            {Offset, Vertices}
    end.

-doc """
A locally cached vertex of a 2D mesh.

It returns a vertex of the local copy, identified by a slice index. The index
is 0-based and may be negative.

```erlang
{ok, Mesh} = mesh2:with_vertices(Vertices, static, keep_copy),
{1, {{0.0, 0.0}, ?COLOR_RED, 0.0, 0.0}} = mesh2:local_vertex(Mesh, 0),
{3, {{0.0, 1.0}, ?COLOR_BLUE, 0.0, 1.0}} = mesh2:local_vertex(Mesh, -1).
```

It returns `undefined` when no local copy is kept, and `out_of_range` when the
index is out of range. The offset in the result is 1-based.
""".
-spec local_vertex(object(), slice:index()) ->
    undefined | out_of_range | {slice:offset(), graphics:vertex2()}
.
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
A GPU vertex of a 2D mesh.

It reads a vertex from GPU memory, identified by a slice index. The index is
0-based and may be negative. It returns `out_of_range` when the index is out
of range. The offset in the result is 1-based.
""".
-spec remote_vertex(object(), slice:index()) ->
    out_of_range | {slice:offset(), graphics:vertex2()}
.
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
                (Offset - 1) * ?VERTEX_STRIDE,
                ?VERTEX_STRIDE
            ),
            [Vertex] = data_to_vertices(Data),
            {Offset, Vertex}
    end.

-doc """
Update the vertices of a 2D mesh from the start.

It writes the given vertices starting at the first vertex. The mesh size is
unchanged. It returns `out_of_range` when the list is longer than the mesh.

It's equivalent to `update_vertices(Mesh, Vertices, 0)`.
""".
-spec update_vertices(object(), [graphics:vertex2()]) ->
    {ok, object()} | out_of_range
.
update_vertices(Mesh, Vertices) ->
    update_vertices(Mesh, Vertices, 0).

-doc """
Update the vertices of a 2D mesh from an index.

It writes the given vertices starting at the given slice index. The index is
0-based and may be negative. The mesh size is unchanged. It returns
`out_of_range` when the index is invalid or the write would not fit.

A zero-length list is a no-op and returns `{ok, Mesh}`.
""".
-spec update_vertices(object(), [graphics:vertex2()], slice:index()) ->
    {ok, object()} | out_of_range
.
update_vertices(Mesh, [], _Index) ->
    {ok, Mesh};
update_vertices(
    {ResourceId, VertexCount, UsageHint, LocalVertices},
    Vertices,
    Index
) ->
    case slice:index(VertexCount, Index) of
        out_of_range ->
            out_of_range;
        Offset when Offset - 1 + length(Vertices) > VertexCount ->
            out_of_range;
        Offset ->
            Data = vertices_to_data(Vertices),
            {mesh2, Buffer} = ResourceId,
            ok = update_mesh_data(
                Buffer,
                (Offset - 1) * ?VERTEX_STRIDE,
                Data
            ),
            NewLocalVertices = case LocalVertices of
                undefined ->
                    undefined;
                _ when length(Vertices) =:= VertexCount ->
                    Vertices;
                _ ->
                    {LeftVertices, _} = lists:split(Offset - 1, LocalVertices),
                    {_, RightVertices} = lists:split(
                        Offset - 1 + length(Vertices),
                        LocalVertices
                    ),
                    LeftVertices ++ Vertices ++ RightVertices
            end,
            {ok, {ResourceId, VertexCount, UsageHint, NewLocalVertices}}
    end.

-doc """
Update a vertex of a 2D mesh.

It writes the given vertex at the given slice index. The index is 0-based and
may be negative.

It's equivalent to `update_vertices(Mesh, [Vertex], Index)`.
""".
-spec update_vertex(object(), graphics:vertex2(), slice:index()) ->
    {ok, object()} | out_of_range
.
update_vertex(Mesh, Vertex, Index) ->
    update_vertices(Mesh, [Vertex], Index).

-doc """
Check whether a 2D mesh keeps a local copy.

It returns `true` when a local copy of the vertices is kept, otherwise
`false`.
""".
-spec has_local_copy(object()) -> boolean().
has_local_copy({_ResourceId, _VertexCount, _UsageHint, undefined}) ->
    false;
has_local_copy({_ResourceId, _VertexCount, _UsageHint, _LocalVertices}) ->
    true.

-doc """
Keep a local copy of a 2D mesh.

It reads the vertices from GPU memory and keeps them as a local copy. It
returns `already_local_copy` when a local copy is already kept.
""".
-spec keep_local_copy(object()) -> {ok, object()} | already_local_copy.
keep_local_copy({_ResourceId, _VertexCount, _UsageHint, undefined} = Mesh) ->
    Vertices = remote_vertices(Mesh),
    {ok, erlang:setelement(4, Mesh, Vertices)};
keep_local_copy({_ResourceId, _VertexCount, _UsageHint, _LocalVertices}) ->
    already_local_copy.

-doc """
Release the local copy of a 2D mesh.

It drops the local copy of the vertices. The GPU buffer is unchanged. It
returns `no_local_copy` when there is no local copy.
""".
-spec release_local_copy(object()) -> {ok, object()} | no_local_copy.
release_local_copy({_ResourceId, _VertexCount, _UsageHint, undefined}) ->
    no_local_copy;
release_local_copy(Mesh) ->
    {ok, erlang:setelement(4, Mesh, undefined)}.

-doc """
The OpenGL buffer of a 2D mesh.

It returns the OpenGL buffer id wrapped by the 2D mesh.
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
    iolist_to_binary(lists:map(
        fun({{X, Y}, {R, G, B, A}, U, V}) ->
            <<
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
        Vertices
    )).

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
        ok = gl:delete_buffers([Buffer]),
        ok
    end,
    AcquireFun = fun() ->
        {ok, [Buffer]} = gl:gen_buffers(1),
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:buffer_data(array_buffer, Data, UsageHint),
        case gl:get_error() of
            {ok, no_error} ->
                ok = gl:bind_buffer(array_buffer, none),
                {ok, {mesh2, Buffer}, ReleaseFun};
            {ok, out_of_memory} ->
                ok = gl:bind_buffer(array_buffer, none),
                ok = gl:delete_buffers([Buffer]),
                {error, out_of_memory}
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

release_mesh(ResourceId) ->
    graphics_context:release_resource(ResourceId).

set_mesh_data(Buffer, Data, UsageHint) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:buffer_data(array_buffer, Data, UsageHint),
        case gl:get_error() of
            {ok, no_error} ->
                ok = gl:bind_buffer(array_buffer, none),
                ok;
            {ok, out_of_memory} ->
                ok = gl:bind_buffer(array_buffer, none),
                out_of_memory
        end
    end).

mesh_data(Buffer, Start, Length) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_buffer(array_buffer, Buffer),
        {ok, Data} = gl:get_buffer_sub_data(array_buffer, Start, Length),
        ok = gl:bind_buffer(array_buffer, none),
        Data
    end).

update_mesh_data(Buffer, Offset, Data) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:buffer_sub_data(array_buffer, Offset, Data),
        ok = gl:bind_buffer(array_buffer, none),
        ok
    end).
