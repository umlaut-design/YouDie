var f:file;
    size:dword;
    raw:array[0..10000000] of byte;
    
procedure load(s:string);
begin
  assign(f,s);
  reset(f,1);
  blockread(f,raw,filesize(f));
  size:=filesize(f);
  close(f);
end;

procedure save(s:string; o,l:dword);
begin
  assign(f,s);
  rewrite(f,1);
  blockwrite(f,raw[o],l);
  close(f);
end;

function getbyte (o:dword):byte;  begin  move(raw[o],getbyte ,1); end;
function getword (o:dword):word;  begin  move(raw[o],getword ,2); end;
function getdword(o:dword):dword; begin  move(raw[o],getdword,4); end;

function getstringterm(o:dword; t:byte):string;
var s:string;
    x:dword;
begin
  getstringterm:='';
  x:=0;
  repeat
   getstringterm:=getstringterm+chr(raw[o+x]);
   inc(x);
  until raw[o+x]=t;
end;

function getstring(o,l:dword):string;
var s:string;
    x:dword;
begin
  getstring:='';
  for x:=0 to l-1 do
   getstring:=getstring+chr(raw[o+x]);
end;

procedure setstring(o:dword; s:string);
var b:byte;
begin
 for b:=0 to length(s)-1 do
  raw[o+b]:=ord(s[b+1]);
end;

procedure setbyte(o:dword; b:byte);  begin move(b,raw[o],1);end;
procedure setword(o:dword; w:word);  begin move(w,raw[o],2);end;
procedure setdword(o:dword; d:dword);begin move(d,raw[o],4);end;
