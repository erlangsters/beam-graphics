%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics_default_program).
-moduledoc """
Default Program

The default program is the stock GPU shader program used by `graphics_frame` and
`graphics_surface` to draw meshes and shapes.

This module is an internal helper. It is not part of the public graphics API.
A default program is a `graphics_program:object()`. It is created with `new/0` and
disposed with `graphics_program:destroy/1`. Copying the term does not copy the GPU
program.

```erlang
{ok, Program} = graphics_default_program:new(),
ok = graphics_program:destroy(Program).
```

There is one default program for both 2D and 3D drawing. Meshes upload
position, color, and UV at attribute locations 0, 1, and 2. 2D positions are
two floats; the shader reads a `vec3` and the missing Z is 0.0. 2D model
matrices are embedded with `graphics_matrix3:to_matrix4/1` at draw time.

The stock uniforms are `uModel`, `uView`, and `uProjection` (`graphics_matrix4`),
`uTexture` (`sampler2d` on texture unit 0), and `uUseTexture` (`bool`).
`new/0` sets `uTexture` to 0 and `uUseTexture` to `false`. Model, view, and
projection are draw-target state; they are not set here.

`uUseTexture` selects vertex color only, or vertex color modulated by the
bound texture. A `sampler2d` uniform is a texture unit, not a texture object.
Binding a texture is a draw concern.

**OpenGL Internals**

A default program is a `graphics_program:object()`. Use `graphics_program:gl_object/1` to
retrieve the program id.
""".

-export([
    new/0
]).

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

-doc """
A default program from the stock shaders.

It compiles and links the stock vertex and fragment shaders. It sets
`uTexture` to texture unit 0 and `uUseTexture` to `false`.

It returns `out_of_memory` when the GPU cannot allocate the program. Compile
and link failures include the driver info log.
""".
-spec new() ->
    {ok, graphics_program:object()} |
    {compile_error, vertex | fragment, string()} |
    {link_error, string()} |
    out_of_memory
.
new() ->
    case graphics_program:with_shaders(?VERTEX_SHADER_SRC, ?FRAGMENT_SHADER_SRC) of
        {ok, Program} ->
            ok = graphics_program:set_uniform(Program, "uTexture", 0),
            ok = graphics_program:set_uniform(Program, "uUseTexture", false),
            {ok, Program};
        Error ->
            Error
    end.
