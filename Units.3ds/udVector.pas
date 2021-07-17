unit udVector;

interface

type Tvector=record
      x,y,z:single;
     end;

type Tpoint=record
      x,y:longint;
     end;

function Vector(x,y,z:single):TVector;
function udVectorEqual(v1,v2:Tvector):boolean;
function udVectorDiff(v1,v2:Tvector):Tvector;
function udVectorDotProd(v1,v2:Tvector):single;
function udVectorCrossProd(v1,v2:Tvector):Tvector;
function udVectorNormalize(v:Tvector):Tvector;
function udVectorNegative(v:Tvector):Tvector;
function udVectorMulScalar(v:Tvector; s:single):Tvector;
function udVectorAdd(v1,v2:Tvector):Tvector;

implementation

function Vector(x,y,z:single):TVector;
var v:Tvector;
begin
 v.x:=x; v.y:=y; v.z:=z;
 Vector:=v;
end;

function udVectorEqual(v1,v2:Tvector):boolean;
begin
  udVectorEqual:=(v1.x=v2.x) and (v1.y=v2.y) and (v1.z=v2.z);
end;

function udVectorDotProd(v1,v2:Tvector):single;
begin
 udVectorDotProd:=v1.x * v2.x +
                  v1.y * v2.y +
                  v1.z * v2.z;
end;

function udVectorDiff(v1,v2:Tvector):Tvector;
var v:Tvector;
begin
 v.x:=v1.x - v2.x;
 v.y:=v1.y - v2.y;
 v.z:=v1.z - v2.z;
 udVectorDiff:=v;
end;

function udVectorCrossProd(v1,v2:Tvector):Tvector;
var v:Tvector;
begin
 v.x:=v1.y * v2.z - v1.z * v2.y;
 v.y:=v1.z * v2.x - v1.x * v2.z;
 v.z:=v1.x * v2.y - v1.y * v2.x;
 udVectorCrossProd:=v;
end;

function udVectorNormalize(v:Tvector):Tvector;
var u:Tvector;
    l:single;
begin
 l:=sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
 u.x:=v.x/l;
 u.y:=v.y/l;
 u.z:=v.z/l;
 udVectorNormalize:=u;
end;

function udVectorNegative(v:Tvector):Tvector;
var u:Tvector;
begin
 u.x:=-v.x;
 u.y:=-v.y;
 u.z:=-v.z;
 udVectorNegative:=u;
end;

function udVectorMulScalar(v:Tvector; s:single):Tvector;
var u:Tvector;
begin
 u.x:=v.x*s;
 u.y:=v.y*s;
 u.z:=v.z*s;
 udVectorMulScalar:=u;
end;

function udVectorAdd(v1,v2:Tvector):Tvector;
var u:Tvector;
begin
 u.x:=v1.x+v2.x;
 u.y:=v1.y+v2.y;
 u.z:=v1.z+v2.z;
 udVectorAdd:=u;
end;

BEGIN END.