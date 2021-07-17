procedure rotate(kep:pointer; a,zoom:byte);
var x,y,c:word;
    _x,_y,__x,__y:integer;
begin
 for y:=0 to 199 do
  for x:=0 to 319 do
   begin
    _x:=x-160;
    _y:=y-100;
 
    __x:=_x*cost[a] div zoom+_y*sint[a] div zoom+160;
    __y:=_y*cost[a] div zoom-_x*sint[a] div zoom+100;

    if (__x>0) and (__x<320) and
       (__y>0) and (__y<200) then
     for c:=0 to 2 do
      vscr[x+y*320].x[c]:=pbyte(kep+4*(__x+__y*320)+c)^;
   end;
end;