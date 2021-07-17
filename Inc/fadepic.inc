procedure displayfadepic(kep:pointer; x,y:integer; w,h:word; fade:word);
var a,b,c:word;
begin
 for a:=0 to (w-1) do
  for b:=0 to (h-1) do
   for c:=0 to 2 do
    vscr[a+x+(b+y)*320].x[c]:=(pbyte(kep+4*(a+b*w)+c)^ * fade) shr 8;
end;
