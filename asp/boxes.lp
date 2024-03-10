% domains
xNum(1..n).
yNum(1..m).

time(0..t).

% up, down, left, right (n was already used, so use different names)
direction(u).
direction(d).
direction(l).
direction(r).

% to print these infos in output, usefull if we need to visualize the solution
boardX(n).
boardY(m).

board(X,Y) :- xNum(X), yNum(Y).

boxLenOffset(L,0..L-1) :- box(_,L).

boardVal(1..n*m).

% retrieve data from init configuration
box(B,L) :- boxInit(B,L,_,_).

boxPos(B,L,X,Y,0) :- boxInit(B,L,X,Y), board(X,Y).

% avoid instance inconsistencies
:- box(B,L1), box(B,L2), L1 < L2.

% each box must be at a certain position at some time
1{boxPos(B,L,X,Y,T):board(X,Y)}1 :- box(B,L), time(T).

% no boxes outside board at start
:- not board(Xb+L-1,Yb+L-1), boxPos(B,L,Xb,Yb,0).
:- not board(Xb,Yb), boxPos(B,L,Xb,Yb,0), box(B,L).

% occupation during time
occupied(X,Y,B,T) :- X = Xb + Ox, Y = Yb + Oy,
                     boxLenOffset(L,Ox),boxLenOffset(L,Oy),
                     boxPos(B,L,Xb,Yb,T), board(X,Y), time(T).

% no box overlapping
:- occupied(X,Y,B1,T), occupied(X,Y,B2,T), B1<B2, time(T), box(B1,_), box(B2,_), board(X,Y). 

% check is a box touches the wall on a given direction
wallContact(B,r,T) :- X+L-1 = n, boxPos(B,L,X,Y,T),
                    box(B,L), board(X,Y), time(T).

wallContact(B,l,T) :- X = 1, boxPos(B,L,X,Y,T),
                    box(B,L), board(X,Y), time(T).

wallContact(B,d,T) :- Y = 1, boxPos(B,L,X,Y,T),
                    box(B,L), board(X,Y), time(T).

wallContact(B,u,T) :- Y+L-1 = m, boxPos(B,L,X,Y,T),
                    box(B,L), board(X,Y), time(T).

% is there at least one position not occupied to push the box B at time T ?
freeBack(B,u,T) :-  not occupied(Xb,Yb,_,T),
                    Xb = X + Ox, boxLenOffset(L,Ox),
                    Yb = Y-1,
                    board(Xb,Yb),board(X,Y),
                    boxPos(B,L,X,Y,T), time(T).

freeBack(B,d,T) :-  not occupied(Xb,Yb,_,T),
                    Xb = X + Ox, boxLenOffset(L,Ox),
                    Yb = Y+L,
                    board(Xb,Yb),board(X,Y),
                    boxPos(B,L,X,Y,T), time(T).

freeBack(B,l,T) :-  not occupied(Xb,Yb,_,T),
                    Xb = X+L,
                    Yb = Y + Oy, boxLenOffset(L,Oy),
                    board(Xb,Yb),board(X,Y),
                    boxPos(B,L,X,Y,T), time(T).

freeBack(B,r,T) :-  not occupied(Xb,Yb,_,T),
                    Xb = X-1,
                    Yb = Y + Oy, boxLenOffset(L,Oy),
                    board(Xb,Yb),board(X,Y),
                    boxPos(B,L,X,Y,T), time(T).

% check that we can push a certain box, will guarantee move correctness with the non- overlapping constraint
canBeMoved(B,D,T) :- not wallContact(B,D,T), freeBack(B,D,T),
                     box(B,_), direction(D), time(T).

1{move(B,D,T):box(B,_),direction(D)}1 :- time(T), T<t.

% avoid illegal moves
:- move(B,D,T), not canBeMoved(B,D,T), box(B,_), direction(D), time(T).

% move effect
boxPos(B,L,X,Y1,T1):- boxPos(B,L,X,Y,T), move(B,u,T), box(B,_), time(T), time(T1), T1=T+1, board(X,Y1), board(X,Y), Y1=Y+1.
boxPos(B,L,X,Y1,T1):- boxPos(B,L,X,Y,T), move(B,d,T), box(B,_), time(T), time(T1), T1=T+1, board(X,Y1), board(X,Y), Y1=Y-1.
boxPos(B,L,X1,Y,T1):- boxPos(B,L,X,Y,T), move(B,l,T), box(B,_), time(T), time(T1), T1=T+1, board(X1,Y), board(X,Y), X1=X-1.
boxPos(B,L,X1,Y,T1):- boxPos(B,L,X,Y,T), move(B,r,T), box(B,_), time(T), time(T1), T1=T+1, board(X1,Y), board(X,Y), X1=X+1.

% check if a box is moved at a certain time
isMoved(B,T) :- move(B,_,T), box(B,_), time(T).

% inertia
boxPos(B,L,X,Y,T+1) :- not isMoved(B,T), boxPos(B,L,X,Y,T), time(T), board(X,Y), T<t.

occupied(X,Y,B,T+1) :- not isMoved(B,T), occupied(X,Y,B,T), time(T), board(X,Y), T<t.

% final constraints
:- occupied(_,Y,_,t), Y>h.

finalPos(B,L,X,Y) :- boxPos(B,L,X,Y,t).

finalOccupiedVal(V) :- V=(Y-1)*n+X, occupied(X,Y,_,t).

maxFinalVertexVal(Vmax) :- Vmax = #max{(Y-1)*n+X: finalPos(_,_,X,Y)}.

:- maxFinalVertexVal(Vmax), boardVal(V), V<Vmax, not finalOccupiedVal(V).

#show boardX/1.
#show boardY/1.
#show move/3.
#show finalPos/4.













