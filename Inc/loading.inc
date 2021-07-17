{
 assign(f,'youdie.dat');
 reset(f,1);
 n:=filesize(f);
 getmem(p,n);
 blockread(f,p^,n);
 close(f);

 for m:=0 to n-1 do pbyte(p+m)^:=pbyte(p+m)^ xor byte(m);

 assign(f,'youdie.dat');
 reset(f,1);
 blockwrite(f,p^,n);
 close(f);
 freemem(p,n);
} 

(*
{$IFDEF DEBUG}
 udZipOpen('YouDie_d.dat');
{$ELSE}
 decode('YouDie.dat','temp.dat');
 udZipOpen('temp.dat');
{$ENDIF}
*)
 udZipOpen('YouDie.lib');

 udZipSave('music\YouDie.xm','temp.xm');
 module:=udBassInitModule('temp.xm', hW);
 kill('temp.xm');

 percent(10);

 for x:=0 to 3 do
  gore[x]:=loadziptga('gfx\pictures\boom'+st(x)+'.tga');
 gore[4]:=loadziptga('gfx\pictures\bright.tga');
  

 tex1:=loadziptga('gfx\2d_tex\tunnel.tga');
 tex2:=loadziptga('gfx\2d_tex\potential.tga');
 tex3:=loadziptga('gfx\2d_tex\grid.tga');
 tex4:=loadziptga('gfx\2d_tex\plane.tga');
 warning:=loadziptga('gfx\warning.tga');
 ifpic1:=loadziptga('gfx\fxpix\interf1.tga');
 ifpic2:=loadziptga('gfx\fxpix\interf2.tga');

 grp_umlaut:=loadziptga('gfx\texts\umlaut.tga');
 grp_feat  :=loadziptga('gfx\texts\feat.tga');
 grp_dstall:=loadziptga('gfx\texts\destroy.tga');

 credz[0]:=loadziptga('gfx\texts\c_noel1.tga');
 credz[1]:=loadziptga('gfx\texts\c_noel2.tga');
 credz[2]:=loadziptga('gfx\texts\c_garg1.tga');
 credz[3]:=loadziptga('gfx\texts\c_garg2.tga');
 credz[4]:=loadziptga('gfx\texts\c_pcn1.tga');
 credz[5]:=loadziptga('gfx\texts\c_pcn2.tga');
 credz[6]:=loadziptga('gfx\texts\c_vercy1.tga');
 credz[7]:=loadziptga('gfx\texts\c_vercy2.tga');
 percent(25);

 grp_you:=loadziptga('gfx\texts\_you.tga');
 grp_die:=loadziptga('gfx\texts\_die.tga');
 pain[0]:=loadziptga('gfx\texts\0here.tga');
 pain[1]:=loadziptga('gfx\texts\1comes.tga');
 pain[2]:=loadziptga('gfx\texts\2the.tga');
 pain[3]:=loadziptga('gfx\texts\3pain.tga');
 not_fact:=loadziptga('gfx\texts\not_fact.tga');
 percent(35);

 udZipSave('3d\spin1\spin1.3ds','temp.3ds'); spin1.Load3DS('temp.3ds');       kill('temp.3ds');
 udZipSave('3d\spin1\spin1.tga','temp.tga'); spin1.LoadTexture('temp.tga',0); kill('temp.tga');
 percent(40);

 udZipSave('3d\spin2\spin2.3ds','temp.3ds'); spin2.Load3DS('temp.3ds');       kill('temp.3ds');
 udZipSave('3d\spin2\spin2.tga','temp.tga'); spin2.LoadTexture('temp.tga',0); kill('temp.tga');
 percent(45);

 udZipSave('3d\sphere\sphere.3ds','temp.3ds'); sphere.Load3DS('temp.3ds'); kill('temp.3ds');
 udZipSave('3d\sphere\big.tga'  ,'temp.tga'); sphere.LoadTexture('temp.tga',0); kill('temp.tga');
 udZipSave('3d\sphere\small.tga','temp.tga'); sphere.LoadTexture('temp.tga',1); kill('temp.tga');
 sphere.wave:=true;
 percent(55);

 udZipSave('3d\particle\particle.3ds','temp.3ds'); particle.Load3DS('temp.3ds'); kill('temp.3ds');
 udZipSave('3d\particle\wall.tga' ,'temp.tga'); particle.LoadTexture('temp.tga',0); kill('temp.tga');
 udZipSave('3d\particle\spike.tga','temp.tga'); particle.LoadTexture('temp.tga',1); kill('temp.tga');
 particle.particles:=true;
 percent(60);

 udZipSave('3d\capsule\capsule.3ds','temp.3ds'); capsule.Load3DS('temp.3ds'); kill('temp.3ds');
 udZipSave('3d\capsule\cylinder.tga','temp.tga'); capsule.LoadTexture('temp.tga',0); kill('temp.tga');
 udZipSave('3d\capsule\knot.tga'    ,'temp.tga'); capsule.LoadTexture('temp.tga',1); kill('temp.tga');
 percent(70);

 udZipSave('3d\cemetery\cemetery.3ds','temp.3ds'); cemetery.Load3DS('temp.3ds'); kill('temp.3ds');
 udZipSave('3d\cemetery\grass.tga'   ,'temp.tga'); cemetery.LoadTexture('temp.tga', 0); kill('temp.tga');
 udZipSave('3d\cemetery\stone.tga'   ,'temp.tga'); cemetery.LoadTexture('temp.tga', 1); kill('temp.tga');
 udZipSave('3d\cemetery\marble.tga'  ,'temp.tga'); cemetery.LoadTexture('temp.tga', 2); kill('temp.tga');
 udZipSave('3d\cemetery\wood2.tga'   ,'temp.tga'); cemetery.LoadTexture('temp.tga', 4); kill('temp.tga');
 udZipSave('3d\cemetery\banner.tga'  ,'temp.tga'); cemetery.LoadTexture('temp.tga', 5); kill('temp.tga'); percent(71);
 udZipSave('3d\cemetery\marble.tga'  ,'temp.tga'); cemetery.LoadTexture('temp.tga', 6); kill('temp.tga');
 udZipSave('3d\cemetery\stone2.tga'  ,'temp.tga'); cemetery.LoadTexture('temp.tga',13); kill('temp.tga'); percent(72);
 udZipSave('3d\cemetery\wood1.tga'   ,'temp.tga'); cemetery.LoadTexture('temp.tga',14); kill('temp.tga');

 udZipSave('3d\cemetery\_3state.tga' ,'temp.tga'); cemetery.LoadTexture('temp.tga', 3); kill('temp.tga'); percent(73);
 udZipSave('3d\cemetery\_damage.tga' ,'temp.tga'); cemetery.LoadTexture('temp.tga', 7); kill('temp.tga');
 udZipSave('3d\cemetery\_haujobb.tga','temp.tga'); cemetery.LoadTexture('temp.tga', 8); kill('temp.tga'); percent(74);
 udZipSave('3d\cemetery\_bypass.tga' ,'temp.tga'); cemetery.LoadTexture('temp.tga', 9); kill('temp.tga');
 udZipSave('3d\cemetery\_dd.tga'     ,'temp.tga'); cemetery.LoadTexture('temp.tga',10); kill('temp.tga'); percent(75);
 udZipSave('3d\cemetery\_mist.tga'   ,'temp.tga'); cemetery.LoadTexture('temp.tga',11); kill('temp.tga');
 udZipSave('3d\cemetery\_exceed.tga' ,'temp.tga'); cemetery.LoadTexture('temp.tga',12); kill('temp.tga'); percent(76);
 udZipSave('3d\cemetery\_astral.tga' ,'temp.tga'); cemetery.LoadTexture('temp.tga',15); kill('temp.tga');
 udZipSave('3d\cemetery\_evd.tga'    ,'temp.tga'); cemetery.LoadTexture('temp.tga',16); kill('temp.tga'); percent(77);
 udZipSave('3d\cemetery\_fresh.tga'  ,'temp.tga'); cemetery.LoadTexture('temp.tga',17); kill('temp.tga');
 udZipSave('3d\cemetery\_cph.tga'    ,'temp.tga'); cemetery.LoadTexture('temp.tga',18); kill('temp.tga'); percent(78);
 udZipSave('3d\cemetery\_inq.tga'    ,'temp.tga'); cemetery.LoadTexture('temp.tga',19); kill('temp.tga');
 udZipSave('3d\cemetery\_greenr.tga' ,'temp.tga'); cemetery.LoadTexture('temp.tga',20); kill('temp.tga'); percent(79);
 udZipSave('3d\cemetery\_dilemma.tga','temp.tga'); cemetery.LoadTexture('temp.tga',21); kill('temp.tga');
 udZipSave('3d\cemetery\_astro.tga'  ,'temp.tga'); cemetery.LoadTexture('temp.tga',22); kill('temp.tga'); percent(80);
 udZipSave('3d\cemetery\_hugi.tga'   ,'temp.tga'); cemetery.LoadTexture('temp.tga',23); kill('temp.tga');

 initpottab;

  for x:=0 to 319 do
   for y:=0 to 199 do
//    DTab1[x+320*y]:=10*Byte(Round(Sqrt(x*x+y*y)) mod 8 < 4) ;
    DTab1[x+320*y]:=10*Byte(Round(Sqrt(x*x+y*y)) mod 16 < 6) ;

  for x:=0 to 319 do
   for y:=0 to 199 do
    DTab2[x+320*y]:=10*Byte(Round(Sqrt(x*y)) mod 8 < 4) ;


 for x:=0 to 255 do
 begin
  sinm[x]:=round(sin(2*pi*x/255)*127)+128;
  cost[x]:=round(-cos(x*(pi/128))*64);
  sint[x]:=round( sin(x*(pi/128))*64);
  sini[x]:=round(sin(2*pi*x/255)*64);
 end;

 percent(99);

// udZipClose;
{$IFNDEF DEBUG}
// kill('temp.dat');
{$ENDIF}
