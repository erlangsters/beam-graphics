# Going Native

This document covers mixing the BEAM graphics library with OpenGL. The high
level API owns resources, draw targets, and the stock pipeline. Custom
shaders and extra GL state go through the escape hatch.

The public concepts stay the same if a later backend replaces OpenGL. The
escape hatch is the OpenGL-shaped part.

**Table of Contents**

- [When to go native](#when-to-go-native)
- [Mapping to OpenGL](#mapping-to-opengl)
- [Programs](#programs)
- [Issuing OpenGL commands](#issuing-opengl-commands)
- [Stock pipeline](#stock-pipeline)

## When to go native

Stay on `surface` / `frame` draw calls when the stock program is enough:
position, color, UV, a model matrix, a view, a projection, and an optional
texture.

Go native to compile your own shaders, bind extra GL state, or draw with a
vertex layout this library does not own. Draw does not take a program.
`surface:draw_mesh2/4` and `frame:draw_mesh3/4` always use the stock
pipeline.

## Mapping to OpenGL

| Concept | OpenGL object | Escape hatch |
| --- | --- | --- |
| `graphics_context` | Shared EGL/OpenGL context and the resource table | `inner_context/0`, `execute_commands/1` |
| `surface` | EGL window or pbuffer, dedicated OpenGL context | `gl_commands/2` |
| `frame` | Framebuffer, color texture, hidden depth renderbuffer | `gl_object/1` (framebuffer). Color id is `texture:gl_object(frame:texture(Frame))` |
| `mesh2`, `mesh3` | Buffer | `gl_object/1` |
| `texture` | 2D texture | `gl_object/1` |
| `program` | Program | `gl_object/1` |

A surface context shares with the graphics context, so mesh, texture, and
program ids created on `graphics_context` can be used while a surface
context is current.

`none` is the public unbind. Do not pass integer `0` as “no object”.

## Programs

A program is a GPU shader program. There is one module for 2D and 3D. It is
created from a vertex shader string and a fragment shader string.

```erlang
{ok, Program} = program:with_shaders(VertexSrc, FragmentSrc),
ok = program:set_uniform(Program, "uModel", matrix4:identity()),
ok = program:destroy(Program).
```

`set_uniform/3` writes GPU state with `glProgramUniform*`. The program does
not need to be bound. The Erlang term does not change. A missing or
optimized-out name is `no_uniform`. A well-formed value of the wrong kind is
`type_mismatch`.

Supported uniform types: `bool`, `int`, `float`, `vector2`, `vector3`,
`vector4`, `matrix3`, `matrix4`, `sampler2d`. A `sampler2d` value is a
texture unit (an integer), not a `texture:object()`. A color is a `vector4`.
There is no silent `matrix3:to_matrix4/1`.

`binary/1` returns a vendor-specific compiled payload. It is not portable
across drivers. `no_binary` means the driver has no program binary.

Meshes upload position, color, and UV at attribute locations 0, 1, and 2.
`program` does not enforce that layout. A custom program drawn against these
meshes should match it. 2D positions are two floats; a `vec3` input reads
Z as `0.0`.

See the `program` module.

## Issuing OpenGL commands

Commands must run while the intended OpenGL context is current.

On the graphics context (meshes, textures, programs, frames):

```erlang
Result = graphics_context:execute_commands(fun() ->
    ok = gl:clear_color(0.0, 0.0, 0.0, 1.0),
    ok = gl:clear([color_buffer_bit, depth_buffer_bit]),
    ok
end).
```

On a surface:

```erlang
Result = surface:gl_commands(Surface, fun() ->
    ok = gl:viewport(0, 0, 640, 480),
    ok = gl:clear_color(0.0, 0.0, 0.0, 1.0),
    ok = gl:clear([color_buffer_bit, depth_buffer_bit]),
    ok
end).
```

If the fun raises, the return is `{error, {exception, Class, Reason}}` and
the process stays running.

`program:set_uniform/3` hops to `graphics_context`. Uniform writes there are
not reliably visible on a surface context. On a surface, set uniforms with
`gl:program_uniform*` inside `gl_commands/2`. On a frame, `set_uniform/3`
is the same context that draws.

Bind a frame's framebuffer from `frame:gl_object/1` before issuing draw
commands through `execute_commands/1`. Sampling `frame:texture(Frame)` while
that framebuffer is the draw target is undefined.

After custom draws on a surface, `surface:display/1` and `surface:image/1`
still work. The stock `draw_mesh` / `draw_shape` calls are unaware of extra
GL state you leave bound; set what you need inside the same command batch.

## Stock pipeline

The stock program is an internal helper. It is not a public GPU type. Surface
and frame each own one.

Attribute locations: 0 position, 1 color, 2 UV.

Uniforms: `uModel`, `uView`, `uProjection` (`matrix4`), `uTexture`
(`sampler2d` unit 0), `uUseTexture` (`bool`).

2D model matrices are embedded with `matrix3:to_matrix4/1` at draw time.
`uUseTexture` selects vertex color only, or vertex color modulated by the
bound texture.

GLSL is `#version 460 core`. Custom factors, extra shader stages, and
pipeline state beyond viewport, blend mode, and depth test stay on this
escape hatch.

See the generated OpenGL binding for command names.
