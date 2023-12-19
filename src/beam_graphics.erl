-module(beam_graphics).

-export_type([vector2/0, vector3/0]).

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
