unit udFPS;

interface

procedure udFPSWait(ms:longint);
procedure udSetFPS;
function udGetFPS:dword;
function timeGetTime: Dword; stdcall; external 'winmm' name 'timeGetTime';

const udStartTime:dword=0;

implementation

procedure udFPSWait(ms:longint);
var a:longint;
begin
 a:=timeGetTime;
 repeat until ((timeGetTime-a)>=ms) or (ms<0);
end;

procedure udSetFPS;
begin
 udStartTime:=timeGetTime;
end;

function udGetFPS:dword;
begin
 udGetFPS:=timeGetTime-udStartTime;
 udSetFPS;
end;

BEGIN
END.