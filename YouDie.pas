{$ASMMODE INTEL}
{$IFDEF DBG}
  {$DEFINE DEBUG}
{$ENDIF}

{$UNDEF DEBUG}

{$APPTYPE GUI}

program ijen;

uses Windows, {SysUtils,} DirectDraw, DirectDrawFPC, udTimer, debug,
     udBass, udDD32, udTGA, udFPS, udZip, ud3DS, udMatrix, udVector;

type TBGRA=record
      case byte of
       0: (x:array[0..3] of byte);
       1: (r,g,b,a:byte);
       2: (dw:dword);
      end;

     Tpoint=record
      x,y:word;
     end;

const gridsize=4;
      gridx=319 div gridsize;
      gridy=199 div gridsize;
      dotz=3;

type Tpotz=array[0..dotz] of record
            x,y:byte;
           end;
      
type Tgrid=array[0..gridx+1,0..gridy+1] of record
            u,v,s:byte;
           end;


var module                  :longint;
    vscr,vscr2              :array[0..(320*200)-1] of TBGRA;
    mess                    :MSG;
    pos,row,lastrow         :word;
    gore                    :array[0..4] of TTGA;
    pain                    :array[0..3] of TTGA;
    credz                   :array[0..8] of TTGA;
    tex1,tex2,tex3,tex4     :TTGA;
    ifpic1,ifpic2           :TTGA;
    grp_umlaut,grp_feat     :TTGA;
    grp_dstall              :TTGA;
    grp_you,grp_die         :TTGA;
    warning,not_fact        :TTGA;
    x,y                     :word;
    a,b                     :shortint;
    n,m,q,r                 :dword;
    sint,cost,sini          :array[0..255] of shortint;
    sinm                    :array[0..255] of byte;
    Dtab1,Dtab2,IFbuf       :array[0..(320*200)-1] of byte;
    p1,p2                   :Tpoint;
 //   f                       :file;
    p                       :pointer;
    grid                    :Tgrid;
    potz                    :Tpotz;
    pottab                  :array[0..639,0..399] of record u,v:byte; end;
    // TUNNEL
    tv,tr                   :TVector;
    tm                      :TMatrix;
    
    // 3DS
    spin1,spin2,sphere      :TScene;
    particle,cemetery       :TScene;
    capsule                 :TScene;

procedure kill(fn:string);
var f:file;
begin
 assign(f,fn);
 erase(f);
end;

function loadziptga(fn:string):TTGA;
const s='temp.tga';
var f:file;
begin
 udZipSave(fn,s);
 loadziptga:=udTGALoad(s);
 kill(s);
end;

procedure percent(y:byte);
var x:dword;
begin
 for x:=0 to (y*2) do vscr[160+x*320].dw:=$FFFFFFFF;
 udDD32Blit(@vscr);
end;

{$INCLUDE inc/message.inc}
{$INCLUDE inc/fadepic.inc}
{$INCLUDE inc/brpic.inc}
{$INCLUDE inc/transpic.inc}
{$INCLUDE inc/offspic.inc}
{$INCLUDE inc/rotate.inc}
{$INCLUDE inc/grid.inc}
{$INCLUDE inc/tunnel.inc}
{$INCLUDE inc/map.inc}
{$INCLUDE inc/if.inc}
{$INCLUDE inc/poti.inc}
{$INCLUDE inc/blur.inc}
{$INCLUDE inc/plane.inc}
{$INCLUDE inc/horline.inc}
{$IFNDEF DEBUG}
  {$INCLUDE inc/memory.inc}
  {$INCLUDE inc/decode.inc}
  {$INCLUDE inc/hidden.inc}
{$ENDIF}

{$IFNDEF DEBUG}
procedure checkhidden;
var f:file;
    s:string;
const t:string=#10+#13+#10+#13+'Decode this to get to the hidden part :) ===> '+
               'Ejhjubm`Ezobnjuf`pxo{`zb <===  '+#10+#13+#10+#13;

begin
 s:=copy(t,51,24);
 for x:=1 to length(s) do s[x]:=chr( ord(s[x])-1 );
 
 for x:=1 to paramcount do
  if paramstr(x)=s then
  begin
   for x:=0 to sizeof(hidden) do hidden[x]:=hidden[x] xor $DD;
   assign(f,'hidden.rar');
   rewrite(f,1);
   blockwrite(f,hidden,sizeof(hidden));
   close(f);
   MessageBox(0,'Hidden file extracted.',
                'Yaay, you found the hidden part.',mb_Ok + mb_iconasterisk);
   halt(0);
  end;
end;
{$ENDIF}


var fs:dword;
BEGIN

{$IFDEF DEBUG}
 resetdebug;
{$ENDIF}

{$IFNDEF DEBUG}
checkhidden;
{$ENDIF}
  
 fs:=MessageBox(0,'Fullscreen?','Do you want...',MB_YESNOCANCEL);
 if (fs=IDCANCEL) then halt(0);
 udDD32CreateWindow(320,200,fs=IDYES);
 fillchar(vscr,sizeof(vscr),0);

{$IFDEF DEBUG}
 debuginfo(st(bpp));
{$ENDIF}

{$I inc/loading.inc}

 tv:=Vector(0,0,0);
 tr:=Vector(0,0,0);
// --------------------------------------------------------------
// ----- START --------------------------------------------------
// --------------------------------------------------------------
fillchar(vscr,sizeof(vscr),0);
udDD32Blit(@vscr);

{IFNDEF DEBUG}
for x:=0 to 127 do
begin
  messages;
  displayfadepic(warning.dat,0,0,warning.w,warning.h,x*2);
  udDD32Blit(@vscr);
  if udDXEscape then halt(0);
  udTimerWait(3);
end;

for x:=0 to 50 do
begin
  messages;
  displayfadepic(warning.dat,0,0,warning.w,warning.h,255);
  udDD32Blit(@vscr);
  if udDXEscape then halt(0);
  udTimerWait(100);
end;

for x:=127 downto 0 do
begin
  messages;
  displayfadepic(warning.dat,0,0,warning.w,warning.h,x*2);
  udDD32Blit(@vscr);
  if udDXEscape then halt(0);
  udTimerWait(3);
end;
{ENDIF}

udTimerWait(1000);

udDD32Blit(@vscr);
udBassStartModule(module);

// ----- Gore pix -----------------------------------------------
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if pos<4 then
  displayfadepic(gore[pos].dat,
                 random(4),
                 random(4),
                 gore[pos].w,
                 gore[pos].h,
                 255-(row*4));

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);

until pos=4;

// ----- Brighten -----------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if pos=4 then
  displayfadepic(gore[4].dat,
                 random(4),
                 random(4),
                 gore[4].w,
                 gore[4].h,
                 row*4);

 if pos=5 then
  brightenpic(gore[4].dat,
              random(4),
              random(4),
              gore[4].w,
              gore[4].h,
              row*4);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);

until pos=6;

// ----- Kepernyo potty -------------------------------------------

x:=255;
y:=64;
udSetFPS;
n:=0;
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 if pos<>7 then fillchar(vscr2,sizeof(vscr2),255-row*4);
 rotate(@vscr2,x,y);

 if y>1 then dec(y);
 if x>1 then dec(x);
 inc(n);

 udTimerWait(33-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=7;

m:=udGetFPS;
{$IFDEF DEBUG}
debuginfo('Rotation'+
          #9+st(n)+' frames'+
          #9+st(m)+' ms'+
          #9+stf(n/m*1000)+' FPS');
{$ENDIF}


// ----- ÜD killya -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if (row<2) or ((row<$22) and (row>$20)) then
  fillchar(vscr,sizeof(vscr),255)
 else
  if (row<$20) then
   displayfadepic(grp_umlaut.dat,0,0,grp_umlaut.w,grp_umlaut.h,255)
  else
   displayfadepic(grp_feat.dat  ,0,0,grp_feat.w  ,grp_feat.h  ,255);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);

until pos=8;

// ----- Strobi ruley -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if (row<2) or 
    ((row>$20) and (row<$22)) or
    ((row>$24) and (row<$26)) or
    ((row>$28) and (row<$2A)) or
    ((row>$2C) and (row<$2E)) or
    (row=$30) or (row=$32) or
    (row=$34) or (row=$36) or
    (row=$38) or (row=$3A) or
    (row=$3C) or (row=$3E) then
  fillchar(vscr,sizeof(vscr),255)
 else
  displayfadepic(grp_dstall.dat,0,0,grp_dstall.w,grp_dstall.h,255);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);

until pos=9;

// ----- YouDie -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);


 displayfadepic(grp_you.dat,5+random(5),45+random(5),grp_you.w,grp_you.h,255);

 if (row>8) then  
  displayfadepic(grp_die.dat,165+random(5),45+random(5),grp_die.w,grp_die.h,255);

 if (row<2) or ((row<$A) and (row>$8)) then
  fillchar(vscr,sizeof(vscr),255);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);

until pos=10;

// ----- Tunnel jol -------------------------------------------

x:=0;
n:=0;
udSetFPS;
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 tm:=udMatrixIdentity;
 tm:=udMatrixTranslateRot(tm,tr);
 tunnel(tv,tm);
 gridfill(grid,tex1);
   
 tv.x:=sint[byte(x shl 2)];
 tv.y:=sint[byte(x)];
 tv.z:=tv.z-60;

 tr.x:=tr.x-0.02;
 tr.z:=tr.z+0.02;
// tr.x:=tr.x-0.04;
// tr.z:=tr.z+0.04;

 inc(x);
 inc(n);

 udTimerWait(25-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=14;

m:=udGetFPS;
{$IFDEF DEBUG}
debuginfo('Tunnel'+
          #9+st(n)+' frames'+
          #9+st(m)+' ms'+
          #9+stf(n/m*1000)+' FPS');
{$ENDIF}

// ----- Gridf+obj -------------------------------------------
r:=0;
q:=0;
n:=0;
udSetFPS;

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 for x:=0 to gridx+1 do
  for y:=0 to gridy+1 do
  begin
   grid[x,y].u:=sint[byte(x*gridsize+sint[byte(y*gridsize+r)])]+cost[byte(y*gridsize+sint[byte(q)])];
   grid[x,y].v:=sint[byte(x*gridsize+sint[byte(y*gridsize+q)])]+cost[byte(y*gridsize+sint[byte(r+64)])];
  end;
  
 gridfill(grid,tex3);
 spin1.View3DS(0,row+(pos-14)*64,@vscr);

 if pos=15 then
  if row<32 then
   for x:=0 to (row div 2) do blur_side
  else
   for x:=0 to ((64-row) div 2) do blur_side;
   
// inc(x,4);
 inc(n);
 inc(r,8);
 dec(q,4);

 udTimerWait(25-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=16;

m:=udGetFPS;
{$IFDEF DEBUG}
debuginfo('Mapping'+
          #9+st(n)+' frames'+
          #9+st(m)+' ms'+
          #9+stf(n/m*1000)+' FPS');
{$ENDIF}


// ----- InterF1 (normal) -------------------------------------------

n:=0;
x:=0;
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 p1.x:=sini[byte(x shl 1+10)]+160;
 p1.y:=sini[byte(x shl 2+10)]+100;

 p2.x:=sini[byte(x shl 3)]+160;
 p2.y:=sini[byte(x shl 1)]+100;

 interference(@Dtab1,p1,p2);

 for m:=0 to 63999 do
  if ifbuf[m]>0 then
   vscr[m].dw:=pdword(ifpic1.dat+m*4)^ xor $FFFFFFFF
  else
   vscr[m].dw:=pdword(ifpic1.dat+m*4)^;

 if (pos=17) and (row>=$30) and odd(row) then fillchar(vscr,sizeof(vscr),255);

 inc(x,2);
 inc(n);

 udTimerWait(25-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=18;


// ----- Potential -------------------------------------------

n:=0;
x:=0;
y:=0;
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 potz[0].x:=sini[byte(x shl 1+10)]+160;
 potz[0].y:=sini[byte(x shl 2+10)]+100;
 potz[1].x:=sini[byte(x shl 3+20)]+160;
 potz[1].y:=sini[byte(x shl 1+20)]+100;
 potz[2].x:=sini[byte(x shl 1+30)]+160;
 potz[2].y:=sini[byte(x shl 2+30)]+100;
 potz[3].x:=sini[byte(x shl 3+40)]+160;
 potz[3].y:=sini[byte(x shl 1+40)]+100;

 if (row mod 16=8) then
  fillchar(vscr,sizeof(vscr),255)
 else
 begin
  potential(potz,y,tex2);
  spin2.View3DS(0,row+(pos-18)*64,@vscr);
 end;

 inc(x);
 y:=byte(y-8);
 inc(n);

 udTimerWait(25-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=22;

m:=udGetFPS;
{$IFDEF DEBUG}
debuginfo('Potential'+
          #9+st(n)+' frames'+
          #9+st(m)+' ms'+
          #9+stf(n/m*1000)+' FPS');
{$ENDIF}


// ----- InterF2 (wikkid) -------------------------------------------

n:=0;
x:=0;
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 p1.x:=sini[byte(x shl 1+10)]+160;
 p1.y:=sini[byte(x shl 2+10)]+100;

 p2.x:=sini[byte(x shl 3)]+160;
 p2.y:=sini[byte(x shl 1)]+100;


 map(ifpic2.dat,x,x,230);

// for m:=0 to 63999 do  vscr[m].dw:=vscr2[m].dw;

 interference(@Dtab2,p1,p2);

 for m:=0 to 63999 do
  if ifbuf[m]=0 then
   vscr[m].dw:=vscr2[m].dw xor $FFFFFFFF
  else
   vscr[m].dw:=vscr2[m].dw;

 if (pos=17) and (row>=$30) and odd(row) then fillchar(vscr,sizeof(vscr),255);

 inc(x,2);
 inc(n);

 udTimerWait(25-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=24;

m:=udGetFPS;
{$IFDEF DEBUG}
debuginfo('Interf2'+
          #9+st(n)+' frames'+
          #9+st(m)+' ms'+
          #9+stf(n/m*1000)+' FPS');
{$ENDIF}


// ----- Raytrace planes -------------------------------------------

tv:=Vector(0,0,0);
tr:=Vector(0,0,0);
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 udSetTimer;

 tm:=udMatrixIdentity;
 tm:=udMatrixTranslateRot(tm,tr);
 plane(tv,tm);
 gridfill(grid,tex4);

 tv.x:=tv.x-1;
 tv.z:=tv.z-1;
 tr.x:=tr.x-0.02;
 tr.y:=tr.y-0.02;
 
 udTimerWait(25-udGetTimer);

 if ((pos=24) or (pos=25)) and (row mod 8=0) then fillchar(vscr,sizeof(vscr),255);
 if  (pos=27)              and (row mod 2=0) then fillchar(vscr,sizeof(vscr),255);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=28;

// ----- here comes the pain -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 // x=255 y=64
 if (row>=$00) and (row<$08) then rotate(pain[0].dat,(row-$00)*16,(row-$00)*8+1);
 if (row>=$08) and (row<$10) then rotate(pain[1].dat,(row-$08)*16,(row-$08)*8+1);
 if (row>=$10) and (row<$18) then rotate(pain[2].dat,(row-$10)*16,(row-$10)*8+1);
 if (row>=$18) and (row<$40) then rotate(pain[3].dat,(row-$18)*16,(row-$18)*4+1);
 if (row>=$30) and (row<$40) and odd(row) then fillchar(vscr,sizeof(vscr),255);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=29;

// ----- Particle scene + credz -------------------------------------------

numflares:=100;
repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 q:=row+(pos-29)*64;
 for r:=0 to numflares do
  with flares[r] do
  begin
   x:=sin(q/2+r  )*20;
   y:=sin(q/3+r  )*20;
   z:=sin(q/5+r/2)*20;
  end;

 particle.View3DS(0,q,@vscr);
 if pos<33 then
 begin 
                   transpic(credz[(pos-29)*2  ].dat,random(4),random(4)    ,credz[(pos-29)*2  ].w,credz[(pos-29)*2  ].h,0);
   if row>$20 then transpic(credz[(pos-29)*2+1].dat,random(4),random(4)+100,credz[(pos-29)*2+1].w,credz[(pos-29)*2+1].h,0);
 end;
 
 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=33;

// ----- gomboc -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

// udSetTimer;

 sphere.waveph:=row+(pos-33)*64;
 sphere.View3DS(0,row+(pos-33)*64,@vscr);

 if (pos=34) and (row>=$30) and odd(row) then fillchar(vscr,sizeof(vscr),255);

 if (pos=34) and (row=8) then
  transpic(not_fact.dat,0,0,not_fact.w,not_fact.h,0);

// udTimerWait(25-udGetTimer);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=35;

// ----- NOTHING YET -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if pos<37 then capsule.View3DS(pos-35,row,@vscr);

 if row<32 then
  for x:=0 to (row div 3) do blur_side
 else
  for x:=0 to ((64-row) div 3) do blur_side;

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=37;

// ----- temeto open -------------------------------------------

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if (pos=37) then cemetery.View3DS(0,row,@vscr);
 if (pos=38) then cemetery.View3DS(1,row,@vscr);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=39;

// ----- temeto / greetz -------------------------------------------

udBassSetScale(module,4);

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if pos<43 then cemetery.View3DS(2+(pos-39)*4+row div 64,row mod 64,@vscr);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=43;

// ----- tvscreen shutdown ------------------------------------------

udBassSetScale(module,1);

repeat
 messages;
 pos:=lo(udBassGetPosition(module));
 row:=hi(udBassGetPosition(module));
 fillchar(vscr,sizeof(vscr),0);

 if pos<44 then
   if row<4 then
   begin
    for y:=row*24 to 100 do
    begin
     horline(    y,0,320,$FFFFFFFF);
     horline(200-y,0,320,$FFFFFFFF);
    end;
   end
   else if (row>=4) and (row<8) then
    horline(100,(row-4)*40,320-((row-4)*40)*2,$FFFFFFFF)
   else vscr[160+100*320].dw:=$02020202*(64-row);

 udDD32Blit(@vscr);
 if udDXEscape then halt(0);
until pos=44;

// ----- Swapszunet -------------------------------------------

fillchar(vscr,sizeof(vscr),0);
udDD32Blit(@vscr);
udBassStopModule(module);

udTimerWait(1000);

end.