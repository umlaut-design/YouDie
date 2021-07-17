procedure interference(dtab:pointer; p1,p2:Tpoint); //assembler;
type d=array[0..63999] of byte;
var zx,zy:word;

begin
for zx:=0 to 319 do
 for zy:=0 to 199 do
  IfBuf[zx+320*zy]:= lo(d(dTab^)[abs(zx-p1.x)+320*abs(zy-p1.y)]) xor
                     lo(d(dTab^)[abs(zx-p2.x)+320*abs(zy-p2.y)]);

end;