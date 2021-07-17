{ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿}
{³ þ ISS_VAR .PAS - Loader for Autodesk 3D Studio R4 type .3DS files        ³}
{³                  Work started     : 1998.12.04.                          ³}
{³                  Last modification: 2001.07.03.                          ³}
{³             OS - Platform Independent                                    ³}
{³                                                                          ³}
{³            ISS - Inquisition 3D Engine for Free Pascal                   ³}
{³                  Code by Marton Ekler (a.k.a. mrc/iNQ) and               ³}
{³                          Karoly Balogh (a.k.a. Charlie/iNQ)              ³}
{³                  Copyright (C) 1998-2001 Inquisition                     ³}
{ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{ þ THIS RELEASE SEEMS TO BE STABLE. ANYWAY, STILL HANDLE WITH CARE. þ }
{ þ USE AT YOUR OWN RISK. þ }

{$MODE FPC}     { þ Compiler mode to FPC þ }
{$IOCHECKS OFF} { þ Switching off runtime IO error handling. þ }

{$HINTS OFF}    { þ Disabling hints - Enable this, if you modify the loader! þ }
{$NOTES OFF}    { þ Disabling notes - Enable this, if you modify the loader! þ }

{ þ Enable this directive, if you want to generate logfile. It's useful þ }
{ þ to dig up bugs and incompatibilities. Check out the debugging section þ }
{ þ in the implementation part for more info. þ }
{ þ IMPORTANT! THE DEBUG LOG GENERATOR CODE IS _NOT_ FAIL SAFE! þ }
{ þ DO _NOT_ ENABLE DEBUG LOG GENERATION IN OFFICIALLY RELEASED PRODUCTS! þ }
{ þ OKAY, YOU'VE BEEN WARNED. þ }
{ DEFINE _I3D_3DSL_DEBUGMODE_}

{ þ The symbol definied below makes possible to include the loader into þ }
{ þ our 3D engine. Do NOT enable if you want to use the loader without it. þ }
{ þ (Also enables IDS integration.) þ }
{ DEFINE _I3D_INCLUDE_}

Unit I3D_3DSL;

Interface

{$IFDEF _I3D_INCLUDE_}
 Uses I3D_Vect,I3D_Quat,IDS_Load;
{$ENDIF}

Const I3D_LoaderVersionStr = '0.4.7';
      I3D_LoaderVersion    = $000407;

Type TSplineFlags = Record { þ Spline flags belong to every key þ }
       Flags      : Word;  { þ These flags show if a value changed þ }
       Tension    : Single;
       Continuity : Single;
       Bias       : Single;
       EaseTo     : Single;
       EaseFrom   : Single;
      End;

     {$IFNDEF _I3D_INCLUDE_}
      P3DVector = ^T3DVector;
      T3DVector = Record { þ A coordinate in the 3D space þ }
        X : Single;
        Y : Single;
        Z : Single;
       End;
     {$ENDIF}

     {$IFNDEF _I3D_INCLUDE_}
      TQuaternion = Record
        S : Single;
        V : T3DVector;
       End;
     {$ENDIF}

     PPosKey = ^TPosKey;
     TPosKey = Record   { þ Track Position Coordinates þ }
       Frame  : Word;
       Vector : T3DVector;
       Spline : TSplineFlags;
      End;

     PRotKey = ^TRotKey;
     TRotKey = Record { þ Track Rotation Value þ }
       Frame      : Word;
       Angle      : Single;
       Vector     : T3DVector;
       Spline     : TSplineFlags;
       Quaternion : TQuaternion;
      End;

     PScaleKey = ^TScaleKey;
     TScaleKey = Record { þ Track Scale Value þ }
       Frame   : Word;
       Vector  : T3DVector;
       Spline  : TSplineFlags;
      End;

     PMorphKey = ^TMorphKey;
     TMorphKey = Record
       Frame   : Word;
       ObjName : String[32];
       Spline  : TSplineFlags;
      End;

     PFOVKey = ^TFOVKey;
     TFOVKey = Record   { þ Track FOV Value þ }
       Frame  : Word;
       FOV    : Single;
       Spline : TSplineFlags;
      End;

     PRollKey = ^TRollKey;
     TRollKey = Record  { þ Track Roll Value þ }
       Frame  : Word;
       Roll   : Single;
       Spline : TSplineFlags;
      End;

     PObjPivot = ^TObjPivot;
     TObjPivot = Record { þ Object Pivot Point þ }
       Vector  : T3DVector;
      End;

     P3DVertex = ^T3DVertex;
     T3DVertex = Record { þ Vertex Data þ }
       Vector  : T3DVector;
       U       : Single; { þ Texture Coordinates þ }
       V       : Single;
      End;

     P3DFace = ^T3DFace;
     T3DFace = Record { þ Triangle Face Data þ }
       Vertex1 : Word;  { þ Number Of Vertexes In Vertex List þ }
       Vertex2 : Word;
       Vertex3 : Word;
       ABVis   : Boolean; { þ Edge Visibility Switches þ }
       BCVis   : Boolean;
       ACVis   : Boolean;
       UWrap   : Boolean; { þ Texture Tile Switches þ }
       VWrap   : Boolean;
       MatName : String[32]; { þ Material Name Assigned To This Face þ }
       MatNum  : Word; { þ Material Number Assigned To This Face þ }
      End;

     P3DObject  = ^T3DObject;
     T3DObject  = Record { þ 3D Object Data þ }
       PNextObj    : P3DObject;  { þ Pointer to the next Object þ }
       ObjName     : String[32]; { þ Name Of This Object þ }
       VertexNum   : Word;       { þ Number Of Vertexes þ }
       Vertex      : P3DVertex;  { þ Pointer To Vertex List þ }
       FaceNum     : Word;       { þ Number Of Faces þ }
       Face        : P3DFace;    { þ Pointer To Faces List þ }
       Rot_Mat     : Array[0..8] Of Single; { þ Object Rotation Matrix þ }
       Trans_Mat   : Array[0..2] Of Single; { þ Object Translation Matrix þ }
       Static      : Boolean;    { þ True If Static Object (Every KeysNum=1) þ }
       Visible     : Boolean;    { þ Object is set as visible þ }
       TrackNum    : Word;       { þ Track Number Belongs To This Object þ }
       BoundingBox : Array[0..7] Of T3DVector; { þ Object Bounding Box Vertices þ }
       FaceNormals : P3DVector;  { þ Face normals array þ }
      End;
     PP3DObject = ^P3DObject;

     P3DCamera  = ^T3DCamera;
     T3DCamera  = Record { þ Camera Data þ }
       PNextCam  : P3DCamera;    { þ Pointer to the next Camera þ }
       CamName   : String[32];   { þ Name Of This Camera þ }
       Position  : T3DVector;      { þ Camera Eye Position þ }
       Target    : T3DVector;      { þ Camera Viewpoint Target þ }
       Roll      : Single;
       FOV       : Single;
       PosTrack  : Word;         { þ Track Number Belongs To This Camera Position þ }
       TargTrack : Word;         { þ Track Number Belongs To This Camera Target   þ }
      End;
     PP3DCamera = ^P3DCamera;

     TRGBByteColor = Record { þ RGB Byte Color Data þ }
       R       : Byte;
       G       : Byte;
       B       : Byte;
      End;

     TRGBFloatColor = Record { þ RGB Float Color Data þ }
       R       : Single;
       G       : Single;
       B       : Single;
      End;

     PLight = ^TLight;
     TLight = Record { þ Lightsource Data þ }
       PNextLight : PLight;     { þ Pointer to Next Light þ }
       LightName  : String[32]; { þ Light Name þ }
      End;
     PPLight = ^PLight;

     PMaterial  = ^TMaterial;
     TMaterial  = Record { þ Material Data þ }
       PNextMat   : PMaterial;  { þ Pointer to Next Material þ }
       Name       : String[32]; { þ Material Name þ }
       Ambient    : TRGBByteColor; { þ Material Ambient Color þ }
       FileName   : String[12]; { þ Material Filename þ }
       Visibility : Word;       { þ Material Visibility þ }
       MapX       : Word;       { þ Material Map X Size þ }
       MapY       : Word;       { þ Material Map Y Size þ }
       MapData    : Pointer;    { þ Pointer to Material RAW Image Data þ }
      End;
     PPMaterial = ^PMaterial;

     P3DTrack  = ^T3DTrack;
     T3DTrack  = Record { þ Animation Track Data þ }
       Static         : Boolean;    { þ Indicates if track is static þ }
       PNextTrack     : P3DTrack;   { þ Pointer to Next Track þ }
       TrackNumber    : Word;       { þ Number Of The Track þ }
       TrackParent    : Word;       { þ Parent Number Of The Track þ }
       TrackType      : Byte;       { þ Track Type þ }
       TrackName      : String[32]; { þ Name Of The Track (Same as the Object Name) þ }
       TrackPivot     : TObjPivot;  { þ Pivot Point Of The Object þ }
       TrackPosNum    : Word;       { þ Number Of Track Position Keys þ }
       TrackPosKeys   : PPosKey;    { þ Pointer To Position Keys (Nil If No Position Track) þ }
       TrackRotNum    : Word;       { þ Number Of Track Rotation Keys (Object Tracks Only) þ }
       TrackRotKeys   : PRotKey;    { þ Pointer To Rotation Keys (Nil If No Rotation Track) þ }
       TrackScaleNum  : Word;       { þ Number Of Scale Keys (Object Tracks Only) þ }
       TrackScaleKeys : PScaleKey;  { þ Pointer To Scale Keys (Nil If No Scale Track) þ }
       TrackMorphNum  : Word;       { þ Number Of Morph Keys (Object Tracks Only) þ }
       TrackMorphKeys : PMorphKey;  { þ Pointer To Morph Keys (Nil If No Morph Track) þ }
       TrackFOVNum    : Word;       { þ Number Of Track FOV Keys (Camera Tracks Only) þ }
       TrackFOVKeys   : PFOVKey;    { þ Pointer To FOV Keys (Nil If No FOV Track) þ }
       TrackRollNum   : Word;       { þ Number Of Roll Keys (Camera Tracks Only) þ }
       TrackRollKeys  : PRollKey;   { þ Pointer To Roll Keys (Nil If No Roll Track) þ }
      End;
     PP3DTrack = ^P3DTrack;

     P3DMesh = ^T3DMesh;
     T3DMesh = Record  { þ The Whole 3D Mesh Data þ }

       { þ ADDITIONAL INFO þ }

       MemoryUsed  : DWord; { þ Gives back the memory size used by the Mesh-tree þ }

       { þ MESH DATA (3D EDITOR) þ }

       ObjectNum   : Word; { þ Number Of Objects In Mesh þ }
       Object3D    : PP3DObject; { þ Array Of Pointers To Object Data þ }
       Object3DL   : P3DObject;  { þ Pointer To The First Element Of Object List þ }
       CameraNum   : Word; { þ Number Of Cameras In Mesh þ }
       Camera3D    : PP3DCamera; { þ Array Of Pointers To Camera Data þ }
       Camera3DL   : P3DCamera;  { þ Pointer To The First Element Of Camera List þ }
       LightNum    : Word; { þ Number Of Lightsources In Mesh þ }
       Light       : PPLight;    { þ Array Of Pointers To Light Data þ }
       LightL      : PLight;     { þ Pointer To The First Element Of Lightsource List þ }
       MaterialNum : Word; { þ Number Of Materials In Mesh þ }
       Material    : PPMaterial; { þ Array Of Pointers To Material Data þ }
       MaterialL   : PMaterial;  { þ Pointer To The First Element Of Material List þ }

       { þ ANIMATION DATA (KEYFRAMER) þ }

       FramesNum   : Word; { þ Number Of Frames In The Animation þ }
       FirstFrame  : Word; { þ First Keyframe In The Animation þ }
       LastFrame   : Word; { þ Last Keyframe In The Animation þ }
       TracksNum   : Word; { þ Number Of Stored Tracks þ }
       Tracks      : PP3DTrack; { þ Array Of Pointers To The Track Data þ }
       TracksL     : P3DTrack;  { þ Pointer To The First Element Of Track List þ }
      End;

Const I3DL_ErrorFileName = 1; { þ Invalid filename þ }
      I3DL_ErrorFileOpen = 2; { þ File open failed þ }
      I3DL_ErrorFileIO   = 3; { þ File I/O operation error þ }
      I3DL_ErrorMemAlloc = 4; { þ Memory allocation failed þ }
      I3DL_ErrorNo3DS    = 5; { þ Corrupted 3DS file, or not a 3DS file! þ }
      I3DL_Error3DSRead  = 6; { þ Error in the 3DS file þ }
      I3DL_ErrorFree3DS  = 7; { þ Free 3DS function failed þ }

Var I3D_Load3DSErrorCode : LongInt; { þ Contains the last error code þ }

Function I3D_Get3DSError : DWord;
Function I3D_Get3DSErrorString(ErrorCode : DWord) : String;

Function I3D_Load3DS(Var Mesh3D : P3DMesh; FileName : String) : Boolean;
Function I3D_Free3DS(Var Mesh3D : P3DMesh) : Boolean;

{$IFDEF _I3D_INCLUDE_}
 Function I3D_IDSLoad3DS(Var Mesh3D : P3DMesh; DFHandle : IDS_PDataFile; FileName : String) : Boolean;
{$ENDIF}

Implementation

{ þ >>> L O C A L  D A T A  A R E A <<< þ }

{$IFDEF _I3D_3DSL_DEBUGMODE_}
 Uses CRT;
{$ENDIF}

Type TChunkData = Record { þ Store chunk data, used by FindChunk þ }
       CValid  : Boolean;   { þ True if chunk valid. þ }
       CDescr  : String;    { þ Chunk description þ }
       CReader : Procedure(TreeDepth : DWord; CPosition : DWord); { þ Chunk reader procedure þ }
      End;

Const { þ ID Chunk þ }
      Main3DS = $04D4D;

      { þ Main Chunks þ }
      Edit3DS = $03D3D; { þ This is the start of the Editor config þ }
          { þ Sub Defines of Edit3DS þ }
          Edit_MATERIAL = $0AFFF;
               Mat_NAME    = $0A000;
               Mat_AMBIENT = $0A010;
               Mat_TEXTURE = $0A200;
                   Tex_MAPFILE = $0A300;
          Edit_BACKGR   = $01200;
          Edit_AMBIENT  = $02100;
          Edit_OBJECT   = $04000;
               { þ Sub Defines of Edit_OBJECT þ }
               Obj_OBJMESH = $04100;
                   { þ Sub Defines of Obj_TRIMESH þ }
                   Tri_VERTEXL  = $04110; { þ Vertex List þ }
                   Tri_FACELIST = $04120; { þ Face List þ }
                       Tri_FACEMAT = $04130; { þ Faces mapping list þ }
                   Tri_MAPPING  = $04140; { þ Mapping coordinates for each vertex þ }
                   Tri_SMOOTH   = $04150;
                   Tri_MATRIX   = $04160;
                   Tri_VISIBLE  = $04165;
               Obj_LIGHT  = $04600;
               Obj_CAMERA = $04700;

      Keyf3DS = $0B000; { þ This is the start of the Keyframer config þ }
          { þ Sub Defines Of Keyf3DS þ }
          Keyf_FRAMES    = $0B008; { þ Frames of the Animation þ }
          Keyf_OBJTRACK  = $0B002; { þ Animation Track Info    þ }
               Track_OBJNAME   = $0B010;
               Track_OBJNUMBER = $0B030;
               Track_OBJPIVOT  = $0B013;
               Track_OBJPOS    = $0B020; { þ Animation Position Keys þ }
               Track_OBJROTATE = $0B021;
               Track_OBJSCALE  = $0B022;
               Track_OBJMORPH  = $0B026;
               Track_OBJHIDE   = $0B029;
          Keyf_CAMTRACK     = $0B003;    { þ Camera Track þ }
          Keyf_CAMTARGTRACK = $0B004;
               Track_CAMFOV  = $0B023;
               Track_CAMROLL = $0B024;
          Keyf_LIGHTTRACK     = $0B005;  { þ Spotlight(?) Track þ }
          Keyf_LIGHTTARGTRACK = $0B006;  { þ Spotlight(?) Target Track þ }
          Keyf_OMNILIGHTTRACK = $0B007;  { þ Omnilight Track þ }

      { þ Additional Chunks þ }
      Chunk_RGBF = $00010;
      Chunk_RGBB = $00011;
      Chunk_WORD = $00030;

Const ObjectTrack          =  1; { þ Track type flags þ }
      CameraTrack          =  2;
      CameraTargetTrack    =  4;
      SpotLightTrack       =  8;
      SpotLightTargetTrack = 16;
      OmniLightTrack       = 32;

Var Current3DS     : Pointer; { þ Pointer to current 3DS to load þ }
    Current3DSPos  : DWord;   { þ Current memory position to load from þ }
    Current3DSSize : DWord;   { þ Size of the memory area to load þ }
    Loaded3DS      : P3DMesh;

    GlobalBufStr   : String;         { þ Global string buffer. þ }
    GlobalBufRGBB  : TRGBByteColor;  { þ Global RGBB color buffer. þ }
    GlobalBufRGBF  : TRGBFloatColor; { þ Global RGBF color buffer. þ }
    GlobalBufWord  : Word;           { þ Global WORD value buffer. þ }

    CurrentObject    : P3DObject;
    CurrentCamera    : P3DCamera;
    CurrentLight     : PLight;
    CurrentMaterial  : PMaterial;
    CurrentTrack     : P3DTrack;
    CurrentTrackType : DWord;

    MemoryAllocated   : DWord;

{ þ >>> D E B U G  F U N C T I O N S <<< þ }

{$IFDEF _I3D_3DSL_DEBUGMODE_}
Const DebugFileName = '3dsload.log'; { þ Debug log filename þ }
Var VertexSum       : DWord;
    FaceSum         : DWord;

 Function Hex(L : LongInt) : String;
 Const HexNumbers : Array[0..15] Of Char = '0123456789ABCDEF';
 Var S : String[8];
 Begin
  S:='';
  Repeat
   S:=HexNumbers[L Mod 16]+S;
   L:=L Div 16;
  Until L=0;
  Hex:=S;
 End ;

 Procedure DebugInit(FileToDebug : String);
 Begin
  VertexSum:=0; FaceSum:=0;
  If DebugFileName<>'' Then Assign(Output,DebugFileName);
  Rewrite(Output);
  WriteLn(Output,#13,#10,' þ Inquisition 3D Engine for Free Pascal - 3DS LOADER DEBUG LOG FILE');
  WriteLn(Output,' þ Loader code by Karoly Balogh (a.k.a. Charlie/Inquisition) and others');
  WriteLn(Output,' þ Loader version : ',I3D_LoaderVersionStr);
  WriteLn(Output,' þ .3DS Filename  : ',FileToDebug,#13,#10);
 End;

 Procedure DebugDone;
 Begin
  With Loaded3DS^ Do Begin
    WriteLn(Output,#13,#10,' þ Memory allocated : ',MemoryAllocated,' bytes.');
    WriteLn(Output,#13,#10,' þ Number of Objects loaded   : ',ObjectNum);
    WriteLn(Output,'   - Number of Vertices loaded  : ',VertexSum);
    WriteLn(Output,'   - Number of Faces loaded     : ',FaceSum);
    WriteLn(Output,' þ Number of Cameras loaded   : ',CameraNum);
    WriteLn(Output,' þ Number of Lights loaded    : ',LightNum);
    WriteLn(Output,' þ Number of Materials loaded : ',MaterialNum);
    WriteLn(Output,' þ Number of Tracks loaded    : ',TracksNum);
    If I3D_Load3DSErrorCode=0 Then WriteLn(Output,#13,#10,' þ Everything went OK.')
                              Else Begin
                                    WriteLn(Output,#13,#10,' þ ERROR CODE : ',I3D_Load3DSErrorCode);
                                    WriteLn(Output,' þ ERROR MSG  : ',I3D_Get3DSErrorString(I3D_Load3DSErrorCode));
                                   End;
   End;
  Close(Output);
  Assign(Output,'');
  AssignCrt(Output);
  Rewrite(Output);
 End;
{$ENDIF}

{ þ >>> I N T E R N A L  F U N C T I O N S <<< þ }

{ þ >>> FORWARD DECLARATIONS <<< þ }
Procedure I3DSL_ChunkReader(TreeDepth : DWord; CPosition : DWord); Forward;

{ þ >>> ADDITIONAL FUNCTIONS <<< þ }

{ þ Reads a byte from the 3DS buffer þ }
Function ReadByte : Byte;
Begin
 ReadByte:=Byte((Current3DS+Current3DSPos)^);
 Inc(Current3DSPos);
End;

{ þ Reads a word from the 3DS buffer þ }
Function ReadWord : Word;
Begin
 ReadWord:=Word((Current3DS+Current3DSPos)^);
 Inc(Current3DSPos,2);
End;

{ þ Reads a doubleword from the 3DS buffer þ }
Function ReadDWord : DWord;
Begin
 ReadDWord:=DWord((Current3DS+Current3DSPos)^);
 Inc(Current3DSPos,4);
End;

{ þ Reads a null-terminated string from, the 3DS buffer þ }
Function ReadANSIString : String;
Var BufString : String;
    BufChar   : Char;
Begin
 BufString:='';
 BufChar:=Char(ReadByte);
 While BufChar<>#0 Do Begin
   BufString:=BufString+BufChar;
   BufChar:=Char(ReadByte);
  End;
 If BufString='' Then BufString:='$DUMMY$';
 ReadANSIString:=BufString;
End;


{ þ >>> CHUNK SPECIFIC READERS <<< þ }

{ þ Reads an RGB byte color chunk þ }
Procedure Chunk_RGBBColor(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read RGB values, and store into the global RGBB buffer, so þ }
 { þ the surrounding chunk what needs this data can fetch it. þ }
 With GlobalBufRGBB Do Begin
   R:=ReadByte;
   G:=ReadByte;
   B:=ReadByte;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - RGB byte color values:',
                   ' R:',R,' G:',G,' B:',B);
   {$ENDIF}
  End;
End;

{ þ Reads an RGB float color chunk þ }
Procedure Chunk_RGBFColor(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read RGB values, and store into the global RGBF buffer, so þ }
 { þ the surrounding chunk what needs this data can fetch it. þ }
 With GlobalBufRGBF Do Begin
   R:=ReadDWord;
   G:=ReadDWord;
   B:=ReadDWord;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - RGB float color values:',
                   ' R:',R:0:5,' G:',G:0:5,' B:',B:0:5);
   {$ENDIF}
  End;
End;

{ þ Reads a WORD value chunk þ }
Procedure Chunk_WORDValue(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read the WORD value, and store into the global WORD buffer, so þ }
 { þ the surrounding chunk what needs this data can fetch it. þ }
 GlobalBufWord:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Value: ',GlobalBufWord);
 {$ENDIF}
End;

{ þ Reads a material block chunk þ }
Procedure Chunk_MaterialBlock(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Init memory area to store this material data þ }
 Inc(Loaded3DS^.MaterialNum);
 If Loaded3DS^.MaterialNum=1 Then Begin
   New(Loaded3DS^.MaterialL);
   CurrentMaterial:=Loaded3DS^.MaterialL;
   Inc(MemoryAllocated,SizeOf(Loaded3DS^.MaterialL^));
  End Else Begin
   New(CurrentMaterial^.PNextMat);
   CurrentMaterial:=CurrentMaterial^.PNextMat;
   Inc(MemoryAllocated,SizeOf(CurrentMaterial^.PNextMat^));
  End;
 FillChar(CurrentMaterial^,SizeOf(Loaded3DS^.MaterialL^),#0);

 { þ Read remaining chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ þ Reads a material name chunk þ }
Procedure Chunk_MaterialName(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Material name þ }
 With CurrentMaterial^ Do Begin
   Name:=ReadANSIString;

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn('':TreeDepth,' - Material name: ',Name);
   {$ENDIF}
  End;
End;

{ þ Reads a material ambient color chunk þ }
Procedure Chunk_MaterialAmbient(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read internal chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);

 { þ Now store the global color values into the material data. þ }
 { þ If the .3DS file isn't buggy there was an RGBB chunk... þ }
 CurrentMaterial^.Ambient:=GlobalBufRGBB;
End;

{ þ Reads a material texture data chunk þ }
Procedure Chunk_MaterialTexture(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read internal chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);

 { þ Now store the global word value into the material data. þ }
 { þ If the .3DS file isn't buggy, there was a WORD value chunk... þ }
 CurrentMaterial^.Visibility:=GlobalBufWord;
End;

{ þ Reads a texture map file name þ }
Procedure Chunk_TexMapFileName(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read the filename þ }
 With CurrentMaterial^ Do Begin
   FileName:=ReadANSIString;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Filename: ',FileName);
   {$ENDIF}
  End;
End;

{ þ Reads an object block chunk (contains camera, light or object data þ }
Procedure Chunk_ObjectBlock(TreeDepth : DWord; CPosition : DWord);
Var BufString : String;
Begin
 BufString:=ReadANSIString;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn('':TreeDepth,' - Object name: ',BufString);
 {$ENDIF}
 GlobalBufStr:=BufString;
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ þ Reads an object mesh chunk þ }
Procedure Chunk_ObjectMesh(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Init memory area to store this object data þ }
 Inc(Loaded3DS^.ObjectNum);
 If Loaded3DS^.ObjectNum=1 Then Begin
   New(Loaded3DS^.Object3DL);
   CurrentObject:=Loaded3DS^.Object3DL;
   Inc(MemoryAllocated,SizeOf(Loaded3DS^.Object3DL^));
  End Else Begin
   New(CurrentObject^.PNextObj);
   CurrentObject:=CurrentObject^.PNextObj;
   Inc(MemoryAllocated,SizeOf(CurrentObject^.PNextObj^));
  End;
 FillChar(CurrentObject^,SizeOf(Loaded3DS^.Object3DL^),#0);
 CurrentObject^.ObjName:=GlobalBufStr;

 { þ Read remaining chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ þ Reads a vertex list chunk þ }
Procedure Chunk_VertexList(TreeDepth : DWord; CPosition : DWord);
Var BufVertexNum : Word;
    Counter      : DWord;
Begin
 BufVertexNum:=ReadWord; { þ Reads number of vertexes in this chunk þ }

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  Inc(VertexSum,BufVertexNum);
  WriteLn(Output,'':TreeDepth,' - Found ',BufVertexNum,' vertexes.');
 {$ENDIF}

 With CurrentObject^ Do Begin
   VertexNum:=BufVertexNum;
   { þ Allocating memory for the vertex list þ }
   GetMem(Vertex,SizeOf(T3DVertex)*BufVertexNum);
   FillChar(Vertex^,SizeOf(T3DVertex)*BufVertexNum,#0);
   Inc(MemoryAllocated,SizeOf(T3DVertex)*BufVertexNum);

   { þ Vertex data. XZY ORDER! þ }
   For Counter:=0 To BufVertexNum-1 Do Begin
     With Vertex[Counter].Vector Do Begin
       DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth,' - Vertex ',Counter,'. X:',X:0:3,' Y:',Y:0:3,' Z:',Z:0:3);
       {$ENDIF}
      End;
    End;
  End;
End;

{ þ Reads a face list chunk þ }
Procedure Chunk_FaceList(TreeDepth : DWord; CPosition : DWord);
Var BufFaceNum : Word;
    Counter    : DWord;
    BufValue   : Word;
Begin
 BufFaceNum:=ReadWord; { þ Reads number of faces in this chunk þ }

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  Inc(FaceSum,BufFaceNum);
  WriteLn(Output,'':TreeDepth,' - Found ',BufFaceNum,' faces.');
 {$ENDIF}

 With CurrentObject^ Do Begin
   FaceNum:=BufFaceNum;
   { þ Allocating memory for the face list þ }
   GetMem(Face,SizeOf(T3DFace)*BufFaceNum);
   FillChar(Face^,SizeOf(T3DFace)*BufFaceNum,#0);
   Inc(MemoryAllocated,SizeOf(T3DFace)*BufFaceNum);

   { þ Face data þ }
   For Counter:=0 To BufFaceNum-1 Do Begin
     With Face[Counter] Do Begin
       Vertex1:=ReadWord;
       Vertex2:=ReadWord;
       Vertex3:=ReadWord;
       BufValue:=ReadWord {And $00FF};
       ABVis:=Boolean(BufValue And $0004);
       BCVis:=Boolean(BufValue And $0002);
       ACVis:=Boolean(BufValue And $0001);

       UWrap:=Boolean(BufValue And $0008); { ? May be buggy  ? }
       VWrap:=Boolean(BufValue And $0010); { ? Needs testing ? }

       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth,' - Face ',Counter,'.',
                       ' A:',Vertex1,' B:',Vertex2,' C:',Vertex3,
                       ' AB:',ABVis:5,' BC:',BCVis:5,' CA:',ACVis:5,
                       ' UWrap:',UWrap,' VWrap:',VWrap,' Flags:',BufValue);
       {$ENDIF}
      End;
    End;
  End;

 { þ Read remaining chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ þ Reads a face mapping list chunk þ  }
Procedure Chunk_FaceMappingList(TreeDepth : DWord; CPosition : DWord);
Var BufString  : String;
    BufFaceNum : Word;
    BufMapFace : Word;
    Counter    : DWord;
Begin
 { þ Read material name for the faces following þ }
 BufString:=ReadANSIString;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Material name for the faces following: ',BufString);
 {$ENDIF}

 { þ Read number of face mapping data þ }
 BufFaceNum:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of faces with this material: ',BufFaceNum);
 {$ENDIF}

 { þ Read face mapping data þ }
 If BufFaceNum>0 Then Begin
   For Counter:=0 To BufFaceNum-1 Do Begin
     BufMapFace:=ReadWord;
     With CurrentObject^.Face[BufMapFace] Do Begin
       MatName:=BufString;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth,' - Face ',BufMapFace,'.');
       {$ENDIF}
      End;
    End;
  End;
End;

{ þ Reads a mapping list chunk þ }
Procedure Chunk_MappingList(TreeDepth : DWord; CPosition : DWord);
Var BufMappingNum : Word;
    Counter       : DWord;
Begin
 BufMappingNum:=ReadWord; { þ Reads number of mapping coords. in this chunk þ }

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Found ',BufMappingNum,' vertex mappings.');
 {$ENDIF}

 With CurrentObject^ Do Begin

   For Counter:=0 To BufMappingNum-1 Do Begin
     With Vertex[Counter] Do Begin
       DWord(U):=ReadDWord;
       DWord(V):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
{        WriteLn(Output,'':TreeDepth,' - Vertex ',Counter,
                       '. U:',U:0:6,' V:',V:0:6);}
       {$ENDIF}
      End;
    End;

  End;

End;

{ þ Reads an object transformation matrix chunk þ }
Procedure Chunk_ObjMatrix(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentObject^ Do Begin

   { þ Rotation matrix data (BOTH ROWS AND COLUMNS ARE IN XZY ORDER!) þ }
   DWord(Rot_Mat[0]):=ReadDWord; DWord(Rot_Mat[2]):=ReadDWord; DWord(Rot_Mat[1]):=ReadDWord;
   DWord(Rot_Mat[6]):=ReadDWord; DWord(Rot_Mat[8]):=ReadDWord; DWord(Rot_Mat[7]):=ReadDWord;
   DWord(Rot_Mat[3]):=ReadDWord; DWord(Rot_Mat[5]):=ReadDWord; DWord(Rot_Mat[4]):=ReadDWord;

   { þ Translation matrix data (XYZ ORDER!) þ }
   DWord(Trans_Mat[0]):=ReadDWord;
   DWord(Trans_Mat[2]):=ReadDWord;
   DWord(Trans_Mat[1]):=ReadDWord;

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(OutPut,'':TreeDepth,' - The rotation matrix is: ');
    WriteLn(OutPut,'':TreeDepth,'   | ',Rot_Mat[0]:13:5,' ',Rot_Mat[1]:13:5,' ',Rot_Mat[2]:13:5,'  |',#13,#10,
                   '':TreeDepth,'   | ',Rot_Mat[3]:13:5,' ',Rot_Mat[4]:13:5,' ',Rot_Mat[5]:13:5,'  |',#13,#10,
                   '':TreeDepth,'   | ',Rot_Mat[6]:13:5,' ',Rot_Mat[7]:13:5,' ',Rot_Mat[8]:13:5,'  |');
    WriteLn(OutPut,'':TreeDepth,' - The translation matrix is:');
    WriteLn(OutPut,'':TreeDepth,'   | ',Trans_Mat[0]:13:5,' ',Trans_Mat[1]:13:5,' ',Trans_Mat[2]:13:5,'  |');
   {$ENDIF}

  End;
End;

{ þ Reads an object visibility chunk þ }
Procedure Chunk_ObjVisibility(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentObject^ Do Begin

   { þ Read visibility data þ }
   Visible:=(ReadByte=0);

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    Write(Output,'':TreeDepth,' - Object is ');
    If Visible Then WriteLn('visible.') Else WriteLn('invisible.');
   {$ENDIF}

  End;
End;

{ þ Reads a light object chunk þ }
Procedure Chunk_Light(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Init memory area to store this light data þ }
 Inc(Loaded3DS^.LightNum);
 If Loaded3DS^.LightNum=1 Then Begin
   New(Loaded3DS^.LightL);
   CurrentLight:=Loaded3DS^.LightL;
   Inc(MemoryAllocated,SizeOf(Loaded3DS^.LightL^));
  End Else Begin
   New(CurrentLight^.PNextLight);
   CurrentLight:=CurrentLight^.PNextLight;
   Inc(MemoryAllocated,SizeOf(CurrentLight^.PNextLight^));
  End;
 FillChar(CurrentLight^,SizeOf(Loaded3DS^.LightL^),#0);
 CurrentLight^.LightName:=GlobalBufStr;
End;

{ þ Reads a camera object chunk þ }
Procedure Chunk_Camera(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Init memory area to store this camera data þ }
 Inc(Loaded3DS^.CameraNum);
 If Loaded3DS^.CameraNum=1 Then Begin
   New(Loaded3DS^.Camera3DL);
   CurrentCamera:=Loaded3DS^.Camera3DL;
   Inc(MemoryAllocated,SizeOf(Loaded3DS^.Camera3DL^));
  End Else Begin
   New(CurrentCamera^.PNextCam);
   CurrentCamera:=CurrentCamera^.PNextCam;
   Inc(MemoryAllocated,SizeOf(CurrentCamera^.PNextCam^));
  End;
 FillChar(CurrentCamera^,SizeOf(Loaded3DS^.Camera3DL^),#0);
 CurrentCamera^.CamName:=GlobalBufStr;

 { þ Moving camera data þ }
 With CurrentCamera^ Do Begin
   With Position Do Begin { þ Camera position data. XZY ORDER! þ }
     DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
    End;
   With Target Do Begin { þ Camera target data. XZY ORDER! þ }
     DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
    End;
   DWord(Roll):=ReadDWord; { þ Camera roll value þ }
   DWord(FOV):=ReadDWord; { þ Camera FOV value þ }

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    With Position Do
      WriteLn(Output,'':TreeDepth,' - Camera position: X:',X:0:3,' Y:',Y:0:3,' Z:',Z:0:3);
    With Target Do
      WriteLn(Output,'':TreeDepth,' - Camera target:   X:',X:0:3,' Y:',Y:0:3,' Z:',Z:0:3);
    WriteLn(Output,'':TreeDepth,' - Camera roll: ',Roll:0:3);
    WriteLn(Output,'':TreeDepth,' - Camera FOV : ',FOV:0:3);
   {$ENDIF}
  End;

 { þ Read remaining chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ þ Reads a frames info chunk þ }
Procedure Chunk_FramesInfo(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Read frame info data þ }
 With Loaded3DS^ Do Begin
   FirstFrame:=ReadDWord;
   LastFrame :=ReadDWord;
   FramesNum :=Abs(LastFrame-FirstFrame);
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Start : ',FirstFrame,'. frame');
    WriteLn(Output,'':TreeDepth,' - End   : ',LastFrame,'. frame');
    WriteLn(Output,'':TreeDepth,' - Length: ',FramesNum,' frames');
   {$ENDIF}
  End;
End;

{ þ Reads a track info chunk þ }
{ þ THIS IS NOT A CHUNK, BUT A PART OF SEVERAL CHUNKS! þ }
Procedure Read_TrackInfo(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Init memory are to store this track data þ }
 Inc(Loaded3DS^.TracksNum);
 If Loaded3DS^.TracksNum=1 Then Begin
   New(Loaded3DS^.TracksL);
   CurrentTrack:=Loaded3DS^.TracksL;
   Inc(MemoryAllocated,SizeOf(Loaded3DS^.TracksL^));
  End Else Begin
   New(CurrentTrack^.PNextTrack);
   CurrentTrack:=CurrentTrack^.PNextTrack;
   Inc(MemoryAllocated,SizeOf(CurrentTrack^.PNextTrack^));
  End;
 FillChar(CurrentTrack^,SizeOf(Loaded3DS^.TracksL^),#0);

 { þ Assign track type þ }
 CurrentTrack^.TrackType:=CurrentTrackType;

 { þ Reading internal chunks þ }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ þ Reads an object track info chunk þ }
Procedure Chunk_ObjectTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Set track type þ }
 CurrentTrackType:=ObjectTrack;
 { þ Read remaining track info þ }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ þ Reads a track name chunk þ }
Procedure Chunk_TrackName(TreeDepth : DWord; CPosition : DWord);
Var BufWord1, BufWord2 : Word;
Begin
 With CurrentTrack^ Do Begin
   { þ Read track name þ }
   TrackName:=ReadANSIString;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Track name: ',TrackName);
   {$ENDIF}

   { þ Read track name data þ }
   BufWord1:=ReadWord;
   BufWord2:=ReadWord;
   TrackParent:=ReadWord;

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Track name data: Flags $0',Hex(BufWord1),
                                ', $0',Hex(BufWord2),', Parent ',TrackParent);
   {$ENDIF}
  End;
End;

{ þ Reads a track number chunk þ }
Procedure Chunk_TrackNumber(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentTrack^ Do Begin
   { þ Read track number þ }
   TrackNumber:=ReadWord;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Track number: ',TrackNumber);
    If TrackNumber<>Loaded3DS^.TracksNum-1 Then
      WriteLn(Output,'':TreeDepth,' - WARNING! TRACK CHUNK MISSED! TRUE TRACK NUMBER:',Loaded3DS^.TracksNum-1);
   {$ENDIF}
  End;
End;

{ þ Reads a track pivot point chunk þ }
Procedure Chunk_TrackPivotPoint(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentTrack^ Do Begin
   { þ Read track pivot point (XZY ORDER!) þ }
   With TrackPivot.Vector Do Begin
     DWord(X):=ReadDWord;
     DWord(Z):=ReadDWord;
     DWord(Y):=ReadDWord;

     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Track pivot point: ',
                     ' X:',X:0:6,' Y:',Y:0:6,' Z:',Z:0:6);
     {$ENDIF}
    End;
  End;
End;

{ þ THIS IS NOT A CHUNK, BUT A PART OF SEVERAL CHUNKS! þ }
Procedure Read_SplineFlags(TreeDepth : DWord; Flags : Word; Var SplineFlags : TSplineFlags);
Const FlagNamesNum = 4;
      FlagNames    : Array[0..FlagNamesNum] Of String[16] = (
                     'Tension','Continuity','Bias',
                     'Ease To','Ease From');
Var BufSingle : Single;
    Counter   : Word;
Begin
 SplineFlags.Flags:=Flags;
 For Counter:=0 To 15 Do Begin
   If Boolean(Flags And (1 Shl Counter)) Then Begin
     DWord(BufSingle):=ReadDWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      If Counter<FlagNamesNum Then WriteLn(Output,'':TreeDepth,' - ',FlagNames[Counter],'=',BufSingle:0:6)
                              Else WriteLn(Output,'':TreeDepth,' - Unknown Flag = ',BufSingle:0:6);
     {$ENDIF}
     With SplineFlags Do Begin
       Case Counter Of
         0 : Tension:=BufSingle;
         1 : Continuity:=BufSingle;
         2 : Bias:=BufSingle;
         3 : EaseTo:=BufSingle;
         4 : EaseFrom:=BufSingle;
        End;
      End;
    End;
  End;
End;

{ þ  THIS IS NOT A CHUNK, BUT A PART OF SEVERAL CHUNKS! þ }
Procedure Read_UnknownValues(TreeDepth : DWord);
Var UnknownValue : Word;
    Counter      : DWord;
Begin
 { þ Read some unknown values þ }
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  Write(Output,'':TreeDepth,' - Unknown values: ');
 {$ENDIF}
 For Counter:=0 To 4 Do Begin
   UnknownValue:=ReadWord;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    Write(Output,'$',Hex(UnknownValue),' ')
   {$ENDIF}
  End;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output);
 {$ENDIF}
End;

{ þ Reads a track position keys chunk þ }
Procedure Chunk_TrackPositionKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufPosKeys   : Word;
    BufFlags     : Word;
Begin
 { þ Read some unknown values þ }
 Read_UnknownValues(TreeDepth);

 { þ Read number of position keys þ }
 BufPosKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of position keys: ',BufPosKeys);
 {$ENDIF}

 { þ An unknown value again... þ }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { þ Init memory area to store the keys þ }
 With CurrentTrack^ Do Begin
   TrackPosNum:=BufPosKeys;
   GetMem(TrackPosKeys,SizeOf(TPosKey)*BufPosKeys);
   FillChar(TrackPosKeys^,SizeOf(TPosKey)*BufPosKeys,#0);
   Inc(MemoryAllocated,SizeOf(TPosKey)*BufPosKeys);
  End;

 { þ Read positionkeys þ }
 For Counter:=0 To BufPosKeys-1 Do Begin
   With CurrentTrack^.TrackPosKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { þ Reading position XZY ORDER! þ }
     With Vector Do Begin
       DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth+2,' - X:',X:0:6,' Y:',Y:0:6,' Z:',Z:0:6);
       {$ENDIF}
      End;
    End;
  End;

End;

{ þ Reads a track rotation keys chunk þ }
Procedure Chunk_TrackRotationKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufRotKeys   : Word;
    BufFlags     : Word;
Begin
 { þ Read some unknown values þ }
 Read_UnknownValues(TreeDepth);

 { þ Read number of position keys þ }
 BufRotKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of rotation keys: ',BufRotKeys);
 {$ENDIF}

 { þ An unknown value again... þ }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { þ Init memory area to store the keys þ }
 With CurrentTrack^ Do Begin
   TrackRotNum:=BufRotKeys;
   GetMem(TrackRotKeys,SizeOf(TRotKey)*BufRotKeys);
   FillChar(TrackRotKeys^,SizeOf(TRotKey)*BufRotKeys,#0);
   Inc(MemoryAllocated,SizeOf(TRotKey)*BufRotKeys);
  End;

 { þ Read positionkeys þ }
 For Counter:=0 To BufRotKeys-1 Do Begin
   With CurrentTrack^.TrackRotKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { þ Reading position XZY ORDER! þ }
     DWord(Angle):=ReadDWord;
     With Vector Do Begin
       DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth+2,' - Angle: ',(Angle*180/PI):0:6,
                                    ' X:',X:0:6,' Y:',Y:0:6,' Z:',Z:0:6);
       {$ENDIF}
      End;
    End;
  End;

End;

{ þ Reads a track scale keys chunk þ }
Procedure Chunk_TrackScaleKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufScaleKeys : Word;
    BufFlags     : Word;
Begin
 { þ Read some unknown values þ }
 Read_UnknownValues(TreeDepth);

 { þ Read number of position keys þ }
 BufScaleKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of scale keys: ',BufScaleKeys);
 {$ENDIF}

 { þ An unknown value again... þ }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { þ Init memory area to store the keys þ }
 With CurrentTrack^ Do Begin
   TrackScaleNum:=BufScaleKeys;
   GetMem(TrackScaleKeys,SizeOf(TScaleKey)*BufScaleKeys);
   FillChar(TrackScaleKeys^,SizeOf(TScaleKey)*BufScaleKeys,#0);
   Inc(MemoryAllocated,SizeOf(TScaleKey)*BufScaleKeys);
  End;

 { þ Read positionkeys þ }
 For Counter:=0 To BufScaleKeys-1 Do Begin
   With CurrentTrack^.TrackScaleKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { þ Reading position XZY ORDER! þ }
     With Vector Do Begin
       DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth+2,' - X:',X:0:6,' Y:',Y:0:6,' Z:',Z:0:6);
       {$ENDIF}
      End;
    End;
  End;

End;

{ þ Reads a track morph keys chunk þ }
Procedure Chunk_TrackMorphKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufMorphKeys : Word;
    BufFlags     : Word;
Begin
 { þ Read some unknown values þ }
 Read_UnknownValues(TreeDepth);

 { þ Read number of position keys þ }
 BufMorphKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of morph keys: ',BufMorphKeys);
 {$ENDIF}

 { þ An unknown value again... þ }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { þ Init memory area to store the keys þ }
 With CurrentTrack^ Do Begin
   TrackMorphNum:=BufMorphKeys;
   GetMem(TrackMorphKeys,SizeOf(TMorphKey)*BufMorphKeys);
   FillChar(TrackMorphKeys^,SizeOf(TMorphKey)*BufMorphKeys,#0);
   Inc(MemoryAllocated,SizeOf(TMorphKey)*BufMorphKeys);
  End;

 { þ Read positionkeys þ }
 For Counter:=0 To BufMorphKeys-1 Do Begin
   With CurrentTrack^.TrackMorphKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { þ Reading object name to morph þ }
     ObjName:=ReadANSIString;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth+2,' - Object name: ',ObjName);
     {$ENDIF}
    End;
  End;

End;


{ þ Reads a camera track info chunk þ }
Procedure Chunk_CameraTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Set track type þ }
 CurrentTrackType:=CameraTrack;
 { þ Read remaining track info þ }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ þ Reads a camera target track info chunk þ }
Procedure Chunk_CameraTargetTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Set track type þ }
 CurrentTrackType:=CameraTargetTrack;
 { þ Read remaining track info þ }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ þ Reads a camera FOV keys chunk þ }
Procedure Chunk_CameraFOVKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufFOVKeys   : Word;
    BufFlags     : Word;
Begin
 { þ Read some unknown values þ }
 Read_UnknownValues(TreeDepth);

 { þ Read number of position keys þ }
 BufFOVKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of FOV keys: ',BufFOVKeys);
 {$ENDIF}

 { þ An unknown value again... þ }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { þ Init memory area to store the keys þ }
 With CurrentTrack^ Do Begin
   TrackFOVNum:=BufFOVKeys;
   GetMem(TrackFOVKeys,SizeOf(TFOVKey)*BufFOVKeys);
   FillChar(TrackFOVKeys^,SizeOf(TFOVKey)*BufFOVKeys,#0);
   Inc(MemoryAllocated,SizeOf(TFOVKey)*BufFOVKeys);
  End;

 { þ Read positionkeys þ }
 For Counter:=0 To BufFOVKeys-1 Do Begin
   With CurrentTrack^.TrackFOVKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { þ Reading roll value þ }
     DWord(FOV):=ReadDWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth+2,' - FOV:',FOV:0:6);
     {$ENDIF}
    End;
  End;

End;

{ þ Reads a camera roll keys chunk þ }
Procedure Chunk_CameraRollKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufRollKeys  : Word;
    BufFlags     : Word;
Begin
 { þ Read some unknown values þ }
 Read_UnknownValues(TreeDepth);

 { þ Read number of position keys þ }
 BufRollKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of roll keys: ',BufRollKeys);
 {$ENDIF}

 { þ An unknown value again... þ }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { þ Init memory area to store the keys þ }
 With CurrentTrack^ Do Begin
   TrackRollNum:=BufRollKeys;
   GetMem(TrackRollKeys,SizeOf(TRollKey)*BufRollKeys);
   FillChar(TrackRollKeys^,SizeOf(TRollKey)*BufRollKeys,#0);
   Inc(MemoryAllocated,SizeOf(TRollKey)*BufRollKeys);
  End;

 { þ Read positionkeys þ }
 For Counter:=0 To BufRollKeys-1 Do Begin
   With CurrentTrack^.TrackRollKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { þ Reading roll value þ }
     DWord(Roll):=ReadDWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth+2,' - Roll:',Roll:0:6);
     {$ENDIF}
    End;
  End;

End;


{ þ Reads a spotlight position keys chunk þ }
Procedure Chunk_SpotlightTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Set track type þ }
 CurrentTrackType:=SpotlightTrack;
 { þ Read remaining track info þ }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ þ Reads a spotlight position keys chunk þ }
Procedure Chunk_SpotlightTargetTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Set track type þ }
 CurrentTrackType:=SpotlightTargetTrack;
 { þ Read remaining track info þ }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ þ Reads a omnilight position keys chunk þ }
Procedure Chunk_OmnilightTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { þ Set track type þ }
 CurrentTrackType:=OmnilightTrack;
 { þ Read remaining track info þ }
 Read_TrackInfo(TreeDepth,CPosition);
End;


{ þ >>> MAIN CHUNK READERS <<< þ }

Procedure I3DSL_UnknownChunk(TreeDepth : DWord; CPosition : DWord);
Begin
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn('':TreeDepth,' - Chunk was skipped!');
 {$ENDIF}
End;

{ þ Returns chunk data, belongs to the specified ID. þ }
Function I3DSL_FindChunk(ChunkID : Word) : TChunkData;
Var BufChunkData : TChunkData;
Begin
 With BufChunkData Do Begin
   Case ChunkID Of
     Main3DS : Begin CDescr:='Main'; CReader:=Nil; End;
     Edit3DS : Begin CDescr:='Editor'; CReader:=Nil; End;
         Edit_MATERIAL : Begin CDescr:='Material block'; CReader:=@Chunk_MaterialBlock; End;
              Mat_NAME    : Begin CDescr:='Material name'; CReader:=@Chunk_MaterialName; End;
              Mat_AMBIENT : Begin CDescr:='Material ambient color'; CReader:=@Chunk_MaterialAmbient; End;
              Mat_TEXTURE : Begin CDescr:='Material texture data'; CReader:=@Chunk_MaterialTexture; End;
                  Tex_MAPFILE : Begin CDescr:='Texture map filename'; CReader:=@Chunk_TexMapFileName; End;
         Edit_BACKGR   : Begin CDescr:='Background color'; CReader:=Nil; End;
         Edit_AMBIENT  : Begin CDescr:='Ambient color'; CReader:=Nil; End;
         Edit_OBJECT   : Begin CDescr:='Object block'; CReader:=@Chunk_ObjectBlock; End;
              Obj_OBJMESH : Begin CDescr:='Object mesh'; CReader:=@Chunk_ObjectMesh; End;
                  Tri_VERTEXL  : Begin CDescr:='Vertex list'; CReader:=@Chunk_VertexList; End;
                  Tri_FACELIST : Begin CDescr:='Face list'; CReader:=@Chunk_FaceList; End;
                      Tri_FACEMAT : Begin CDescr:='Faces mapping list'; CReader:=@Chunk_FaceMappingList; End;
                  Tri_MAPPING  : Begin CDescr:='Mapping coordinates list'; CReader:=@Chunk_MappingList; End;
                  Tri_MATRIX   : Begin CDescr:='Object transformation matrix'; CReader:=@Chunk_ObjMatrix; End;
                  Tri_VISIBLE  : Begin CDescr:='Object visibility'; CReader:=@Chunk_ObjVisibility; End;
              Obj_LIGHT   : Begin CDescr:='Light'; CReader:=@Chunk_Light; End;
              Obj_CAMERA  : Begin CDescr:='Camera'; CReader:=@Chunk_Camera; End;

     Keyf3DS : Begin CDescr:='Keyframer'; CReader:=Nil; End;
         Keyf_FRAMES       : Begin CDescr:='Frames info'; CReader:=@Chunk_FramesInfo; End;
         Keyf_OBJTRACK     : Begin CDescr:='Object track info'; CReader:=@Chunk_ObjectTrack; End;
              Track_OBJNAME   : Begin CDescr:='Track name'; CReader:=@Chunk_TrackName; End;
              Track_OBJNUMBER : Begin CDescr:='Track number'; CReader:=@Chunk_TrackNumber; End;
              Track_OBJPIVOT  : Begin CDescr:='Track pivot point'; CReader:=@Chunk_TrackPivotPoint; End;
              Track_OBJPOS    : Begin CDescr:='Track position keys'; CReader:=@Chunk_TrackPositionKeys; End;
              Track_OBJROTATE : Begin CDescr:='Track rotate keys'; CReader:=@Chunk_TrackRotationKeys; End;
              Track_OBJSCALE  : Begin CDescr:='Track scale keys'; CReader:=@Chunk_TrackScaleKeys; End;
              Track_OBJMORPH  : Begin CDescr:='Track morph keys'; CReader:=@Chunk_TrackMorphKeys; End;
              Track_OBJHIDE   : Begin CDescr:='Track hide keys'; CReader:=@I3DSL_UnknownChunk; End;
         Keyf_CAMTRACK     : Begin CDescr:='Camera position track info'; CReader:=@Chunk_CameraTrack; End;
         Keyf_CAMTARGTRACK : Begin CDescr:='Camera target track info'; CReader:=@Chunk_CameraTargetTrack; End;
              Track_CAMFOV    : Begin CDescr:='Track camera FOV keys'; CReader:=@Chunk_CameraFOVKeys; End;
              Track_CAMROLL   : Begin CDescr:='Track camera roll keys'; CReader:=@Chunk_CameraRollKeys; End;
         Keyf_LIGHTTRACK     : Begin CDescr:='Spotlight(?) position track info'; CReader:=@Chunk_SpotlightTrack; End;
         Keyf_LIGHTTARGTRACK : Begin CDescr:='Spotlight(?) target position track info'; CReader:=@Chunk_SpotlightTargetTrack; End;
         Keyf_OMNILIGHTTRACK : Begin CDescr:='Omnilight(?) positition track info'; CReader:=@Chunk_OmnilightTrack; End;

     Chunk_RGBB : Begin CDescr:='RGB byte color'; CReader:=@Chunk_RGBBColor; End;
     Chunk_RGBF : Begin CDescr:='RGB float color'; CReader:=@Chunk_RGBFColor; End;
     Chunk_WORD : Begin CDescr:='WORD value'; CReader:=@Chunk_WORDValue; End;

     Else Begin { þ Unknown chunk specified þ }
            CValid:=False; CDescr:='Unknown'; CReader:=Nil;
            I3DSL_FindChunk:=BufChunkData;
            Exit;
           End;
    End;
   CValid:=True;
  End;
 I3DSL_FindChunk:=BufChunkData;
End;

{ þ This is the main analyzer procedure. Processes the next branch-level þ }
{ þ in the .3DS file (which tree-structured). This procedure is recursive. þ }
{ þ I don't like recursive procedures, but in this case, this is the þ }
{ þ better solution. The previous versions (below 0.4.0) of this loader þ }
{ þ wasn't recursive, so i tried both ways... þ }
Procedure I3DSL_ChunkReader(TreeDepth : DWord; CPosition : DWord);
Var ChunkID      : Word;
    ChunkLength  : DWord;
    CurrentPos   : DWord;
    CurrentChunk : TChunkData;
Begin
 While Current3DSPos<CPosition Do Begin

   CurrentPos:=Current3DSPos;

   { þ Read current chunk header values þ }
   ChunkID    :=ReadWord;
   ChunkLength:=ReadDWord;
   If ChunkLength=0 Then Exit;
{   WriteLn(ChunkID,' ',ChunkLength);}
   If (TreeDepth=0) And (ChunkID<>Main3DS) Then Begin
     { þ If there is no main chunk ID at the beginning of the file, þ }
     { þ then it's a 3DS file, or corrupted. þ }
     I3D_Load3DSErrorCode:=I3DL_ErrorNo3DS;
     Exit;
    End;

   CurrentChunk:=I3DSL_FindChunk(ChunkID);
   With CurrentChunk Do Begin
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' þ ',CDescr,' chunk ID $',Hex(ChunkID),
                     ' at ',CurrentPos,', size: ',ChunkLength,
                     ' bytes.');
     {$ENDIF}
     If Not CValid Then Begin
       Current3DSPos:=CurrentPos+ChunkLength;
      End Else Begin
       CurrentPos:=CurrentPos+ChunkLength;
       If CReader<>Nil Then Begin
          CReader(TreeDepth+2,CurrentPos);
         End Else Begin
          I3DSL_ChunkReader(TreeDepth+2,CurrentPos);
         End;
       Current3DSPos:=CurrentPos;
      End;
    End;

  End;
End;

{ þ >>> DATA AREA INIT FUNCTIONS <<< þ }

Procedure CollectLinkedData;
Var Counter : DWord;
Begin
 With Loaded3DS^ Do Begin
   { þ Collect Object Pointers þ }
   If ObjectNum>0 Then Begin
     GetMem(Object3D,ObjectNum*SizeOf(PP3DObject));
     FillChar(Object3D^,ObjectNum*SizeOf(PP3DObject),#0);
     Inc(MemoryAllocated,ObjectNum*SizeOf(PP3DObject));
     CurrentObject:=Object3DL;
     For Counter:=0 To ObjectNum-1 Do Begin
       Object3D[Counter]:=CurrentObject;
       CurrentObject:=CurrentObject^.PNextObj;
      End;
    End;

   { þ Collect Camera Datas þ }
   If CameraNum>0 Then Begin
     GetMem(Camera3D,CameraNum*SizeOf(PP3DCamera));
     FillChar(Camera3D^,CameraNum*SizeOf(PP3DCamera),#0);
     Inc(MemoryAllocated,CameraNum*SizeOf(PP3DCamera));
     CurrentCamera:=Camera3DL;
     For Counter:=0 To CameraNum-1 Do Begin
       Camera3D[Counter]:=CurrentCamera;
       CurrentCamera:=CurrentCamera^.PNextCam;
      End;
    End;

   If LightNum>0 Then Begin
     GetMem(Light,LightNum*SizeOf(PPLight));
     FillChar(Light^,LightNum*SizeOf(PPLight),#0);
     Inc(MemoryAllocated,LightNum*SizeOf(PPLight));
     CurrentLight:=LightL;
     For Counter:=0 To LightNum-1 Do Begin
       Light[Counter]:=CurrentLight;
       CurrentLight:=CurrentLight^.PNextLight;
      End;
    End;

   { þ Collect Material Data þ }
   If MaterialNum>0 Then Begin
     GetMem(Material,MaterialNum*SizeOf(PPMaterial));
     FillChar(Material^,MaterialNum*SizeOf(PPMaterial),#0);
     Inc(MemoryAllocated,MaterialNum*SizeOf(PPMaterial));
     CurrentMaterial:=MaterialL;
     For Counter:=0 To MaterialNum-1 Do Begin
       Material[Counter]:=CurrentMaterial;
       CurrentMaterial:=CurrentMaterial^.PNextMat;
      End;
    End;

   { þ Collect Animation Data þ }
   If TracksNum>0 Then Begin
     GetMem(Tracks,TracksNum*SizeOf(PP3DTrack));
     FillChar(Tracks^,TracksNum*SizeOf(PP3DTrack),#0);
     Inc(MemoryAllocated,TracksNum*SizeOf(PP3DTrack));
     CurrentTrack:=TracksL;
     For Counter:=0 To TracksNum-1 Do Begin
       Tracks[Counter]:=CurrentTrack;
       CurrentTrack:=CurrentTrack^.PNextTrack;
      End;
    End;
  End;
End;

Procedure PreLoadValues;
Var Counter  : DWord;
    Counter2 : DWord;
    Counter3 : DWord;
Begin
 With Loaded3DS^ Do Begin

   { þ Pairing Faces With Materials þ }
   If ObjectNum>0 Then Begin
     For Counter:=0 To ObjectNum-1 Do Begin
       With Object3D[Counter]^ Do Begin
         If FaceNum>0 Then Begin
           For Counter2:=0 To FaceNum-1 Do Begin
             If MaterialNum>0 Then Begin
               For Counter3:=0 To MaterialNum-1 Do Begin
                 If Face[Counter2].MatName=Material[Counter3]^.Name Then
                   Face[Counter2].MatNum:=Counter3;
                End;
              End;
            End;
          End;
        End;
      End;
    End;

   { þ Pairing Objects With Tracks þ }
   If ObjectNum>0 Then Begin
     For Counter:=0 To ObjectNum-1 Do Begin
       If TracksNum>0 Then Begin
         For Counter2:=0 To TracksNum-1 Do Begin
           If Object3D[Counter]^.ObjName=Tracks[Counter2]^.TrackName Then Begin
             Object3D[Counter]^.TrackNum:=Counter2;
            End;
          End;
        End;
      End;
    End;

   { þ Init Cameras With Tracks þ }
   If CameraNum>0 Then Begin
     For Counter:=0 To CameraNum-1 Do Begin
       With Camera3D[Counter]^ Do Begin
         PosTrack:=65535;
         TargTrack:=65535;
        End;
      End;
    End;

   { þ Pairing Cameras With Tracks þ }
   If CameraNum>0 Then Begin
     For Counter:=0 To CameraNum-1 Do Begin
       If TracksNum>0 Then Begin
         For Counter2:=0 To TracksNum-1 Do Begin
           If Camera3D[Counter]^.CamName=Tracks[Counter2]^.TrackName Then Begin
             If Tracks[Counter2]^.TrackType=CameraTrack Then
               Camera3D[Counter]^.PosTrack:=Counter2;
             If Tracks[Counter2]^.TrackType=CameraTargetTrack Then
               Camera3D[Counter]^.TargTrack:=Counter2;
           End;
          End;
        End;
      End;
    End;

  End;
End;

{ þ >>> P U B L I C  F U N C T I O N S <<< þ }

{ þ Returns the last 3DS loader error code, then reset the I3D_Load3DSError þ }
{ þ variable. No 3DS can be loaded while this variable isn't zero. As you þ }
{ þ see, it works exactly like the IOResult. Simple. þ }
Function I3D_Get3DSError : DWord;
Begin
 I3D_Get3DSError:=I3D_Load3DSErrorCode;
 I3D_Load3DSErrorCode:=0;
End;

{ þ Returns an error message string specific to the error code þ }
Function I3D_Get3DSErrorString(ErrorCode : DWord) : String;
Var BufString : String;
Begin
 Case ErrorCode Of
   I3DL_ErrorFileName : BufString:='Filename is empty!';
   I3DL_ErrorFileOpen : BufString:='Can''t open .3DS file!';
   I3DL_ErrorFileIO   : BufString:='Can''t read .3DS file!';
   I3DL_ErrorMemAlloc : BufString:='Not enough memory available to load .3DS file!';
   I3DL_ErrorNo3DS    : BufString:='Not a 3DS file or corrupted file!';
   I3DL_Error3DSRead  : BufString:='Fatal error in .3DS file!';
   I3DL_ErrorFree3DS  : BufString:='Can''t free up 3DS structure!';
   Else BufString:='Unknown error!';
  End;
 I3D_Get3DSErrorString:=BufString;
End;

{ þ Frees up a specified 3DS structure, from the memory þ }
Function I3D_Free3DS(Var Mesh3D : P3DMesh) : Boolean;
Var Counter : DWord;
Begin
 I3D_Free3DS:=False;

 If I3D_Load3DSErrorCode<>0 Then Begin
   { þ ERROR - Loader subsystem is in error! þ }
   Exit;
  End;

 If Mesh3D=Nil Then Begin
   { þ ERROR - Invalid pointer specified! þ }
   I3D_Load3DSErrorCode:=I3DL_ErrorFree3DS;
   Exit;
  End;

 { þ Freeing up the .3DS structure þ }
 With Mesh3D^ Do Begin

   { þ Freeing up objects þ }
   If ObjectNum>0 Then Begin
     For Counter:=0 To ObjectNum-1 Do Begin
       With Object3D[Counter]^ Do Begin
         { þ Freeing up vertexes þ }
         FreeMem(Vertex,VertexNum*SizeOf(T3DVertex));
         { þ Freeing up faces þ }
         FreeMem(Face,FaceNum*SizeOf(T3DFace));
        End;
       { þ Freeing up main object record þ }
       Dispose(Object3D[Counter]);
      End;
     { þ Freeing up main object pointer array þ }
     FreeMem(Object3D,ObjectNum*SizeOf(P3DObject));
    End;

   { þ Freeing up cameras þ }
   If CameraNum>0 Then Begin
     For Counter:=0 To CameraNum-1 Do Begin
       { þ Freeing up main camera record þ }
       Dispose(Camera3D[Counter]);
      End;
     { þ Freeing up main camera pointer array þ }
     FreeMem(Camera3D,CameraNum*SizeOf(P3DCamera));
    End;

   { þ Freeing up lights þ }
   If LightNum>0 Then Begin
     For Counter:=0 To LightNum-1 Do Begin
       { þ Freeing up main light record þ }
       Dispose(Light[Counter]);
      End;
     { þ Freeing up main light pointer array þ }
     FreeMem(Light,LightNum*SizeOf(PLight));
     { þ LIGHTS STILL TO BE IMPLEMENTED!!! þ }
    End;

   { þ Freeing up materials þ }
   If MaterialNum>0 Then Begin
     For Counter:=0 To MaterialNum-1 Do Begin
       { þ Freeing up main material record þ }
       Dispose(Material[Counter]);
      End;
     { þ Freeing up main material pointer array þ }
     FreeMem(Material,MaterialNum*SizeOf(PMaterial));
    End;

   { þ Freeing up tracks þ }
   If TracksNum>0 Then Begin
     For Counter:=0 To TracksNum-1 Do Begin
       With Tracks[Counter]^ Do Begin
         { þ Freeing up position keys þ }
         If TrackPosKeys<>Nil Then Begin
           FreeMem(TrackPosKeys,TrackPosNum*SizeOf(TPosKey));
          End;
         { þ Freeing up rotation keys þ }
         If TrackRotKeys<>Nil Then Begin
           FreeMem(TrackRotKeys,TrackRotNum*SizeOf(TRotKey));
          End;
         { þ Freeing up scale keys þ }
         If TrackScaleKeys<>Nil Then Begin
           FreeMem(TrackScaleKeys,TrackScaleNum*SizeOf(TScaleKey));
          End;
         { þ Freeing up morph keys þ }
         If TrackMorphKeys<>Nil Then Begin
           FreeMem(TrackMorphKeys,TrackMorphNum*SizeOf(TMorphKey));
          End;
         { þ Freeing up FOV keys þ }
         If TrackFOVKeys<>Nil Then Begin
           FreeMem(TrackFOVKeys,TrackFOVNum*SizeOf(TFOVKey));
          End;
         { þ Freeing up roll keys þ }
         If TrackRollKeys<>Nil Then Begin
           FreeMem(TrackRollKeys,TrackRollNum*SizeOf(TRollKey));
          End;
        End;
       { þ Freeing up main track record þ }
       Dispose(Tracks[Counter]);
      End;
     { þ Freeing up main track pointer array þ }
     FreeMem(Tracks,TracksNum*SizeOf(P3DTrack));
    End;

  End;

 { þ Freeing up main 3DS array þ }
 Dispose(Mesh3D);

 Mesh3D:=Nil;
 I3D_Free3DS:=True;
End;

{$IFDEF _I3D_INCLUDE_}
 { þ Loads a .3DS file from the specified datafile. þ }
 Function I3D_IDSLoad3DS(Var Mesh3D : P3DMesh; DFHandle : IDS_PDataFile; FileName : String) : Boolean;
 Var File3DS    : IDS_PFile;
     TreeDepth  : DWord;
     CPosition  : DWord;
 Begin
  I3D_IDSLoad3DS:=False;

  If I3D_Load3DSErrorCode<>0 Then Begin
    { þ ERROR - Loader subsystem is in error! þ }
    Exit;
   End;

  { þ Checking if filename is valid. þ }
  If Filename='' Then Begin
    { þ ERROR - Filename is an empty string þ }
    I3D_Load3DSErrorCode:=I3DL_ErrorFileName;
    Exit;
   End;

  { þ Opening and reading file þ }
  File3DS:=IDS_OpenFile(DFHandle,FileName);
  If File3DS=Nil Then Begin
    { þ ERROR - Unable to open file þ }
    I3D_Load3DSErrorCode:=I3DL_ErrorFileOpen;
    Exit;
   End;

  { þ Assigning internal variables þ }
  With File3DS^ Do Begin
    Current3DSSize:=FSize;
    Current3DS:=FData;
   End;

  {$IFDEF _I3D_3DSL_DEBUGMODE_}
   DebugInit(FileName);
  {$ENDIF}

  { þ Loading .3DS file into the specified mesh structure þ }
  MemoryAllocated:=0;
  TreeDepth:=0; CPosition:=Current3DSSize-1;
  New(Loaded3DS); FillChar(Loaded3DS^,SizeOf(Loaded3DS^),#0);
  Inc(MemoryAllocated,SizeOf(Loaded3DS^));
  Current3DSPos:=0;

  I3DSL_ChunkReader(TreeDepth,CPosition);

  CollectLinkedData;
  PreLoadValues;

  Loaded3DS^.MemoryUsed:=MemoryAllocated;

  {$IFDEF _I3D_3DSL_DEBUGMODE_}
   DebugDone;
  {$ENDIF}

  { þ Closing file þ }
  IDS_CloseFile(File3DS);

  Mesh3D:=Loaded3DS;
  I3D_IDSLoad3DS:=(I3D_Load3DSErrorCode=0);
 End;
{$ENDIF}

{ þ Loads a .3DS file from the specified filename. þ }
Function I3D_Load3DS(Var Mesh3D : P3DMesh; FileName : String) : Boolean;
Var File3DS    : File;
    TreeDepth  : DWord;
    CPosition  : DWord;
Begin
 I3D_Load3DS:=False;

 If I3D_Load3DSErrorCode<>0 Then Begin
   { þ ERROR - Loader subsystem is in error! þ }
   Exit;
  End;

 { þ Checking if filename is valid. þ }
 If Filename='' Then Begin
   { þ ERROR - Filename is an empty string þ }
   I3D_Load3DSErrorCode:=I3DL_ErrorFileName;
   Exit;
  End;

 { þ Opening file þ }
 Assign(File3DS,FileName);
 FileMode:=0;
 Reset(File3DS,1);
 If IOResult<>0 Then Begin
   { þ ERROR - Unable to open file þ }
   I3D_Load3DSErrorCode:=I3DL_ErrorFileOpen;
   Exit;
  End;

 { þ Allocating load buffer þ }
 Current3DSSize:=FileSize(File3DS);
 GetMem(Current3DS,Current3DSSize);
 If Current3DS=Nil Then Begin
   { þ ERROR - Not enough memory þ }
   I3D_Load3DSErrorCode:=I3DL_ErrorMemAlloc;
   Exit;
  End;

 { þ Reading file to load buffer þ }
 BlockRead(File3DS,Current3DS^,Current3DSSize);
 If IOResult<>0 Then Begin
   { þ ERROR - File read error þ }
   I3D_Load3DSErrorCode:=I3DL_ErrorFileIO;
   Exit;
  End;

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  DebugInit(FileName);
 {$ENDIF}

 { þ Loading .3DS file into the specified mesh structure þ }
 MemoryAllocated:=0;
 TreeDepth:=0; CPosition:=Current3DSSize-1;
 New(Loaded3DS); FillChar(Loaded3DS^,SizeOf(Loaded3DS^),#0);
 Inc(MemoryAllocated,SizeOf(Loaded3DS^));
 Current3DSPos:=0;

 I3DSL_ChunkReader(TreeDepth,CPosition);

 CollectLinkedData;
 PreLoadValues;

 Loaded3DS^.MemoryUsed:=MemoryAllocated;

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  DebugDone;
 {$ENDIF}

 { þ Freeing up load buffer þ }
 FreeMem(Current3DS,Current3DSSize);

 { þ Closing file þ }
 Close(File3DS);

 Mesh3D:=Loaded3DS;
 I3D_Load3DS:=(I3D_Load3DSErrorCode=0);
End;

Begin
 I3D_Load3DSErrorCode:=0;
End.
{ þ I3D_3DSL.PAS - (C) 1998-2001 Charlie/Inquisition and others þ }

{ þ Changelog : þ }
{ þ 0.4.7 - Released to the public on the internet                        þ }
{ þ         [03.july.2001 - Charlie]                                      þ }
{ þ 0.4.6 - Added I3D_IDSLoad3DS procedure to allow loading from IDS      þ }
{ þ         datafiles. [05.feb.2001 - Charlie]                            þ }
{ þ 0.4.5 - Minor changes (re-enabled memory deallocation of light        þ }
{ þ         structures, added P3DVector type for stand-alone version,     þ }
{ þ         little bug in logfile fixed) [15.10.2000 - mrc!]              þ }
{ þ 0.4.4 - Huge amount of memory handling reorganizations, and bugfixes. þ }
{ þ       - Aaaaaaarghhh... It was not possible to load more 3DS file     þ }
{ þ         with the loader... Fixed.                                     þ }
{ þ       - I3D_Free3DS was buggy with Lights. Fixed.                     þ }
{ þ       - Some other modifications                                      þ }
{ þ         [30.august.2000 - Charlie]                                    þ }
{ þ 0.4.3 - I3D_Free3DS() function implemented.                           þ }
{ þ       - Some additional comments.                                     þ }
{ þ       - Spot and omnilight track support. Not well tested, so may     þ }
{ þ         contain bugs. Anyway it seems to work. Light objects still    þ }
{ þ         not supported.                                                þ }
{ þ       - Bugfix for wrong track numbers.                               þ }
{ þ       - Modifications for mrc!'s 3D engine. (_I3D_INCLUDE_ symbol)    þ }
{ þ       - Merged with some other modifications from mrc!.               þ }
{ þ         [07.august.2000 - Charlie]                                    þ }
{ þ 0.4.2 - Added BoundingBox array to T3DObject structure                þ }
{ þ       - TVector was renamed to T3DVector                              þ }
{ þ         [20.july.2000 - mrc!]                                         þ }
{ þ 0.4.1 - Modified to match mrc!'s recommendations.                     þ }
{ þ       - XYZ coordinates moved into TVector type in all records.       þ }
{ þ       - Camera target and position moved into TVector type.           þ }
{ þ       - TCamPosition type removed.                                    þ }
{ þ       - WARNING! Due to the modifications described above, the        þ }
{ þ         internal data structure of this version no longer compatible  þ }
{ þ         with previous versions! You'll need to modify your programs   þ }
{ þ         to match the new structure. Sorry.                            þ }
{ þ       - Better error detection and handling.                          þ }
{ þ       - Still no light support. Reason: lack of time. Sorry. :(       þ }
{ þ         [30.june.2000 - Charlie]                                      þ }
{ þ 0.4.0 - Complettely rewritten from scratch. Uses recursive loading.   þ }
{ þ         All features of previous versions supported, but the API is   þ }
{ þ         a little bit modified. You'll need to syncronize your sources þ }
{ þ         to this new version. Sorry.                                   þ }
{ þ       - As this new version is complettely rewritten, many bugs of    þ }
{ þ         the old loader is fixed. In some cases the old version didn't þ }
{ þ         find some chunks. (Mainly with 3DS Max exported files.)       þ }
{ þ         Also the translation matrix reading was buggy, in version     þ }
{ þ         0.3.0. These problems has been eliminated. But also it's      þ }
{ þ         possible that this new version also has bugs, since it's      þ }
{ þ         not very well tested. We'll see.                              þ }
{ þ       - Object visibility flag added to the T3DObject record.         þ }
{ þ       - Track hierarchy value added to the T3DTrack record.           þ }
{ þ       - Spline flags now stored in the track keys.                    þ }
{ þ       - MemoryUsed value added to the T3DMesh record.                 þ }
{ þ       - I3D_Get3DSError and I3D_Get3DSErrorString procedure added.    þ }
{ þ       - I3D_Gen3DSError procedure removed.                            þ }
{ þ       - Note: Lights still not completely supported in this release   þ }
{ þ               Do _NOT_ use lights. Wait for the next release, which   þ }
{ þ               will be released soon. Okay, you've been warned...      þ }
{ þ         [04.may.2000 - Charlie]                                       þ }
{ þ 0.3.1 - Initial Light support, omnilights (never finished version)    þ }
{ þ         [22.apr.2000 - Charlie]                                       þ }
{ þ 0.3.0 - A huge bug fixed, if specified .3DS didn't exist, the loader  þ }
{ þ         crashed. Sorry. It happenned only with debug mode enabled.    þ }
{ þ         (It was my most stupid fault by far, since i'm coding...)     þ }
{ þ       - Another huge bug fixed, stupid Autodesk store the coordinates þ }
{ þ         in XZY order. We loaded it in XYZ order... Now it is fixed.   þ }
{ þ       - Texture Wrapping Flags added to face record                   þ }
{ þ       - Some cosmetic changes (mrc!!!!! What the hell was that!? :)   þ }
{ þ         [10.feb.2000 - Charlie]                                       þ }
{ þ 0.2.5 - If Camera PosTrack or TargTrack not exist then default 65535. þ }
{ þ         [06.nov.1999 - Tcc]                                           þ }
{ þ 0.2.4 - I3D_Gen3DSError procedure added                               þ }
{ þ         [15.oct.1999 - mrc!]                                          þ }
{ þ 0.2.3 - The loader crashed without debug mode enabled. Fixed.         þ }
{ þ         [28.sep.1999 - Charlie]                                       þ }
{ þ 0.2.2 - Camera with Camera Track pairing bug fixed                    þ }
{ þ       - Chunk Type "Object Hide Track" ($0B029) added. (ID only)      þ }
{ þ         [03.aug.1999 - Charlie]                                       þ }
{ þ 0.2.1 - Some array limit checking code added to eliminate various     þ }
{ þ         general protection faults                                     þ }
{ þ       - Chunk Type "Object Morph Track" ($0B026) added.               þ }
{ þ         (INQ-Members' Party at Innocent/INQ's place)                  þ }
{ þ         [01.aug.1999 - Charlie]                                       þ }
{ þ 0.2.0 - First public version                                          þ }
{ þ         [30.jul.1999 - Charlie]                                       þ }
{ þ 0.1.x - Not public                                                    þ }
