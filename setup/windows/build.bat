SET VERSION=1.2.0

"C:\Program Files (x86)\NSIS\makensis.exe" /DVERSION=%VERSION% /DGAMELANG=ru /DUPPERLANG=RU Trixie16bit.nsi
"C:\Program Files (x86)\NSIS\makensis.exe" /DVERSION=%VERSION% /DGAMELANG=en /DUPPERLANG=EN Trixie16bit.nsi

call create_zip32.bat ru RU
call create_zip32.bat en EN
