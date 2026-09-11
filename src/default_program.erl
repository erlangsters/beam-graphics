-module(default_program).

-export([
    make/2
]).

-include_lib("gl/include/gl.hrl").
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

make(Width, Height) ->
    {ok, Program} = program:with_shaders(
        ?VERTEX_SHADER_SRC,
        ?FRAGMENT_SHADER_SRC
    ),
    GlProgram = program:gl_object(Program),

    Locations = graphics_context:execute_commands(fun() ->
        ok = gl:use_program(GlProgram),

        % Retrieve uniform locations (model, view and projection matrices).
        {ok, ModelLocation} = gl:get_uniform_location(GlProgram, "uModel"),
        {ok, ViewLocation} = gl:get_uniform_location(GlProgram, "uView"),
        {ok, ProjectionLocation} = gl:get_uniform_location(GlProgram, "uProjection"),

        % Set up default model matrix (no transformation).
        GlModelMatrix = matrix4:columns(?MATRIX4_IDENTITY),
        gl:uniform_matrix(f, ModelLocation, GlModelMatrix),

        % Set up default view matrix (no transformation).
        ViewMatrix = default_view_matrix(),
        GlViewMatrix = matrix4:columns(ViewMatrix),
        gl:uniform_matrix(f, ViewLocation, GlViewMatrix),

        % Set up default projection matrix (an orthographic projection).
        % XXX: What is a good value for the near and far planes?
        ProjectionMatrix = default_projection_matrix(Width, Height),
        GlProjectionMatrix = matrix4:columns(ProjectionMatrix),
        gl:uniform_matrix(f, ProjectionLocation, GlProjectionMatrix),

        % Set up default viewport.
        ok = gl:viewport(0, 0, Width, Height),

        {ModelLocation, ViewLocation, ProjectionLocation}
    end),

    {Program, Locations}.

default_view_matrix() ->
    ?MATRIX4_IDENTITY.

default_projection_matrix(Width, Height) ->
    view3:orthographic(
        0.0, erlang:float(Width), 0.0, erlang:float(Height), -9999.0, 9999.0
    ).
