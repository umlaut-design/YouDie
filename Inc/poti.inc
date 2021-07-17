procedure initpottab;
var x,y:word;
    _x,_y:integer;
    u,v:word;
const sok:word=81;
      c2:word=2;
      c4:word=4;
begin
  for x:=0 to 639 do
    for y:=0 to 399 do
    begin
      _x:=320-x;
      _y:=200-y;
      asm
        fild word [_x]      
        fmul st(0)          
        fild word [_y]      
        fmul st(0)          
        faddp st(1)         
        
        fsqrt
        
        fild word [_x]
        fild word [_y]
        fpatan        
    
        fimul word [sok]
    
        fidiv word [c2]
        fistp word [v]
        fidiv word [c4]
        fistp word [u]
      end;
      pottab[x,y].u:=u;
      pottab[x,y].v:=v;
    end;
     
end;

procedure potential(p:Tpotz; w:byte; t:TTGA);
var x,y:word;
    _x,_y:integer;
    u,v:word;
const sok:word=81;
begin

  for x:=0 to 319 do
    for y:=0 to 199 do
    begin
      u:=0; v:=0;
//      v:=pottab[x+160,y+100].v;
      
      for _x:=0 to dotz do
      begin
        u:=u+pottab[potz[_x].x+x,potz[_x].y+y].u;
        v:=v+pottab[potz[_x].x+x,potz[_x].y+y].v;
      end;
            
      vscr[x+y*320].dw:=pdword( t.dat+( byte(u+w)+byte(v)*256 )*4)^;
//      vscr[x+y*320].r:=u;
    end;
 
end;