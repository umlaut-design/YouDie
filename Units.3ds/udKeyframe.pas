unit udKeyframe;

interface

type TKey=record
      frame:word;
      t,b,c:single;
      an,bn:single;
      v:single;
     end;

type TTrack=record
      numkey:byte;
      key:array[0..50] of Tkey;
     end;

const loop=false;

procedure udKeyInitVectors(var track:TTrack);
function udKeyGetVector(track:TTrack; sel,n:integer):single;
function udKeyHermite(p1,p2,r1,r2,t:single):single;
function udKeyGetPoint(track:TTrack; fr:word):single;

implementation

procedure udKeyInitVectors(var track:TTrack);
var y:byte;
begin
 for y:=0 to track.numkey-1 do
 begin
  track.key[y].an:=udKeyGetVector(track,0,y);
  track.key[y].bn:=udKeyGetVector(track,1,y);
 end;
end;

function udKeyGetVector(track:TTrack; sel,n:integer):single;
var kn_1,kn,kn1:Tkey;
    pn_1,pn,pn1:single;
    f,g1,g2:single;
begin

 kn:=track.key[n];
 pn:=kn.v;

 if sel=2 then
 begin
  udKeyGetVector:=pn;
  exit;
 end;

 if n=0 then
 begin
  kn1:=track.key[1];
  pn1:=kn1.v;

  if track.numkey=2 then
  begin
   udKeyGetVector:=(pn1-pn)*(1-kn.t);
   exit;
  end;

  if loop then
   kn_1:=track.key[track.numkey-2]
  else
  begin
   udKeyGetVector:=((pn1-pn)*1.5-udKeyGetVector(track,0,1)*0.5)*(1-kn.t);
   exit;
  end;

 end
 else
  if (n=track.numkey-1) then
  begin
   kn_1:=track.key[n-1];
   pn_1:=kn_1.v;

   if track.numkey=2 then begin
    udKeyGetVector:=(pn-pn_1)*(1-kn.t);
    exit;
   end;

   if loop then
    kn_1:=track.key[1]
   else
   begin
    udKeyGetVector:=((pn-pn_1)*1.5-udKeyGetVector(track,1,n-1)*0.5)*(1-kn.t);
    exit;
   end;

  end
  else
  begin
   kn_1:=track.key[n-1];
   kn1 :=track.key[n+1];
  end;

  pn_1:=kn_1.v;
  pn1 :=kn1.v;

  if (sel=0) then f:=0.5 else f:=-0.5;

  g1:=(pn  -pn_1)*(1+kn.b);
  g2:=(pn1 -pn  )*(1-kn.b);

  udKeyGetVector:=(g1+(g2-g1)*(0.5+f*kn.c))*(1-kn.t);


end;

function udKeyHermite(p1,p2,r1,r2,t:single):single;
begin
 udKeyHermite:=p1*( 2*(t*t*t)-3*(t*t)+1)+
               r1*(   (t*t*t)-2*(t*t)+t)+
               p2*(-2*(t*t*t)+3*(t*t)  )+
               r2*(   (t*t*t)-  (t*t)  );
end;

function udKeyGetPoint(track:TTrack; fr:word):single;
var x,y:byte;
begin

 if track.numkey=1 then udKeyGetPoint:=track.key[0].v
 else
 begin

  if (track.key[0].frame>fr) and (track.key[0].frame>0) then begin 
   udKeyGetPoint:=track.key[0].v;
   exit;
  end;

  y:=255;
//  for x:=1 to track.numkey do
  for x:=0 to track.numkey-1 do
   if (fr<=track.key[x].frame) and (y=255) then y:=x-1;

  if y=255 then begin 
   udKeyGetPoint:=track.key[track.numkey-1].v;
   exit;
  end;

  udKeyGetPoint:=udKeyHermite(track.key[y  ].v ,track.key[y+1].v,
                              track.key[y  ].an,track.key[y+1].bn,
                              (fr-track.key[y].frame)/(track.key[y+1].frame-track.key[y].frame));
 end;

end;

BEGIN
END.