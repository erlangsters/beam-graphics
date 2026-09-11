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
The root graphics context.

It's a background process that holds an OpenGL context which is shared with the
OpenGL context of all `graphics:surface/0` objects. It's responsible for
creating, manipulating, and destroying OpenGL resources such as buffers and
textures which are shareable resources (and therefore can be used by all
surfaces).

> The OpenGL context is always active within the process. The sole responsibility
> of the process is to handle OpenGL resources and operations, and frees up
> when process owning them die.

The root graphics context serves as the foundation of the graphics library
and therefore must be started before any other graphics-related operations can
take place.

```erlang
ok = graphics_context:start().
```

Note that it's done by the `graphics:initialize/0` function (which should be
used instead).

To access the inner OpenGL context, use the `graphics_context:inner_context/0`
function.

```erlang
{ok, Context} = graphics_context:inner_context(),
```

Unless you intend to use your own OpenGL calls, you do not need to retrieve
the inner OpenGL context. (rephrase).

Later...

```
ok = graphics_context:stop().
```

It's indirectly performed by the `graphics:terminate/0` function.

**OpenGL resources and ownership**

The sole responsibility of the process is to holds shared OpenGL resources
which implies a dependency of those resources on the root graphics context.

**About "mesh" operations**

To be written.

**About "texture" operations**

The texture-related functions allow to create, manipulate, and destroy OpenGL
textures (on the root OpenGL context). Together, those functions allow the
implementation of the `graphics:texture/0` object.

- `texture_new/3` - Create an OpenGL texture (and initialize it, first allocation).
- `texture_set_data/3` - Set the data of an OpenGL texture (re-allocation).
- `texture_data/3` - Read the data (or a subset) of an OpenGL texture.
- `texture_update_data/3` - Update the data of an OpenGL texture (no re-allocation).
- `texture_destroy/1` - Destroy an OpenGL texture.

Notice how they reflect the semantics of the OpenGL API
(uninitialized/allocation/re-allocation) with one constraint: the texture is
always initialized (it must be at least 1x1 pixel in size).

```
{ok, [Texture]} = gl:gen_textures(1),
ok = gl:bind_texture(texture_2d, Texture),
ok = gl:tex_image_2d()
```

Each pixel must be encoded in the following format:
```
R:8/unsigned byte
G:8/unsigned byte
B:8/unsigned byte
A:8/unsigned byte
```

Blabla.

**About "shader program" operations**

To be written.

```
XXX: Can be optimized in various way. For instance, if keeping the a release
     function per resource is too expensive, it can implement a "register
    "resource type" mechanism.
XXX: The start/x function should return infos about the OpenGL context, such as
     the version, the vendor, etc.
XXXX: verify if a pbuffer surface is needed (or if passing no_surface is enough)

XXX: Consider adding "kill" option to stop/x function in order to kill owners of
     resources before freeing the resources.
```
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
    swap_buffers/0
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

% -include_lib("gl/include/gl.hrl").

% -type resource_type() :: atom().
% -type resource_handle() :: gl:texture() | gl:buffer() | gl:program().
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
The inner OpenGL context.

It returns the inner OpenGL context which is shared by the OpenGL context of
all surfaces.
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
-spec swap_buffers() -> ok.
swap_buffers() ->
    {reply, Reply} = worker:request(?WORKER_NAME, swap_buffers),
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
        % % % {context_opengl_profile_mask, [context_opengl_core_profile_bit]},
        % {context_opengl_forward_compatible, true},

        % {context_opengl_robust_access, false},
        % {context_opengl_debug, true},
        % % % {context_opengl_reset_notification_strategy, lose_context_on_reset},
        % % {context_opengl_reset_notification_strategy, no_reset_notification},

        {context_major_version, 4},
        {context_minor_version, 6}
    ],
    {ok, Context} =
        egl:create_context(Display, Config, no_context, ContextAttribs),
    % egl_helper:print_context(Display, Context),

    ok = egl:make_current(Display, Surface, Surface, Context),
    io:format(user, "[debug] OpenGL context made current~n", []),
    ok = gl:glad_load_gl(),

    io:format(user, "[debug] aaa~n", []),
    no_error = gl:get_error(),
    io:format(user, "[debug] bbb~n", []),

    {ok, Version} = gl:get_string(version),
    io:format(user, "OpenGL version: ~p~n", [Version]),

    {continue, #state{
        display = Display,
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
    swap_buffers,
    _From,
    #state{
        display = Display,
        surface = Surface
    } = State
) ->
    ok = egl:swap_buffers(Display, Surface),
    {reply, ok, State};

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
