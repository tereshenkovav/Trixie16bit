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

call create_zip16.bat ru RU
call create_zip16.bat en EN
