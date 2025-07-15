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
To be written.

To be written.
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
    gl_object/1
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
To be written.

To be written.
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
To be written.

To be written.
""".
-spec set_vertices(object(), vertices()) -> {ok, object()} | out_of_memory.
set_vertices(Mesh, Vertices) ->
    set_vertices(Mesh, Vertices, ?DEFAULT_USAGE_HINT).

-doc """
To be written.

To be written.
""".
-spec set_vertices(object(), vertices(), usage_hint()) ->
    {ok, object()} | out_of_memory
.
set_vertices(Mesh, Vertices, UsageHint) ->
    set_vertices(Mesh, Vertices, UsageHint, ?DEFAULT_KEEP_COPY).

-doc """
To be written.

To be written.
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
To be written.

To be written.
""".
-spec vertex_count(object()) -> non_neg_integer().
vertex_count({_ResourceId, VertexCount, _UsageHint, _LocalVertices}) ->
    VertexCount.

-doc """
To be written.

To be written.
""".
-spec usage_hint(object()) -> usage_hint().
usage_hint({_ResourceId, _VertexCount, UsageHint, _LocalVertices}) ->
    UsageHint.

-doc """
To be written.

To be written.
""".
-spec local_vertices(object()) -> undefined | vertices().
local_vertices({_ResourceId, _VertexCount, _UsageHint, undefined}) ->
    undefined;
local_vertices({_ResourceId, _VertexCount, _UsageHint, LocalVertices}) ->
    LocalVertices.

-doc """
To be written.

To be written.
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
To be written.

To be written.
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
        fun({X, Y, {R, G, B, A}, U, V}, Acc) ->
            <<
                Acc/binary,
                X:32/float-little,
                Y:32/float-little,
                R:8/integer-little,
                G:8/integer-little,
                B:8/integer-little,
                A:8/integer-little,
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
        R:8/integer-little,
        G:8/integer-little,
        B:8/integer-little,
        A:8/integer-little,
        U:32/float-little,
        V:32/float-little,
        DataRest/binary
    >> = Data,
    Vertex = {X, Y, {R, G, B, A}, U, V},
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
            {ok, no_error} ->
                ok = gl:bind_buffer(array_buffer, 0),
                {ok, {mesh2, Buffer}, ReleaseFun};
            {ok, out_of_memory} ->
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
            {ok, no_error} ->
                ok;
            {ok, out_of_memory} ->
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
