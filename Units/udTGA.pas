unit udTGA;

// ----------------------------------------------------------------------
interface

type TTGA=record
      w,h:word;
      dat:pointer;
     end;

function udTGALoad(fn:string):TTGA;
procedure udTGADisplay(tga:TTGA; x,y:word; vscr:pointer);

// ----------------------------------------------------------------------
implementation

const tgaoffset=18;

function udTGALoad(fn:string):TTGA;
var f:file;
    p:pointer;
    raw:array[0..1000000] of byte;
    w,h,_w,_h:word;
    a:TTGA;
begin
 assign(f,fn);
 reset(f,1);
 blockread(f,raw,filesize(f));
 close(f);

 move(raw[$C],w,2);
 move(raw[$E],h,2);

 getmem(p,w*h*4);
 fillchar(p^,w*h*4,0);

 for _w:=0 to w-1 do
  for _h:=0 to (h-1) do
  begin
   pbyte(p+(_w+_h*w)*4+0)^:=raw[(_w+(h-_h-1)*w)*3+0+tgaoffset];
   pbyte(p+(_w+_h*w)*4+1)^:=raw[(_w+(h-_h-1)*w)*3+1+tgaoffset];
   pbyte(p+(_w+_h*w)*4+2)^:=raw[(_w+(h-_h-1)*w)*3+2+tgaoffset];
  end;

 a.dat:=p;
 a.w:=w;
 a.h:=h;

 udTGALoad:=a;
end;


procedure udTGADisplay(tga:TTGA; x,y:word; vscr:pointer);
var u:word;
begin
 for u:=0 to (tga.h-1) do
  move(pbyte(tga.dat+u*tga.w*4)^,pbyte(vscr+(x+(u+y)*640)*4)^,tga.w*4);
end;

BEGIN
END.