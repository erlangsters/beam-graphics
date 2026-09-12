%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_context).
-moduledoc """
Graphics Context

The graphics context is the root GPU process that holds the shared OpenGL
context and the shareable GPU resources.

It is a singleton. It is started with `start/1` and stopped with `stop/0`.
The calling process is linked to it. `graphics:initialize/1` starts it.

```erlang
Display = egl:get_display(default_display),
{ok, {_, _}} = egl:initialize(Display),
{ok, _Pid} = graphics_context:start(Display).
```

Meshes, textures, programs, and frames are created on this context. Surfaces
create their own OpenGL contexts that share with this one. There is one
graphics context for both 2D and 3D drawing.

A GPU resource is acquired with `acquire_resource/1`. The calling process
becomes the owner. If that process dies, the resource is released.
`transfer_ownership/2` changes the owner without destroying the GPU object.
Copying a resource term does not copy the GPU object. Anyone who has the
resource id may release or transfer it.

```erlang
ok = graphics_context:stop().
```

`stop/0` releases remaining resources. Using them afterwards has undefined
behavior. Owners are not killed. `graphics:terminate/0` stops it.

**OpenGL Internals**

The process keeps an EGL context current. `inner_context/0` returns that
handle so another context can share with it. `execute_commands/1` runs
OpenGL calls while it is current.
""".

-behavior(worker).

-export_type([
    resource_id/0,
    resource_release_fun/0,
    resource_acquire_fun/0
]).
-export([
    start/1,
    stop/0
]).
-export([
    inner_context/0,
    execute_commands/1
]).
-export([
    acquire_resource/1,
    release_resource/1,
    inner_resources/0,
    transfer_ownership/2
]).
-export([
    initialize/1,
    handle_request/3,
    handle_message/2,
    terminate/2
]).

-doc """
A GPU resource identifier.

It is chosen by the acquire function. It must be unique among live resources.
Typical values are tagged tuples such as `{texture, GlTexture}`.
""".
-type resource_id() :: term().

-doc """
A GPU resource release function.

It runs on the graphics context process. The OpenGL context is current. It is
called when the resource is released, when the owner process dies, or when
the graphics context stops.
""".
-type resource_release_fun() ::
    fun((resource_id()) -> ok)
.

-doc """
A GPU resource acquire function.

It runs on the graphics context process. The OpenGL context is current. It
returns `{ok, ResourceId, ReleaseFun}` or `{error, Reason}`.
""".
-type resource_acquire_fun() ::
    fun(() -> {ok, resource_id(), resource_release_fun()} | {error, term()})
.

-define(WORKER_NAME, '$beam_graphics_context').
-define(STOP_REQUEST, '$beam_graphics_stop_context').
-define(OWNER_DOWN_MESSAGE, '$beam_graphics_owner_down').

-record(state, {
    display :: egl:display(),
    context :: egl:context(),
    surface :: egl:surface(),
    resources = #{} :: #{
        resource_id() => {pid(), reference(), resource_release_fun()}
    }
}).

-doc """
Start the graphics context.

It starts the singleton process for the given EGL display. The calling
process is linked to it. A second start is `already_spawned`.

The display must already be initialized. Meshes, textures, programs, and
frames require a running graphics context.
""".
-spec start(egl:display()) ->
    {ok, pid()} |
    already_spawned |
    {aborted, term()} |
    timeout |
    {error, term()}
.
start(Display) ->
    worker:spawn(link, {name, ?WORKER_NAME}, ?MODULE, [Display]).

-doc """
Stop the graphics context.

It releases remaining GPU resources and destroys the inner OpenGL context.
Using a resource after stop has undefined behavior. Owners are not killed.
""".
-spec stop() -> ok.
stop() ->
    {reply, Reply} = worker:request(?WORKER_NAME, ?STOP_REQUEST),
    Reply.

-doc """
The inner OpenGL context.

It returns the EGL context handle. Surfaces create their own OpenGL contexts
that share with this one.
""".
-spec inner_context() -> egl:context().
inner_context() ->
    {reply, Context} = worker:request(?WORKER_NAME, inner_context),
    Context.

-doc """
Run OpenGL commands.

It runs the given function on the graphics context process. The OpenGL
context is current. The return value is the function's return value.

If the function raises, it returns `{error, {exception, Class, Reason}}` and
the graphics context stays running.
""".
-spec execute_commands(fun(() -> term())) -> term().
execute_commands(Commands) ->
    {reply, Reply} = worker:request(?WORKER_NAME, {execute_commands, Commands}),
    Reply.

-doc """
Acquire a GPU resource.

It runs the acquire function on the graphics context process. The OpenGL
context is current. The calling process becomes the owner.

The acquire function must return `{ok, ResourceId, ReleaseFun}` or
`{error, Reason}`. The resource id must be unique among live resources. A
duplicate id is `{error, already_acquired}` and the new GPU object is
released.

If the function raises, it returns `{error, {exception, Class, Reason}}` and
no resource is registered.
""".
-spec acquire_resource(resource_acquire_fun()) ->
    {ok, resource_id()} | {error, term()}
.
acquire_resource(AcquireFun) ->
    Request = {acquire_resource, AcquireFun, self()},
    {reply, Reply} = worker:request(?WORKER_NAME, Request),
    Reply.

-doc """
Release a GPU resource.

It runs the release function on the graphics context process and drops the
resource from the owner table. A missing id is `invalid_resource_id`.
""".
-spec release_resource(resource_id()) -> ok | invalid_resource_id.
release_resource(ResourceId) ->
    {reply, Reply} = worker:request(?WORKER_NAME, {release_resource, ResourceId}),
    Reply.

-doc """
The inner GPU resources.

It returns a snapshot of live resource ids and their owner processes.
""".
-spec inner_resources() -> #{resource_id() => pid()}.
inner_resources() ->
    {reply, Resources} = worker:request(?WORKER_NAME, inner_resources),
    Resources.

-doc """
Transfer ownership of a GPU resource.

It changes the owner of the given resource without destroying the GPU object.
A missing id is `invalid_resource_id`.
""".
-spec transfer_ownership(resource_id(), pid()) ->
    ok | invalid_resource_id
.
transfer_ownership(ResourceId, Owner) ->
    {reply, Reply} = worker:request(
        ?WORKER_NAME,
        {transfer_ownership, ResourceId, Owner}
    ),
    Reply.

-doc false.
initialize([Display]) ->
    ConfigAttribs = [
        {surface_type, [pbuffer_bit]},
        {renderable_type, [opengl_bit]}
    ],
    {ok, Configs} = egl:choose_config(Display, ConfigAttribs),
    Config = hd(Configs),

    SurfaceAttribs = [
        {width, 1},
        {height, 1}
    ],
    {ok, Surface} = egl:create_pbuffer_surface(Display, Config, SurfaceAttribs),

    egl:bind_api(opengl_api),
    ContextAttribs = [
        {context_major_version, 4},
        {context_minor_version, 6}
    ],
    {ok, Context} =
        egl:create_context(Display, Config, no_context, ContextAttribs),

    ok = egl:make_current(Display, Surface, Surface, Context),
    ok = gl:glad_load_gl(),

    {continue, #state{
        display = Display,
        context = Context,
        surface = Surface
    }}.

-doc false.
handle_request(
    inner_context,
    _From,
    #state{context = Context} = State
) ->
    {reply, Context, State};

handle_request({execute_commands, Commands}, _From, State) ->
    drain_gl_errors(),
    Reply = try Commands() of
        Result ->
            Result
    catch
        Class:Reason:_Stack ->
            {error, {exception, Class, Reason}}
    end,
    {reply, Reply, State};

handle_request(
    {acquire_resource, AcquireFun, Owner},
    _From,
    #state{resources = Resources} = State
) ->
    drain_gl_errors(),
    {Reply, NewState} = try AcquireFun() of
        {ok, ResourceId, ReleaseFun} ->
            case maps:is_key(ResourceId, Resources) of
                true ->
                    run_release(ReleaseFun, ResourceId),
                    {{error, already_acquired}, State};
                false ->
                    OwnerMonitor = erlang:monitor(
                        process,
                        Owner,
                        [{tag, {?OWNER_DOWN_MESSAGE, ResourceId}}]
                    ),
                    NewResources = maps:put(
                        ResourceId,
                        {Owner, OwnerMonitor, ReleaseFun},
                        Resources
                    ),
                    {{ok, ResourceId}, State#state{resources = NewResources}}
            end;
        {error, Reason} ->
            {{error, Reason}, State}
    catch
        Class:Reason:_Stack ->
            {{error, {exception, Class, Reason}}, State}
    end,
    {reply, Reply, NewState};

handle_request(
    {release_resource, ResourceId},
    _From,
    #state{resources = Resources} = State
) ->
    {Reply, NewState} = case maps:take(ResourceId, Resources) of
        {{_Owner, OwnerMonitor, ReleaseFun}, NewResources} ->
            run_release(ReleaseFun, ResourceId),
            erlang:demonitor(OwnerMonitor, [flush]),
            {ok, State#state{resources = NewResources}};
        error ->
            {invalid_resource_id, State}
    end,
    {reply, Reply, NewState};

handle_request(inner_resources, _From, #state{resources = Resources} = State) ->
    Reply = maps:map(fun(_ResourceId, {Owner, _OwnerMonitor, _ReleaseFun}) ->
        Owner
    end, Resources),
    {reply, Reply, State};

handle_request(
    {transfer_ownership, ResourceId, NewOwner},
    _From,
    #state{resources = Resources} = State
) ->
    {Reply, NewState} = case maps:get(ResourceId, Resources, undefined) of
        undefined ->
            {invalid_resource_id, State};
        {_Owner, OwnerMonitor, ReleaseFun} ->
            NewOwnerMonitor = erlang:monitor(
                process,
                NewOwner,
                [{tag, {?OWNER_DOWN_MESSAGE, ResourceId}}]
            ),
            erlang:demonitor(OwnerMonitor, [flush]),
            NewResources = maps:put(
                ResourceId,
                {NewOwner, NewOwnerMonitor, ReleaseFun},
                Resources
            ),
            {ok, State#state{resources = NewResources}}
    end,
    {reply, Reply, NewState};

handle_request(?STOP_REQUEST, _From, State) ->
    {stop, requested, ok, State}.

-doc false.
handle_message(
    {{?OWNER_DOWN_MESSAGE, ResourceId}, _OwnerMonitor, process, _Owner, _Reason},
    #state{resources = Resources} = State
) ->
    NewState = case maps:take(ResourceId, Resources) of
        {{_TrackedOwner, _TrackedMonitor, ReleaseFun}, NewResources} ->
            run_release(ReleaseFun, ResourceId),
            State#state{resources = NewResources};
        error ->
            State
    end,
    {continue, NewState}.

-doc false.
terminate(_Reason, #state{
    display = Display,
    context = Context,
    surface = Surface,
    resources = Resources
}) ->
    maps:foreach(fun(ResourceId, {_Owner, OwnerMonitor, ReleaseFun}) ->
        run_release(ReleaseFun, ResourceId),
        erlang:demonitor(OwnerMonitor, [flush])
    end, Resources),
    % Do not unbind with `no_context`: that EGL path asserts. Destroy the
    % pbuffer and context from this process while they are still current.
    _ = egl:destroy_surface(Display, Surface),
    _ = egl:destroy_context(Display, Context),
    ok.

run_release(ReleaseFun, ResourceId) ->
    drain_gl_errors(),
    try ReleaseFun(ResourceId) of
        _ ->
            ok
    catch
        _Class:_Reason:_Stack ->
            ok
    end.

drain_gl_errors() ->
    case gl:get_error() of
        {ok, no_error} ->
            ok;
        {ok, _Error} ->
            drain_gl_errors();
        _ ->
            ok
    end.
