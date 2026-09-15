unit uCalcButton;

{==============================================================================
  PCalc 高级科学与工程计算器 - 语义化自绘按键组件单元 (uCalcButton.pas)
  ------------------------------------------------------------------------------
  本单元实现了计算器专用的自绘按键控件 (TCalcButton)，相比原生 Windows 按钮：
  1. 具备语义角色 (Role: TCalcButtonRole)，与主题管理器 (uThemeManager) 无缝配合
  2. 采用原生 GDI/LCL 自绘与双缓冲 (DoubleBuffered)，彻底杜绝闪烁
  3. 平滑圆角矩形渲染 (RoundRect) 并智能预先擦除圆角四个外围死角的底色残影
  4. 完整的交互状态机：
     - 正常态 (Normal)、鼠标悬浮态 (Hovered)、鼠标按下态 (Pressed)
     - 切换按下保持态 (IsDown: 用于 2nd 切换或 DEG/RAD 选中)
     - 键盘空格/回车按下联动与文字 1px 微偏移沉浸动效 (Tactile Feedback)
  5. 完整的无障碍辅助 (Accessibility)：
     - 支持焦点虚线框 (Focus Ring)，按 Tab 键可平滑导航并可通过 Enter/Space 激活
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, LCLType, LCLIntf, Types, Math,
  uCalcTypes;

type
  { 自绘语义计算器按钮组件类 }
  TCalcButton = class(TCustomControl)
  private
    FRole: TCalcButtonRole;      { 语义角色 (数字、运算符、函数、等号、导航) }
    FBgColor: TColor;            { 常态底色 }
    FTextColor: TColor;          { 常态文字颜色 }
    FBorderColor: TColor;        { 边框细线颜色 }
    FHoverColor: TColor;         { 鼠标悬浮底色 }
    FPressColor: TColor;         { 鼠标按下底色 }
    FDownBgColor: TColor;        { 保持按下激活态底色 }
    FDownTextColor: TColor;      { 保持按下激活态文字色 }
    FFocusRingColor: TColor;     { 键盘焦点虚线环颜色 }
    FDisabledTextColor: TColor;  { 禁用置灰文字颜色 }
    FCornerRadius: Integer;      { 圆角弧度像素半径 }
    FIsHovered: Boolean;         { 鼠标悬浮标志位 }
    FIsPressed: Boolean;         { 鼠标按下标志位 }
    FIsDown: Boolean;            { 切换锁定保持按下标志位 }
    FIsKeyPressed: Boolean;      { 键盘按键触发按下标志位 }
    FMouseCaptured: Boolean;     { 鼠标捕获跟踪标志位 }

    procedure SetRole(const AValue: TCalcButtonRole);
    procedure SetBgColor(const AValue: TColor);
    procedure SetTextColor(const AValue: TColor);
    procedure SetBorderColor(const AValue: TColor);
    procedure SetIsDown(const AValue: Boolean);
    procedure SetDownBgColor(const AValue: TColor);
    procedure SetDownTextColor(const AValue: TColor);
    procedure SetCornerRadius(const AValue: Integer);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure TextChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;

    { 批量设置按键交互色彩令牌 }
    procedure SetColors(const ABg, AText, ABorder, AHover, APress: TColor);
    procedure SetDownColors(const ABg, AText: TColor);
  published
    property Caption;
    property Role: TCalcButtonRole read FRole write SetRole;
    property BgColor: TColor read FBgColor write SetBgColor;
    property TextColor: TColor read FTextColor write SetTextColor;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property FocusRingColor: TColor read FFocusRingColor write FFocusRingColor;
    property DisabledTextColor: TColor read FDisabledTextColor write FDisabledTextColor;
    property IsDown: Boolean read FIsDown write SetIsDown;
    property DownBgColor: TColor read FDownBgColor write SetDownBgColor;
    property DownTextColor: TColor read FDownTextColor write SetDownTextColor;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius;
    property TabStop default True;
    property OnClick;
  end;

implementation

constructor TCalcButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  DoubleBuffered := True;
  TabStop := True;
  FRole := cbrFunction;
  FBgColor := clBtnFace;
  FTextColor := clWindowText;
  FBorderColor := clGray;
  FHoverColor := clHighlight;
  FPressColor := clMedGray;
  FDownBgColor := RGBToColor(183, 76, 43);
  FDownTextColor := clWhite;
  FFocusRingColor := RGBToColor(183, 76, 43);
  FDisabledTextColor := clGray;
  FIsHovered := False;
  FIsPressed := False;
  FIsDown := False;
  FIsKeyPressed := False;
  FCornerRadius := 10;
  FMouseCaptured := False;
  Cursor := crHandPoint;
  Font.Name := 'Microsoft YaHei UI';
  Font.Size := 11;
  Font.Style := [];
end;

procedure TCalcButton.SetRole(const AValue: TCalcButtonRole);
begin
  if FRole <> AValue then
  begin
    FRole := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.TextChanged;
begin
  inherited TextChanged;
  Invalidate;
end;

procedure TCalcButton.Click;
begin
  inherited Click;
end;

procedure TCalcButton.SetBgColor(const AValue: TColor);
begin
  if FBgColor <> AValue then
  begin
    FBgColor := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetTextColor(const AValue: TColor);
begin
  if FTextColor <> AValue then
  begin
    FTextColor := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetIsDown(const AValue: Boolean);
begin
  if FIsDown <> AValue then
  begin
    FIsDown := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetDownBgColor(const AValue: TColor);
begin
  if FDownBgColor <> AValue then
  begin
    FDownBgColor := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetDownTextColor(const AValue: TColor);
begin
  if FDownTextColor <> AValue then
  begin
    FDownTextColor := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetCornerRadius(const AValue: Integer);
begin
  if FCornerRadius <> AValue then
  begin
    FCornerRadius := AValue;
    Invalidate;
  end;
end;

procedure TCalcButton.SetColors(const ABg, AText, ABorder, AHover, APress: TColor);
begin
  FBgColor := ABg;
  FTextColor := AText;
  FBorderColor := ABorder;
  FHoverColor := AHover;
  FPressColor := APress;
  Invalidate;
end;

procedure TCalcButton.SetDownColors(const ABg, AText: TColor);
begin
  FDownBgColor := ABg;
  FDownTextColor := AText;
  Invalidate;
end;

procedure TCalcButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    if CanFocus and not Focused then
      SetFocus;
    FMouseCaptured := True;
    FIsPressed := True;
    Invalidate;
  end;
end;

procedure TCalcButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewPressed: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  if FMouseCaptured then
  begin
    NewPressed := PtInRect(ClientRect, Point(X, Y));
    if NewPressed <> FIsPressed then
    begin
      FIsPressed := NewPressed;
      Invalidate;
    end;
  end;
end;

procedure TCalcButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FMouseCaptured := False;
    FIsPressed := False;
    Invalidate;
  end;
end;

procedure TCalcButton.MouseEnter;
begin
  inherited MouseEnter;
  if Enabled then
  begin
    FIsHovered := True;
    Invalidate;
  end;
end;

procedure TCalcButton.MouseLeave;
begin
  inherited MouseLeave;
  FIsHovered := False;
  if not FMouseCaptured then
    FIsPressed := False;
  Invalidate;
end;

procedure TCalcButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if Enabled and ((Key = VK_SPACE) or (Key = VK_RETURN)) and not FIsKeyPressed then
  begin
    FIsKeyPressed := True;
    FIsPressed := True;
    Invalidate;
    Key := 0;
  end;
end;

procedure TCalcButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if Enabled and FIsKeyPressed and ((Key = VK_SPACE) or (Key = VK_RETURN)) then
  begin
    FIsKeyPressed := False;
    FIsPressed := False;
    Invalidate;
    Click;
    Key := 0;
  end;
end;

procedure TCalcButton.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TCalcButton.DoExit;
begin
  inherited DoExit;
  FIsPressed := False;
  FIsKeyPressed := False;
  Invalidate;
end;

procedure TCalcButton.Paint;
var
  CurBg, CurTxtColor: TColor;
  TxtRect: TRect;
  Flags: Cardinal;
  TextStr: string;
  ParentBg: TColor;
begin
  if (Width < 2) or (Height < 2) then Exit;

  // 1. 先用父容器底色擦除整个矩形，消除 csOpaque 配合 RoundRect 在四个圆角留下旧底色残影
  ParentBg := clBtnFace;
  if Assigned(Parent) then
    ParentBg := Parent.Brush.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := ParentBg;
  Canvas.FillRect(ClientRect);

  TextStr := Caption;

  if not Enabled then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := FBgColor;
    Canvas.Pen.Color := FBorderColor;
    Canvas.Pen.Width := 1;
    Canvas.RoundRect(0, 0, Width, Height, FCornerRadius, FCornerRadius);

    if Length(TextStr) > 0 then
    begin
      Canvas.Font := Self.Font;
      Canvas.Font.Color := FDisabledTextColor;
      Canvas.Brush.Style := bsClear;
      TxtRect := ClientRect;
      Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
      DrawText(Canvas.Handle, PChar(TextStr), Length(TextStr), TxtRect, Flags);
    end;
    Exit;
  end;

  if FIsPressed then
  begin
    CurBg := FPressColor;
    CurTxtColor := FTextColor;
  end
  else if FIsDown then
  begin
    CurBg := FDownBgColor;
    CurTxtColor := FDownTextColor;
  end
  else if FIsHovered then
  begin
    CurBg := FHoverColor;
    CurTxtColor := FTextColor;
  end
  else
  begin
    CurBg := FBgColor;
    CurTxtColor := FTextColor;
  end;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := CurBg;
  Canvas.Pen.Color := FBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.RoundRect(0, 0, Width, Height, FCornerRadius, FCornerRadius);

  if Length(TextStr) > 0 then
  begin
    Canvas.Font.Assign(Self.Font);
    Canvas.Font.Color := CurTxtColor;
    Canvas.Brush.Style := bsClear;

    TxtRect := ClientRect;
    if FIsPressed then
      Types.OffsetRect(TxtRect, 1, 1);

    Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
    DrawText(Canvas.Handle, PChar(TextStr), Length(TextStr), TxtRect, Flags);
  end;

  // 4. 获得焦点时绘制无障碍焦点环
  if Focused then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := FFocusRingColor;
    Canvas.Pen.Style := psDot;
    Canvas.Pen.Width := 1;
    Canvas.RoundRect(2, 2, Width - 2, Height - 2, Max(2, FCornerRadius - 2), Max(2, FCornerRadius - 2));
    Canvas.Pen.Style := psSolid;
  end;
end;

end.
