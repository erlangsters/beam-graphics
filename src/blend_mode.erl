%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(blend_mode).
-moduledoc """
To be written.

To be written.
""".

% XXX: Implement somethign similar to this ?
% sf::BlendMode::BlendMode 	( 	Factor 	sourceFactor,
% 		Factor 	destinationFactor,
% 		Equation 	blendEquation = Equation::Add )

% Construct the blend mode given the factors and equation.

% This constructor uses the same factors and equation for both color and alpha components. It also defaults to the Add equation.


-export_type([
    factor/0,
    equation/0
]).

-doc """
To be written.

To be written.
""".
-type factor() ::
    zero |
    one |
    src_color |
    one_minus_src_color |
    dst_color |
    one_minus_dst_color |
    src_alpha |
    one_minus_src_alpha |
    dst_alpha |
    one_minus_dst_alpha
.

-doc """
To be written.

To be written.
""".
-type equation() ::
    add |
    subtract |
    reverse_subtract |
    min |
    max
.
