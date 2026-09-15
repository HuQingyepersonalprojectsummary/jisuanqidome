unit uThemeManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics, Controls, Buttons,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  uCalcTypes;

type
  TThemePalette = record
    BgColor: TColor;
    TabBg: TColor;
    BorderColor: TColor;
    // 输入框固定专属颜色 (不受主题切换影响)
    DisplayBg: TColor;
    DisplayText: TColor;
    DisplaySubText: TColor;
    DisplayBorder: TColor;
    // 按键分类配色与动效
    NumBtnBg: TColor;
    NumBtnText: TColor;
    NumBtnHover: TColor;
    NumBtnPress: TColor;
    OpBtnBg: TColor;
    OpBtnText: TColor;
    OpBtnHover: TColor;
    OpBtnPress: TColor;
    FuncBtnBg: TColor;
    FuncBtnText: TColor;
    FuncBtnHover: TColor;
    FuncBtnPress: TColor;
    EqualBtnBg: TColor;
    EqualBtnText: TColor;
    EqualBtnHover: TColor;
    EqualBtnPress: TColor;
    // 顶部栏与模式切换按键配色
    TopBarBg: TColor;
    TopBtnBg: TColor;
    TopBtnText: TColor;
    TopBtnHover: TColor;
    TopBtnPress: TColor;
    TopBtnActiveBg: TColor;
    TopBtnActiveText: TColor;
    IsDark: Boolean;
  end;

function GetThemePalette(const ATheme: TThemeType): TThemePalette;
procedure ApplyThemeToForm(const AForm: TForm; const ATheme: TThemeType);
procedure SetWindowsDarkTitleBar(const AForm: TForm; const EnableDark: Boolean);

implementation

{$IFDEF WINDOWS}
const
  DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: Pointer; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll' name 'DwmSetWindowAttribute';
{$ENDIF}

function GetThemePalette(const ATheme: TThemeType): TThemePalette;
var
  P: TThemePalette;
begin
  // 【关键设计】：输入框与显示屏颜色固定锁定，不受白/黑/浅黄主题切换影响，保证极高辨识度与专业质感
  P.DisplayBg      := RGBToColor(28, 30, 34);   // 深邃高质感液晶暗屏
  P.DisplayText    := RGBToColor(255, 255, 255); // 纯白高亮主显示
  P.DisplaySubText := RGBToColor(160, 165, 175); // 柔和银灰副算式
  P.DisplayBorder  := RGBToColor(45, 48, 55);   // 微妙内嵌暗边框

  case ATheme of
    ttBlack: // 经典极客黑 (深邃高对比)
    begin
      P.BgColor       := RGBToColor(24, 24, 26);
      P.TabBg         := RGBToColor(16, 16, 18);
      P.BorderColor   := RGBToColor(50, 50, 56);

      P.TopBarBg         := RGBToColor(16, 16, 18);
      P.TopBtnBg         := RGBToColor(36, 36, 42);
      P.TopBtnText       := RGBToColor(230, 235, 245);
      P.TopBtnHover      := RGBToColor(52, 52, 60);
      P.TopBtnPress      := RGBToColor(28, 28, 32);
      P.TopBtnActiveBg   := RGBToColor(0, 122, 255);
      P.TopBtnActiveText := RGBToColor(255, 255, 255);

      P.NumBtnBg      := RGBToColor(48, 48, 54);
      P.NumBtnText    := RGBToColor(255, 255, 255);
      P.NumBtnHover   := RGBToColor(68, 68, 76);
      P.NumBtnPress   := RGBToColor(36, 36, 42);

      P.OpBtnBg       := RGBToColor(255, 149, 0); // 经典 PCalc 亮橙
      P.OpBtnText     := RGBToColor(255, 255, 255);
      P.OpBtnHover    := RGBToColor(255, 172, 40);
      P.OpBtnPress    := RGBToColor(218, 125, 0);

      P.FuncBtnBg     := RGBToColor(36, 36, 42);
      P.FuncBtnText   := RGBToColor(235, 238, 245);
      P.FuncBtnHover  := RGBToColor(54, 54, 62);
      P.FuncBtnPress  := RGBToColor(26, 26, 30);

      P.EqualBtnBg    := RGBToColor(255, 149, 0);
      P.EqualBtnText  := RGBToColor(255, 255, 255);
      P.EqualBtnHover := RGBToColor(255, 172, 40);
      P.EqualBtnPress := RGBToColor(218, 125, 0);

      P.IsDark        := True;
    end;

    ttWhite: // 优雅浅白 (高对比度清晰大字：运算符亮橙白字，功能键与数字键纯黑浓郁字)
    begin
      P.BgColor       := RGBToColor(244, 246, 250);
      P.TabBg         := RGBToColor(232, 235, 242);
      P.BorderColor   := RGBToColor(205, 210, 220);

      P.TopBarBg         := RGBToColor(232, 235, 242);
      P.TopBtnBg         := RGBToColor(255, 255, 255);
      P.TopBtnText       := RGBToColor(20, 24, 32);
      P.TopBtnHover      := RGBToColor(240, 244, 250);
      P.TopBtnPress      := RGBToColor(220, 225, 235);
      P.TopBtnActiveBg   := RGBToColor(0, 122, 255);
      P.TopBtnActiveText := RGBToColor(255, 255, 255);

      // 数字键：纯白底 + 纯黑高对比粗字
      P.NumBtnBg      := RGBToColor(255, 255, 255);
      P.NumBtnText    := RGBToColor(15, 18, 25);
      P.NumBtnHover   := RGBToColor(240, 244, 252);
      P.NumBtnPress   := RGBToColor(225, 230, 240);

      // 运算符键：经典 PCalc 亮橙底 + 纯白醒目大字 (彻底杜绝浅色背景看不清字迹)
      P.OpBtnBg       := RGBToColor(255, 149, 0);
      P.OpBtnText     := RGBToColor(255, 255, 255);
      P.OpBtnHover    := RGBToColor(255, 172, 40);
      P.OpBtnPress    := RGBToColor(218, 125, 0);

      // 功能键 (sin/cos/tan/sinh 等)：高级浅灰底 + 纯深黑挺拔粗字 (对比度 14:1)
      P.FuncBtnBg     := RGBToColor(228, 232, 240);
      P.FuncBtnText   := RGBToColor(15, 18, 25);
      P.FuncBtnHover  := RGBToColor(218, 223, 233);
      P.FuncBtnPress  := RGBToColor(202, 208, 220);

      // 等号键：经典 PCalc 亮橙底 + 纯白粗字
      P.EqualBtnBg    := RGBToColor(255, 149, 0);
      P.EqualBtnText  := RGBToColor(255, 255, 255);
      P.EqualBtnHover := RGBToColor(255, 172, 40);
      P.EqualBtnPress := RGBToColor(218, 125, 0);

      P.IsDark        := False;
    end;

    ttYellow: // 温润浅黄 (舒适护眼米黄，高对比)
    begin
      P.BgColor       := RGBToColor(250, 244, 220);
      P.TabBg         := RGBToColor(242, 235, 205);
      P.BorderColor   := RGBToColor(218, 205, 170);

      P.TopBarBg         := RGBToColor(242, 235, 205);
      P.TopBtnBg         := RGBToColor(255, 253, 242);
      P.TopBtnText       := RGBToColor(35, 22, 10);
      P.TopBtnHover      := RGBToColor(255, 255, 250);
      P.TopBtnPress      := RGBToColor(240, 232, 200);
      P.TopBtnActiveBg   := RGBToColor(225, 145, 30);
      P.TopBtnActiveText := RGBToColor(255, 255, 255);

      // 数字键：象牙温润白 + 深深褐炭字 (对比度 14:1)
      P.NumBtnBg      := RGBToColor(255, 253, 242);
      P.NumBtnText    := RGBToColor(35, 22, 10);
      P.NumBtnHover   := RGBToColor(255, 255, 250);
      P.NumBtnPress   := RGBToColor(242, 234, 210);

      // 运算符键：暖金琥珀底 + 纯白粗体字 (高饱和醒目)
      P.OpBtnBg       := RGBToColor(225, 145, 30);
      P.OpBtnText     := RGBToColor(255, 255, 255);
      P.OpBtnHover    := RGBToColor(240, 165, 50);
      P.OpBtnPress    := RGBToColor(195, 120, 15);

      // 功能键：暖米黄底 + 深深褐炭字 (对比度 12:1)
      P.FuncBtnBg     := RGBToColor(238, 228, 198);
      P.FuncBtnText   := RGBToColor(35, 22, 10);
      P.FuncBtnHover  := RGBToColor(245, 236, 208);
      P.FuncBtnPress  := RGBToColor(224, 212, 180);

      // 等号键：暖金琥珀底 + 纯白粗体字
      P.EqualBtnBg    := RGBToColor(215, 135, 20);
      P.EqualBtnText  := RGBToColor(255, 255, 255);
      P.EqualBtnHover := RGBToColor(235, 155, 40);
      P.EqualBtnPress := RGBToColor(185, 115, 10);

      P.IsDark        := False;
    end;

  end;
  Result := P;
end;


procedure SetWindowsDarkTitleBar(const AForm: TForm; const EnableDark: Boolean);
{$IFDEF WINDOWS}
var
  Val: DWORD;
begin
  if not Assigned(AForm) or not AForm.HandleAllocated then Exit;
  if EnableDark then Val := 1 else Val := 0;
  // 兼容 Win10 1809+ 与 Win11
  DwmSetWindowAttribute(AForm.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @Val, SizeOf(Val));
  DwmSetWindowAttribute(AForm.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, @Val, SizeOf(Val));
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure ApplyThemeToForm(const AForm: TForm; const ATheme: TThemeType);
var
  Palette: TThemePalette;
begin
  if not Assigned(AForm) then Exit;
  Palette := GetThemePalette(ATheme);

  AForm.Color := Palette.BgColor;
  SetWindowsDarkTitleBar(AForm, Palette.IsDark);
end;

end.
