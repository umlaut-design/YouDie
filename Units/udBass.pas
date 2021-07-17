unit udBass;

interface

uses windows;

function udBassInitModule(fn:pchar; hW:hWnd):longint;
procedure udBassStartModule(module:longint);
procedure udBassStopModule(module:longint);
function udBassGetPosition(strm:longint):dword;
procedure udBassSetScale(strm,sc:longint);

implementation

uses bass;

function udBassInitModule(fn:pchar; hW:hWnd):longint;
var sh:longint;
begin

 if not BASS_Init(-1, 44100, BASS_DEVICE_LEAVEVOL, hW) then
 begin
//  if not BASS_Init(-2, 44100, BASS_DEVICE_LEAVEVOL, hW) then
  begin
   MessageBox( 0,'Error in BASS_Init',nil,mb_Ok );
   halt(0);
  end;
 end;

 if not BASS_Start Then
 begin
  MessageBox( 0,'Error in BASS_Start',nil,mb_Ok );
  halt(0);
 end;

// BASS_MusicFree(sh);
 sh:=BASS_MusicLoad(false,fn,0,0,0);
 if sh = 0 Then
 begin
  MessageBox( 0,'Error in BASS_StreamCreateFile',nil,mb_Ok );
  halt(0);
  udBassInitModule:=0;
 end
 else
 begin
  udBassInitModule := sh;
 end;

end;

procedure udBassStartModule(module:longint);
begin
 If not BASS_MusicPlay(module) Then
  MessageBox( 0,'Error in BASS_MusicPlay',nil,mb_Ok );
end;

procedure udBassStopModule(module:longint);
begin
 BASS_ChannelStop(module);
 BASS_Stop;
 BASS_Free;
end;

function udBassGetPosition(strm:longint):dword;
begin
 udBassGetPosition:=BASS_ChannelGetPosition(strm);
end;

procedure udBassSetScale(strm,sc:longint);
begin
  BASS_MusicSetPositionScaler(strm,sc);
end;

BEGIN
END.
