procedure tunnel(o:Tvector; m:Tmatrix);
var a,b,c,ds,t,t1,t2:single;
    d,i:Tvector;
    x,y:byte;
    
begin
 for x:=0 to gridx+1 do
  for y:=0 to gridy+1 do
  begin
   d.x:=x-(gridx div 2);
   d.y:=y-(gridy div 2);
   d.z:=100;
   d:=udMatrixMultiplyVector(m,d);
   a :=    d.x*d.x + d.y*d.y;
   b := 2*(o.x*d.x + o.y*d.y);
   c :=    o.x*o.x + o.y*o.y - 40000;
   ds:= b*b - 4*a*c;
   
   if ds<0 then
   begin
     grid[x,y].u:=128;
     grid[x,y].v:=128;
   end
   else
   begin
     t1 := (-b + sqrt(ds))/(2*a+1);
     t2 := (-b - sqrt(ds))/(2*a+1);
     if t1<t2 then t:=t1 else t:=t2;
     i.x:=o.x+t*d.x+1;
     i.y:=o.y+t*d.y;
     i.z:=o.z+t*d.z;

{
     grid[x,y].u := round(abs(i.z)*0.2);
     grid[x,y].v := round(abs(arctan(i.y/i.x)*256/pi));
}
     grid[x,y].u := round(abs(i.z)*0.4);
     grid[x,y].v := round(abs(arctan(i.y/i.x)*512/pi));
     grid[x,y].s := (round(255/(abs(t)+1))+1)*2;
    
   end;
  
  end;
  
end;