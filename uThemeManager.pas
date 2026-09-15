unit uThemeManager;

{==============================================================================
  PCalc 高级科学与工程计算器 - 主题调色板与 DWM 沉浸视觉管理器 (uThemeManager.pas)
  ------------------------------------------------------------------------------
  本单元实现了多套现代桌面高质感 UI 主题与 Windows 系统级外观融合：
  1. 设计令牌体系 (Design Tokens Palette)：
     - 窗体底色、卡片表面底色、细线边框、无障碍焦点环
     - 独立液晶显示屏专属配色
     - 核心强调主色 (Accent / OnAccent / AccentSoft / AccentText)
     - 各语义按键 (数字键、运算符键、科学函数键、等号主动作键) 正常/悬停/按下色
  2. 三大调校主题：
     - 暗夜黑 (ttBlack): 经典石墨黑磨砂沉浸，赤陶红高亮核心动作，默认启动
     - 浅亮白 (ttWhite): 现代明亮极简风格，柔和灰白层次，按钮微凸质感
     - 温润浅黄 (ttYellow): 护眼暖米黄，长时间重度计算舒适防眩光
  3. Windows 10/11 DWM (Desktop Window Manager) 沉浸式暗色标题栏：
     - 通过直接调用 dwmapi.dll 中的 DwmSetWindowAttribute 原生 API，
       根据当前主题亮暗自适应切换 Windows 系统窗口标题栏配色。
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics, Controls, Buttons,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  uCalcTypes;

type
  { 主题配色令牌结构体 (Design Tokens Palette) }
  TThemePalette = record
    // 语义底色与卡片表面
    WindowBg: TColor;        { 窗口背景底色 }
    Surface: TColor;         { 面板与选项卡表面底色 }
    HistoryBg: TColor;       { 历史纸带列表底色 }
    BorderColor: TColor;     { 核心分割线与控件外边框色 }
    BorderSoft: TColor;      { 柔和辅助分隔线色 }
    FocusRing: TColor;       { 键盘 Tab 导航获得的无障碍焦点环色 }

    // 显示屏专属区域
    DisplayBg: TColor;       { 显示屏背景色 }
    DisplayText: TColor;     { 主算式数值大字体荧光色 }
    DisplaySubText: TColor;  { 上层公式预览与内存状态指示辅助文字色 }
    DisplayBorder: TColor;   { 显示屏边框色 }

    // 基础文本层次与状态提示
    TextPrimary: TColor;     { 一级主要文字色 }
    TextSecondary: TColor;   { 二级辅助文字色 }
    DisabledText: TColor;    { 禁用/置灰状态文字色 }
    ErrorText: TColor;       { 错误提示红字 }
    ErrorBg: TColor;         { 错误状态背景浅红微光 }

    // 强调色体系 (等号与核心主动作)
    Accent: TColor;          { 核心强调主色 }
    OnAccent: TColor;        { 位于强调主色之上的前景色 }
    AccentSoft: TColor;      { 强调色弱化背景 (用于二元运算符背景) }
    AccentText: TColor;      { 强调色前景色 (用于二元运算符文字) }

    // 语义按键交互分类色彩令牌 (用于自绘按键状态渲染)
    BgColor: TColor;
    TabBg: TColor;
    NumBtnBg: TColor;        { 数字键默认底色 }
    NumBtnText: TColor;      { 数字键文字色 }
    NumBtnHover: TColor;     { 数字键鼠标悬浮色 }
    NumBtnPress: TColor;     { 数字键鼠标按下色 }
    OpBtnBg: TColor;         { 运算符键默认底色 }
    OpBtnText: TColor;       { 运算符键文字色 }
    OpBtnHover: TColor;      { 运算符键鼠标悬浮色 }
    OpBtnPress: TColor;      { 运算符键鼠标按下色 }
    FuncBtnBg: TColor;       { 函数键默认底色 }
    FuncBtnText: TColor;     { 函数键文字色 }
    FuncBtnHover: TColor;    { 函数键鼠标悬浮色 }
    FuncBtnPress: TColor;    { 函数键鼠标按下色 }
    EqualBtnBg: TColor;      { 等号主键默认底色 }
    EqualBtnText: TColor;    { 等号主键文字色 }
    EqualBtnHover: TColor;   { 等号主键鼠标悬浮色 }
    EqualBtnPress: TColor;   { 等号主键鼠标按下色 }

    // 顶部栏与导航按键配色
    TopBarBg: TColor;
    TopBtnBg: TColor;
    TopBtnText: TColor;
    TopBtnHover: TColor;
    TopBtnPress: TColor;
    TopBtnActiveBg: TColor;
    TopBtnActiveText: TColor;
    IsDark: Boolean;         { 该主题是否属于深色调 (决定系统标题栏暗色属性) }
  end;

{ 获取指定主题的完整调色板令牌 }
function GetThemePalette(const ATheme: TThemeType): TThemePalette;

{ 根据按键语义角色提取该按键在调色板中对应的背景色、前景色、边框色、悬停色与按下色 }
procedure GetRoleColors(const P: TThemePalette; const ARole: TCalcButtonRole;
  out ABg, AText, ABorder, AHover, APress: TColor);

{ 将指定主题应用至窗体基础底色与系统标题栏 }
procedure ApplyThemeToForm(const AForm: TForm; const ATheme: TThemeType);

{ 切换 Windows 10/11 DWM 沉浸式暗色标题栏属性 }
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
  case ATheme of
    ttBlack: // 经典极客黑 / 石墨黑 (深邃质感，符合专业计算器规范)
    begin
      P.IsDark        := True;
      P.WindowBg      := RGBToColor($20, $21, $23);
      P.Surface       := RGBToColor($29, $2A, $2D);
      P.HistoryBg     := RGBToColor($24, $25, $27);
      P.BorderColor   := RGBToColor($3B, $3D, $3E);
      P.BorderSoft    := RGBToColor($32, $34, $36);
      P.FocusRing     := RGBToColor($F5, $B3, $94);

      // 显示屏区域
      P.DisplayBg      := RGBToColor($1C, $1E, $20);
      P.DisplayText    := RGBToColor($F3, $F2, $ED);
      P.DisplaySubText := RGBToColor($A8, $AB, $A5);
      P.DisplayBorder  := P.BorderColor;

      // 文本与状态
      P.TextPrimary   := RGBToColor($F3, $F2, $ED);
      P.TextSecondary := RGBToColor($A8, $AB, $A5);
      P.DisabledText  := RGBToColor($5A, $5D, $58);
      P.ErrorText     := RGBToColor($FF, $6B, $6B);
      P.ErrorBg       := RGBToColor($3D, $1F, $1F);

      // 强调色体系
      P.Accent        := RGBToColor($B7, $4C, $2B); // 经典赤陶红
      P.OnAccent      := RGBToColor($FF, $F8, $F2);
      P.AccentSoft    := RGBToColor($42, $31, $28);
      P.AccentText    := RGBToColor($F5, $B3, $94);

      // 兼容分类配色
      P.BgColor       := P.WindowBg;
      P.TabBg         := P.Surface;

      P.NumBtnBg      := RGBToColor($36, $38, $3B);
      P.NumBtnText    := P.TextPrimary;
      P.NumBtnHover   := RGBToColor($48, $4A, $4E);
      P.NumBtnPress   := RGBToColor($28, $29, $2B);

      P.OpBtnBg       := P.AccentSoft;
      P.OpBtnText     := P.AccentText;
      P.OpBtnHover    := RGBToColor($54, $3E, $33);
      P.OpBtnPress    := RGBToColor($33, $24, $1E);

      P.FuncBtnBg     := RGBToColor($2D, $2F, $32);
      P.FuncBtnText   := P.TextSecondary;
      P.FuncBtnHover  := RGBToColor($3C, $3E, $42);
      P.FuncBtnPress  := RGBToColor($22, $23, $25);

      P.EqualBtnBg    := P.Accent;
      P.EqualBtnText  := P.OnAccent;
      P.EqualBtnHover := RGBToColor($C9, $57, $35);
      P.EqualBtnPress := RGBToColor($9E, $3E, $21);

      P.TopBarBg         := P.WindowBg;
      P.TopBtnBg         := P.Surface;
      P.TopBtnText       := P.TextPrimary;
      P.TopBtnHover      := RGBToColor($3C, $3E, $42);
      P.TopBtnPress      := RGBToColor($20, $21, $23);
      P.TopBtnActiveBg   := P.AccentSoft;
      P.TopBtnActiveText := P.AccentText;
    end;

    ttWhite: // 暖白主题 (清爽现代，显示屏随主题切换为浅色，对比度达标)
    begin
      P.IsDark        := False;
      P.WindowBg      := RGBToColor($F5, $F4, $F1);
      P.Surface       := RGBToColor($FC, $FC, $FB);
      P.HistoryBg     := RGBToColor($EE, $ED, $E9);
      P.BorderColor   := RGBToColor($DC, $DE, $D8);
      P.BorderSoft    := RGBToColor($E6, $E8, $E2);
      P.FocusRing     := RGBToColor($B7, $4C, $2B);

      // 显示屏区域跟随浅色主题
      P.DisplayBg      := P.Surface;
      P.DisplayText    := RGBToColor($24, $27, $24);
      P.DisplaySubText := RGBToColor($62, $66, $60);
      P.DisplayBorder  := P.BorderColor;

      // 文本与状态
      P.TextPrimary   := RGBToColor($24, $27, $24);
      P.TextSecondary := RGBToColor($62, $66, $60);
      P.DisabledText  := RGBToColor($9E, $A2, $9C);
      P.ErrorText     := RGBToColor($C8, $32, $32);
      P.ErrorBg       := RGBToColor($FD, $E8, $E8);

      // 强调色体系
      P.Accent        := RGBToColor($B7, $4C, $2B);
      P.OnAccent      := RGBToColor($FF, $F8, $F2);
      P.AccentSoft    := RGBToColor($F4, $E5, $DC);
      P.AccentText    := RGBToColor($96, $3D, $21);

      // 兼容分类配色
      P.BgColor       := P.WindowBg;
      P.TabBg         := P.Surface;

      P.NumBtnBg      := RGBToColor($FF, $FF, $FF);
      P.NumBtnText    := P.TextPrimary;
      P.NumBtnHover   := RGBToColor($EE, $EE, $EB);
      P.NumBtnPress   := RGBToColor($E0, $DF, $DB);

      P.OpBtnBg       := P.AccentSoft;
      P.OpBtnText     := P.AccentText;
      P.OpBtnHover    := RGBToColor($EB, $D5, $C8);
      P.OpBtnPress    := RGBToColor($DE, $C4, $B5);

      P.FuncBtnBg     := RGBToColor($E9, $E8, $E4);
      P.FuncBtnText   := P.TextSecondary;
      P.FuncBtnHover  := RGBToColor($DE, $DD, $D8);
      P.FuncBtnPress  := RGBToColor($CF, $CE, $C8);

      P.EqualBtnBg    := P.Accent;
      P.EqualBtnText  := P.OnAccent;
      P.EqualBtnHover := RGBToColor($C9, $57, $35);
      P.EqualBtnPress := RGBToColor($9E, $3E, $21);

      P.TopBarBg         := P.WindowBg;
      P.TopBtnBg         := P.Surface;
      P.TopBtnText       := P.TextPrimary;
      P.TopBtnHover      := RGBToColor($EE, $EE, $EB);
      P.TopBtnPress      := RGBToColor($DE, $DD, $D8);
      P.TopBtnActiveBg   := P.AccentSoft;
      P.TopBtnActiveText := P.AccentText;
    end;

    ttYellow: // 温润浅黄 (护眼米黄兼容配色)
    begin
      P.IsDark        := False;
      P.WindowBg      := RGBToColor($FA, $F4, $DC);
      P.Surface       := RGBToColor($FF, $FD, $F2);
      P.HistoryBg     := RGBToColor($F2, $EB, $C5);
      P.BorderColor   := RGBToColor($DA, $CD, $AA);
      P.BorderSoft    := RGBToColor($E6, $DB, $C0);
      P.FocusRing     := RGBToColor($D7, $87, $14);

      P.DisplayBg      := P.Surface;
      P.DisplayText    := RGBToColor($23, $16, $0A);
      P.DisplaySubText := RGBToColor($6B, $5B, $49);
      P.DisplayBorder  := P.BorderColor;

      P.TextPrimary   := RGBToColor($23, $16, $0A);
      P.TextSecondary := RGBToColor($6B, $5B, $49);
      P.DisabledText  := RGBToColor($A0, $94, $84);
      P.ErrorText     := RGBToColor($C8, $32, $32);
      P.ErrorBg       := RGBToColor($FD, $E8, $E8);

      P.Accent        := RGBToColor($D7, $87, $14);
      P.OnAccent      := RGBToColor($FF, $FF, $FF);
      P.AccentSoft    := RGBToColor($F9, $E0, $B2);
      P.AccentText    := RGBToColor($8A, $4A, $05);

      P.BgColor       := P.WindowBg;
      P.TabBg         := P.Surface;

      P.NumBtnBg      := RGBToColor($FF, $FD, $F2);
      P.NumBtnText    := P.TextPrimary;
      P.NumBtnHover   := RGBToColor($F4, $F0, $DA);
      P.NumBtnPress   := RGBToColor($E8, $E0, $C4);

      P.OpBtnBg       := P.AccentSoft;
      P.OpBtnText     := P.AccentText;
      P.OpBtnHover    := RGBToColor($F3, $D4, $9E);
      P.OpBtnPress    := RGBToColor($E8, $C4, $88);

      P.FuncBtnBg     := RGBToColor($EE, $E4, $C6);
      P.FuncBtnText   := P.TextSecondary;
      P.FuncBtnHover  := RGBToColor($E2, $D6, $B6);
      P.FuncBtnPress  := RGBToColor($D4, $C6, $A2);

      P.EqualBtnBg    := P.Accent;
      P.EqualBtnText  := P.OnAccent;
      P.EqualBtnHover := RGBToColor($E8, $9B, $2A);
      P.EqualBtnPress := RGBToColor($B8, $6E, $08);

      P.TopBarBg         := P.WindowBg;
      P.TopBtnBg         := P.Surface;
      P.TopBtnText       := P.TextPrimary;
      P.TopBtnHover      := RGBToColor($F4, $F0, $DA);
      P.TopBtnPress      := RGBToColor($E8, $E0, $C4);
      P.TopBtnActiveBg   := P.AccentSoft;
      P.TopBtnActiveText := P.AccentText;
    end;
  end;

  Result := P;
end;

procedure GetRoleColors(const P: TThemePalette; const ARole: TCalcButtonRole;
  out ABg, AText, ABorder, AHover, APress: TColor);
begin
  ABorder := P.BorderColor;
  case ARole of
    cbrNumber:
    begin
      ABg := P.NumBtnBg;
      AText := P.NumBtnText;
      AHover := P.NumBtnHover;
      APress := P.NumBtnPress;
    end;
    cbrFunction:
    begin
      ABg := P.FuncBtnBg;
      AText := P.FuncBtnText;
      AHover := P.FuncBtnHover;
      APress := P.FuncBtnPress;
    end;
    cbrOperator:
    begin
      ABg := P.OpBtnBg;
      AText := P.OpBtnText;
      AHover := P.OpBtnHover;
      APress := P.OpBtnPress;
    end;
    cbrPrimary:
    begin
      ABg := P.EqualBtnBg;
      AText := P.EqualBtnText;
      AHover := P.EqualBtnHover;
      APress := P.EqualBtnPress;
    end;
    cbrNavigation:
    begin
      ABg := P.TopBtnBg;
      AText := P.TopBtnText;
      AHover := P.TopBtnHover;
      APress := P.TopBtnPress;
    end;
    cbrUtility:
    begin
      ABg := P.FuncBtnBg;
      AText := P.TextPrimary;
      AHover := P.FuncBtnHover;
      APress := P.FuncBtnPress;
    end;
    cbrBit:
    begin
      ABg := P.NumBtnBg;
      AText := P.TextPrimary;
      AHover := P.NumBtnHover;
      APress := P.NumBtnPress;
    end;
  end;
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
