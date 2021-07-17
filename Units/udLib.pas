unit udLib;

interface

uses windows,debug;

function udLibGetFileNum(fn:string):byte;
procedure udLibRead(fn:string; p:pointer);
procedure udLibOpen(fn:string);
function udLibGetOffset(fn:string):dword;
procedure udLibSave(tfn,fn:string);

var raw:array[0..20000000] of byte;
    size:dword;

implementation

function getbyte (o:dword):byte;  begin  move(raw[o],getbyte ,1); end;
function getword (o:dword):word;  begin  move(raw[o],getword ,2); end;
function getdword(o:dword):dword; begin  move(raw[o],getdword,4); end;

function getstring(o,l:dword):string;
var s:string;
    x:dword;
begin
  getstring:='';
  for x:=0 to l-1 do
   getstring:=getstring+chr(raw[o+x]);
end;

function getstringterm(o:dword; t:byte):string;
var s:string;
    x:dword;
begin
  getstringterm:='';
  x:=0;
  repeat
   getstringterm:=getstringterm+chr(raw[o+x]);
   inc(x);
  until ((raw[o+x]=t) or (x>=24));
end;
    
function udLibGetFileNum(fn:string):byte;
var k:dword;
    s:string;
begin
  k:=0;
  repeat
//    writeln('-',getstringterm($10+k*$20,0),'-');
//    s:=getstring($10+k*$20,24);
    s:=getstringterm($10+k*$20,0);
    debuginfo('-'+s+'-');
    if s=fn then
    begin
//      writeln(getstringterm($10+k*$20,0));
      udLibGetFileNum:=k;
      exit;
    end;
    inc(k);
  until s='*';
end;

procedure udLibOpen(fn:string);
var f:file;
begin
  debuginfo('opening file');
  assign(f,fn);
  reset(f,1);
  blockread(f,raw,filesize(f));
  size:=filesize(f);
  close(f);
end;

function udLibGetOffset(fn:string):dword;
var n:dword;
begin
  n:=udLibGetFileNum(fn);
  udLibGetOffset:=getdword($10+$10+n*$20);
end;

procedure udLibRead(fn:string; p:pointer);
var ofs,len,n:dword;
begin
  n:=udLibGetFileNum(fn);
  ofs:=getdword($10+$10+n*$20);
  len:=getdword($10+$14+n*$20);
  move(raw[ofs],p^,len);
end;

procedure udLibSave(tfn,fn:string);
var ofs,len,n:dword;
    fo:file;
begin
  debuginfo('searching '+fn);
  n:=udLibGetFileNum(fn);
  ofs:=getdword($10+$18+n*$20);
  len:=getdword($10+$1C+n*$20);

  debuginfo('Saving "'+fn+'" to "'+tfn+'", size '+st(len)+', offset '+st(ofs));
  assign(fo,tfn);
  rewrite(fo,1);
  blockwrite(fo,raw[ofs],len);
  close(fo);
  
  //move(raw[ofs],p^,len);
end;

BEGIN
END.
