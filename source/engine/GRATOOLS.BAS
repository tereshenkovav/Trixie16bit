'$INCLUDE: 'gratools.bi'

DEFINT A-Z

DIM SHARED PalStart AS INTEGER
DIM SHARED NewPal(255) AS LONG
DIM SHARED NextFreePal AS INTEGER
DIM SHARED isdebug AS INTEGER
DIM SHARED timerfix AS SINGLE
DIM SHARED ticksfix AS INTEGER
DIM SHARED currentfps AS INTEGER
DIM SHARED debugFileN AS INTEGER

CONST TRANSPCOLOR = 255
CONST MODSPRITE = 1
CONST MODANIM = 2

SUB copyBuffer (bufsrc() AS INTEGER, bufdst() AS INTEGER, w AS INTEGER, h AS INTEGER)
  CALL copyBufferAsm(VARPTR(bufsrc(0)), VARSEG(bufsrc(0)), VARPTR(bufdst(0)), VARSEG(bufdst(0)), w, h)
END SUB

SUB directLoadPicToBuf (buf() AS INTEGER, FileName AS STRING, usedpal() AS ColorRGB, usedpalcount AS INTEGER)

    IF isdebug = 1 THEN PRINT "Direct load " + FileName
    DIM Poz AS LONG

    OPEN FileName FOR BINARY AS #1

    Window$ = "********"

    GET #1, 5, Window$

    DIM XMax AS INTEGER
    DIM YMax AS INTEGER

    XMax = 256 * ASC(MID$(Window$, 6, 1)) + ASC(MID$(Window$, 5, 1))
    YMax = 256 * ASC(MID$(Window$, 8, 1)) + ASC(MID$(Window$, 7, 1))
       
    Ps$ = "*"
    Poz = 129

   DIM bufp AS LONG
   buf(0) = 8 * (XMax + 1)
   buf(1) = YMax + 1

   DEF SEG = VARSEG(buf(2))
   bufp = VARPTR(buf(2))

   DIM Num AS INTEGER
   Poz = 129
   MaxPalN = 0
   DO
     GET #1, Poz, Ps$
     Num = ASC(Ps$)
     IF Num >= 192 THEN
      Des = Num - 192
      GET #1, Poz + 1, Ps$
      Num = ASC(Ps$)
      FOR x = Xt TO Xt + Des - 1
        POKE bufp, PalStart + Num
        bufp = bufp + 1
      NEXT x
      IF MaxPalN < Num THEN MaxPalN = Num
      Xt = Xt + Des
      Poz = Poz + 2
     ELSE
      POKE bufp, PalStart + Num
      bufp = bufp + 1
      IF MaxPalN < Num THEN MaxPalN = Num
      Xt = Xt + 1
      Poz = Poz + 1
     END IF
 
     IF Xt > XMax THEN
      Xt = 0
      Yt = Yt + 1
     END IF
     IF Yt = YMax + 1 THEN EXIT DO

   LOOP

   DEF SEG

    Red$ = "*"
    Green$ = "*"
    Blue$ = "*"
  
    Poz = LOF(1) - 768 + 1
  
    FOR c = 0 TO MaxPalN
     GET #1, Poz, Red$: GET #1, Poz + 1, Green$: GET #1, Poz + 2, Blue$
     Poz = Poz + 3

     Red = ASC(Red$) \ 4: Green = ASC(Green$) \ 4: Blue = ASC(Blue$) \ 4

     IF PalStart + c >= 256 THEN EXIT FOR
     ' disable set up palette in function - we use appear by brightness
     'PALETTE PalStart + c, 65536 * Blue + 256 * Green + Red
     usedpal(c).r = Red
     usedpal(c).g = Green
     usedpal(c).b = Blue
    NEXT c
    usedpalcount = MaxPalN + 1

   CLOSE #1

END SUB

SUB drawAnimation (buf() AS INTEGER, Sprite() AS INTEGER, Anim AS Animation, x AS INTEGER, y AS INTEGER)
  DIM p AS LONG
  p = Anim.BufPos + Anim.BytesPerFrame * Anim.TekFrame
  CALL drawSpriteAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(p)), VARSEG(Sprite(p)), x, y, 0)
END SUB

SUB drawAnimationMirror (buf() AS INTEGER, Sprite() AS INTEGER, Anim AS Animation, x AS INTEGER, y AS INTEGER)
  DIM p AS LONG
  p = Anim.BufPos + Anim.BytesPerFrame * Anim.TekFrame
  CALL drawSpriteMirrorAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(p)), VARSEG(Sprite(p)), x, y, 0)
END SUB

SUB drawAnimationTransp (buf() AS INTEGER, Sprite() AS INTEGER, Anim AS Animation, x AS INTEGER, y AS INTEGER)
  DIM p AS LONG
  p = Anim.BufPos + Anim.BytesPerFrame * Anim.TekFrame
  CALL drawSpriteAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(p)), VARSEG(Sprite(p)), x, y, 1)
END SUB

SUB drawAnimationTranspMirror (buf() AS INTEGER, Sprite() AS INTEGER, Anim AS Animation, x AS INTEGER, y AS INTEGER)
  DIM p AS LONG
  p = Anim.BufPos + Anim.BytesPerFrame * Anim.TekFrame
  CALL drawSpriteMirrorAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(p)), VARSEG(Sprite(p)), x, y, 1)
END SUB

SUB drawLineHorz (buf() AS INTEGER, x1 AS INTEGER, X2 AS INTEGER, y AS INTEGER, c AS INTEGER)
  CALL drawLineHorzAsm(VARPTR(buf(0)), VARSEG(buf(0)), x1, X2, y, c)
END SUB

SUB drawLineVert (buf() AS INTEGER, x AS INTEGER, y1 AS INTEGER, Y2 AS INTEGER, c AS INTEGER)
  CALL drawLineVertAsm(VARPTR(buf(0)), VARSEG(buf(0)), x, y1, Y2, c)
END SUB

SUB drawSprite (buf() AS INTEGER, Sprite() AS INTEGER, SpritePos AS LONG, x AS INTEGER, y AS INTEGER)
  CALL drawSpriteAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(SpritePos)), VARSEG(Sprite(SpritePos)), x, y, 0)
END SUB

SUB drawSpriteMirror (buf() AS INTEGER, Sprite() AS INTEGER, SpritePos AS LONG, x AS INTEGER, y AS INTEGER)
  CALL drawSpriteMirrorAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(SpritePos)), VARSEG(Sprite(SpritePos)), x, y, 0)
END SUB

SUB drawSpriteTransp (buf() AS INTEGER, Sprite() AS INTEGER, SpritePos AS LONG, x AS INTEGER, y AS INTEGER)
  CALL drawSpriteAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(SpritePos)), VARSEG(Sprite(SpritePos)), x, y, 1)
END SUB

SUB drawSpriteTranspMirror (buf() AS INTEGER, Sprite() AS INTEGER, SpritePos AS LONG, x AS INTEGER, y AS INTEGER)
  CALL drawSpriteMirrorAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(Sprite(SpritePos)), VARSEG(Sprite(SpritePos)), x, y, 1)
END SUB

SUB drawString (buf() AS INTEGER, font() AS INTEGER, x AS INTEGER, y AS INTEGER, text AS STRING, colr AS INTEGER)
  
  FOR i = 1 TO LEN(text)
    CALL drawCharAsm(VARPTR(buf(0)), VARSEG(buf(0)), VARPTR(font(0)), VARSEG(font(0)), x + (i - 1) * 8, y, ASC(MID$(text, i, 1)), colr)
  NEXT i

END SUB

SUB enableDebug
  isdebug = 1
END SUB

SUB fillRect (buf() AS INTEGER, x1 AS INTEGER, y1 AS INTEGER, w AS INTEGER, h AS INTEGER, c AS INTEGER)
  CALL fillRectAsm(VARPTR(buf(0)), VARSEG(buf(0)), x1, y1, w, h, c)
END SUB

FUNCTION getBufferReport$ (buf() AS INTEGER, MaxSize AS LONG)
 
  DIM Handle AS LONG
  Handle = buf(0) * 256 + buf(1)

  DIM s AS STRING
  s = s + "Handle: " + STR$(Handle) + " /" + STR$(MaxSize)
  s = s + " (" + STR$(CINT(100 * Handle / MaxSize)) + " %)"
  getBufferReport$ = s

END FUNCTION

FUNCTION getFPS%
  getFPS% = currentfps
END FUNCTION

FUNCTION getLoaderReport$

  DIM s AS STRING
  s = "NextFreePal:" + STR$(NextFreePal) + CHR$(13)
  s = s + "Used colors: " + STR$(NextFreePal - PalStart)
  s = s + " /" + STR$(255 - PalStart)
  getLoaderReport$ = s

END FUNCTION

SUB getMouse (MouseX AS INTEGER, MouseY AS INTEGER, ButLeft AS INTEGER, ButRight AS INTEGER)
  DIM MouseBuf(3) AS INTEGER

  CALL getMouseAsm(VARPTR(MouseBuf(0)), VARSEG(MouseBuf(0)))
  MouseX = MouseBuf(0)
  MouseY = MouseBuf(1)
  IF (MouseBuf(2) AND 1) = 1 THEN ButLeft = 1 ELSE ButLeft = 0
  IF (MouseBuf(2) AND 2) = 2 THEN ButRight = 1 ELSE ButRight = 0
END SUB

SUB initSpriteBuf (buf() AS INTEGER)
  buf(0) = 0
  buf(1) = 2
END SUB

SUB internalLoadAllInBuf (buf() AS INTEGER, Sprite AS Sprite, Anim AS Animation, mode AS INTEGER, FileName AS STRING, FrameCount AS INTEGER, FPS AS INTEGER, TranspX AS INTEGER, TranspY AS INTEGER, SetGray AS INTEGER)

    DIM Handle AS LONG
    Handle = buf(0) * 256 + buf(1)

    IF isdebug = 1 THEN PRINT "Load " + FileName
    DIM Poz AS LONG

    OPEN FileName FOR BINARY AS #1

    Window$ = "********"

    GET #1, 5, Window$

    DIM XMax AS INTEGER
    DIM YMax AS INTEGER

    XMax = 256 * ASC(MID$(Window$, 6, 1)) + ASC(MID$(Window$, 5, 1))
    YMax = 256 * ASC(MID$(Window$, 8, 1)) + ASC(MID$(Window$, 7, 1))
        
    Ps$ = "*"
    Poz = 129

   DIM Pic(XMax + 1, YMax + 1) AS INTEGER

   DIM Num AS INTEGER
   Poz = 129
   MaxPalN = 0
   DO
     GET #1, Poz, Ps$
     Num = ASC(Ps$)
     IF Num >= 192 THEN
      Des = Num - 192
      GET #1, Poz + 1, Ps$
      Num = ASC(Ps$)
      FOR x = Xt TO Xt + Des - 1
        Pic(x, Yt) = Num
      NEXT x
      IF MaxPalN < Num THEN MaxPalN = Num
      Xt = Xt + Des
      Poz = Poz + 2
     ELSE
      Pic(Xt, Yt) = Num
      IF MaxPalN < Num THEN MaxPalN = Num
      Xt = Xt + 1
      Poz = Poz + 1
     END IF
  
     IF Xt > XMax THEN
      Xt = 0
      Yt = Yt + 1
     END IF
     IF Yt = YMax + 1 THEN EXIT DO

   LOOP

    Red$ = "*"
    Green$ = "*"
    Blue$ = "*"
   
    Poz = LOF(1) - 768 + 1
   
    DIM PcxPal(0 TO MaxPalN) AS LONG

    FOR c = 0 TO MaxPalN
     GET #1, Poz, Red$: GET #1, Poz + 1, Green$: GET #1, Poz + 2, Blue$
     Poz = Poz + 3

     Red = ASC(Red$) \ 4: Green = ASC(Green$) \ 4: Blue = ASC(Blue$) \ 4

     IF SetGray = 1 THEN
       Sum = (Red + Green + Blue) \ 3
       Red = Sum: Green = Sum: Blue = Sum
     END IF

     PcxPal(c) = 65536 * Blue + 256 * Green + Red
    NEXT c

   CLOSE #1

   ' palitra process
   usetransp = 0
   IF TranspX <> -1 THEN
     usetransp = 1
     transpidx = Pic(TranspX, TranspY)
   END IF

   DIM NewIndex(0 TO MaxPalN) AS INTEGER
  
   nextidx = NextFreePal
   FOR c = 0 TO MaxPalN
     IF usetransp = 1 AND c = transpidx THEN
       NewIndex(c) = TRANSPCOLOR
     ELSE
       findidx = -1
       FOR j = PalStart TO nextidx - 1
         IF NewPal(j) = PcxPal(c) THEN findidx = j
       NEXT j
       IF findidx = -1 THEN
         NewPal(nextidx) = PcxPal(c)
         NewIndex(c) = nextidx
         nextidx = nextidx + 1
       ELSE
         NewIndex(c) = findidx
       END IF
     END IF
   NEXT c
   NextFreePal = nextidx

   ' update pic array
   FOR x = 0 TO XMax
     FOR y = 0 TO YMax
       Pic(x, y) = NewIndex(Pic(x, y))
     NEXT y
   NEXT x
  
    doPalLog = 0
    debugFileN = debugFileN + 1
    IF doPalLog = 1 THEN
      OPEN STR$(debugFileN) + ".log" FOR OUTPUT AS #3
      PRINT #3, FileName
      PRINT #3, "usetransp", usetransp
      PRINT #3, "transpidx", transpidx
      PRINT #3, MaxPalN
      FOR i = 0 TO MaxPalN
         PRINT #3, i, PcxPal(i), NewIndex(i)
      NEXT i
      CLOSE #3
    END IF

   DIM bufp AS LONG
   IF mode = MODSPRITE THEN
    Sprite.BufPos = Handle
   
    Sprite.w = (XMax + 1)
    Sprite.h = (YMax + 1)

    buf(Handle) = 8 * Sprite.w
    buf(Handle + 1) = Sprite.h

    DEF SEG = VARSEG(buf(Handle + 2))
    bufp = VARPTR(buf(Handle + 2))
    FOR y = 0 TO Sprite.h
       FOR x = 0 TO Sprite.w - 1
          POKE bufp, Pic(x, y)
          bufp = bufp + 1
       NEXT x
    NEXT y
    DEF SEG

    Handle = Handle + 2 + (Sprite.w * Sprite.h) \ 2 + 1
  ELSE
    Anim.BufPos = Handle
  
    Anim.w = (XMax + 1) \ FrameCount
    Anim.h = (YMax + 1)
    Anim.FrameCount = FrameCount
    Anim.FPS = FPS
    Anim.Ticks = 0
    Anim.BytesPerFrame = 2 + (Anim.w * Anim.h) \ 2 + 1

    FOR f = 0 TO FrameCount - 1
      buf(Handle) = 8 * Anim.w
      buf(Handle + 1) = Anim.h

      DEF SEG = VARSEG(buf(Handle + 2))
      bufp = VARPTR(buf(Handle + 2))
      FOR y = 0 TO Anim.h
         FOR x = 0 TO Anim.w - 1
            POKE bufp, Pic(x + Anim.w * f, y)
            bufp = bufp + 1
         NEXT x
      NEXT y
      DEF SEG

      Handle = Handle + Anim.BytesPerFrame
    NEXT f
  END IF
 
  buf(0) = Handle \ 256: buf(1) = Handle MOD 256

END SUB

SUB LoadAnimationInBuf (buf() AS INTEGER, Anim AS Animation, FileName AS STRING, FrameCount AS INTEGER, FPS AS INTEGER)
   CALL LoadTranspAnimationInBuf(buf(), Anim, FileName, FrameCount, FPS, -1, -1)
END SUB

SUB loadFont (buf() AS INTEGER, FileName AS STRING)

  s$ = "*"

  OPEN FileName FOR BINARY AS #1

  DEF SEG = VARSEG(buf(0))
  DIM bufp AS LONG
  bufp = VARPTR(buf(0))
  Poz = 1
  FOR i = 0 TO 255
    FOR y = 0 TO 7
      GET #1, Poz, s$
      Poz = Poz + 1
      POKE bufp, ASC(MID$(s$, 1, 1))
      bufp = bufp + 1
    NEXT y
  NEXT i
  DEF SEG

  CLOSE #1

END SUB

SUB LoadSpriteInBuf (buf() AS INTEGER, Sprite AS Sprite, FileName AS STRING)
   CALL LoadTranspSpriteInBuf(buf(), Sprite, FileName, -1, -1)
END SUB

SUB LoadTranspAnimationInBuf (buf() AS INTEGER, Anim AS Animation, FileName AS STRING, FrameCount AS INTEGER, FPS AS INTEGER, TranspX AS INTEGER, TranspY AS INTEGER)
  DIM Sprite AS Sprite
  CALL internalLoadAllInBuf(buf(), Sprite, Anim, MODANIM, FileName, FrameCount, FPS, TranspX, TranspY, 0)
END SUB

SUB LoadTranspGrayedSpriteInBuf (buf() AS INTEGER, Sprite AS Sprite, FileName AS STRING, TranspX AS INTEGER, TranspY AS INTEGER)
  DIM Anim AS Animation
  CALL internalLoadAllInBuf(buf(), Sprite, Anim, MODSPRITE, FileName, 1, 1, TranspX, TranspY, 1)
END SUB

SUB LoadTranspSpriteInBuf (buf() AS INTEGER, Sprite AS Sprite, FileName AS STRING, TranspX AS INTEGER, TranspY AS INTEGER)
  DIM Anim AS Animation
  CALL internalLoadAllInBuf(buf(), Sprite, Anim, MODSPRITE, FileName, 1, 1, TranspX, TranspY, 0)
END SUB

SUB ResetSpriteLoader (ReservedColorCount AS INTEGER)
  IF isdebug = 1 THEN PRINT "Start loader"
  PalStart = ReservedColorCount
  NextFreePal = ReservedColorCount
  Handle = 0
END SUB

FUNCTION RGB2Pal& (rgb AS ColorRGB)
   RGB2Pal& = 65536 * rgb.b + 256 * rgb.g + rgb.r
END FUNCTION

SUB SetBrightRGB (rgb AS ColorRGB, bright AS SINGLE)
   rgb.r = CINT(rgb.r * bright)
   rgb.g = CINT(rgb.g * bright)
   rgb.b = CINT(rgb.b * bright)
END SUB

SUB setMouseWindow (x1 AS INTEGER, y1 AS INTEGER, X2 AS INTEGER, Y2 AS INTEGER)
  CALL setMouseWindowAsm(x1, y1, X2, Y2)
END SUB

SUB SetNewPalette

  DIM dynpal(0 TO 383) AS INTEGER
  DEF SEG = VARSEG(dynpal(0))
  bufp = VARPTR(dynpal(0))
  FOR i = PalStart TO NextFreePal - 1
    s$ = MKL$(NewPal(i))
    POKE bufp, ASC(MID$(s$, 1, 1))
    POKE bufp + 1, ASC(MID$(s$, 2, 1))
    POKE bufp + 2, ASC(MID$(s$, 3, 1))
    bufp = bufp + 3
  NEXT i
  DEF SEG
  CALL setPalette(dynpal(), PalStart, NextFreePal - PalStart)

   'FOR i = 0 TO PalStart - 1: NewPal(i) = -1: NEXT i
   'PALETTE USING NewPal(0)
   'FOR c = PalStart TO NextFreePal - 1
   '  PALETTE c, NewPal(c)
   'NEXT c
END SUB

SUB setPalette (bufpal() AS INTEGER, start AS INTEGER, count AS INTEGER)
  CALL setPaletteAsm(VARPTR(bufpal(0)), VARSEG(bufpal(0)), start, count)
END SUB

SUB setUpBuffer (buf() AS INTEGER, w AS INTEGER, h AS INTEGER, c AS INTEGER)
  CALL setUpBufferAsm(VARPTR(buf(0)), VARSEG(buf(0)), w, h, c)
END SUB

SUB startFPSCounter
  timerfix = TIMER
  ticksfix = 0
END SUB

SUB updateAnimation (Anim AS Animation)
  Anim.Ticks = Anim.Ticks + 1
  IF 18 / Anim.FPS = Anim.Ticks THEN
    Anim.Ticks = 0
    Anim.TekFrame = Anim.TekFrame + 1
    IF Anim.TekFrame = Anim.FrameCount THEN Anim.TekFrame = 0
  END IF
END SUB

SUB updateFPSCounter
  ticksfix = ticksfix + 1
  DIM dt AS SINGLE
  dt = TIMER - timerfix
  IF dt >= 1! THEN
    currentfps = ticksfix
    CALL startFPSCounter
  END IF
END SUB

