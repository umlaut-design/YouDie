procedure Messages;
begin
 while ( PeekMessage( @Mess, 0, 0, 0, 0 )) do
 begin
  If ( GetMessage( @Mess, 0, 0, 0 )) then
  begin
   TranslateMessage( Mess );
   DispatchMessage( Mess );
  end
  else
  begin
   udBassStopModule(module);
   Halt;
  end;
 end;
end;
