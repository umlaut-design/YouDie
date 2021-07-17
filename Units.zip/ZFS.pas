{****************************************************************************

  Name      : ZIP File System
  Version   : 2.10
  Part Of   : #nothing#
  Compiler  : FPC v0.99.x (Go32v2, Win32)
  Tested on : FPC v0.99.11 (Go32v2, Win32) - Athlon500 64Mb, Win'98
  Date      : 27.MAY.99
  Author    : Iv n Montes Velencoso <senbei@teleline.es>
  Purpose   : Handling of files from disk or from a ZIP.
  Updates   : My pascal page : http://webs.demasiado.com/freakpascal/

  LICENCE   : Take a look at the documentation

  KNOWN BUGS: * The reset function isn't 100% compatible with the RTL,
                with Typed Files it needs the size of a componnet as second
                parameter unlike pascal RTL.
              * Directory handling routines ChDir, GetDir, FileExist,
              FindFirst, FindNext ... doesn't work correctly yet.


  Future    : It's discontinued, but I'm working on a new library which will
              be the follow-up of this. It's called Pack File System, and can
              be found on my home page.

  Credits   : InfoZIP, Christian Ghisler, Mark Adler, Dr. Abimbola Olowofoyeku
              and Peter Vreman for the uncompression routines.

  Greetings : to the whole FearMinds team
              to the FPC mailing lists users
              to the FPC developers
              to Toxic Avenger / Apocalipse Inc.
              to everyone that thinks that the good if it's free twice good.


 A brief explanation :

    With this unit you can access to files from the disk or files packed
    inside ZIP files with a total transparency.
    For do that this unit uses a set of modificated routines based on the
    pascal standard file handling functions : ASSIGN, CLOSE, BLOCKREAD,
    SEEK, EOF ...


 Notes:
   When a file is inside a ZIP file its filerec.userdata[16] is 127,
   and if it's a binary file type (file, file of ...) its "filerec.mode" is
   fmZipped.

   The pointer to the extra data needed by the packed files is stored in
   the first four bytes of "filerec.UserData".

   BlockWrite returns the error 101 (DISK WRITE ERROR) if we try to write in
   a zipped file.

*****************************************************************************}

{$I DEFINES.INC}

{$IFDEF ZFS_SEEKING_INFO}
{$INFO !!!Compiling w/ Seeking_info enabled, it's not recommended!!!}
{$ENDIF}

Unit ZFS;

{$MODE OBJFPC}        {-s2  (Delphi 2 extensions ON)}

INTERFACE

Uses Dos;     {Some file handling routines}

Const
  OMZSignature = 'OMZ';  {ZFS Optimize file signature}

  err_Dispose  = 256;  {Unable to dipose pointer (it''s NIL)}
  err_New      = 257;  {Error allocating a new pointer (Not enough mem?)}
  err_seeking  = 258;  {Error seeking a packed file : Out of boundaries}
  err_localhdr = 259;  {Missing or invalid local file header in ZIP file}
  err_longname = 260;  {Error reading zip local file header (too long file name)}
  err_write    = 261;  {Write error while uncompressing}
  err_read     = 262;  {Read error while uncompressing}
  err_zipfile  = 263;  {Error in ZIP file}
  err_method   = 264;  {Compression method not supported}
  err_wrongOMZ = 265;  {Wrong seeking optimization file signature (OMZ)}
  err_resetbug = 266;  {The ZFS reset function for typed files have a bug (see docs)}


type
  tFileZIP = record {Packed Files info}
    Nom   :pchar;       {file name}
    Kind  :Longint;     {0:Store, 1:LZW, 2:..., 8:HUFFMAN}
    Pos   :DWord;       {file position in the ZIP}
    Size  :DWord;       {file size}
    USize :DWord;       {Uncompressed size}
    time  :DWord;       {Packed date+time struct}
  end; {tFileZip}

  pSeekList =^tSeekList;
  tSeekList =Record
    Pos     :DWord;     {Position in the compressed file}
    UPos    :DWord;     {Positon of file (uncompressed)}
    Values  :DWord;     {(K SHL 16)+B}
    SlidePos:DWord;     {W -> Initial position of the sliding dictionary}
    SlideLen:DWord;     {Size of the encoded slide data}
    Slide   :pchar;     {Pointer to the slide data}
    next    :pSeekList; {Next seek info}
  end; {tSeekList}

  pMEMDir = ^tMEMDir;
  tMEMDir = record
    Obj  :tFileZIP;     {Packed file information}
    seek :pSeekList;    {Seeking information}
    next :pMEMDir;      {Next packed file}
  end; {tMemDir}

  pZIP = ^tZIP;
  tZIP = RECORD
    Name        :String;     {file name .ZIP}
    zfile       :file;       {handle for the zip file}
    DirMode     :LongBool;   {Normalmode or Dirmode}
    NumFiles    :DWord;      {number of files zipped}
    FirstMEMDir :pMEMDir;    {Index of the files linked list}
    Next        :pZIP;       {Next ZIP file (NIL if none)}
  end; {tZip}

  pZFSfile = ^tZFSfile;
  tZFSfile = record
    ZIP       :pZIP;         {ZIP where it's stored}
    comp      :longint;      {Type of compression}
    pos       :DWord;        {position in case it is on a ZIP}
    size      :DWord;        {size in case it is on a ZIP}
    usize     :DWord;        {size of the uncompressed archive}
    curr      :DWord;        {Current position in the file}
    time      :DWord;        {File Date+Time}
    FirstSeek :pSeekList;    {Seeking information for this file}
  end; {tZFSfile}


const
  FirstZIP  :pZIP = NIL;    {Index of the ZIP archives linked list}

  ZFSResult :DWord = 0;     {Variable with the result of a function (0=O.K.)}

  fmZipped  = $D7B4; {fmClosed=$D7B0
                      fmInput =$D7B1
                      fmOutput=$D7B2
                      fmInOut =$D7B3 -> Those are standard in Pascal}

  Zipped    = $40;   {ReadOnly =$01
                      Hidden   =$02
                      SysFile  =$04
                      VolumeID =$08
                      Directory=$10
                      Archive  =$20 -> those are standard in Pascal}
  AnyFile   = $7f;   {In the RTL it's $3f}


  NormalMode = FALSE;      {opens a ZIP in normal mode}
  DirMode    = TRUE;       {opens a ZIP in directory mode}


{Converts a case sensitive UNIX file name to a DOS/Win32 upcase one. '/'->'\'}
function  FormatFileName(s:string) : string;

{Opens a ZIP file}
Function  OpenZIP (ZIPName :string; Mode:LongBool ):pZIP;
Function  OpenZIP (ZIPName :pChar; Mode:LongBool ):pZIP;
{Closes a ZIP file}
Procedure CloseZIP(zipf:pZip);
{Closes all the oppened ZIPs}
Procedure KillZIPs;

{Returns the status of the last I/O operation performed}
function  IOResult :DWord;

{Returns the size of the file 'f' in number of components}
function  FileSize(var f :file):DWord;

{Returns TRUE if the file or directory 'sExp' exists}
function  FileExist( sExp :STRING ):LongBool;
function  FileExist( sExp :pChar ): LongBool;

{Gets the date/time stamp of a file}
procedure GetFTime(var F :file; var Time: Longint);
procedure GetFTime(var F :text; var Time: Longint);
{Sets the date/time stamp of a file (only affects temporaly to zipped files)}
procedure SetFTime(var F :file; Time: Longint);
procedure SetFTime(var F :text; Time: Longint);
{Gets the file attribute (zipped files return always ZIPPED)}
procedure GetFAttr(var F :file; var Attr: Word);
procedure GetFAttr(var F :text; var Attr: Word);
{Sets the file attribute (with zipped files gives a DosError=5)}
procedure SetFAttr(var F :file; Attr: Word);
procedure SetFAttr(var F :text; Attr: Word);

{Returns TRUE if the file 'f' has been loaded from a ZIP}
Function  InsideZIP(var f:file):LongBool;
Function  InsideZIP(var f:text):LongBool;

{Returns the current file possition of 'f'}
function  FilePos( var f :file ):DWord;

{Assigns the name of an external file to a file variable}
Procedure Assign(var f:file; fname:string);
Procedure Assign(var f:file; fname:pchar);
Procedure Assign(var f:text; fname:string);
Procedure Assign(var f:text; fname:pchar);

{Opens an existing file for reading}
Procedure Reset(var f:file; l:DWord); {recsize=l}
Procedure Reset(var f:file); {recsize=128}
Procedure Reset(var f:typedfile); {DOESN'T WORK!!}
Procedure Reset(var f:text);

{Closes an opened file}
Procedure Close(var f:file);
Procedure Close(var f:text);

{Changes the current possition of a file to a specified possition}
procedure seek(var f:file; N:DWord);

{Returns true if the file have reached the end}
Function  EOF(var f:file):LongBool;
Function  EOF(var f:text):LongBool;

{Read from a file, returns the bytes readed}
procedure BlockRead(var F :file; var Buf; Count :DWord; var readed:DWord);
procedure BlockRead(var F :file; var Buf; Count :DWord);

{Reads from a typed file}
procedure Read(var f :typedfile; var v1);
procedure Read(var f :typedfile; var v1,v2);
procedure Read(var f :typedfile; var v1,v2,v3);
procedure Read(var f :typedfile; var v1,v2,v3,v4);
procedure Read(var f :typedfile; var v1,v2,v3,v4,v5);


function errormsg(err :DWord):String;

{Loads a seeking optimization file}
Procedure LoadOMZ(z :pZip; oname :string);

{Reads a string of a text file using a binary file handle}
function  TxtReadln(var f:file): string;


IMPLEMENTATION

uses
  STRINGS, {Null terminated strings handling routines}
  UNZIP    {tweaked InfoZIP's uncompression routines}
  ;

{$IFDEF ZFS_ERRORMSGS}
{$I ERRORS.INC}
{$ELSE}
function errormsg(err :DWord):String;
begin
  result:='Error messages not available';
end;
{$ENDIF}

type
  TextFunc = Procedure(var t : TextRec); {To call procedure pointers of text files}

  pFind = ^tFind;
  tFind = RECORD             {Internal use of FindFirst/FindNext}
    exp       :string;         {256 bytes long}
    attr      :word;
    zip       :pZip;
    mem       :pMemDir;
  end;

var
  OldExitProc :Pointer;     {Stores a temporal ExitProc}

type
  Local_File_Header_Type = packed record {ZIP archive header for packed files}
    Eytract_Version_Reqd   :Word;
    Bit_Flag               :Word;
    Compress_Method        :Word;
    Last_Mod_Time          :Word;
    Last_Mod_Date          :Word;
    Crc32                  :LongInt;
    Compressed_Size        :LongInt;
    Uncompressed_Size      :LongInt;
    Filename_Length        :Word;
    Extra_Field_Length     :Word;
  end;

var
  LocalHdr      :Local_File_Header_Type;  { temp. var. for a local file header }
  Hdr_FileName  :string; {temporal strings}
  Hdr_ExtraField:string;

{ Define the ZIP file header types }
const
  LOCAL_FILE_HEADER_SIGNATURE   = $04034B50;
  CENTRAL_FILE_HEADER_SIGNATURE = $02014B50;
  END_OF_CENTRAL_DIR_SIGNATURE  = $06054B50;

var
  pf:pZFSfile; {temporal var to store the address of the pZFSfile data}


{forward declaration of READFROMZIP, to be used by zipped TEXT type files}
function ReadFromZip( fil :pZFSfile; dst :pointer; count :DWord) :Longint; FORWARD;


function IOResult :DWord;
var a:word;
begin
  a:=System.IOResult;   {Result of the low-level file routines (RTL)}
  if a<>0 then IOResult:=a
          else IOResult:=ZFSResult;
  ZFSResult:=0;
end;


{iNITIALIZES a zIP oBJECT}
Procedure InitZO(fname:string; var zo :tZIP);
var res:longint;
begin
  {oppening the ZIP file}
  system.assign( zo.zFile, fName);
  res:=system.FileMode;
  system.FileMode := 64;  { Read Only }
  {$I-}system.reset(zo.zFile, 1);{$I+}
  system.FileMode:=res;
  res:=system.IOResult;
  if res<>0 then
   begin
     ZFSResult:=res;
     exit;
   end;
  {Initializing ZIP object variables}
  zo.Name := fname;
  zo.FirstMemDir := NIL;
end;

{Closes a ZIP file}
procedure CloseZO(var zo:tZIP);
begin
  {$I-}System.Close(zo.zFile);{$I+}
  ZFSResult:=System.IOResult;
end;

{Gets a local header of a zipped file}
function Read_Local_Hdr(var zo:tZip) : LongBool;
var
  Sig : longInt;
begin
  ZFSResult:=0;

  BlockRead(zo.zFile, sig, SizeOf(Sig));
  if Sig = CENTRAL_FILE_HEADER_SIGNATURE then
   begin
     Read_Local_Hdr := false;
   end {then}
  else
   begin
     if Sig <> LOCAL_FILE_HEADER_SIGNATURE then
      begin
        ZFSResult:=err_localhdr;  {Missing or invalid local file header in Zip file}
        EXIT;
      end;
     BlockRead(zo.zFile, LocalHdr, SizeOf(LocalHdr));
     with LocalHdr do
      begin
        if FileName_Length > 255 then
         begin
           ZFSResult:=err_longname; {Filename of a compressed file exceeds 255 chars!}
           EXIT;
         end;
        BlockRead(zo.zFile, Hdr_FileName[1], FileName_Length);
        Hdr_FileName[0] := Chr(FileName_Length);
        if Extra_Field_Length > 255 then
         begin
           ZFSResult:=err_longname; {Extra Field of a compressed file exceeds 255 chars!}
           EXIT;
         end;
        BlockRead(zo.zFile, Hdr_ExtraField[1], Extra_Field_Length);
        Hdr_ExtraField[0] := Chr(Extra_Field_Length);
      end {with};
     Read_Local_Hdr := true;
   end {else};
end;


{Normalize a filename for the routines - Uppercase with inverted slayer '\'}
function FormatFileName(s:string) : string;
var l:string; i:integer;
begin
  l:=s;
  for i:=1 to Length(s) do
   begin
     if s[i]='/' then l[i]:='\'
                 else l[i]:=UpCase(s[i]);
   end;
  Result:=l;
end;


{Adds a node at the end of the linked list of the .Zip directory}
Procedure AddMEMDir(ZIPf:pZIP; data:tFileZIP);
var
  tmp, tmp2 :pMEMDir;
begin
  ZFSResult:=0;

  new(Tmp);
  if Tmp=NIL then
   begin
     ZFSResult:=err_new;  {Unable to create a new node}
     exit;
   end;

  if ZIPf^.FirstMemDir=NIL then {if the list is empty...}
   ZIPf^.FirstMemDir:=Tmp
  else
   begin
     tmp2:=ZIPf^.FirstMemDir;
     while tmp2^.next<>NIL do   {searching for the last item in the list}
      begin
        tmp2:=tmp2^.next;
      end;
     tmp2^.next:=tmp;
   end;
  tmp^.next:=NIL;

  {Fills the list item with the file information}
  move(data, tmp^.obj, sizeof(tmp^.obj));
end;


{Erase the whole linked list of a r .zip directory}
Procedure KillMEMDir(ZIPf:pZIP);
var
  tmp,
  tmp2 :pMEMDir;

begin
  tmp:=ZIPf^.FirstMemDir;
  if tmp=NIL then {there isn't nothing to erase}
   begin
     exit;
   end
  else
   begin
     While tmp<>NIL do
      begin
        tmp2:=tmp^.NEXT;
        FreeMem(tmp^.Obj.Nom, StrLen(tmp^.Obj.Nom));
        Dispose(tmp);
        tmp:=Tmp2;
      end;
   end;
  ZIPf^.FirstMemDir:=NIL;
end;

{adds a node to the end of the zip files linked list}
Function AddZIP :pZIP;
var
  tmp, tmp2 :pZIP;
begin
  ZFSResult:=0;

  AddZIP:=NIL;
  new(Tmp);
  if Tmp=NIL then
   begin
     ZFSResult:=err_new;  {Unable to create a new node on ZIP linked list}
     exit;
   end;

  if FirstZIP=NIL then     {If it's the first ZIP oppened}
   begin
     FirstZIP:=Tmp;
     FirstZIP^.next:=NIL;
   end
  else
   begin
     tmp2:=FirstZIP;
     while tmp2^.next<>NIL do    {Searching for the last item in the list}
      begin
        tmp2:=tmp2^.next;
      end;
     tmp^.next:=NIL;
     tmp2^.next:=tmp;
   end;
  AddZIP:=tmp;
end;

{erases a node from the zips linked list}
Procedure EraseZIP(ZIPf :pZIP);
Var
  tmp :pZIP;  { Used to move through the list. }
begin
  if ZIPf = nil then
   begin     {The pointer is NIL, can not be erased}
     exit;
   end;

  if FirstZIP = nil then   { Is the list empty? }
   begin    {No nodes to be delete in this linked list}
     exit;
   end
  else
   begin
     if FirstZIP=ZIPf then
      begin
        FirstZIP:=ZIPf^.next;
        Dispose(ZIPf);
        exit;
      end;
   end;

  tmp := FirstZIP;
  While tmp^.Next <> ZIPf do
   begin
     tmp := tmp^.Next;
     if tmp=NIL then
      begin       {node not found in this linked list}
        exit;
      end;
   end;
  tmp^.Next := ZIPf^.Next;       { Point around old link }
  Dispose(ZIPf);              { Get rid of the link }
end;


{Adds a SeekInfo field to the SeekInfo linked list}
Procedure AddSeekInfo(f:pMemDir; seekat, uposs:DWord; wpos :word; val :DWord; len :word; p:pchar);
var
  tmp, tmp2 :pSeekList;
begin
  ZFSResult:=0;

  new(Tmp);
  if Tmp=NIL then
   begin
     ZFSResult:=err_new;  {Unable to create a new node on the packed files linked list}
     exit;
   end;

  if f^.Seek=NIL then {if the list is empty...}
   begin
     f^.Seek:=Tmp;
     f^.Seek^.next:=NIL;
   end
  else
   begin
     tmp2:=f^.Seek;
     if tmp2^.pos=seekat then {if it's already stored we exit}
      begin
        Dispose(tmp);
        exit;
      end;
     while tmp2^.next<>NIL do   {searching for the last item in the list}
      begin
        if tmp2^.pos=seekat then {if it's already stored we exit}
         begin
           Dispose(tmp);
           exit;
         end;
        tmp2:=tmp2^.next;
      end;
     tmp2^.next:=tmp;
     tmp^.next:=NIL;
   end;

  with tmp^ do   {Fills the list item with the file information}
   begin
     pos := seekat;
     upos := uposs;
     values := val;
     SlidePos := wpos;
     SlideLen := len;
     GetMem(slide, len);
     Move(p[0], slide[0], len);
   end;
end;


{erases the whole linked list of seeking information for a file}
Procedure KillSeekInfo(pzf :pZFSFile);
var
  tmp,
  tmp2 :pSeekList;
begin
  tmp:=pzf^.FirstSeek;
  if tmp=NIL then {there isn't nothing to erase}
   begin
     exit;
   end
  else
   begin
     While tmp<>NIL do
      begin
        tmp2:=tmp^.NEXT;
        FreeMem(tmp^.slide, tmp^.slidelen);
        Dispose(tmp);
        tmp:=Tmp2;
      end;
   end;
  pzf^.FirstSeek:=NIL;
end;


{Opens a zip archive and initializes it}
Function OpenZIP (ZIPName :string; Mode:LongBool ):pZIP;
{the files of the zip are included in the current system path, so if
you open 'c:\data\mypics.zip' and the current directory is 'd:\showit\' the
files will be listed in 'd:\showit\'}
var
  ZIPf:pZIP;
  dat:tfileZip;
  zdir, zname, zext :string;
  i :Longint;
begin
{$I-}
  ZFSResult:=0;
  OpenZIP:=NIL;

  ZIPf:=AddZIP;
  if ZFSResult<>0 then Exit;

  InitZO(ZipName, ZIPf^);
  if ZFSResult<>0 then
   begin
     EraseZIP(ZIPf);
     Exit;
   end;

  FSplit(ZIPName, Zdir, Zname, Zext);

  ZIPf^.Name:=Zname+Zext;
  ZIPf^.DirMode:=Mode;

  ZIPf^.NumFiles:=0;
  ZIPf^.FirstMemDir:=NIL;
  while Read_Local_Hdr(ZIPf^) do
   begin
     inc(ZIPf^.NumFiles,1);

     if Mode=DirMode then
      begin
        Zname:=Zname+'\'+Hdr_FileName;
        GetMem(dat.Nom, sizeof(zname));
        StrPCopy(dat.Nom, Zname);
      end
     else
      begin
        GetMem(dat.Nom, sizeof(Hdr_FileName));
        StrPCopy(dat.Nom, Hdr_FileName);
      end;

     dat.Kind:=LocalHdr.Compress_Method;
     dat.pos:=system.FilePos(ZIPf^.zfile);
     dat.Size:=LocalHdr.Compressed_Size;
     dat.USize:=LocalHdr.UnCompressed_Size;
     dat.Time:=(LocalHdr.Last_Mod_Date SHL 16)+LocalHdr.Last_Mod_Time;

     addMemDir(ZIPf, dat);
     Seek(ZIPf^.zFile, dat.Pos+dat.Size);
   end;

  OpenZIP:=ZIPf;
{$I+}
end;

Function  OpenZIP (ZIPName :pChar; Mode:LongBool ):pZIP;
begin
  result:=OpenZIP(StrPas(ZIPName), mode);
end;

{Closes an oppened zip file}
Procedure CloseZIP(ZIPf:pZIP);
begin
{$I-}
  ZFSResult:=0;

  if ZIPf=NIL then
   begin
     ZFSResult:=err_Dispose; {the ZIP file is NIL and can't be erased}
     Exit;
   end;

  KillMEMDir(ZIPf); {Kills the list of files}
  CloseZO(ZIPf^);   {Closes the ZIP Object}
  EraseZIP(ZIPf);   {Kills the ZIP object from the oppened zip list}
{$I+}
end;


{Looks if exists a file or a directory in the disk or in the oppened zips}
FUNCTION FileExist( sExp :STRING ): LongBool;
VAR
  s       :SearchRec;
  tmpZIP  :pZIP;
  tmpDir  :pMEMDir;
BEGIN
{$I-}
  DOS.FindFirst( sExp, Archive+Directory, s );
  if DOSError=0 then {If the file have been found on disk...}
   begin
     FileExist:=true;
     Exit;
   end;

  if FirstZIP=NIL then {No oppened ZIPS, so not found}
   begin
     FileExist:=False;
     exit;
   end;

  tmpZIP:=FirstZIP;
  REPEAT

    if tmpZIP^.FirstMemDir<>NIL then {If there are any file in the ZIP}
     begin
       tmpDir:=tmpZIP^.FirstMemDir;
       REPEAT
         if FormatFileName(tmpDir^.Obj.Nom)=FormatFileName(sExp) then
          begin
            FileExist:=TRUE;
            exit;
          end;

         tmpDir:=tmpDir^.Next;
       UNTIL tmpDir=NIL;
     end;

    tmpZIP:=tmpZIP^.next;
  UNTIL tmpZIP=NIL;

  FileExist := False;  {File not found}
{$I+}
END;

FUNCTION FileExist( sExp :pChar ): LongBool;
begin
  result:=FileExist(StrPas(sExp));
end;

procedure GetFTime(var F :file; var Time: Longint);
begin
  if filerec(f).UserData[16]=127 then {If is a zipped file}
   begin
     move(filerec(f).UserData[1], pf, 4);
     time:=pf^.time;
   end
  else
   dos.GetFTime(f, time);
end;

procedure GetFTime(var F :text; var Time: Longint);
begin
  if textrec(f).UserData[16]=127 then {If is a zipped file}
   begin
     move(textrec(f).UserData[1], pf, 4);
     time:=pf^.time;
   end
  else
   dos.GetFTime(f, time);
end;

procedure SetFTime(var F :file; Time: Longint);
begin
  if filerec(f).UserData[16]=127 then {If is a zipped file}
   begin
     move(filerec(f).UserData[1], pf, 4);
     pf^.time:=time;
   end
  else
   dos.SetFTime(f, time);
end;

procedure SetFTime(var F :text; Time: Longint);
begin
  if textrec(f).UserData[16]=127 then {If is a zipped file}
   begin
     move(textrec(f).UserData[1], pf, 4);
     pf^.time:=time;
   end
  else
   dos.SetFTime(f, time);
end;

procedure GetFAttr(var F :file; var Attr: Word);
begin
  if filerec(f).UserData[16]=127 then {If is a zipped file}
   begin
     attr:=Zipped;
   end
  else
   dos.GetFAttr(f, attr);
end;

procedure GetFAttr(var F :text; var Attr: Word);
begin
  if textrec(f).UserData[16]=127 then {If is a zipped file}
   begin
     attr:=Zipped;
   end
  else
   dos.GetFAttr(f, attr);
end;

procedure SetFAttr(var F :file; Attr: Word);
begin
  if filerec(f).UserData[16]=127 then {If is a zipped file}
   begin
     DosError:=5;  {Cannot change a zipped file attribute}
   end
  else
   dos.SetfAttr(f, attr);
end;

procedure SetFAttr(var F :text; Attr: Word);
begin
  if textrec(f).UserData[16]=127 then {If is a zipped file}
   begin
     DosError:=5;  {Cannot change a zipped file attribute}
   end
  else
   dos.SetfAttr(f, attr);
end;


{Returns TRUE if the file variable (f) is associated to a zipped file}
Function InsideZIP(var f:file):LongBool;
begin
  if (filerec(f).UserData[16]=127) then result:=true
                                   else result:=false;
end;

Function InsideZIP(var f:text):LongBool;
begin
  if (textrec(f).UserData[16]=127) then result:=true
                                   else result:=false;
end;


{################# FPC RTL patched routines ################}

{Used to read from the zipped text type files}
Procedure ZFS_FileReadFunc(var f:TextRec);
var res :longint;
Begin
  ZFSResult:=0;

  if f.handle=0 then
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  move(f.UserData[1], pf, 4);

  res := ReadFromZip(pf, f.bufptr, f.bufsize);
  if res<>0 then
   begin
     ZFSResult:=res;
     exit;
   end;
  f.BufPos:=0;
  f.BufEnd:=zfs_reachedbytes-zfs_toreachbytes;
End;

{Used to read from the zipped text type files}
Procedure ZFS_FileOpenFunc(var f:TextRec);
Begin
  f.CloseFunc:=nil;
  f.FlushFunc:=nil;
  f.InOutFunc:=@ZFS_FileReadFunc;
End;


Procedure Assign(var f:file; fname:string);
BEGIN
  FillChar(f, SizeOf(FileRec), 0);
  FileRec(f).Handle:=UnusedHandle;
  FileRec(f).mode:=fmClosed;
  Move(fName[1], FileRec(f).Name, Length(fName));
end;

Procedure Assign(var f:file; fname:pchar);
begin
  Assign(f, strpas(fname));
end;

Procedure Assign(var f:text; fname:string);
BEGIN
  FillChar(f, SizeOf(TextRec), 0);
  TextRec(f).Handle:=UnusedHandle;
  TextRec(f).mode:=fmClosed;
  TextRec(f).BufSize:=TextRecBufSize;
  TextRec(f).BufPtr:=@TextRec(f).Buffer;
  TextRec(f).OpenFunc:=@ZFS_FileOpenFunc;
  Move(fName[1], TextRec(f).Name, Length(fName));
end;

Procedure Assign(var f:text; fname:pchar);
begin
  Assign(f, strpas(fname));
end;


Procedure Reset(var f:file; l:DWord);
VAR
  fname   :string;
  s       :SearchRec;
  tmpZIP  :pZIP;
  tmpDir  :pMEMDir;
  tmpFile :pZFSFile;
  res     :longint;
BEGIN
{$I-}
  ZFSResult:=0;

  fname:=strpas(filerec(f).Name);

  DOS.FindFirst( fname, Archive, s );
  if DOSError=0 then
   begin
     FileRec(f).Handle:=UnusedHandle;
     system.reset(f,l);
     res:=system.IOResult;
     If res<>0 then
      begin
        ZFSResult:=res;
        exit;
      end;
     fillchar( filerec(f).UserData[1], 16, 0 ); {Clear the UserData field}

     Exit;
   end;

  if FirstZIP=NIL then {No oppened ZIPS}
   begin
     ZFSResult:=2; {File not found}
     exit;
   end;

  tmpZIP:=FirstZIP;
  REPEAT

    if tmpZIP^.FirstMemDir<>NIL then {If there are any file in the ZIP}
     begin
       tmpDir:=tmpZIP^.FirstMemDir;
       REPEAT
         if FormatFileName(tmpDir^.Obj.Nom)=FormatFileName(fname) then
          begin
            fillchar( f, sizeof(f), 0 );

            new(tmpFile);
            if tmpFile=NIL then begin ZFSResult:=err_new; exit; end;

            tmpFile^.ZIP:=tmpZIP;
            tmpFile^.comp:=tmpDir^.Obj.Kind;
            tmpFile^.pos:=tmpDir^.Obj.Pos;
            tmpFile^.size:=tmpDir^.Obj.Size;
            tmpFile^.USize:=tmpDir^.Obj.USize;
            tmpFile^.curr:=0;
            tmpFile^.time:=tmpDir^.Obj.Time;
            tmpFile^.FirstSeek:=tmpDir^.Seek;

            filerec(f).handle:=$FFFF;
            filerec(f).Mode:=fmZipped;
            filerec(f).RecSize:=l;
            filerec(f).UserData[16]:=127;

//            move( ofs(tmpfile), filerec(f).UserData[1], 4);
            move( tmpfile, filerec(f).UserData[1], 4);
            move( fName[1], FileRec(f).Name, Length(fName));


            exit;
          end;

         tmpDir:=tmpDir^.Next;
       UNTIL tmpDir=NIL;
     end;

    tmpZIP:=tmpZIP^.next;
  UNTIL tmpZIP=NIL;

  ZFSResult:=2; {File not found}
{$I+}
end;

Procedure Reset(var f:file);
begin
  Reset(f, 128);
end;

{DOESN'T WORK!!}
Procedure Reset(var f:typedfile);
begin
  {Use Reset(typed file, sizeof(component))}
  ZFSResult:=err_resetbug;
end;

Procedure Reset(var f:text);
VAR
  fname   :string;
  s       :SearchRec;
  tmpZIP  :pZIP;
  tmpDir  :pMEMDir;
  tmpFile :pZFSFile;
  res     :longint;
BEGIN
{$I-}
  ZFSResult:=0;

  fname:=strpas(textrec(f).Name);

  DOS.FindFirst( fname, Archive, s );
  if DOSError=0 then
   begin
     system.assign(f, fname);
     textRec(f).Handle:=UnusedHandle;
     system.reset(f);
     res:=system.IOResult;
     If res<>0 then
      begin
        ZFSResult:=res;
        exit;
      end;

     fillchar( textrec(f).UserData[1], 16, 0 ); {Clear the UserData field}

     Exit;
   end;

  if FirstZIP=NIL then {No oppened ZIPS}
   begin
     ZFSResult:=2; {File not found}
     exit;
   end;

  tmpZIP:=FirstZIP;
  REPEAT

    if tmpZIP^.FirstMemDir<>NIL then {If there are any file in the ZIP}
     begin
       tmpDir:=tmpZIP^.FirstMemDir;
       REPEAT
         if FormatFileName(tmpDir^.Obj.Nom)=FormatFileName(fname) then
          begin
            new(tmpFile);

            tmpFile^.ZIP:=tmpZIP;
            tmpFile^.comp:=tmpDir^.Obj.Kind;
            tmpFile^.pos:=tmpDir^.Obj.Pos;
            tmpFile^.size:=tmpDir^.Obj.Size;
            tmpFile^.USize:=tmpDir^.Obj.USize;
            tmpFile^.curr:=0;
            tmpFile^.time:=tmpDir^.Obj.Time;
            tmpFile^.FirstSeek:=NIL; {tmpDir^.Seek;}
            {In theory text files doen't support seek}

            textrec(f).handle:=$FFFF;
            textrec(f).Mode:=fmInput;      {fmZipped}
            {It needs to be fmInput instead of fmZipped because I want to
            use some RTL routines for text type files}
            textrec(f).bufpos:=0;
            textrec(f).bufend:=0;
            TextFunc(textrec(f).openfunc)(textrec(f));
            textrec(f).UserData[16]:=127;

//            move( ofs(tmpfile), textrec(f).UserData[1], 4);
            move( tmpfile, textrec(f).UserData[1], 4);
            move( fName[1], textRec(f).Name, Length(fName));

            exit;
          end;

         tmpDir:=tmpDir^.Next;
       UNTIL tmpDir=NIL;
     end;

    tmpZIP:=tmpZIP^.next;
  UNTIL tmpZIP=NIL;

  ZFSResult:=2; {File not found}
{$I+}
end;


Procedure Close(var f:file);
var res:longint;
BEGIN
{$I-}
  ZFSResult:=0;

  if filerec(f).handle=0 then
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  if filerec(f).Mode<>fmZipped then   {if it's not inside a ZIP...}
   begin
     system.Close(f);
     res:=system.IOResult;
     if res<>0 then
      begin
        ZFSResult:=res;
        exit;
      end;
   end
  else
   begin
     move(filerec(f).UserData[1], pf, 4);
     KillSeekInfo(pf);
     filerec(f).mode:=fmclosed;
   end;
{$I+}
end;

Procedure Close(var f:text);
var res:longint;
BEGIN
{$I-}
  ZFSResult:=0;

  if textrec(f).handle=0 then
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  if textrec(f).UserData[16]<>127 then   {if it's not inside a ZIP...}
   begin
     system.Close(f);
     res:=system.IOResult;
     if res<>0 then
      begin
        ZFSResult:=res;
        exit;
      end;
   end
  else
   begin
     {move(textrec(f).UserData[1], pf, 4);
     KillSeekInfo(pf);}
     {Text files doesn't support seeking}
     textrec(f).mode:=fmClosed;
     textrec(f).BufPos:=0;
     textrec(f).BufEnd:=0;
   end;
{$I+}
end;


procedure seek(var f:file; N:DWord);
begin
{$I-}
  ZFSResult:=0;

  if filerec(f).handle=0 then
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  if filerec(f).Mode=fmZipped then    {if it's in a ZIP}
   begin
     move(filerec(f).userdata[1], pf, 4);

     if pf^.Comp=0 then
      begin
        if (N>pf^.USize) or (N<0) then
         begin
           ZFSResult:=err_seeking;  {Error seeking the packed file : Out of boundaries}
           exit;
         end;

        system.seek(pf^.ZIP^.zfile, pf^.POS+N);
        ZFSResult:=system.IOResult;
        pf^.Curr:=N;
      end
     else
      begin
        if (N>pf^.USize) or (N<0) then
         begin
           ZFSResult:=err_seeking;
           exit;
         end;

        pf^.Curr:=N;
      end;
   end
  else
   begin
     system.seek(f, n);
     ZFSResult:=System.IOResult;
   end;
{$I-}
end;


function FilePos(var f :file):DWord;
begin
  move(filerec(f).UserData[1], pf, 4);

  if filerec(f).Mode=fmZipped then  {If it's on a ZIP file ...}
   FilePos:=pf^.Curr
  else                              {If not ...}
   FilePos:=System.FilePos(f);
end;


function FileSize(var f :file):DWord;
begin
  move(filerec(f).UserData[1], pf, 4);

  if filerec(f).Mode=fmZipped then  {If it's on a ZIP file ...}
   FileSize:=pf^.USize div filerec(f).RecSize
  else                              {If not ...}
   FileSize:=System.FileSize(f);
end;

{This function is used to read binary data from a zip file}
function ReadFromZip( fil :pZFSfile; dst :pointer; count :DWord) :Longint;
var
  readed :DWord;
  tmpseek, nextseek :pSeekList;
  seekat :DWord;
  b      :Longint;
  k      :byte;
  w      :word;
  slide  :pchar;
  slidesize :dword;
  reached:DWord;
begin
{$I-}
  result:=0;

  if fil^.Curr>=fil^.Usize then EXIT;

  if (fil^.curr+Count)>fil^.USize then
   begin {The requested data exceeds the file limits}
     Count:=fil^.USize-fil^.Curr;
     if count<=0 then exit;
   end;

  case fil^.Comp of
    0 :begin {stored}
         system.Seek(fil^.ZIP^.zfile, fil^.pos+fil^.curr);
         result:=system.IOResult;
         if result<>0 then exit;

         system.BlockRead(fil^.ZIP^.zfile, dst^, Count, Readed);
         result:=system.IOResult;
         if result<>0 then exit;
         fil^.curr:=fil^.curr+Readed;
       end {case|0};
    else
     begin
       if ((1 SHL fil^.comp) AND GetSupportedMethods) = 0 then
        begin  {compression method not supported!!!}
          result := err_method;
          exit;
        end;

       {Takes care of seeking information}
       NextSeek:=NIL;
       tmpSeek:=fil^.FirstSeek;
       While tmpSeek<>NIL do
        begin
          if tmpSeek^.upos<fil^.Curr then
           begin
             if NextSeek=NIL then
              NextSeek:=tmpSeek
             else
              begin
                if tmpSeek^.upos>NextSeek^.upos then
                 NextSeek:=tmpSeek;
              end;
           end;
          tmpSeek:=tmpSeek^.next;
        end;

       if NextSeek<>NIL then
        begin
          Seekat:=nextseek^.pos;
          reached:=nextseek^.upos;
          b:=Lo(nextseek^.values);
          k:=Hi(nextseek^.values);
          w:=nextseek^.slidepos;
          slide:=nextseek^.slide;
          slidesize:=nextseek^.slideLen;
        end
       else
        begin
          seekat:=0;
          reached:=0;
          w:=0;
          b:=0;
          k:=0;
          slide:=NIL;
          slidesize:=0;
        end;
//       WriteLN('SEEKING AT : ',seekat,' --- real pos : ',reached);

       {Set-up some unzipping engine variables}
       zfs_reachedbytes:=reached;
       zfs_toreachbytes:=fil^.Curr;
       zfs_neededsize:=Count;
       zfs_outofs:=0;
       zfs_outbuf:=dst;

       {Unzips the file}
       result:=unzipfile (fil^.ZIP^.zfile, fil^.pos, fil^.size, fil^.comp,
                          seekat, W, B, K, slide, slidesize);

       {compute the results of the unziping}
       case result of
         unzip_WriteErr     : ZFSResult:=err_write;   {Write error while decompressing}
         unzip_ReadErr      : ZFSResult:=err_read;    {Read error while decompressing}
         unzip_ZipFileErr   : ZFSResult:=err_zipfile; {Error in Zip file}
         unzip_NotSupported : ZFSResult:=err_method;  {Compression method not supported}
       end;
       if result<>0 then exit;

       fil^.Curr:=fil^.Curr+zfs_neededsize;
       if fil^.Curr>fil^.USize then fil^.Curr:=fil^.Usize;
     end {case|else};
  end {case};
{$I+}
end;


procedure BlockRead(var F :file; var Buf; Count :DWord; var readed :DWord);
var res:longint;
begin
{$I-}
  ZFSResult:=0;

  if Count=0 then EXIT;

  if filerec(f).handle=0 then
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  if filerec(f).Mode=fmZipped then
   begin
     move(filerec(f).UserData[1], pf, 4);

     res := ReadFromZip(pf, pointer(@buf), Count*filerec(f).RecSize);
     if res<>0 then
      begin
        ZFSResult:=res;
        exit;
      end;

     readed:=(zfs_reachedbytes-zfs_toreachbytes) div filerec(f).RecSize;
   end
  ELSE {Not InZIP}
   begin
     system.BlockRead(f, Buf, Count, Readed);
     res:=system.IOResult;
     if res<>0 then
      begin
        ZFSResult:=res;
        exit;
      end;
   end;
{$I+}
end;

procedure BlockRead(var F :file; var Buf; Count :DWord);
var l:DWord;
begin
  BlockRead(f, buf, count, l);
end;


procedure Read (var f :typedfile; var v1);
begin
  BlockRead(f, v1, 1);
end;

procedure Read (var f :typedfile; var v1,v2);
begin
  BlockRead(f, v1, 1); BlockRead(f, v2, 1);
end;

procedure Read (var f :typedfile; var v1,v2,v3);
begin
  BlockRead(f, v1, 1); BlockRead(f, v2, 1); BlockRead(f, v3, 1);
end;

procedure Read (var f :typedfile; var v1,v2,v3,v4);
begin
  BlockRead(f, v1, 1); BlockRead(f, v2, 1); BlockRead(f, v3, 1);
  BlockRead(f, v4, 1);
end;

procedure Read (var f :typedfile; var v1,v2,v3,v4,v5);
begin
  BlockRead(f, v1, 1); BlockRead(f, v2, 1); BlockRead(f, v3, 1);
  BlockRead(f, v4, 1); BlockRead(f, v5, 1);
end;


Function EOF(var f:file):LongBool;
begin
{$I-}
  EOF:=FALSE;

  if filerec(f).handle<>0 then
   begin
     if filerec(f).Mode=fmZipped then
      begin
        move(filerec(f).UserData[1], pf, 4);
        EOF:=(pf^.Curr>=pf^.USize);
        exit;
      end
     else
      begin
        EOF:=SYSTEM.EOF(f);
      end;
   end
  else
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  ZFSResult:=system.IOResult;
{$I+}
end;

Function EOF(var f:text):LongBool;
begin
{$I-}
  EOF:=FALSE;

  if textrec(f).handle<>0 then
   begin
     if textrec(f).UserData[16]=127 then
      begin
        move(textrec(f).UserData[1], pf, 4);
        EOF:=(pf^.Curr>=pf^.USize) AND (textrec(f).bufpos>=textrec(f).bufend);
        exit;
      end
     else
      begin
        EOF:=SYSTEM.EOF(f);
      end;
   end
  else
   begin
     ZFSResult:=103; {RTE 103 : File not oppened}
     exit;
   end;

  ZFSResult:=system.IOResult;
{$I+}
end;


Procedure KillZIPs;
var
  tmp,
  tmp2 :pZIP;
begin
  tmp:=FirstZIP;
  if tmp=NIL then              {there is nothing to close}
  else
   begin
     While tmp<>NIL do
      begin
        tmp2:=tmp^.NEXT;
        CloseZIP(tmp);
        tmp:=Tmp2;
      end;
   end;
  FirstZIP:=NIL;
end;

{#################### End of RTL pathed routines #####################}


{Closes all the oppened zip files automatically when we stop the program}
procedure ZIPExitProc;
begin
  ExitProc:=OldExitProc;        {restore the original exit}
  KillZIPs;
end;


{Reads a text line from a binary file (original from Just4Fun)}
function TxtReadLn(var f :file) :string;
var
  s    : string;
  c    : char;
  done : boolean;
  arr  : array [0..255] of char;
  idx  : longint;
  len  : longint;
begin
   result := '';

   if eof(f) then exit;

   s:='';
   idx:=0;
   done:=false;

   blockread(f, arr, 256, len);
   repeat
     c:=arr[idx];   inc(idx,1);
     if (c=char(13)) or (c=char(10)) then
      begin
        done:=true;
        c:=arr[idx];   inc(idx,1);
        seek(f,filepos(f)-len+idx);
      end
     else s:=s+c;

     if idx>len then
      begin
        if len<>256 then done:=true    {End of file}
                    else BlockRead(f, arr, 256, len);
        idx:=0;
      end;
   until done;

  Result:=s;
END;


{Generates a SeekInfo linked list from an encoded seek info data}
Procedure ProcessOMZ(z :pZip; buf :pchar; size :DWord);
var
  tmpDir  :pMEMDir;    {Temporal for listing of files}
  name    :string;
  val     :DWord;
  pos     :DWord;
  upos    :DWord;
  w       :Word;
  len     :Word;
  p       :pchar;
  i       :DWord;
  found   :boolean;

  Function GetData :Boolean;
  begin
    result:=true;
    if buf[i]=#255 then begin inc(i,1); result:=false; exit; end;
    Move(pointer(@buf[i])^, pos, 4);
    Move(pointer(@buf[i+4])^, upos, 4);
    Move(pointer(@buf[i+8])^, val, 4);
    Move(pointer(@buf[i+12])^, w, 2);
    Move(pointer(@buf[i+14])^, len, 2);
    GetMem(p, len);
    Move(pointer(@buf[i+16])^, p[0], len);
    inc(i,16+len);
  end;

begin
  if z=NIL then Exit;
  if buf=NIL then Exit;
  i:=0;

  name[0]:=#3;
  Move(pointer(@buf[i])^, name[1], 3);
  if name<>OMZSignature then
   begin
     ZFSResult:=err_wrongOMZ; {OMZ not valid}
     exit;
   end;
  inc(i,3);

  While (i<size) DO
   begin
     found:=false;
     Name:=StrPas(pchar(buf+i));
     inc(i, ord(name[0])+1);

     tmpDir:=z^.FirstMemDir;
     While tmpDir<>NIL DO
      begin
        if FormatFileName(StrPas(tmpdir^.obj.Nom))=FormatFileName(name) then
         begin
           found:=true;
           While (GetData) AND (i<=size) do
            begin
              AddSeekInfo(tmpDir, pos, upos, w, val, len, p);
              FreeMem(p,len);
            end;
         end;

        tmpDir:=tmpDir^.Next;
      end;

     if NOT(found) then
      begin
        While (GetData) AND (i<=size) do
         begin
           FreeMem(p,len);
         end;
      end;
   end;
end;

{Loads an optimizing seeking data file}
Procedure LoadOMZ(z :pZip; oname :string);
var
  f:file;
  p:pchar;
  s:DWord;
begin
  if z=NIL then Exit;

  Assign(f,oname);
  {$I-} Reset(f,1); {$I+}
  if ZFSResult<>0 then exit;
  s:=FileSize(f);

  GetMem(p, s);
  BlockRead(f, p^, s);

  ProcessOMZ(z, p, s);

  FreeMem(p, s);
  Close(f);
end;



BEGIN
//  OldExitProc:=ExitProc;
//  ExitProc:=@ZIPExitProc;
END.
