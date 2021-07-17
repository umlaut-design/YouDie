procedure horline(y,x,d:word; c:dword);
var q:dword;
begin
  for q:=x to x+d do vscr[y*320+q].dw:=c;
end;
