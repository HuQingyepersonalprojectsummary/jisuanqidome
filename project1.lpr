program project1;

{==============================================================================
  PCalc 高级科学与工程计算器 - 应用程序主入口 (project1.lpr)
  ------------------------------------------------------------------------------
  本程序是基于 Free Pascal (FPC) 与 Lazarus LCL 框架的原生 64 位 Win64 桌面程序。
  不依赖 .NET Framework、WebView2 或 VC++ Runtime，具备毫秒级冷启动与超低内存占用。
==============================================================================}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // LCL 图形构件集入口
  Forms, unit1;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

