RequestExecutionLevel user
AutoCloseWindow true

XPStyle on

Icon main.ico

SetCompressor /SOLID lzma

LoadLanguageFile "${NSISDIR}\Contrib\Language files\Russian.nlf"

; �������������� ����
OutFile "Trixie16bit-1.0.0-emulator-Win32.exe"
InstallDir "$DESKTOP\Trixie16bit"

Name "������ � ������"

Page directory
Page instfiles

; ��������
      
Function .onInstSuccess
  MessageBox MB_OK "���� '������ � ������' ������� ����������� ������ � ���������� DOSBox. ����� �� ����� ������� �����"
FunctionEnd

Function .onInstFailed
  MessageBox MB_OK "������ ��� ���������!"
FunctionEnd

Section "������ � ������"

  SetOutPath $INSTDIR
  File /r dosbox\*
  File main.ico
  SetOutPath $INSTDIR\game
  File /r ..\bin\*

  ; �������� �������
  SetOutPath $INSTDIR
  CreateShortCut "������ � ������ 16 ��� (��������).lnk" "$INSTDIR\DOSBox.exe" "-conf dosbox.conf -noconsole" "$INSTDIR\main.ico" 
  CopyFiles "$INSTDIR\������ � ������ 16 ��� (��������).lnk" $DESKTOP

SectionEnd

