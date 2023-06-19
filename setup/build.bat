SET VERSION=1.1.0

"C:\Programs\NSIS\makensis.exe" trixie16bit.nsi

call create_zip32.bat ru RU
call create_zip32.bat en EN

call create_zip16.bat ru RU
call create_zip16.bat en EN
