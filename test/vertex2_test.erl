%%
%% Copyright (c) 2023, Byteplug LLC.
%%
%% This source file is part of the Multimedia Layer for the BEAM project which
%% is released under the MIT license. Please refer to the LICENSE.txt file that
%% can be found at the root of the project directory.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>, December 2023
%%
-module(vertex2_test).
-include_lib("eunit/include/eunit.hrl").

vertex2_test() ->
    {
        {0.0, 0.0},
        {0.0, 0.0, 0.0, 1.0},
        0.0,
        0.0
    } = vertex2:new(),

    ok.
