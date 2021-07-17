unit udMatrix;

interface

uses udVector,udQuat;

type Tmatrix=array[0..3,0..3] of single;
type Tmatrix3=array[0..2,0..2] of single;

function udMatrixMultiply(m1,m2:TMatrix):TMatrix;
function udMatrixMultiplyVector(m:TMatrix; v:Tvector):Tvector;
function udMatrixIdentity:TMatrix;
function udMatrixTranslatePos(m:TMatrix; viewer:Tvector):TMatrix;
function udMatrixTranslateRot(m:TMatrix; angle:Tvector):TMatrix;
function udMatrixTranslateScl(m:TMatrix; size:Tvector):TMatrix;
function udMatrixRoll(m:TMatrix; angle:single):TMatrix;
function udMatrixProject(point:Tvector; fov:single):Tpoint;
function udMatrixFromQuat(q:TQuat):TMatrix;
function udMatrixInvert3(m:TMatrix3):TMatrix3;
function udMatrixInvert(m:TMatrix):TMatrix;

implementation

function udMatrixMultiply(m1,m2:TMatrix):TMatrix;
var x,y:byte;
    a:TMatrix;
begin
 for x:=0 to 3 do
  for y:=0 to 3 do
   a[x,y]:=m1[x,0]*m2[0,y] + 
           m1[x,1]*m2[1,y] + 
           m1[x,2]*m2[2,y] + 
           m1[x,3]*m2[3,y];
 udMatrixMultiply:=a;
end;

function udMatrixMultiplyVector(m:TMatrix; u:Tvector):Tvector;
var x:Tvector;
begin

 x.x:=u.x*m[0,0] + u.y*m[1,0] + u.z*m[2,0] + m[3,0];
 x.y:=u.x*m[0,1] + u.y*m[1,1] + u.z*m[2,1] + m[3,1];
 x.z:=u.x*m[0,2] + u.y*m[1,2] + u.z*m[2,2] + m[3,2];

// x.x:=-x.x;

 udMatrixMultiplyVector:=x;
end;

function udMatrixIdentity:TMatrix;
var a:TMatrix;
    x:byte;
begin
 fillchar(a,sizeof(a),0);
 for x:=0 to 3 do a[x,x]:=1;
 udMatrixIdentity:=a;
end;

function udMatrixTranslatePos(m:TMatrix; viewer:Tvector):TMatrix;
var a:TMatrix;
begin
 a:=udMatrixIdentity;
 a[3,0]:=viewer.x;
 a[3,1]:=viewer.y;
 a[3,2]:=viewer.z;
 udMatrixTranslatePos:=udMatrixMultiply(m,a);
end;

function udMatrixTranslateRot(m:TMatrix; b:Tvector):TMatrix;
var a,x,y,z:TMatrix;
    angle:Tvector;
const c=0;
begin
 x:=udMatrixIdentity; y:=udMatrixIdentity; z:=udMatrixIdentity;
 angle.x:=-b.x;
 angle.y:=-b.y;
 angle.z:=-b.z;

 x[1,1]:= cos(angle.x+c);
 x[1,2]:= sin(angle.x+c);
 x[2,1]:=-sin(angle.x+c);
 x[2,2]:= cos(angle.x+c);

 y[0,0]:= cos(angle.y);  y[0,2]:=-sin(angle.y);  y[2,0]:= sin(angle.y);  y[2,2]:= cos(angle.y);
 z[0,0]:= cos(angle.z);  z[0,1]:= sin(angle.z);  z[1,0]:=-sin(angle.z);  z[1,1]:= cos(angle.z);

 a:=udMatrixMultiply(m,y); a:=udMatrixMultiply(a,x); a:=udMatrixMultiply(a,z);

 udMatrixTranslateRot:=a;
end;

function udMatrixTranslateScl(m:TMatrix; size:Tvector):TMatrix;
var a:TMatrix;
begin
 a:=udMatrixIdentity;

 a[0,0]:=size.x;
 a[1,1]:=size.y;
 a[2,2]:=size.z;

 udMatrixTranslateScl:=udMatrixMultiply(m,a);
end;

function udMatrixRoll(m:TMatrix; angle:single):TMatrix;
var a:TMatrix;
begin
 a:=udMatrixIdentity;
 a[0,0]:= cos(angle);
 a[0,1]:= sin(angle);  
 a[1,0]:=-sin(angle);  
 a[1,1]:= cos(angle);

 a:=udMatrixMultiply(m,a);

 udMatrixRoll:=a;
end;

function udMatrixProject(point:Tvector; fov:single):Tpoint;
var x:Tpoint;
begin
 x.x:=round((point.x*fov)/point.z+160);
 x.y:=round((point.y*fov)/point.z+100);
 udMatrixProject:=x;
end;

function udMatrixFromQuat(q:TQuat):TMatrix;
var m:TMatrix;
begin
  m:=udMatrixIdentity;
  {
     ( 1-2yy-2zz          2xy+2sz           2xz-2sy )
M =  (   2xy-2sz        1-2xx-2zz           2yz+2sx )
     (   2xz+2sy          2yz-2sx         1-2xx-2yy )
  }
  with q do
  begin
    with v do
    begin
     m[0,0]:=1-2*y*y-2*z*z; m[0,1]:=  2*x*y+2*s*z; m[0,2]:=  2*x*z-2*s*y;
     m[1,0]:=  2*x*y-2*s*z; m[1,1]:=1-2*x*x-2*z*z; m[1,2]:=  2*y*z+2*s*x;
     m[2,0]:=  2*x*z+2*s*y; m[2,1]:=  2*y*z-2*s*x; m[2,2]:=1-2*x*x-2*y*y;
    end;
  end;
  
  udMatrixFromQuat:=m;
 
end;

function udMatrixInvert3(m:TMatrix3):TMatrix3;
var i,j,k,l:byte;
    n:TMatrix3;
    d,e:single;
    function det(m:TMatrix3):single;
    begin
      det:=(m[0,0]*m[1,1]*m[2,2]+
            m[0,1]*m[1,2]*m[2,0]+
            m[0,2]*m[1,0]*m[2,1])-
           (m[0,2]*m[1,1]*m[2,0]+
            m[0,1]*m[1,0]*m[2,2]+
            m[0,0]*m[1,2]*m[2,1]);
    end;
begin
  for i:=0 to 2 do
    for j:=0 to 2 do
    begin
      d:=1; e:=1;
      for k:=0 to 2 do
        for l:=0 to 2 do
          if (i<>k) and (j<>l) then
            if (k=l) then d:=d*m[k,l] else e:=e*m[k,l];
      d:=d-e;
          
      n[i,j]:=m[i,j]*(d/det(m));
      if ((i-j) mod 2)<>0 then n[i,j]:=-n[i,j];
      
    end;
  writeln(det(m));
  udMatrixInvert3:=n;
end;

function udMatrixInvert(m:TMatrix):TMatrix;
var i,j:byte;
    n:TMatrix;
    d:single;
    f:array[0..8] of single;

    function hdet:single;
    begin
      hdet:=(f[0]*f[4]*f[8]+
             f[1]*f[5]*f[6]+
             f[2]*f[3]*f[7])-
            (f[2]*f[4]*f[6]+
             f[1]*f[3]*f[8]+
             f[0]*f[5]*f[7]);
    end;

    function aldet(q,r:byte):single;
    var h,k,l:byte;
    begin
      h:=0;
      for k:=0 to 3 do
        for l:=0 to 3 do
          if (q<>k) and (r<>l) then
          begin
            f[h]:=m[k,l];
            inc(h);
          end;
       if ((q+r) mod 2)=0 then
        aldet:= hdet
       else
        aldet:=-hdet;
    end;

    function det:single;
    var s:single;
        k:byte;
    begin
      s:=0;
      for k:=0 to 3 do
        s:=s+m[k,0]*aldet(k,0);
         
      det:=s;
    end;
        
begin
  d:=det;
  for i:=0 to 3 do
    for j:=0 to 3 do
      n[j,i]:=aldet(i,j)/d;

  udMatrixInvert:=n;
end;

BEGIN END.
