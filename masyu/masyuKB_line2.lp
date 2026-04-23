#const n=10.
#const m=10.

col(1..m).
fila(1..n).

direc(h).
direc(v).

{seg(S,X,Y)} :- direc(S), fila(X), col(Y).

:- seg(h,X,m), fila(X).
:- seg(v,n,Y), col(Y).

circulo(X,Y) :- blanco(X,Y), fila(X), col(Y).
circulo(X,Y) :- negro(X,Y), fila(X), col(Y).

pasaPor(X,Y) :- seg(S,X,Y), fila(X), col(Y), direc(S).
pasaPor(X,Y+1) :- seg(h,X,Y), Y<m, fila(X), col(Y).
pasaPor(X+1,Y) :- seg(v,X,Y), X<n, fila(X), col(Y).

:- circulo(X,Y), not pasaPor(X,Y).