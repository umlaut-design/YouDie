{��������������������������������������������������������������������������Ŀ}
{� � ISS_VAR .PAS - Loader for Autodesk 3D Studio R4 type .3DS files        �}
{�                  Work started     : 1998.12.04.                          �}
{�                  Last modification: 2001.07.03.                          �}
{�             OS - Platform Independent                                    �}
{�                                                                          �}
{�            ISS - Inquisition 3D Engine for Free Pascal                   �}
{�                  Code by Marton Ekler (a.k.a. mrc/iNQ) and               �}
{�                          Karoly Balogh (a.k.a. Charlie/iNQ)              �}
{�                  Copyright (C) 1998-2001 Inquisition                     �}
{����������������������������������������������������������������������������}

{ � THIS RELEASE SEEMS TO BE STABLE. ANYWAY, STILL HANDLE WITH CARE. � }
{ � USE AT YOUR OWN RISK. � }

{$MODE FPC}     { � Compiler mode to FPC � }
{$IOCHECKS OFF} { � Switching off runtime IO error handling. � }

{$HINTS OFF}    { � Disabling hints - Enable this, if you modify the loader! � }
{$NOTES OFF}    { � Disabling notes - Enable this, if you modify the loader! � }

{ � Enable this directive, if you want to generate logfile. It's useful � }
{ � to dig up bugs and incompatibilities. Check out the debugging section � }
{ � in the implementation part for more info. � }
{ � IMPORTANT! THE DEBUG LOG GENERATOR CODE IS _NOT_ FAIL SAFE! � }
{ � DO _NOT_ ENABLE DEBUG LOG GENERATION IN OFFICIALLY RELEASED PRODUCTS! � }
{ � OKAY, YOU'VE BEEN WARNED. � }
{ DEFINE _I3D_3DSL_DEBUGMODE_}

{ � The symbol definied below makes possible to include the loader into � }
{ � our 3D engine. Do NOT enable if you want to use the loader without it. � }
{ � (Also enables IDS integration.) � }
{ DEFINE _I3D_INCLUDE_}

Unit I3D_3DSL;

Interface

{$IFDEF _I3D_INCLUDE_}
 Uses I3D_Vect,I3D_Quat,IDS_Load;
{$ENDIF}

Const I3D_LoaderVersionStr = '0.4.7';
      I3D_LoaderVersion    = $000407;

Type TSplineFlags = Record { � Spline flags belong to every key � }
       Flags      : Word;  { � These flags show if a value changed � }
       Tension    : Single;
       Continuity : Single;
       Bias       : Single;
       EaseTo     : Single;
       EaseFrom   : Single;
      End;

     {$IFNDEF _I3D_INCLUDE_}
      P3DVector = ^T3DVector;
      T3DVector = Record { � A coordinate in the 3D space � }
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
     TPosKey = Record   { � Track Position Coordinates � }
       Frame  : Word;
       Vector : T3DVector;
       Spline : TSplineFlags;
      End;

     PRotKey = ^TRotKey;
     TRotKey = Record { � Track Rotation Value � }
       Frame      : Word;
       Angle      : Single;
       Vector     : T3DVector;
       Spline     : TSplineFlags;
       Quaternion : TQuaternion;
      End;

     PScaleKey = ^TScaleKey;
     TScaleKey = Record { � Track Scale Value � }
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
     TFOVKey = Record   { � Track FOV Value � }
       Frame  : Word;
       FOV    : Single;
       Spline : TSplineFlags;
      End;

     PRollKey = ^TRollKey;
     TRollKey = Record  { � Track Roll Value � }
       Frame  : Word;
       Roll   : Single;
       Spline : TSplineFlags;
      End;

     PObjPivot = ^TObjPivot;
     TObjPivot = Record { � Object Pivot Point � }
       Vector  : T3DVector;
      End;

     P3DVertex = ^T3DVertex;
     T3DVertex = Record { � Vertex Data � }
       Vector  : T3DVector;
       U       : Single; { � Texture Coordinates � }
       V       : Single;
      End;

     P3DFace = ^T3DFace;
     T3DFace = Record { � Triangle Face Data � }
       Vertex1 : Word;  { � Number Of Vertexes In Vertex List � }
       Vertex2 : Word;
       Vertex3 : Word;
       ABVis   : Boolean; { � Edge Visibility Switches � }
       BCVis   : Boolean;
       ACVis   : Boolean;
       UWrap   : Boolean; { � Texture Tile Switches � }
       VWrap   : Boolean;
       MatName : String[32]; { � Material Name Assigned To This Face � }
       MatNum  : Word; { � Material Number Assigned To This Face � }
      End;

     P3DObject  = ^T3DObject;
     T3DObject  = Record { � 3D Object Data � }
       PNextObj    : P3DObject;  { � Pointer to the next Object � }
       ObjName     : String[32]; { � Name Of This Object � }
       VertexNum   : Word;       { � Number Of Vertexes � }
       Vertex      : P3DVertex;  { � Pointer To Vertex List � }
       FaceNum     : Word;       { � Number Of Faces � }
       Face        : P3DFace;    { � Pointer To Faces List � }
       Rot_Mat     : Array[0..8] Of Single; { � Object Rotation Matrix � }
       Trans_Mat   : Array[0..2] Of Single; { � Object Translation Matrix � }
       Static      : Boolean;    { � True If Static Object (Every KeysNum=1) � }
       Visible     : Boolean;    { � Object is set as visible � }
       TrackNum    : Word;       { � Track Number Belongs To This Object � }
       BoundingBox : Array[0..7] Of T3DVector; { � Object Bounding Box Vertices � }
       FaceNormals : P3DVector;  { � Face normals array � }
      End;
     PP3DObject = ^P3DObject;

     P3DCamera  = ^T3DCamera;
     T3DCamera  = Record { � Camera Data � }
       PNextCam  : P3DCamera;    { � Pointer to the next Camera � }
       CamName   : String[32];   { � Name Of This Camera � }
       Position  : T3DVector;      { � Camera Eye Position � }
       Target    : T3DVector;      { � Camera Viewpoint Target � }
       Roll      : Single;
       FOV       : Single;
       PosTrack  : Word;         { � Track Number Belongs To This Camera Position � }
       TargTrack : Word;         { � Track Number Belongs To This Camera Target   � }
      End;
     PP3DCamera = ^P3DCamera;

     TRGBByteColor = Record { � RGB Byte Color Data � }
       R       : Byte;
       G       : Byte;
       B       : Byte;
      End;

     TRGBFloatColor = Record { � RGB Float Color Data � }
       R       : Single;
       G       : Single;
       B       : Single;
      End;

     PLight = ^TLight;
     TLight = Record { � Lightsource Data � }
       PNextLight : PLight;     { � Pointer to Next Light � }
       LightName  : String[32]; { � Light Name � }
      End;
     PPLight = ^PLight;

     PMaterial  = ^TMaterial;
     TMaterial  = Record { � Material Data � }
       PNextMat   : PMaterial;  { � Pointer to Next Material � }
       Name       : String[32]; { � Material Name � }
       Ambient    : TRGBByteColor; { � Material Ambient Color � }
       FileName   : String[12]; { � Material Filename � }
       Visibility : Word;       { � Material Visibility � }
       MapX       : Word;       { � Material Map X Size � }
       MapY       : Word;       { � Material Map Y Size � }
       MapData    : Pointer;    { � Pointer to Material RAW Image Data � }
      End;
     PPMaterial = ^PMaterial;

     P3DTrack  = ^T3DTrack;
     T3DTrack  = Record { � Animation Track Data � }
       Static         : Boolean;    { � Indicates if track is static � }
       PNextTrack     : P3DTrack;   { � Pointer to Next Track � }
       TrackNumber    : Word;       { � Number Of The Track � }
       TrackParent    : Word;       { � Parent Number Of The Track � }
       TrackType      : Byte;       { � Track Type � }
       TrackName      : String[32]; { � Name Of The Track (Same as the Object Name) � }
       TrackPivot     : TObjPivot;  { � Pivot Point Of The Object � }
       TrackPosNum    : Word;       { � Number Of Track Position Keys � }
       TrackPosKeys   : PPosKey;    { � Pointer To Position Keys (Nil If No Position Track) � }
       TrackRotNum    : Word;       { � Number Of Track Rotation Keys (Object Tracks Only) � }
       TrackRotKeys   : PRotKey;    { � Pointer To Rotation Keys (Nil If No Rotation Track) � }
       TrackScaleNum  : Word;       { � Number Of Scale Keys (Object Tracks Only) � }
       TrackScaleKeys : PScaleKey;  { � Pointer To Scale Keys (Nil If No Scale Track) � }
       TrackMorphNum  : Word;       { � Number Of Morph Keys (Object Tracks Only) � }
       TrackMorphKeys : PMorphKey;  { � Pointer To Morph Keys (Nil If No Morph Track) � }
       TrackFOVNum    : Word;       { � Number Of Track FOV Keys (Camera Tracks Only) � }
       TrackFOVKeys   : PFOVKey;    { � Pointer To FOV Keys (Nil If No FOV Track) � }
       TrackRollNum   : Word;       { � Number Of Roll Keys (Camera Tracks Only) � }
       TrackRollKeys  : PRollKey;   { � Pointer To Roll Keys (Nil If No Roll Track) � }
      End;
     PP3DTrack = ^P3DTrack;

     P3DMesh = ^T3DMesh;
     T3DMesh = Record  { � The Whole 3D Mesh Data � }

       { � ADDITIONAL INFO � }

       MemoryUsed  : DWord; { � Gives back the memory size used by the Mesh-tree � }

       { � MESH DATA (3D EDITOR) � }

       ObjectNum   : Word; { � Number Of Objects In Mesh � }
       Object3D    : PP3DObject; { � Array Of Pointers To Object Data � }
       Object3DL   : P3DObject;  { � Pointer To The First Element Of Object List � }
       CameraNum   : Word; { � Number Of Cameras In Mesh � }
       Camera3D    : PP3DCamera; { � Array Of Pointers To Camera Data � }
       Camera3DL   : P3DCamera;  { � Pointer To The First Element Of Camera List � }
       LightNum    : Word; { � Number Of Lightsources In Mesh � }
       Light       : PPLight;    { � Array Of Pointers To Light Data � }
       LightL      : PLight;     { � Pointer To The First Element Of Lightsource List � }
       MaterialNum : Word; { � Number Of Materials In Mesh � }
       Material    : PPMaterial; { � Array Of Pointers To Material Data � }
       MaterialL   : PMaterial;  { � Pointer To The First Element Of Material List � }

       { � ANIMATION DATA (KEYFRAMER) � }

       FramesNum   : Word; { � Number Of Frames In The Animation � }
       FirstFrame  : Word; { � First Keyframe In The Animation � }
       LastFrame   : Word; { � Last Keyframe In The Animation � }
       TracksNum   : Word; { � Number Of Stored Tracks � }
       Tracks      : PP3DTrack; { � Array Of Pointers To The Track Data � }
       TracksL     : P3DTrack;  { � Pointer To The First Element Of Track List � }
      End;

Const I3DL_ErrorFileName = 1; { � Invalid filename � }
      I3DL_ErrorFileOpen = 2; { � File open failed � }
      I3DL_ErrorFileIO   = 3; { � File I/O operation error � }
      I3DL_ErrorMemAlloc = 4; { � Memory allocation failed � }
      I3DL_ErrorNo3DS    = 5; { � Corrupted 3DS file, or not a 3DS file! � }
      I3DL_Error3DSRead  = 6; { � Error in the 3DS file � }
      I3DL_ErrorFree3DS  = 7; { � Free 3DS function failed � }

Var I3D_Load3DSErrorCode : LongInt; { � Contains the last error code � }

Function I3D_Get3DSError : DWord;
Function I3D_Get3DSErrorString(ErrorCode : DWord) : String;

Function I3D_Load3DS(Var Mesh3D : P3DMesh; FileName : String) : Boolean;
Function I3D_Free3DS(Var Mesh3D : P3DMesh) : Boolean;

{$IFDEF _I3D_INCLUDE_}
 Function I3D_IDSLoad3DS(Var Mesh3D : P3DMesh; DFHandle : IDS_PDataFile; FileName : String) : Boolean;
{$ENDIF}

Implementation

{ � >>> L O C A L  D A T A  A R E A <<< � }

{$IFDEF _I3D_3DSL_DEBUGMODE_}
 Uses CRT;
{$ENDIF}

Type TChunkData = Record { � Store chunk data, used by FindChunk � }
       CValid  : Boolean;   { � True if chunk valid. � }
       CDescr  : String;    { � Chunk description � }
       CReader : Procedure(TreeDepth : DWord; CPosition : DWord); { � Chunk reader procedure � }
      End;

Const { � ID Chunk � }
      Main3DS = $04D4D;

      { � Main Chunks � }
      Edit3DS = $03D3D; { � This is the start of the Editor config � }
          { � Sub Defines of Edit3DS � }
          Edit_MATERIAL = $0AFFF;
               Mat_NAME    = $0A000;
               Mat_AMBIENT = $0A010;
               Mat_TEXTURE = $0A200;
                   Tex_MAPFILE = $0A300;
          Edit_BACKGR   = $01200;
          Edit_AMBIENT  = $02100;
          Edit_OBJECT   = $04000;
               { � Sub Defines of Edit_OBJECT � }
               Obj_OBJMESH = $04100;
                   { � Sub Defines of Obj_TRIMESH � }
                   Tri_VERTEXL  = $04110; { � Vertex List � }
                   Tri_FACELIST = $04120; { � Face List � }
                       Tri_FACEMAT = $04130; { � Faces mapping list � }
                   Tri_MAPPING  = $04140; { � Mapping coordinates for each vertex � }
                   Tri_SMOOTH   = $04150;
                   Tri_MATRIX   = $04160;
                   Tri_VISIBLE  = $04165;
               Obj_LIGHT  = $04600;
               Obj_CAMERA = $04700;

      Keyf3DS = $0B000; { � This is the start of the Keyframer config � }
          { � Sub Defines Of Keyf3DS � }
          Keyf_FRAMES    = $0B008; { � Frames of the Animation � }
          Keyf_OBJTRACK  = $0B002; { � Animation Track Info    � }
               Track_OBJNAME   = $0B010;
               Track_OBJNUMBER = $0B030;
               Track_OBJPIVOT  = $0B013;
               Track_OBJPOS    = $0B020; { � Animation Position Keys � }
               Track_OBJROTATE = $0B021;
               Track_OBJSCALE  = $0B022;
               Track_OBJMORPH  = $0B026;
               Track_OBJHIDE   = $0B029;
          Keyf_CAMTRACK     = $0B003;    { � Camera Track � }
          Keyf_CAMTARGTRACK = $0B004;
               Track_CAMFOV  = $0B023;
               Track_CAMROLL = $0B024;
          Keyf_LIGHTTRACK     = $0B005;  { � Spotlight(?) Track � }
          Keyf_LIGHTTARGTRACK = $0B006;  { � Spotlight(?) Target Track � }
          Keyf_OMNILIGHTTRACK = $0B007;  { � Omnilight Track � }

      { � Additional Chunks � }
      Chunk_RGBF = $00010;
      Chunk_RGBB = $00011;
      Chunk_WORD = $00030;

Const ObjectTrack          =  1; { � Track type flags � }
      CameraTrack          =  2;
      CameraTargetTrack    =  4;
      SpotLightTrack       =  8;
      SpotLightTargetTrack = 16;
      OmniLightTrack       = 32;

Var Current3DS     : Pointer; { � Pointer to current 3DS to load � }
    Current3DSPos  : DWord;   { � Current memory position to load from � }
    Current3DSSize : DWord;   { � Size of the memory area to load � }
    Loaded3DS      : P3DMesh;

    GlobalBufStr   : String;         { � Global string buffer. � }
    GlobalBufRGBB  : TRGBByteColor;  { � Global RGBB color buffer. � }
    GlobalBufRGBF  : TRGBFloatColor; { � Global RGBF color buffer. � }
    GlobalBufWord  : Word;           { � Global WORD value buffer. � }

    CurrentObject    : P3DObject;
    CurrentCamera    : P3DCamera;
    CurrentLight     : PLight;
    CurrentMaterial  : PMaterial;
    CurrentTrack     : P3DTrack;
    CurrentTrackType : DWord;

    MemoryAllocated   : DWord;

{ � >>> D E B U G  F U N C T I O N S <<< � }

{$IFDEF _I3D_3DSL_DEBUGMODE_}
Const DebugFileName = '3dsload.log'; { � Debug log filename � }
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
  WriteLn(Output,#13,#10,' � Inquisition 3D Engine for Free Pascal - 3DS LOADER DEBUG LOG FILE');
  WriteLn(Output,' � Loader code by Karoly Balogh (a.k.a. Charlie/Inquisition) and others');
  WriteLn(Output,' � Loader version : ',I3D_LoaderVersionStr);
  WriteLn(Output,' � .3DS Filename  : ',FileToDebug,#13,#10);
 End;

 Procedure DebugDone;
 Begin
  With Loaded3DS^ Do Begin
    WriteLn(Output,#13,#10,' � Memory allocated : ',MemoryAllocated,' bytes.');
    WriteLn(Output,#13,#10,' � Number of Objects loaded   : ',ObjectNum);
    WriteLn(Output,'   - Number of Vertices loaded  : ',VertexSum);
    WriteLn(Output,'   - Number of Faces loaded     : ',FaceSum);
    WriteLn(Output,' � Number of Cameras loaded   : ',CameraNum);
    WriteLn(Output,' � Number of Lights loaded    : ',LightNum);
    WriteLn(Output,' � Number of Materials loaded : ',MaterialNum);
    WriteLn(Output,' � Number of Tracks loaded    : ',TracksNum);
    If I3D_Load3DSErrorCode=0 Then WriteLn(Output,#13,#10,' � Everything went OK.')
                              Else Begin
                                    WriteLn(Output,#13,#10,' � ERROR CODE : ',I3D_Load3DSErrorCode);
                                    WriteLn(Output,' � ERROR MSG  : ',I3D_Get3DSErrorString(I3D_Load3DSErrorCode));
                                   End;
   End;
  Close(Output);
  Assign(Output,'');
  AssignCrt(Output);
  Rewrite(Output);
 End;
{$ENDIF}

{ � >>> I N T E R N A L  F U N C T I O N S <<< � }

{ � >>> FORWARD DECLARATIONS <<< � }
Procedure I3DSL_ChunkReader(TreeDepth : DWord; CPosition : DWord); Forward;

{ � >>> ADDITIONAL FUNCTIONS <<< � }

{ � Reads a byte from the 3DS buffer � }
Function ReadByte : Byte;
Begin
 ReadByte:=Byte((Current3DS+Current3DSPos)^);
 Inc(Current3DSPos);
End;

{ � Reads a word from the 3DS buffer � }
Function ReadWord : Word;
Begin
 ReadWord:=Word((Current3DS+Current3DSPos)^);
 Inc(Current3DSPos,2);
End;

{ � Reads a doubleword from the 3DS buffer � }
Function ReadDWord : DWord;
Begin
 ReadDWord:=DWord((Current3DS+Current3DSPos)^);
 Inc(Current3DSPos,4);
End;

{ � Reads a null-terminated string from, the 3DS buffer � }
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


{ � >>> CHUNK SPECIFIC READERS <<< � }

{ � Reads an RGB byte color chunk � }
Procedure Chunk_RGBBColor(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read RGB values, and store into the global RGBB buffer, so � }
 { � the surrounding chunk what needs this data can fetch it. � }
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

{ � Reads an RGB float color chunk � }
Procedure Chunk_RGBFColor(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read RGB values, and store into the global RGBF buffer, so � }
 { � the surrounding chunk what needs this data can fetch it. � }
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

{ � Reads a WORD value chunk � }
Procedure Chunk_WORDValue(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read the WORD value, and store into the global WORD buffer, so � }
 { � the surrounding chunk what needs this data can fetch it. � }
 GlobalBufWord:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Value: ',GlobalBufWord);
 {$ENDIF}
End;

{ � Reads a material block chunk � }
Procedure Chunk_MaterialBlock(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Init memory area to store this material data � }
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

 { � Read remaining chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ � Reads a material name chunk � }
Procedure Chunk_MaterialName(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Material name � }
 With CurrentMaterial^ Do Begin
   Name:=ReadANSIString;

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn('':TreeDepth,' - Material name: ',Name);
   {$ENDIF}
  End;
End;

{ � Reads a material ambient color chunk � }
Procedure Chunk_MaterialAmbient(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read internal chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);

 { � Now store the global color values into the material data. � }
 { � If the .3DS file isn't buggy there was an RGBB chunk... � }
 CurrentMaterial^.Ambient:=GlobalBufRGBB;
End;

{ � Reads a material texture data chunk � }
Procedure Chunk_MaterialTexture(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read internal chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);

 { � Now store the global word value into the material data. � }
 { � If the .3DS file isn't buggy, there was a WORD value chunk... � }
 CurrentMaterial^.Visibility:=GlobalBufWord;
End;

{ � Reads a texture map file name � }
Procedure Chunk_TexMapFileName(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read the filename � }
 With CurrentMaterial^ Do Begin
   FileName:=ReadANSIString;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Filename: ',FileName);
   {$ENDIF}
  End;
End;

{ � Reads an object block chunk (contains camera, light or object data � }
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

{ � Reads an object mesh chunk � }
Procedure Chunk_ObjectMesh(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Init memory area to store this object data � }
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

 { � Read remaining chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ � Reads a vertex list chunk � }
Procedure Chunk_VertexList(TreeDepth : DWord; CPosition : DWord);
Var BufVertexNum : Word;
    Counter      : DWord;
Begin
 BufVertexNum:=ReadWord; { � Reads number of vertexes in this chunk � }

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  Inc(VertexSum,BufVertexNum);
  WriteLn(Output,'':TreeDepth,' - Found ',BufVertexNum,' vertexes.');
 {$ENDIF}

 With CurrentObject^ Do Begin
   VertexNum:=BufVertexNum;
   { � Allocating memory for the vertex list � }
   GetMem(Vertex,SizeOf(T3DVertex)*BufVertexNum);
   FillChar(Vertex^,SizeOf(T3DVertex)*BufVertexNum,#0);
   Inc(MemoryAllocated,SizeOf(T3DVertex)*BufVertexNum);

   { � Vertex data. XZY ORDER! � }
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

{ � Reads a face list chunk � }
Procedure Chunk_FaceList(TreeDepth : DWord; CPosition : DWord);
Var BufFaceNum : Word;
    Counter    : DWord;
    BufValue   : Word;
Begin
 BufFaceNum:=ReadWord; { � Reads number of faces in this chunk � }

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  Inc(FaceSum,BufFaceNum);
  WriteLn(Output,'':TreeDepth,' - Found ',BufFaceNum,' faces.');
 {$ENDIF}

 With CurrentObject^ Do Begin
   FaceNum:=BufFaceNum;
   { � Allocating memory for the face list � }
   GetMem(Face,SizeOf(T3DFace)*BufFaceNum);
   FillChar(Face^,SizeOf(T3DFace)*BufFaceNum,#0);
   Inc(MemoryAllocated,SizeOf(T3DFace)*BufFaceNum);

   { � Face data � }
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

 { � Read remaining chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ � Reads a face mapping list chunk �  }
Procedure Chunk_FaceMappingList(TreeDepth : DWord; CPosition : DWord);
Var BufString  : String;
    BufFaceNum : Word;
    BufMapFace : Word;
    Counter    : DWord;
Begin
 { � Read material name for the faces following � }
 BufString:=ReadANSIString;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Material name for the faces following: ',BufString);
 {$ENDIF}

 { � Read number of face mapping data � }
 BufFaceNum:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of faces with this material: ',BufFaceNum);
 {$ENDIF}

 { � Read face mapping data � }
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

{ � Reads a mapping list chunk � }
Procedure Chunk_MappingList(TreeDepth : DWord; CPosition : DWord);
Var BufMappingNum : Word;
    Counter       : DWord;
Begin
 BufMappingNum:=ReadWord; { � Reads number of mapping coords. in this chunk � }

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

{ � Reads an object transformation matrix chunk � }
Procedure Chunk_ObjMatrix(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentObject^ Do Begin

   { � Rotation matrix data (BOTH ROWS AND COLUMNS ARE IN XZY ORDER!) � }
   DWord(Rot_Mat[0]):=ReadDWord; DWord(Rot_Mat[2]):=ReadDWord; DWord(Rot_Mat[1]):=ReadDWord;
   DWord(Rot_Mat[6]):=ReadDWord; DWord(Rot_Mat[8]):=ReadDWord; DWord(Rot_Mat[7]):=ReadDWord;
   DWord(Rot_Mat[3]):=ReadDWord; DWord(Rot_Mat[5]):=ReadDWord; DWord(Rot_Mat[4]):=ReadDWord;

   { � Translation matrix data (XYZ ORDER!) � }
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

{ � Reads an object visibility chunk � }
Procedure Chunk_ObjVisibility(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentObject^ Do Begin

   { � Read visibility data � }
   Visible:=(ReadByte=0);

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    Write(Output,'':TreeDepth,' - Object is ');
    If Visible Then WriteLn('visible.') Else WriteLn('invisible.');
   {$ENDIF}

  End;
End;

{ � Reads a light object chunk � }
Procedure Chunk_Light(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Init memory area to store this light data � }
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

{ � Reads a camera object chunk � }
Procedure Chunk_Camera(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Init memory area to store this camera data � }
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

 { � Moving camera data � }
 With CurrentCamera^ Do Begin
   With Position Do Begin { � Camera position data. XZY ORDER! � }
     DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
    End;
   With Target Do Begin { � Camera target data. XZY ORDER! � }
     DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
    End;
   DWord(Roll):=ReadDWord; { � Camera roll value � }
   DWord(FOV):=ReadDWord; { � Camera FOV value � }

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    With Position Do
      WriteLn(Output,'':TreeDepth,' - Camera position: X:',X:0:3,' Y:',Y:0:3,' Z:',Z:0:3);
    With Target Do
      WriteLn(Output,'':TreeDepth,' - Camera target:   X:',X:0:3,' Y:',Y:0:3,' Z:',Z:0:3);
    WriteLn(Output,'':TreeDepth,' - Camera roll: ',Roll:0:3);
    WriteLn(Output,'':TreeDepth,' - Camera FOV : ',FOV:0:3);
   {$ENDIF}
  End;

 { � Read remaining chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ � Reads a frames info chunk � }
Procedure Chunk_FramesInfo(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Read frame info data � }
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

{ � Reads a track info chunk � }
{ � THIS IS NOT A CHUNK, BUT A PART OF SEVERAL CHUNKS! � }
Procedure Read_TrackInfo(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Init memory are to store this track data � }
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

 { � Assign track type � }
 CurrentTrack^.TrackType:=CurrentTrackType;

 { � Reading internal chunks � }
 I3DSL_ChunkReader(TreeDepth+2,CPosition);
End;

{ � Reads an object track info chunk � }
Procedure Chunk_ObjectTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Set track type � }
 CurrentTrackType:=ObjectTrack;
 { � Read remaining track info � }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ � Reads a track name chunk � }
Procedure Chunk_TrackName(TreeDepth : DWord; CPosition : DWord);
Var BufWord1, BufWord2 : Word;
Begin
 With CurrentTrack^ Do Begin
   { � Read track name � }
   TrackName:=ReadANSIString;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Track name: ',TrackName);
   {$ENDIF}

   { � Read track name data � }
   BufWord1:=ReadWord;
   BufWord2:=ReadWord;
   TrackParent:=ReadWord;

   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Track name data: Flags $0',Hex(BufWord1),
                                ', $0',Hex(BufWord2),', Parent ',TrackParent);
   {$ENDIF}
  End;
End;

{ � Reads a track number chunk � }
Procedure Chunk_TrackNumber(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentTrack^ Do Begin
   { � Read track number � }
   TrackNumber:=ReadWord;
   {$IFDEF _I3D_3DSL_DEBUGMODE_}
    WriteLn(Output,'':TreeDepth,' - Track number: ',TrackNumber);
    If TrackNumber<>Loaded3DS^.TracksNum-1 Then
      WriteLn(Output,'':TreeDepth,' - WARNING! TRACK CHUNK MISSED! TRUE TRACK NUMBER:',Loaded3DS^.TracksNum-1);
   {$ENDIF}
  End;
End;

{ � Reads a track pivot point chunk � }
Procedure Chunk_TrackPivotPoint(TreeDepth : DWord; CPosition : DWord);
Begin
 With CurrentTrack^ Do Begin
   { � Read track pivot point (XZY ORDER!) � }
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

{ � THIS IS NOT A CHUNK, BUT A PART OF SEVERAL CHUNKS! � }
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

{ �  THIS IS NOT A CHUNK, BUT A PART OF SEVERAL CHUNKS! � }
Procedure Read_UnknownValues(TreeDepth : DWord);
Var UnknownValue : Word;
    Counter      : DWord;
Begin
 { � Read some unknown values � }
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

{ � Reads a track position keys chunk � }
Procedure Chunk_TrackPositionKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufPosKeys   : Word;
    BufFlags     : Word;
Begin
 { � Read some unknown values � }
 Read_UnknownValues(TreeDepth);

 { � Read number of position keys � }
 BufPosKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of position keys: ',BufPosKeys);
 {$ENDIF}

 { � An unknown value again... � }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { � Init memory area to store the keys � }
 With CurrentTrack^ Do Begin
   TrackPosNum:=BufPosKeys;
   GetMem(TrackPosKeys,SizeOf(TPosKey)*BufPosKeys);
   FillChar(TrackPosKeys^,SizeOf(TPosKey)*BufPosKeys,#0);
   Inc(MemoryAllocated,SizeOf(TPosKey)*BufPosKeys);
  End;

 { � Read positionkeys � }
 For Counter:=0 To BufPosKeys-1 Do Begin
   With CurrentTrack^.TrackPosKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { � Reading position XZY ORDER! � }
     With Vector Do Begin
       DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth+2,' - X:',X:0:6,' Y:',Y:0:6,' Z:',Z:0:6);
       {$ENDIF}
      End;
    End;
  End;

End;

{ � Reads a track rotation keys chunk � }
Procedure Chunk_TrackRotationKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufRotKeys   : Word;
    BufFlags     : Word;
Begin
 { � Read some unknown values � }
 Read_UnknownValues(TreeDepth);

 { � Read number of position keys � }
 BufRotKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of rotation keys: ',BufRotKeys);
 {$ENDIF}

 { � An unknown value again... � }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { � Init memory area to store the keys � }
 With CurrentTrack^ Do Begin
   TrackRotNum:=BufRotKeys;
   GetMem(TrackRotKeys,SizeOf(TRotKey)*BufRotKeys);
   FillChar(TrackRotKeys^,SizeOf(TRotKey)*BufRotKeys,#0);
   Inc(MemoryAllocated,SizeOf(TRotKey)*BufRotKeys);
  End;

 { � Read positionkeys � }
 For Counter:=0 To BufRotKeys-1 Do Begin
   With CurrentTrack^.TrackRotKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { � Reading position XZY ORDER! � }
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

{ � Reads a track scale keys chunk � }
Procedure Chunk_TrackScaleKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufScaleKeys : Word;
    BufFlags     : Word;
Begin
 { � Read some unknown values � }
 Read_UnknownValues(TreeDepth);

 { � Read number of position keys � }
 BufScaleKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of scale keys: ',BufScaleKeys);
 {$ENDIF}

 { � An unknown value again... � }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { � Init memory area to store the keys � }
 With CurrentTrack^ Do Begin
   TrackScaleNum:=BufScaleKeys;
   GetMem(TrackScaleKeys,SizeOf(TScaleKey)*BufScaleKeys);
   FillChar(TrackScaleKeys^,SizeOf(TScaleKey)*BufScaleKeys,#0);
   Inc(MemoryAllocated,SizeOf(TScaleKey)*BufScaleKeys);
  End;

 { � Read positionkeys � }
 For Counter:=0 To BufScaleKeys-1 Do Begin
   With CurrentTrack^.TrackScaleKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { � Reading position XZY ORDER! � }
     With Vector Do Begin
       DWord(X):=ReadDWord; DWord(Z):=ReadDWord; DWord(Y):=ReadDWord;
       {$IFDEF _I3D_3DSL_DEBUGMODE_}
        WriteLn(Output,'':TreeDepth+2,' - X:',X:0:6,' Y:',Y:0:6,' Z:',Z:0:6);
       {$ENDIF}
      End;
    End;
  End;

End;

{ � Reads a track morph keys chunk � }
Procedure Chunk_TrackMorphKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufMorphKeys : Word;
    BufFlags     : Word;
Begin
 { � Read some unknown values � }
 Read_UnknownValues(TreeDepth);

 { � Read number of position keys � }
 BufMorphKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of morph keys: ',BufMorphKeys);
 {$ENDIF}

 { � An unknown value again... � }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { � Init memory area to store the keys � }
 With CurrentTrack^ Do Begin
   TrackMorphNum:=BufMorphKeys;
   GetMem(TrackMorphKeys,SizeOf(TMorphKey)*BufMorphKeys);
   FillChar(TrackMorphKeys^,SizeOf(TMorphKey)*BufMorphKeys,#0);
   Inc(MemoryAllocated,SizeOf(TMorphKey)*BufMorphKeys);
  End;

 { � Read positionkeys � }
 For Counter:=0 To BufMorphKeys-1 Do Begin
   With CurrentTrack^.TrackMorphKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { � Reading object name to morph � }
     ObjName:=ReadANSIString;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth+2,' - Object name: ',ObjName);
     {$ENDIF}
    End;
  End;

End;


{ � Reads a camera track info chunk � }
Procedure Chunk_CameraTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Set track type � }
 CurrentTrackType:=CameraTrack;
 { � Read remaining track info � }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ � Reads a camera target track info chunk � }
Procedure Chunk_CameraTargetTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Set track type � }
 CurrentTrackType:=CameraTargetTrack;
 { � Read remaining track info � }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ � Reads a camera FOV keys chunk � }
Procedure Chunk_CameraFOVKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufFOVKeys   : Word;
    BufFlags     : Word;
Begin
 { � Read some unknown values � }
 Read_UnknownValues(TreeDepth);

 { � Read number of position keys � }
 BufFOVKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of FOV keys: ',BufFOVKeys);
 {$ENDIF}

 { � An unknown value again... � }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { � Init memory area to store the keys � }
 With CurrentTrack^ Do Begin
   TrackFOVNum:=BufFOVKeys;
   GetMem(TrackFOVKeys,SizeOf(TFOVKey)*BufFOVKeys);
   FillChar(TrackFOVKeys^,SizeOf(TFOVKey)*BufFOVKeys,#0);
   Inc(MemoryAllocated,SizeOf(TFOVKey)*BufFOVKeys);
  End;

 { � Read positionkeys � }
 For Counter:=0 To BufFOVKeys-1 Do Begin
   With CurrentTrack^.TrackFOVKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { � Reading roll value � }
     DWord(FOV):=ReadDWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth+2,' - FOV:',FOV:0:6);
     {$ENDIF}
    End;
  End;

End;

{ � Reads a camera roll keys chunk � }
Procedure Chunk_CameraRollKeys(TreeDepth : DWord; CPosition : DWord);
Var Counter      : DWord;
    UnknownValue : Word;
    BufRollKeys  : Word;
    BufFlags     : Word;
Begin
 { � Read some unknown values � }
 Read_UnknownValues(TreeDepth);

 { � Read number of position keys � }
 BufRollKeys:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Number of roll keys: ',BufRollKeys);
 {$ENDIF}

 { � An unknown value again... � }
 UnknownValue:=ReadWord;
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn(Output,'':TreeDepth,' - Unknown value: $',Hex(UnknownValue));
 {$ENDIF}

 { � Init memory area to store the keys � }
 With CurrentTrack^ Do Begin
   TrackRollNum:=BufRollKeys;
   GetMem(TrackRollKeys,SizeOf(TRollKey)*BufRollKeys);
   FillChar(TrackRollKeys^,SizeOf(TRollKey)*BufRollKeys,#0);
   Inc(MemoryAllocated,SizeOf(TRollKey)*BufRollKeys);
  End;

 { � Read positionkeys � }
 For Counter:=0 To BufRollKeys-1 Do Begin
   With CurrentTrack^.TrackRollKeys[Counter] Do Begin
     Frame:=ReadWord;
     UnknownValue:=ReadWord;
     BufFlags:=ReadWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' - Frame ',Frame,'. Flags: $',Hex(BufFlags));
     {$ENDIF}
     Read_SplineFlags(TreeDepth+2,BufFlags,Spline);

     { � Reading roll value � }
     DWord(Roll):=ReadDWord;
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth+2,' - Roll:',Roll:0:6);
     {$ENDIF}
    End;
  End;

End;


{ � Reads a spotlight position keys chunk � }
Procedure Chunk_SpotlightTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Set track type � }
 CurrentTrackType:=SpotlightTrack;
 { � Read remaining track info � }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ � Reads a spotlight position keys chunk � }
Procedure Chunk_SpotlightTargetTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Set track type � }
 CurrentTrackType:=SpotlightTargetTrack;
 { � Read remaining track info � }
 Read_TrackInfo(TreeDepth,CPosition);
End;

{ � Reads a omnilight position keys chunk � }
Procedure Chunk_OmnilightTrack(TreeDepth : DWord; CPosition : DWord);
Begin
 { � Set track type � }
 CurrentTrackType:=OmnilightTrack;
 { � Read remaining track info � }
 Read_TrackInfo(TreeDepth,CPosition);
End;


{ � >>> MAIN CHUNK READERS <<< � }

Procedure I3DSL_UnknownChunk(TreeDepth : DWord; CPosition : DWord);
Begin
 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  WriteLn('':TreeDepth,' - Chunk was skipped!');
 {$ENDIF}
End;

{ � Returns chunk data, belongs to the specified ID. � }
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

     Else Begin { � Unknown chunk specified � }
            CValid:=False; CDescr:='Unknown'; CReader:=Nil;
            I3DSL_FindChunk:=BufChunkData;
            Exit;
           End;
    End;
   CValid:=True;
  End;
 I3DSL_FindChunk:=BufChunkData;
End;

{ � This is the main analyzer procedure. Processes the next branch-level � }
{ � in the .3DS file (which tree-structured). This procedure is recursive. � }
{ � I don't like recursive procedures, but in this case, this is the � }
{ � better solution. The previous versions (below 0.4.0) of this loader � }
{ � wasn't recursive, so i tried both ways... � }
Procedure I3DSL_ChunkReader(TreeDepth : DWord; CPosition : DWord);
Var ChunkID      : Word;
    ChunkLength  : DWord;
    CurrentPos   : DWord;
    CurrentChunk : TChunkData;
Begin
 While Current3DSPos<CPosition Do Begin

   CurrentPos:=Current3DSPos;

   { � Read current chunk header values � }
   ChunkID    :=ReadWord;
   ChunkLength:=ReadDWord;
   If ChunkLength=0 Then Exit;
{   WriteLn(ChunkID,' ',ChunkLength);}
   If (TreeDepth=0) And (ChunkID<>Main3DS) Then Begin
     { � If there is no main chunk ID at the beginning of the file, � }
     { � then it's a 3DS file, or corrupted. � }
     I3D_Load3DSErrorCode:=I3DL_ErrorNo3DS;
     Exit;
    End;

   CurrentChunk:=I3DSL_FindChunk(ChunkID);
   With CurrentChunk Do Begin
     {$IFDEF _I3D_3DSL_DEBUGMODE_}
      WriteLn(Output,'':TreeDepth,' � ',CDescr,' chunk ID $',Hex(ChunkID),
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

{ � >>> DATA AREA INIT FUNCTIONS <<< � }

Procedure CollectLinkedData;
Var Counter : DWord;
Begin
 With Loaded3DS^ Do Begin
   { � Collect Object Pointers � }
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

   { � Collect Camera Datas � }
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

   { � Collect Material Data � }
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

   { � Collect Animation Data � }
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

   { � Pairing Faces With Materials � }
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

   { � Pairing Objects With Tracks � }
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

   { � Init Cameras With Tracks � }
   If CameraNum>0 Then Begin
     For Counter:=0 To CameraNum-1 Do Begin
       With Camera3D[Counter]^ Do Begin
         PosTrack:=65535;
         TargTrack:=65535;
        End;
      End;
    End;

   { � Pairing Cameras With Tracks � }
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

{ � >>> P U B L I C  F U N C T I O N S <<< � }

{ � Returns the last 3DS loader error code, then reset the I3D_Load3DSError � }
{ � variable. No 3DS can be loaded while this variable isn't zero. As you � }
{ � see, it works exactly like the IOResult. Simple. � }
Function I3D_Get3DSError : DWord;
Begin
 I3D_Get3DSError:=I3D_Load3DSErrorCode;
 I3D_Load3DSErrorCode:=0;
End;

{ � Returns an error message string specific to the error code � }
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

{ � Frees up a specified 3DS structure, from the memory � }
Function I3D_Free3DS(Var Mesh3D : P3DMesh) : Boolean;
Var Counter : DWord;
Begin
 I3D_Free3DS:=False;

 If I3D_Load3DSErrorCode<>0 Then Begin
   { � ERROR - Loader subsystem is in error! � }
   Exit;
  End;

 If Mesh3D=Nil Then Begin
   { � ERROR - Invalid pointer specified! � }
   I3D_Load3DSErrorCode:=I3DL_ErrorFree3DS;
   Exit;
  End;

 { � Freeing up the .3DS structure � }
 With Mesh3D^ Do Begin

   { � Freeing up objects � }
   If ObjectNum>0 Then Begin
     For Counter:=0 To ObjectNum-1 Do Begin
       With Object3D[Counter]^ Do Begin
         { � Freeing up vertexes � }
         FreeMem(Vertex,VertexNum*SizeOf(T3DVertex));
         { � Freeing up faces � }
         FreeMem(Face,FaceNum*SizeOf(T3DFace));
        End;
       { � Freeing up main object record � }
       Dispose(Object3D[Counter]);
      End;
     { � Freeing up main object pointer array � }
     FreeMem(Object3D,ObjectNum*SizeOf(P3DObject));
    End;

   { � Freeing up cameras � }
   If CameraNum>0 Then Begin
     For Counter:=0 To CameraNum-1 Do Begin
       { � Freeing up main camera record � }
       Dispose(Camera3D[Counter]);
      End;
     { � Freeing up main camera pointer array � }
     FreeMem(Camera3D,CameraNum*SizeOf(P3DCamera));
    End;

   { � Freeing up lights � }
   If LightNum>0 Then Begin
     For Counter:=0 To LightNum-1 Do Begin
       { � Freeing up main light record � }
       Dispose(Light[Counter]);
      End;
     { � Freeing up main light pointer array � }
     FreeMem(Light,LightNum*SizeOf(PLight));
     { � LIGHTS STILL TO BE IMPLEMENTED!!! � }
    End;

   { � Freeing up materials � }
   If MaterialNum>0 Then Begin
     For Counter:=0 To MaterialNum-1 Do Begin
       { � Freeing up main material record � }
       Dispose(Material[Counter]);
      End;
     { � Freeing up main material pointer array � }
     FreeMem(Material,MaterialNum*SizeOf(PMaterial));
    End;

   { � Freeing up tracks � }
   If TracksNum>0 Then Begin
     For Counter:=0 To TracksNum-1 Do Begin
       With Tracks[Counter]^ Do Begin
         { � Freeing up position keys � }
         If TrackPosKeys<>Nil Then Begin
           FreeMem(TrackPosKeys,TrackPosNum*SizeOf(TPosKey));
          End;
         { � Freeing up rotation keys � }
         If TrackRotKeys<>Nil Then Begin
           FreeMem(TrackRotKeys,TrackRotNum*SizeOf(TRotKey));
          End;
         { � Freeing up scale keys � }
         If TrackScaleKeys<>Nil Then Begin
           FreeMem(TrackScaleKeys,TrackScaleNum*SizeOf(TScaleKey));
          End;
         { � Freeing up morph keys � }
         If TrackMorphKeys<>Nil Then Begin
           FreeMem(TrackMorphKeys,TrackMorphNum*SizeOf(TMorphKey));
          End;
         { � Freeing up FOV keys � }
         If TrackFOVKeys<>Nil Then Begin
           FreeMem(TrackFOVKeys,TrackFOVNum*SizeOf(TFOVKey));
          End;
         { � Freeing up roll keys � }
         If TrackRollKeys<>Nil Then Begin
           FreeMem(TrackRollKeys,TrackRollNum*SizeOf(TRollKey));
          End;
        End;
       { � Freeing up main track record � }
       Dispose(Tracks[Counter]);
      End;
     { � Freeing up main track pointer array � }
     FreeMem(Tracks,TracksNum*SizeOf(P3DTrack));
    End;

  End;

 { � Freeing up main 3DS array � }
 Dispose(Mesh3D);

 Mesh3D:=Nil;
 I3D_Free3DS:=True;
End;

{$IFDEF _I3D_INCLUDE_}
 { � Loads a .3DS file from the specified datafile. � }
 Function I3D_IDSLoad3DS(Var Mesh3D : P3DMesh; DFHandle : IDS_PDataFile; FileName : String) : Boolean;
 Var File3DS    : IDS_PFile;
     TreeDepth  : DWord;
     CPosition  : DWord;
 Begin
  I3D_IDSLoad3DS:=False;

  If I3D_Load3DSErrorCode<>0 Then Begin
    { � ERROR - Loader subsystem is in error! � }
    Exit;
   End;

  { � Checking if filename is valid. � }
  If Filename='' Then Begin
    { � ERROR - Filename is an empty string � }
    I3D_Load3DSErrorCode:=I3DL_ErrorFileName;
    Exit;
   End;

  { � Opening and reading file � }
  File3DS:=IDS_OpenFile(DFHandle,FileName);
  If File3DS=Nil Then Begin
    { � ERROR - Unable to open file � }
    I3D_Load3DSErrorCode:=I3DL_ErrorFileOpen;
    Exit;
   End;

  { � Assigning internal variables � }
  With File3DS^ Do Begin
    Current3DSSize:=FSize;
    Current3DS:=FData;
   End;

  {$IFDEF _I3D_3DSL_DEBUGMODE_}
   DebugInit(FileName);
  {$ENDIF}

  { � Loading .3DS file into the specified mesh structure � }
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

  { � Closing file � }
  IDS_CloseFile(File3DS);

  Mesh3D:=Loaded3DS;
  I3D_IDSLoad3DS:=(I3D_Load3DSErrorCode=0);
 End;
{$ENDIF}

{ � Loads a .3DS file from the specified filename. � }
Function I3D_Load3DS(Var Mesh3D : P3DMesh; FileName : String) : Boolean;
Var File3DS    : File;
    TreeDepth  : DWord;
    CPosition  : DWord;
Begin
 I3D_Load3DS:=False;

 If I3D_Load3DSErrorCode<>0 Then Begin
   { � ERROR - Loader subsystem is in error! � }
   Exit;
  End;

 { � Checking if filename is valid. � }
 If Filename='' Then Begin
   { � ERROR - Filename is an empty string � }
   I3D_Load3DSErrorCode:=I3DL_ErrorFileName;
   Exit;
  End;

 { � Opening file � }
 Assign(File3DS,FileName);
 FileMode:=0;
 Reset(File3DS,1);
 If IOResult<>0 Then Begin
   { � ERROR - Unable to open file � }
   I3D_Load3DSErrorCode:=I3DL_ErrorFileOpen;
   Exit;
  End;

 { � Allocating load buffer � }
 Current3DSSize:=FileSize(File3DS);
 GetMem(Current3DS,Current3DSSize);
 If Current3DS=Nil Then Begin
   { � ERROR - Not enough memory � }
   I3D_Load3DSErrorCode:=I3DL_ErrorMemAlloc;
   Exit;
  End;

 { � Reading file to load buffer � }
 BlockRead(File3DS,Current3DS^,Current3DSSize);
 If IOResult<>0 Then Begin
   { � ERROR - File read error � }
   I3D_Load3DSErrorCode:=I3DL_ErrorFileIO;
   Exit;
  End;

 {$IFDEF _I3D_3DSL_DEBUGMODE_}
  DebugInit(FileName);
 {$ENDIF}

 { � Loading .3DS file into the specified mesh structure � }
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

 { � Freeing up load buffer � }
 FreeMem(Current3DS,Current3DSSize);

 { � Closing file � }
 Close(File3DS);

 Mesh3D:=Loaded3DS;
 I3D_Load3DS:=(I3D_Load3DSErrorCode=0);
End;

Begin
 I3D_Load3DSErrorCode:=0;
End.
{ � I3D_3DSL.PAS - (C) 1998-2001 Charlie/Inquisition and others � }

{ � Changelog : � }
{ � 0.4.7 - Released to the public on the internet                        � }
{ �         [03.july.2001 - Charlie]                                      � }
{ � 0.4.6 - Added I3D_IDSLoad3DS procedure to allow loading from IDS      � }
{ �         datafiles. [05.feb.2001 - Charlie]                            � }
{ � 0.4.5 - Minor changes (re-enabled memory deallocation of light        � }
{ �         structures, added P3DVector type for stand-alone version,     � }
{ �         little bug in logfile fixed) [15.10.2000 - mrc!]              � }
{ � 0.4.4 - Huge amount of memory handling reorganizations, and bugfixes. � }
{ �       - Aaaaaaarghhh... It was not possible to load more 3DS file     � }
{ �         with the loader... Fixed.                                     � }
{ �       - I3D_Free3DS was buggy with Lights. Fixed.                     � }
{ �       - Some other modifications                                      � }
{ �         [30.august.2000 - Charlie]                                    � }
{ � 0.4.3 - I3D_Free3DS() function implemented.                           � }
{ �       - Some additional comments.                                     � }
{ �       - Spot and omnilight track support. Not well tested, so may     � }
{ �         contain bugs. Anyway it seems to work. Light objects still    � }
{ �         not supported.                                                � }
{ �       - Bugfix for wrong track numbers.                               � }
{ �       - Modifications for mrc!'s 3D engine. (_I3D_INCLUDE_ symbol)    � }
{ �       - Merged with some other modifications from mrc!.               � }
{ �         [07.august.2000 - Charlie]                                    � }
{ � 0.4.2 - Added BoundingBox array to T3DObject structure                � }
{ �       - TVector was renamed to T3DVector                              � }
{ �         [20.july.2000 - mrc!]                                         � }
{ � 0.4.1 - Modified to match mrc!'s recommendations.                     � }
{ �       - XYZ coordinates moved into TVector type in all records.       � }
{ �       - Camera target and position moved into TVector type.           � }
{ �       - TCamPosition type removed.                                    � }
{ �       - WARNING! Due to the modifications described above, the        � }
{ �         internal data structure of this version no longer compatible  � }
{ �         with previous versions! You'll need to modify your programs   � }
{ �         to match the new structure. Sorry.                            � }
{ �       - Better error detection and handling.                          � }
{ �       - Still no light support. Reason: lack of time. Sorry. :(       � }
{ �         [30.june.2000 - Charlie]                                      � }
{ � 0.4.0 - Complettely rewritten from scratch. Uses recursive loading.   � }
{ �         All features of previous versions supported, but the API is   � }
{ �         a little bit modified. You'll need to syncronize your sources � }
{ �         to this new version. Sorry.                                   � }
{ �       - As this new version is complettely rewritten, many bugs of    � }
{ �         the old loader is fixed. In some cases the old version didn't � }
{ �         find some chunks. (Mainly with 3DS Max exported files.)       � }
{ �         Also the translation matrix reading was buggy, in version     � }
{ �         0.3.0. These problems has been eliminated. But also it's      � }
{ �         possible that this new version also has bugs, since it's      � }
{ �         not very well tested. We'll see.                              � }
{ �       - Object visibility flag added to the T3DObject record.         � }
{ �       - Track hierarchy value added to the T3DTrack record.           � }
{ �       - Spline flags now stored in the track keys.                    � }
{ �       - MemoryUsed value added to the T3DMesh record.                 � }
{ �       - I3D_Get3DSError and I3D_Get3DSErrorString procedure added.    � }
{ �       - I3D_Gen3DSError procedure removed.                            � }
{ �       - Note: Lights still not completely supported in this release   � }
{ �               Do _NOT_ use lights. Wait for the next release, which   � }
{ �               will be released soon. Okay, you've been warned...      � }
{ �         [04.may.2000 - Charlie]                                       � }
{ � 0.3.1 - Initial Light support, omnilights (never finished version)    � }
{ �         [22.apr.2000 - Charlie]                                       � }
{ � 0.3.0 - A huge bug fixed, if specified .3DS didn't exist, the loader  � }
{ �         crashed. Sorry. It happenned only with debug mode enabled.    � }
{ �         (It was my most stupid fault by far, since i'm coding...)     � }
{ �       - Another huge bug fixed, stupid Autodesk store the coordinates � }
{ �         in XZY order. We loaded it in XYZ order... Now it is fixed.   � }
{ �       - Texture Wrapping Flags added to face record                   � }
{ �       - Some cosmetic changes (mrc!!!!! What the hell was that!? :)   � }
{ �         [10.feb.2000 - Charlie]                                       � }
{ � 0.2.5 - If Camera PosTrack or TargTrack not exist then default 65535. � }
{ �         [06.nov.1999 - Tcc]                                           � }
{ � 0.2.4 - I3D_Gen3DSError procedure added                               � }
{ �         [15.oct.1999 - mrc!]                                          � }
{ � 0.2.3 - The loader crashed without debug mode enabled. Fixed.         � }
{ �         [28.sep.1999 - Charlie]                                       � }
{ � 0.2.2 - Camera with Camera Track pairing bug fixed                    � }
{ �       - Chunk Type "Object Hide Track" ($0B029) added. (ID only)      � }
{ �         [03.aug.1999 - Charlie]                                       � }
{ � 0.2.1 - Some array limit checking code added to eliminate various     � }
{ �         general protection faults                                     � }
{ �       - Chunk Type "Object Morph Track" ($0B026) added.               � }
{ �         (INQ-Members' Party at Innocent/INQ's place)                  � }
{ �         [01.aug.1999 - Charlie]                                       � }
{ � 0.2.0 - First public version                                          � }
{ �         [30.jul.1999 - Charlie]                                       � }
{ � 0.1.x - Not public                                                    � }
