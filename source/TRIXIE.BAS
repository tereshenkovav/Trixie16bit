DEFINT A-Z
'$INCLUDE: 'gratools.bi'
'$INCLUDE: 'trixie.bi'

CLS
SCREEN 13

CALL LoadOpt
CALL LoadLangs
CALL LoadTexts
IF opt.showlog THEN CALL enableDebug
CALL ResetSpriteLoader(STARTPAL)

CALL SetCustomColors

CALL loadFont(font(), "data\font.8x8")
CALL LoadSounds

CALL setUpBuffer(back(), 320, 180, SKYC0 + 7)
CALL RenderBackground
IF opt.showlog THEN PRINT FRE(-1) / 1024
CALL initSpriteBuf(sprites())
CALL initSpriteBuf(slogos())
CALL initSpriteBuf(monsters())

CALL LoadResources

' intro proc - appear intro.pcx
DIM bufpal(0 TO 255) AS ColorRGB
CALL directLoadPicToBuf(buf(), "data\intro.pcx", bufpal(), usedpalcount)
DO WHILE INKEY$ <> "": LOOP

DIM dynpal(0 TO 383) AS INTEGER
FOR i = 0 TO 383: dynpal(i) = 0: NEXT i
CALL setPalette(dynpal(), STARTPAL, usedpalcount)

PUT (0, 0), buf(0), PSET

DIM crgb AS ColorRGB
FOR p = 1 TO 10
  IF WaitTicks(4) THEN GOTO skipintro
  DEF SEG = VARSEG(dynpal(0))
  bufp = VARPTR(dynpal(0))
  FOR i = 0 TO usedpalcount - 1
    crgb = bufpal(i)
    CALL SetBrightRGB(crgb, p / 10)
    POKE bufp, crgb.r
    POKE bufp + 1, crgb.g
    POKE bufp + 2, crgb.b: bufp = bufp + 3
  NEXT i
  DEF SEG
  CALL setPalette(dynpal(), STARTPAL, usedpalcount)
NEXT p

IF WaitTicks(36) THEN GOTO skipintro

CALL drawString(buf(), font(), 215, 185, msgpress$ + " " + msgspace$, TEXTCOLOR)
PUT (0, 0), buf(0), PSET

DO WHILE INKEY$ = "": LOOP

skipintro:

CALL SetNewPalette

IF opt.showlog THEN
PRINT getLoaderReport$
PRINT "sprites:"; getBufferReport$(sprites(), MEMSPRITE)
PRINT "logos:"; getBufferReport$(slogos(), MEMLOGOS)
PRINT "monster:"; getBufferReport$(monsters(), MEMMONSTERS)
PRINT "Press any key"
DO WHILE INKEY$ = "": LOOP
END IF

mainmenu:

CLS

scenestage = TRUE
scenepos = -150
teksel = 1

CALL startFPSCounter

PUT (35, 10), slogos(logo.BufPos), PSET

DO WHILE TRUE

t0 = TIMER

CALL setUpBuffer(buf(), 320, 160, 0)

CALL DrawBorder(70, 180, 0, 96)

CALL drawSpriteTransp(buf(), sprites(), selector.BufPos, 90, spos(teksel))
FOR i = 1 TO 5
  CALL drawString(buf(), font(), 120, spos(i) + 7, menus$(i), TEXTCOLOR)
NEXT i
CALL drawSprite(buf(), sprites(), slang(teklang).BufPos, 124 + 8 * LEN(menus$(3)), spos(3) + 5)

FOR x = 0 TO 7
  CALL drawSprite(buf(), sprites(), gndstone.BufPos, x * gndstone.W, 160 - gndstone.H)
  CALL drawSpriteTransp(buf(), sprites(), gndcave.BufPos, x * gndcave.W, 158 - gndcave.H)
NEXT x

IF scenepos >= 0 AND scenepos < 318 - herowalk.W THEN
  IF scenestage = 1 THEN
    CALL drawAnimationTransp(buf(), sprites(), herowalk, scenepos, 149 - herowalk.H)
  ELSE
    CALL drawAnimationTranspMirror(buf(), sprites(), herowalk, scenepos, 149 - herowalk.H)
  END IF
END IF

IF scenestage = 1 THEN
  IF scenepos + 80 >= 0 AND scenepos + 80 < 318 - monsterarr(1).W THEN
    CALL drawAnimationTransp(buf(), monsters(), monsterarr(1), scenepos + 80, 149 - monsterarr(1).H)
  END IF
ELSE
  FOR i = 0 TO 2
  IF scenepos + 80 + 40 * i >= 0 AND scenepos + 80 + 40 * i < 318 - monsterarr(1).W THEN
    CALL drawAnimationTranspMirror(buf(), monsters(), monsterarr(1), scenepos + 80 + 40 * i, 149 - monsterarr(1).H)
  END IF
  NEXT i
END IF

CALL ShowFPSIfSet

PUT (0, 40), buf(0), PSET

IF scenestage = 1 THEN
  scenepos = scenepos + 3
  IF scenepos > 350 THEN scenestage = 2
END IF
IF scenestage = 2 THEN
  scenepos = scenepos - 3
  IF scenepos < -150 THEN scenestage = 1
END IF

CALL updateAnimation(herowalk)
CALL updateAnimation(monsterarr(1))
CALL updateFPSCounter

k$ = INKEY$

SELECT CASE k$
CASE CHR$(27): END
CASE CHR$(13), CHR$(32):
  IF teksel = 1 THEN
    casual = TRUE
    GOTO startgame
  END IF
  IF teksel = 2 THEN
    casual = FALSE
    GOTO startgame
  END IF
  IF teksel = 3 THEN
    teklang = teklang + 1
    IF teklang >= LANGCOUNT THEN teklang = 0
    CALL LoadTexts
    FOR i = 1 TO 5
      CALL LoadScene("DATA\scene" + LTRIM$(STR$(i)) + langs$(teklang) + ".txt", i)
    NEXT i
    CALL initSpriteBuf(slogos())
    CALL LoadSpriteInBuf(slogos(), logo, "data\logo_" + langs$(teklang) + ".pcx")
    PUT (35, 10), slogos(logo.BufPos), PSET
  END IF
  IF teksel = 4 THEN
    CLS
    helppage = 1
    DO WHILE RenderHelpPage = TRUE: LOOP
    GOTO mainmenu
  END IF
  IF teksel = 5 THEN END
CASE CHR$(0) + "H":
  IF teksel > 1 THEN
    teksel = teksel - 1
    PLAY soundmenu
  END IF
CASE CHR$(0) + "P":
  IF teksel < 5 THEN
    teksel = teksel + 1
    PLAY soundmenu
  END IF
END SELECT

DO WHILE t0 = TIMER: LOOP

LOOP

startgame:

' Game init start
hero.y = Ypos(2): hero.x = 160: hero.vx = 0

jump = FALSE
fire = FALSE
victory = FALSE
manacount = MAXMANA
heartcount = 3
bonuscount = 0
hitmode = 0
lastdir = 1

bonusleft = MAXBONUS
nextmana = NEXTMANATICKS
nextmonster = NEXTMONSTERTICKS
nextbonus = NEXTBONUSTICKS
gameover = FALSE
hidehero = FALSE
countdown = 0
mcount = 0
bcount = 0
' Game init end

CLS
CALL startFPSCounter

' Game cicle
DO WHILE TRUE

t0 = TIMER

CALL copyBuffer(back(), buf(), 320, 180)
CALL setUpBuffer(bufpanel(), 320, 20, SKYC0 + 7)

FOR i = 0 TO bcount - 1
  CALL drawSpriteTransp(buf(), sprites(), bonus.BufPos, bx(i).x, bx(i).y - bonus.H)
NEXT i

FOR i = 0 TO mcount - 1
  IF mx(i).vx > 0 THEN
    CALL drawAnimationTransp(buf(), monsters(), monsterarr(mx(i).tag), mx(i).x, mx(i).y - monsterarr(mx(i).tag).H + 1)
  ELSE
    CALL drawAnimationTranspMirror(buf(), monsters(), monsterarr(mx(i).tag), mx(i).x, mx(i).y - monsterarr(mx(i).tag).H + 1)
  END IF
NEXT i

IF hitmode MOD 4 < 2 AND countdown = 0 THEN
  IF hero.vx = 0 THEN
    IF lastdir = 1 THEN
      CALL drawSpriteTransp(buf(), sprites(), herowait.BufPos, hero.x, hero.y - herowait.H)
    ELSE
      CALL drawSpriteTranspMirror(buf(), sprites(), herowait.BufPos, hero.x, hero.y - herowait.H)
    END IF
  ELSE
    IF lastdir = 1 THEN
      CALL drawAnimationTransp(buf(), sprites(), herowalk, hero.x, hero.y + 3 - herowalk.H)
    ELSE
      CALL drawAnimationTranspMirror(buf(), sprites(), herowalk, hero.x, hero.y + 3 - herowalk.H)
    END IF
  END IF
END IF

IF fire = TRUE THEN
  IF lastdir = 1 THEN
    CALL drawAnimationTransp(buf(), sprites(), fireball, fireobj.x, fireobj.y - fireball.H)
  ELSE
    CALL drawAnimationTranspMirror(buf(), sprites(), fireball, fireobj.x, fireobj.y - fireball.H)
  END IF
END IF

IF jump = TRUE THEN
  CALL drawAnimationTransp(buf(), sprites(), teleport, hero.x, hero.y - teleport.H - 5)
END IF

CALL RenderPanel

CALL ShowFPSIfSet
CALL updateFPSCounter
 
PUT (0, 20), buf(0), PSET
PUT (0, 0), bufpanel(0), PSET

CALL UpdateAnimations

IF jump = TRUE THEN
  CALL updateAnimation(teleport)
  IF teleport.TekFrame = 3 THEN
    IF gameover = TRUE THEN countdown = 30 ELSE hero.y = targety
  END IF
  IF teleport.TekFrame = 8 THEN jump = FALSE
END IF

IF fire = TRUE THEN
  fireobj.x = fireobj.x + fireobj.vx
  IF fireobj.x < 0 THEN fire = FALSE
  IF fireobj.x > 320 - fireball.W THEN fire = FALSE
END IF

IF hitmode > 0 THEN hitmode = hitmode - 1

FOR i = 0 TO mcount - 1
  mx(i).x = mx(i).x + mx(i).vx
  IF (mx(i).vx < 0) THEN
    IF (mx(i).x < 10) THEN mx(i).vx = -mx(i).vx
  ELSE
    IF (mx(i).x > 310 - monsterarr(mx(i).tag).W) THEN mx(i).vx = -mx(i).vx
  END IF
 
  IF gameover = FALSE THEN
  IF hitmode = 0 THEN
  IF (mx(i).y = hero.y) THEN
  IF IsBlockIntersect(mx(i).x, monsterarr(mx(i).tag).W, hero.x, herowait.W) THEN
    hitmode = PROTECTAFTERDAMAGETICKS
    heartcount = heartcount - 1
    IF heartcount = 0 THEN
      PLAY soundteleport
      victory = FALSE
      gameover = TRUE
      jump = TRUE
      teleport.TekFrame = 0
      'GOTO endgame
    ELSE
      PLAY soundhit
    END IF
  END IF
  END IF
  END IF
  END IF

  IF fire = TRUE THEN
  IF (mx(i).y = fireobj.y) THEN
    IF IsBlockIntersect(mx(i).x, monsterarr(mx(i).tag).W, fireobj.x, fireball.W) THEN mx(i).killed = TRUE
  END IF
  END IF
NEXT i

IF gameover = FALSE THEN
FOR i = 0 TO bcount - 1
  IF (hitmode = 0) THEN
  IF (bx(i).y = hero.y) THEN
  IF IsBlockIntersect(bx(i).x, bonus.W, hero.x, herowait.W) THEN
    PLAY soundgetbonus
    bx(i).killed = TRUE
    bonuscount = bonuscount + 1
    IF bonuscount = MAXBONUS THEN
      PLAY soundteleport
      victory = TRUE
      gameover = TRUE
      jump = TRUE
      teleport.TekFrame = 0
      'GOTO endgame
    END IF
  END IF
  END IF
  END IF
NEXT i
END IF

CALL RemoveKilledGameObjects(mx(), mcount)
CALL RemoveKilledGameObjects(bx(), bcount)

nextmana = nextmana - 1
IF nextmana = 0 THEN
  nextmana = NEXTMANATICKS
  IF casual = TRUE THEN nextmana = 48
  IF manacount < MAXMANA THEN manacount = manacount + 1
END IF

nextmonster = nextmonster - 1
IF nextmonster = 0 THEN
  nextmonster = NEXTMONSTERTICKS
  IF mcount < 15 THEN
    CALL NewMonster(mx(mcount))
    mcount = mcount + 1
  END IF
END IF

nextbonus = nextbonus - 1
IF nextbonus = 0 THEN
  nextbonus = NEXTBONUSTICKS
  IF (bonusleft > 0) THEN
    CALL NewBonus(bx(bcount))
    bcount = bcount + 1
    bonusleft = bonusleft - 1
  END IF
END IF

k$ = INKEY$
IF gameover = FALSE THEN
SELECT CASE k$
CASE CHR$(27): victory = 2: GOTO endgame
CASE "1": CALL TryJump(Ypos(1))
CASE "2": CALL TryJump(Ypos(2))
CASE "3": CALL TryJump(Ypos(3))
CASE CHR$(0) + "K": hero.vx = -HEROSPEED: lastdir = -1
CASE CHR$(0) + "M": hero.vx = HEROSPEED: lastdir = 1
CASE CHR$(0) + CHR$(68): DO WHILE INKEY$ = "": LOOP
CASE CHR$(32): CALL TryFire(lastdir)
CASE CHR$(0) + "H": hero.vx = 0
CASE CHR$(0) + "P": hero.vx = 0
END SELECT
IF (hero.x <= 10) AND (hero.vx < 0) THEN hero.vx = 0
IF (hero.x >= 310 - herowait.W) AND (hero.vx > 0) THEN hero.vx = 0
hero.x = hero.x + hero.vx
END IF

DO WHILE INKEY$ <> "": LOOP

IF countdown > 0 THEN
  countdown = countdown - 1
  IF countdown = 0 THEN GOTO endgame
END IF

DO WHILE t0 = TIMER: LOOP

LOOP

endgame:

CALL RenderEndGame(victory)

DO WHILE INKEY$ <> CHR$(32): LOOP

GOTO mainmenu

REM $DYNAMIC
SUB DrawBorder (borderx AS INTEGER, borderw AS INTEGER, bordery AS INTEGER, borderh AS INTEGER)

FOR i = 0 TO 6
  IF i < 3 THEN tekc = BORDERC0 + i ELSE tekc = BORDERC0 + 6 - i
  CALL drawLineHorz(buf(), borderx + i, borderx + borderw - i, bordery + i, tekc)
  CALL drawLineHorz(buf(), borderx + i, borderx + borderw - i, bordery + borderh - i, tekc)
  CALL drawLineVert(buf(), borderx + i, bordery + i, bordery + borderh - i, tekc)
  CALL drawLineVert(buf(), borderx + borderw - i, bordery + i, bordery + borderh - i, tekc)
NEXT i

CALL fillRect(buf(), borderx + 7, bordery + 7, borderw - 13, borderh - 13, BORDERC0)

END SUB

REM $STATIC
SUB DrawScene (scenen AS INTEGER)

  FOR i = 0 TO scenes((scenen - 1) * 16).cnt - 1
    p = (scenen - 1) * 16 + i
    CALL drawString(buf(), font(), scenes(p).x, scenes(p).y, scenes(p).str, TEXTCOLOR)
  NEXT i

END SUB

FUNCTION IsBlockIntersect% (x1 AS INTEGER, w1 AS INTEGER, x2 AS INTEGER, w2 AS INTEGER)
 
  IsBlockIntersect = FALSE
  'EXIT FUNCTION

  xw1 = x1 + w1
  xw2 = x2 + w2

  IF (x1 <= x2) AND (x2 <= xw1) THEN
    IsBlockIntersect = TRUE
    EXIT FUNCTION
  END IF
  IF (x1 <= xw2) AND (xw2 <= xw1) THEN
    IsBlockIntersect = TRUE
    EXIT FUNCTION
  END IF
  IF (x2 <= x1) AND (x1 <= xw2) THEN
    IsBlockIntersect = TRUE
    EXIT FUNCTION
  END IF
  IF (x2 <= xw1) AND (xw1 <= xw2) THEN IsBlockIntersect = TRUE
 
END FUNCTION

SUB LoadLangs
  langs$(0) = "ru"
  langs$(1) = "en"
  teklang = 0
  OPEN "data\deflang" FOR INPUT AS #1
  IF NOT EOF(1) THEN
    INPUT #1, s$
    FOR i = 0 TO LANGCOUNT - 1
      IF langs$(i) = s$ THEN teklang = i
    NEXT i
  END IF
  CLOSE #1
END SUB

REM $DYNAMIC
SUB LoadOpt

  opt.showfps = 0
  opt.showlog = 0

  OPEN "DATA\options" FOR INPUT AS #1
  WHILE NOT EOF(1)
    INPUT #1, optline$
    IF optline$ = "show_log" THEN opt.showlog = TRUE
    IF optline$ = "show_fps" THEN opt.showfps = TRUE
  WEND
  CLOSE #1

END SUB

SUB LoadResources

ind = 9
CALL LoadTranspAnimationInBuf(monsters(), monsterarr(1), "data\m_1.pcx", 6, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(monsters(), monsterarr(2), "data\m_2.pcx", 6, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(monsters(), monsterarr(3), "data\m_3.pcx", 4, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(monsters(), monsterarr(4), "data\m_4.pcx", 5, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(monsters(), monsterarr(5), "data\m_5.pcx", 6, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(sprites(), fireball, "data\fireball.pcx", 5, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(sprites(), herowalk, "data\trx_walk.pcx", 11, 9, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), herowait, "data\trx_wait.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspAnimationInBuf(sprites(), teleport, "data\teleport.pcx", 9, 18, 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), heart, "data\heart.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), bonus, "data\bonus.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), mana, "data\mana.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspGrayedSpriteInBuf(sprites(), heartgray, "data\heart.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspGrayedSpriteInBuf(sprites(), bonusgray, "data\bonus.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspGrayedSpriteInBuf(sprites(), managray, "data\mana.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), winimg, "data\win.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), selector, "data\selector.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), gndcave, "data\gnd_cave.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), gndstone, "data\gnd_ston.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), starlight, "data\star.pcx", 0, 0)
CALL UpdateIndicator(ind)
FOR i = 0 TO LANGCOUNT - 1
  CALL LoadSpriteInBuf(sprites(), slang(i), "data\lang_" + langs$(i) + ".pcx")
NEXT i
CALL LoadSpriteInBuf(slogos(), logo, "data\logo_" + langs$(teklang) + ".pcx")
CALL UpdateIndicator(ind)

FOR i = 1 TO 5
  CALL LoadScene("DATA\scene" + LTRIM$(STR$(i)) + langs$(teklang) + ".txt", i)
NEXT i
 
END SUB

REM $STATIC
SUB LoadScene (datafile AS STRING, scenen AS INTEGER)

  OPEN datafile FOR INPUT AS #1
  INPUT #1, cnt
  p = (scenen - 1) * 16
  scenes(p).cnt = cnt
  FOR i = 0 TO cnt - 1
    LINE INPUT #1, scenes(p + i).str
    INPUT #1, scenes(p + i).x
    INPUT #1, scenes(p + i).y
  NEXT i
  CLOSE #1

END SUB

SUB LoadSounds
 
  OPEN "DATA\sounds" FOR INPUT AS #1
  INPUT #1, optline$: INPUT #1, optline$
  soundgetbonus = "MB" + optline$
  INPUT #1, optline$: INPUT #1, optline$
  soundfireball = "MB" + optline$
  INPUT #1, optline$: INPUT #1, optline$
  soundmenu = "MB" + optline$
  INPUT #1, optline$: INPUT #1, optline$
  soundteleport = "MB" + optline$
  INPUT #1, optline$: INPUT #1, optline$
  soundhit = "MB" + optline$
  CLOSE #1
   
END SUB

SUB LoadTexts

  OPEN "DATA\texts_" + langs$(teklang) + ".dat" FOR INPUT AS #1
  LINE INPUT #1, msgload$
  LINE INPUT #1, msgpress$
  LINE INPUT #1, msgspace$
  LINE INPUT #1, msgwin$
  LINE INPUT #1, msgfail$
  LINE INPUT #1, msgcancel$
  LINE INPUT #1, msgpage$
  LINE INPUT #1, msghelp$
  LINE INPUT #1, menus$(1)
  LINE INPUT #1, menus$(2)
  LINE INPUT #1, menus$(3)
  LINE INPUT #1, menus$(4)
  LINE INPUT #1, menus$(5)
  CLOSE #1

END SUB

REM $DYNAMIC
SUB NewBonus (b AS GameObject)
  b.y = Ypos(1 + INT(3 * RND(1)))
  b.x = 5 + INT(280 * RND(1))
  b.killed = FALSE
END SUB

SUB NewMonster (m AS GameObject)

  m.y = Ypos(1 + INT(3 * RND(1)))
  m.tag = 1 + INT(5 * RND(1))

  IF hero.y <> m.y THEN
    IF INT(2 * RND(1)) = 0 THEN onleft = TRUE ELSE onleft = FALSE
  ELSE
    IF hero.x > 160 THEN onleft = TRUE ELSE onleft = FALSE
  END IF

  IF onleft THEN
    m.x = 5
    m.vx = MonsterSpeed(m.tag)
  ELSE
    m.x = 260
    m.vx = -MonsterSpeed(m.tag)
  END IF

  m.killed = FALSE

END SUB

SUB RemoveKilledGameObjects (objs() AS GameObject, cnt AS INTEGER)

  i = 0
  DO WHILE i < cnt
    IF (objs(i).killed = TRUE) THEN
      FOR j = i TO cnt - 2: objs(j) = objs(j + 1): NEXT j
      cnt = cnt - 1
    ELSE
      i = i + 1
    END IF
  LOOP

END SUB

SUB RenderBackground

CALL initSpriteBuf(sprites())

ind = 0
CALL LoadTranspSpriteInBuf(sprites(), gndmid, "data\gnd_mid.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), gndleft, "data\gnd_left.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), gndright, "data\gnd_rght.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), gndcave, "data\gnd_cave.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), gndstone, "data\gnd_ston.pcx", 0, 0)
CALL UpdateIndicator(ind)

DIM cave AS Sprite
DIM sky1 AS Sprite
DIM sky2 AS Sprite
DIM sky3 AS Sprite
CALL LoadTranspSpriteInBuf(sprites(), cave, "data\caveback.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), sky1, "data\sky1.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), sky2, "data\sky2.pcx", 0, 0)
CALL UpdateIndicator(ind)
CALL LoadTranspSpriteInBuf(sprites(), sky3, "data\sky4.pcx", 0, 0)
CALL UpdateIndicator(ind)
IF opt.showlog THEN PRINT "buf:"; getBufferReport$(sprites(), MEMSPRITE)

FOR x = 0 TO 7
  FOR j = 0 TO 6
    CALL drawSpriteTransp(back(), sprites(), cave.BufPos, x * cave.W, Ypos(2) + 13 + j * (cave.H - 2))
  NEXT j
NEXT x

p = Ypos(2)
FOR i = 0 TO 7
  FOR k = 0 TO Ypos(2) \ 8
    CALL drawLineHorz(back(), 0, 319, p, SKYC0 + i)
    p = p - 1
    IF p < 0 THEN GOTO skip
  NEXT k
NEXT i
skip:

CALL drawSpriteTransp(back(), sprites(), sky1.BufPos, 40, 15)
CALL drawSpriteTransp(back(), sprites(), sky2.BufPos, 120, 2)
CALL drawSpriteTransp(back(), sprites(), sky3.BufPos, 240, 20)

CALL drawSpriteTransp(back(), sprites(), gndleft.BufPos, 24, Ypos(1) - 3)
FOR x = 0 TO 5
  CALL drawSpriteTransp(back(), sprites(), gndmid.BufPos, 40 + x * gndmid.W, Ypos(1) - 3)
NEXT x
CALL drawSpriteTransp(back(), sprites(), gndright.BufPos, 280, Ypos(1) - 3)

FOR x = 0 TO 7
  CALL drawSpriteTransp(back(), sprites(), gndcave.BufPos, x * gndcave.W, Ypos(2) - 3 + 5)
  CALL drawSpriteTransp(back(), sprites(), gndcave.BufPos, x * gndcave.W, Ypos(2) - 3)
  CALL drawSpriteTransp(back(), sprites(), gndstone.BufPos, x * gndstone.W, Ypos(3))
NEXT x

END SUB

REM $STATIC
SUB RenderEndGame (iswin AS INTEGER)

borderx = 70
bordery = 40
CALL DrawBorder(borderx, 180, bordery, 90)

SELECT CASE iswin
CASE TRUE
  info$ = msgwin$
  CALL drawSpriteTransp(buf(), sprites(), winimg.BufPos, borderx + 10, bordery + 10)
CASE FALSE
  info$ = msgfail$
  CALL drawSpriteTransp(buf(), sprites(), herowait.BufPos, borderx + 20, bordery + 25)
CASE ELSE
  info$ = msgcancel$
  CALL drawSpriteTransp(buf(), sprites(), herowait.BufPos, borderx + 20, bordery + 25)
END SELECT

CALL drawString(buf(), font(), 155, bordery + 25, info$, TEXTCOLOR)
CALL drawString(buf(), font(), 155, bordery + 50, msgpress$, TEXTCOLOR)
CALL drawString(buf(), font(), 155, bordery + 60, msgspace$, TEXTCOLOR)

PUT (0, 20), buf(0), PSET

END SUB

FUNCTION RenderHelpPage%

  MaxHelpPage = 5

  RenderHelpPage% = TRUE
 
  CALL setUpBuffer(buf(), 320, 195, 0)
  CALL DrawBorder(10, 300, 10, 180)
  CALL drawLineHorz(buf(), 20, 300, 32, GRAYCOLOR)
  CALL drawLineHorz(buf(), 20, 300, 167, GRAYCOLOR)

  info$ = msgpage$ + " " + STR$(helppage) + " /" + STR$(MaxHelpPage)
  CALL drawString(buf(), font(), 100, 20, info$, GRAYCOLOR)
  CALL drawString(buf(), font(), 30, 173, msghelp$, GRAYCOLOR)

  SELECT CASE helppage
  CASE 1
    CALL DrawScene(1)
    CALL drawSpriteTransp(buf(), sprites(), herowait.BufPos, 30, 60)
  CASE 2
    CALL DrawScene(2)
    CALL drawSpriteTranspMirror(buf(), sprites(), starlight.BufPos, 245, 50)
  CASE 3
    CALL DrawScene(3)
    CALL drawSpriteTransp(buf(), sprites(), bonus.BufPos, 265, 45)
    CALL drawSpriteTransp(buf(), sprites(), bonus.BufPos, 276, 53)
    CALL drawSpriteTransp(buf(), sprites(), bonus.BufPos, 286, 45)
    FOR i = 1 TO 5: monsterarr(i).TekFrame = 0: NEXT i

    CALL drawAnimationTransp(buf(), monsters(), monsterarr(3), 40, 127 - monsterarr(3).H)
    CALL drawAnimationTransp(buf(), monsters(), monsterarr(2), 90, 127 - monsterarr(2).H)
    CALL drawAnimationTransp(buf(), monsters(), monsterarr(1), 140, 127 - monsterarr(1).H)
    CALL drawAnimationTransp(buf(), monsters(), monsterarr(4), 190, 127 - monsterarr(4).H)
    CALL drawAnimationTransp(buf(), monsters(), monsterarr(5), 240, 127 - monsterarr(5).H)
    CALL drawSpriteTransp(buf(), sprites(), heart.BufPos, 130, 147)
    CALL drawSpriteTransp(buf(), sprites(), heart.BufPos, 150, 147)
    CALL drawSpriteTransp(buf(), sprites(), heartgray.BufPos, 170, 147)
  CASE 4
    CALL DrawScene(4)
    FOR i = 0 TO MAXMANA - 1
      IF i < MAXMANA - 3 THEN
        CALL drawSpriteTransp(buf(), sprites(), mana.BufPos, 100 + i * (mana.W + 2), 147)
      ELSE
        CALL drawSpriteTransp(buf(), sprites(), managray.BufPos, 100 + i * (mana.W + 2), 147)
      END IF
    NEXT i
  CASE 5
    CALL DrawScene(5)
  END SELECT


  PUT (0, 0), buf(0), PSET

  DO WHILE TRUE
    k$ = INKEY$
    SELECT CASE k$
      CASE CHR$(27)
        RenderHelpPage% = FALSE
        EXIT FUNCTION
      CASE CHR$(0) + "H"
        IF helppage > 1 THEN
          helppage = helppage - 1
          EXIT FUNCTION
        END IF
      CASE CHR$(0) + "P"
        IF helppage < MaxHelpPage THEN
          helppage = helppage + 1
          EXIT FUNCTION
        END IF
    END SELECT
  LOOP
  
END FUNCTION

REM $DYNAMIC
SUB RenderPanel

FOR i = 0 TO 2
  IF i < heartcount THEN spridx& = heart.BufPos ELSE spridx& = heartgray.BufPos
  CALL drawSpriteTransp(bufpanel(), sprites(), spridx&, 122 + i * (heart.W + 4), 3)
NEXT i

FOR i = 0 TO MAXMANA - 1
  IF i < manacount THEN
    CALL drawSpriteTransp(bufpanel(), sprites(), mana.BufPos, 3 + i * (mana.W + 2), 3)
  ELSE
    CALL drawSpriteTransp(bufpanel(), sprites(), managray.BufPos, 3 + i * (mana.W + 2), 3)
  END IF
NEXT i

FOR i = 0 TO MAXBONUS - 1
  IF i MOD 2 = 0 THEN
    bonusx = 192 + (i \ 2) * (bonus.W + 3)
    bonusy = 1
  ELSE
    bonusx = 200 + (i \ 2) * (bonus.W + 3)
    bonusy = 9
  END IF

  IF i < bonuscount THEN spridx& = bonus.BufPos ELSE spridx& = bonusgray.BufPos
  CALL drawSpriteTransp(bufpanel(), sprites(), spridx&, bonusx, bonusy)
NEXT i

END SUB

REM $STATIC
SUB SetCustomColors

FOR i = 0 TO 3
  PALETTE BORDERC0 + i, 65536 * (20 + 10 * i) + 256 * (20 + 10 * i) + (20 + 10 * i)
  'PALETTE BORDERC0 + i, 65536 * 63 + 256 * 45 + 8
NEXT i

FOR i = 0 TO 7
  PALETTE SKYC0 + i, 65536 * 63 + 256 * (50 - i * 2) + (40 - i * 2)
NEXT i
PALETTE TEXTCOLOR, 65536 * 63 + 256 * 63 + 63
PALETTE GRAYCOLOR, 65536 * 45 + 256 * 45 + 45

END SUB

SUB ShowFPSIfSet
IF opt.showfps THEN
  info$ = "FPS:" + STR$(getFPS%)
  CALL drawString(buf(), font(), 5, 0, info$, TEXTCOLOR)
  info$ = "Fre" + STR$(CINT(FRE(-1) / 1024)) + "K"
  CALL drawString(buf(), font(), 5, 9, info$, TEXTCOLOR)
END IF
END SUB

REM $DYNAMIC
SUB TryFire (lastdir AS INTEGER)
  IF hitmode > 0 THEN EXIT SUB

  mananeed = FIREMANACOST
  IF manacount < mananeed THEN EXIT SUB

  PLAY soundfireball

  manacount = manacount - mananeed
  fire = TRUE
  fireobj.y = hero.y
  IF lastdir > 0 THEN
    fireobj.vx = FIRESPEED
    fireobj.x = hero.x + herowait.W
  ELSE
    fireobj.vx = -FIRESPEED
    fireobj.x = hero.x - fireball.W
  END IF
                 
END SUB

SUB TryJump (y AS INTEGER)

  IF hitmode > 0 THEN EXIT SUB

  IF hero.y = y THEN EXIT SUB
  
  IF ABS(hero.y - y) = Ypos(3) - Ypos(1) THEN mananeed = 2 ELSE mananeed = 1

  IF manacount < mananeed THEN EXIT SUB

  PLAY soundteleport
  manacount = manacount - mananeed
  jump = TRUE
  targety = y
  teleport.TekFrame = 0
END SUB

SUB UpdateAnimations

FOR i = 1 TO 5: CALL updateAnimation(monsterarr(i)): NEXT i
CALL updateAnimation(fireball)
CALL updateAnimation(herowalk)

END SUB

REM $STATIC
SUB UpdateIndicator (indpos AS INTEGER)
 
  IF opt.showlog THEN EXIT SUB
 
  CALL setUpBuffer(buf(), 320, 30, 0)
  CALL DrawBorder(20, 280, 0, 30)
  W = CINT(266 * indpos / MAXINDPOS)
  CALL fillRect(buf(), 27, 7, W, 16, SKYC0 + 7)

  info$ = msgload$ + STR$(CINT(100 * indpos / MAXINDPOS)) + "%"
  CALL drawString(buf(), font(), 100, 10, info$, TEXTCOLOR)
  PUT (0, 50), buf(0), PSET

  indpos = indpos + 1
END SUB

FUNCTION WaitTicks% (TickN AS INTEGER)

WaitTicks% = FALSE
DIM t0 AS SINGLE
FOR slp = 1 TO TickN
  t0 = TIMER
  DO WHILE t0 = TIMER: LOOP
  IF INKEY$ <> "" THEN
    WaitTicks% = TRUE
    EXIT FUNCTION
  END IF
NEXT slp

END FUNCTION

