procedure flare(x0,y0:word; r:byte; vscr:pointer);
var x,y,z:integer;
    c,f:byte;
    q:dword;
begin
 for x:=-r to r do
  for y:=-r to r do
   if (sqr(x)+sqr(y)<=sqr(r)) and
      (y0+y>=0) and (y0+y<200) and
      (x0+x>=0) and (x0+x<320) then
   begin
    f:=round(r-(sqrt(sqr(x)+sqr(y))))*10;
    for c:=0 to 2 do
     begin
       q:=4*((y0+y)*320+x0+x)+c;
       z:=pbyte(vscr+q)^+f;
       if z>255 then pbyte(vscr+q)^:=255 
                else pbyte(vscr+q)^:=z;
     end;
   end;
end;
