@echo off
set CFILE=YouDie

del compile.txt
del %CFILE%.exe
cls

if not "%1"=="-final" set D=-dDBG

ppc386.exe %CFILE%.pas -Fecompile.txt -FuUNITS -FuUNITS.3ds -FuUNITS.zip -B -Ct- -Og3p3 -WN %D%

if exist %CFILE%.exe goto fordul
type compile.txt

:fordul
del *.ow  > NUL
del units\*.ow  > NUL
del units\*.ppw > NUL
del units.zip\*.ow  > NUL
del units.zip\*.ppw > NUL
del units.3ds\*.ow  > NUL
del units.3ds\*.ppw > NUL
ren %CFILE%.exe %CFILE%.exe

if not "%1"=="-final" goto end

copy YouDie_d.dat !encode\YouDie_d.dat
cd !encode
encode
cd ..
copy !encode\YouDie.dat YouDie.dat
rem upx.exe -9 --crp-ms=999999 YouDie.exe

:end

