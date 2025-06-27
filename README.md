# Graphics library for the BEAM

> :construction: This project is under active development. Do not used at the
> moment as it's not ready. Consult the `develop` branch for progress.

[![Erlangsters Repository](https://img.shields.io/badge/erlangsters-beam--graphics-%23a90432)](https://github.com/erlangsters/beam-graphics)
![Supported Erlang/OTP Versions](https://img.shields.io/badge/erlang%2Fotp-28-%23a90432)
![Current Version](https://img.shields.io/badge/version-0.1.0-%23354052)
![License](https://img.shields.io/github/license/erlangsters/beam-graphics)
[![Build Status](https://img.shields.io/github/actions/workflow/status/erlangsters/beam-graphics/workflow.yml)](https://github.com/erlangsters/beam-graphics/actions/workflows/workflow.yml)
[![Documentation Link](https://img.shields.io/badge/documentation-available-yellow)](http://erlangsters.github.io/beam-graphics/)

The missing graphics library of the BEAM ecosystem available for the Erlang and
Elixir programming language.

It provides a minimal API for graphics rendering and is built on top of EGL,
OpenGL and OpenGL ES. For advanced uses, [interpolation with the underlying
graphics library](https://docs.erlangsters.org/beam-graphics/latest/opengl-interpolation)
is possible.

```erlang
{deps, [
  {beam_graphics, {git, "https://github.com/erlangsters/beam-graphics.git", {tag, "master"}}}
]}.
```

Supported platforms.

- [x] Linux
- [ ] macOS
- [ ] Windows
- [ ] iOS*
- [ ] Android*

Written by the Erlangsters [community](https://about.erlangsters.org/) and
released under the MIT [license](/https://opensource.org/license/mit).

> Note that it does not provide any window capabilities. See the
[BEAM window library](https://github.com/erlangsters/beam-window) to display
graphics on the screen.

## Getting started

To render anything, you must first create a surface which will contain the result
of whatever you're rendering (be it a 2D or 3D object).

```erlang
{ok, S} = surface:new({640, 480}).
```

See a surface as a 2D image actually. And it's not uncommon to start rendering
fresh and fill the surface with an even color.

```erlang
ok = surface:erase(S, ?COLOR_BLACK).
```

The actual rendering is covered in one of the sections below, depending on
whether you're interested in rendering [2D objects](#going-2d) or
[3D objects](#going-3d).

When you're done, use the swap operation in order to wait until all rendering
operations are executed and the surface contains the result.

```erlang
ok = surface:swap(S).
```

With the surface containing the final result, you're ready to display it on a
window, or save it as an image on disk, or even re-use it for further rendering
(such as in a texture).

Read the documentation which covers the entire foo, bar, quz.

## Going 2D

The following snippet of code showcases the use of the library for 2D
rendering.

```erlang
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

The following snippet of code showcases the use of the library for 3D
rendering.

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

## Going native

The library is designed to eliminate the need of writing a rendering pipeline
and having to write complex mathematical operation, but it does not mean it
keeps you from doing in it. In fact, it's equally designed for addvanced
rendering.

First, you will want to know the underlying OpenGL-related infos that graphics
library was initialized with.

```erlang
beam_graphics:info().
```

Instead of relying on the default rendering pipeline, you start with creating
your own, that is, a shader program.

```erlang
shader:new(Vertex, Fragment).
```

From there on, you're in control of the coordinates system and know how to feed
it with data.

Instead of setting the view of a surface (transformations is now done in your
shader), you adjust the viewport.

```erlang
surface:set_viewport(S, {1, 2, 3, 4}).
```

Now you're ready to draw vertices using your program.

```erlang
surface:draw(S, V, Shader).
```

An entire section in the documentation is dedicated to advanced rendering by
showing you, and foo and bar.
