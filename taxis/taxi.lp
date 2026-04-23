#program initial.

% Define taxis and passengers from initial positions
taxi(T) :- init_at(T,_,_).
passenger(P) :- init_person_at(P,_,_).

% Define all cells in the grid
cell(I,J) :- I=0..n-1, J=0..m-1, not building(I,J).

% Initial state
at(T,I,J) :- init_at(T,I,J).
person_at(P,I,J) :- init_person_at(P,I,J).
free(T) :- taxi(T).

#program dynamic.

%%%%%%%%%%% Inertia for taxi positions
at(T,I,J) :- 'at(T,I,J), not -at(T,I,J), _taxi(T).
-at(T,I,J) :- at(T,I2,J2), _cell(I,J), (I,J)!=(I2,J2), _taxi(T).

%%%%%%%%%%% Inertia for passenger positions - blocks inertia when inside taxi
% person_at(P,I,J) :- 'person_at(P,I,J), not -person_at(P,I,J), _passenger(P), _free(T), 'in(P,T).
% person_at(P,I,J) :- 'person_at(P,I,J), not -person_at(P,I,J), _passenger(P), not in(P,_).
% -person_at(P,I,J) :- person_at(P,I2,J2), _cell(I,J), (I,J)!=(I2,J2), _passenger(P).

% Alternative, explicit negation of passenger position when inside taxi
person_at(P,I,J) :- 'person_at(P,I,J), not -person_at(P,I,J), _passenger(P).
-person_at(P,I,J) :- person_at(P,I2,J2), _cell(I,J), (I,J)!=(I2,J2), _passenger(P).
-person_at(P,I,J) :- in(P,_), _cell(I,J).

%%%%%%%%%%% Inertia for passenger-taxi relationship
in(P,T) :- 'in(P,T), not -in(P,T).
-in(P,T) :- in(P,T2), T!=T2, _taxi(T).

%%%%%%%%%%% Free status - derived, not inertial
free(T) :- _taxi(T), not in(_,T).

% Inertial version for free status
% free(T) :- 'free(T), not -free(T).
% -free(T) :- in(_,T).
% Drop effects
% free(T) :- drop(T).

%%%%%%%%%%% Movement actions
{ move(T,u) } :- _taxi(T), 'at(T,I,J), _cell(I-1,J).
{ move(T,d) } :- _taxi(T), 'at(T,I,J), _cell(I+1,J).
{ move(T,l) } :- _taxi(T), 'at(T,I,J), _cell(I,J-1).
{ move(T,r) } :- _taxi(T), 'at(T,I,J), _cell(I,J+1).

% At most one move per taxi
:- move(T,D1), move(T,D2), D1!=D2.

% Update position after move
at(T,I-1,J) :- move(T,u), 'at(T,I,J).
at(T,I+1,J) :- move(T,d), 'at(T,I,J).
at(T,I,J-1) :- move(T,l), 'at(T,I,J).
at(T,I,J+1) :- move(T,r), 'at(T,I,J).

%%%%%%%%%%% Pick action
{ pick(T) } :- _taxi(T), 'at(T,I,J), 'person_at(P,I,J), 'free(T).

% At most one pick per taxi
:- pick(T1), pick(T2), T1!=T2, 'at(T1,I,J), 'at(T2,I,J).

% Effect of pick
in(P,T) :- pick(T), 'at(T,I,J), 'person_at(P,I,J).

%%%%%%%%%%% Drop action
{ drop(T) } :- _taxi(T), 'in(P,T).

% Effect of drop
person_at(P,I,J) :- drop(T), at(T,I,J), 'in(P,T).
-in(P,T) :- drop(T), 'in(P,T).

%%%%%%%%%%% Wait action
{ wait(T) } :- _taxi(T).

%%%%%%%%%%% Action exclusivity
action(T) :- move(T,_).
action(T) :- pick(T).
action(T) :- drop(T).
action(T) :- wait(T).

% Each taxi must do exactly one action
:- _taxi(T), not action(T).
:- _taxi(T), move(T,_), pick(T).
:- _taxi(T), move(T,_), drop(T).
:- _taxi(T), move(T,_), wait(T).
:- _taxi(T), pick(T), drop(T).
:- _taxi(T), pick(T), wait(T).
:- _taxi(T), drop(T), wait(T).

%%%%%%%%%%% Constraints

% Two taxis cannot be at the same cell
:- at(T1,I,J), at(T2,I,J), T1<T2.

% Two passengers cannot be at the same cell (outside or one in/one out)
:- person_at(P1,I,J), person_at(P2,I,J), P1<P2.
:- person_at(P1,I,J), at(T,I,J), in(P2,T), P1!=P2.
:- person_at(P,I,J), at(T,I,J), in(P,T).

% Prevent swapping positions
:- move(T1,u), move(T2,d), 'at(T1,I,J), 'at(T2,I-1,J).
:- move(T1,d), move(T2,u), 'at(T1,I,J), 'at(T2,I+1,J).
:- move(T1,l), move(T2,r), 'at(T1,I,J), 'at(T2,I,J-1).
:- move(T1,r), move(T2,l), 'at(T1,I,J), 'at(T2,I,J+1).

%%%%%%%%%%% OPTIMIZATIONS

% OPT 1: Cannot pick the same passenger that was just dropped
:- pick(T), 'drop(T).

% Or Cannot do wait immediately after picking and before dropping
% Sometimes this decreases number of taxi movements (dom03), but sometimes it increases it (dom02)
:- drop(T), 'wait(T), ''pick(T).

% OPT 2: Cannot return to the previous position
:- at(T,I,J), 'at(T,I2,J2), ''at(T,I,J), (I,J)!=(I2,J2).

% OPT 3: Empty taxi must wait if no passengers are outside
:- move(T,_), free(T), not person_at(_,_,_).

% Cannot move if all passengers outside are already at stations
:- move(T,_), free(T), { person_at(_,I,J) : not _station(I,J) } 0.

% Also person must not be the same as it was in the taxi in the previous step
:- move(T,_), free(T), not person_at(P,_,_), 'in(P,T).

% Or dropped by another taxi in this step
:- move(T,_), free(T), not 'person_at(_,_,_).

% OPT 4: Cannot pick a passenger that is already at a station
:- pick(T), 'at(T,I,J), 'person_at(P,I,J), _station(I,J).

% OPT 5: Cannot pick a passenger that was ever in this taxi before
% This increases grounding size (and time) significantly
% picked_before(P,T) :- 'picked_before(P,T).
% picked_before(P,T) :- pick(T), at(T,I,J), person_at(P,I,J).
% :- pick(T), at(T,I,J), person_at(P,I,J), picked_before(P,T).

% Using &tel to check if P was ever in T before (commented due a bit slower performance)
% :- pick(T), 'at(T,I,J), 'person_at(P,I,J), 
%    &tel { initially(in(P,T)) } ; 
%    &tel { <* in(P,T) }. % <* means "sometime in the past"

#program final.

% Goal: all passengers at stations and outside taxis
:- _passenger(P), in(P,_).
:- _passenger(P), not person_at(P,_,_).
:- _passenger(P), person_at(P,I,J), not _station(I,J).

#show move/2.
#show pick/1.
#show drop/1.
#show wait/1.