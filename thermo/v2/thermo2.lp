% Define valid positions
pos(Z) :- thermo(_,Z,_).

% Each cell of a thermometer can be filled or empty
{fill(Z)} :- thermo(_,Z,_).

% Main rule: If a cell is filled, all preceding cells must also be filled
:- thermo(T,Z,Pos), fill(Z), thermo(T,Z2,Pos2), Pos2 < Pos, not fill(Z2).

% Count filled cells per column
col_count(C,N) :- col_target(C,_), N = #count{Z : fill(Z), Z\n = C}.

% Count filled cells per row  
row_count(R,N) :- row_target(R,_), N = #count{Z : fill(Z), Z/n = R}.

% Constraints
:- col_target(C,T), col_count(C,N), T != N.
:- row_target(R,T), row_count(R,N), T != N.

#show fill/1.
#show dim/1.