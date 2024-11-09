program Runner;
//
// Приложение позволяет запустить DOSBox из структуры Info.plist
// с аргументом-именем файла конфигурации.
// Соответственно, в параметре CFBundleExecutable оно указывается вместо DOSBox
//
{$mode objfpc}{$h+}

uses 
  Classes, SysUtils, Process;
 
var 
  AProcess: TProcess;
begin
  ChDir(ExtractFilePath(ParamStr(0))) ;
  AProcess := TProcess.Create(nil);
  AProcess.Executable:= 'DOSBox';
  AProcess.Parameters.Add('-conf') ;
  AProcess.Parameters.Add('dosbox.conf');
  AProcess.Execute;
  AProcess.Free ;
end.