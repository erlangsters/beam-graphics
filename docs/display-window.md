# Display on a Window

This library renders. It does not create or manage windows. A surface is
either a pbuffer (`surface:with_size/2`) or a window drawable
(`surface:with_window/3`).

`with_window/3` takes an already-initialized EGL display, an EGL native
window handle, and a pixel size that should match the window framebuffer. A
running graphics context is required.

The current way to obtain that handle is
[GLFW](https://github.com/erlangsters/glfw). GLFW windows in that binding are
contextless: EGL owns the context, which is what `surface` already does.

```erlang
true = glfw:init(),
{ok, Window} = glfw:create_window(640, 480, "beam-graphics"),
Handle = glfw:window_egl_handle(Window),
{ok, Surface} = surface:with_window(Display, Handle, {640, 480}),
ok = surface:clear(Surface, ?COLOR_BLACK),
ok = surface:draw_shape2(Surface, Shape),
ok = surface:display(Surface).
```

`display/1` is `egl:swap_buffers`. After it, the window back buffer is
undefined. `image/1` reads the current drawable, which is the buffer that was
just drawn to, not the presented front buffer.

Input, the event loop, and window lifetime stay in GLFW. A higher-level
`beam-window` library is planned and is not required to present.

For offscreen work, keep `surface:with_size/2` and `surface:image/1`, or draw
into a `frame` and sample `frame:texture/1`. See [Texturing](texturing.md).
