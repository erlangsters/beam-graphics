# Graphics library for the BEAM

This is the missing graphics library in the Erlang/Elixir programming language.
It provides a minimal API for graphics rendering and is built on top of EGL,
OpenGL and OpenGL ES. For advanced uses, interpolation with the underlying
graphics library is possible.

Supported platforms.

- [x] Linux
- [ ] macOS
- [ ] Windows
- [ ] iOS*
- [ ] Android*

*We are working on a modern distribution of Erlang (without the OTP framework)
which will make supporting those platforms easy.

Written by Jonathan De Wachter (dewachter.jonathan@gmail.com) and released
under the MIT license.

> Note that it does not provide any window capabilities. See the
[BEAM window library](https://github.com/erlangsters/beam-window) to display
graphics on the screen.

## Getting started

This library can be seen as a wrapper around the OpenGL. Instead of exposing
a heavy machinery, it aims to

Typically, 3D rendering knowledges are essential.
If you are an OpenGL programmer and need to use
rendering pipeline

```
To be written.
```

To be written.

functional (pid like )

## Going 2D

The following snippet of code showcase the use of the library for 2D rendering.

```erlang
surface:new({640, 480}).

View = view2:new({0, 0}, {320, 240}),

surface:set_view(View)
Square = [
    {1, 2, 3, 0, 0, ?COLOR_RED},
    {1, 2, 3, 0, 0, ?COLOR_RED},
    {1, 2, 3, 0, 0, ?COLOR_RED},
    {1, 2, 3, 0, 0, ?COLOR_RED}
],

surface:draw(strip_triangle, Square),

surface:swap()
Image = surface:to_image(),

display_image(Image)
```

See the section below for the implementation of the `display_image/1` function.

## Going 3D

The following snippet of code showcase the use of the library for 3D rendering.

```erlang
surface:new({640, 480}).

View = view3:new({0, 0}, {320, 240}),
surface:set_view(View)

Cube = [
    {1, 2, 3, 0, 0, ?COLOR_RED},
    {1, 2, 3, 0, 0, ?COLOR_RED},
    {1, 2, 3, 0, 0, ?COLOR_RED},
    {1, 2, 3, 0, 0, ?COLOR_RED}
],

surface:draw(strip_triangle, Square),

surface:swap()
Image = surface:to_image(),

display_image(Image)
```

See the section below for the implementation of the `display_image/1` function.

## Custom rendering pipeline

To be written.

```
beam_graphics:initialize({open_gl, 4, 2}).


```

To be written.

## Displaying an image

The previous snippets of code show rendering is done on a surface and then how
pixels (=image) are retrieved. Because the graphics library is designed to be
minimal, there is no built-in ways to display the results. For that you must
either use the window library to display on a window, or you can save the result
an on disk image.

Displaying on a window.

```erlang
display_image(Image) ->
  {ok, Window} = window:new({640, 480}, "Result"),
  Surface = window:surface(Window),
  surface:update_with_image(Image),
  window:swap()
  timer:sleep(infinity).

```

Saving pixels to image.

```erlang
save_to_disk(Image, png) ->
  image_png:save(Image, "result.png");
save_to_disk(Image, jpeg) ->
  image_png:save(Image, "result.jpeg");
save_to_disk(Image, bmp) ->
  image_png:save(Image, "result.bmp").
```

To be written.

## Using it in your project

With the **Rebar3** build system, add the following to the `rebar.config` file
of your project.

```
{deps, [
  {beam_graphics, {git, "https://github.com/erlangsters/beam-graphics.git", {tag, "master"}}}
]}.
```

If you happen to use the **Erlang.mk** build system, then add the following to
your Makefile.

```
BUILD_DEPS = beam_graphics
dep_beam_graphics = git https://github.com/erlangsters/beam-graphics master
```

In practice, you want to replace the branch "master" with a specific tag to
avoid breaking your project if incompatible changes are made.
