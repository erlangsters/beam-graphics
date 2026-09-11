%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_context_test).
-include_lib("eunit/include/eunit.hrl").

-define(INVALID_RESOURCE_ID, {abc, 9999}).

graphics_context_test() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),

    {ok, GraphicsContext} = graphics_context:start(Display),
    already_spawned = graphics_context:start(Display),
    % XXX: Remove this after bug is fixed in spawn mode library.
    ok = receive
        {'DOWN', _, process, _, normal} -> ok
    end,

    Context = graphics_context:inner_context(),
    {ok, opengl_api} = egl:query_context(Display, Context, context_client_type),
    {ok, 4} = egl:query_context(Display, Context, context_client_version),

    {ok, GlVersion} = graphics_context:execute_commands(fun() ->
        gl:get_string(version)
    end),
    % XXX: match string (look for substring instead)
    io:format(user, "OpenGL version: ~p~n", [GlVersion]),

    Resources1 = graphics_context:inner_resources(),
    0 = maps:size(Resources1),

    Self = self(),
    ReleaseFun = fun({buffer, Buffer} = ResourceId) ->
        ok = gl:delete_buffers([Buffer]),
        Self ! {released_resource, ResourceId},
        ok
    end,
    AcquireFun = fun() ->
        {ok, [Buffer]} = gl:gen_buffers(1),
        Self ! {acquired_resource, {buffer, Buffer}},
        {ok, {buffer, Buffer}, ReleaseFun}
    end,

    Pid = spawn_link(fun() ->
        {ok, _ResourceId} = graphics_context:acquire_resource(AcquireFun),
        link(GraphicsContext),
        timer:sleep(5000)
    end),
    {ok, ResourceId} = receive
        {acquired_resource, ResourceId1_} ->
            {ok, ResourceId1_}
    end,

    Resources2 = graphics_context:inner_resources(),
    1 = maps:size(Resources2),
    [ResourceId] = maps:keys(Resources2),
    [Pid] = maps:values(Resources2),

    process_flag(trap_exit, true),
    ok = graphics_context:stop(),

    {ok, ResourceId} = receive
        {released_resource, ResourceId2_} ->
            {ok, ResourceId2_}
    end,
    ok = receive
        {'EXIT', GraphicsContext, normal} ->
            ok
    end,

    ok.

graphics_context_resource_test() ->
    % Display = egl:get_display(default_display),
    % {ok, {_, _}} = egl:initialize(Display),

    % {ok, _GraphicsContext} = graphics_context:start(Display),

    % Self = self(),

    % Resources1 = graphics_context:inner_resources(),
    % 0 = maps:size(Resources1),

    % ReleaseFun = fun({buffer, Buffer}) ->
    %     ok = gl:delete_buffers([Buffer]),
    %     ok
    % end,
    % AcquireFun = fun() ->
    %     {ok, [Buffer]} = gl:create_buffers(1),
    %     {ok, {buffer, Buffer}, ReleaseFun}
    % end,
    % {ok, Resource} = graphics_context:acquire_resource(AcquireFun),
    % {buffer, Buffer} = Resource,

    % {ok, true} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    % Resources2 = graphics_context:inner_resources(),
    % 1 = maps:size(Resources2),
    % [{buffer, Buffer}] = maps:keys(Resources2),
    % [Self] = maps:values(Resources2),

    % graphics_context:release_resource(Resource),

    % {ok, false} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    % Resources3 = graphics_context:inner_resources(),
    % 0 = maps:size(Resources3),

    % ok = graphics_context:stop(),

    ok.

graphics_context_monitor_test() ->
    % % Test if resources are monitored and released properly.
    % Display = egl:get_display(default_display),
    % {ok, {_, _}} = egl:initialize(Display),

    % {ok, _GraphicsContext} = graphics_context:start(Display),

    % process_flag(trap_exit, true),

    % ReleaseFun = fun({buffer, Buffer}) ->
    %     ok = gl:delete_buffers([Buffer]),
    %     ok
    % end,
    % AcquireFun = fun() ->
    %     {ok, [Buffer]} = gl:create_buffers(1),
    %     {ok, {buffer, Buffer}, ReleaseFun}
    % end,
    % Pid = spawn_link(fun() ->
    %     {ok, Resource} = graphics_context:acquire_resource(AcquireFun),
    %     timer:sleep(100),
    %     exit({normal, Resource})
    % end),
    % timer:sleep(50),
    % Resources1 = graphics_context:inner_resources(),
    % 1 = maps:size(Resources1),
    % [Resource] = maps:keys(Resources1),
    % [Pid] = maps:values(Resources1),

    % ok = receive
    %     {'EXIT', Pid, {normal, Resource}} ->
    %         ok
    % end,

    % Resources2 = graphics_context:inner_resources(),
    % 0 = maps:size(Resources2),

    % {buffer, Buffer} = Resource,
    % {ok, false} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    % ok = graphics_context:stop(),

    ok.

graphics_context_ownership_test() ->
    % % Test if ownership transfer works correctly.
    % Display = egl:get_display(default_display),
    % {ok, {_, _}} = egl:initialize(Display),

    % {ok, _GraphicsContext} = graphics_context:start(Display),

    % process_flag(trap_exit, true),

    % ReleaseFun = fun({buffer, Buffer}) ->
    %     ok = gl:delete_buffers([Buffer]),
    %     ok
    % end,
    % AcquireFun = fun() ->
    %     {ok, [Buffer]} = gl:create_buffers(1),
    %     {ok, {buffer, Buffer}, ReleaseFun}
    % end,
    % {ok, Resource} = graphics_context:acquire_resource(AcquireFun),
    % {buffer, Buffer} = Resource,

    % Pid = spawn_link(fun() ->
    %     invalid_resource_id = graphics_context:transfer_ownership(?INVALID_RESOURCE_ID, self()),
    %     ok = graphics_context:transfer_ownership(Resource, self()),
    %     timer:sleep(100)
    % end),
    % timer:sleep(50),
    % Resources1 = graphics_context:inner_resources(),
    % 1 = maps:size(Resources1),
    % #{Resource := Pid} = Resources1,

    % ok = receive
    %     {'EXIT', Pid, normal} ->
    %         ok
    % end,

    % Resources2 = graphics_context:inner_resources(),
    % 0 = maps:size(Resources2),

    % {ok, false} = graphics_context:execute_commands(fun() ->
    %     gl:is_buffer(Buffer)
    % end),

    % ok = graphics_context:stop(),

    ok.
