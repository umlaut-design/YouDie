procedure blur;
var w:dword;
    q:byte;
begin
   for w:=320 to (320*199-1) do
    vscr[w].dw:=(vscr[w-1].b+vscr[w+1  ].b+vscr[w-320].b+vscr[w+320].b) shr 2 shl 16+
                (vscr[w-1].g+vscr[w+1  ].g+vscr[w-320].g+vscr[w+320].g) shr 2 shl 8+
                (vscr[w-1].r+vscr[w+1  ].r+vscr[w-320].r+vscr[w+320].r) shr 2;
end;

procedure blur_side;
var w:dword;
    q:byte;
begin
   for w:=1 to (320*199-1) do
     vscr[w].dw:=(vscr[w-1].b+vscr[w+1].b) shr 1 shl 16+
                 (vscr[w-1].g+vscr[w+1].g) shr 1 shl 8+
                 (vscr[w-1].r+vscr[w+1].r) shr 1;
end;
