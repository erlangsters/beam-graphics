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
    color/0
]).

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
