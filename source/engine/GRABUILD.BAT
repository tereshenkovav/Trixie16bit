@echo off
rem build asm part
C:\nasm\nasm.exe -f obj gratools.asm
rename gratools.obj asmtools.obj

rem build bas part
bc gratools.bas gratools.obj,NUL

rem make qlb and lib
link /q gratools.obj+asmtools.obj, gratools.qlb, NUL, bqlb45.lib
del gratools.lib
lib gratools.lib+gratools.obj+asmtools.obj,NUL

rem remove objs
del gratools.obj
del asmtools.obj
