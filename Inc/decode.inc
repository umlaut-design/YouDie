
function dec_byte(data,xorb,rolb:byte):byte; assembler;
asm
  mov al,data

  xor al,xorb

  mov cl,rolb
  ror al,cl

  xor al,xorb


  mov @Result,al
end;

procedure decode(inf,outf:string);
var x:dword;
begin
  load(inf);
  if getstring(0,13)<>'GrimRippazPak' then MessageBox(hW,'Invalid Datafile!',nil,mb_ok);
  for x:=0 to size-1 do raw[x+32]:=dec_byte(raw[x+32],x+13,x+5);
  save(outf,32,size-32);
end;
