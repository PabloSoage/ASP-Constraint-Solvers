#const n=5.
#const m=10.

% Buildings
building(0,8).
building(1,1).
building(1,2).
building(1,3).
building(1,4).
building(1,6).
building(1,8).
building(2,4).
building(2,6).
building(2,8).
building(3,1).
building(3,2).
building(3,6).
building(3,8).
building(4,6).

% Stations
station(0,9).
station(2,9).
station(4,9).

% Initial taxi positions
init_at(3,0,2).
init_at(1,2,0).
init_at(2,2,5).

% Initial passenger positions
init_person_at(c,0,0).
init_person_at(b,2,2).
init_person_at(a,4,2).
