if NOT "%~1" == "" goto mainproc

echo "Argument - lang code" 
exit

:mainproc

rm -f Trixie16bit-%2-%VERSION%-DOSBox-Win32.zip
7z a -mx9 Trixie16bit-%2-%VERSION%-DOSBox-Win32.zip ..\..\bin
cd dosbox
7z a -mx9 ..\Trixie16bit-%2-%VERSION%-DOSBox-Win32.zip *
cd ..

SET TMPDIR=%TEMP%\ZKJd62lksLsM3
mkdir %TMPDIR%\bin\data
echo %1 > %TMPDIR%\bin\data\deflang

7z a -mx9 Trixie16bit-%2-%VERSION%-DOSBox-Win32.zip %TMPDIR%\bin
