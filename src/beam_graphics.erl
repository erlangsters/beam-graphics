-module(beam_graphics).

-export_type([vector2/0, vector3/0]).
-export_type([matrix3/0, matrix4/0]).
-export_type([color/0]).
-export_type([vertex2/0, vertex3/0]).
-export_type([box2/0, box3/0]).

-export_type([vertex2_array/0]).
-export_type([vertex3_array/0]).

-export([]).

%%
%% To be written.
%%
-type vector2() :: {
    X :: float(),
    Y :: float()
}.
-type vector3() :: {
    X :: float(),
    Y :: float(),
    Z :: float()
}.

-type matrix3() :: {
    A :: float(), B :: float(), C :: float(),
    D :: float(), E :: float(), F :: float(),
    G :: float(), H :: float(), I :: float()
}.
-type matrix4() :: {
    A :: float(), B :: float(), C :: float(), D :: float(),
    E :: float(), F :: float(), G :: float(), H :: float(),
    I :: float(), J :: float(), K :: float(), L :: float(),
    M :: float(), N :: float(), O :: float(), P :: float()
}.

-type color() :: {
    R :: float(),
    G :: float(),
    B :: float(),
    A :: float()
}.

-type vertex2() :: {
    Coordinate :: vector2(),
    Color :: color(),
    U :: float(),
    V :: float()
}.
-type vertex3() :: {
    Coordinate :: vector3(),
    Color :: color(),
    U :: float(),
    V :: float()
}.

-type box2() :: {
    Position :: vector2(),
    Size :: vector2()
}.
-type box3() :: {
    Position :: vector3(),
    Size :: vector3()
}.

-type vertex2_array() :: reference().
-type vertex3_array() :: reference().
