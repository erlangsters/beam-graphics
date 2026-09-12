%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(frame).
-moduledoc """
Frame

A frame is an offscreen 2D image that is typically used as a render target.

A frame is an opaque object that wraps a GPU framebuffer, a color texture, and
a hidden depth buffer. It is created with the `with_size` function and disposed
with the `destroy/1` function. Copying the term does not copy the GPU objects.

A frame is not a surface. A surface presents to a window or a pbuffer. A frame
is sampled later as a texture, with no presentation and no CPU round-trip.
`texture/1` returns the color texture owned by the frame. Destroying the frame
destroys that texture. Do not destroy the texture independently. Using the
texture after the frame is destroyed has undefined behavior.

```erlang
{ok, Frame} = frame:with_size({640, 480}),
ok = frame:clear(Frame, ?COLOR_BLACK),
ok = frame:draw_mesh2(Frame, Mesh, triangles, 3),
Texture = frame:texture(Frame),
ok = surface:draw_mesh2(Surface, Quad, triangle_fan, 4, Texture),
ok = frame:destroy(Frame).
```

Drawing a mesh with `frame:texture(Frame)` as the texture argument while that
frame is the draw target is undefined.

Meshes are drawn on a frame with a primitive type and an optional texture. The
primitive type and the texture are not part of the mesh; they are arguments of
`draw_mesh2/4` and of `shape2`. The same holds for 3D meshes and `shape3`.

View and projection matrices and the viewport live on the frame term and are
applied when clearing or drawing. They are not read back from the GPU.

An empty frame is not allowed. Width and height must be at least 1.

Beware that a well-formed view matrix, projection matrix, and mesh always use
floats, not integers.

**OpenGL Internals**

A frame wraps an OpenGL framebuffer object, a color texture attachment, and a
depth renderbuffer that is not exposed. Use `gl_object/1` to retrieve the
framebuffer id. The color texture id is `texture:gl_object(frame:texture(Frame))`.
""".

-export_type([
    size/0,
    viewport/0
]).
-export_type([
    object/0
]).
-export([
    with_size/1,
    destroy/1,
    size/1,
    resize/2,
    texture/1,
    gl_object/1
]).
-export([
    viewport/1,
    set_viewport/2,
    view_matrix/1,
    set_view_matrix/2,
    projection_matrix/1,
    set_projection_matrix/2,
    clear/2,
    draw_mesh2/4, draw_mesh2/5, draw_mesh2/6,
    draw_mesh3/4, draw_mesh3/5, draw_mesh3/6,
    draw_shape2/2,
    draw_shape3/2
]).

-compile({inline, [
    size/1,
    texture/1,
    gl_object/1,
    viewport/1,
    view_matrix/1,
    projection_matrix/1
]}).

-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

-doc """
A frame size in pixels.

Width and height are at least 1.
""".
-type size() :: {
    Width :: pos_integer(),
    Height :: pos_integer()
}.

-doc """
A frame viewport.

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
A frame object.

It wraps an OpenGL framebuffer id, a depth renderbuffer id, the size, the
owned color texture, the default program used to draw, the viewport, and the
view and projection matrices.
""".
-opaque object() :: {
    ResourceId :: {frame, gl:framebuffer(), gl:renderbuffer()},
    Size :: size(),
    Texture :: graphics:texture(),
    Program :: program:object(),
    Viewport :: viewport(),
    ViewMatrix :: graphics:matrix4(),
    ProjectionMatrix :: graphics:matrix4()
}.

-doc """
A frame of a given size.

It constructs a frame of the given size. The color texture uses the `linear`
color space and no local copy is kept. The view matrix is identity. The
projection matrix is an orthographic projection of the size. The viewport is
the full size.

Width and height must be at least 1. It returns `out_of_memory` when the GPU
cannot allocate the framebuffer, the color texture, or the default program.
""".
-spec with_size(size()) -> {ok, object()} | out_of_memory.
with_size({Width, Height}) when Width > 0, Height > 0 ->
    case texture:with_color(?COLOR_BLACK, {Width, Height}) of
        out_of_memory ->
            out_of_memory;
        {ok, Texture} ->
            GlTexture = texture:gl_object(Texture),
            case acquire_frame(Width, Height, GlTexture) of
                {error, out_of_memory} ->
                    ok = texture:destroy(Texture),
                    out_of_memory;
                {ok, ResourceId} ->
                    case default_program:new() of
                        {ok, Program} ->
                            Frame = {
                                ResourceId,
                                {Width, Height},
                                Texture,
                                Program,
                                {0, 0, Width, Height},
                                ?MATRIX4_IDENTITY,
                                default_projection_matrix(Width, Height)
                            },
                            {ok, Frame};
                        Error ->
                            ok = release_frame(ResourceId),
                            ok = texture:destroy(Texture),
                            case Error of
                                out_of_memory ->
                                    out_of_memory;
                                {compile_error, _, _} ->
                                    error(Error);
                                {link_error, _} ->
                                    error(Error)
                            end
                    end
            end
    end.

-doc """
Destroy a frame.

It releases the GPU framebuffer, the depth renderbuffer, the owned color
texture, and the default program. Using the frame or its color texture after
it is destroyed has undefined behavior. Destroying the same frame twice is
invalid.
""".
-spec destroy(object()) -> ok.
destroy({ResourceId, _Size, Texture, Program, _Viewport, _View, _Projection}) ->
    ok = release_frame(ResourceId),
    ok = texture:destroy(Texture),
    ok = program:destroy(Program),
    ok.

-doc """
The size of a frame.

It returns the width and height currently stored in the frame.
""".
-spec size(object()) -> size().
size({_ResourceId, Size, _Texture, _Program, _Viewport, _View, _Projection}) ->
    Size.

-doc """
Resize a frame.

It reallocates the color texture and the depth buffer to the given size. The
framebuffer id and the texture id are unchanged. Existing pixels are discarded
and the color texture is filled with black. The viewport is reset to the full
new size. The view and projection matrices are unchanged.

Width and height must be at least 1. It returns `out_of_memory` when the GPU
cannot allocate the new data store.
""".
-spec resize(object(), size()) -> {ok, object()} | out_of_memory.
resize(
    {ResourceId, _Size, Texture, Program, _Viewport, ViewMatrix, ProjectionMatrix},
    {Width, Height} = Size
) when Width > 0, Height > 0 ->
    case texture:resize(Texture, Size) of
        out_of_memory ->
            out_of_memory;
        {ok, NewTexture} ->
            GlTexture = texture:gl_object(NewTexture),
            case resize_depth(ResourceId, GlTexture, Width, Height) of
                out_of_memory ->
                    out_of_memory;
                ok ->
                    NewFrame = {
                        ResourceId,
                        Size,
                        NewTexture,
                        Program,
                        {0, 0, Width, Height},
                        ViewMatrix,
                        ProjectionMatrix
                    },
                    {ok, NewFrame}
            end
    end.

-doc """
The color texture of a frame.

It returns the color texture owned by the frame. The texture is destroyed with
the frame. Do not destroy it independently.
""".
-spec texture(object()) -> graphics:texture().
texture({_ResourceId, _Size, Texture, _Program, _Viewport, _View, _Projection}) ->
    Texture.

-doc """
The OpenGL framebuffer of a frame.

It returns the OpenGL framebuffer id wrapped by the frame.
""".
-spec gl_object(object()) -> gl:framebuffer().
gl_object({{frame, Framebuffer, _Renderbuffer}, _Size, _Texture, _Program, _Viewport, _View, _Projection}) ->
    Framebuffer.

-doc """
The viewport of a frame.

It returns the viewport last set on the frame.
""".
-spec viewport(object()) -> viewport().
viewport({_ResourceId, _Size, _Texture, _Program, Viewport, _View, _Projection}) ->
    Viewport.

-doc """
Set the viewport of a frame.

It sets the viewport stored on the frame. The viewport is applied when
clearing or drawing.
""".
-spec set_viewport(object(), viewport()) -> {ok, object()}.
set_viewport(Frame, {X, Y, Width, Height} = Viewport)
        when X >= 0, Y >= 0, Width > 0, Height > 0 ->
    {ok, erlang:setelement(5, Frame, Viewport)}.

-doc """
The view matrix of a frame.

It returns the view matrix last set on the frame.
""".
-spec view_matrix(object()) -> graphics:matrix4().
view_matrix({_ResourceId, _Size, _Texture, _Program, _Viewport, ViewMatrix, _Projection}) ->
    ViewMatrix.

-doc """
Set the view matrix of a frame.

It sets the view matrix stored on the frame. The matrix is applied when
drawing.
""".
-spec set_view_matrix(object(), graphics:matrix4()) -> {ok, object()}.
set_view_matrix(Frame, Matrix) ->
    {ok, erlang:setelement(6, Frame, Matrix)}.

-doc """
The projection matrix of a frame.

It returns the projection matrix last set on the frame.
""".
-spec projection_matrix(object()) -> graphics:matrix4().
projection_matrix({_ResourceId, _Size, _Texture, _Program, _Viewport, _View, ProjectionMatrix}) ->
    ProjectionMatrix.

-doc """
Set the projection matrix of a frame.

It sets the projection matrix stored on the frame. The matrix is applied when
drawing.
""".
-spec set_projection_matrix(object(), graphics:matrix4()) -> {ok, object()}.
set_projection_matrix(Frame, Matrix) ->
    {ok, erlang:setelement(7, Frame, Matrix)}.

-doc """
Clear a frame.

It fills the color texture with the given color and resets the depth buffer.
""".
-spec clear(object(), graphics:color()) -> ok.
clear(
    {{frame, Framebuffer, _Renderbuffer}, _Size, _Texture, _Program, Viewport, _View, _Projection},
    {Red, Green, Blue, Alpha}
) ->
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_framebuffer(framebuffer, Framebuffer),
        {X, Y, Width, Height} = Viewport,
        ok = gl:viewport(X, Y, Width, Height),
        ok = gl:enable(depth_test),
        ok = gl:clear_color(Red, Green, Blue, Alpha),
        ok = gl:clear([color_buffer_bit, depth_buffer_bit]),
        ok = gl:bind_framebuffer(framebuffer, 0),
        ok
    end),
    ok.

-doc """
Draw a 2D mesh on a frame.

It draws the given 2D mesh with the given primitive type and vertex count.
There is no texture. The model matrix is the identity.

It's equivalent to `draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, no_texture)`.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count()
) -> ok.
draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount) ->
    draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
Draw a 2D mesh on a frame with a texture.

It draws the given 2D mesh with the given primitive type, vertex count, and
texture. The model matrix is the identity.

It's equivalent to `draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, Texture, matrix3:identity())`.
""".
-spec draw_mesh2(
    object(),
    graphics:mesh2(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) -> ok.
draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, Texture) ->
    draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX3_IDENTITY).

-doc """
Draw a 2D mesh on a frame with a texture and a model matrix.

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
    {
        {frame, Framebuffer, _Renderbuffer},
        _Size,
        _ColorTexture,
        Program,
        Viewport,
        ViewMatrix,
        ProjectionMatrix
    },
    Mesh,
    PrimitiveType,
    VertexCount,
    Texture,
    Matrix3
) ->
    Buffer = mesh2:gl_object(Mesh),
    ok = program:set_uniform(Program, "uModel", matrix3:to_matrix4(Matrix3)),
    ok = program:set_uniform(Program, "uView", ViewMatrix),
    ok = program:set_uniform(Program, "uProjection", ProjectionMatrix),
    ok = program:set_uniform(Program, "uUseTexture", Texture =/= no_texture),
    ok = frame_draw(
        Framebuffer,
        Viewport,
        program:gl_object(Program),
        {{mesh2, Buffer}, PrimitiveType, VertexCount, Texture}
    ),
    ok.

-doc """
Draw a 3D mesh on a frame.

It draws the given 3D mesh with the given primitive type and vertex count.
There is no texture. The model matrix is the identity.

It's equivalent to `draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, no_texture)`.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count()
) -> ok.
draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount) ->
    draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, no_texture).

-doc """
Draw a 3D mesh on a frame with a texture.

It draws the given 3D mesh with the given primitive type, vertex count, and
texture. The model matrix is the identity.

It's equivalent to `draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, Texture, matrix4:identity())`.
""".
-spec draw_mesh3(
    object(),
    graphics:mesh3(),
    graphics:primitive_type(),
    graphics:vertex_count(),
    no_texture | graphics:texture()
) -> ok.
draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, Texture) ->
    draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX4_IDENTITY).

-doc """
Draw a 3D mesh on a frame with a texture and a model matrix.

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
    {
        {frame, Framebuffer, _Renderbuffer},
        _Size,
        _ColorTexture,
        Program,
        Viewport,
        ViewMatrix,
        ProjectionMatrix
    },
    Mesh,
    PrimitiveType,
    VertexCount,
    Texture,
    Matrix
) ->
    Buffer = mesh3:gl_object(Mesh),
    ok = program:set_uniform(Program, "uModel", Matrix),
    ok = program:set_uniform(Program, "uView", ViewMatrix),
    ok = program:set_uniform(Program, "uProjection", ProjectionMatrix),
    ok = program:set_uniform(Program, "uUseTexture", Texture =/= no_texture),
    ok = frame_draw(
        Framebuffer,
        Viewport,
        program:gl_object(Program),
        {{mesh3, Buffer}, PrimitiveType, VertexCount, Texture}
    ),
    ok.

-doc """
Draw a 2D shape on a frame.

It draws each mesh of the 2D shape with the shape texture and the shape model
matrix.
""".
-spec draw_shape2(object(), graphics:shape2()) -> ok.
draw_shape2(
    Frame,
    #shape2{
        meshes = Meshes,
        texture = Texture,
        matrix = Matrix
    }
) ->
    lists:foreach(fun({Mesh, PrimitiveType, VertexCount}) ->
        draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, Texture, Matrix)
    end, Meshes).

-doc """
Draw a 3D shape on a frame.

It draws each mesh of the 3D shape with the shape texture and the shape model
matrix.
""".
-spec draw_shape3(object(), graphics:shape3()) -> ok.
draw_shape3(
    Frame,
    #shape3{
        meshes = Meshes,
        texture = Texture,
        matrix = Matrix
    }
) ->
    lists:foreach(fun({Mesh, PrimitiveType, VertexCount}) ->
        draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, Texture, Matrix)
    end, Meshes).

frame_draw(
    Framebuffer, Viewport, Program,
    {Mesh, PrimitiveType, VertexCount, Texture}
) ->
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_framebuffer(framebuffer, Framebuffer),
        {X, Y, Width, Height} = Viewport,
        ok = gl:viewport(X, Y, Width, Height),
        ok = gl:enable(depth_test),

        ok = gl:use_program(Program),
        ok = gl:active_texture(texture0),

        {ok, [VertexArray]} = gl:gen_vertex_arrays(1),
        gl:bind_vertex_array(VertexArray),

        case Mesh of
            {mesh2, Buffer} ->
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

            {mesh3, Buffer} ->
                gl:bind_vertex_buffer(0, Buffer, 0, 4 * (3 + 4 + 2)),

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
        ok = gl:bind_framebuffer(framebuffer, 0),
        ok
    end),
    ok.

default_projection_matrix(Width, Height) ->
    view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).

acquire_frame(Width, Height, GlTexture) ->
    ReleaseFun = fun({frame, Framebuffer, Renderbuffer}) ->
        ok = gl:bind_framebuffer(framebuffer, 0),
        ok = gl:bind_renderbuffer(renderbuffer, 0),
        ok = gl:delete_framebuffers([Framebuffer]),
        ok = gl:delete_renderbuffers([Renderbuffer]),
        ok
    end,
    AcquireFun = fun() ->
        {ok, [Framebuffer]} = gl:gen_framebuffers(1),
        {ok, [Renderbuffer]} = gl:gen_renderbuffers(1),
        ok = gl:bind_renderbuffer(renderbuffer, Renderbuffer),
        ok = gl:renderbuffer_storage(renderbuffer, depth_component24, Width, Height),
        case gl:get_error() of
            {ok, out_of_memory} ->
                ok = gl:bind_renderbuffer(renderbuffer, 0),
                ok = gl:delete_renderbuffers([Renderbuffer]),
                ok = gl:delete_framebuffers([Framebuffer]),
                {error, out_of_memory};
            {ok, no_error} ->
                ok = gl:bind_framebuffer(framebuffer, Framebuffer),
                ok = gl:framebuffer_texture(
                    framebuffer, color_attachment0, GlTexture, 0
                ),
                ok = gl:framebuffer_renderbuffer(
                    framebuffer, depth_attachment, renderbuffer, Renderbuffer
                ),
                ok = gl:draw_buffers([color_attachment0]),
                case gl:check_framebuffer_status(framebuffer) of
                    {ok, framebuffer_complete} ->
                        ok = gl:bind_framebuffer(framebuffer, 0),
                        ok = gl:bind_renderbuffer(renderbuffer, 0),
                        {ok, {frame, Framebuffer, Renderbuffer}, ReleaseFun};
                    _Status ->
                        ok = gl:bind_framebuffer(framebuffer, 0),
                        ok = gl:bind_renderbuffer(renderbuffer, 0),
                        ok = gl:delete_framebuffers([Framebuffer]),
                        ok = gl:delete_renderbuffers([Renderbuffer]),
                        {error, out_of_memory}
                end
        end
    end,
    graphics_context:acquire_resource(AcquireFun).

release_frame(ResourceId) ->
    graphics_context:release_resource(ResourceId).

resize_depth({frame, Framebuffer, Renderbuffer}, GlTexture, Width, Height) ->
    graphics_context:execute_commands(fun() ->
        ok = gl:bind_renderbuffer(renderbuffer, Renderbuffer),
        ok = gl:renderbuffer_storage(renderbuffer, depth_component24, Width, Height),
        case gl:get_error() of
            {ok, out_of_memory} ->
                ok = gl:bind_renderbuffer(renderbuffer, 0),
                out_of_memory;
            {ok, no_error} ->
                ok = gl:bind_framebuffer(framebuffer, Framebuffer),
                ok = gl:framebuffer_texture(
                    framebuffer, color_attachment0, GlTexture, 0
                ),
                ok = gl:framebuffer_renderbuffer(
                    framebuffer, depth_attachment, renderbuffer, Renderbuffer
                ),
                Status = gl:check_framebuffer_status(framebuffer),
                ok = gl:bind_framebuffer(framebuffer, 0),
                ok = gl:bind_renderbuffer(renderbuffer, 0),
                case Status of
                    {ok, framebuffer_complete} ->
                        ok;
                    _ ->
                        out_of_memory
                end
        end
    end).
