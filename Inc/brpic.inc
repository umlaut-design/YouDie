procedure brightenpic(kep:pointer; x,y:integer; w,h:word; br:word);
var a,b,c,z:word;
begin
 for a:=0 to (w-1) do
  for b:=0 to (h-1) do
   for c:=0 to 2 do
   begin
    z:=pbyte(kep+4*(a+b*w)+c)^+br;
    if z>255 then
     vscr[a+x+(b+y)*320].x[c]:=255
    else
     vscr[a+x+(b+y)*320].x[c]:=z;
   end;
end;
