% pos(X) donde X representa la posición de la celda en la cuadrícula
pos(0..N) :- N = n*n-1.

% Generación de los posibles segmentos posibles seg(X1,X2)
dif_col(X1,X2) :- X1 != X2, X1/n = X2/n, X1\n + 1 = X2\n, pos(X1), pos(X2).
dif_row(X1,X2) :- X1 != X2, X1/n + 1 = X2/n, X1\n = X2\n, pos(X1), pos(X2).
{seg(X1,X2)} :- pos(X1), pos(X2), 1{dif_col(X1,X2);dif_row(X1,X2)}1.

% ball(X) se verifica si la celda X contiene un círculo blanco o negro
ball(X) :- 1{black(X);white(X)}, pos(X).

% La línea solución debe pasar por todos los círculos
through(X) :- 2 {seg(X,_);seg(_,X)} 2, pos(X).

:- ball(X), not through(X).

% Regla 1: La línea solución debe formar un único camino cerrado que entra y sale de cada celda que atraviesa una única vez
:- seg(X,_), not through(X).
:- seg(_,X), not through(X).

% Ademas se debe pintar una unica linea solucion, de forma que si esta pasa por dos celdas, se puede llegar de una a otra recorriendola
val(M) :- #min{X:white(X)} = M.
val(M) :- not white(_),#min{X:black(X)} = M.
val(M) :- not white(_),not black(_),#min{X:through(X)} = M.

reachable(X) :- 1{seg(X,M);seg(M,X)}, pos(X), val(M).
reachable(X) :- 1{seg(X,X1);seg(X1,X)}, reachable(X1), pos(X), pos(X1), X!=X1.
:- through(X), not reachable(X).

%Regla 2: Al llegar a un circulo blanco, debo seguir en línea recta
:- seg(X,X+1), white(X), not seg(X-1,X), pos(X).
:- seg(X-1,X), white(X), not seg(X,X+1), pos(X).

:- seg(X,X+n), white(X), not seg(X-n,X), pos(X).
:- seg(X-n,X), white(X), not seg(X,X+n), pos(X).

% Además, en la posicion anterior o posterior (o ambas) debe haber un giro
% vertical
:- white(X), seg(Z,X-n), seg(X-n,X), %*seg(X,X+n),*% seg(X+n,Y), Z!= X, Z!=Y, X!=Y, Z+n = X-n, Y-n = X+n, pos(Z), pos(X), pos(Y).
% horizontal
:- white(X), seg(Z,X-1), seg(X-1,X), %*seg(X,X+1),*% seg(X+1,Y), Z!= X, Z!=Y, X!=Y, Z+1 = X-1, Y-1 = X+1, pos(Z), pos(X), pos(Y).

% Regla 3: Al llegar a una bola negra, tengo que girar
:- seg(X,X+1), black(X), seg(X-1,X), pos(X).
:- seg(X,X+n), black(X), seg(X-n,X), pos(X).

% Además, en la posicion anterior y posterior, no puede haber un giro
% vertical
:- black(X), seg(X-n,X), 1{seg(Z,X-n);seg(X-n,Z)}, Z!=X, Z\n != X\n, pos(Z), pos(X).
:- black(X), seg(X,X+n), 1{seg(X+n,Y);seg(Y,X+n)}, X!=Y, Y\n != X\n, pos(X), pos(Y).

% horizontal
:- black(X), seg(X-1,X), 1{seg(Z,X-1);seg(X-1,Z)}, Z!= X, Z/n != X/n, pos(Z), pos(X).
:- black(X), seg(X,X+1), 1{seg(X+1,Y);seg(Y,X+1)}, X!=Y, Y/n != X/n, pos(X), pos(Y).

#show seg/2.