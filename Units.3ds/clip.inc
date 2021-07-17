const
  zmin=3.1;

  e_left =0;
  e_top  =0;
  e_right=319;
  e_down =199;

var
 poly_z:array[0..3] of Tvertex;  num_z:byte;
 poly_s:array[0..20] of Tvertex; num_s:byte;
 poly_t:array[0..20] of Tvertex; num_t:byte;


// ===== CLIP TO VIEWER PLANE
procedure clip_front(v1,v2:Tvertex);
var dold,dnew,m:single;
begin
  dold:=v2.vec.z-v1.vec.z;
  dnew:=    zmin-v1.vec.z;
  if dold<>0 then m:=dnew/dold else m:=1;
  
  if ((v1.vec.z>=zmin) and (v2.vec.z>=zmin)) then
  begin
   poly_z[num_z]:=v2;
   inc(num_z);
  end;

  if ((v1.vec.z>=zmin) and (v2.vec.z<zmin)) then
  begin
   poly_z[num_z].vec.x:=v1.vec.x+(v2.vec.x-v1.vec.x)*m;
   poly_z[num_z].vec.y:=v1.vec.y+(v2.vec.y-v1.vec.y)*m;
   poly_z[num_z].vec.z:=zmin;
   poly_z[num_z].u:=v1.u+(v2.u-v1.u)*m;
   poly_z[num_z].v:=v1.v+(v2.v-v1.v)*m;
   inc(num_z);
  end;

  if ((v1.vec.z<zmin) and (v2.vec.z>=zmin)) then
  begin
   poly_z[num_z].vec.x:=v1.vec.x+(v2.vec.x-v1.vec.x)*m;
   poly_z[num_z].vec.y:=v1.vec.y+(v2.vec.y-v1.vec.y)*m;
   poly_z[num_z].vec.z:=zmin;
   poly_z[num_z].u:=v1.u+(v2.u-v1.u)*m;
   poly_z[num_z].v:=v1.v+(v2.v-v1.v)*m;
   inc(num_z);
   poly_z[num_z]:=v2;
   inc(num_z);
  end;

end;

// ===== CLIP RIGHT
procedure clip_right(v1,v2:Tvertex);
var dx,dy,dz,m,ur,vr,zm,um,vm:single;
begin

  dx:=v2.vec.x-v1.vec.x;
  dy:=v2.vec.y-v1.vec.y;
  dz:=v2.vec.z-v1.vec.z;
  ur:=v2.u-v1.u;
  vr:=v2.v-v1.v;

  if dx<>0 then begin
    m:=dy/dx;    um:=ur/dx;    vm:=vr/dx;   zm:=dz/dx;
  end
  else  begin
    m:=1;        um:=1;        vm:=1;
  end;
  
  if (v1.vec.x<=e_right) and (v2.vec.x<=e_right) then
  begin
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

  if (v1.vec.x<=e_right) and (v2.vec.x>e_right) then
  begin
    poly_t[num_t].vec.x:=e_right;
    poly_t[num_t].vec.y:=v1.vec.y+ m*(e_right-v1.vec.x);
    poly_t[num_t].vec.z:=v1.vec.z+zm*(e_right-v1.vec.x);
    poly_t[num_t].u:=v1.u+um*(e_right-v1.vec.x);
    poly_t[num_t].v:=v1.v+vm*(e_right-v1.vec.x);
    inc(num_t);
  end;

  if (v1.vec.x>e_right) and (v2.vec.x<=e_right) then
  begin
    poly_t[num_t].vec.x:=e_right;
    poly_t[num_t].vec.y:=v1.vec.y+ m*(e_right-v1.vec.x);
    poly_t[num_t].vec.z:=v1.vec.z+zm*(e_right-v1.vec.x);
    poly_t[num_t].u:=v1.u+um*(e_right-v1.vec.x);
    poly_t[num_t].v:=v1.v+vm*(e_right-v1.vec.x);
    inc(num_t);
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

end;

// ===== CLIP LEFT
procedure clip_left(v1,v2:Tvertex);
var dx,dy,dz,m,ur,vr,zm,um,vm:single;
begin

  dx:=v2.vec.x-v1.vec.x;
  dy:=v2.vec.y-v1.vec.y;
  dz:=v2.vec.z-v1.vec.z;
  ur:=v2.u-v1.u;
  vr:=v2.v-v1.v;

  if dx<>0 then begin
    m:=dy/dx;    um:=ur/dx;    vm:=vr/dx;   zm:=dz/dx;
  end
  else  begin
    m:=1;        um:=1;        vm:=1;
  end;
  
 if (v1.vec.x>=e_left) and (v2.vec.x>=e_left) then
  begin
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

  if (v1.vec.x>=e_left) and (v2.vec.x<e_left) then
  begin
    poly_t[num_t].vec.x:=e_left;
    poly_t[num_t].vec.y:=v1.vec.y+ m*(e_left-v1.vec.x);
    poly_t[num_t].vec.z:=v1.vec.z+zm*(e_left-v1.vec.x);
    poly_t[num_t].u:=v1.u+um*(e_left-v1.vec.x);
    poly_t[num_t].v:=v1.v+vm*(e_left-v1.vec.x);
    inc(num_t);
  end;

  if (v1.vec.x<e_left) and (v2.vec.x>=e_left) then
  begin
    poly_t[num_t].vec.x:=e_left;
    poly_t[num_t].vec.y:=v1.vec.y+ m*(e_left-v1.vec.x);
    poly_t[num_t].vec.z:=v1.vec.z+zm*(e_left-v1.vec.x);
    poly_t[num_t].u:=v1.u+um*(e_left-v1.vec.x);
    poly_t[num_t].v:=v1.v+vm*(e_left-v1.vec.x);
    inc(num_t);
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

end;

// ===== CLIP TOP
procedure clip_top(v1,v2:Tvertex);
var dx,dy,dz,m,ur,vr,zm,um,vm:single;
begin

  dx:=v2.vec.x-v1.vec.x;
  dy:=v2.vec.y-v1.vec.y;
  dz:=v2.vec.z-v1.vec.z;
  ur:=v2.u-v1.u;
  vr:=v2.v-v1.v;

  if dy<>0 then  begin
    m:=dx/dy;    um:=ur/dy;    vm:=vr/dy;   zm:=dz/dy;
  end
  else  begin
    m:=1;        um:=1;        vm:=1;
  end;

  if (v1.vec.y>=e_top) and (v2.vec.y>=e_top) then
  begin
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

  if (v1.vec.y>=e_top) and (v2.vec.y<e_top) then
  begin
    poly_t[num_t].vec.x:=v1.vec.x+(e_top-v1.vec.y)*m;
    poly_t[num_t].vec.y:=e_top;
    poly_t[num_t].vec.z:=v1.vec.z+(e_top-v1.vec.y)*zm;
    poly_t[num_t].u:=v1.u+(e_top-v1.vec.y)*um;
    poly_t[num_t].v:=v1.v+(e_top-v1.vec.y)*vm;
    inc(num_t);
  end;

  if (v1.vec.y<e_top) and (v2.vec.y>=e_top) then
  begin
    poly_t[num_t].vec.x:=v1.vec.x+(e_top-v1.vec.y)*m;
    poly_t[num_t].vec.y:=e_top;
    poly_t[num_t].vec.z:=v1.vec.z+(e_top-v1.vec.y)*zm;
    poly_t[num_t].u:=v1.u+(e_top-v1.vec.y)*um;
    poly_t[num_t].v:=v1.v+(e_top-v1.vec.y)*vm;
    inc(num_t);
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

end;

// ===== CLIP BOTTOM
procedure clip_down(v1,v2:Tvertex);
var dx,dy,dz,m,ur,vr,zm,um,vm:single;
begin

  dx:=v2.vec.x-v1.vec.x;
  dy:=v2.vec.y-v1.vec.y;
  dz:=v2.vec.z-v1.vec.z;
  ur:=v2.u-v1.u;
  vr:=v2.v-v1.v;

  if dy<>0 then  begin
    m:=dx/dy;    um:=ur/dy;    vm:=vr/dy;   zm:=dz/dy;
  end
  else  begin
    m:=1;        um:=1;        vm:=1;
  end;

  if (v1.vec.y<=e_down) and (v2.vec.y<=e_down) then
  begin
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

  if (v1.vec.y<=e_down) and (v2.vec.y>e_down) then
  begin
    poly_t[num_t].vec.x:=v1.vec.x+(e_down-v1.vec.y)*m;
    poly_t[num_t].vec.y:=e_down;
    poly_t[num_t].vec.z:=v1.vec.z+(e_down-v1.vec.y)*zm;
    poly_t[num_t].u:=v1.u+(e_down-v1.vec.y)*um;
    poly_t[num_t].v:=v1.v+(e_down-v1.vec.y)*vm;
    inc(num_t);
  end;

  if (v1.vec.y>e_down) and (v2.vec.y<=e_down) then
  begin
    poly_t[num_t].vec.x:=v1.vec.x+(e_down-v1.vec.y)*m;
    poly_t[num_t].vec.y:=e_down;
    poly_t[num_t].vec.z:=v1.vec.z+(e_down-v1.vec.y)*zm;
    poly_t[num_t].u:=v1.u+(e_down-v1.vec.y)*um;
    poly_t[num_t].v:=v1.v+(e_down-v1.vec.y)*vm;
    inc(num_t);
    poly_t[num_t]:=v2;
    inc(num_t);
  end;

end;


// ====== CLIP Z
procedure clip_z(v1,v2,v3:Tvertex);
begin
  num_z:=0;
  clip_front(v1,v2);
  clip_front(v2,v3);
  clip_front(v3,v1);
end;

procedure clip_screen;
var x:shortint;
begin

  num_t:=0;
  for x:=0 to num_s-1 do clip_right(poly_s[x],poly_s[(x+1) mod num_s]);
  move(poly_t,poly_s,sizeof(poly_s));
  num_s:=num_t;

  num_t:=0;
  for x:=0 to num_s-1 do clip_left (poly_s[x],poly_s[(x+1) mod num_s]);
  move(poly_t,poly_s,sizeof(poly_s));
  num_s:=num_t;

  num_t:=0;
  for x:=0 to num_s-1 do clip_top  (poly_s[x],poly_s[(x+1) mod num_s]);
  move(poly_t,poly_s,sizeof(poly_s));
  num_s:=num_t;

  num_t:=0;
  for x:=0 to num_s-1 do clip_down (poly_s[x],poly_s[(x+1) mod num_s]);
  move(poly_t,poly_s,sizeof(poly_s));
  num_s:=num_t;

  
end;
