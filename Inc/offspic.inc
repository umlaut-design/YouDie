procedure offsetpic(kep:pointer; x,y:word; w,h:word; x0,y0:word);
var a,b,c:word;
begin
 for a:=0 to (w-1) do
  for b:=0 to (h-1) do
   for c:=0 to 2 do
    vscr[a+x+(b+y)*320].x[c]:=pbyte(kep+4*(a+x0+(b+y0)*w)+c)^;
end;
