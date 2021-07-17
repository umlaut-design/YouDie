unit udQuat;

interface

uses udVector, math, debug;

type TQuat=record
      s:single;
      v:Tvector;
     end;

type TAngleAxis=record
      angle:single;
      axis:Tvector;
     end;

type TQKey=record
      frame:word;
      t,b,c:single;
      an,bn:TQuat;
      q:TQuat;
     end;

type TQTrack=record
      numkey:byte;
      key:array[0..50] of TQkey;
     end;

const qloop=false;

function Quat(s:single; v:Tvector):TQuat;
function AngleAxis(s:single; v:Tvector):TAngleAxis;
function Angle2Quat(aa:TAngleAxis):TQuat;
function Quat2Angle(q:TQuat):TAngleAxis;
function udQuatAdd(q1,q2:TQuat):TQuat;
function udQuatMultiply(q1,q2:TQuat):TQuat;
function udQuatMulScalar(q1:TQuat; a:single):TQuat;
function udQuatNormalize(q:TQuat):TQuat;
function udQuatDotProduct(q1,q2:TQuat):single;
function udQuatSlerp(q1,q2:TQuat; t:single):TQuat;
function udQuatKeyGetQuat(track:TQTrack; sel,n:integer):TQuat;
procedure udQuatKeyInit(var track:TQTrack);
function udQuatKeyInterp(track:TQTrack; n:word; t:single):TQuat;
function udQuatKeyGet(track:TQTrack; fr:word):TQuat;
     
implementation

function Quat(s:single; v:Tvector):TQuat;
var q:TQuat;
begin
  q.s:=s;
  q.v:=v;
  Quat:=q;
end;

function AngleAxis(s:single; v:Tvector):TAngleAxis;
var aa:TAngleAxis;
begin
  aa.angle:=s;
  aa.axis:=v;
  AngleAxis:=aa;
end;

function Angle2Quat(aa:TAngleAxis):TQuat;
var q:TQuat;
begin
  q.s := cos(aa.angle/2.0);
  q.v := udVectorMulScalar(aa.axis,sin(aa.angle/2.0));
  Angle2Quat:=q;
end;

function Quat2Angle(q:TQuat):TAngleAxis;
var aa:TAngleAxis;
begin
  aa.angle:=2*arccos(q.s);
  aa.axis :=udVectorMulScalar(q.v, 1/(sqrt(1-(q.s*q.s))) );
  Quat2Angle:=aa;
end;

function udQuatAdd(q1,q2:TQuat):TQuat;
var q:TQuat;
begin
	q.s   := q1.s  +q2.s  ;
	q.v.x := q1.v.x+q2.v.x;
	q.v.y := q1.v.y+q2.v.y;
	q.v.z := q1.v.z+q2.v.z;
  udQuatAdd:=q;
end;

function udQuatMultiply(q1,q2:TQuat):TQuat;
var q:TQuat;
begin
	q.s   := q1.s*q2.s   - q1.v.x*q2.v.x - q1.v.y*q2.v.y - q1.v.z*q2.v.z;
	q.v.x := q1.s*q2.v.x + q1.v.x*q2.s   + q1.v.y*q2.v.z - q1.v.z*q2.v.y;
	q.v.y := q1.s*q2.v.y + q1.v.y*q2.s   + q1.v.z*q2.v.x - q1.v.x*q2.v.z;
	q.v.z := q1.s*q2.v.z + q1.v.z*q2.s   + q1.v.x*q2.v.y - q1.v.y*q2.v.x;
  udQuatMultiply:=q;
end;

function udQuatMulScalar(q1:TQuat; a:single):TQuat;
var q:TQuat;
begin
	q.s   := q1.s  *a;
	q.v.x := q1.v.x*a;
	q.v.y := q1.v.y*a;
	q.v.z := q1.v.z*a;
  udQuatMulScalar:=q;
end;

function udQuatNormalize(q:TQuat):TQuat;
var d:single;
begin
	d:=sqrt(q.v.x*q.v.x + q.v.y*q.v.y + q.v.z*q.v.z + q.s*q.s);
	if d=0 then d:=1;
  udQuatNormalize:=udQuatMulScalar(q,1/d);
end;

function udQuatDotProduct(q1,q2:TQuat):single;
begin
	udQuatDotProduct:=(q1.s  *q2.s)+
	                  (q1.v.x*q2.v.x)+
	                  (q1.v.y*q2.v.y)+
	                  (q1.v.z*q2.v.z);
end;
  
function udQuatSlerp(q1,q2:TQuat; t:single):TQuat;
var a,c1,c2:single;
begin
  a:=udQuatDotProduct(q1,q2);

       if a<=-0.9 then a:=pi
  else if a>= 1.0 then a:=0
  else                 a:=arccos(a);

  if a<1 then begin
    c1:=1-t;
    c2:=t;
  end
  else begin
    c1:=sin((1-t)*a)/sin(a); 
    c2:=sin(   t *a)/sin(a);
  end;
  
  udQuatSlerp:=udQuatNormalize( 
               udQuatAdd(udQuatMulScalar(q1,c1) ,
                         udQuatMulScalar(q2,c2) ) );
end;

procedure udQuatKeyInit(var track:TQTrack);
var y:byte;
begin
 for y:=0 to track.numkey-1 do
 begin
  track.key[y].an:=udQuatKeyGetQuat(track,0,y);
  track.key[y].bn:=udQuatKeyGetQuat(track,1,y);
 end;
end;

function udQuatKeyGetQuat(track:TQTrack; sel,n:integer):TQuat;
var kn_1,kn,kn1:TQKey;
    qn_1,qn,qn1,g1,g2:TQuat;
    f:single;

begin
  kn:=track.key[n];
  qn:=kn.q;

  if sel=2 then
  begin
    udQuatKeyGetQuat:=qn;
    exit;
  end;

  if (n = 0) then
  begin
    kn1:=track.key[1];
    qn1:=kn1.q;

    if not qloop or (track.numkey<=2) then
    begin
      udQuatKeyGetQuat:=udQuatSlerp(qn,qn1,(1-kn.t)*(1+kn.c*kn.b)/3);
      exit;
    end
    else
      kn_1:=track.key[track.numkey-2];

  end
  else
   if (n=track.numkey-1) then
   begin
    kn_1:=track.key[n-1];
    qn_1:=kn_1.q;

    if not qloop or (track.numkey<=2) then
    begin
      udQuatKeyGetQuat:=udQuatSlerp(qn,qn_1,(1-kn.t)*(1-kn.c*kn.b)/3);
      exit;
    end
    else
      kn1:=track.key[1];
      
   end
   else 
   begin
    kn_1:=track.key[n-1];
    kn1 :=track.key[n+1];
   end;
   
  qn_1:=kn_1.q;
  qn1 :=kn1 .q;

  if (sel=0) then f:=1.0 else f:=-1.0;

  g1 := udQuatSlerp(qn,qn_1,-(1+kn.b)/3);
  g2 := udQuatSlerp(qn,qn1 , (1-kn.b)/3);

  udQuatKeyGetQuat:=udQuatSlerp(qn, udQuatSlerp(g1,g2,0.5+f*0.5*kn.c) ,f*(kn.t-1));
  
end;

function udQuatKeyInterp(track:TQTrack; n:word; t:single):TQuat;
var q0,q1,q2:Tquat;
begin
  q0:=udQuatSlerp(track.key[n  ].q ,track.key[n  ].bn,t);
  q1:=udQuatSlerp(track.key[n  ].bn,track.key[n+1].an,t);
  q2:=udQuatSlerp(track.key[n+1].an,track.key[n+1].q ,t);
  
  q0:=udQuatSlerp(q0,q1,t);
  q1:=udQuatSlerp(q1,q2,t);
  
  udQuatKeyInterp:=udQuatSlerp(q0,q1,t);
end;

function udQuatKeyGet(track:TQTrack; fr:word):TQuat;
var x,y:byte;
begin

 if track.numkey=1 then udQuatKeyGet:=track.key[0].q
 else
 begin

  if (track.key[0].frame>fr) and (track.key[0].frame>0) then
  begin 
   udQuatKeyGet:=track.key[0].q;
   exit;
  end;

  y:=255;
  for x:=0 to track.numkey-1 do
   if (fr<=track.key[x].frame) and (y=255) then y:=x-1;

  if y=255 then begin 
   udQuatKeyGet:=track.key[track.numkey-1].q;
   exit;
  end;

  udQuatKeyGet:=udQuatKeyInterp(track,
                                y,
                                (fr-track.key[y].frame)/(track.key[y+1].frame-track.key[y].frame));
 end;

end;


BEGIN
END.