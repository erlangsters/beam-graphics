%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(surface).
-moduledoc """
To be written.

To be written.
""".

-behavior(worker).

-export_type([
    size/0,
    viewport/0
]).
-export_type([
    object/0
]).

-export([
    from_window/3
]).
-export([
    with_size/2,
    size/1,
    view_matrix/1,
    set_view_matrix/2,
    projection_matrix/1,
    set_projection_matrix/2,
    viewport/1,
    set_viewport/2,
    clear/2,
    draw_mesh2/4, draw_mesh2/5, draw_mesh2/6,
    draw_mesh3/4, draw_mesh3/5, draw_mesh3/6,
    draw_shape2/2,
    draw_shape3/2,
    display/1
]).
-export([
    gl_context/1,
    gl_commands/2
]).
-export([
    initialize/1,
    handle_request/3
]).

-compile({inline, [
    size/1
]}).
-compile({inline, [
    default_view_matrix/0,
    default_projection_matrix/2
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-define(VERTEX_SHADER_SRC, """
#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aColor;
layout(location = 2) in vec2 aTexCoords;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

out vec4 vColor;
out vec2 vTexCoords;

void main() {
    gl_Position = uProjection * uView * uModel * vec4(aPos, 1.0);
    vColor = aColor;
    vTexCoords = aTexCoords;
}
""").

-define(FRAGMENT_SHADER_SRC, """
#version 460 core
in vec4 vColor;
in vec2 vTexCoords;

out vec4 FragColor;

uniform sampler2D uTexture;
uniform bool uUseTexture;

void main() {
    vec4 color = vColor;
    if (uUseTexture) {
        vec4 texColor = texture(uTexture, vTexCoords);
        color *= texColor;
    }
    FragColor = color;
}
""").

-record(state, {
    display :: egl:display(),
    context :: egl:context(),
    surface :: egl:surface(),
    program :: gl:program(),
    % Location of the view and projection matrices in the shader program.
    model_location :: gl:location(),
    view_location :: gl:location(),
    projection_location :: gl:location()
}).

-type size() :: {
    Width :: pos_integer(),
    Height :: pos_integer()
}.
-type viewport() :: {
    X :: non_neg_integer(),
    Y :: non_neg_integer(),
    Width :: pos_integer(),
    Height :: pos_integer()
}.

-opaque object() :: {
    WorkerId :: worker:id(),
    Size :: size()
}.

-doc """
To be written.

To be written.
""".
-spec from_window(egl:display(), egl:window(), size()) -> worker:start_ret().
from_window(Display, Window, {Width, Height}) when Width > 0 andalso Height > 0 ->
    {ok, WorkerId} = worker:spawn(link, ?MODULE, [Display, Window, Width, Height]),
    {ok, {WorkerId, {Width, Height}}}.

-doc """
To be written.

To be written.
""".
-spec with_size(egl:display(), size()) -> worker:start_ret().
with_size(Display, {Width, Height}) when Width > 0 andalso Height > 0 ->
    {ok, WorkerId} = worker:spawn(link, ?MODULE, [Display, no_window, Width, Height]),
    {ok, {WorkerId, {Width, Height}}}.

-doc """
To be written.

To be written.
""".
-spec size(object()) -> size().
size({_, Size}) ->
    Size.

-doc """
To be written.

To be written.
""".
-spec view_matrix(object()) -> graphics:matrix4().
view_matrix({WorkerId, _}) ->
    {reply, Values} = worker:request(WorkerId, view_matrix),
    erlang:list_to_tuple(Values).

-doc """
To be written.

To be written.
""".
-spec set_view_matrix(object(), graphics:matrix4()) -> ok.
set_view_matrix({WorkerId, _}, Matrix) ->
    GlMatrix = matrix4:columns(Matrix),
    {reply, ok} = worker:request(WorkerId, {set_view_matrix, GlMatrix}),
    ok.

-doc """
To be written.

To be written.
""".
-spec projection_matrix(object()) -> graphics:matrix4().
projection_matrix({WorkerId, _Size}) ->
    {reply, Values} = worker:request(WorkerId, projection_matrix),
    erlang:list_to_tuple(Values).

-doc """
To be written.

To be written.
""".
-spec set_projection_matrix(object(), graphics:matrix4()) -> ok.
set_projection_matrix({WorkerId, _}, Matrix) ->
    GlMatrix = matrix4:columns(Matrix),
    {reply, ok} = worker:request(WorkerId, {set_projection_matrix, GlMatrix}),
    ok.

-doc """
To be written.

To be written.
""".
-spec viewport(object()) -> viewport().
viewport({WorkerId, _}) ->
    {reply, Viewport} = worker:request(WorkerId, viewport),
    Viewport.

-doc """
To be written.

To be written.
""".
-spec set_viewport(object(), viewport()) -> ok.
set_viewport({WorkerId, _}, Viewport) ->
    {reply, ok} = worker:request(WorkerId, {set_viewport, Viewport}),
    ok.

-doc """
To be written.

To be written.
""".
-spec clear(object(), graphics:color()) -> ok.
clear({WorkerId, _}, Color) ->
    {reply, ok} = worker:request(WorkerId, {clear, Color}),
    ok.

-doc """
To be written.

To be written.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count()
) -> ok.
draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount) ->
    % XXX: Minor optimization can be made here.
    draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
To be written.

To be written.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) -> ok.
draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, Texture) ->
    % XXX: Minor optimization can be made here.
    draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX3_IDENTITY).


-doc """
To be written.

To be written.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture(),
    graphics:matrix3()
) -> ok.
draw_mesh2({WorkerId, _}, Mesh, PrimitiveType, VertexCount, Texture, Matrix3) ->
    Buffer = mesh2:gl_object(Mesh),
    Matrix4 = matrix3:to_matrix4(Matrix3),
    Request = {
        draw,
        {mesh2, Buffer},
        PrimitiveType,
        VertexCount,
        Texture,
        matrix4:columns(Matrix4)
    },
    {reply, ok} = worker:request(WorkerId, Request),
    ok.

-doc """
To be written.

To be written.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count()
) -> ok.
draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount) ->
    draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
To be written.

To be written.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) -> ok.
draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, Texture) ->
    draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX4_IDENTITY).


-doc """
To be written.

To be written.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture(),
    graphics:matrix4()
) -> ok.
draw_mesh3({WorkerId, _}, Mesh, PrimitiveType, VertexCount, Texture, Matrix) ->
    Buffer = mesh3:gl_object(Mesh),
    Request = {
        draw,
        {mesh3, Buffer},
        PrimitiveType,
        VertexCount,
        Texture,
        matrix4:columns(Matrix)
    },
    {reply, ok} = worker:request(WorkerId, Request),
    ok.

-doc """
To be written.

To be written.
""".
-spec draw_shape2(object(), graphics:shape2()) -> ok.
draw_shape2(
    Surface,
    #shape2{
        meshes = Meshes,
        texture = Texture,
        matrix = Matrix
    }
) ->
    % XXX: It should be matrix3 which is later converted.
    % XXX: this can be optimized.
    lists:foreach(fun({Mesh, PrimitiveType, VertexCount}) ->
        draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, Texture, Matrix)
    end, Meshes).

-doc """
To be written.

To be written.
""".
-spec draw_shape3(object(), graphics:shape3()) -> ok.
draw_shape3(
    Surface,
    #shape3{
        meshes = Meshes,
        texture = Texture,
        matrix = Matrix
    }
) ->
    % XXX: It should be matrix3 which is later converted.
    % XXX: this can be optimized.
    lists:foreach(fun({Mesh, PrimitiveType, VertexCount}) ->
        draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, Texture, Matrix)
    end, Meshes).

-doc """
To be written.

To be written.
""".
-spec display(object()) -> ok.
display({WorkerId, _}) ->
    {reply, ok} = worker:request(WorkerId, display),
    ok.

-doc """
To be written.

To be written.
""".
-spec gl_context(object()) -> egl:context().
gl_context({WorkerId, _}) ->
    {reply, Context} = worker:request(WorkerId, gl_context),
    Context.

-doc """
To be written.

To be written.
""".
-spec gl_commands(object(), fun(() -> term())) -> term().
gl_commands({WorkerId, _}, Commands) ->
    {reply, Reply} = worker:request(WorkerId, {gl_commands, Commands}),
    Reply.

initialize([Display, Window, Width, Height]) ->
    ShareContext = graphics_context:inner_context(),
    egl_helper:print_context(Display, ShareContext),

    ConfigAttribs = [
        {surface_type, [window_bit]},
        {renderable_type, [opengl_bit]}
    ],
    {ok, Configs} = egl:choose_config(Display, ConfigAttribs),
    Config = hd(Configs),

    ContextAttribs = [
        {context_major_version, 4},
        {context_minor_version, 6}
    ],
    egl:bind_api(opengl_api),
    {ok, Context} =
        egl:create_context(Display, Config, ShareContext, ContextAttribs),

    {ok, Surface} = egl:create_window_surface(Display, Config, Window, []),

    ok = egl:make_current(Display, Surface, Surface, Context),

    % The default shader with default values for view and projection matrices.
    % XXX: Handle failure.
    {Program, ModelLocation, ViewLocation, ProjectionLocation} =
        setup_program(Width, Height),

    % The default shader program is always bound.
    ok = gl:use_program(Program),

    % When rendering with a texture, we always use texture unit 0.
    ok = gl:active_texture(texture0),

    {ok, TextureLocation} = gl:get_uniform_location(Program, "uTexture"),
    ok = gl:uniform(i, TextureLocation, {0}),

    gl:enable(depth_test),
    gl:front_face(ccw),

    {continue, #state{
        display = Display,
        context = Context,
        surface = Surface,
        program = Program,
        model_location = ModelLocation,
        view_location = ViewLocation,
        projection_location = ProjectionLocation
    }}.

handle_request(viewport, _From, State) ->
    {ok, [X, Y, Width, Height]} = gl:get_integer(viewport, 4),
    {reply, {X, Y, Width, Height}, State};

handle_request({set_viewport, {X, Y, Width, Height}}, _From, State) ->
    ok = gl:viewport(X, Y, Width, Height),
    {reply, ok, State};

handle_request(
    view_matrix,
    _From,
    #state{
        program = Program,
        view_location = Location
    } = State
) ->
    {ok, Values} = gl:get_uniform(f, Program, Location, 16),
    {reply, Values, State};

handle_request(
    {set_view_matrix, Matrix},
    _From,
    #state{
        view_location = Location
    } = State
) ->
    ok = gl:uniform_matrix(f, Location, 1, false, [Matrix]),
    {reply, ok, State};

handle_request(
    projection_matrix,
    _From,
    #state{
        program = Program,
        projection_location = Location
    } = State
) ->
    {ok, Values} = gl:get_uniform(f, Program, Location, 16),
    {reply, Values, State};

handle_request(
    {set_projection_matrix, Matrix},
    _From,
    #state{
        projection_location = Location
    } = State
) ->
    ok = gl:uniform_matrix(f, Location, 1, false, [Matrix]),
    {reply, ok, State};

handle_request(
    {clear, {Red, Green, Blue, Alpha}},
    _From,
    #state{
    } = State
) ->
    gl:clear_color(Red, Green, Blue, Alpha),
    gl:clear([color_buffer_bit, depth_buffer_bit]),
    {reply, ok, State};

handle_request(
    {draw, Mesh, PrimitiveType, VertexCount, Texture, Matrix},
    _From,
    #state{
        model_location = ModelLocation,
        program = Program
    } = State
) ->

    {ok, [VertexArray]} = gl:gen_vertex_arrays(1),
    gl:bind_vertex_array(VertexArray),

    case Mesh of
        {mesh2, Buffer} ->
            gl:bind_vertex_buffer(0, Buffer, 0, 4*(2 + 4 + 2)),

            gl:vertex_attrib_format(0, 2, float, false, 0),
            gl:vertex_attrib_binding(0, 0),
            gl:enable_vertex_attrib_array(0),

            gl:vertex_attrib_format(1, 4, float, false, 2 * 4),
            gl:vertex_attrib_binding(1, 0),
            gl:enable_vertex_attrib_array(1),

            gl:vertex_attrib_format(2, 2, float, false, (2 + 4) * 4),
            gl:vertex_attrib_binding(2, 0),
            gl:enable_vertex_attrib_array(2);


        {mesh3, Buffer} ->
            gl:bind_vertex_buffer(0, Buffer, 0, 4*(3 + 4 + 2)),

            gl:vertex_attrib_format(0, 3, float, false, 0),
            gl:vertex_attrib_binding(0, 0),
            gl:enable_vertex_attrib_array(0),

            gl:vertex_attrib_format(1, 4, float, false, 3 * 4),
            gl:vertex_attrib_binding(1, 0),
            gl:enable_vertex_attrib_array(1),

            gl:vertex_attrib_format(2, 2, float, false, (3 + 4) * 4),
            gl:vertex_attrib_binding(2, 0),
            gl:enable_vertex_attrib_array(2)
    end,

    ok = gl:uniform_matrix(f, ModelLocation, 1, false, [Matrix]),

    % XXX: Location could be cached.
    {ok, UseTextureLocation} = gl:get_uniform_location(Program, "uUseTexture"),
    case Texture of
        no_texture ->
            ok = gl:uniform(i, UseTextureLocation, {0});
        _ ->
            ok = gl:uniform(i, UseTextureLocation, {1}),

            GlTexture = texture:gl_object(Texture),
            ok = gl:bind_texture(texture_2d, GlTexture)
    end,

    ok = gl:draw_arrays(PrimitiveType, 0, VertexCount),

    case Texture of
        no_texture ->
            ok;
        _ ->
            ok = gl:bind_texture(texture_2d, 0)
    end,

    ok = gl:bind_vertex_array(0),
    ok = gl:delete_vertex_arrays(1, [VertexArray]),

    {reply, ok, State};

handle_request(
    display,
    _From,
    #state{
        display = Display,
        surface = Surface
    } = State
) ->
    ok = egl:swap_buffers(Display, Surface),
    {reply, ok, State};

handle_request(gl_context, _From, #state{context = Context} = State) ->
    {reply, Context, State};

handle_request({gl_commands, Commands}, _From, State) ->
    Result = Commands(),
    {reply, Result, State}.

setup_program(Width, Height) ->
    {ok, ProgramX} = program:with_shaders(
        ?VERTEX_SHADER_SRC,
        ?FRAGMENT_SHADER_SRC
    ),
    Program = program:gl_object(ProgramX),
    ok = gl:use_program(Program),

    % Retrieve uniform locations (model, view and projection matrices).
    {ok, ModelLocation} = gl:get_uniform_location(Program, "uModel"),
    {ok, ViewLocation} = gl:get_uniform_location(Program, "uView"),
    {ok, ProjectionLocation} = gl:get_uniform_location(Program, "uProjection"),

    % Set up default model matrix (no transformation).
    GlModelMatrix = matrix4:columns(?MATRIX4_IDENTITY),
    gl:uniform_matrix(f, ModelLocation, 1, false, [GlModelMatrix]),

    % Set up default view matrix (no transformation).
    ViewMatrix = default_view_matrix(),
    GlViewMatrix = matrix4:columns(ViewMatrix),
    gl:uniform_matrix(f, ViewLocation, 1, false, [GlViewMatrix]),

    % Set up default projection matrix (an orthographic projection).
    % XXX: What is a good value for the near and far planes?
    ProjectionMatrix = default_projection_matrix(Width, Height),
    GlProjectionMatrix = matrix4:columns(ProjectionMatrix),
    gl:uniform_matrix(f, ProjectionLocation, 1, false, [GlProjectionMatrix]),

    % Set up default viewport.
    ok = gl:viewport(0, 0, Width, Height),

    {Program, ModelLocation, ViewLocation, ProjectionLocation}.

default_view_matrix() ->
    ?MATRIX4_IDENTITY.

default_projection_matrix(Width, Height) ->
    view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).
