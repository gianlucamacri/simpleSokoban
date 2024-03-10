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


% finalT will be the actual final time that we try to minimize
var MAXTIMEINT: finalT;
var set of int: USEDTIME = 0..finalT;
var set of int: MOVETIMEINT = 0..finalT-1;
var set of int: UNUSEDTIME = finalT+1..maxT;

% VARS -------------------------------

% for each time, for each box we save position of the box (lower-left corner)
array [MAXTIMEINT,EXTBOXNUMS] of var XS: boxesX;
array [MAXTIMEINT,EXTBOXNUMS] of var YS: boxesY;

% for each time (excluded the final one) we save what box we move and the direction
array [0..maxT-1] of var BOXNUMS: boxMoved;
array [0..maxT-1] of var DIRS: dirMoved;

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

% symmetry break for unused time
% arbitrary displacement
constraint forall(t in UNUSEDTIME)(
  forall(b in EXTBOXNUMS)(boxesX[t,b]=1 /\ boxesY[t,b]=1));

% special boxes' side lengths
constraint forall(t in finalT..maxT)
  (xExtBoxSideLen[t,spaceIndex] = 1 /\ yExtBoxSideLen[t,spaceIndex] = 1);

% fake moves
constraint forall(t in UNUSEDTIME where t < maxT)(
  boxMoved[t] = 1 /\
  dirMoved[t] = U
);

% "copy" values in extended arrays
constraint forall(t in MAXTIMEINT)(
  forall(b in BOXNUMS) (xExtBoxSideLen[t,b] = boxSideLen[b] /\ yExtBoxSideLen[t,b] = boxSideLen[b]) /\
  % sokoban simulated by a 1x1 box
  yExtBoxSideLen[t,sokoban] = 1 /\ xExtBoxSideLen[t,sokoban] = 1);

% init boxes' position
constraint forall(b in BOXNUMS)(boxesX[0,b] = boxStartX[b] /\
                                boxesY[0,b] = boxStartY[b]);

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
constraint
  forall(t in MAXTIMEINT where t = finalT)
  (diffn(boxesX[t,BOXNUMS], boxesY[t,BOXNUMS], boxSideLen, boxSideLen));

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
constraint forall(b in BOXNUMS)( boxesY[finalT,b]+boxSideLen[b]-1 <= h);

%  fill by rows from left to right, from bottom to top
constraint
  let {var 1..m*n: maxPosVetex = max([ boxesX[finalT,b]+n*(boxesY[finalT,b]-1) | b in BOXNUMS])} in
    forall(x in XS, y in YS where x+n*(y-1)<=maxPosVetex)
      (exists(b in BOXNUMS)
        (x >= boxesX[finalT,b] /\ x < boxesX[finalT,b]+boxSideLen[b] /\
         y >= boxesY[finalT,b] /\ y < boxesY[finalT,b]+boxSideLen[b]) );


% OUTPUT AND SOLVING STATEGY ---------

output [ "\(boxMoved[t]) \(dirMoved[t]), " | t in 0..fix(finalT)-1];
output [ "\nfinal time: \(finalT)" ];

% human readable version
%output [ "(\(boxesX[t,b]),\(boxesY[t,b]))" ++ if b = boxNumber then (if t < maxT then " then move \(boxMoved[t]) \(dirMoved[t])\n" else "" endif) else "" endif | t in MAXTIMEINT, b in BOXNUMS];


solve
:: int_search([finalT]++boxMoved++dirMoved, 
input_order, 
%dom_w_deg,
%first_fail,
%most_constrained,
indomain_min,
% indomain_random, 
complete)
minimize finalT;
