# Text Rendering

This library has no text or font API. Font loading, glyph rasterization, and
layout live in
[beam-graphics-text](https://github.com/erlangsters/beam-graphics-text).

That companion constructs a core `graphics:shape2()` of glyph quads. Draw it
with `graphics_surface:draw_shape2/2` or `graphics_frame:draw_shape2/2`. Blend mode `alpha` is
required.

```erlang
{ok, Font} = graphics_font:from_file("font.ttf", 32.0),
{ok, Shape} = graphics_text:from_string(
    Font,
    {0.0, 0.0},
    "Hello",
    ?COLOR_WHITE
),
{ok, Surface} = graphics_surface:set_blend_mode(Surface, alpha),
ok = graphics_surface:draw_shape2(Surface, Shape),
ok = graphics_shape2:destroy(Shape),
ok = graphics_font:destroy(Font).
```

`Position` is the baseline origin of the first line. Y increases upward. The
font owns the atlas texture. The text shape does not. Destroy the shape
before the font. `graphics_shape2:destroy/1` does not destroy the atlas.
