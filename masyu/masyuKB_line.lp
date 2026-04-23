#const n=10.
%black(0;12;26).
%white(10;13;22;23;31;34).

white(1,3). black(1,6). black(3,1). black(3,4). white(3,5).
black(3,8). white(3,10). white(4,7). black(5,3). black(5,8).
white(5,9). white(5,10). white(6,6). white(7,2). white(7,4).
white(7,7). white(7,8). white(8,2). white(8,5). black(9,9).
black(10,1). white(10,3). white(10,6).


%seg(N,M)
% Definición de la cuadrícula
col(1..n).
row(1..n).
direction(v;h).

% Generate a set of unit segments passing through cells
{line(S,X,Y)} :- direction(S), col(X), row(Y).
:- line(h,n,Y), row(Y).
:- line(v,X,n), col(X).
% including balls:
:- ball(X,Y), not on(X,Y).
ball(X,Y) :- black(X,Y), col(X), row(Y).
ball(X,Y) :- white(X,Y), col(X), row(Y).
on(X,Y) :- line(S,X,Y), direction(S), col(X), row(Y).
on(X+1,Y) :- line(h,X,Y), col(X), row(Y), X<n.
on(X,Y+1) :- line(v,X,Y), col(X), row(Y), Y<n.

% Asegurar las restricciones M1--M3

% M1:
% Cada celda por la que pasa la línea generada está conectada exactamente a 2 celdas de la cuadrícula
:- 3 { line(h,X-1,Y); line(h,X,Y); line(v,X,Y); line(v,X,Y-1) }, on(X,Y), col(X), row(Y).
:- { line(h,X-1,Y); line(h,X,Y); line(v,X,Y); line(v,X,Y-1) } 1, on(X,Y), col(X), row(Y).

% Además, cada celda en la línea generada es alcanzable desde otras celdas de la cuadrícula en la línea
:- on(X,Y), on(Z,W), not reachable(X,Y,Z,W), col(X;Z), row(Y;W).

adj(X,Y,X,Y+1) :- line(v,X,Y), col(X), row(Y), Y<n.
adj(X,Y,X+1,Y) :- line(h,X,Y), col(X), row(Y), X<n.
adj(X,Y,Z,W) :- adj(Z,W,X,Y), col(X;Z), row(Y;W).

reachable(X,Y,X,Y) :- on(X,Y), col(X;Z), row(Y;W).
reachable(X,Y,Z,W) :- reachable(I,J,Z,W), adj(X,Y,I,J), col(X;I;Z), row(Y;J;W).

% M3:
% El bucle debe girar (90 grados) en círculos negros
:- black(X,Y), line(h,X,Y), line(h,X-1,Y), col(X), row(Y).
:- black(X,Y), line(v,X,Y), line(v,X,Y-1), col(X), row(Y).
% Pero debe viajar recto a través de las celdas siguiente y anterior en su camino
:- 1 { line(v,X+1,Y); line(v,X+1,Y-1) }, black(X,Y), line(h,X,Y), col(X), row(Y).
:- 1 { line(v,X-1,Y); line(v,X-1,Y-1) }, black(X,Y), line(h,X-1,Y), col(X),row(Y).
:- 1 { line(h,X,Y+1); line(h,X-1,Y+1) }, black(X,Y), line(v,X,Y), col(X), row(Y).
:- 1 { line(h,X,Y-1); line(h,X-1,Y-1) }, black(X,Y), line(v,X,Y-1), col(X), row(Y).

% M2:
% Los círculos blancos deben ser atravesados rectos
:- 1 { line(v,X,Y); line(v,X,Y-1) }, 1 { line(h,X,Y); line(h,X-1,Y) }, white(X,Y), col(X), row(Y).
% Pero el bucle debe girar (90 grados) en la celda anterior y/o siguiente en su camino
:- white(X,Y), line(h,X,Y), line(h,X+1,Y), line(h,X-1,Y), line(h,X-2,Y), col(X), row(Y).
:- white(X,Y), line(v,X,Y), line(v,X,Y+1), line(v,X,Y-1), line(v,X,Y-2), col(X), row(Y).

% Mostrar segmentos
#show line/3.