unit debug;

interface

procedure debuginfo(str:string);
procedure resetdebug;
function st(i:longint):string;
function stf(i:single):string;

implementation

{==================}
procedure debuginfo(str:string);
var f:text;
begin
{$IFDEF DEBUG}
 assign(f,'debug.txt');
 append(f);
 writeln(f,str);
 close(f);
{$ENDIF}
end;

procedure resetdebug;
var f:text;
begin
{$IFDEF DEBUG}
 assign(f,'debug.txt');
 rewrite(f);
 writeln(f,'===== START =====');
 close(f);
{$ENDIF}
end;

function st(i:longint):string;
var x:string;
begin
 str(i,x);
 st:=x;
end;

function stf(i:single):string;
var x:string;
begin
 str(i:8:4,x);
 stf:=x;
end;

{==================}
BEGIN
END.