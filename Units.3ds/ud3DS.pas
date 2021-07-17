{$DEFINE TEXTURIZE}

unit ud3DS;

interface

uses debug, udKeyFrame, udMatrix, udVector, udQuat, I3d_3dsl, udTGA;

type tTexCoord=packed record
        X,Y,U,V:word;
        Z:Longint;
     end;

type PVertex=^TVertex;
     Tvertex=packed record
      vec:Tvector;
      u,v:single;
     end;

type PFace=^TFace;
     TFace=packed record
      a,b,c:word;
      tex:byte;
     end;


type
     PObject=^TObject;
     TObject=packed record
{
        vertex:array[0..1024] of Tvertex;
        temp_vertex:array[0..1024] of Tvertex;
}
        numvertex:word;
        vertex:PVertex;
        temp_vertex:Pvertex;

        numfaces:word;
        face:PFace;

        transmat,pivot:Tvector;        
        rotmat:TMatrix3;
        tracknum:word;
        static:boolean;
        matrix:Tmatrix;
     end;

type P3DSTrack=^T3DSTrack;
     T3DSTrack=packed record
        keys:byte;
        pivot:Tvector;
        startpos:Tvector;
        scalefactor:Tvector;
        parent:word;
        data:array[0..8] of TTrack;
        rotdata:TQTrack;
     end;
     
type Tscene=object
      Public

       numobjects:byte;
       objects:PObject;

       numcamera:byte;
       camera:array[0..255] of packed record
        pos,target:TVector;
        fov:single;
        postrack,targtrack:word;
       end;

       nummaterial:byte;
       material:array[0..255] of packed record
        fn:string;
        data:pointer;
        w,h:word;
       end;

       // 0-2 POS x,y,z
       // 3-5 SCL x,y,z
       // 6 MRPH
       // 7 FOV
       // 8 ROLL

       numtracks:byte;
       track:P3dsTrack;

       curview:packed record
        camera:Tvector;
        target:Tvector;
        angle:Tvector;
       end;

       frame_first:word;
       frame_last:word;

       zoom,roll:single;
       
       wave:boolean;
       waveph:byte;
       particles:boolean;

       procedure Load3DS(fn:string);
       procedure LoadTexture(fn:string; num:byte);
       procedure View3DS(cam,frame:word; vscr:pointer);
     end;

var
    flares:array[0..100] of TVector;
    numflares:dword;

implementation

var mesh3d:P3DMesh;
    l:boolean;
    
function ttex(p1:tVector; u,v:single):ttexcoord;
var t:ttexcoord;
begin
 t.x:=round(319-p1.x);
 t.y:=round(p1.y);
 t.u:=round(u*256);
 t.v:=round(v*256);
 t.z:=round(p1.z*65536);
 ttex:=t;
end;

{$INCLUDE inc/clip.inc}
{$INCLUDE inc/texture.inc}
{$INCLUDE inc/flare.inc}

procedure Tscene.LoadTexture(fn:string; num:byte);
var t:TTGA;
begin
  t:=udTGALoad(fn);
  material[num].w:=t.w;
  material[num].h:=t.h;
  material[num].data:=t.dat;
end;

// ==================================================
// || 3DS Player - Loader
// || *** WARNING! Explicit language! ***
// ==================================================

procedure Tscene.Load3DS(fn:string);
var p:P3DObject;
    v:T3DVertex;
    w:T3DVector;
    f:T3DFace;
    c:P3DCamera;
    t:P3DTrack;
    m:PMaterial;
    x,y,z:word;
    min:single;

begin

 If Not I3D_Load3DS(Mesh3D,fn) Then
  writeln('» ERROR! '+I3D_Get3DSErrorString(I3D_Get3DSError));

 x:=0;

 frame_first:=Mesh3D^.FirstFrame;
 frame_last:=Mesh3D^.LastFrame;

 // ----------------- objectgeci ---------------------
// debuginfo(' - Loadin objectz...');
 p:=Mesh3D^.Object3DL;
 numobjects:=Mesh3D^.ObjectNum-1;
 getmem(objects,Mesh3D^.ObjectNum*sizeof(TObject));
 fillchar(objects^,Mesh3D^.ObjectNum*sizeof(TObject),0);
 repeat
//  debuginfo(st(x)+' * '+p^.ObjName);
  // kibaszott vertexek
  objects[x].numvertex:=p^.VertexNum-1;
  getmem(objects[x].vertex     ,p^.VertexNum*sizeof(TVertex));
  getmem(objects[x].temp_vertex,p^.VertexNum*sizeof(TVertex));
  fillchar(objects[x].vertex^     ,p^.VertexNum*sizeof(TVertex),0);
  fillchar(objects[x].temp_vertex^,p^.VertexNum*sizeof(TVertex),0);
  min:=0;
//  min:=single(min);
//  debuginfo(stf(min));
  for y:=0 to p^.VertexNum-1 do
  begin
   v:=p^.Vertex[y];
   objects[x].vertex[y].vec.x:=v.Vector.X;
   objects[x].vertex[y].vec.y:=v.Vector.Y;
   objects[x].vertex[y].vec.z:=v.Vector.Z;
   objects[x].vertex[y].u:=v.u; if v.u<min then min:=v.u;
   objects[x].vertex[y].v:=v.v; if v.v<min then min:=v.v;
  end;
//  if min<1 then min:=0;
  min:=int(min);
  
  // buzi texturakoordinatak lehetnek minuszok, mindegyiket eltoljuxarul
  for y:=0 to p^.VertexNum-1 do
  begin
   v:=p^.Vertex[y];
   objects[x].vertex[y].u:=objects[x].vertex[y].u-round(min)+1;
   objects[x].vertex[y].v:=objects[x].vertex[y].v-round(min)+1;
  end;
  
  // kurva facek
  objects[x].numfaces:=p^.FaceNum-1;
  getmem(objects[x].face,p^.FaceNum*sizeof(TFace));
  fillchar(objects[x].face^,p^.FaceNum*sizeof(TFace),0);
  for y:=0 to p^.FaceNum-1 do
  begin
   f:=p^.Face[y];
   objects[x].face[y].a:=f.Vertex1;
   objects[x].face[y].b:=f.Vertex2;
   objects[x].face[y].c:=f.Vertex3;
   objects[x].face[y].tex:=f.MatNum;
  end;

  // egyéb szirszarok

  objects[x].tracknum:=p^.TrackNum;
  
  objects[x].transmat.x:=p^.Trans_Mat[0];
  objects[x].transmat.y:=p^.Trans_Mat[1];
  objects[x].transmat.z:=p^.Trans_Mat[2];
  
  objects[x].rotmat[0,0]:=p^.Rot_Mat[0];
  objects[x].rotmat[0,1]:=p^.Rot_Mat[1];
  objects[x].rotmat[0,2]:=p^.Rot_Mat[2];
  
  objects[x].rotmat[1,0]:=p^.Rot_Mat[3];
  objects[x].rotmat[1,1]:=p^.Rot_Mat[4];
  objects[x].rotmat[1,2]:=p^.Rot_Mat[5];
  
  objects[x].rotmat[2,0]:=p^.Rot_Mat[6];
  objects[x].rotmat[2,1]:=p^.Rot_Mat[7];
  objects[x].rotmat[2,2]:=p^.Rot_Mat[8];

  objects[x].static:=p^.static;

  p:=p^.PNextObj;
  inc(x);
 until p=nil;

 // ----------------- lofasz kamerak ---------------------
// debuginfo(' - Loadin camz...');
 x:=0;
 c:=Mesh3D^.Camera3DL;
 numcamera:=Mesh3D^.CameraNum-1;
 if Mesh3D^.CameraNum=0 then
 begin
   writeln('*** No cameras in mesh!');
   halt(0);
 end;
 repeat

  w:=c^.Position;
  camera[x].pos.x:=w.x;
  camera[x].pos.y:=w.y;
  camera[x].pos.z:=w.z;

  w:=c^.Target;
  camera[x].target.x:=w.x;
  camera[x].target.y:=w.y;
  camera[x].target.z:=w.z;

  camera[x].fov:=c^.fov;

  camera[x].postrack:=c^.PosTrack;
  camera[x].targtrack:=c^.TargTrack;

  c:=c^.PNextCam;
  inc(x);
 until c=nil;

 // ------------------ primko material loader ---------------------
 // -- (taposabb nem kell, mer ugyse hasznaljuk, meg mer lofasz) --

// debuginfo(' - Loadin materialz...');
 x:=0;
 if Mesh3D^.MaterialNum>0 then
 begin
  m:=Mesh3D^.MaterialL;
  nummaterial:=Mesh3D^.MaterialNum-1;
  repeat
//   material[x].fn:=m^.filename;
//   debuginfo(st(x)+' - '+m^.filename);
   inc(x);
   m:=m^.PNextMat;
  until m=nil;
 end;

 // ------------------ trackek bazmeg ---------------------
// debuginfo(' - Loadin trax...');

 x:=0;
 t:=Mesh3D^.TracksL;
 numtracks:=Mesh3D^.TracksNum-1;
 getmem(track,Mesh3D^.TracksNum*sizeof(T3DSTrack));
 fillchar(track^,Mesh3D^.TracksNum*sizeof(T3DSTrack),0);
 repeat
//  debuginfo(' - Init trax...');

  track[x].keys:=0;

   // 0-2 POS x,y,z
   // 3-5 SCL x,y,z
   // 6 MRPH
   // 7 FOV
   // 8 ROLL

//  track[x].type:=t^.tracktype;

  track[x].pivot.x:=t^.TrackPivot.Vector.x;
  track[x].pivot.y:=t^.TrackPivot.Vector.y;
  track[x].pivot.z:=t^.TrackPivot.Vector.z;

  track[x].parent:=t^.TrackParent;

//  debuginfo('  - Loadin postrax...');
  if t^.trackPosKeys<>nil then
  begin
   for z:=0 to 2 do
   begin
    track[x].data[z].numkey:=t^.TrackPosNum;
{
    getmem  (track[x].data[z].key ,t^.TrackPosNum*sizeof(Tkey));
    fillchar(track[x].data[z].key^,t^.TrackPosNum*sizeof(Tkey),0);
}
   end;
   
   for y:=0 to t^.TrackPosNum do
   begin
    track[x].data[0].key[y].v:=t^.trackposkeys[y].Vector.x;
    track[x].data[1].key[y].v:=t^.trackposkeys[y].Vector.y;
    track[x].data[2].key[y].v:=t^.trackposkeys[y].Vector.z;
    for z:=0 to 2 do
    begin
     track[x].data[z].key[y].frame:=t^.trackposkeys[y].frame;
     track[x].data[z].key[y].t:=t^.trackposkeys[y].Spline.tension;
     track[x].data[z].key[y].c:=t^.trackposkeys[y].Spline.continuity;
     track[x].data[z].key[y].b:=t^.trackposkeys[y].Spline.bias;
    end;
   end;
   track[x].keys:=track[x].keys or 1;
  end;

  track[x].startpos.x:=track[x].data[0].key[0].v;
  track[x].startpos.y:=track[x].data[1].key[0].v;
  track[x].startpos.z:=track[x].data[2].key[0].v;

//  debuginfo('  - Loadin rottrax...');
  if t^.trackRotKeys<>nil then
  begin
   track[x].rotdata.numkey:=t^.TrackRotNum;
   for y:=0 to t^.TrackRotNum do
   begin
    track[x].rotdata.key[y].q:=Angle2Quat(AngleAxis(t^.trackrotkeys[y].Angle,
                                          Vector(t^.trackrotkeys[y].Vector.x,
                                                 t^.trackrotkeys[y].Vector.y,
                                                 t^.trackrotkeys[y].Vector.z)));
    
    track[x].rotdata.key[y].frame:=t^.trackrotkeys[y].frame;
    track[x].rotdata.key[y].t:=t^.trackrotkeys[y].Spline.tension;
    track[x].rotdata.key[y].c:=t^.trackrotkeys[y].Spline.continuity;
    track[x].rotdata.key[y].b:=t^.trackrotkeys[y].Spline.bias;
   end;
   track[x].keys:=track[x].keys or 2;
  end;

  for y:=1 to track[x].rotdata.numkey do
    track[x].rotdata.key[y].q:=udQuatMultiply(track[x].rotdata.key[y-1].q,track[x].rotdata.key[y].q);

//  debuginfo('  - Loadin scaletrax...');
  if t^.trackScaleKeys<>nil then
  begin
   for z:=3 to 5 do
    track[x].data[z].numkey:=t^.TrackScaleNum;
{
   for z:=3 to 5 do
   begin
    track[x].data[z].numkey:=t^.TrackScaleNum;
    getmem  (track[x].data[z].key ,t^.TrackScaleNum*sizeof(Tkey));
    fillchar(track[x].data[z].key^,t^.TrackScaleNum*sizeof(Tkey),0);
   end;
}
   for y:=0 to t^.TrackScaleNum do
   begin
    track[x].data[3].key[y].v:=t^.trackScalekeys[y].Vector.x;
    track[x].data[4].key[y].v:=t^.trackScalekeys[y].Vector.y;
    track[x].data[5].key[y].v:=t^.trackScalekeys[y].Vector.z;
    for z:=3 to 5 do
    begin
     track[x].data[z].key[y].frame:=t^.trackScalekeys[y].frame;
     track[x].data[z].key[y].t:=t^.trackScalekeys[y].Spline.tension;
     track[x].data[z].key[y].c:=t^.trackScalekeys[y].Spline.continuity;
     track[x].data[z].key[y].b:=t^.trackScalekeys[y].Spline.bias;
    end;
   end;
   track[x].keys:=track[x].keys or 4;
  end;

  // NO MORPH KEY!!!

//  debuginfo('  - Loadin FOVtrax...');
  if t^.trackFOVKeys<>nil then
  begin
   track[x].data[7].numkey:=t^.TrackFOVNum;
{
   getmem  (track[x].data[7].key ,t^.TrackFOVNum*sizeof(Tkey));
   fillchar(track[x].data[7].key^,t^.TrackFOVNum*sizeof(Tkey),0);
}
   for y:=0 to t^.TrackFOVNum do
   begin
    track[x].data[7].key[y].v:=t^.trackFOVkeys[y].FOV;
    track[x].data[7].key[y].frame:=t^.trackFOVkeys[y].frame;
    track[x].data[7].key[y].t:=t^.trackFOVkeys[y].Spline.tension;
    track[x].data[7].key[y].c:=t^.trackFOVkeys[y].Spline.continuity;
    track[x].data[7].key[y].b:=t^.trackFOVkeys[y].Spline.bias;
   end;
   track[x].keys:=track[x].keys or 16;
  end;

//  debuginfo('  - Loadin rolltrax...');
  if t^.trackRollKeys<>nil then
  begin
   track[x].data[8].numkey:=t^.TrackRollNum;
{
   getmem  (track[x].data[8].key ,(t^.TrackRollNum+1)*sizeof(Tkey));
   fillchar(track[x].data[8].key^,(t^.TrackRollNum+1)*sizeof(Tkey),0);
}
   for y:=0 to t^.TrackRollNum do
   begin
    track[x].data[8].key[y].v:=t^.trackRollkeys[y].Roll;
    track[x].data[8].key[y].frame:=t^.trackRollkeys[y].frame;
    track[x].data[8].key[y].t:=t^.trackRollkeys[y].Spline.tension;
    track[x].data[8].key[y].c:=t^.trackRollkeys[y].Spline.continuity;
    track[x].data[8].key[y].b:=t^.trackRollkeys[y].Spline.bias;
   end;
   track[x].keys:=track[x].keys or 32;
  end;

  inc(x);
  t:=t^.PNextTrack;
 until t=nil;

// debuginfo(' - Doin init (normal)');
 for x:=0 to numtracks do
  for y:=0 to 8 do
   if track[x].data[y].numkey>1 then
    udKeyInitVectors(track[x].data[y]);

// debuginfo(' - Doin init (rotation)');
 for x:=0 to numtracks do
  if track[x].rotdata.numkey>1 then
   udQuatKeyInit(track[x].rotdata);

 // Elvben ennyi...


end;

// ==================================================
// || 3DS Player - Display routine
// ==================================================

procedure Tscene.View3DS(cam,frame:word; vscr:pointer);
var m,n:Tmatrix;
    x,y:word;
    vx,vy,vz,v:Tvector;
    tempv:array[0..1024] of Tvertex;
    mv,sv,vv:Tvector;
    p1,p2,p3,p:Tpoint;
    k:boolean;
    q:TQuat;
    aa:TAngleAxis;
    mm:Tmatrix3;
begin

// Basic steps:
// 1 - Set basic values for camera, camera target, FOV, etc. (load)
// 2 - Keyframe
// 3 - Matrix all vertex values
// 4 - Polyfill

 fillchar(zbuf,sizeof(zbuf),255);

 for x:=0 to numobjects do
 begin
  
  m:=udMatrixIdentity;
  
  m[0,0]:=objects[x].rotmat[0,0]; m[0,1]:=objects[x].rotmat[0,1]; m[0,2]:=objects[x].rotmat[0,2]; 
  m[1,0]:=objects[x].rotmat[1,0]; m[1,1]:=objects[x].rotmat[1,1]; m[1,2]:=objects[x].rotmat[1,2]; 
  m[2,0]:=objects[x].rotmat[2,0]; m[2,1]:=objects[x].rotmat[2,1]; m[2,2]:=objects[x].rotmat[2,2]; 
  m[3,0]:=objects[x].transmat.x;
  m[3,1]:=objects[x].transmat.y;
  m[3,2]:=objects[x].transmat.z;

  m:=udMatrixInvert(m);

  n:=udMatrixIdentity;
  q:=udQuatKeyGet(track[objects[x].tracknum].rotdata,frame);
  n:=udMatrixFromQuat(q);
  m:=udMatrixMultiply(m,n);

  sv.x:=udKeyGetPoint(track[objects[x].tracknum].data[3],frame);
  sv.y:=udKeyGetPoint(track[objects[x].tracknum].data[4],frame);
  sv.z:=udKeyGetPoint(track[objects[x].tracknum].data[5],frame);
  m:=udMatrixTranslateScl(m,sv);

  mv.x:=udKeyGetPoint(track[objects[x].tracknum].data[0],frame)-track[objects[x].tracknum].pivot.x;
  mv.y:=udKeyGetPoint(track[objects[x].tracknum].data[1],frame)-track[objects[x].tracknum].pivot.y;
  mv.z:=udKeyGetPoint(track[objects[x].tracknum].data[2],frame)-track[objects[x].tracknum].pivot.z;
  m:=udMatrixTranslatePos(m,mv);
  
  if (track[objects[x].tracknum].parent<>65535) then
    m:=udMatrixMultiply(m,objects[track[objects[x].tracknum].parent].matrix);

  for y:=0 to objects[x].numvertex do
  begin
   objects[x].temp_vertex[y]:=objects[x].vertex[y];

   v:=objects[x].vertex[y].vec;
   if wave and (x=1) then
     v.y:=v.y+sin(waveph/4+v.y*4)*4;
   
//   objects[x].temp_vertex[y].vec:=udMatrixMultiplyVector(m,objects[x].vertex[y].vec);
   objects[x].temp_vertex[y].vec:=udMatrixMultiplyVector(m,v);
  end;
  objects[x].matrix:=m;
 end;
 
 
// --------------------------------------------------
// Camera + camera target keyframing
// --------------------------------------------------

 curview.camera.x:=udKeyGetPoint(track[camera[cam].postrack].data[0],frame);
 curview.camera.y:=udKeyGetPoint(track[camera[cam].postrack].data[1],frame);
 curview.camera.z:=udKeyGetPoint(track[camera[cam].postrack].data[2],frame);

 curview.target.x:=udKeyGetPoint(track[camera[cam].targtrack].data[0],frame);
 curview.target.y:=udKeyGetPoint(track[camera[cam].targtrack].data[1],frame);
 curview.target.z:=udKeyGetPoint(track[camera[cam].targtrack].data[2],frame);


// --------------------------------------------------
// Calculating new basic system
// --------------------------------------------------

 vz:=udVectorNormalize( udVectorDiff( curview.target,curview.camera ) );
 vx:=udVectorNormalize( udVectorCrossProd(vz,Vector(0,1,0)) );
 vy:=udVectorNormalize( udVectorCrossProd(vz,vx) );

 m:=udMatrixIdentity;
 n:=udMatrixIdentity;

 zoom:=10000/udKeyGetPoint(track[camera[cam].postrack].data[7],frame);
 roll:=      udKeyGetPoint(track[camera[cam].postrack].data[8],frame);

 m:=udMatrixTranslatePos(m, udVectorNegative(curview.camera));

 n[0,0]:= vx.x; n[0,1]:= vy.x; n[0,2]:= vz.x;
 n[1,0]:= vx.y; n[1,1]:= vy.y; n[1,2]:= vz.y;
 n[2,0]:= vx.z; n[2,1]:= vy.z; n[2,2]:= vz.z;

 m:=udMatrixMultiply(m,n);
 m:=udMatrixRoll(m,roll/180*pi); 

// --------------------------------------------------
// Polyfilling
// --------------------------------------------------
 
{$IFDEF TEXTURIZE}

 for x:=0 to numobjects do
 begin
  for y:=0 to objects[x].numvertex do
  begin
   tempv[y]:=objects[x].temp_vertex[y];
   tempv[y].vec:=udMatrixMultiplyVector(m, objects[x].temp_vertex[y].vec );
   if (abs(tempv[y].vec.z)<1) then tempv[y].vec.z:=1;
  end;
  
  for y:=0 to objects[x].numfaces do
  begin
{
    if (tempv[objects[x].face[y].a].vec.z>0) or
       (tempv[objects[x].face[y].b].vec.z>0) or
       (tempv[objects[x].face[y].c].vec.z>0) then
}
    l:=(x=0) and (y=2);
    drawpoly(tempv[objects[x].face[y].a],
             tempv[objects[x].face[y].b],
             tempv[objects[x].face[y].c],
             material[objects[x].face[y].tex].data,vscr,zoom);


  end;
 end;

 if particles then
   for x:=0 to numflares do
   begin
    v:=udMatrixMultiplyVector(m, flares[x] );
//    if v.z>1 then
    begin
      p:=udMatrixProject(v, zoom);
//      if v.z*65535>zbuf[p.x+p.y*320] then
        flare(p.x,p.y,10,vscr);
    end;
   end;
  
  
{$ELSE}

 for x:=0 to numobjects do
  for y:=0 to objects[x].numvertex do
  begin
   v:=udMatrixMultiplyVector(m, objects[x].temp_vertex[y].vec );
   if (v.z>1) then
   begin
    p:=udMatrixProject(v, zoom);
    if (p.x>0) and (p.x<320) and (p.y>0) and (p.y<200) then pdword(vscr+(320-p.x+p.y*320)*4)^:=$FFFFFFFF;
   end;
  end;

{$ENDIF}

{
  v:=udMatrixMultiplyVector(m, objects[2].pivot);
   if v.z>1 then
   begin
    p:=udMatrixProject(v, zoom);
    if (p.x>0) and (p.x<320) and (p.y>0) and (p.y<200) then pdword(vscr+(p.x+p.y*320)*4)^:=$000088FF;
   end;
}

end;

BEGIN
END.