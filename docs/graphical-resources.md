# Graphical Resources

Meshes, textures, programs, frames, and surfaces wrap GPU or EGL objects.
Vectors, matrices, colors, boxes, cameras, vertices, and images are values.
Copying a value copies the data. Copying a resource term does not copy the
GPU object.

A well-formed float payload uses floats, not integers. Resource constructors
that talk to the GPU also require a running graphics context. Named color
macros come from `graphics.hrl`.

**Table of Contents**

- [Values and resources](#values-and-resources)
- [Creating and destroying](#creating-and-destroying)
- [Ownership](#ownership)
- [Surfaces and frames](#surfaces-and-frames)
- [Shapes](#shapes)
- [Usage hints and local copies](#usage-hints-and-local-copies)

## Values and resources

| Kind | Modules | GPU object |
| --- | --- | --- |
| Value | `vector2`, `vector3`, `matrix3`, `matrix4`, `color`, `box2`, `box3`, `camera2`, `camera3`, `transform2`, `transform3`, `view2`, `view3` | no |
| Vertex / image | `graphics:vertex2()`, `graphics:vertex3()`, `graphics:image()` | no; there is no vertex module |
| GPU resource | `mesh2`, `mesh3`, `texture`, `program`, `frame` | yes; acquired on `graphics_context` |
| Draw target worker | `surface` | yes; own OpenGL context, linked process |
| Wrapper | `shape2`, `shape3`, `sprite` | the meshes underneath |

`sprite` constructs a `graphics:shape2()`. There is no sprite type.

## Creating and destroying

GPU constructors are named `with_*`. They return `{ok, Object}` or a resource
error.

```erlang
{ok, Mesh} = mesh2:with_vertices(Vertices),
{ok, Texture} = texture:with_image(Image),
{ok, Program} = program:with_shaders(VertexSrc, FragmentSrc),
{ok, Frame} = frame:with_size({256, 256}),
{ok, Surface} = surface:with_size(Display, {640, 480}).
```

`out_of_memory` is a bare atom. Program compile and link failures are tagged
tuples because they carry the driver info log.

Dispose with `destroy/1`. Using the object afterwards has undefined behavior.
Destroying the same object twice is invalid.

```erlang
ok = mesh2:destroy(Mesh),
ok = texture:destroy(Texture),
ok = program:destroy(Program),
ok = frame:destroy(Frame),
ok = surface:destroy(Surface).
```

`graphics:terminate/0` stops the graphics context and releases remaining GPU
resources acquired on it.

## Ownership

The graphics context is the singleton GPU process. `graphics:initialize/1`
starts it. Meshes, textures, programs, and frames are created there.

The **owner** is the process whose death releases the resource. Construction
records `self()`. If that process dies, the GPU object is released. If the
graphics context stops, remaining resources are released. Owners are not
killed.

Copying a `texture:object()` or `mesh2:object()` shares the GPU object. It
does not create a second owner.

`graphics_context:transfer_ownership/2` retargets the owner of a
`resource_id()`. It does not copy GPU memory. High-level objects do not
export that id. The transfer API is for ids from
`graphics_context:acquire_resource/1`. Anyone who has the id may release or
transfer it.

A surface is different. It is a worker process with its own OpenGL context
that shares with the graphics context. The calling process is linked to that
worker. If the caller dies, the worker stops.

See the `graphics_context` module.

## Surfaces and frames

A surface presents to a window or a pbuffer and can read CPU pixels. A frame
is an offscreen target whose result is a texture.

The frame owns its framebuffer, its hidden depth renderbuffer, its color
texture, and its stock program. `frame:texture/1` returns that owned texture.
Destroying the frame destroys the texture. Do not destroy the texture
independently.

A surface owns its EGL surface, its OpenGL context, and its stock program.
It does not own the meshes and textures drawn on it.

Viewport, blend mode, depth test, view, and projection live on the Erlang
term of both. Setters return `{ok, NewTarget}` and do not talk to the GPU
until the next `clear` or `draw`.

See [2D Rendering](going-2d.md) and [3D Rendering](going-3d.md) for drawing.
See [Texturing](texturing.md) for using a frame as a texture.

## Shapes

A shape is a value wrapper around GPU meshes, a model matrix, and an optional
texture. Copying the term shares the meshes.

```erlang
{ok, Shape} = shape2:rectangle({0.0, 0.0}, {100.0, 50.0}, ?COLOR_RED),
ok = shape2:destroy(Shape).
```

`destroy/1` destroys the meshes. It does not destroy the texture. Primitive
constructors allocate with `mesh2:with_vertices/1` or `mesh3:with_vertices/1`.
`with_mesh` / `with_meshes` do not allocate.

`set_matrix/2` and `set_texture/2` return a new shape with the same mesh
terms. They do not mutate GPU state.

## Usage hints and local copies

Vertex and pixel data must live in GPU memory to be drawn. Reading and
updating that data has a cost.

Mesh usage hints are `static`, `dynamic`, and `stream`. They are DRAW only.
The default is `static`.

```erlang
{ok, Mesh} = mesh2:with_vertices(Vertices, dynamic).
```

Copy policy is `no_copy` or `keep_copy`. The default is `no_copy`.
`local_vertices/1` and `local_image/1` return `undefined` when there is no
cache. `remote_vertices/1` and `remote_image/1` read from the GPU.

```erlang
{ok, Mesh} = mesh2:with_vertices(Vertices, static, keep_copy),
Vertices = mesh2:local_vertices(Mesh).
```

`keep_local_copy/1` GPU-reads and stores a cache. `release_local_copy/1`
drops it. `has_local_copy/1` is the predicate.

In-place updates (`update_vertices`, `update_image`, `update_pixel`) keep
the size. Replacing the payload (`set_vertices`, `set_image`, `resize`)
reallocates the data store and keeps the OpenGL id.

See the `mesh2`, `mesh3`, and `texture` modules.
