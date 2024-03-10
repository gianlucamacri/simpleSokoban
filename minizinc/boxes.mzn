include "globals.mzn";

% INIT DATA --------------------------

int: boxNumber; % number of boxes
int: n;         % xs board limit
int: m;         % ys board limit
int: h;         % at the end no box can occupy a cell of height greater than h

% init data: boxes' side length, x and y position
array [BOXNUMS] of int: boxSideLen;
array [BOXNUMS] of XS: boxStartX;
array [BOXNUMS] of YS: boxStartY;


% PARAMS -----------------------------

% domains
set of int: XS = 1..n;
set of int: YS = 1..m;
set of int: BOXNUMS = 1..boxNumber;
set of int: EXTBOXNUMS = 0..boxNumber+1;
set of int: SIDELENGTHS = 1..max(boxSideLen);

enum DIRS = {U,R,L,D};

% index of a flying 'sokoban' who pushes the boxes around and for a phantom box
% that represents the free space where we push a box, we keep its data in boxes' variables
int: sokoban = 0;
int: spaceIndex = boxNumber+1;

% maximum time instance and associated interval
int: maxT;
set of int: MAXTIMEINT = 0..maxT;
set of int: MOVETIMEINT = 0..maxT-1;


% VARS -------------------------------

% for each time, for each box we save position of the box (lower-left corner)
array [MAXTIMEINT,EXTBOXNUMS] of var XS: boxesX;
array [MAXTIMEINT,EXTBOXNUMS] of var YS: boxesY;

% for each time (excluded the final one) we save what box we move and the direction
array [MOVETIMEINT] of var BOXNUMS: boxMoved;
array [MOVETIMEINT] of var DIRS: dirMoved;

array [MAXTIMEINT,EXTBOXNUMS] of var SIDELENGTHS: xExtBoxSideLen; %= array1d(0..boxNumber,[1] ++ boxSideLen);
array [MAXTIMEINT,EXTBOXNUMS] of var SIDELENGTHS: yExtBoxSideLen;


% UTILITIES --------------------------

% get new X and Y coord after a given move
function var XS: newBoxX(var XS:oldPos, var DIRS:dir) = 
  if     dir = R then oldPos+1
  elseif dir = L then oldPos-1
  else                oldPos    % dir = U \/ dir = D
  endif;

function var YS: newBoxY(var YS:oldPos, var DIRS:dir) = 
  if     dir = U then oldPos+1
  elseif dir = D then oldPos-1
  else                oldPos    % dir = R \/ dir = L
  endif;


% CONSTRAINTS ------------------------

% some constraints are not joined due to better observed performace

% no boundary overflow at start, then mantained performing only valid moves
constraint assert(forall(b in BOXNUMS)(boxStartX[b]+boxSideLen[b]-1 <= n /\ boxStartY[b]+boxSideLen[b]-1 <= m),"Some box is out of bonds.");

% box side lengths' consistency
constraint assert(forall(b in BOXNUMS)(boxSideLen[b] > 0), "Some box has non-positive side length.");

% "copy" values in extended arrays
constraint forall(t in MAXTIMEINT)(
  forall(b in BOXNUMS) (xExtBoxSideLen[t,b] = boxSideLen[b] /\ yExtBoxSideLen[t,b] = boxSideLen[b]) /\
  % sokoban simulated by a 1x1 box
  yExtBoxSideLen[t,sokoban] = 1 /\ xExtBoxSideLen[t,sokoban] = 1);

% init boxes' position
constraint forall(b in BOXNUMS)(boxesX[0,b] = boxStartX[b] /\
                                boxesY[0,b] = boxStartY[b]);

% there is a bit of redoundancy with the let expessions, but this seems more efficient in solving, probably due to separated constraints
% avoid moving boxes stuck to the wall, redoundant but seems to improve performances
constraint forall(t in MOVETIMEINT)(
  let {var DIRS: dir = dirMoved[t],
       var BOXNUMS: boxMov = boxMoved[t],
       var SIDELENGTHS: movedLen = boxSideLen[boxMov],
       var XS: movedX = boxesX[t,boxMov],
       var YS: movedY = boxesY[t,boxMov]}
  in
      if     dir = U \/ dir = D then movedY + movedLen <= m /\ movedY > 1
      else                           movedX + movedLen <= n /\ movedX > 1  % dir = L \/ dir = R
      endif);

% set phantom box's coords for the arrival position
constraint forall(t in MOVETIMEINT)
  (let {var DIRS: dir = dirMoved[t],
        var BOXNUMS: boxMov = boxMoved[t],
        var SIDELENGTHS: movedLen = boxSideLen[boxMov],
        var XS: movedX = boxesX[t,boxMov],
        var YS: movedY = boxesY[t,boxMov],}
  in
  if     dir = U then boxesX[t,spaceIndex] = movedX /\ boxesY[t,spaceIndex] = movedY+movedLen /\ xExtBoxSideLen[t,spaceIndex] = movedLen /\ yExtBoxSideLen[t,spaceIndex] = 1
  elseif dir = D then boxesX[t,spaceIndex] = movedX /\ boxesY[t,spaceIndex] = movedY-1 /\ xExtBoxSideLen[t,spaceIndex] = movedLen /\ yExtBoxSideLen[t,spaceIndex] = 1
  elseif dir = R then boxesX[t,spaceIndex] = movedX+movedLen /\ boxesY[t,spaceIndex] = movedY /\ xExtBoxSideLen[t,spaceIndex] = 1 /\ yExtBoxSideLen[t,spaceIndex] = movedLen
  else                boxesX[t,spaceIndex] = movedX-1 /\ boxesY[t,spaceIndex] = movedY /\ xExtBoxSideLen[t,spaceIndex] = 1 /\ yExtBoxSideLen[t,spaceIndex] = movedLen % dir = L
  endif);

% check that the sokoban is infact in a position from where he can push the moved box
constraint forall(t in MOVETIMEINT)(
  let {var DIRS: dir = dirMoved[t],
       var BOXNUMS: boxMov = boxMoved[t],
       var SIDELENGTHS: movedLen = boxSideLen[boxMov],
       var XS: movedX = boxesX[t,boxMov],
       var YS: movedY = boxesY[t,boxMov]}
  in 
      if     dir = U then boxesX[t,sokoban] >= movedX /\ boxesX[t,sokoban] < movedX+movedLen /\ boxesY[t,sokoban] = movedY-1
      elseif dir = D then boxesX[t,sokoban] >= movedX /\ boxesX[t,sokoban] < movedX+movedLen /\ boxesY[t,sokoban] = movedY+movedLen
      elseif dir = R then boxesX[t,sokoban] = movedX-1 /\ boxesY[t,sokoban] >= movedY /\ boxesY[t,sokoban] < movedY + movedLen
      else                boxesX[t,sokoban] = movedX+movedLen /\ boxesY[t,sokoban] >= movedY /\ boxesY[t,sokoban] < movedY + movedLen
      endif);

% no overlapping when moved, we introduce a phantom box one the arrival positions to exploit the global constaint diffn
constraint forall(t in MOVETIMEINT)(
  let {var DIRS: dir = dirMoved[t],
       var BOXNUMS: boxMov = boxMoved[t],
       var SIDELENGTHS: movedLen = boxSideLen[boxMov],
       var XS: movedX = boxesX[t,boxMov],
       var YS: movedY = boxesY[t,boxMov],}
  in
      if     dir = U then diffn(boxesX[t,EXTBOXNUMS], boxesY[t,EXTBOXNUMS], xExtBoxSideLen[t,EXTBOXNUMS], yExtBoxSideLen[t,EXTBOXNUMS])
      elseif dir = D then diffn(boxesX[t,EXTBOXNUMS], boxesY[t,EXTBOXNUMS], xExtBoxSideLen[t,EXTBOXNUMS], yExtBoxSideLen[t,EXTBOXNUMS])
      elseif dir = R then diffn(boxesX[t,EXTBOXNUMS], boxesY[t,EXTBOXNUMS], xExtBoxSideLen[t,EXTBOXNUMS], yExtBoxSideLen[t,EXTBOXNUMS])
      else                diffn(boxesX[t,EXTBOXNUMS], boxesY[t,EXTBOXNUMS], xExtBoxSideLen[t,EXTBOXNUMS], yExtBoxSideLen[t,EXTBOXNUMS])  % dir = L
      endif);

% no overlapping at the end
constraint diffn(boxesX[maxT,BOXNUMS], boxesY[maxT,BOXNUMS], boxSideLen, boxSideLen);

% inertia + move effect
constraint
  forall(t in MOVETIMEINT)(
    forall(b in BOXNUMS)(
      if boxMoved[t] = b
      then % move effect
        boxesX[t+1,b] = newBoxX(boxesX[t,b],dirMoved[t]) /\
        boxesY[t+1,b] = newBoxY(boxesY[t,b],dirMoved[t])  
      else % inertia
        boxesX[t+1,b] = boxesX[t,b] /\
        boxesY[t+1,b] = boxesY[t,b]      
      endif
      )
    );

% final constraints
% no box can occupy a position higher than h (as a row index)
constraint forall(b in BOXNUMS)( boxesY[maxT,b]+boxSideLen[b]-1 <= h);

%  fill by rows from left to right, from bottom to top
constraint
  let {var 1..m*n: maxPosVetex = max([ boxesX[maxT,b]+n*(boxesY[maxT,b]-1) | b in BOXNUMS])} in
    forall(x in XS, y in YS where x+n*(y-1)<=maxPosVetex)
      (exists(b in BOXNUMS)
        (x >= boxesX[maxT,b] /\ x < boxesX[maxT,b]+boxSideLen[b] /\
         y >= boxesY[maxT,b] /\ y < boxesY[maxT,b]+boxSideLen[b]) );


% OUTPUT AND SOLVING STATEGY ---------

output [ "\(boxMoved[t]) \(dirMoved[t]), " | t in MOVETIMEINT];

% human readable version
%output [ "(\(boxesX[t,b]),\(boxesY[t,b]))" ++ if b = boxNumber then (if t < maxT then " then move \(boxMoved[t]) \(dirMoved[t])\n" else "" endif) else "" endif | t in MAXTIMEINT, b in BOXNUMS];

solve satisfy;
