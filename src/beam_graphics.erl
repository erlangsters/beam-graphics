-module(beam_graphics).

-export_type([vector2/0, vector3/0]).
-export_type([matrix3/0, matrix4/0]).

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
