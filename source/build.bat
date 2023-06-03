@echo off

bc trixie.bas trixie.obj,NUL

link /noe trixie.obj+noem.obj,game_fpu.exe,NUL,gratools.lib+bcom45.lib
link /noe trixie.obj,game.exe,NUL,gratools.lib+bcom45.lib

