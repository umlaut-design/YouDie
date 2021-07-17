UNIT Unzip;
{
  Based on C code by info-zip group
  Original pascal conversion by Christian Ghisler, portions by Mark Adler
  Improved by Dr Abimbola Olowofoyeku (The African Chief)
  Free Pascal port by Peter Vreman
  Adaptations for its use with ZIP File System by Iv n Montes (drslump@mundomail.net)

  Last modification 10-MAY-99

  * Only supports the Deflated method
}

{$MODE objfpc}

{$I DEFINES.INC}

INTERFACE

CONST
  unzip_Ok               =   0;
  unzip_Reached          =   1;
  unzip_WriteErr         = - 1;
  unzip_ReadErr          = - 2;
  unzip_ZipFileErr       = - 3;
  unzip_NotEnoughMem     = - 4;
  unzip_NotSupported     = - 5;

  {$IFDEF ZFS_SEEKING_INFO}
  SeekingInfo  :Boolean  =FALSE;
  {$ENDIF}


VAR
  zfs_ReachedBytes :dword;
  zfs_ToReachBytes :dword;
  zfs_NeededSize   :dword;
  zfs_OutBuf       :pointer;
  zfs_OutOfs       :dword;



FUNCTION GetSupportedMethods : DWord;
{Checks which pack methods are supported by the unit}
{bit 8=1 -> Format 8 supported, etc.}
FUNCTION unzipfile (var in_file :file; offset, csize, ztype, seekat :DWord; initw:word; B:longint; k:byte; comprslide :pchar; comprsize :DWord):longint;


{$IFDEF ZFS_SEEKING_INFO}
var
  Outname    :string;
  firstdone  :Boolean;
  ZIP        :file;    {ZIP archive}

type
  pFileZIP = ^tFileZIP;
  tFileZIP = record {Packed Files info}
    Nom   :string;      {file name}
    Kind  :Longint;     {0:Store, 1:LZW, 2:..., 8:HUFFMAN}
    Pos   :DWord;       {file position in the ZIP}
    Size  :DWord;       {file size}
    USize :DWord;       {Uncompressed size}
    next  :pFileZip;
  end;

const
  FirstFileZip :pFileZip =NIL;

procedure OpenZIP(name:string);
procedure CloseZIP;
Procedure GetZIPfiles;
{$ENDIF}

IMPLEMENTATION

{*************************************************************************}
{global constants, types and variables}

CONST   {Error codes returned by huft_build}
  huft_complete  = 0;   {Complete tree}
  huft_incomplete = 1;  {Incomplete tree <- sufficient in some cases!}
  huft_error     = 2;   {bad tree constructed}
  huft_outofmem  = 3;   {not enough memory}
  MaxMax = 256 * 1024;  {256kb buffer}

CONST
  wsize = 32768;            {Size of sliding dictionary}
  INBUFSIZ = 1024 * 4;      {Size of input buffer}

CONST
  lbits : longint = 9;
  dbits : longint = 6;

CONST
  b_max = 16;
  n_max = 288;
  BMAX = 16;

TYPE
  push = ^ush;
  ush = word;
  pbyte = ^byte;
  pushlist = ^ushlist;
  ushlist = ARRAY [ 0..maxmax ] of ush;  {only pseudo-size!!}
  pword = ^word;
  pwordarr = ^twordarr;
  twordarr = ARRAY [ 0..maxmax ] of word;
  iobuf = ARRAY [ 0..inbufsiz - 1 ] of byte;

TYPE
  pphuft = ^phuft;
  phuft = ^huft;
  phuftlist = ^huftlist;
  huft = PACKED RECORD
    e,             {# of extra bits}
    b : byte;        {# of bits in code}
    v_n : ush;
    v_t : phuftlist; {Linked List}
  END;
  huftlist = ARRAY [ 0..8190 ] of huft;

VAR
  slide : pchar;            {Sliding dictionary for unzipping}
  inbuf : iobuf;            {input buffer}
  inpos, readpos : longint;  {position in input buffer, position read from file}

VAR
  w : word;                 {Current Position in slide}
  b : longint;              {Bit Buffer}
  k : byte;                 {Bits in bit buffer}
  infile :file;             {handle to zipfile}
  compsize,                 {comressed size of file}
  reachedsize :DWord;       {number of bytes read from zipfile}
  zipeof : boolean;         {read over end of zip section for this file}

{$IFDEF ZFS_SEEKING_INFO}
  oldPos    :DWord;
  oldUPos   :DWord;
  oldK      :byte;
  oldB      :longint;
  oldW      :word;
  slidefile :file;
  oldslide  :pchar;
{$ENDIF}


{b and mask_bits[i] gets lower i bits out of i}
CONST
  mask_bits : ARRAY [ 0..16 ] of word =
    ( $0000,
      $0001, $0003, $0007, $000f, $001f, $003f, $007f, $00ff,
      $01ff, $03ff, $07ff, $0fff, $1fff, $3fff, $7fff, $ffff );

{ Tables for deflate from PKZIP's appnote.txt. }

CONST
  border : ARRAY [ 0..18 ] of byte =   { Order of the bit length code lengths }
    ( 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 );
  cplens : ARRAY [ 0..30 ] of word =    { Copy lengths for literal codes 257..285 }
    ( 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
      35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 0, 0 );
{ note: see note #13 above about the 258 in this list.}
  cplext : ARRAY [ 0..30 ] of word =    { Extra bits for literal codes 257..285 }
    ( 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
      3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, 99, 99 ); { 99==invalid }
  cpdist : ARRAY [ 0..29 ] of word =     { Copy offsets for distance codes 0..29 }
    ( 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
      257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
      8193, 12289, 16385, 24577 );
  cpdext : ARRAY [ 0..29 ] of word =    { Extra bits for distance codes }
    ( 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
      7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
      12, 12, 13, 13 );

{ Tables for explode }
  cplen2 : ARRAY [ 0..63 ] of word =
    ( 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
      18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
      35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
      52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65 );
  cplen3 : ARRAY [ 0..63 ] of word =
    ( 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
      19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
      36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
      53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66 );
  extra : ARRAY [ 0..63 ] of word =
    ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      8 );
  cpdist4 : ARRAY [ 0..63 ] of word =
    ( 1, 65, 129, 193, 257, 321, 385, 449, 513, 577, 641, 705,
      769, 833, 897, 961, 1025, 1089, 1153, 1217, 1281, 1345, 1409, 1473,
      1537, 1601, 1665, 1729, 1793, 1857, 1921, 1985, 2049, 2113, 2177,
      2241, 2305, 2369, 2433, 2497, 2561, 2625, 2689, 2753, 2817, 2881,
      2945, 3009, 3073, 3137, 3201, 3265, 3329, 3393, 3457, 3521, 3585,
      3649, 3713, 3777, 3841, 3905, 3969, 4033 );
  cpdist8 : ARRAY [ 0..63 ] of word =
    ( 1, 129, 257, 385, 513, 641, 769, 897, 1025, 1153, 1281,
      1409, 1537, 1665, 1793, 1921, 2049, 2177, 2305, 2433, 2561, 2689,
      2817, 2945, 3073, 3201, 3329, 3457, 3585, 3713, 3841, 3969, 4097,
      4225, 4353, 4481, 4609, 4737, 4865, 4993, 5121, 5249, 5377, 5505,
      5633, 5761, 5889, 6017, 6145, 6273, 6401, 6529, 6657, 6785, 6913,
      7041, 7169, 7297, 7425, 7553, 7681, 7809, 7937, 8065 );


{$IFDEF ZFS_SEEKING_INFO}
type
  pSlideData = ^tSlideData;
  tSlideData = RECORD
    d     :Word;
    w     :Word;
    len   :Word;
    next  :pSlideData;
    prev  :pSlideData;
  end;

const
  FirstSlideData :pSlideData =NIL;
  LastSlideData  :pSlideData =NIL;

procedure AddSlideData(dd,ww,l:word);
var sd,tmp :pSlideData;
begin
  new(sd);
  sd^.prev:=FirstSlideData;
  sd^.next:=NIL;

  if LastSlideData=NIL then
   FirstSlideData:=sd
  else
   LastSlideData^.next:=sd;

  LastSlideData:=sd;

  sd^.d:=dd;
  sd^.w:=ww;
  sd^.len:=l;
end;

procedure KillSlideData;
var tmp,tmp2 :pSlideData;
begin
  tmp:=FirstSlideData;
  if tmp=NIL then {there isn't nothing to erase}
   begin
     exit;
   end
  else
   begin
     While tmp<>NIL do
      begin
        tmp2:=tmp^.NEXT;
        Dispose(tmp);
        tmp:=Tmp2;
      end;
   end;
  FirstSlideData:=NIL;
  LastSlideData:=NIL;
end;

Function ComputeSlideData(var fo:file; initw:word) :DWord;
var
  tmp   :pSlideData;
  currw :Word;
  p, q  :pchar;
  i, j  :Longint;
begin
  GetMem(p, wsize);
  FillChar(p[0], wsize, #0);

  q:=oldslide;

  FillChar(p[0], initw, #255);   {the bytes currently decompressed}

  tmp:=FirstSlideData;
  While tmp<>NIL do
   begin
     if tmp^.w<=initw then currw:=wsize+tmp^.w
                      else currw:=tmp^.w;

     if NOT((tmp^.d>initw) AND (tmp^.d<currw)) then
      begin
        FillChar(p[tmp^.d], tmp^.len, #255);
      end;

     tmp:=tmp^.next;
   end;

  result:=0;
  i:=0;
  While i<wsize do
   begin
     if p[i]<>#0 then
      begin
        BlockWrite(fo, word(i), 2);
        j:=0;
        while p[i+j]<>#0 do inc(j,1);
        BlockWrite(fo, word(j), 2);
        BlockWrite(fo, q[i], j);
        inc(i,j);
        inc(result,4+j);
      end;
     inc(i,1);
   end;

  FreeMem(p,wsize);
end;
{$ENDIF}



{************************** fill inbuf from infile *********************}
PROCEDURE readbuf;
BEGIN
  IF reachedsize > compsize + 2 THEN
   BEGIN {+2: last code is smaller than requested!}
     readpos := sizeof ( inbuf ); {Simulates reading -> no blocking}
     zipeof := TRUE;
   END
  ELSE
   BEGIN
    {$I-}
    blockread ( infile, inbuf, sizeof ( inbuf ), readpos );
    {$I+}
    IF ( ioresult <> 0 ) OR ( readpos = 0 ) THEN
     BEGIN  {readpos=0: kein Fehler gemeldet!!!}
       readpos := sizeof ( inbuf ); {Simulates reading -> CRC error}
       zipeof := TRUE;
     END;
    inc ( reachedsize, readpos );
    dec ( readpos );    {Reason: index of inbuf starts at 0}
  END;
  inpos := 0;
END;

{**** read byte, only used by explode ****}
PROCEDURE READBYTE ( VAR bt : byte );
BEGIN
  IF inpos > readpos THEN readbuf;
  bt := inbuf [ inpos ];
  inc ( inpos );
END;

{*********** read at least n bits into the global variable b *************}
PROCEDURE NEEDBITS ( n : byte );
VAR nb : longint;
BEGIN
  {$IFNDEF ZFS_ASSEMBLER}
  WHILE k < n DO BEGIN
    IF inpos > readpos THEN readbuf;
    nb := inbuf [ inpos ];
    inc ( inpos );
    b := b OR nb SHL k;
    inc ( k, 8 );
  END;
  {$ELSE}
  {$ASMMODE intel} ASM
    lea   esi, inbuf
    mov   ch, n
    mov   cl, k
    mov   ebx, inpos    {bx=inpos}
  @again:
    cmp   cl, ch
    JAE   @finished   {k>=n -> finished}
    cmp   ebx, readpos
    jg    @readbuf
  @fullbuf:
    mov  al, [esi + ebx ]  {dx:ax=nb}
    XOR  ah, ah
    XOR  edx, edx
    cmp  cl, 8      {cl>=8 -> shift into DX or directly by 1 byte}
    JAE  @bigger8
    SHL  eax, cl     {Normal shifting!}
    jmp  @continue
  @bigger8:
    mov  edi, ecx     {save cx}
    mov  ah, al     {shift by 8}
    sub  cl, 8      {8 bits shifted}
    XOR  al, al
  @rotate:
    OR   cl, cl
    jz   @continue1 {all shifted -> finished}
    SHL  ah, 1      {al ist empty!}
    rcl  edx, 1
    dec  cl
    jmp  @rotate
  @continue1:
    mov  ecx, edi
  @continue:
    OR   word ptr [b+2], dx
    OR   word ptr [b], ax     {b := b OR nb SHL k;}

    inc  ebx         {inpos}
    add  cl, 8       {inc k by 8 Bits}
    jmp  @again

  @readbuf:
    push esi
    push ecx
    call readbuf   {readbuf not critical, called only every 2000 bytes}
    pop  ecx
    pop  esi
    mov  ebx, inpos   {New inpos}
    jmp  @fullbuf

  @finished:
    mov  k, cl
    mov  inpos, ebx
  END ['EAX','EBX','ECX','EDX','ESI','EDI'];
  {$ENDIF}
END;

{***************** dump n bits no longer needed from global variable b *************}

PROCEDURE DUMPBITS ( n : byte );
BEGIN
  b := b SHR n;
  k := k - n;
END;


FUNCTION flush ( w : longint ) : Boolean;
LABEL COPYTO;
VAR
  n :longint;
  o :DWord;
BEGIN
  if (zfs_reachedbytes>=zfs_toreachbytes) then
   begin  {to destination buffer}
     o:=0;
COPYTO:
     if (zfs_reachedbytes+w<=zfs_toreachbytes+zfs_neededsize) then
      begin  {full buffer to destination}
        move(slide[o], pointer(ofs(zfs_outbuf^)+zfs_outofs)^, w);
        inc(zfs_outofs, w);
        inc(zfs_reachedbytes, w);
      end
     else
      begin  {part of the buffer to destination}
        n := zfs_toreachbytes+zfs_neededsize-zfs_reachedbytes; {w-((zfs_reachedbytes+w)-(zfs_toreachbytes+zfs_neededsize));}
        move(slide[o], pointer(ofs(zfs_outbuf^)+zfs_outofs)^, n);
        inc(zfs_outofs, n);
        inc(zfs_reachedbytes, n);

        exit(FALSE);
      end;
   end
  else
   begin {to temporal buffer}
     if (zfs_toreachbytes-zfs_reachedbytes)<w then
      begin
        o:=(zfs_toreachbytes-zfs_reachedbytes);
        w:=w-(zfs_toreachbytes-zfs_reachedbytes);
        zfs_reachedbytes:=zfs_toreachbytes;
        goto copyto;
      end
     else
      begin
        inc(zfs_reachedbytes, w);
      end;
   end;

  Flush:=TRUE;
END;



{Huffman tree generating and destroying}

{*************** free huffman tables starting with table where t points to ************}
PROCEDURE huft_free ( t : phuftlist );
VAR p, q : phuftlist;
    z : longint;
BEGIN
  p := pointer ( t );
  WHILE p <> NIL DO
   BEGIN
     dec ( longint ( p ), sizeof ( huft ) );
     q := p^ [ 0 ].v_t;
     z := p^ [ 0 ].v_n;   {Size in Bytes, required by TP ***}
     freemem ( p, ( z + 1 ) * sizeof ( huft ) );
     p := q
   END;
END;

{*********** build huffman table from code lengths given by array b^ *******************}
FUNCTION huft_build ( b : pword;n : word;s : word;d, e : pushlist;t : pphuft;VAR m : longint ) : longint;
VAR a : word;                        {counter for codes of length k}
    c : ARRAY [ 0..b_max + 1 ] of word;   {bit length count table}
    f : word;                        {i repeats in table every f entries}
    g,                             {max. code length}
    h : longint;                     {table level}
    i,                             {counter, current code}
    j : word;                        {counter}
    k : longint;                     {number of bits in current code}
    p : pword;                       {pointer into c, b and v}
    q : phuftlist;                   {points to current table}
    r : huft;                        {table entry for structure assignment}
    u : ARRAY [ 0..b_max ] of phuftlist;{table stack}
    v : ARRAY [ 0..n_max ] of word;     {values in order of bit length}
    w : longint;                     {bits before this table}
    x : ARRAY [ 0..b_max + 1 ] of word;   {bit offsets, then code stack}
    l : ARRAY [  - 1..b_max + 1 ] of word;  {l[h] bits in table of level h}
    xp : ^word;                      {pointer into x}
    y : longint;                     {number of dummy codes added}
    z : word;                        {number of entries in current table}
    tryagain : boolean;              {bool for loop}
    pt : phuft;                      {for test against bad input}
    el : word;                       {length of eob code=code 256}

BEGIN
  IF n > 256 THEN el := pword ( longint ( b ) + 256 * sizeof ( word ) ) ^
             ELSE el := BMAX;
  {generate counts for each bit length}
  fillchar ( c, sizeof ( c ), #0 );
  p := b; i := n;                      {p points to array of word}
  REPEAT
    IF p^ > b_max THEN
     BEGIN
       t^ := NIL;
       m := 0;
       huft_build := huft_error;
       exit
     END;
    inc ( c [ p^ ] );
    inc ( longint ( p ), sizeof ( word ) );   {point to next item}
    dec ( i );
  UNTIL i = 0;
  IF c [ 0 ] = n THEN
   BEGIN
     t^ := NIL;
     m := 0;
     huft_build := huft_complete;
     exit
   END;

  {find minimum and maximum length, bound m by those}
  j := 1;
  WHILE ( j <= b_max ) AND ( c [ j ] = 0 ) DO inc ( j );
  k := j;
  IF m < j THEN m := j;
  i := b_max;
  WHILE ( i > 0 ) AND ( c [ i ] = 0 ) DO dec ( i );
  g := i;
  IF m > i THEN m := i;

  {adjust last length count to fill out codes, if needed}
  y := 1 SHL j;
  WHILE j < i DO
   BEGIN
     y := y - c [ j ];
     IF y < 0 THEN
      BEGIN
        huft_build := huft_error;
        exit
      END;
     y := y SHL 1;
     inc ( j );
   END;
  dec ( y, c [ i ] );
  IF y < 0 THEN
   BEGIN
     huft_build := huft_error;
     exit
   END;
  inc ( c [ i ], y );

  {generate starting offsets into the value table for each length}
  x [ 1 ] := 0;
  j := 0;
  p := @c;
  inc ( longint ( p ), sizeof ( word ) );
  xp := @x;
  inc ( longint ( xp ), 2 * sizeof ( word ) );
  dec ( i );
  WHILE i <> 0 DO
   BEGIN
     inc ( j, p^ );
     xp^ := j;
     inc ( longint ( p ), 2 );
     inc ( longint ( xp ), 2 );
     dec ( i );
   END;

  {make table of values in order of bit length}
  p := b; i := 0;
  REPEAT
    j := p^;
    inc ( longint ( p ), sizeof ( word ) );
    IF j <> 0 THEN
     BEGIN
       v [ x [ j ] ] := i;
       inc ( x [ j ] );
     END;
    inc ( i );
  UNTIL i >= n;

  {generate huffman codes and for each, make the table entries}
  x [ 0 ] := 0; i := 0;
  p := @v;
  h := - 1;
  l [  - 1 ] := 0;
  w := 0;
  u [ 0 ] := NIL;
  q := NIL;
  z := 0;

  {go through the bit lengths (k already is bits in shortest code)}
  FOR k := k TO g DO
   BEGIN
     FOR a := c [ k ] DOWNTO 1 DO
      BEGIN
        {here i is the huffman code of length k bits for value p^}
        WHILE k > w + l [ h ] DO
         BEGIN
           inc ( w, l [ h ] ); {Length of tables to this position}
           inc ( h );
           z := g - w;
           IF z > m THEN z := m;
           j := k - w;
           f := 1 SHL j;
           IF f > a + 1 THEN
            BEGIN
              dec ( f, a + 1 );
              xp := @c [ k ];
              inc ( j );
              tryagain := TRUE;
              WHILE ( j < z ) AND tryagain DO
               BEGIN
                 f := f SHL 1;
                 inc ( longint ( xp ), sizeof ( word ) );
                 IF f <= xp^ THEN
                  tryagain := FALSE
                 ELSE
                  BEGIN
                    dec ( f, xp^ );
                    inc ( j );
                  END;
               END;
            END;
           IF ( w + j > el ) AND ( w < el ) THEN j := el - w;  {Make eob code end at table}
           IF w = 0 THEN J:= m;  {*** Fix: main table always m bits!}
           z := 1 SHL j;
           l [ h ] := j;

           {allocate and link new table}
           getmem ( q, ( z + 1 ) * sizeof ( huft ) );
           IF q = NIL THEN
            BEGIN
              IF h <> 0 THEN huft_free ( pointer ( u [ 0 ] ) );
              huft_build := huft_outofmem;
              exit
            END;

           fillchar ( q^, ( z + 1 ) * sizeof ( huft ), #0 );
           q^ [ 0 ].v_n := z;  {Size of table, needed in freemem ***}
           t^ := @q^ [ 1 ];     {first item starts at 1}
           t := @q^ [ 0 ].v_t;
           t^ := NIL;
           q := @q^ [ 1 ];   {pointer(longint(q)+sizeof(huft));} {???}
           u [ h ] := q;
           {connect to last table, if there is one}
           IF h <> 0 THEN
            BEGIN
              x [ h ] := i;
              r.b := l [ h - 1 ];
              r.e := 16 + j;
              r.v_t := q;
              j := ( i AND ( ( 1 SHL w ) - 1 ) ) SHR ( w - l [ h - 1 ] );

              {test against bad input!}
              pt := phuft ( longint ( u [ h - 1 ] ) - sizeof ( huft ) );
              IF j > pt^.v_n THEN
               BEGIN
                 huft_free ( pointer ( u [ 0 ] ) );
                 huft_build := huft_error;
                 exit
               END;

              pt := @u [ h - 1 ]^ [ j ];
              pt^ := r;
            END;
         END;

        {set up table entry in r}
        r.b := word ( k - w );
        r.v_t := NIL;   {Unused}
        IF longint ( p ) >= longint ( @v [ n ] ) THEN
         r.e := 99
        ELSE
         IF p^ < s THEN
          BEGIN
            IF p^ < 256 THEN r.e := 16
                        ELSE r.e := 15;
            r.v_n := p^;
            inc ( longint ( p ), sizeof ( word ) );
          END
         ELSE
          BEGIN
            IF ( d = NIL ) OR ( e = NIL ) THEN
             BEGIN
               huft_free ( pointer ( u [ 0 ] ) );
               huft_build := huft_error;
               exit
             END;
            r.e := word ( e^ [ p^ - s ] );
            r.v_n := d^ [ p^ - s ];
            inc ( longint ( p ), sizeof ( word ) );
          END;

        {fill code like entries with r}
        f := 1 SHL ( k - w );
        j := i SHR w;
        WHILE j < z DO
         BEGIN
           q^ [ j ] := r;
           inc ( j, f );
         END;

        {backwards increment the k-bit code i}
        j := 1 SHL ( k - 1 );
        WHILE ( i AND j ) <> 0 DO
         BEGIN
           {i:=i^j;}
           i := i XOR j;
           j := j SHR 1;
         END;
        i := i XOR j;

        {backup over finished tables}
        WHILE ( ( i AND ( ( 1 SHL w ) - 1 ) ) <> x [ h ] ) DO
         BEGIN
           dec ( h );
           dec ( w, l [ h ] ); {Size of previous table!}
         END;
      END;
   END;

  IF ( y <> 0 ) AND ( g <> 1 ) THEN huft_build := huft_incomplete
                               ELSE huft_build := huft_complete;
END;

(***************************************************************************)
{Inflate deflated file}
FUNCTION inflate_codes ( tl, td : phuftlist;bl, bd : longint ) : longint;
VAR
    n, d, e1,          {length and index for copy}
    ml, md : word;      {masks for bl and bd bits}
    t : phuft;         {pointer to table entry}
    e : byte;          {table entry flag/number of extra bits}

BEGIN
  { inflate the coded data }
  ml := mask_bits [ bl ];          {precompute masks for speed}
  md := mask_bits [ bd ];
  WHILE NOT ( zipeof ) DO
   BEGIN
     NEEDBITS ( bl );
     t := @tl^ [ b AND ml ];
     e := t^.e;
     IF e > 16 THEN
      REPEAT       {then it's a literal}
        IF e = 99 THEN
         BEGIN
           inflate_codes := unzip_ZipFileErr;
           exit
         END;
        DUMPBITS ( t^.b );
        dec ( e, 16 );
        NEEDBITS ( e );
        t := @t^.v_t^ [ b AND mask_bits [ e ] ];
        e := t^.e;
      UNTIL e <= 16;
     DUMPBITS ( t^.b );
     IF e = 16 THEN
      BEGIN
        slide [ w ] := char ( t^.v_n );
        inc ( w );
        IF w = WSIZE THEN
         BEGIN
           IF NOT flush ( w ) THEN
            BEGIN
              inflate_codes := unzip_Reached;
              exit;
            END;
           w := 0
         END;
      END
     ELSE
      BEGIN                {it's an EOB or a length}
        IF e = 15 THEN
         BEGIN {Ende}   {exit if end of block}
           inflate_codes := unzip_Ok;
           exit;
         END;
        NEEDBITS ( e );                 {get length of block to copy}
        n := t^.v_n + ( b AND mask_bits [ e ] );
        DUMPBITS ( e );

        NEEDBITS ( bd );                {decode distance of block to copy}
        t := @td^ [ b AND md ];
        e := t^.e;
        IF e > 16 THEN
         REPEAT
           IF e = 99 THEN
            BEGIN
              inflate_codes := unzip_ZipFileErr;
              exit
            END;
           DUMPBITS ( t^.b );
           dec ( e, 16 );
           NEEDBITS ( e );
           t := @t^.v_t^ [ b AND mask_bits [ e ] ];
           e := t^.e;
         UNTIL e <= 16;
        DUMPBITS ( t^.b );
        NEEDBITS ( e );
        d := w - t^.v_n - b AND mask_bits [ e ];
        DUMPBITS ( e );
        {do the copy}
        REPEAT
          d := d AND ( WSIZE - 1 );
          IF d > w THEN e1 := WSIZE - d
                   ELSE e1 := WSIZE - w;
          IF e1 > n THEN e1 := n;
          dec ( n, e1 );
          IF ( w - d >= e1 ) THEN
           BEGIN
             move ( slide [ d ], slide [ w ], e1 );
             {$IFDEF ZFS_SEEKING_INFO}
             if SeekingInfo then AddSlideData(d,w,e1);
             {$ENDIF}
             inc ( w, e1 );
             inc ( d, e1 );
           END
          ELSE
           REPEAT
             slide [ w ] := slide [ d ];
             {$IFDEF ZFS_SEEKING_INFO}
             if SeekingInfo then AddSlideData(d,w,1);
             {$ENDIF}
             inc ( w );
             inc ( d );
             dec ( e1 );
           UNTIL ( e1 = 0 );
          IF w = WSIZE THEN
           BEGIN
             IF NOT flush ( w ) THEN
              BEGIN
                inflate_codes := unzip_Reached;
                exit;
              END;
             w := 0;
           END;
        UNTIL n = 0;
      END;
   END;

  inflate_codes := unzip_readErr;
END;

{**************************** "decompress" stored block **************************}
FUNCTION inflate_stored : longint;
VAR n : word;            {number of bytes in block}

BEGIN
  {go to byte boundary}
  n := k AND 7;
  dumpbits ( n );
  {get the length and its complement}
  NEEDBITS ( 16 );
  n := b AND $ffff;
  DUMPBITS ( 16 );
  NEEDBITS ( 16 );
  IF ( n <> ( NOT b ) AND $ffff ) THEN
   BEGIN
     inflate_stored := unzip_zipFileErr;
     exit
   END;
  DUMPBITS ( 16 );
  WHILE ( n > 0 ) AND NOT ( zipeof ) DO
   BEGIN {read and output the compressed data}
     dec ( n );
     NEEDBITS ( 8 );
     slide [ w ] := char ( b );
     inc ( w );
     IF w = WSIZE THEN
      BEGIN
        IF NOT flush ( w ) THEN
         BEGIN
           inflate_stored := unzip_Reached;
           exit
         END;
        w := 0;
      END;
     DUMPBITS ( 8 );
   END;

  IF zipeof THEN inflate_stored := unzip_readErr
            ELSE inflate_stored := unzip_Ok;
END;

{**************************** decompress fixed block **************************}
FUNCTION inflate_fixed : longint;
VAR i : longint;               {temporary variable}
    tl,                      {literal/length code table}
    td : phuftlist;                {distance code table}
    bl, bd : longint;           {lookup bits for tl/bd}
    l : ARRAY [ 0..287 ] of word; {length list for huft_build}
BEGIN
  {set up literal table}
  FOR i := 0 TO 143 DO l [ i ] := 8;
  FOR i := 144 TO 255 DO l [ i ] := 9;
  FOR i := 256 TO 279 DO l [ i ] := 7;
  FOR i := 280 TO 287 DO l [ i ] := 8; {make a complete, but wrong code set}
  bl := 7;
  i := huft_build ( pword ( @l ), 288, 257, pushlist ( @cplens ), pushlist ( @cplext ), @tl, bl );
  IF i <> huft_complete THEN
   BEGIN
     inflate_fixed := i;
     exit
   END;
  FOR i := 0 TO 29 DO l [ i ] := 5;    {make an incomplete code set}
  bd := 5;
  i := huft_build ( pword ( @l ), 30, 0, pushlist ( @cpdist ), pushlist ( @cpdext ), @td, bd );
  IF i > huft_incomplete THEN
   BEGIN
     huft_free ( tl );
     inflate_fixed := unzip_ZipFileErr;
     exit
   END;
  inflate_fixed := inflate_codes ( tl, td, bl, bd );
  huft_free ( tl );
  huft_free ( td );
END;

{**************************** decompress dynamic block **************************}
FUNCTION inflate_dynamic : longint;
VAR i : longint;                      {temporary variables}
    j,
    l,                              {last length}
    m,                              {mask for bit length table}
    n : word;                         {number of lengths to get}
    tl,                             {literal/length code table}
    td : phuftlist;                   {distance code table}
    bl, bd : longint;                  {lookup bits for tl/bd}
    nb, nl, nd : word;                  {number of bit length/literal length/distance codes}
    ll : ARRAY [ 0..288 + 32 - 1 ] of word;  {literal/length and distance code lengths}

BEGIN
  {read in table lengths}
  NEEDBITS ( 5 );
  nl := 257 + word ( b ) AND $1f;
  DUMPBITS ( 5 );
  NEEDBITS ( 5 );
  nd := 1 + word ( b ) AND $1f;
  DUMPBITS ( 5 );
  NEEDBITS ( 4 );
  nb := 4 + word ( b ) AND $f;
  DUMPBITS ( 4 );
  IF ( nl > 288 ) OR ( nd > 32 ) THEN
   BEGIN
     inflate_dynamic := 1;
     exit
   END;
  fillchar ( ll, sizeof ( ll ), #0 );

  {read in bit-length-code lengths}
  FOR j := 0 TO nb - 1 DO
   BEGIN
     NEEDBITS ( 3 );
     ll [ border [ j ] ] := b AND 7;
     DUMPBITS ( 3 );
   END;
  FOR j := nb TO 18 DO ll [ border [ j ] ] := 0;

  {build decoding table for trees--single level, 7 bit lookup}
  bl := 7;
  i := huft_build ( pword ( @ll ), 19, 19, NIL, NIL, @tl, bl );
  IF i <> huft_complete THEN
   BEGIN
     IF i = huft_incomplete THEN huft_free ( tl ); {other errors: already freed}
     inflate_dynamic := unzip_ZipFileErr;
     exit
   END;

  {read in literal and distance code lengths}
  n := nl + nd;
  m := mask_bits [ bl ];
  i := 0; l := 0;
  WHILE word ( i ) < n DO
   BEGIN
     NEEDBITS ( bl );
     td := @tl^ [ b AND m ];
     j := phuft ( td ) ^.b;
     DUMPBITS ( j );
     j := phuft ( td ) ^.v_n;
     IF j < 16 THEN
      BEGIN            {length of code in bits (0..15)}
        l := j;                       {ave last length in l}
        ll [ i ] := l;
        inc ( i )
      END
     ELSE
      IF j = 16 THEN
       BEGIN   {repeat last length 3 to 6 times}
         NEEDBITS ( 2 );
         j := 3 + b AND 3;
         DUMPBITS ( 2 );
         IF i + j > n THEN
          BEGIN
            inflate_dynamic := 1;
            exit
          END;

         WHILE j > 0 DO
          BEGIN
            ll [ i ] := l;
            dec ( j );
            inc ( i );
          END;
       END
      ELSE
       IF j = 17 THEN
        BEGIN   {3 to 10 zero length codes}
          NEEDBITS ( 3 );
          j := 3 + b AND 7;
          DUMPBITS ( 3 );
          IF i + j > n THEN
           BEGIN
             inflate_dynamic := 1;
             exit
           END;
          WHILE j > 0 DO
           BEGIN
             ll [ i ] := 0;
             inc ( i );
             dec ( j );
           END;
          l := 0;
        END
       ELSE
        BEGIN                {j == 18: 11 to 138 zero length codes}
          NEEDBITS ( 7 );
          j := 11 + b AND $7f;
          DUMPBITS ( 7 );
          IF i + j > n THEN
           BEGIN
             inflate_dynamic := unzip_zipfileErr;
             exit
           END;
          WHILE j > 0 DO
           BEGIN
             ll [ i ] := 0;
             dec ( j );
             inc ( i );
           END;
          l := 0;
        END;
   END;
  huft_free ( tl );        {free decoding table for trees}

  {build the decoding tables for literal/length and distance codes}
  bl := lbits;
  i := huft_build ( pword ( @ll ), nl, 257, pushlist ( @cplens ), pushlist ( @cplext ), @tl, bl );
  IF i <> huft_complete THEN
   BEGIN
     IF i = huft_incomplete THEN huft_free ( tl );
     inflate_dynamic := unzip_ZipFileErr;
     exit
   END;
  bd := dbits;
  i := huft_build ( pword ( @ll [ nl ] ), nd, 0, pushlist ( @cpdist ), pushlist ( @cpdext ), @td, bd );
  IF i > huft_incomplete THEN
   BEGIN {pkzip bug workaround}
     IF i = huft_incomplete THEN huft_free ( td );
     huft_free ( tl );
     inflate_dynamic := unzip_ZipFileErr;
     exit
   END;
  {decompress until an end-of-block code}
  inflate_dynamic := inflate_codes ( tl, td, bl, bd );
  huft_free ( tl );
  huft_free ( td );
END;

{**************************** decompress a block ******************************}
FUNCTION inflate_block ( VAR e : longint ) : longint;
VAR t : longint;           {block type}
BEGIN
  NEEDBITS ( 1 );
  e := b AND 1;
  DUMPBITS ( 1 );

  NEEDBITS ( 2 );
  t := b AND 3;
  DUMPBITS ( 2 );

  CASE t of
    0 : result := inflate_stored;
    1 : result := inflate_fixed;
    2 : result := inflate_dynamic;
   else inflate_block := unzip_ZipFileErr;  {bad block type}
  END;
END;

{**************************** decompress an inflated entry **************************}
FUNCTION inflate(_w:Word; _b:longint; _k:byte) : longint;
VAR e,                 {last block flag}
    r   : longint;     {result code}
    {$IFDEF ZFS_SEEKING_INFO}
    s   : longint;
    {$ENDIF}
BEGIN
  inpos := 0;            {Input buffer position}
  readpos := -1;        {Nothing read}

  {initialize window, bit buffer}
  w := _w;
  b := _b;
  k := _k;

  {$IFDEF ZFS_SEEKING_INFO}
  if seekinginfo then
   begin
     assign(slidefile, OutName);
     rewrite(slidefile, 1);
   end;
  {$ENDIF}

  {decompress until the last block}
  REPEAT
    r := inflate_block ( e );
    if r = unzip_Reached then BREAK;
    if r <> 0 then
     begin
       inflate := r;
       exit
     end;

    {$IFDEF ZFS_SEEKING_INFO}
    if seekinginfo then
     begin
       if (r=0) and (firstdone) then  {If block complete and not first one}
        begin
          r:=oldpos;
          BlockWrite(slidefile, r, 4); {pos}
          r:=oldupos;
          BlockWrite(slidefile, r, 4); {upos}
          r:=oldw;
          BlockWrite(slidefile, r, 4); {w}
          r:=oldb;
          BlockWrite(slidefile, r, 4); {b}
          r:=oldk;
          BlockWrite(slidefile, r, 4); {k}
          r:=filepos(slidefile);
          seek(slidefile, r+4);
          s:=ComputeSlideData(slidefile, oldw);
          seek(slidefile, r);
          BlockWrite(slidefile, s, 4); {size of  slide}
          seek(slidefile, r+s+4);
        end;

       KillSlideData;

       if not(firstdone) then firstdone:=TRUE;
       oldPos:=reachedsize-(readpos+1)+inpos;
       oldUPos:=zfs_reachedbytes;   {!!BUGGY}
       oldK:=k;
       oldB:=b;
       oldW:=w;
       Move(slide[0], oldslide[0], wsize);
     end;
    {$ENDIF}

  UNTIL e <> 0;

  {$IFDEF ZFS_SEEKING_INFO}
  if seekinginfo then close(slidefile);
  {$ENDIF}

  {flush out slide}
  flush(w);

  inflate := unzip_OK;
END;


FUNCTION GetSupportedMethods : DWord;
BEGIN
  GetSupportedMethods := ( 1 SHL 8 );
                         {deflated}
END;

{Expands an encoded Slide}
Procedure ExpandSlide(compr :pchar; size :word);
var
  d :Word;
  l :Word;
  i :Longint;
begin
  i:=0;
  While i<size do
   begin
     d:=Word(pointer(DWord(compr)+i)^);
     inc(i,2);
     l:=Word(pointer(DWord(compr)+i)^);
     inc(i,2);
     Move(compr[i], slide[d], l);
     inc(i,l);
   end;
end;


{******************** main low level function: unzipfile ********************}
FUNCTION unzipfile (var in_file :file; offset, csize, ztype, seekat :DWord; initw:word; B:longint; k:byte; comprslide :pchar; comprsize :DWord):longint;
BEGIN
  {0=stored, 1=shunk, 6=imploded, 8=deflated}
  if (1 SHL ztype) AND GetSupportedMethods = 0 then
   begin  {Not Supported!!!}
     result := unzip_NotSupported;
     exit;
   end;

  getmem ( slide, wsize );
  if slide=NIL then
   begin
     unzipfile := unzip_NotEnoughMem;
     exit;
   end;
//  fillchar ( slide [0], wsize, #0 );

  if (comprslide<>NIL) or (comprsize<>0) then ExpandSlide(comprslide, comprsize);

  {$IFDEF ZFS_SEEKING_INFO}
  if Seekinginfo then getmem ( oldslide, wsize );
  {$ENDIF}

  infile:=in_file;
  seek ( infile, offset+seekat);       {seek to header position}

  compsize := csize;

  reachedsize := seekat;

  zipeof := FALSE;

  {Unzip correct type}
  CASE ztype of
    8 : Result := inflate(initw,b,k);
    ELSE Result := unzip_NotSupported;
  END;

  {$IFDEF ZFS_SEEKING_INFO}
  if seekinginfo then freemem ( oldslide, wsize );
  {$ENDIF}

  freemem ( slide, wsize );
END;

{-------------------------------------------------------------------------}

{$IFDEF ZFS_SEEKING_INFO}
procedure AddFileZip(n:string; k:longint; p,s,u :Dword);
var tmp, tmp2 :pFileZip;
begin
  new(tmp);
  if firstfilezip=NIL then
   begin
     firstfilezip:=tmp;
   end
  else
   begin
     tmp2:=firstfilezip;
     while tmp2^.next<>NIL do
      begin
        tmp2:=tmp2^.next;
      end;
     tmp2^.next:=tmp;
   end;

  with tmp^ do
   begin
     Nom := n;
     Kind := k;
     Pos := p;
     Size := s;
     USize := u;
     next := NIL;
   end;
end;

procedure KillFileZip;
var tmp,tmp2 :pFileZip;
begin
  tmp:=FirstFileZip;
  if tmp=NIL then {there isn't nothing to erase}
   begin
     exit;
   end
  else
   begin
     While tmp<>NIL do
      begin
        tmp2:=tmp^.NEXT;
        Dispose(tmp);
        tmp:=Tmp2;
      end;
   end;
  FirstFileZip:=NIL;
end;

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

{Gets a local header of a zipped file}
function Read_Local_Hdr : LongBool;
var
  Sig : longInt;
begin
  BlockRead(ZIP, sig, SizeOf(Sig));
  if Sig = CENTRAL_FILE_HEADER_SIGNATURE then
   begin
     Result:=FALSE;
   end {then}
  else
   begin
     if Sig <> LOCAL_FILE_HEADER_SIGNATURE then
      begin
        Result:=FALSE;  {Missing or invalid local file header in Zip file}
        EXIT;
      end;
     BlockRead(ZIP, LocalHdr, SizeOf(LocalHdr));
     with LocalHdr do
      begin
        if FileName_Length > 255 then
         begin
           Result:=FALSE; {Filename of a compressed file exceeds 255 chars!}
           EXIT;
         end;
        BlockRead(ZIP, Hdr_FileName[1], FileName_Length);
        Hdr_FileName[0] := Chr(FileName_Length);
        if Extra_Field_Length > 255 then
         begin
           Result:=FALSE; {Extra Field of a compressed file exceeds 255 chars!}
           EXIT;
         end;
        BlockRead(ZIP, Hdr_ExtraField[1], Extra_Field_Length);
        Hdr_ExtraField[0] := Chr(Extra_Field_Length);
      end {with};
     Result := TRUE;
   end {else};
end;

Procedure GetZIPfiles;
begin
  while Read_Local_Hdr do
   begin
     addfilezip(hdr_filename, LocalHdr.Compress_Method, FilePos(ZIP),
                LocalHdr.Compressed_Size, LocalHdr.UNCompressed_Size);

     Seek(ZIP, FilePos(ZIP)+LocalHdr.Compressed_Size);
   end;
end;

procedure OpenZIP(name:string);
var r:longint;
begin
  assign(zip, name);
  {$I-} system.reset(zip, 1); {$I+}
  r:=IOResult;
  if r<>0 then
   begin
     WriteLN('ERROR OPPENING ZIP FILE');
     halt;
   end;

  GetZIPfiles;
end;

procedure CloseZIP;
begin
  Close(ZIP);
  KillFileZip;
end;
{$ENDIF}



BEGIN
  slide := NIL;      {unused}
END.
