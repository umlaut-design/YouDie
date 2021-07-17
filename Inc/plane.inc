procedure plane(o:Tvector; m:Tmatrix);
var t:single;
    d,i:Tvector;
    x,y:byte;
    z:word;
begin
 for x:=0 to gridx+1 do
  for y:=0 to gridy+1 do
  begin
   d.x:=x-(gridx div 2);
   d.y:=y-(gridy div 2);
   d.z:=100;
   d:=udMatrixMultiplyVector(m,d);

   if d.y=0 then d.y:=1;
//   t:=abs((10-o.y)/d.y);
   t:=((10-o.y)/d.y);
   
   i.x:=o.x+t*d.x+1;
   i.y:=o.y+t*d.y;
   i.z:=o.z+t*d.z;

   if i.x=0 then i.x:=1;
//   grid[x,y].u := byte(round(i.x*4));
//   grid[x,y].v := byte(round(i.z*4));
   grid[x,y].u := (round(i.x*4));
   grid[x,y].v := (round(i.z*4));
   z:=round(255/(abs(t)+1));
   if z>254 then grid[x,y].s:=254 else grid[x,y].s:=z;

  end;
  
end;