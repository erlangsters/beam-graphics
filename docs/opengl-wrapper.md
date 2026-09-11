# OpenGL Wrapper

The BEAM graphics library is nothing but a wrapper around the OpenGL.

OpenGL is not process-safe (as opposed to "thread-safe" in C) and it requires 
to carefully manage OpenGL contexts that must be bound to a process before 
executing OpenGL commands.

Then, on top of that, it involves transferring raw data to buffer and 
programming the rendering pipelines with a shader program. Also, it requires a 
fair amount of mathematics to understand vertices transformation.

It's a low-level API that is not for everyone, that's for sure.

With that said, it's useful to know OpenGL contexts and the OpenGL objects 
are managed under the hood to make the best out of this library.
or even interpolate ..xxx

## To be written.

This graphics library merely is a convenient wrapper around OpenGL (or OpenGL
ES when the former is not available) that eliminates the needs of having
to write a rendering pipeline (a shader program) and make complicated math
operations in order to position both objects and cameras.


## Mapping with OpenGL resources

Every concept in the BEAM graphics library has a one-on-one mapping with a
OpenGL resources.

**Surface**

Surfaces are
Note that when you use a window, this is OpenGL frame buffer.

**Vertex Arrays**

Vertex arrays are nothing but OpenGL buffer objects that contains the
vertices.

XXX: Explain how vertices are stored in the object.

**Texture**

Textures are nothing but OpenGL textures.

XXX: Explain constraints put on texture.

**Shader**

Shader are nothing but OpenGL shader programs.

To be written.

## Custom viewport and shader programs

If you define your own rendering pipeline, which means your own shader
programs, you must say good bye to most helper modules and functions this
library gives you. Such as the `vertexN_array` and `viewN`.
And instead set the viewport yourself.

To create your own OpenGL shader programs you may still use the `shader` and
`shader_program` module. Use the `shader_program:bind/1` function to make it
current.

Because you're using your own OpenGL shader program, only you knows the
format of the vertices that are fed, and the transformations to apply in order 
to get the rendering of yr scene right. Therefore, `vertex_array` which pack 
the vertices in known format, can't be used (unless you decide to make a 
compatible shader), and the `view` can't be used as it's the matrix that 
transform the vertices. Use the `shader_program:set_uniform/2` functions.

Last, you the output vertices of your shader program is unknown to the library. 
Therefore, you must manually set the viewport with the `surface:set_viewport/2`
function yourself.

Finally, after you're done rendering on the surface, with your own OpenGL 
calls, you may use the usual `surface:swap/x` function and do the rest as 
you always do.