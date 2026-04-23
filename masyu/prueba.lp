through(1;2;3;4).
% Definimos un conjunto de valores que puede tomar choose
{ choose(Y) : through(Y) } 1 :- through(_).

% Si choose(Y) es verdadero, entonces Y es un valor válido de through
valid(Y) :- choose(Y), through(Y).

% Si no hay valores de choose, entonces no hay valores válidos de through
:- not valid(_).

#show choose/1.