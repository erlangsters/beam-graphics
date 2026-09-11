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

To be written.
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
    size/1,
    % resize/2,
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
    texture/1
    % image/1
]).

-compile({inline, [
    size/1,
    viewport/1,
    set_viewport/2
]}).

-include_lib("gl/include/gl.hrl").
-include_lib("beam_graphics/include/graphics.hrl").

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

-doc """
To be written.

To be written.
""".
-opaque object() :: {
    ResourceId :: {frame, gl:framebuffer(), gl:texture()},
    Size :: size(),
    Program :: {program:objects(), {
        ModelLocation :: gl:int(),
        ViewLocation :: gl:int(),
        ProjectionLocation :: gl:int()
    }},
    Viewport :: viewport()
}.

-doc """
To be written.

To be written.
""".
-spec with_size(size()) -> {ok, object()} | out_of_memory.
with_size({Width, Height}) when Width > 0 andalso Height > 0 ->
    InternalFormat = rgba32f,
    case acquire_frame(Width, Height, InternalFormat) of
        {ok, ResourceId} ->
            {Program, Locations} = default_program:make(Width, Height),

            Frame = {
                ResourceId,
                {Width, Height},
                {Program, Locations},
                {0, 0, Width, Height}
            },
            {ok, Frame};
        {error, out_of_memory} ->
            out_of_memory
    end.

-doc """
To be written.

To be written.
""".
-spec size(object()) -> size().
size(Frame) ->
    erlang:element(2, Frame).

% -doc """
% To be written.

% To be written.
% """.
% -spec resize(object(), size()) -> {ok, object()} | out_of_memory.
% resize(
%     {{framebuffer, Buffer}, _, ViewMatrix, ProjectionMatrix, Viewport},
%     Size
% ) ->
%     % XXX: Handle when size is the same ?

%     ok = graphics_context:execute_commands(fun() ->
%         % XXX: To be implemented.
%         ok
%     end),
%     NewFrame = {
%         {framebuffer, Buffer},
%         Size,
%         ViewMatrix,
%         ProjectionMatrix,
%         Viewport
%     },
    % {ok, NewFrame}.

-doc """
To be written.

To be written.
""".
-spec view_matrix(object()) -> graphics:matrix4().
view_matrix({_, _, {Program, Locations}, _}) ->
    GlProgram = program:gl_object(Program),
    {_, ViewLocation, _} = Locations,
    Values = graphics_context:execute_commands(fun() ->
        gl:use_program(GlProgram),
        {ok, Values} = gl:get_uniform(f, GlProgram, ViewLocation, 16),
        Values
    end),
    erlang:list_to_tuple(Values).

-doc """
To be written.

To be written.
""".
-spec set_view_matrix(object(), graphics:matrix4()) -> ok.
set_view_matrix({_, _, {Program, Locations}, _}, Matrix) ->
    GlProgram = program:gl_object(Program),
    {_, ViewLocation, _} = Locations,
    GlMatrix = matrix4:columns(Matrix),
    graphics_context:execute_commands(fun() ->
        ok = gl:use_program(GlProgram),
        ok = gl:uniform_matrix(f, ViewLocation, GlMatrix),
        ok
    end).

-doc """
To be written.

To be written.
""".
-spec projection_matrix(object()) -> graphics:matrix4().
projection_matrix({_, _, {Program, Locations}, _}) ->
    GlProgram = program:gl_object(Program),
    {_, _, ProjectionLocation} = Locations,
    Values = graphics_context:execute_commands(fun() ->
        gl:use_program(GlProgram),
        {ok, Values} = gl:get_uniform(f, GlProgram, ProjectionLocation, 16),
        Values
    end),
    erlang:list_to_tuple(Values).

-doc """
To be written.

To be written.
""".
-spec set_projection_matrix(object(), graphics:matrix4()) -> ok.
set_projection_matrix({_, _, {Program, Locations}, _}, Matrix) ->
    GlProgram = program:gl_object(Program),
    {_, _, ProjectionLocation} = Locations,
    GlMatrix = matrix4:columns(Matrix),
    graphics_context:execute_commands(fun() ->
        ok = gl:use_program(GlProgram),
        ok = gl:uniform_matrix(f, ProjectionLocation, GlMatrix),
        ok
    end).

-doc """
To be written.

To be written.
""".
-spec viewport(object()) -> viewport().
viewport(Frame) ->
    erlang:element(5, Frame).

-doc """
To be written.

To be written.
""".
-spec set_viewport(object(), viewport()) -> ok.
set_viewport(Frame, Viewport) ->
    erlang:setelement(5, Frame, Viewport).

-doc """
To be written.

To be written.
""".
-spec clear(object(), graphics:color()) -> ok.
clear(
    {{frame, Framebuffer, _}, _, _, _}, 
    {Red, Green, Blue, Alpha}
) ->
    ok = graphics_context:execute_commands(fun() ->
        ok = gl:bind_framebuffer(framebuffer, Framebuffer),
        ok = gl:clear_color(Red, Green, Blue, Alpha),
        % ok = gl:clear([color_buffer_bit, depth_buffer_bit]),
        ok
    end),

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
draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount) ->
    % XXX: Minor optimization can be made here.
    draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, no_texture).

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
draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, Texture) ->
    % XXX: Minor optimization can be made here.
    draw_mesh2(Frame, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX3_IDENTITY).


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
draw_mesh2(
    {{frame, Framebuffer, _}, _, {Program, Locations}, Viewport},
    Mesh, 
    PrimitiveType, 
    VertexCount, 
    Texture, 
    Matrix3
) ->
    Buffer = mesh2:gl_object(Mesh),
    Matrix4 = matrix3:to_matrix4(Matrix3),

    {ModelLocation, _, _} = Locations,
    ok = frame_draw(
        Framebuffer,
        Viewport,
        program:gl_object(Program),
        ModelLocation,
        {{mesh2, Buffer}, PrimitiveType, VertexCount, Texture, matrix4:columns(Matrix4)}
    ),

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
draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount) ->
    draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, no_texture).

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
draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, Texture) ->
    draw_mesh3(Frame, Mesh, PrimitiveType, VertexCount, Texture, ?MATRIX4_IDENTITY).


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
draw_mesh3(
    {{frame, Framebuffer, _}, _, {Program, Locations}, Viewport},
    Mesh, 
    PrimitiveType, 
    VertexCount, 
    Texture, 
    Matrix
) ->
    Buffer = mesh3:gl_object(Mesh),

    {ModelLocation, _, _} = Locations,
    ok = frame_draw(
        Framebuffer,
        Viewport,
        program:gl_object(Program),
        ModelLocation,
        {{mesh3, Buffer}, PrimitiveType, VertexCount, Texture, matrix4:columns(Matrix)}
    ),
    
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

frame_draw(
    Framebuffer, Viewport, Program, ModelLocation,
    {Mesh, PrimitiveType, VertexCount, Texture, Matrix}
) ->
    ok = graphics_context:execute_commands(fun() ->

        ok = gl:bind_framebuffer(framebuffer, Framebuffer),
        {X, Y, Width, Height} = Viewport,
        ok = gl:viewport(X, Y, Width, Height),

        ok = gl:use_program(Program),

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

        ok = gl:uniform_matrix(f, ModelLocation, Matrix),

        % XXX: Location could be cached.
        {ok, UseTextureLocation} = gl:get_uniform_location(Program, "uUseTexture"),
        case Texture of
            no_texture ->
                ok = gl:uniform(i, UseTextureLocation, 0);
            _ ->
                ok = gl:uniform(i, UseTextureLocation, 1),

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

        ok
    end),

    ok.

-doc """
To be written.

To be written.
""".
-spec display(object()) -> ok.
display(_) ->
    ok = graphics_context:swap_buffers(),
    ok.

-doc """
To be written.

To be written.
""".
-spec texture(object()) -> graphics:texture().
texture({{frame, _, Texture}, Size, _, _}) ->
    {
        {texture, Texture},
        Size,
        linear,
        linear,
        linear,
        {clamp_to_edge, clamp_to_edge},
        undefined
    }.

acquire_frame(Width, Height, InternalFormat) when Width > 0 andalso Height > 0 ->
    ReleaseFun = fun({frame, Framebuffer, Texture}) ->
        ok = gl:bind_texture(texture_2d, none),
        ok = gl:delete_textures([Texture]),
        ok
    end,
    AcquireFun = fun() ->
        {ok, [Framebuffer]} = gl:gen_framebuffers(1),
        ok = gl:bind_framebuffer(framebuffer, Framebuffer),

        {ok, [Texture]} = gl:gen_textures(1),
        ok = gl:bind_texture(texture_2d, Texture),

        % the binding version of this function won't accept "null", therefore 
        % we generate dummy data (to allocate the inside of the texture).
        Pixels = gen_pixels(Width, Height),
        Data = pixels_to_data(Pixels),
        ok = gl:tex_image_2d(
            texture_2d, 0, InternalFormat,
            Width, Height, 0,
            rgba, float,
            Data
        ),

        % ok = gl:tex_image_2d(
        %     texture_2d, 0, InternalFormat,
        %     Width, Height, 0,
        %     rgba, float,
        %     <<>>
        % ),
        
        ok = gl:tex_min_filter(texture_2d, linear),
        ok = gl:tex_mag_filter(texture_2d, linear),
        ok = gl:tex_wrap_s(texture_2d, clamp_to_edge),
        ok = gl:tex_wrap_t(texture_2d, clamp_to_edge),

        % glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
        % glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, texture, 0);

        ok = gl:framebuffer_texture(
            framebuffer, 
            color_attachment0, 
            Texture, 
            0
        ),


        ok = gl:flush(),
        
        {ok, {frame, Framebuffer, Texture}, ReleaseFun}
    end,
    graphics_context:acquire_resource(AcquireFun).

release_frame(ResourceId) ->
    graphics_context:release_resource(ResourceId).

pixels_to_data(Pixels) ->
    lists:foldl(
        fun({R, G, B, A}, Acc) ->
            <<
                Acc/binary,
                R:32/float-little,
                G:32/float-little,
                B:32/float-little,
                A:32/float-little
            >>
        end,
        <<>>,
        Pixels
    ).

gen_pixels(Width, Height) ->
    [ {X/Width, Y/Height, 0.5, 1.0}
      || Y <- lists:seq(0, Height-1),
         X <- lists:seq(0, Width-1)
    ].
