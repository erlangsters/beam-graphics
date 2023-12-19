%%
%% Copyright (c) 2023, Byteplug LLC.
%%
%% This source file is part of the Multimedia Layer for the BEAM project which
%% is released under the MIT license. Please refer to the LICENSE.txt file that
%% can be found at the root of the project directory.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>, December 2023
%%
-module(box3).
-export([new/0]).

%%
%% The box3 module.
%%
%% To be written.
%%

%%
%% To be written.
%%
-spec new() -> bml:box3().
new() ->
    {
        vector3:new(),
        vector3:new()
    }.
