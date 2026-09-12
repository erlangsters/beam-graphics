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
Surface

A surface is a presentable 2D image that is typically used as a render target.

A surface is an opaque object that wraps an EGL window or pbuffer, a dedicated
OpenGL context, and a default program. It is created with the `with_size` and
`with_window` functions and disposed with the `destroy/1` function. Copying
the term does not copy the EGL objects.

A surface is not a frame. A frame is sampled later as a texture, with no
presentation and no CPU round-trip. A surface presents to a window or a
pbuffer. `image/1` reads CPU pixels. `display/1` presents. Meshes, textures,
and programs used with a surface are created on `graphics_context`; the
surface context shares with that one.

```erlang
{ok, Surface} = surface:with_size(Display, {640, 480}),
ok = surface:clear(Surface, ?COLOR_BLACK),
ok = surface:draw_mesh2(Surface, Mesh, triangles, 3),
Image = surface:image(Surface),
ok = surface:destroy(Surface).
```

A running graphics context is required. The calling process is linked to the
surface worker.

Meshes are drawn on a surface with a primitive type and an optional texture.
The primitive type and the texture are not part of the mesh; they are
arguments of `draw_mesh2/4` and of `shape2`. The same holds for 3D meshes and
`shape3`. The stock program modulates vertex color by the bound texture. That
is tint, not framebuffer blending. Draw does not take a program. The surface
owns the stock pipeline.

The viewport, blend mode, and depth test live on the surface term and are
applied when clearing or drawing. View and projection matrices live on the
surface term and are applied when drawing. They are not read back from the
GPU. The default is depth test `enabled` and blend mode `none`. Overlapping
2D draws share Z and need `set_depth_test(Surface, disabled)`; transparent
2D also needs `set_blend_mode(Surface, alpha)`. View and projection are 4x4
matrices. A 2D view or camera matrix is 3x3; embed it with
`matrix3:to_matrix4/1`.

An empty surface is not allowed. Width and height must be at least 1.

Beware that a well-formed view matrix, projection matrix, and mesh always use
floats, not integers.

**OpenGL Internals**

A surface has its own OpenGL context. Use `gl_commands/2` to run OpenGL calls
while that context is current. Custom shaders are not a draw argument. Build
a `program`, take `program:gl_object/1`, and issue GL calls through
`gl_commands/2`.
""".

-behavior(worker).

-export_type([
    size/0,
    viewport/0,
    blend_mode/0,
    depth_test/0
]).
-export_type([
    object/0
]).
-export([
    with_size/2,
    with_window/3,
    destroy/1,
    size/1,
    resize/2
]).
-export([
    viewport/1,
    set_viewport/2,
    view_matrix/1,
    set_view_matrix/2,
    projection_matrix/1,
    set_projection_matrix/2,
    blend_mode/1,
    set_blend_mode/2,
    depth_test/1,
    set_depth_test/2,
    clear/2,
    draw_mesh2/4, draw_mesh2/5, draw_mesh2/6,
    draw_mesh3/4, draw_mesh3/5, draw_mesh3/6,
    draw_shape2/2,
    draw_shape3/2
]).
-export([
    display/1,
    image/1
]).
-export([
    gl_commands/2
]).
-export([
    initialize/1,
    handle_request/3,
    handle_message/2,
    terminate/2
]).

-compile({inline, [
    size/1,
    viewport/1,
    view_matrix/1,
    projection_matrix/1,
    blend_mode/1,
    depth_test/1
]}).

-include_lib("beam_graphics/include/graphics.hrl").

-define(DESTROY_REQUEST, '$beam_graphics_destroy_surface').

-record(state, {
    display :: egl:display(),
    context :: egl:context(),
    surface :: {pbuffer | window, egl:surface()},
    config :: egl:config(),
    program :: program:object(),
    model_location :: integer(),
    view_location :: integer(),
    projection_location :: integer(),
    use_texture_location :: integer()
}).

-doc """
A surface size in pixels.

Width and height are at least 1.
""".
-type size() :: {
    Width :: pos_integer(),
    Height :: pos_integer()
}.

-doc """
A surface viewport.

`X` and `Y` are the lower-left corner in pixels. `Width` and `Height` are at
least 1.
""".
-type viewport() :: {
    X :: non_neg_integer(),
    Y :: non_neg_integer(),
    Width :: pos_integer(),
    Height :: pos_integer()
}.

-doc """
A surface blend mode.

`none` disables blending. `alpha` composites with the source alpha. `add`
adds the source, scaled by its alpha. `multiply` modulates with the color
already in the surface. Custom factors stay on the OpenGL escape hatch.
""".
-type blend_mode() :: none | alpha | add | multiply.

-doc """
A surface depth test.

`enabled` keeps closer fragments. `disabled` keeps the fragment last drawn.
""".
-type depth_test() :: enabled | disabled.

-doc """
A surface object.

It wraps a worker process, the size, the viewport, the view and projection
matrices, the blend mode, and the depth test.
""".
-opaque object() :: {
    WorkerId :: worker:id(),
    Size :: size(),
    Viewport :: viewport(),
    ViewMatrix :: graphics:matrix4(),
    ProjectionMatrix :: graphics:matrix4(),
    BlendMode :: blend_mode(),
    DepthTest :: depth_test()
}.

-doc """
A pbuffer surface of a given size.

It constructs a pbuffer surface of the given size. The view matrix is
identity. The projection matrix is an orthographic projection of the size.
The viewport is the full size. The blend mode is `none`. The depth test is
`enabled`.

A running graphics context is required. The calling process is linked to the
surface worker.

Width and height must be at least 1. It returns `out_of_memory` when the GPU
cannot allocate the default program. Other constructor failures are
`{aborted, term()}`, `timeout`, or `{error, term()}`.
""".
-spec with_size(egl:display(), size()) ->
    {ok, object()} |
    out_of_memory |
    {aborted, term()} |
    timeout |
    {error, term()}
.
with_size(Display, {Width, Height}) when Width > 0, Height > 0 ->
    spawn_surface(Display, no_window, Width, Height).

-doc """
A window surface of a given size.

It constructs a surface attached to the given native window. The view matrix
is identity. The projection matrix is an orthographic projection of the size.
The viewport is the full size. The blend mode is `none`. The depth test is
`enabled`.

`Window` is an EGL native window handle. A running graphics context is
required. The calling process is linked to the surface worker.

Width and height must be at least 1. `Size` should match the window
framebuffer. It returns `out_of_memory` when the GPU cannot allocate the
default program. Other constructor failures are `{aborted, term()}`,
`timeout`, or `{error, term()}`.
""".
-spec with_window(egl:display(), term(), size()) ->
    {ok, object()} |
    out_of_memory |
    {aborted, term()} |
    timeout |
    {error, term()}
.
with_window(Display, Window, {Width, Height}) when Width > 0, Height > 0 ->
    spawn_surface(Display, Window, Width, Height).

-doc """
Destroy a surface.

It stops the worker and releases the EGL surface, the OpenGL context, and the
default program. Using the surface after it is destroyed has undefined
behavior. Destroying the same surface twice is invalid.
""".
-spec destroy(object()) -> ok.
destroy({WorkerId, _Size, _Viewport, _View, _Projection, _Blend, _Depth}) ->
    {reply, ok} = surface_request(WorkerId, ?DESTROY_REQUEST),
    ok.

-doc """
The size of a surface.

It returns the width and height currently stored in the surface.
""".
-spec size(object()) -> size().
size({_WorkerId, Size, _Viewport, _View, _Projection, _Blend, _Depth}) ->
    Size.

-doc """
Resize a surface.

It sets the size stored on the surface. The viewport is reset to the full new
size. The view and projection matrices, the blend mode, and the depth test
are unchanged.

On a pbuffer, the EGL pbuffer is recreated. On a window, the drawable is not
changed; the window owns that size.

Width and height must be at least 1. It returns `out_of_memory` when the GPU
cannot allocate the new pbuffer.
""".
-spec resize(object(), size()) -> {ok, object()} | out_of_memory.
resize(
    {WorkerId, _Size, _Viewport, ViewMatrix, ProjectionMatrix, BlendMode, DepthTest},
    {Width, Height} = Size
) when Width > 0, Height > 0 ->
    {reply, Reply} = surface_request(WorkerId, {resize, Size}),
    case Reply of
        out_of_memory ->
            out_of_memory;
        ok ->
            {ok, {
                WorkerId,
                Size,
                {0, 0, Width, Height},
                ViewMatrix,
                ProjectionMatrix,
                BlendMode,
                DepthTest
            }}
    end.

-doc """
The viewport of a surface.

It returns the viewport last set on the surface.
""".
-spec viewport(object()) -> viewport().
viewport({_WorkerId, _Size, Viewport, _View, _Projection, _Blend, _Depth}) ->
    Viewport.

-doc """
Set the viewport of a surface.

It sets the viewport stored on the surface. The viewport is applied when
clearing or drawing.
""".
-spec set_viewport(object(), viewport()) -> {ok, object()}.
set_viewport(Surface, {X, Y, Width, Height} = Viewport)
        when X >= 0, Y >= 0, Width > 0, Height > 0 ->
    {ok, erlang:setelement(3, Surface, Viewport)}.

-doc """
The view matrix of a surface.

It returns the view matrix last set on the surface.
""".
-spec view_matrix(object()) -> graphics:matrix4().
view_matrix({_WorkerId, _Size, _Viewport, ViewMatrix, _Projection, _Blend, _Depth}) ->
    ViewMatrix.

-doc """
Set the view matrix of a surface.

It sets the view matrix stored on the surface. The matrix is applied when
drawing.
""".
-spec set_view_matrix(object(), graphics:matrix4()) -> {ok, object()}.
set_view_matrix(Surface, Matrix) ->
    {ok, erlang:setelement(4, Surface, Matrix)}.

-doc """
The projection matrix of a surface.

It returns the projection matrix last set on the surface.
""".
-spec projection_matrix(object()) -> graphics:matrix4().
projection_matrix({_WorkerId, _Size, _Viewport, _View, ProjectionMatrix, _Blend, _Depth}) ->
    ProjectionMatrix.

-doc """
Set the projection matrix of a surface.

It sets the projection matrix stored on the surface. The matrix is applied
when drawing.
""".
-spec set_projection_matrix(object(), graphics:matrix4()) -> {ok, object()}.
set_projection_matrix(Surface, Matrix) ->
    {ok, erlang:setelement(5, Surface, Matrix)}.

-doc """
The blend mode of a surface.

It returns the blend mode last set on the surface.
""".
-spec blend_mode(object()) -> blend_mode().
blend_mode({_WorkerId, _Size, _Viewport, _View, _Projection, BlendMode, _Depth}) ->
    BlendMode.

-doc """
Set the blend mode of a surface.

It sets the blend mode stored on the surface. The mode is applied when
clearing or drawing. Clearing writes the clear color directly; blending does
not affect `clear/2`.
""".
-spec set_blend_mode(object(), blend_mode()) -> {ok, object()}.
set_blend_mode(Surface, BlendMode)
        when BlendMode =:= none; BlendMode =:= alpha;
             BlendMode =:= add; BlendMode =:= multiply ->
    {ok, erlang:setelement(6, Surface, BlendMode)}.

-doc """
The depth test of a surface.

It returns the depth test last set on the surface.
""".
-spec depth_test(object()) -> depth_test().
depth_test({_WorkerId, _Size, _Viewport, _View, _Projection, _Blend, DepthTest}) ->
    DepthTest.

-doc """
Set the depth test of a surface.

It sets the depth test stored on the surface. The policy is applied when
clearing or drawing.
""".
-spec set_depth_test(object(), depth_test()) -> {ok, object()}.
set_depth_test(Surface, DepthTest)
        when DepthTest =:= enabled; DepthTest =:= disabled ->
    {ok, erlang:setelement(7, Surface, DepthTest)}.

-doc """
Clear a surface.

It fills the surface with the given color and resets the depth buffer.
""".
-spec clear(object(), graphics:color()) -> ok.
clear({WorkerId, _Size, Viewport, _View, _Projection, BlendMode, DepthTest}, Color) ->
    {reply, ok} = surface_request(
        WorkerId, {clear, Viewport, Color, BlendMode, DepthTest}
    ),
    ok.

-doc """
Draw a 2D mesh on a surface.

It draws the given 2D mesh with the given primitive type and vertex count.
There is no texture. The model matrix is the identity.

It's equivalent to `draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, no_texture)`.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count()
) -> ok.
draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount) ->
    draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
Draw a 2D mesh on a surface with a texture.

It draws the given 2D mesh with the given primitive type, vertex count, and
texture. The model matrix is the identity.

It's equivalent to `draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, Texture, matrix3:identity())`.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) -> ok.
draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, Texture) ->
    draw_mesh2(
        Surface, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX3_IDENTITY
    ).

-doc """
Draw a 2D mesh on a surface with a texture and a model matrix.

It draws the given 2D mesh with the given primitive type, vertex count,
texture, and 3x3 model matrix.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture(),
    graphics:matrix3()
) -> ok.
draw_mesh2(
    {WorkerId, _Size, Viewport, ViewMatrix, ProjectionMatrix, BlendMode, DepthTest},
    Mesh,
    PrimitiveType,
    VertexCount,
    Texture,
    Matrix3
) ->
    Buffer = mesh2:gl_object(Mesh),
    Request = {
        draw,
        Viewport,
        ViewMatrix,
        ProjectionMatrix,
        {mesh2, Buffer},
        PrimitiveType,
        VertexCount,
        Texture,
        matrix3:to_matrix4(Matrix3),
        BlendMode,
        DepthTest
    },
    {reply, ok} = surface_request(WorkerId, Request),
    ok.

-doc """
Draw a 3D mesh on a surface.

It draws the given 3D mesh with the given primitive type and vertex count.
There is no texture. The model matrix is the identity.

It's equivalent to `draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, no_texture)`.
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
Draw a 3D mesh on a surface with a texture.

It draws the given 3D mesh with the given primitive type, vertex count, and
texture. The model matrix is the identity.

It's equivalent to `draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, Texture, matrix4:identity())`.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) -> ok.
draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, Texture) ->
    draw_mesh3(
        Surface, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX4_IDENTITY
    ).

-doc """
Draw a 3D mesh on a surface with a texture and a model matrix.

It draws the given 3D mesh with the given primitive type, vertex count,
texture, and 4x4 model matrix.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture(),
    graphics:matrix4()
) -> ok.
draw_mesh3(
    {WorkerId, _Size, Viewport, ViewMatrix, ProjectionMatrix, BlendMode, DepthTest},
    Mesh,
    PrimitiveType,
    VertexCount,
    Texture,
    Matrix
) ->
    Buffer = mesh3:gl_object(Mesh),
    Request = {
        draw,
        Viewport,
        ViewMatrix,
        ProjectionMatrix,
        {mesh3, Buffer},
        PrimitiveType,
        VertexCount,
        Texture,
        Matrix,
        BlendMode,
        DepthTest
    },
    {reply, ok} = surface_request(WorkerId, Request),
    ok.

-doc """
Draw a 2D shape on a surface.

It draws each mesh of the 2D shape with the shape texture and the shape model
matrix.
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
    lists:foreach(fun({Mesh, PrimitiveType, VertexCount}) ->
        draw_mesh2(Surface, Mesh, PrimitiveType, VertexCount, Texture, Matrix)
    end, Meshes).

-doc """
Draw a 3D shape on a surface.

It draws each mesh of the 3D shape with the shape texture and the shape model
matrix.
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
    lists:foreach(fun({Mesh, PrimitiveType, VertexCount}) ->
        draw_mesh3(Surface, Mesh, PrimitiveType, VertexCount, Texture, Matrix)
    end, Meshes).

-doc """
Display a surface.

It presents the surface. On a window, the back buffer becomes visible.
""".
-spec display(object()) -> ok.
display({WorkerId, _Size, _Viewport, _View, _Projection, _Blend, _Depth}) ->
    {reply, ok} = surface_request(WorkerId, display),
    ok.

-doc """
The image of a surface.

It reads the pixels of the current drawable. This is the buffer that was just
drawn to, not the presented front buffer of a window after `display/1`.

Pixels are row-major, X varies fastest, then Y. Slice index `(0, 0)` is the
first pixel. OpenGL `read_pixels` origin is the lower-left corner. Surface
does not flip the image.
""".
-spec image(object()) -> graphics:image().
image({WorkerId, {Width, Height}, _Viewport, _View, _Projection, _Blend, _Depth}) ->
    {reply, Data} = surface_request(WorkerId, {raw_pixels, Width, Height}),
    {Width, Height, data_to_pixels(Data)}.

-doc """
Run OpenGL commands on a surface.

It runs the given function on the surface worker. The OpenGL context is
current. The return value is the function's return value. Custom shaders
use this path with `program:gl_object/1`.

If the function raises, it returns `{error, {exception, Class, Reason}}` and
the surface stays running.
""".
-spec gl_commands(object(), fun(() -> term())) -> term().
gl_commands({WorkerId, _Size, _Viewport, _View, _Projection, _Blend, _Depth}, Commands) ->
    {reply, Reply} = surface_request(WorkerId, {gl_commands, Commands}),
    Reply.

-doc false.
initialize([Display, Window, Width, Height]) ->
    process_flag(trap_exit, true),
    SurfaceType = case Window of
        no_window ->
            pbuffer;
        _ ->
            window
    end,
    case egl:bind_api(opengl_api) of
        not_ok ->
            {abort, not_ok};
        ok ->
            case choose_egl_config(Display, SurfaceType) of
                {error, Reason} ->
                    {abort, Reason};
                {ok, Config} ->
                    create_gl_context(
                        Display, Config, Window, Width, Height, SurfaceType
                    )
            end
    end.

-doc false.
handle_request(
    {resize, {Width, Height}},
    _From,
    #state{
        display = Display,
        context = Context,
        surface = {pbuffer, Surface},
        config = Config
    } = State
) ->
    SurfaceAttribs = [{width, Width}, {height, Height}],
    case egl:create_pbuffer_surface(Display, Config, SurfaceAttribs) of
        not_ok ->
            {reply, out_of_memory, State};
        {ok, NewSurface} ->
            case egl:make_current(Display, NewSurface, NewSurface, Context) of
                not_ok ->
                    _ = egl:destroy_surface(Display, NewSurface),
                    {reply, out_of_memory, State};
                ok ->
                    _ = egl:destroy_surface(Display, Surface),
                    {reply, ok, State#state{
                        surface = {pbuffer, NewSurface}
                    }}
            end
    end;

handle_request({resize, _Size}, _From, #state{surface = {window, _}} = State) ->
    {reply, ok, State};

handle_request(
    {clear, Viewport, {Red, Green, Blue, Alpha}, BlendMode, DepthTest},
    _From,
    State
) ->
    {X, Y, Width, Height} = Viewport,
    ok = gl:viewport(X, Y, Width, Height),
    ok = apply_pipeline(BlendMode, DepthTest),
    ok = gl:clear_color(Red, Green, Blue, Alpha),
    ok = gl:clear([color_buffer_bit, depth_buffer_bit]),
    {reply, ok, State};

handle_request(
    {draw, Viewport, ViewMatrix, ProjectionMatrix, Mesh, PrimitiveType,
     VertexCount, Texture, ModelMatrix, BlendMode, DepthTest},
    _From,
    #state{
        program = Program,
        model_location = ModelLocation,
        view_location = ViewLocation,
        projection_location = ProjectionLocation,
        use_texture_location = UseTextureLocation
    } = State
) ->
    GlProgram = program:gl_object(Program),
    {X, Y, Width, Height} = Viewport,
    ok = gl:viewport(X, Y, Width, Height),
    ok = apply_pipeline(BlendMode, DepthTest),
    ok = gl:use_program(GlProgram),
    ok = gl:active_texture(texture0),
    ok = gl:program_uniform_matrix(
        f, GlProgram, ModelLocation, matrix4:columns(ModelMatrix)
    ),
    ok = gl:program_uniform_matrix(
        f, GlProgram, ViewLocation, matrix4:columns(ViewMatrix)
    ),
    ok = gl:program_uniform_matrix(
        f, GlProgram, ProjectionLocation, matrix4:columns(ProjectionMatrix)
    ),
    UseTexture = case Texture of
        no_texture ->
            0;
        _ ->
            1
    end,
    ok = gl:program_uniform(i, GlProgram, UseTextureLocation, UseTexture),

    {ok, [VertexArray]} = gl:gen_vertex_arrays(1),
    gl:bind_vertex_array(VertexArray),
    bind_mesh(Mesh),
    case Texture of
        no_texture ->
            ok;
        _ ->
            GlTexture = texture:gl_object(Texture),
            ok = gl:bind_texture(texture_2d, GlTexture)
    end,
    ok = gl:draw_arrays(PrimitiveType, 0, VertexCount),
    case Texture of
        no_texture ->
            ok;
        _ ->
            ok = gl:bind_texture(texture_2d, none)
    end,
    ok = gl:bind_vertex_array(none),
    ok = gl:delete_vertex_arrays([VertexArray]),
    {reply, ok, State};

handle_request(
    display,
    _From,
    #state{
        display = Display,
        surface = {_, Surface}
    } = State
) ->
    ok = egl:swap_buffers(Display, Surface),
    {reply, ok, State};

handle_request({raw_pixels, Width, Height}, _From, State) ->
    {ok, Data} = gl:read_pixels(
        0, 0, Width, Height, rgba, unsigned_byte, Width * Height * 4
    ),
    {reply, Data, State};

handle_request({gl_commands, Commands}, _From, State) ->
    Reply = try Commands() of
        Result ->
            Result
    catch
        Class:Reason:_Stack ->
            {error, {exception, Class, Reason}}
    end,
    {reply, Reply, State};

handle_request(?DESTROY_REQUEST, _From, State) ->
    {stop, requested, ok, State}.

-doc false.
handle_message({'EXIT', _Pid, Reason}, State) ->
    {stop, Reason, State};
handle_message(_Message, State) ->
    {continue, State}.

-doc false.
terminate(_Reason, #state{
    display = Display,
    context = Context,
    surface = {_, Surface},
    program = Program
}) ->
    try
        ok = program:destroy(Program)
    catch
        _Class:_DestroyReason:_Stack ->
            ok
    end,
    _ = egl:destroy_surface(Display, Surface),
    _ = egl:destroy_context(Display, Context),
    ok.

spawn_surface(Display, Window, Width, Height) ->
    case worker:spawn(link, ?MODULE, [Display, Window, Width, Height]) of
        {ok, WorkerId} ->
            {ok, {
                WorkerId,
                {Width, Height},
                {0, 0, Width, Height},
                ?MATRIX4_IDENTITY,
                default_projection_matrix(Width, Height),
                none,
                enabled
            }};
        {aborted, out_of_memory} ->
            out_of_memory;
        {aborted, {compile_error, _, _} = Error} ->
            error(Error);
        {aborted, {link_error, _} = Error} ->
            error(Error);
        Other ->
            Other
    end.

surface_request(WorkerId, Request) ->
    Monitor = erlang:monitor(process, WorkerId),
    RequestId = erlang:timestamp(),
    WorkerId ! {'$worker_request', {self(), RequestId}, Request},
    receive
        {reply, RequestId, Reply} ->
            erlang:demonitor(Monitor, [flush]),
            {reply, Reply};
        {'DOWN', Monitor, process, WorkerId, _Reason} ->
            error(noproc)
    end.

create_gl_context(Display, Config, Window, Width, Height, SurfaceType) ->
    ContextAttribs = [
        {context_major_version, 4},
        {context_minor_version, 6}
    ],
    ShareContext = graphics_context:inner_context(),
    case egl:create_context(Display, Config, ShareContext, ContextAttribs) of
        not_ok ->
            {abort, not_ok};
        {ok, Context} ->
            case create_egl_surface(
                Display, Config, Window, Width, Height, SurfaceType
            ) of
                not_ok ->
                    _ = egl:destroy_context(Display, Context),
                    {abort, not_ok};
                {ok, EglSurface} ->
                    case egl:make_current(
                        Display, EglSurface, EglSurface, Context
                    ) of
                        not_ok ->
                            _ = egl:destroy_surface(Display, EglSurface),
                            _ = egl:destroy_context(Display, Context),
                            {abort, not_ok};
                        ok ->
                            _ = gl:glad_load_gl(),
                            finish_initialize(
                                Display, Config, Context, SurfaceType, EglSurface
                            )
                    end
            end
    end.

create_egl_surface(Display, Config, _Window, Width, Height, pbuffer) ->
    egl:create_pbuffer_surface(
        Display, Config, [{width, Width}, {height, Height}]
    );
create_egl_surface(Display, Config, Window, _Width, _Height, window) ->
    egl:create_window_surface(Display, Config, Window, []).

finish_initialize(Display, Config, Context, SurfaceType, EglSurface) ->
    case default_program:new() of
        out_of_memory ->
            destroy_egl(Display, Context, EglSurface),
            {abort, out_of_memory};
        {compile_error, _, _} = Error ->
            destroy_egl(Display, Context, EglSurface),
            {abort, Error};
        {link_error, _} = Error ->
            destroy_egl(Display, Context, EglSurface),
            {abort, Error};
        {ok, Program} ->
            GlProgram = program:gl_object(Program),
            ok = gl:use_program(GlProgram),
            {ok, ModelLocation} = gl:get_uniform_location(GlProgram, "uModel"),
            {ok, ViewLocation} = gl:get_uniform_location(GlProgram, "uView"),
            {ok, ProjectionLocation} =
                gl:get_uniform_location(GlProgram, "uProjection"),
            {ok, UseTextureLocation} =
                gl:get_uniform_location(GlProgram, "uUseTexture"),
            {ok, TextureLocation} =
                gl:get_uniform_location(GlProgram, "uTexture"),
            ok = gl:program_uniform(i, GlProgram, TextureLocation, 0),
            ok = gl:active_texture(texture0),
            ok = gl:enable(depth_test),
            ok = gl:disable(blend),
            ok = gl:front_face(ccw),
            {continue, #state{
                display = Display,
                context = Context,
                surface = {SurfaceType, EglSurface},
                config = Config,
                program = Program,
                model_location = ModelLocation,
                view_location = ViewLocation,
                projection_location = ProjectionLocation,
                use_texture_location = UseTextureLocation
            }}
    end.

choose_egl_config(Display, SurfaceType) ->
    SurfaceBit = case SurfaceType of
        pbuffer ->
            pbuffer_bit;
        window ->
            window_bit
    end,
    ConfigAttribs = [
        {surface_type, [SurfaceBit]},
        {renderable_type, [opengl_bit]},
        {red_size, 8},
        {green_size, 8},
        {blue_size, 8},
        {alpha_size, 8},
        {depth_size, 24}
    ],
    case egl:choose_config(Display, ConfigAttribs) of
        not_ok ->
            {error, not_ok};
        {ok, []} ->
            {error, no_config};
        {ok, [Config | _]} ->
            {ok, Config}
    end.

destroy_egl(Display, Context, EglSurface) ->
    _ = egl:destroy_surface(Display, EglSurface),
    _ = egl:destroy_context(Display, Context),
    ok.

bind_mesh({mesh2, Buffer}) ->
    gl:bind_vertex_buffer(0, Buffer, 0, 4 * (2 + 4 + 2)),
    gl:vertex_attrib_format(0, 2, float, false, 0),
    gl:vertex_attrib_binding(0, 0),
    gl:enable_vertex_attrib_array(0),
    gl:vertex_attrib_format(1, 4, float, false, 2 * 4),
    gl:vertex_attrib_binding(1, 0),
    gl:enable_vertex_attrib_array(1),
    gl:vertex_attrib_format(2, 2, float, false, (2 + 4) * 4),
    gl:vertex_attrib_binding(2, 0),
    gl:enable_vertex_attrib_array(2);
bind_mesh({mesh3, Buffer}) ->
    gl:bind_vertex_buffer(0, Buffer, 0, 4 * (3 + 4 + 2)),
    gl:vertex_attrib_format(0, 3, float, false, 0),
    gl:vertex_attrib_binding(0, 0),
    gl:enable_vertex_attrib_array(0),
    gl:vertex_attrib_format(1, 4, float, false, 3 * 4),
    gl:vertex_attrib_binding(1, 0),
    gl:enable_vertex_attrib_array(1),
    gl:vertex_attrib_format(2, 2, float, false, (3 + 4) * 4),
    gl:vertex_attrib_binding(2, 0),
    gl:enable_vertex_attrib_array(2).

apply_pipeline(BlendMode, DepthTest) ->
    case DepthTest of
        enabled ->
            ok = gl:enable(depth_test);
        disabled ->
            ok = gl:disable(depth_test)
    end,
    case BlendMode of
        none ->
            ok = gl:disable(blend);
        alpha ->
            ok = gl:enable(blend),
            ok = gl:blend_func(src_alpha, one_minus_src_alpha);
        add ->
            ok = gl:enable(blend),
            ok = gl:blend_func(src_alpha, one);
        multiply ->
            ok = gl:enable(blend),
            ok = gl:blend_func(dst_color, zero)
    end.

default_projection_matrix(Width, Height) ->
    view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).

byte_to_channel(Byte) ->
    Byte / 255.0.

data_to_pixels(Data) ->
    data_to_pixels(Data, []).

data_to_pixels(<<>>, Pixels) ->
    lists:reverse(Pixels);
data_to_pixels(<<R:8, G:8, B:8, A:8, DataRest/binary>>, Pixels) ->
    Color = {
        byte_to_channel(R),
        byte_to_channel(G),
        byte_to_channel(B),
        byte_to_channel(A)
    },
    data_to_pixels(DataRest, [Color | Pixels]).
