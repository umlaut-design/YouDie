//type tTexCoord=packed record X,Y,U,V:integer; Z:Longint; end;

var
	zbuf : array[0..63999] of dword;

procedure DispTex(p1, p2, p3 : tTexCoord; wtdisp, screen : pointer);
	type
		tscr = array[0..320 * 200 - 1] of dword;
		ttex = array[0..256 * 256 - 1] of dword;
	var
		w, h	:	longint;
		t		:	longint;
		x, y,
		yend	:	integer;
		u, v, z	:	longint;
		xl, xr	:	longint;
		ul, vl,
		zl		:	longint;    
		us, vs,
		zs		:	longint;
		xls, xrs,
		uls, vls,
		zls		:	longint;

	{nem $I _line.inc}

	///////////////////////////////////////////////////
	procedure Csere(var _1, _2 : tTexCoord);  //cserelo
		var temp : tTexCoord;
	begin
		temp := _1;
		_1 := _2;
		_2 := temp;
	end;
	//////////////////////////////////////////////////
	procedure Display;  // a valodi kirako rutin
	begin
		
		(*		
		line(p1.x,p1.y,p2.x,p2.y);		
		line(p1.x,p1.y,p3.x,p3.y);
		line(p3.x,p3.y,p2.x,p2.y);
		exit;		
		*)
		repeat
			u := ul;
			v := vl;
			z := zl;
			x := xl shr 16;
			//if x < 319 then
			repeat
				if z < zbuf[x + y * 320] then
				begin
					tscr(screen^)[x + y * 320] := ttex(wtdisp^)[byte(u shr 16) + byte(v shr 16) * 256];
					//tscr(screen^)[x + x * 320] := byte(z shr 16) * $01010101;
					//tscr(screen^)[x + x * 320] := z;
					zbuf[x + y * 320] := z;
				end;
				u := u + us;
				v := v + vs;
				z := z + zs;
				inc(x);
			until (x > (xr shr 16)); // or (x > 319); 
			ul := ul + uls;
			vl := vl + vls;
			zl := zl + zls;
			xl := xl + xls;
			xr := xr + xrs;
			inc(y);
		until (y >= yend); // or (y > 200);
	end;
	//////////////////////////////////////////////////

begin
	if (p1.y > p2.y) then Csere(p1, p2);
	if (p1.y > p3.y) then Csere(p1, p3);
	if (p2.y > p3.y) then Csere(p2, p3);
		
	if (p1.y = p2.y) then							//felsok egyvonalban, azaz also 3szog
	begin
		if (p3.y = p2.y) or (p1.x = p2.x) then exit;
		if (p2.x < p1.x) then Csere(p1, p2);
		w := (p2.x - p1.x);
		h := (p3.y - p2.y);
		us := (p2.u - p1.u) * $10000 div w;
		vs := (p2.v - p1.v) * $10000 div w;
		zs := (p2.z - p1.z)          div w;
		xls := (p3.x - p1.x) * $10000 div h;
		xrs := (p3.x - p2.x) * $10000 div h;
		uls := (p3.u - p1.u) * $10000 div h;
		vls := (p3.v - p1.v) * $10000 div h;
		zls := (p3.z - p1.z)          div h;
		xl := p1.x * $10000;
		xr := p2.x * $10000;
		ul := p1.u * $10000;
		vl := p1.v * $10000;
		zl := p1.z;
		y := p1.y;
		yend := p3.y;
		Display;
		exit;
	end;
	
	if (p2.y = p3.y) then							//alsok egyvonalban, azaz felso 3szog
	begin
		if (p1.y = p2.y) or (p2.x = p3.x) then exit;
		if (p3.x < p2.x) then Csere(p2, p3);
		w := (p3.x - p2.x);
		h := (p2.y - p1.y);
		us := (p3.u - p2.u) * $10000 div w;
		vs := (p3.v - p2.v) * $10000 div w;
		zs := (p3.z - p2.z)          div w;
		xls := (p2.x - p1.x) * $10000 div h;
		xrs := (p3.x - p1.x) * $10000 div h;
		uls := (p2.u - p1.u) * $10000 div h;
		vls := (p2.v - p1.v) * $10000 div h;
		zls := (p2.z - p1.z)          div h;
		xl := p1.x * $10000;
		xr := p1.x * $10000;
		ul := p1.u * $10000;
		vl := p1.v * $10000;
		zl := p1.z;
		y := p1.y;
		yend := p3.y;
		Display;
		exit;
	end;
		
	if p3.y = p1.y then exit;
	
	t := (p2.y - p1.y) * $10000 div (p3.y - p1.y);	//egyebkent altalanos
	w := p1.x - p2.x + (t * (p3.x - p1.x)) div $10000;
	if (w = 0) then exit;
	
	us := ((p3.u - p1.u) * t + (p1.u - p2.u) * $10000) div w;
	vs := ((p3.v - p1.v) * t + (p1.v - p2.v) * $10000) div w;

	zs := (p1.z + ((p3.z - p1.z) * (p2.y - p1.y) div (p3.y - p1.y)) - p2.z) div w;
	// ez ugyanaz, de kevesbe valoszinu, hogy tulcsordul
	
	//akarmelyik oldalon is van, mindig ugyanugy kell kiszamolni a belso lepeskozoket.
	
	if (w > 0) then									//baloldalt torott
	begin
		h := p2.y - p1.y;
		xls := (p2.x - p1.x) * $10000 div h;
		xrs := (p3.x - p1.x) * $10000 div (p3.y - p1.y);
		uls := (p2.u - p1.u) * $10000 div h;
		vls := (p2.v - p1.v) * $10000 div h;
		zls := (p2.z - p1.z)          div h;
		xl := p1.x * $10000;
		xr := p1.x * $10000;
		ul := p1.u * $10000;
		vl := p1.v * $10000;
		zl := p1.z;
		y := p1.y;
		yend := p2.y;
		Display;
		h := p3.y - p2.y;
		xls := (p3.x - p2.x) * $10000 div h;
		uls := (p3.u - p2.u) * $10000 div h;
		vls := (p3.v - p2.v) * $10000 div h;
		zls := (p3.z - p2.z)          div h;
		yend := p3.y;
		Display;
		exit;
	end
	else											//jobboldalt torott
	begin
		h := p3.y - p1.y;
		xls := (p3.x - p1.x) * $10000 div h;
		xrs := (p2.x - p1.x) * $10000 div (p2.y - p1.y);
		uls := (p3.u - p1.u) * $10000 div h;
		vls := (p3.v - p1.v) * $10000 div h;
		zls := (p3.z - p1.z)          div h;
		xl := p1.x * $10000;
		xr := p1.x * $10000;
		ul := p1.u * $10000;
		vl := p1.v * $10000;
		zl := p1.z;
		y := p1.y;
		yend := p2.y;
		Display;
		xrs := (p3.x - p2.x) * $10000 div (p3.y - p2.y);
		yend := p3.y;
		Display;
		exit;
	end;
end;

/////innen copypaste



function project(point:Tvector; fov:single):Tvector;
var x:Tvector;
begin
 x.x:=round((point.x*fov)/point.z+160);
 x.y:=round((point.y*fov)/point.z+100);
// x.z:=sqrt( point.x*point.x + point.y*point.y + point.z*point.z );
 x.z:=point.z;
 project:=x;
end;

procedure drawpoly(v1,v2,v3:Tvertex; wtdisp,screen:pointer; fov:single);
var p:TVector;
    x:shortint;
begin

  clip_z(v1,v2,v3);

  for x:=0 to num_z-1 do
  begin
    p:=project(poly_z[x].vec, fov);
    poly_s[x]:=poly_z[x];
    poly_s[x].vec:=p;
  end;
  num_s:=num_z;

{
  if l then
    for x:=0 to num_s-1 do
      debuginfo(stf(poly_s[x].vec.x)+'|'+
                stf(poly_s[x].vec.y)+'|'+
                stf(poly_s[x].vec.z)+'|');
}
  clip_screen;
{
      debuginfo(st(frame)+' * '+
                stf(tempv[objects[x].face[y].a].vec.x)+'| '+
                stf(tempv[objects[x].face[y].a].vec.y)+'| '+
                stf(tempv[objects[x].face[y].a].vec.z)+'  #  '+
                stf(tempv[objects[x].face[y].b].vec.x)+'| '+
                stf(tempv[objects[x].face[y].b].vec.y)+'| '+
                stf(tempv[objects[x].face[y].b].vec.z)+'  #  '+
                stf(tempv[objects[x].face[y].c].vec.x)+'| '+
                stf(tempv[objects[x].face[y].c].vec.y)+'| '+
                stf(tempv[objects[x].face[y].c].vec.z)+'  #  ');
  if l then
    debuginfo(stf(poly_s[0].vec.z)+' - '+
              stf(poly_s[1].vec.z)+' - '+
              stf(poly_s[2].vec.z));
}

  for x:=0 to num_s-3 do
  begin
   Disptex(ttex(poly_s[0  ].vec,poly_s[0  ].u,poly_s[0  ].v),
           ttex(poly_s[x+1].vec,poly_s[x+1].u,poly_s[x+1].v),
           ttex(poly_s[x+2].vec,poly_s[x+2].u,poly_s[x+2].v),
           wtdisp,screen);
  end;

end;