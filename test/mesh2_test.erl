%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(mesh2_test).
-include_lib("eunit/include/eunit.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-define(VERTEX_1, {0.0, 0.0, ?COLOR_RED, 0.0, 0.0}).
-define(VERTEX_2, {1.0, 0.0, ?COLOR_GREEN, 1.0, 0.0}).
-define(VERTEX_3, {0.0, 1.0, ?COLOR_BLUE, 0.0, 1.0}).
-define(VERTICES, [?VERTEX_1, ?VERTEX_2, ?VERTEX_3]).

run_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    graphics_context:start(Display),

    ok.

mesh2_test() ->
    % Just a canonical test.
    ok = run_graphics(),

    {ok, Mesh} = mesh2:with_vertices(?VERTICES),

    3 = mesh2:vertex_count(Mesh),
    static = mesh2:usage_hint(Mesh),
    undefined = mesh2:local_vertices(Mesh),
    ?VERTICES = mesh2:remote_vertices(Mesh),

    ok = mesh2:destroy(Mesh),

    ok.

mesh2_with_vertices_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices([]),
    % 0 = mesh2:vertex_count(Mesh),
    % static = mesh2:usage_hint(Mesh),
    % undefined = mesh2:local_vertices(Mesh),
    % [] = mesh2:remote_vertices(Mesh),

    % {ok, Mesh1} = mesh2:with_vertices(?VERTICES),
    % 3 = mesh2:vertex_count(Mesh1),
    % static = mesh2:usage_hint(Mesh1),
    % undefined = mesh2:local_vertices(Mesh1),
    % ?VERTICES = mesh2:remote_vertices(Mesh1),

    % {ok, Mesh2} = mesh2:with_vertices([?VERTEX_1], dynamic),
    % 1 = mesh2:vertex_count(Mesh2),
    % dynamic = mesh2:usage_hint(Mesh2),
    % undefined = mesh2:local_vertices(Mesh2),
    % [?VERTEX_1] = mesh2:remote_vertices(Mesh2),

    % {ok, Mesh3} = mesh2:with_vertices([?VERTEX_2, ?VERTEX_3], stream, keep_copy),
    % 2 = mesh2:vertex_count(Mesh3),
    % stream = mesh2:usage_hint(Mesh3),
    % [?VERTEX_2, ?VERTEX_3] = mesh2:local_vertices(Mesh3),
    % [?VERTEX_2, ?VERTEX_3] = mesh2:remote_vertices(Mesh3),

    % ok = mesh2:destroy(Mesh1),
    % ok = mesh2:destroy(Mesh2),
    % ok = mesh2:destroy(Mesh3),

    ok.

mesh2_new_destroy_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices(?VERTICES),

    % Buffer = mesh2:gl_object(Mesh),
    % {ok, true} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    % ok = mesh2:destroy(Mesh),

    % {ok, false} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    ok.

mesh2_set_vertices_test() ->
    % ok = run_graphics(),

    % {ok, Mesh1} = mesh2:with_vertices(?VERTICES),

    % {ok, Mesh2} = mesh2:set_vertices(Mesh1, [?VERTEX_3]),
    % 1 = mesh2:vertex_count(Mesh2),
    % static = mesh2:usage_hint(Mesh2),
    % undefined = mesh2:local_vertices(Mesh2),
    % [?VERTEX_3] = mesh2:remote_vertices(Mesh2),

    % {ok, Mesh3} = mesh2:set_vertices(Mesh2, [?VERTEX_1, ?VERTEX_2], dynamic),
    % 2 = mesh2:vertex_count(Mesh3),
    % dynamic = mesh2:usage_hint(Mesh3),
    % undefined = mesh2:local_vertices(Mesh3),
    % [?VERTEX_1, ?VERTEX_2] = mesh2:remote_vertices(Mesh3),

    % {ok, Mesh4} = mesh2:set_vertices(
    %     Mesh3,
    %     [?VERTEX_3, ?VERTEX_1, ?VERTEX_2],
    %     stream,
    %     keep_copy
    % ),
    % 3 = mesh2:vertex_count(Mesh4),
    % stream = mesh2:usage_hint(Mesh4),
    % [?VERTEX_3, ?VERTEX_1, ?VERTEX_2] = mesh2:local_vertices(Mesh4),
    % [?VERTEX_3, ?VERTEX_1, ?VERTEX_2] = mesh2:remote_vertices(Mesh4),

    % ok = mesh2:destroy(Mesh4),

    ok.

mesh2_vertex_count_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices([]),
    % 0 = mesh2:vertex_count(Mesh),

    % {ok, Mesh1} = mesh2:set_vertices(Mesh, ?VERTICES),
    % 3 = mesh2:vertex_count(Mesh1),

    % {ok, Mesh2} = mesh2:set_vertices(Mesh1, [?VERTEX_1]),
    % 1 = mesh2:vertex_count(Mesh2),

    % {ok, Mesh3} = mesh2:set_vertices(Mesh2, [?VERTEX_2, ?VERTEX_3]),
    % 2 = mesh2:vertex_count(Mesh3),

    % {ok, Mesh4} = mesh2:set_vertices(Mesh3, []),
    % 0 = mesh2:vertex_count(Mesh4),

    % mesh2:destroy(Mesh4),

    ok.

mesh2_usage_hint_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices([]),
    % static = mesh2:usage_hint(Mesh),

    % {ok, Mesh1} = mesh2:set_vertices(Mesh, ?VERTICES, dynamic),
    % dynamic = mesh2:usage_hint(Mesh1),

    % {ok, Mesh2} = mesh2:set_vertices(Mesh1, [?VERTEX_1], stream),
    % stream = mesh2:usage_hint(Mesh2),

    % {ok, Mesh3} = mesh2:set_vertices(Mesh2, [?VERTEX_2, ?VERTEX_3], static),
    % static = mesh2:usage_hint(Mesh3),

    % mesh2:destroy(Mesh3),

    ok.

mesh2_local_vertices_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices([]),
    % undefined = mesh2:local_vertices(Mesh),
    % undefined = mesh2:local_vertex(Mesh, 1),
    % undefined = mesh2:local_vertices(Mesh, {1, -1}),

    % {ok, Mesh1} = mesh2:set_vertices(Mesh, ?VERTICES, static, no_copy),
    % undefined = mesh2:local_vertices(Mesh1),
    % undefined = mesh2:local_vertex(Mesh1, 1),
    % undefined = mesh2:local_vertices(Mesh1, {1, -1}),

    % {ok, Mesh2} = mesh2:set_vertices(Mesh1, ?VERTICES, static, keep_copy),
    % ?VERTICES = mesh2:local_vertices(Mesh2),

    % {3, ?VERTEX_3} = mesh2:local_vertex(Mesh2, -1),
    % {1, ?VERTEX_1} = mesh2:local_vertex(Mesh2, 0),
    % {2, ?VERTEX_2} = mesh2:local_vertex(Mesh2, 1),
    % {3, ?VERTEX_3} = mesh2:local_vertex(Mesh2, 2),
    % out_of_range = mesh2:local_vertex(Mesh2, 3),

    % {2, [?VERTEX_2]} = mesh2:local_vertices(Mesh2, {1, -1}),
    % {2, [?VERTEX_2, ?VERTEX_3]} = mesh2:local_vertices(Mesh2, {1, undefined}),
    % {1, [?VERTEX_1, ?VERTEX_2]} = mesh2:local_vertices(Mesh2, {undefined, -1}),

    % mesh2:destroy(Mesh2),

    ok.

mesh2_remote_vertices_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices([]),
    % [] = mesh2:remote_vertices(Mesh),
    % out_of_range = mesh2:remote_vertex(Mesh, 1),
    % no_range = mesh2:remote_vertices(Mesh, {1, -1}),

    % {ok, Mesh1} = mesh2:set_vertices(Mesh, ?VERTICES),
    % ?VERTICES = mesh2:remote_vertices(Mesh1),

    % {3, ?VERTEX_3} = mesh2:remote_vertex(Mesh1, -1),
    % {1, ?VERTEX_1} = mesh2:remote_vertex(Mesh1, 0),
    % {2, ?VERTEX_2} = mesh2:remote_vertex(Mesh1, 1),
    % {3, ?VERTEX_3} = mesh2:remote_vertex(Mesh1, 2),
    % out_of_range = mesh2:remote_vertex(Mesh1, 3),

    % {2, [?VERTEX_2]} = mesh2:remote_vertices(Mesh1, {1, -1}),
    % {2, [?VERTEX_2, ?VERTEX_3]} = mesh2:remote_vertices(Mesh1, {1, undefined}),
    % {1, [?VERTEX_1, ?VERTEX_2]} = mesh2:remote_vertices(Mesh1, {undefined, -1}),

    % mesh2:destroy(Mesh1),

    ok.

mesh2_update_vertices_test() ->
    % ok = run_graphics(),

    % {ok, MeshNoCopy} = mesh2:with_vertices(?VERTICES),

    % NewVertices = [?VERTEX_3, ?VERTEX_1, ?VERTEX_2],
    % {ok, MeshNoCopy1} = mesh2:update_vertices(MeshNoCopy, NewVertices),
    % 3 = mesh2:vertex_count(MeshNoCopy1),
    % static = mesh2:usage_hint(MeshNoCopy1),
    % undefined = mesh2:local_vertices(MeshNoCopy1),
    % NewVertices = mesh2:remote_vertices(MeshNoCopy1),

    % out_of_range = mesh2:update_vertices(MeshNoCopy1,
    %     [?VERTEX_3, ?VERTEX_1, ?VERTEX_2, ?VERTEX_1]
    % ),

    % {ok, MeshNoCopy2} =
    %     mesh2:update_vertices(MeshNoCopy1, [?VERTEX_1, ?VERTEX_3], 1),
    % 3 = mesh2:vertex_count(MeshNoCopy2),
    % static = mesh2:usage_hint(MeshNoCopy2),
    % undefined = mesh2:local_vertices(MeshNoCopy2),
    % [?VERTEX_1, ?VERTEX_3, ?VERTEX_2] = mesh2:remote_vertices(MeshNoCopy2),

    % {ok, MeshNoCopy3} =
    %     mesh2:update_vertices(MeshNoCopy2, [?VERTEX_2, ?VERTEX_1], 2),
    % 3 = mesh2:vertex_count(MeshNoCopy3),
    % static = mesh2:usage_hint(MeshNoCopy3),
    % undefined = mesh2:local_vertices(MeshNoCopy3),
    % [?VERTEX_1, ?VERTEX_2, ?VERTEX_1] = mesh2:remote_vertices(MeshNoCopy3),

    % {ok, MeshNoCopy4} = mesh2:update_vertices(MeshNoCopy3, [?VERTEX_3], 3),
    % 3 = mesh2:vertex_count(MeshNoCopy4),
    % static = mesh2:usage_hint(MeshNoCopy4),
    % undefined = mesh2:local_vertices(MeshNoCopy4),
    % [?VERTEX_1, ?VERTEX_2, ?VERTEX_3] = mesh2:remote_vertices(MeshNoCopy4),

    % out_of_range =
    %     mesh2:update_vertices(MeshNoCopy4, [?VERTEX_3, ?VERTEX_1], 3),

    % {ok, MeshNoCopy5} = mesh2:update_vertex(MeshNoCopy4, ?VERTEX_3, 1),
    % undefined = mesh2:local_vertices(MeshNoCopy5),
    % [?VERTEX_3, ?VERTEX_2, ?VERTEX_3] = mesh2:remote_vertices(MeshNoCopy5),
    % {ok, MeshNoCopy6} = mesh2:update_vertex(MeshNoCopy5, ?VERTEX_1, 3),
    % undefined = mesh2:local_vertices(MeshNoCopy6),
    % [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = mesh2:remote_vertices(MeshNoCopy6),

    % out_of_range = mesh2:update_vertex(MeshNoCopy6, ?VERTEX_3, 4),

    % mesh2:destroy(MeshNoCopy6),

    % % When a copy is kept, the local vertices are updated.
    % {ok, MeshKeepCopy} = mesh2:with_vertices(?VERTICES, dynamic, keep_copy),

    % NewVertices = [?VERTEX_3, ?VERTEX_1, ?VERTEX_2],
    % {ok, MeshKeepCopy1} = mesh2:update_vertices(MeshKeepCopy, NewVertices),
    % 3 = mesh2:vertex_count(MeshKeepCopy1),
    % dynamic = mesh2:usage_hint(MeshKeepCopy1),
    % NewVertices = mesh2:local_vertices(MeshKeepCopy1),
    % NewVertices = mesh2:remote_vertices(MeshKeepCopy1),

    % out_of_range = mesh2:update_vertices(MeshKeepCopy1,
    %     [?VERTEX_3, ?VERTEX_1, ?VERTEX_2, ?VERTEX_1]
    % ),

    % {ok, MeshKeepCopy2} =
    %     mesh2:update_vertices(MeshKeepCopy1, [?VERTEX_1, ?VERTEX_3], 1),
    % 3 = mesh2:vertex_count(MeshKeepCopy2),
    % dynamic = mesh2:usage_hint(MeshKeepCopy2),
    % [?VERTEX_1, ?VERTEX_3, ?VERTEX_2] = mesh2:local_vertices(MeshKeepCopy2),
    % [?VERTEX_1, ?VERTEX_3, ?VERTEX_2] = mesh2:remote_vertices(MeshKeepCopy2),

    % {ok, MeshKeepCopy3} =
    %     mesh2:update_vertices(MeshKeepCopy2, [?VERTEX_2, ?VERTEX_1], 2),
    % 3 = mesh2:vertex_count(MeshKeepCopy3),
    % dynamic = mesh2:usage_hint(MeshKeepCopy3),
    % [?VERTEX_1, ?VERTEX_2, ?VERTEX_1] = mesh2:local_vertices(MeshKeepCopy3),
    % [?VERTEX_1, ?VERTEX_2, ?VERTEX_1] = mesh2:remote_vertices(MeshKeepCopy3),

    % {ok, MeshKeepCopy4} = mesh2:update_vertices(MeshKeepCopy3, [?VERTEX_3], 3),
    % 3 = mesh2:vertex_count(MeshKeepCopy4),
    % dynamic = mesh2:usage_hint(MeshKeepCopy4),
    % [?VERTEX_1, ?VERTEX_2, ?VERTEX_3] = mesh2:local_vertices(MeshKeepCopy4),
    % [?VERTEX_1, ?VERTEX_2, ?VERTEX_3] = mesh2:remote_vertices(MeshKeepCopy4),

    % out_of_range =
    %     mesh2:update_vertices(MeshKeepCopy4, [?VERTEX_3, ?VERTEX_1], 3),

    % {ok, MeshKeepCopy5} = mesh2:update_vertex(MeshKeepCopy4, ?VERTEX_3, 1),
    % [?VERTEX_3, ?VERTEX_2, ?VERTEX_3] = mesh2:local_vertices(MeshKeepCopy5),
    % [?VERTEX_3, ?VERTEX_2, ?VERTEX_3] = mesh2:remote_vertices(MeshKeepCopy5),
    % {ok, MeshKeepCopy6} = mesh2:update_vertex(MeshKeepCopy5, ?VERTEX_1, 3),
    % [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = mesh2:local_vertices(MeshKeepCopy6),
    % [?VERTEX_3, ?VERTEX_2, ?VERTEX_1] = mesh2:remote_vertices(MeshKeepCopy6),

    % out_of_range = mesh2:update_vertex(MeshKeepCopy6, ?VERTEX_3, 4),

    % mesh2:destroy(MeshKeepCopy6),

    ok.

mesh2_gl_object_test() ->
    % ok = run_graphics(),

    % {ok, Mesh} = mesh2:with_vertices(?VERTICES),
    % Buffer = mesh2:gl_object(Mesh),

    % {ok, true} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    % ok = mesh2:destroy(Mesh),

    ok.
