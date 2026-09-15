unit uCalcButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, LCLType, LCLIntf, Types;

type
  TCalcButton = class(TCustomControl)
  private
    FBgColor: TColor;
    FTextColor: TColor;
    FBorderColor: TColor;
    FHoverColor: TColor;
    FPressColor: TColor;
    FDownBgColor: TColor;
    FDownTextColor: TColor;
    FCornerRadius: Integer;
    FIsHovered: Boolean;
    FIsPressed: Boolean;
    FIsDown: Boolean;
    FMouseCaptured: Boolean;
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
    procedure TextChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;
    procedure SetColors(const ABg, AText, ABorder, AHover, APress: TColor);
    procedure SetDownColors(const ABg, AText: TColor);
  published
    property Caption;
    property BgColor: TColor read FBgColor write SetBgColor;
    property TextColor: TColor read FTextColor write SetTextColor;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property IsDown: Boolean read FIsDown write SetIsDown;
    property DownBgColor: TColor read FDownBgColor write SetDownBgColor;
    property DownTextColor: TColor read FDownTextColor write SetDownTextColor;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius;
    property OnClick;
  end;

implementation

constructor TCalcButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  DoubleBuffered := True;
  FBgColor := clBtnFace;
  FTextColor := clWindowText;
  FBorderColor := clGray;
  FHoverColor := clHighlight;
  FPressColor := clMedGray;
  FDownBgColor := RGBToColor(0, 122, 255);
  FDownTextColor := clWhite;
  FIsHovered := False;
  FIsPressed := False;
  FIsDown := False;
  FCornerRadius := 6;
  FMouseCaptured := False;
  Cursor := crHandPoint;
  Font.Name := 'Microsoft YaHei UI';
  Font.Size := 11;
  Font.Style := [fsBold];
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

procedure TCalcButton.Paint;
var
  CurBg, CurTxtColor: TColor;
  TxtRect: TRect;
  Flags: Cardinal;
  TextStr: string;
begin
  if (Width < 2) or (Height < 2) then Exit;

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
      Canvas.Font.Color := clGray;
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
end;

end.
