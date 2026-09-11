# Binding Shape Follow-Up

Status: open. Recorded after comparing this library to the rewritten
generated OpenGL bindings. Adjust `beam-graphics` to the current public
shapes first. Return here before asking the generator to change mapping
policy or add named helpers.

This note is not a replacement for the generator's `docs/api-mapping.md`.
It records where this library disagreed with the generated wrappers, which
of those disagreements are C-shaped calling, and which ones are the binding
failing its own rules.

## Context

`beam-graphics` was written against the pre-rewrite OpenGL wrapper. The
commands it needs are almost all present on the OpenGL 4.6 target. The
mismatches are call-site shape, not missing GL entry points.

The library is desktop 4.6 in practice (`glad_load_gl/0`, context 4.6,
`#version 460 core`) even when older README text talks about OpenGL ES.

## Mapping Rules Used Here

- Keep OpenGL command identity unless a wrapper is clearly safer.
- Atoms for enums, lists of atoms for bitfields.
- `none` for documented unbind and object-zero.
- Derive counts from lists when the derivation is unambiguous.
- `glGet*` stays command-shaped; the parameter name is an argument, not part
  of the function name.
- A type selector (`f` / `i` / `ui`) belongs only on a family that really has
  several C suffixes, and only when the Erlang value is not already enough to
  choose the path.

## Keep The Current Binding Shape

These library call sites should move to the current wrappers. Restoring the
old arities would make the binding look like `gl.h` with snake_case.

| Old consumer call | Current public shape | Why this is the mapping |
| --- | --- | --- |
| `gl:get_shader(i, Shader, compile_status, 1)` | `gl:get_shader(Shader, compile_status, 1)` | `glGetShaderiv` has no `f` sibling. A leading `i` is a fake selector. |
| `gl:get_program(i, Program, link_status, 1)` | `gl:get_program(Program, link_status, 1)` | Same as `get_shader/3`. Status values stay integers in a list. |
| `gl:uniform_matrix(f, Loc, 1, false, [M])` | `gl:uniform_matrix(f, Loc, M)` or a list of matrices | Count is the value's shape. `transpose` exists in C for row-major uploads; public matrices are already column tuples, so `false` is part of the type. |
| `gl:uniform(i, Loc, {0})` | `gl:uniform(i, Loc, 0)` | Vectors are arity 2/3/4. There is no 1-vector. A scalar uniform is a scalar. |
| `gl:delete_buffers(1, [B])` and the same for textures and VAOs | `gl:delete_buffers([B])` | The list already has a length. `glDelete*(n, ptr)` is pointer-plus-length. |
| `gl:bind_vertex_array(0)`, `gl:bind_texture(_, 0)` | `none` | Zero as “no object” leaks the GL name table. EGL already uses `no_context` / `no_surface`. |
| `gl:pixel_store(i, unpack_alignment, 1)` | `gl:pixel_store(unpack_alignment, 1)` | `i`/`f` can be chosen from `is_integer` / `is_float`. An extra selector would only mimic `tex_parameter`. |
| `gl:location()` / `gl:uniform_location()` | `gl:int()` | Locations are not object names; they can be `-1`. Family-specific types are for objects. |

`matrix4:columns/1` already builds nested column tuples. That matches
`uniform_matrix/3`. The extra `1, false` arguments are leftover C signature,
not a missing matrix feature.

`get_uniform(f, Program, Location, 16)` already matches command-shaped
readback: explicit count, typed list. Rebuilding a matrix from that list is
the caller's job.

`pixel_store/2` is a suffixed C family (`glPixelStorei` / `glPixelStoref`), but
the Erlang value type already selects the path. Generator tests lock `/2` and
reject `/3`. Keep that split: use an explicit selector only when the term is
ambiguous.

Do not restore named convenience getters such as `get_shader_compile_status/1`.
That decision stands.

## Binding Follow-Up: Enum Values On Generic Setters

The generator mapping already shows:

```erlang
ok = gl:tex_parameter(i, texture_2d, texture_min_filter, linear).
```

The generated `tex_parameter/4` does not accept `linear`. The `i` path takes
`[integer()]`. Enum atoms only work on extra wrappers:

- `tex_min_filter/2`
- `tex_mag_filter/2`
- `tex_wrap_s/2`
- `tex_wrap_t/2`

That is the same class of leak as `get_shader_compile_status/1`: the parameter
name moved into the function name because the generic setter could not take
atoms.

The consistent public shape is one command-shaped setter whose value is an
atom when the pname is an enum:

```erlang
ok = gl:tex_parameter(i, texture_2d, texture_min_filter, linear).
ok = gl:tex_parameter(i, texture_2d, texture_wrap_s, clamp_to_edge).
ok = gl:tex_parameter(f, texture_2d, texture_lod_bias, -0.5).
```

The named filter and wrap helpers then become optional sugar, not the only
atom path. Do not add more of them.

Passing `?GL_LINEAR` as a raw integer is wrong on both sides: integers are not
the public enum mapping, and a scalar int does not match the current `i` list
clause.

Until that generator follow-up lands, this library can use the existing
`tex_min_filter/2` (and sibling) wrappers or integer lists, then switch to
atom values on `tex_parameter/4`.

When the generator follow-up is picked up, search for the same
pname-selects-enum-value pattern on other generic setters and queries, not
only `tex_parameter`.

## What Not To Reopen

Do not restore:

- type selectors on integer-only get families;
- public delete counts next to lists;
- integer `0` as unbind;
- C-shaped `uniform_matrix/5` with count and transpose.

Those changes would be for one pre-rewrite consumer. The mapping is meant to
be the single OpenGL-to-Erlang contract.

Change the generator only when a port finds a real missing contract: a command
that cannot be expressed, a broken `none` unbind, or a readback that cannot
return BEAM data. That remains a graphics-stack task with the usual OpenGL 4.6
and OpenGL ES 3.2 check.
