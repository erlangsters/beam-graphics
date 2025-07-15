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
To be written.

To be written.
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

-include_lib("gl/include/gl.hrl").

-doc """
To be written.

To be written.
""".
-type resource_id() :: term().
-doc """
To be written.

To be written.
""".
-type resource_release_fun() ::
    fun((resource_id()) -> ok)
.
-doc """
To be written.

To be written.
""".
-type resource_acquire_fun() ::
    fun(() -> {ok, resource_id(), resource_release_fun()} | {error, term()})
.

-define(WORKER_NAME, '$beam_graphics_context').
-define(STOP_REQUEST, '$beam_graphics_stop_context').
-define(OWNER_DOWN_MESSAGE, '$beam_graphics_owner_down').

-record(state, {
    display :: egl:display(),
    config :: egl:config(),
    context :: egl:context(),
    surface :: egl:surface(),
    resources = #{} :: #{
        {resource_id()} := {pid(), reference(), resource_release_fun()}
    }
}).

-doc """
To be written.

To be written.
""".
-spec start(egl:display()) -> worker:start_ret().
start(Display) ->
    worker:spawn(link, {name, ?WORKER_NAME}, ?MODULE, [Display]).

-doc """
To be written.

To be written.
""".
-spec stop() -> ok.
stop() ->
    {reply, Reply} = worker:request(?WORKER_NAME, ?STOP_REQUEST),
    Reply.

-doc """
To be written.

To be written.
""".
-spec inner_context() -> egl:context().
inner_context() ->
    {reply, Context} = worker:request(?WORKER_NAME, inner_context),
    Context.

-doc """
To be written.

To be written.
""".
-spec execute_commands(fun(() -> term())) -> term().
execute_commands(Commands) ->
    {reply, Reply} = worker:request(?WORKER_NAME, {execute_commands, Commands}),
    Reply.

-doc """
To be written.

To be written.
""".
-spec acquire_resource(resource_acquire_fun()) ->
    {ok, resource_id()} | {error, term()}
.
acquire_resource(AcquireFun) ->
    Request = {acquire_resource, AcquireFun, self()},
    {reply, Reply} = worker:request(?WORKER_NAME, Request),
    Reply.

-doc """
To be written.

To be written.
""".
-spec release_resource(resource_id()) -> ok | invalid_resource_id.
release_resource(ResourceId) ->
    {reply, Reply} = worker:request(?WORKER_NAME, {release_resource, ResourceId}),
    Reply.

-doc """
To be written.

To be written.
""".
-spec inner_resources() -> #{resource_id() := pid()}.
inner_resources() ->
    {reply, Resources} = worker:request(?WORKER_NAME, inner_resources),
    Resources.

-doc """
To be written.

To be written.
""".
-spec transfer_ownership(resource_id(), pid()) ->
    ok | invalid_resource_id.
transfer_ownership(ResourceId, Owner) ->
    {reply, Reply} = worker:request(
        ?WORKER_NAME,
        {transfer_ownership, ResourceId, Owner}
    ),
    Reply.

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
        context = Context,
        surface = Surface
    }}.

handle_request(
    inner_context,
    _From,
    #state{context = Context} = State
) ->
    {reply, Context, State};

handle_request({execute_commands, Commands}, _From, State) ->
    Result = Commands(),
    {reply, Result, State};

handle_request(
    {acquire_resource, AcquireFun, Owner},
    _From,
    #state{resources = Resources} = State
) ->
    {Reply, NewState} = case AcquireFun() of
        {ok, ResourceId, ReleaseFun} ->
            OwnerMonitor = erlang:monitor(process,
                Owner,
                [{tag, {?OWNER_DOWN_MESSAGE, ResourceId}}]
            ),
            NewResources = maps:put(
                ResourceId,
                {Owner, OwnerMonitor, ReleaseFun},
                Resources
            ),
            {{ok, ResourceId}, State#state{resources = NewResources}};
        {error, Reason} ->
            {{error, Reason}, State}
    end,
    {reply, Reply, NewState};

handle_request(
    {release_resource, ResourceId},
    _From,
    #state{resources = Resources} = State
) ->
    {Reply, NewState} = case maps:get(ResourceId, Resources, undefined) of
        undefined ->
            {invalid_resource_id, State};
        {_Owner, OwnerMonitor, ReleaseFun} ->
            ok = ReleaseFun(ResourceId),

            erlang:demonitor(OwnerMonitor, [flush]),

            NewResources = maps:remove(ResourceId, Resources),
            {ok, State#state{resources = NewResources}}
    end,
    {reply, Reply, NewState};

handle_request(inner_resources, _From, #state{resources = Resources} = State) ->
    % We only return the owner for each resource (discarding the monitor and
    % the release function).
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

handle_message(
    {{?OWNER_DOWN_MESSAGE, ResourceId}, OwnerMonitor, process, Owner, _Reason},
    #state{resources = Resources} = State
) ->
    {{Owner, OwnerMonitor, ReleaseFun}, NewResources} =
        maps:take(ResourceId, Resources),

    % Release the resource.
    ok = ReleaseFun(ResourceId),

    {continue, State#state{resources = NewResources}}.

terminate(requested, #state{resources = Resources}) ->
    maps:foreach(fun(ResourceId, {_Owner, OwnerMonitor, ReleaseFun}) ->
        % Release the resource.
        ok = ReleaseFun(ResourceId),

        % Delete the monitor.
        erlang:demonitor(OwnerMonitor, [flush])
    end, Resources),

    ok.
