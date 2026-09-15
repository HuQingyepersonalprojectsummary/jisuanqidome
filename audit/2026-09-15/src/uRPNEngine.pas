unit uRPNEngine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uCalcTypes, uMathUtils;

type
  { 逆波兰 (RPN) 计算引擎 }
  TRPNEngine = class
  private
    FStack: array of Double;
    FCurrentInput: string;
    FIsNewInput: Boolean;
    FAngleMode: TAngleMode;

    procedure Push(const Val: Double);
    function Pop: Double;
    function Peek: Double;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ClearAll;
    procedure ClearX;
    procedure Drop;
    procedure Enter;
    procedure SwapXY;
    procedure RollDown;
    procedure RollUp;

    procedure InputDigit(const Ch: Char);
    procedure InputDot;
    procedure InputSign;
    procedure Backspace;

    procedure ApplyBinary(const Op: string);
    procedure ApplyUnary(const FuncName: string);

    function GetStackCount: Integer;
    function GetStackValue(const Index: Integer): Double;
    function GetStackFormatted(const Index: Integer): string;

    property CurrentInput: string read FCurrentInput write FCurrentInput;
    property AngleMode: TAngleMode read FAngleMode write FAngleMode;
    property IsNewInput: Boolean read FIsNewInput write FIsNewInput;
  end;

implementation

constructor TRPNEngine.Create;
begin
  inherited Create;
  FAngleMode := amDeg;
  ClearAll;
end;

destructor TRPNEngine.Destroy;
begin
  SetLength(FStack, 0);
  inherited Destroy;
end;

procedure TRPNEngine.ClearAll;
begin
  SetLength(FStack, 4);
  FStack[0] := 0.0; // X
  FStack[1] := 0.0; // Y
  FStack[2] := 0.0; // Z
  FStack[3] := 0.0; // T
  FCurrentInput := '0';
  FIsNewInput := True;
end;

procedure TRPNEngine.ClearX;
begin
  if Length(FStack) > 0 then
    FStack[0] := 0.0;
  FCurrentInput := '0';
  FIsNewInput := True;
end;

procedure TRPNEngine.Push(const Val: Double);
begin
  if Length(FStack) < 4 then SetLength(FStack, 4);
  FStack[3] := FStack[2];
  FStack[2] := FStack[1];
  FStack[1] := FStack[0];
  FStack[0] := Val;
end;

function TRPNEngine.Pop: Double;
begin
  if Length(FStack) < 4 then SetLength(FStack, 4);
  Result := FStack[0];
  FStack[0] := FStack[1];
  FStack[1] := FStack[2];
  FStack[2] := FStack[3];
  FStack[3] := 0.0;
end;

function TRPNEngine.Peek: Double;
begin
  if Length(FStack) > 0 then
    Result := FStack[0]
  else
    Result := 0.0;
end;

procedure TRPNEngine.Drop;
begin
  Pop;
  FCurrentInput := FormatDisplayFloat(Peek);
  FIsNewInput := True;
end;

procedure TRPNEngine.Enter;
var
  Val: Double;
begin
  Val := StrToFloatDef(FCurrentInput, 0.0);
  Push(Val);
  FCurrentInput := FormatDisplayFloat(Val);
  FIsNewInput := True;
end;

procedure TRPNEngine.SwapXY;
var
  Temp: Double;
begin
  if Length(FStack) < 2 then Exit;
  Temp := FStack[0];
  FStack[0] := FStack[1];
  FStack[1] := Temp;
  FCurrentInput := FormatDisplayFloat(FStack[0]);
  FIsNewInput := True;
end;

procedure TRPNEngine.RollDown;
var
  Temp: Double;
begin
  if Length(FStack) < 4 then SetLength(FStack, 4);
  Temp := FStack[0];
  FStack[0] := FStack[1];
  FStack[1] := FStack[2];
  FStack[2] := FStack[3];
  FStack[3] := Temp;
  FCurrentInput := FormatDisplayFloat(FStack[0]);
  FIsNewInput := True;
end;

procedure TRPNEngine.RollUp;
var
  Temp: Double;
begin
  if Length(FStack) < 4 then SetLength(FStack, 4);
  Temp := FStack[3];
  FStack[3] := FStack[2];
  FStack[2] := FStack[1];
  FStack[1] := FStack[0];
  FStack[0] := Temp;
  FCurrentInput := FormatDisplayFloat(FStack[0]);
  FIsNewInput := True;
end;

procedure TRPNEngine.InputDigit(const Ch: Char);
begin
  if FIsNewInput or (FCurrentInput = '0') then
  begin
    FCurrentInput := Ch;
    FIsNewInput := False;
  end
  else
  begin
    if Length(FCurrentInput) < 24 then
      FCurrentInput := FCurrentInput + Ch;
  end;
  if Length(FStack) > 0 then
    FStack[0] := StrToFloatDef(FCurrentInput, 0.0);
end;

procedure TRPNEngine.InputDot;
begin
  if FIsNewInput then
  begin
    FCurrentInput := '0.';
    FIsNewInput := False;
  end
  else if Pos('.', FCurrentInput) = 0 then
  begin
    FCurrentInput := FCurrentInput + '.';
  end;
  if Length(FStack) > 0 then
    FStack[0] := StrToFloatDef(FCurrentInput, 0.0);
end;

procedure TRPNEngine.InputSign;
begin
  if Length(FStack) > 0 then
  begin
    FStack[0] := -FStack[0];
    FCurrentInput := FormatDisplayFloat(FStack[0]);
  end;
end;

procedure TRPNEngine.Backspace;
begin
  if FIsNewInput then Exit;
  if Length(FCurrentInput) > 0 then
    Delete(FCurrentInput, Length(FCurrentInput), 1);
  if (FCurrentInput = '') or (FCurrentInput = '-') then
  begin
    FCurrentInput := '0';
    FIsNewInput := True;
  end;
  if Length(FStack) > 0 then
    FStack[0] := StrToFloatDef(FCurrentInput, 0.0);
end;

procedure TRPNEngine.ApplyBinary(const Op: string);
var
  X, Y, Res: Double;
begin
  if Length(FStack) < 2 then Exit;

  // X 是栈顶，Y 是次栈顶
  X := FStack[0];
  Y := FStack[1];

  if Op = '+' then Res := Y + X
  else if Op = '-' then Res := Y - X
  else if (Op = '×') or (Op = '*') then Res := Y * X
  else if (Op = '÷') or (Op = '/') then
  begin
    if X = 0.0 then raise Exception.Create('除数不能为 0');
    Res := Y / X;
  end
  else if Op = 'MOD' then
  begin
    if X = 0.0 then raise Exception.Create('模运算除数不能为 0');
    Res := Trunc(Y) mod Trunc(X);
  end
  else if Op = 'nPr' then Res := CalcPermutation(Y, X)
  else if Op = 'nCr' then Res := CalcCombination(Y, X)
  else if (Op = '^') or (Op = 'xʸ') then Res := CalcPower(Y, X)
  else if Op = 'y√x' then Res := CalcRoot(Y, X)
  else Res := X;

  Res := SanitizeFloat(Res);
  // 二元运算后堆栈下坠
  FStack[0] := Res;
  FStack[1] := FStack[2];
  FStack[2] := FStack[3];
  FStack[3] := 0.0;

  FCurrentInput := FormatDisplayFloat(Res);
  FIsNewInput := True;
end;

procedure TRPNEngine.ApplyUnary(const FuncName: string);
var
  Val, Res: Double;
begin
  if Length(FStack) = 0 then Exit;
  Val := FStack[0];

  if FuncName = 'sqrt' then
  begin
    if Val < 0.0 then raise Exception.Create('负数不能开平方根');
    Res := Sqrt(Val);
  end
  else if FuncName = 'sqr' then Res := Sqr(Val)
  else if FuncName = 'cube' then Res := Val * Val * Val
  else if FuncName = 'inv' then
  begin
    if Val = 0.0 then raise Exception.Create('除数不能为 0');
    Res := 1.0 / Val;
  end
  else if FuncName = 'abs' then Res := Abs(Val)
  else if FuncName = 'sin' then Res := CalcSin(Val, FAngleMode)
  else if FuncName = 'cos' then Res := CalcCos(Val, FAngleMode)
  else if FuncName = 'tan' then Res := CalcTan(Val, FAngleMode)
  else if FuncName = 'asin' then Res := CalcArcSin(Val, FAngleMode)
  else if FuncName = 'acos' then Res := CalcArcCos(Val, FAngleMode)
  else if FuncName = 'atan' then Res := CalcArcTan(Val, FAngleMode)
  else if FuncName = 'sinh' then Res := CalcSinh(Val)
  else if FuncName = 'cosh' then Res := CalcCosh(Val)
  else if FuncName = 'tanh' then Res := CalcTanh(Val)
  else if FuncName = 'log10' then
  begin
    if Val <= 0.0 then raise Exception.Create('常用对数真数必须大于 0');
    Res := Log10(Val);
  end
  else if FuncName = 'ln' then
  begin
    if Val <= 0.0 then raise Exception.Create('自然对数真数必须大于 0');
    Res := Ln(Val);
  end
  else if FuncName = 'exp' then Res := Exp(Val)
  else if FuncName = 'fact' then Res := CalcFactorial(Val)
  else Res := Val;

  Res := SanitizeFloat(Res);
  FStack[0] := Res;
  FCurrentInput := FormatDisplayFloat(Res);
  FIsNewInput := True;
end;

function TRPNEngine.GetStackCount: Integer;
begin
  Result := Length(FStack);
end;

function TRPNEngine.GetStackValue(const Index: Integer): Double;
begin
  if (Index >= 0) and (Index < Length(FStack)) then
    Result := FStack[Index]
  else
    Result := 0.0;
end;

function TRPNEngine.GetStackFormatted(const Index: Integer): string;
begin
  Result := FormatDisplayFloat(GetStackValue(Index));
end;

end.
