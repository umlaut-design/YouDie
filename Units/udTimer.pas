unit udTimer;

interface

procedure udTimerWait(ms:longint);
procedure udSetTimer;
function udGetTimer:dword;
function timeGetTime: Dword; stdcall; external 'winmm' name 'timeGetTime';

const udStartTime:dword=0;

implementation

procedure udTimerWait(ms:longint);
var a:longint;
begin
 a:=timeGetTime;
 repeat until ((timeGetTime-a)>=ms) or (ms<0);
end;

procedure udSetTimer;
begin
 udStartTime:=timeGetTime;
end;

function udGetTimer:dword;
begin
 udGetTimer:=timeGetTime-udStartTime;
 udSetTimer;
end;

BEGIN
END.