%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(graphics).
-moduledoc """
To be written.

To be written.
""".

-export_type([
    angle/0,
    vector2/0,
    vector3/0,
    matrix3/0,
    matrix4/0,
    color/0,
    box2/0,
    box3/0
]).
-export_type([
    vertex2/0,
    vertex3/0
]).
-export([
    initialize/1,
    terminate/0
]).

-doc """
An angle in radians.

To be written.
""".
-type angle() :: float().

-doc """
A 2D vector.

A pair of numbers typically used to represent 2D positions and directions in
the Euclidean plane.

Note that it defines operations with 3x3 matrices by assuming an invisible
third component set to 0.0 (also called the homogeneous coordinate).
""".
-type vector2() :: {
    X :: float(),
    Y :: float()
}.

-doc """
A 3D vector.

A triplet of numbers typically used to represent 3D positions and directions in
the Euclidean space.

Note that it defines operations with 4x4 matrices by assuming an invisible
fourth component set to 0.0 (also called the homogeneous coordinate).
""".
-type vector3() :: {
    X :: float(),
    Y :: float(),
    Z :: float()
}.

-doc """
A 3x3 matrix.

A 3x3 grid of numbers typically used to represent 2D transformations in the
Euclidean plane.

column majoor order xxx
""".
-type matrix3() :: {
    M11 :: float(),
    M21 :: float(),
    M31 :: float(),
    M12 :: float(),
    M22 :: float(),
    M32 :: float(),
    M13 :: float(),
    M23 :: float(),
    M33 :: float()
}.

-doc """
A 4x4 matrix.

A 4x4 grid of numbers typically used to represent 3D transformations in the
Euclidean space.

column majoor order xxx
""".
-type matrix4() :: {
    M11 :: float(),
    M21 :: float(),
    M31 :: float(),
    M41 :: float(),
    M12 :: float(),
    M22 :: float(),
    M32 :: float(),
    M42 :: float(),
    M13 :: float(),
    M23 :: float(),
    M33 :: float(),
    M43 :: float(),
    M14 :: float(),
    M24 :: float(),
    M34 :: float(),
    M44 :: float()
}.

-doc """
A RGBA color.

To be written.
""".
-type color() :: {
    Red :: color:channel(),
    Green :: color:channel(),
    Blue :: color:channel(),
    Alpha :: color:channel()
}.

-doc """
To be written.

To be written.
""".
-type box2() :: {
    Min :: vector2(),
    Max :: vector2()
}.

-doc """
To be written.

To be written.
""".
-type box3() :: {
    Min :: vector3(),
    Max :: vector3()
}.

-doc """
To be written.

To be written.
""".
-type vertex2() :: {
    Position :: vector2(),
    Color :: color(),
    U :: float(),
    V :: float()
}.

-doc """
To be written.

To be written.
""".
-type vertex3() :: {
    Position :: vector3(),
    Color :: color(),
    U :: float(),
    V :: float()
}.

-spec initialize(egl:display()) -> ok.
initialize(Display) ->
    graphics_context:start(Display),
    ok.

-doc """
To be written.

To be written.
""".
-spec terminate() -> ok.
terminate() ->
    ok = graphics_context:stop(),
    ok.
