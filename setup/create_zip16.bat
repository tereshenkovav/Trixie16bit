if NOT "%~1" == "" goto mainproc

echo "Argument - lang code" 
exit

:mainproc

rm -f Trixie16bit-%2-1.0.0-DOS.zip
cd ..\bin
7z a -mx9 ..\setup\Trixie16bit-%2-1.0.0-DOS.zip *
cd ..\setup

SET TMPDIR=%TEMP%\Ut762flqP0cx
mkdir %TMPDIR%\data
echo %1 > %TMPDIR%\data\deflang

7z a -mx9 Trixie16bit-%2-1.0.0-DOS.zip %TMPDIR%\data
