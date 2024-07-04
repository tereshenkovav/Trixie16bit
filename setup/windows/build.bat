@echo off
for /F %%i in ('git tag --list --sort=committerdate') do set BUILDTAG=%%i
for /F %%i in ('git rev-parse HEAD') do set BUILDCOMMIT=%%i
set BUILDCOMMIT=%BUILDCOMMIT:~0,8%
for /F %%i in ('git branch --show-current') do set BUILDBRANCH=%%i

echo %BUILDTAG% %BUILDCOMMIT% %BUILDBRANCH%

echo %BUILDTAG% > ..\..\bin\data\version.txt
echo %BUILDCOMMIT% >> ..\..\bin\data\version.txt
echo %BUILDBRANCH% >> ..\..\bin\data\version.txt

SET VERSION=%BUILDTAG:~1%

"C:\Program Files (x86)\NSIS\makensis.exe" /DVERSION=%VERSION% /DGAMELANG=ru /DUPPERLANG=RU Trixie16bit.nsi
"C:\Program Files (x86)\NSIS\makensis.exe" /DVERSION=%VERSION% /DGAMELANG=en /DUPPERLANG=EN Trixie16bit.nsi

del ..\..\bin\data\deflang

SmartZipBuilder.exe script.szb /LANGL=ru /LANGH=RU
SmartZipBuilder.exe script.szb /LANGL=en /LANGH=EN
