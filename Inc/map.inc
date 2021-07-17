procedure map(kep:pointer; a,b,z:byte);
var x,y:word;
    px,py:integer;
    map:array[0..(320*200)-1] of byte;
begin
 for y:=0 to 199 do
  for x:=0 to 319 do
   map[x+y*320]:=( sinm[byte((x-a)*sinm[z] shr 4)]+sinm[byte((y-b)*sinm[z] shr 4)] ) shr 1;

 for y:=0 to 198 do
  for x:=0 to 318 do
  begin
   px:=(map[x+320*y+1]  -map[x+320*y])+x;
   py:=(map[x+320*(y+1)]-map[x+320*y])+y;

   if px<0 then px:=319+px;   if px>319 then px:=px mod 319;
   if py<0 then py:=199+py;   if py>199 then py:=py mod 199;

   vscr2[x+y*320].dw:=pdword(kep+(px+py*320)*4)^;
  end;
end;