%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_mesh3_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(VERTEX_1, {{0.0, 0.0, 0.5}, ?COLOR_RED, 0.0, 0.0}).
-define(VERTEX_2, {{1.0, 0.0, -0.5}, ?COLOR_GREEN, 1.0, 0.0}).
-define(VERTEX_3, {{0.0, 1.0, 0.0}, ?COLOR_BLUE, 0.0, 1.0}).
-define(VERTICES, [?VERTEX_1, ?VERTEX_2, ?VERTEX_3]).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),
    ok.

mesh3_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices(?VERTICES),

    3 = graphics_mesh3:vertex_count(Mesh),
    static = graphics_mesh3:usage_hint(Mesh),
    undefined = graphics_mesh3:local_vertices(Mesh),
    false = graphics_mesh3:has_local_copy(Mesh),
    ?VERTICES = graphics_mesh3:remote_vertices(Mesh),

    ok = graphics_mesh3:destroy(Mesh),

    ok.

mesh3_with_vertices_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices([]),
    0 = graphics_mesh3:vertex_count(Mesh),
    static = graphics_mesh3:usage_hint(Mesh),
    undefined = graphics_mesh3:local_vertices(Mesh),
    false = graphics_mesh3:has_local_copy(Mesh),
    [] = graphics_mesh3:remote_vertices(Mesh),

    {ok, Mesh1} = graphics_mesh3:with_vertices(?VERTICES),
    3 = graphics_mesh3:vertex_count(Mesh1),
    static = graphics_mesh3:usage_hint(Mesh1),
    undefined = graphics_mesh3:local_vertices(Mesh1),
    ?VERTICES = graphics_mesh3:remote_vertices(Mesh1),

    {ok, Mesh2} = graphics_mesh3:with_vertices([?VERTEX_1], dynamic),
    1 = graphics_mesh3:vertex_count(Mesh2),
    dynamic = graphics_mesh3:usage_hint(Mesh2),
    undefined = graphics_mesh3:local_vertices(Mesh2),
    [?VERTEX_1] = graphics_mesh3:remote_vertices(Mesh2),

    {ok, Mesh3} = graphics_mesh3:with_vertices([?VERTEX_2, ?VERTEX_3], stream, keep_copy),
    2 = graphics_mesh3:vertex_count(Mesh3),
    stream = graphics_mesh3:usage_hint(Mesh3),
    [?VERTEX_2, ?VERTEX_3] = graphics_mesh3:local_vertices(Mesh3),
    [?VERTEX_2, ?VERTEX_3] = graphics_mesh3:remote_vertices(Mesh3),
    true = graphics_mesh3:has_local_copy(Mesh3),

    {ok, Mesh4} = graphics_mesh3:with_vertices([], static, keep_copy),
    0 = graphics_mesh3:vertex_count(Mesh4),
    [] = graphics_mesh3:local_vertices(Mesh4),
    true = graphics_mesh3:has_local_copy(Mesh4),

    ok = graphics_mesh3:destroy(Mesh),
    ok = graphics_mesh3:destroy(Mesh1),
    ok = graphics_mesh3:destroy(Mesh2),
    ok = graphics_mesh3:destroy(Mesh3),
    ok = graphics_mesh3:destroy(Mesh4),

    ok.

mesh3_new_destroy_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices(?VERTICES),

    Buffer = graphics_mesh3:gl_object(Mesh),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    ok = graphics_mesh3:destroy(Mesh),

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    ok.

mesh3_set_vertices_test() ->
    ok = run_graphics(),

    {ok, Mesh1} = graphics_mesh3:with_vertices(?VERTICES),
    Buffer = graphics_mesh3:gl_object(Mesh1),

    {ok, Mesh2} = graphics_mesh3:set_vertices(Mesh1, [?VERTEX_3]),
    1 = graphics_mesh3:vertex_count(Mesh2),
    static = graphics_mesh3:usage_hint(Mesh2),
    undefined = graphics_mesh3:local_vertices(Mesh2),
    [?VERTEX_3] = graphics_mesh3:remote_vertices(Mesh2),
    Buffer = graphics_mesh3:gl_object(Mesh2),

    {ok, Mesh3} = graphics_mesh3:set_vertices(Mesh2, [?VERTEX_1, ?VERTEX_2], dynamic),
    2 = graphics_mesh3:vertex_count(Mesh3),
    dynamic = graphics_mesh3:usage_hint(Mesh3),
    undefined = graphics_mesh3:local_vertices(Mesh3),
    [?VERTEX_1, ?VERTEX_2] = graphics_mesh3:remote_vertices(Mesh3),
    Buffer = graphics_mesh3:gl_object(Mesh3),

    {ok, MeshKeep} = graphics_mesh3:with_vertices(?VERTICES, dynamic, keep_copy),
    KeepBuffer = graphics_mesh3:gl_object(MeshKeep),
    {ok, MeshKeep2} = graphics_mesh3:set_vertices(MeshKeep, [?VERTEX_3]),
    1 = graphics_mesh3:vertex_count(MeshKeep2),
    dynamic = graphics_mesh3:usage_hint(MeshKeep2),
    [?VERTEX_3] = graphics_mesh3:local_vertices(MeshKeep2),
    [?VERTEX_3] = graphics_mesh3:remote_vertices(MeshKeep2),
    true = graphics_mesh3:has_local_copy(MeshKeep2),
    KeepBuffer = graphics_mesh3:gl_object(MeshKeep2),

    {ok, MeshKeep3} = graphics_mesh3:set_vertices(
        MeshKeep2,
        [?VERTEX_3, ?VERTEX_1, ?VERTEX_2],
        stream
    ),
    3 = graphics_mesh3:vertex_count(MeshKeep3),
    stream = graphics_mesh3:usage_hint(MeshKeep3),
    [?VERTEX_3, ?VERTEX_1, ?VERTEX_2] = graphics_mesh3:local_vertices(MeshKeep3),
    [?VERTEX_3, ?VERTEX_1, ?VERTEX_2] = graphics_mesh3:remote_vertices(MeshKeep3),
    KeepBuffer = graphics_mesh3:gl_object(MeshKeep3),

    ok = graphics_mesh3:destroy(Mesh3),
    ok = graphics_mesh3:destroy(MeshKeep3),

    ok.

mesh3_vertex_count_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices([]),
    0 = graphics_mesh3:vertex_count(Mesh),

    {ok, Mesh1} = graphics_mesh3:set_vertices(Mesh, ?VERTICES),
    3 = graphics_mesh3:vertex_count(Mesh1),

    {ok, Mesh2} = graphics_mesh3:set_vertices(Mesh1, [?VERTEX_1]),
    1 = graphics_mesh3:vertex_count(Mesh2),

    {ok, Mesh3} = graphics_mesh3:set_vertices(Mesh2, [?VERTEX_2, ?VERTEX_3]),
    2 = graphics_mesh3:vertex_count(Mesh3),

    {ok, Mesh4} = graphics_mesh3:set_vertices(Mesh3, []),
    0 = graphics_mesh3:vertex_count(Mesh4),
    [] = graphics_mesh3:remote_vertices(Mesh4),

    ok = graphics_mesh3:destroy(Mesh4),

    ok.

mesh3_usage_hint_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices([]),
    static = graphics_mesh3:usage_hint(Mesh),

    {ok, Mesh1} = graphics_mesh3:set_vertices(Mesh, ?VERTICES, dynamic),
    dynamic = graphics_mesh3:usage_hint(Mesh1),

    {ok, Mesh2} = graphics_mesh3:set_vertices(Mesh1, [?VERTEX_1], stream),
    stream = graphics_mesh3:usage_hint(Mesh2),

    {ok, Mesh3} = graphics_mesh3:set_vertices(Mesh2, [?VERTEX_2, ?VERTEX_3], static),
    static = graphics_mesh3:usage_hint(Mesh3),

    {ok, Mesh4} = graphics_mesh3:set_vertices(Mesh3, [?VERTEX_1]),
    static = graphics_mesh3:usage_hint(Mesh4),

    ok = graphics_mesh3:destroy(Mesh4),

    ok.

mesh3_local_vertices_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices([]),
    undefined = graphics_mesh3:local_vertices(Mesh),
    undefined = graphics_mesh3:local_vertex(Mesh, 1),
    undefined = graphics_mesh3:local_vertices(Mesh, {1, -1}),

    {ok, Mesh1} = graphics_mesh3:with_vertices(?VERTICES, static, no_copy),
    undefined = graphics_mesh3:local_vertices(Mesh1),
    undefined = graphics_mesh3:local_vertex(Mesh1, 1),
    undefined = graphics_mesh3:local_vertices(Mesh1, {1, -1}),

    {ok, Mesh2} = graphics_mesh3:with_vertices(?VERTICES, static, keep_copy),
    ?VERTICES = graphics_mesh3:local_vertices(Mesh2),

    {3, ?VERTEX_3} = graphics_mesh3:local_vertex(Mesh2, -1),
    {1, ?VERTEX_1} = graphics_mesh3:local_vertex(Mesh2, 0),
    {2, ?VERTEX_2} = graphics_mesh3:local_vertex(Mesh2, 1),
    {3, ?VERTEX_3} = graphics_mesh3:local_vertex(Mesh2, 2),
    out_of_range = graphics_mesh3:local_vertex(Mesh2, 3),

    {2, [?VERTEX_2]} = graphics_mesh3:local_vertices(Mesh2, {1, -1}),
    {2, [?VERTEX_2, ?VERTEX_3]} = graphics_mesh3:local_vertices(Mesh2, {1, undefined}),
    {1, [?VERTEX_1, ?VERTEX_2]} = graphics_mesh3:local_vertices(Mesh2, {undefined, -1}),

    ok = graphics_mesh3:destroy(Mesh),
    ok = graphics_mesh3:destroy(Mesh1),
    ok = graphics_mesh3:destroy(Mesh2),

    ok.

mesh3_remote_vertices_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices([]),
    [] = graphics_mesh3:remote_vertices(Mesh),
    out_of_range = graphics_mesh3:remote_vertex(Mesh, 1),
    no_range = graphics_mesh3:remote_vertices(Mesh, {1, -1}),

    {ok, Mesh1} = graphics_mesh3:set_vertices(Mesh, ?VERTICES),
    ?VERTICES = graphics_mesh3:remote_vertices(Mesh1),

    {3, ?VERTEX_3} = graphics_mesh3:remote_vertex(Mesh1, -1),
    {1, ?VERTEX_1} = graphics_mesh3:remote_vertex(Mesh1, 0),
    {2, ?VERTEX_2} = graphics_mesh3:remote_vertex(Mesh1, 1),
    {3, ?VERTEX_3} = graphics_mesh3:remote_vertex(Mesh1, 2),
    out_of_range = graphics_mesh3:remote_vertex(Mesh1, 3),

    {2, [?VERTEX_2]} = graphics_mesh3:remote_vertices(Mesh1, {1, -1}),
    {2, [?VERTEX_2, ?VERTEX_3]} = graphics_mesh3:remote_vertices(Mesh1, {1, undefined}),
    {1, [?VERTEX_1, ?VERTEX_2]} = graphics_mesh3:remote_vertices(Mesh1, {undefined, -1}),

    ok = graphics_mesh3:destroy(Mesh1),

    ok.

mesh3_update_vertices_test() ->
    ok = run_graphics(),

    {ok, MeshNoCopy} = graphics_mesh3:with_vertices(?VERTICES),

    NewVertices = [?VERTEX_3, ?VERTEX_1, ?VERTEX_2],
    {ok, MeshNoCopy1} = graphics_mesh3:update_vertices(MeshNoCopy, NewVertices),
    3 = graphics_mesh3:vertex_count(MeshNoCopy1),
    static = graphics_mesh3:usage_hint(MeshNoCopy1),
    undefined = graphics_mesh3:local_vertices(MeshNoCopy1),
    NewVertices = graphics_mesh3:remote_vertices(MeshNoCopy1),

    out_of_range = graphics_mesh3:update_vertices(MeshNoCopy1, [
        ?VERTEX_3, ?VERTEX_1, ?VERTEX_2, ?VERTEX_1
    ]),

    {ok, MeshNoCopy2} =
        graphics_mesh3:update_vertices(MeshNoCopy1, [?VERTEX_1, ?VERTEX_3], 0),
    3 = graphics_mesh3:vertex_count(MeshNoCopy2),
    static = graphics_mesh3:usage_hint(MeshNoCopy2),
    undefined = graphics_mesh3:local_vertices(MeshNoCopy2),
    [?VERTEX_1, ?VERTEX_3, ?VERTEX_2] = graphics_mesh3:remote_vertices(MeshNoCopy2),

    {ok, MeshNoCopy3} =
        graphics_mesh3:update_vertices(MeshNoCopy2, [?VERTEX_2, ?VERTEX_1], 1),
    3 = graphics_mesh3:vertex_count(MeshNoCopy3),
    static = graphics_mesh3:usage_hint(MeshNoCopy3),
    undefined = graphics_mesh3:local_vertices(MeshNoCopy3),
    [?VERTEX_1, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:remote_vertices(MeshNoCopy3),

    {ok, MeshNoCopy4} = graphics_mesh3:update_vertices(MeshNoCopy3, [?VERTEX_3], 2),
    3 = graphics_mesh3:vertex_count(MeshNoCopy4),
    static = graphics_mesh3:usage_hint(MeshNoCopy4),
    undefined = graphics_mesh3:local_vertices(MeshNoCopy4),
    [?VERTEX_1, ?VERTEX_2, ?VERTEX_3] = graphics_mesh3:remote_vertices(MeshNoCopy4),

    out_of_range =
        graphics_mesh3:update_vertices(MeshNoCopy4, [?VERTEX_3, ?VERTEX_1], 2),

    {ok, MeshNoCopy5} = graphics_mesh3:update_vertex(MeshNoCopy4, ?VERTEX_3, 0),
    undefined = graphics_mesh3:local_vertices(MeshNoCopy5),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_3] = graphics_mesh3:remote_vertices(MeshNoCopy5),
    {ok, MeshNoCopy6} = graphics_mesh3:update_vertex(MeshNoCopy5, ?VERTEX_1, -1),
    undefined = graphics_mesh3:local_vertices(MeshNoCopy6),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:remote_vertices(MeshNoCopy6),

    out_of_range = graphics_mesh3:update_vertex(MeshNoCopy6, ?VERTEX_3, 3),

    {ok, MeshNoCopy7} = graphics_mesh3:update_vertices(MeshNoCopy6, []),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:remote_vertices(MeshNoCopy7),

    ok = graphics_mesh3:destroy(MeshNoCopy7),

    {ok, MeshKeepCopy} = graphics_mesh3:with_vertices(?VERTICES, dynamic, keep_copy),

    {ok, MeshKeepCopy1} = graphics_mesh3:update_vertices(MeshKeepCopy, NewVertices),
    3 = graphics_mesh3:vertex_count(MeshKeepCopy1),
    dynamic = graphics_mesh3:usage_hint(MeshKeepCopy1),
    NewVertices = graphics_mesh3:local_vertices(MeshKeepCopy1),
    NewVertices = graphics_mesh3:remote_vertices(MeshKeepCopy1),

    out_of_range = graphics_mesh3:update_vertices(MeshKeepCopy1, [
        ?VERTEX_3, ?VERTEX_1, ?VERTEX_2, ?VERTEX_1
    ]),

    {ok, MeshKeepCopy2} =
        graphics_mesh3:update_vertices(MeshKeepCopy1, [?VERTEX_1, ?VERTEX_3], 0),
    3 = graphics_mesh3:vertex_count(MeshKeepCopy2),
    dynamic = graphics_mesh3:usage_hint(MeshKeepCopy2),
    [?VERTEX_1, ?VERTEX_3, ?VERTEX_2] = graphics_mesh3:local_vertices(MeshKeepCopy2),
    [?VERTEX_1, ?VERTEX_3, ?VERTEX_2] = graphics_mesh3:remote_vertices(MeshKeepCopy2),

    {ok, MeshKeepCopy3} =
        graphics_mesh3:update_vertices(MeshKeepCopy2, [?VERTEX_2, ?VERTEX_1], 1),
    3 = graphics_mesh3:vertex_count(MeshKeepCopy3),
    dynamic = graphics_mesh3:usage_hint(MeshKeepCopy3),
    [?VERTEX_1, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:local_vertices(MeshKeepCopy3),
    [?VERTEX_1, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:remote_vertices(MeshKeepCopy3),

    {ok, MeshKeepCopy4} = graphics_mesh3:update_vertices(MeshKeepCopy3, [?VERTEX_3], 2),
    3 = graphics_mesh3:vertex_count(MeshKeepCopy4),
    dynamic = graphics_mesh3:usage_hint(MeshKeepCopy4),
    [?VERTEX_1, ?VERTEX_2, ?VERTEX_3] = graphics_mesh3:local_vertices(MeshKeepCopy4),
    [?VERTEX_1, ?VERTEX_2, ?VERTEX_3] = graphics_mesh3:remote_vertices(MeshKeepCopy4),

    out_of_range =
        graphics_mesh3:update_vertices(MeshKeepCopy4, [?VERTEX_3, ?VERTEX_1], 2),

    {ok, MeshKeepCopy5} = graphics_mesh3:update_vertex(MeshKeepCopy4, ?VERTEX_3, 0),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_3] = graphics_mesh3:local_vertices(MeshKeepCopy5),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_3] = graphics_mesh3:remote_vertices(MeshKeepCopy5),
    {ok, MeshKeepCopy6} = graphics_mesh3:update_vertex(MeshKeepCopy5, ?VERTEX_1, -1),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:local_vertices(MeshKeepCopy6),
    [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = graphics_mesh3:remote_vertices(MeshKeepCopy6),

    out_of_range = graphics_mesh3:update_vertex(MeshKeepCopy6, ?VERTEX_3, 3),

    ok = graphics_mesh3:destroy(MeshKeepCopy6),

    ok.

mesh3_local_copy_test() ->
    ok = run_graphics(),

    {ok, Mesh0} = graphics_mesh3:with_vertices(?VERTICES),

    false = graphics_mesh3:has_local_copy(Mesh0),
    undefined = graphics_mesh3:local_vertices(Mesh0),

    {ok, Mesh1} = graphics_mesh3:keep_local_copy(Mesh0),
    true = graphics_mesh3:has_local_copy(Mesh1),
    ?VERTICES = graphics_mesh3:local_vertices(Mesh1),
    ?VERTICES = graphics_mesh3:remote_vertices(Mesh1),

    already_local_copy = graphics_mesh3:keep_local_copy(Mesh1),

    {ok, Mesh2} = graphics_mesh3:release_local_copy(Mesh1),
    false = graphics_mesh3:has_local_copy(Mesh2),
    undefined = graphics_mesh3:local_vertices(Mesh2),
    ?VERTICES = graphics_mesh3:remote_vertices(Mesh2),

    no_local_copy = graphics_mesh3:release_local_copy(Mesh2),

    ok = graphics_mesh3:destroy(Mesh2),

    ok.

mesh3_gl_object_test() ->
    ok = run_graphics(),

    {ok, Mesh} = graphics_mesh3:with_vertices(?VERTICES),
    Buffer = graphics_mesh3:gl_object(Mesh),

    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    ok = graphics_mesh3:destroy(Mesh),

    ok.
