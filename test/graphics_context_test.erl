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

start_graphics() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),
    Pid = case graphics_context:start(Display) of
        {ok, Started} ->
            Started;
        already_spawned ->
            ok = graphics_context:stop(),
            {ok, Restarted} = graphics_context:start(Display),
            Restarted
    end,
    {Display, Pid}.

buffer_acquire_fun(NotifyPid) ->
    fun() ->
        {ok, [Buffer]} = gl:gen_buffers(1),
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:bind_buffer(array_buffer, none),
        ResourceId = {buffer, Buffer},
        ReleaseFun = fun({buffer, ReleasedBuffer} = ReleasedId) ->
            ok = gl:delete_buffers([ReleasedBuffer]),
            NotifyPid ! {released, ReleasedId},
            ok
        end,
        NotifyPid ! {acquired, ResourceId},
        {ok, ResourceId, ReleaseFun}
    end.

graphics_context_start_test() ->
    Display = egl:get_display(default_display),
    {ok, {_, _}} = egl:initialize(Display),

    {ok, _Pid} = graphics_context:start(Display),
    already_spawned = graphics_context:start(Display),
    % XXX: Remove this after bug is fixed in spawn mode library.
    ok = receive
        {'DOWN', _, process, _, normal} -> ok
    end,

    ok = graphics_context:stop(),
    ok.

graphics_context_inner_context_test() ->
    {Display, _Pid} = start_graphics(),

    Context = graphics_context:inner_context(),
    {ok, opengl_api} = egl:query_context(Display, Context, context_client_type),
    {ok, 4} = egl:query_context(Display, Context, context_client_version),

    {ok, _Version} = graphics_context:execute_commands(fun() ->
        gl:get_string(version)
    end),

    ok = graphics_context:stop(),
    ok.

graphics_context_resource_test() ->
    {_Display, _Pid} = start_graphics(),
    Self = self(),

    Resources1 = graphics_context:inner_resources(),
    0 = maps:size(Resources1),

    {ok, ResourceId} = graphics_context:acquire_resource(
        buffer_acquire_fun(Self)
    ),
    {acquired, ResourceId} = receive
        {acquired, AcquiredId} ->
            {acquired, AcquiredId}
    end,
    {buffer, Buffer} = ResourceId,

    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    Resources2 = graphics_context:inner_resources(),
    1 = maps:size(Resources2),
    #{ResourceId := Self} = Resources2,

    ok = graphics_context:release_resource(ResourceId),
    {released, ResourceId} = receive
        {released, ReleasedId} ->
            {released, ReleasedId}
    end,

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    Resources3 = graphics_context:inner_resources(),
    0 = maps:size(Resources3),

    ok = graphics_context:stop(),
    ok.

graphics_context_invalid_resource_test() ->
    {_Display, _Pid} = start_graphics(),

    invalid_resource_id =
        graphics_context:release_resource(?INVALID_RESOURCE_ID),
    invalid_resource_id =
        graphics_context:transfer_ownership(?INVALID_RESOURCE_ID, self()),

    ok = graphics_context:stop(),
    ok.

graphics_context_duplicate_resource_test() ->
    {_Display, _Pid} = start_graphics(),
    Self = self(),

    AcquireFun = fun() ->
        {ok, [Buffer]} = gl:gen_buffers(1),
        ok = gl:bind_buffer(array_buffer, Buffer),
        ok = gl:bind_buffer(array_buffer, none),
        ReleaseFun = fun(_) ->
            ok = gl:delete_buffers([Buffer]),
            Self ! {deleted, Buffer},
            ok
        end,
        Self ! {created, Buffer},
        {ok, {fixed, 1}, ReleaseFun}
    end,

    {ok, {fixed, 1}} = graphics_context:acquire_resource(AcquireFun),
    Buffer1 = receive
        {created, Created1} ->
            Created1
    end,

    {error, already_acquired} = graphics_context:acquire_resource(AcquireFun),
    Buffer2 = receive
        {created, Created2} ->
            Created2
    end,
    Buffer2 = receive
        {deleted, Deleted2} ->
            Deleted2
    end,

    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer1)
    end),
    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer2)
    end),

    Resources = graphics_context:inner_resources(),
    1 = maps:size(Resources),
    #{{fixed, 1} := Self} = Resources,

    ok = graphics_context:release_resource({fixed, 1}),
    Buffer1 = receive
        {deleted, Deleted1} ->
            Deleted1
    end,

    ok = graphics_context:stop(),
    ok.

graphics_context_owner_down_test() ->
    {_Display, _Pid} = start_graphics(),
    Self = self(),

    Owner = spawn(fun() ->
        {ok, _ResourceId} = graphics_context:acquire_resource(
            buffer_acquire_fun(Self)
        ),
        receive
            stop -> ok
        end
    end),
    ResourceId = receive
        {acquired, AcquiredId} ->
            AcquiredId
    end,
    {buffer, Buffer} = ResourceId,

    Resources1 = graphics_context:inner_resources(),
    #{ResourceId := Owner} = Resources1,

    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    OwnerMonitor = monitor(process, Owner),
    exit(Owner, kill),
    ok = receive
        {'DOWN', OwnerMonitor, process, Owner, _} ->
            ok
    end,
    {released, ResourceId} = receive
        {released, ReleasedId} ->
            {released, ReleasedId}
    end,

    Resources2 = graphics_context:inner_resources(),
    0 = maps:size(Resources2),

    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    ok = graphics_context:stop(),
    ok.

graphics_context_transfer_test() ->
    {_Display, _Pid} = start_graphics(),
    Self = self(),

    Orig = spawn(fun() ->
        {ok, _ResourceId} = graphics_context:acquire_resource(
            buffer_acquire_fun(Self)
        ),
        receive
            stop -> ok
        end
    end),
    ResourceId = receive
        {acquired, AcquiredId} ->
            AcquiredId
    end,
    {buffer, Buffer} = ResourceId,

    NewOwner = spawn(fun() ->
        receive
            stop -> ok
        end
    end),
    ok = graphics_context:transfer_ownership(ResourceId, NewOwner),
    #{ResourceId := NewOwner} = graphics_context:inner_resources(),

    OrigMonitor = monitor(process, Orig),
    exit(Orig, kill),
    ok = receive
        {'DOWN', OrigMonitor, process, Orig, _} ->
            ok
    end,
    #{ResourceId := NewOwner} = graphics_context:inner_resources(),
    {ok, true} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    NewOwnerMonitor = monitor(process, NewOwner),
    exit(NewOwner, kill),
    ok = receive
        {'DOWN', NewOwnerMonitor, process, NewOwner, _} ->
            ok
    end,
    {released, ResourceId} = receive
        {released, ReleasedId} ->
            {released, ReleasedId}
    end,

    Resources = graphics_context:inner_resources(),
    0 = maps:size(Resources),
    {ok, false} = graphics_context:execute_commands(fun() ->
        gl:is_buffer(Buffer)
    end),

    ok = graphics_context:stop(),
    ok.

graphics_context_stop_releases_test() ->
    {_Display, _Pid} = start_graphics(),
    Self = self(),

    {ok, ResourceId} = graphics_context:acquire_resource(
        buffer_acquire_fun(Self)
    ),
    {acquired, ResourceId} = receive
        {acquired, AcquiredId} ->
            {acquired, AcquiredId}
    end,

    ok = graphics_context:stop(),
    {released, ResourceId} = receive
        {released, ReleasedId} ->
            {released, ReleasedId}
    end,
    ok.

graphics_context_execute_commands_exception_test() ->
    {_Display, _Pid} = start_graphics(),

    {error, {exception, error, foobar}} =
        graphics_context:execute_commands(fun() ->
            error(foobar)
        end),

    {ok, _Version} = graphics_context:execute_commands(fun() ->
        gl:get_string(version)
    end),

    ok = graphics_context:stop(),
    ok.

graphics_context_acquire_exception_test() ->
    {_Display, _Pid} = start_graphics(),

    {error, {exception, error, foobar}} =
        graphics_context:acquire_resource(fun() ->
            error(foobar)
        end),

    Resources = graphics_context:inner_resources(),
    0 = maps:size(Resources),

    {ok, _Version} = graphics_context:execute_commands(fun() ->
        gl:get_string(version)
    end),

    ok = graphics_context:stop(),
    ok.
