RequestExecutionLevel user
AutoCloseWindow true

XPStyle on

Icon main.ico

SetCompressor /SOLID lzma

LoadLanguageFile "${NSISDIR}\Contrib\Language files\Russian.nlf"

; Результирующий файл
OutFile "Trixie16bit-1.0.0-emulator-Win32.exe"
InstallDir "$DESKTOP\Trixie16bit"

Name "Трикси и алмазы"

Page directory
Page instfiles

; Страницы
      
Function .onInstSuccess
  MessageBox MB_OK "Игра 'Трикси и алмазы' успешно установлена вместе с эмулятором DOSBox. Ярлык на вашем Рабочем столе"
FunctionEnd

Function .onInstFailed
  MessageBox MB_OK "Ошибка при установке!"
FunctionEnd

Section "Трикси и алмазы"

  SetOutPath $INSTDIR
  File /r dosbox\*
  File main.ico
  SetOutPath $INSTDIR\game
  File /r ..\bin\*

  ; создание ярлыков
  SetOutPath $INSTDIR
  CreateShortCut "Трикси и алмазы 16 бит (эмулятор).lnk" "$INSTDIR\DOSBox.exe" "-conf dosbox.conf -noconsole" "$INSTDIR\main.ico" 
  CopyFiles "$INSTDIR\Трикси и алмазы 16 бит (эмулятор).lnk" $DESKTOP

SectionEnd

