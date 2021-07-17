{$ASMMODE INTEL}
unit udDD32;

// ----------------------------------------------------------------------
interface

uses windows, DirectDraw, DirectDrawFPC, debug;

const udDXEscape:boolean=false;
const udDXSpace :boolean=false;

var hW:hWnd;
    bpp:byte;
   
procedure udDD32CreateWindow(xRez,yRez:word; fullscreen:boolean);
procedure udDD32Blit(vscr:pointer);

// ----------------------------------------------------------------------
implementation

var g_pDDS1,g_pDDS2:IDirectDrawSurface4;
    clipper:IDirectDrawClipper;
    wta:longint;
    full:boolean;
    recwind,recscreen,recvp:RECT;    
    xr,yr:dword;

function WindowProc(h_Wnd: HWND; aMSG: Cardinal; wParam: Cardinal; lParam: LongInt) : LongInt; stdcall;
var minmax:PMINMAXINFO;
begin

  case aMSG of
 	  WM_GETMINMAXINFO:
  	  begin
  	    minmax := PMINMAXINFO(lparam);
        MinMax^.ptMinTrackSize.x := xr+GetSystemMetrics(SM_CXSIZEFRAME)*2;
        MinMax^.ptMinTrackSize.y := yr+GetSystemMetrics(SM_CYSIZEFRAME)*2+GetSystemMetrics(SM_CYMENU);
        MinMax^.ptMaxTrackSize.x := MinMax^.ptMinTrackSize.x;
        MinMax^.ptMaxTrackSize.y := MinMax^.ptMinTrackSize.y;
      end;
    // Clean up and close the app
    WM_DESTROY:
      begin
        PostQuitMessage(0);
        Exit;
      end;
    WM_MOVE:
      begin
        GetWindowRect(hW, recwind);
      	GetClientRect(hW, recvp);
      	GetClientRect(hW, recscreen);
      	ClientToScreen(hW, lppoint(@recscreen.left));
      	ClientToScreen(hW, lppoint(@recscreen.right));
      end;

    // Handle any non-accelerated key commands

     WM_KEYDOWN:
      begin
        case wParam of

            VK_ESCAPE:
            begin
              udDXEscape:=true;
              exit;
            end;
          VK_SPACE:
            begin
              udDXSpace:=true;
            end;
        end;
      end;

    end;
  
 WindowProc:=DefWindowProc(h_Wnd, aMSG, wParam, lParam);
end;

procedure udDD32CreateWindow(xRez,yRez:word; fullscreen:boolean);
var g_pDD  :IDirectDraw4;
    hRet   :HRESULT;
    pDDtemp:IDirectDraw;
    wc     :WNDCLASS;
    ddsd   :TDDSurfaceDesc2;
    ddscaps:TDDSCaps2;
    style:dword;
    dc:HDC;
    cx,cy:dword;
Begin
  full:=fullscreen;
  xr:=xrez;  
  yr:=yrez;  

  wc.style := CS_HREDRAW or CS_VREDRAW;
  wc.lpfnWndProc := @WindowProc;
  wc.cbClsExtra := 0;
  wc.cbWndExtra := 0;
  wc.hInstance := System.MainInstance;
  wc.hIcon := LoadIcon( 0, IDI_Application );
  wc.hCursor := LoadCursor(0, IDC_ARROW);
  wc.hbrBackground := GetStockObject(BLACK_BRUSH);
  wc.lpszMenuName := 'Window name';
  wc.lpszClassName := 'wndclass';

  RegisterClass(wc);

  if fullscreen then begin
    style:=WS_VISIBLE or WS_POPUP;
    cx := 0;
    cy := 0;
  end
  else
  begin
    style:=WS_OVERLAPPEDWINDOW and not WS_MAXIMIZEBOX and not WS_MINIMIZEBOX and not WS_SYSMENU;
    cx := (GetSystemMetrics(SM_CXSCREEN) - xrez) div 2;
    cy := (GetSystemMetrics(SM_CYSCREEN) - yrez) div 2;
  end;
  
  hW := CreateWindowEx(0,
                          'wndclass',
                          'Ümlaüt DirectDraw Handler',
                          style,
                          cx,
                          cy,
                          xrez,
                          yrez,
                          0,
                          0,
                          System.MainInstance,
                          nil);

  if hW=0 then
  begin
      MessageBox( 0,'CreateWindowEx FAILED',nil,mb_Ok );
      Halt(0);
  end;

  ShowWindow(hW, Sw_Show);
  UpdateWindow(hW);
  SetFocus(hW);
  if fullscreen then ShowCursor(FALSE)
  else SetWindowPos(hW,HWND_TOPMOST,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE);

  hRet := DirectDrawCreate(nil, pDDTemp, nil);
  if hRet <> DD_OK then
    begin
      MessageBox( hW,'DirectDrawCreate FAILED',nil,mb_Ok );
      Halt(0);
    end;

  hRet := IDirectDraw_QueryInterface(pDDTemp, IID_IDirectDraw4, g_pDD);
  if hRet <> DD_OK then
    begin
      MessageBox( hW,'QueryInterface FAILED',nil,mb_Ok );
      Halt(0);
    end;
  pDDTemp := nil;
    
  if fullscreen then
  begin
    // ======================================================
    // FULLSCREEN
    // ======================================================
    hRet := IDirectDraw4_SetCooperativeLevel(g_pDD, hW, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
    if hRet <> DD_OK then
      begin
        MessageBox( hW,'SetCooperativeLevel FAILED',nil,mb_Ok );
        Halt(0);
      end;
  
    bpp:=32;
    hRet := IDirectDraw4_SetDisplayMode(g_pDD, xRez, yRez, bpp, 0, 0);
    if hRet <> DD_OK then
    begin
     bpp:=24;
     hRet := IDirectDraw4_SetDisplayMode(g_pDD, xRez, yRez, bpp, 0, 0);
     if hRet <> DD_OK then
     begin
      bpp:=16;
      hRet := IDirectDraw4_SetDisplayMode(g_pDD, xRez, yRez, bpp, 0, 0);
      if hRet <> DD_OK then
      begin
         MessageBox( hW,'SetDisplayMode FAILED',nil,mb_Ok );
         Halt(0);    
      end;
      FillChar(ddsd, SizeOf(ddsd), 0);
      ddsd.dwSize := SizeOf(ddsd);
      IDirectDraw4_GetDisplayMode(g_pDD, ddsd);
      if ddsd.ddpfPixelFormat.dwRBitMask = $7c00 then bpp:=15
      else if ddsd.ddpfPixelFormat.dwRBitMask <> $f800 then begin
         MessageBox( hW,'SetDisplayMode FAILED (unknown pixel format)',nil,mb_Ok );
         Halt(0);    
      end;
     end;
    end;

  // Create the primary surface with 1 back buffer
    FillChar(ddsd, SizeOf(ddsd), 0);
    ddsd.dwSize := SizeOf(ddsd);
    ddsd.dwFlags := DDSD_CAPS or DDSD_BACKBUFFERCOUNT;
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_FLIP or DDSCAPS_COMPLEX or DDSCAPS_VIDEOMEMORY;
  
    ddsd.dwBackBufferCount := 1;
    hRet := IDirectDraw4_CreateSurface(g_pDD, ddsd, g_pDDS1, nil);
    if hRet <> DD_OK then
      begin
       if hRet <> DD_OK then
        begin
         MessageBox( hW,'CreateSurface FAILED',nil,mb_Ok );
         Halt(0);
        end;
      end;
  
    // Get a pointer to the back buffer
    FillChar(ddscaps, SizeOf(ddscaps), 0);
    ddscaps.dwCaps := DDSCAPS_BACKBUFFER;
    hRet := IDirectDrawSurface4_GetAttachedSurface(g_pDDS1, ddscaps, g_pDDS2);
    if hRet <> DD_OK then
      begin
        MessageBox( hW,'GetAttachedSurface FAILED',nil,mb_Ok );
        Halt(0);
      end;
  end
  else
  begin
    // ======================================================
    // WINDOWED
    // ======================================================
    bpp:=GetDeviceCaps(GetDC(hW),BITSPIXEL);
    //bpp:=32;
    hRet := IDirectDraw4_SetCooperativeLevel(g_pDD, hW, DDSCL_NORMAL);
    if hRet <> DD_OK then
      begin
        MessageBox( hW,'SetCooperativeLevel FAILED',nil,mb_Ok );
        Halt(0);
      end;

  	GetClientRect(hW, recvp);
  	GetClientRect(hW, recscreen);
  	ClientToScreen(hW, lppoint(@recscreen.left));
  	ClientToScreen(hW, lppoint(@recscreen.right));

    FillChar(ddsd, SizeOf(ddsd), 0);
    ddsd.dwSize := SizeOf(ddsd);
    ddsd.dwFlags := DDSD_CAPS;
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
    hRet := IDirectDraw4_CreateSurface(g_pDD, ddsd, g_pDDS1, nil);
    if hRet <> DD_OK then
      begin
       MessageBox( hW,'CreateSurface FAILED',nil,mb_Ok );
       Halt(0);
      end;
  
    hRet := IDirectDraw4_CreateClipper(g_pDD, 0, clipper, nil);
    if hRet <> DD_OK then
      begin
       MessageBox( hW,'CreateClipper FAILED',nil,mb_Ok );
       Halt(0);
      end;
  
    hRet:=IDirectDrawClipper_SetHWnd(clipper, 0, hW);
    if hRet <> DD_OK then
      begin
       MessageBox( hW,'SetHWnd FAILED',nil,mb_Ok );
       Halt(0);
      end;

    hRet:=IDirectDrawSurface4_SetClipper(g_pDDS1, clipper);
    if hRet <> DD_OK then
      begin
       MessageBox( hW,'SetClipper FAILED',nil,mb_Ok );
       Halt(0);
      end;
    
    IDirectDrawClipper_Release(clipper);
    
    FillChar(ddsd, SizeOf(ddsd), 0);
    ddsd.dwSize := SizeOf(ddsd);
    ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_CAPS;
    ddsd.dwWidth := xRez;
    ddsd.dwHeight:= yRez;
    ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
    hRet := IDirectDraw4_CreateSurface(g_pDD, ddsd, g_pDDS2, nil);
    if hRet <> DD_OK then
      begin
       MessageBox( hW,'CreateSurface2 FAILED',nil,mb_Ok );
       Halt(0);
      end;

    SetWindowPos(hW,HWND_TOPMOST,0,0,0,0,SWP_SHOWWINDOW or SWP_NOMOVE or SWP_NOSIZE);
  
  end;
  
end;

procedure udDD32Blit(vscr:pointer);
var hRet  :HRESULT;
    ddsd  :TDDSurfaceDesc2;
begin

 FillChar(ddsd, SizeOf(ddsd), 0);
 ddsd.dwSize := SizeOf(ddsd);
 hret:=IDirectDrawSurface4_Lock(g_pDDS2,nil,ddsd,DDLOCK_WAIT or DDLOCK_SURFACEMEMORYPTR,0);

  if hRet <> DD_OK then
    begin
      MessageBox( hW,'Lock FAILED',nil,mb_Ok );
      Halt;
    end;

 wta:=ddsd.lPitch-ddsd.dwWidth*((bpp+1) div 8); // mivel az 555-os 16 bites modhoz 15 van beallitva!

 case bpp of
   32:asm
       push  es
       mov   ax,ds
       mov   es,ax
       mov   esi,[vscr]
       mov   edi,[ddsd.lpSurface]
       mov   ecx,[ddsd.dwHeight]
          @oneline32:
       push  ecx
       mov   ecx,[ddsd.dwWidth]
       rep   movsd
       add   edi,[wta]
       pop   ecx  
       loop  @oneline32
       pop   es
      end;
   24:asm
       push  es
       mov   ax,ds
       mov   es,ax
       mov   esi,[vscr]
       mov   edi,[ddsd.lpSurface]
       mov   ecx,[ddsd.dwHeight]
          @oneline24:
       push  ecx
       mov   ecx,[ddsd.dwWidth]
          @onepix24:
       movsw
       movsb
       inc   esi
       loop  @onepix24
       add   edi,[wta]
       pop   ecx  
       loop  @oneline24
       pop   es
      end;
   16:asm
       push  es
       mov   ax,ds
       mov   es,ax
       mov   esi,[vscr]
       mov   edi,[ddsd.lpSurface]
       mov   ecx,[ddsd.dwHeight]
          @oneline16:
       push  ecx
       mov   ecx,[ddsd.dwWidth]
          @onepix16:
       lodsd
       shr   ax,2
       shl   al,2
       shr   ax,3
       mov   bx,ax
       shr   eax,8
       and   ax,1111100000000000b
       or    ax,bx
       stosw
       loop  @onepix16
       add   edi,[wta]
       pop   ecx
       loop  @oneline16
       pop   es
      end;
   15:asm
       push  es
       mov   ax,ds
       mov   es,ax
       mov   esi,[vscr]
       mov   edi,[ddsd.lpSurface]
       mov   ecx,[ddsd.dwHeight]
          @oneline15:
       push  ecx
       mov   ecx,[ddsd.dwWidth]
          @onepix15:
       lodsd
       shr   ax,3
       shl   al,3
       shr   ax,3
       mov   bx,ax
       shr   eax,9
       and   ax,0111110000000000b
       or    ax,bx
       stosw
       loop  @onepix15
       add   edi,[wta]
       pop   ecx
       loop  @oneline15
       pop   es
      end;
 end;

 hret:=IDirectDrawSurface4_Unlock(g_pDDS2, 0);
  if hRet <> DD_OK then
    begin
      MessageBox( hW,'UnLock FAILED',nil,mb_Ok );
      Halt;
    end;

 if full then
 begin
   hRet := IDirectDrawSurface4_Flip(g_pDDS1, nil, DDFLIP_WAIT);
    if hRet <> DD_OK then
      begin
        MessageBox( hW,'Flip FAILED',nil,mb_Ok );
        Halt(0);
      end;
 end
 else
 begin  
//  recscreen.right:=160;
//  recvp.bottom:=200;
  hRet := IDirectDrawSurface4_Blt(g_pDDS1,@recscreen,g_pDDS2,@recvp,0,nil);
//  hRet := IDirectDrawSurface4_Blt(g_pDDS1,nil,g_pDDS2,nil,0,nil);
    if hRet <> DD_OK then
      begin
        MessageBox( hW,'Blt FAILED',nil,mb_Ok );
        Halt(0);
      end;
 end;
 
end;

BEGIN
END.
