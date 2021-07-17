function wrap(a,b:byte):shortint;
begin
  if abs(a-b)<200 then wrap:=0 else wrap:=-(a-b) div abs(a-b);
end;

procedure gridfill(g:Tgrid; t:TTGA);
var a,b,p,q,r:byte;
    u,ustep,ul,ulstep,ur:longint;
    v,vstep,vl,vlstep,vr:longint;
    s,sstep,sl,slstep,sr:longint;
    xuwrap,yuwrap,
    xvwrap,yvwrap,
    xswrap,yswrap:shortint;
begin

 p:=0;  
 q:=0;  
 v:=0;
 
 for b:=0 to gridy do
  for a:=0 to gridx-1 do
  begin
   xuwrap:=wrap(g[a+1,b].u,g[a,b].u);   yuwrap:=wrap(g[a,b+1].u,g[a,b].u);
   xvwrap:=wrap(g[a+1,b].v,g[a,b].v);   yvwrap:=wrap(g[a,b+1].v,g[a,b].v);
   xswrap:=wrap(g[a+1,b].s,g[a,b].s);   yswrap:=wrap(g[a,b+1].s,g[a,b].s);
   
   ul:=g[a,b].u shl 8;   ur:=g[a+1,b].u shl 8;
   vl:=g[a,b].v shl 8;   vr:=g[a+1,b].v shl 8;
   sl:=g[a,b].s shl 8;   sr:=g[a+1,b].s shl 8;

   ulstep:=(g[a,b].u-g[a,b+1].u-byte(yuwrap) shl 8)*256 div gridsize;
   vlstep:=(g[a,b].v-g[a,b+1].v-byte(yvwrap) shl 8)*256 div gridsize;
   slstep:=(g[a,b].s-g[a,b+1].s-byte(yswrap) shl 8)*256 div gridsize;
   
   for p:=0 to gridsize-1 do
   begin

    u:=ul; ustep:=(ur-ul+byte(xuwrap)*$10000) div gridsize;
    v:=vl; vstep:=(vr-vl+byte(xvwrap)*$10000) div gridsize;
    s:=sl; sstep:=(sr-sl+byte(xswrap)*$10000) div gridsize;

    for q:=0 to gridsize-1 do
    begin
     for r:=0 to 2 do
      vscr[a*gridsize+q+(b*gridsize+p)*320].x[r]:=
        (pbyte(t.dat+(byte(u div 256)+byte(v div 256)*256)*4+r)^*s) shr 16;
      
     u:=u+ustep;
     v:=v+vstep;
     s:=s+sstep;
    end;

    ul:=ul-ulstep;    ur:=ur-ulstep;
    vl:=vl-vlstep;    vr:=vr-vlstep;
    sl:=sl-slstep;    sr:=sr-slstep;
   end;
  end;
end;