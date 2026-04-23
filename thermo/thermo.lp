% Define valid positions
pos(X,Y) :- thermo(_,X,Y,_).

% Each cell of a thermometer can be filled or empty
{fill(X,Y)} :- thermo(_,X,Y,_).

% Main rule: If a cell is filled, all preceding cells 
% (closer to the bulb) must also be filled
:- thermo(T,X,Y,Pos), fill(X,Y), thermo(T,X2,Y2,Pos2), Pos2 < Pos, not fill(X2,Y2).

% Count filled cells per column
col_count(C,N) :- col_target(C,_), N = #count{X : fill(X,C)}.

% Count filled cells per row
row_count(R,N) :- row_target(R,_), N = #count{Y : fill(R,Y)}.

% Constraint: The number of filled cells in each column must match
:- col_target(C,T), col_count(C,N), T != N.

% Constraint: The number of filled cells in each row must match
:- row_target(R,T), row_count(R,N), T != N.

#show fill/2.
#show dim/1.