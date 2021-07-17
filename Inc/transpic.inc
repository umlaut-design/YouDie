procedure transpic(kep:pointer; x,y:integer; w,h:word; c:dword);
var a,b:word;
begin
 for a:=0 to (w-1) do
  for b:=0 to (h-1) do
    if (pdword(kep+4*(a+b*w))^<>c) then
     vscr[a+x+(b+y)*320].dw:=pdword(kep+4*(a+b*w))^;
end;
