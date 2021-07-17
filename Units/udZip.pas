(****************************************************************************)
(*      udZip.pas       -       ömlaÅt Design ZIP Utility                   *)
(*                                                                          *)
(*      Code            -       Adam Zlehovszky (Ady/ömlaÅt Design)         *)
(*                              Gargaj/ömlaÅt Design                        *)
(****************************************************************************)

Unit udZip;

Interface

Procedure udZipOpen(Fn : String);
//Procedure udZipClose;
//Function  udZipRead(Fn : String):Pointer;
Procedure udZipSave(zFn,fn : String);
//Function  udZipFileSize(Fn : String):DWord;

Implementation

Uses
   debug, udlib;

Procedure udZipOpen(Fn : String);
Begin
   udLibOpen(Fn);
End;

Procedure udZipSave(zFn,fn : String);
Begin
  udLibSave(fn,zfn);
End;

Begin
End.
(****************************************************************************)
(*      Version         Date            Small description                   *)
(*      -----------------------------------------------------------------   *)
(*      v0.0.2                          Added saving from ZIP    (Gargaj)   *)
(*      v0.0.1          2001.10.22      First Public Version        (Ady)   *)
(****************************************************************************)