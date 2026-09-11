%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%

-define(ANGLE_PI, 3.14159265358979323846).

-define(ANGLE_ZERO, 0.0).
-define(ANGLE_45, 0.78539816339744830962).
-define(ANGLE_90, 1.57079632679489661923).
-define(ANGLE_180, 3.14159265358979323846).
-define(ANGLE_270, 4.71238898038468985769).
-define(ANGLE_360, 6.28318530717958647692).

-define(ANGLE_TO_RADIAN(Degree), ((Degree) * ?ANGLE_PI / 180.0)).
-define(ANGLE_TO_DEGREE(Radian), ((Radian) * 180.0 / ?ANGLE_PI)).

-define(VECTOR2_ZERO, {0.0, 0.0}).
-define(VECTOR3_ZERO, {0.0, 0.0, 0.0}).

-define(MATRIX3_ZERO, {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}).
-define(MATRIX3_IDENTITY, {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0}).

-define(MATRIX4_ZERO,
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
).
-define(MATRIX4_IDENTITY,
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
).

-define(COLOR_BLACK, {0.0, 0.0, 0.0, 1.0}).
-define(COLOR_WHITE, {1.0, 1.0, 1.0, 1.0}).
-define(COLOR_RED, {1.0, 0.0, 0.0, 1.0}).
-define(COLOR_GREEN, {0.0, 1.0, 0.0, 1.0}).
-define(COLOR_BLUE, {0.0, 0.0, 1.0, 1.0}).
-define(COLOR_YELLOW, {1.0, 1.0, 0.0, 1.0}).
-define(COLOR_CYAN, {0.0, 1.0, 1.0, 1.0}).
-define(COLOR_MAGENTA, {1.0, 0.0, 1.0, 1.0}).
-define(COLOR_TRANSPARENT, {0.0, 0.0, 0.0, 0.0}).

-define(VERTEX2(Position),
    begin
        {
            {element(1, Position), element(2, Position)},
            ?COLOR_BLACK,
            0.0, 0.0
        }
    end
).

-define(VERTEX2(Position, Color),
    begin
        {
            {element(1, Position), element(2, Position)},
            Color,
            0.0, 0.0
        }
    end
).

-define(VERTEX3(Position),
    begin
        {
            {element(1, Position), element(2, Position), element(3, Position)}
            ?COLOR_BLACK,
            0.0, 0.0
        }
    end
).

-define(VERTEX3(Position, Color),
    begin
        {
            {element(1, Position), element(2, Position), element(3, Position)},
            Color,
            0.0, 0.0
        }
    end
).

-record(shape2, {
    meshes :: [{mesh2:mesh(), graphics:primitive_type(), graphics:vertex_count()}],
    matrix = ?MATRIX3_IDENTITY :: graphics:matrix3(),
    texture = no_texture :: no_texture | graphics:texture()
}).

-record(shape3, {
    meshes :: [{mesh3:mesh(), graphics:primitive_type(), graphics:vertex_count()}],
    matrix = ?MATRIX4_IDENTITY :: graphics:matrix4(),
    texture = no_texture  :: no_texture | graphics:texture()
}).

% -record(blend_mode, {
%     color_src_factor :: blend_mode:factor()   = src_alpha,
%     color_dst_factor :: blend_mode:factor()   = one_minus_src_alpha,
%     color_equation   :: blend_mode:equation() = add,
%     alpha_src_factor :: blend_mode:factor()   = one,
%     alpha_dst_factor :: blend_mode:factor()   = one_minus_src_alpha,
%     alpha_equation   :: blend_mode:equation() = add
% }).

% -define(BLEND_ALPHA, #blend_mode{
%     color_src_factor   = src_alpha,
%     color_dst_factor   = one_minus_src_alpha,
%     color_equation     = add,
%     alpha_src_factor   = one,
%     alpha_dst_factor   = one_minus_src_alpha,
%     alpha_equation     = add
% }).

% -define(BLEND_ADD, #blend_mode{
%     color_src_factor   = one,
%     color_dst_factor   = one,
%     color_equation     = add,
%     alpha_src_factor   = one,
%     alpha_dst_factor   = one,
%     alpha_equation     = add
% }).

% -define(BLEND_MULTIPLY, #blend_mode{
%     color_src_factor   = src_color,
%     color_dst_factor   = one_minus_src_color,
%     color_equation     = add,
%     alpha_src_factor   = src_alpha,
%     alpha_dst_factor   = one_minus_src_alpha,
%     alpha_equation     = add
% }).

% -define(BLEND_NONE, #blend_mode{
%     color_src_factor   = zero,
%     color_dst_factor   = zero,
%     color_equation     = add,
%     alpha_src_factor   = zero,
%     alpha_dst_factor   = zero,
%     alpha_equation     = add
% }).
