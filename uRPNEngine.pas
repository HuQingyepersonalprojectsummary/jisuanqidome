unit uRPNEngine;

{==============================================================================
  PCalc 高级科学与工程计算器 - 经典 RPN 逆波兰堆栈计算引擎 (uRPNEngine.pas)
  ------------------------------------------------------------------------------
  本单元实现了惠普经典工程计算器标配的 4 级 RPN (Reverse Polish Notation) 堆栈：
  1. 四级寄存器堆栈结构：
     - X 寄存器：当前栈顶 (Top of Stack)，即主屏幕当前显示与交互运算数值
     - Y 寄存器：次栈顶 (Next to Top)，二元运算中的被操作数 (例如 Y - X)
     - Z 寄存器：第三级堆栈缓存
     - T 寄存器：第四级堆栈顶部 (Top-most level of 4-level stack)
  2. 完整的经典堆栈调度指令：
     - ENTER：复制并向上提升堆栈 (T <- Z <- Y <- X)
     - DROP：弹出丢弃当前栈顶 X，上层堆栈依次下落
     - SWAP (x<>y)：极速对调 X 与 Y 寄存器数值
     - Roll Down (R↓)：4 级堆栈整体向下循环滚动
     - Roll Up (R↑)：4 级堆栈整体向上循环滚动
     - ClearAll / ClearX：全部清空或仅复位当前 X 寄存器
  3. 二元运算与自动堆栈下坠 (Stack Drop)：
     - 触发二元操作符 (+, -, ×, ÷ 等) 时，取出 Y 与 X 计算，结果写入 X，
       原 Z 下坠至 Y，原 T 下坠至 Z，T 置零。
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uCalcTypes, uMathUtils;

type
  { 逆波兰 (RPN) 计算引擎类定义 }
  TRPNEngine = class
  private
    FStack: array of Double;     { 4 级堆栈数组 (0=X, 1=Y, 2=Z, 3=T) }
    FCurrentInput: string;       { X 寄存器当前的字符串显示值 }
    FIsNewInput: Boolean;        { 是否作为新数值输入的开端 }
    FJustEntered: Boolean;       { 刚按下 Enter 标记，控制下一次输入的压栈行为 }
    FAngleMode: TAngleMode;      { 三角函数角度制度 }

    procedure Push(const Val: Double);
    function Pop: Double;
    function Peek: Double;
  public
    constructor Create;
    destructor Destroy; override;

    { 堆栈生命周期与重置 }
    procedure ClearAll;          { 清空所有 4 级堆栈寄存器 (全置 0) }
    procedure ClearX;            { 仅清除当前栈顶 X 寄存器 }
    procedure Drop;              { 丢弃栈顶 X，并下坠堆栈 }
    procedure Enter;             { 压栈指令：复制当前数值并向上推入 Y, Z, T }
    procedure SwapXY;            { 交换 X 和 Y 寄存器 }
    procedure RollDown;          { 堆栈向下循环滚动 (X->T, Y->X, Z->Y, T->Z) }
    procedure RollUp;            { 堆栈向上循环滚动 (X->Y, Y->Z, Z->T, T->X) }

    { 键盘与字符输入录入接口 }
    procedure InputDigit(const Ch: Char); { 键入数字字符 '0'..'9' }
    procedure InputDot;                   { 键入小数点 '.' }
    procedure InputSign;                  { 栈顶正负号反转 }
    procedure Backspace;                  { 栈顶字符退格删除 }

    { 运算操作 }
    procedure ApplyBinary(const Op: string);       { 执行二元运算 (Y [Op] X -> X) }
    procedure ApplyUnary(const FuncName: string);  { 执行单目函数 (f(X) -> X) }

    { 堆栈监视与读取接口 }
    function GetStackCount: Integer;               { 获取当前堆栈层数 (固定为 4) }
    function GetStackValue(const Index: Integer): Double;     { 读取指定寄存器浮点值 }
    function GetStackFormatted(const Index: Integer): string; { 读取指定寄存器格式化串 }

    { 属性暴露 }
    property CurrentInput: string read FCurrentInput write FCurrentInput;
    property AngleMode: TAngleMode read FAngleMode write FAngleMode;
    property IsNewInput: Boolean read FIsNewInput write FIsNewInput;
    property JustEntered: Boolean read FJustEntered write FJustEntered;
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
  FJustEntered := False;
end;

procedure TRPNEngine.ClearX;
begin
  if Length(FStack) > 0 then
    FStack[0] := 0.0;
  FCurrentInput := '0';
  FIsNewInput := True;
  FJustEntered := False;
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
  FJustEntered := False;
end;

procedure TRPNEngine.Enter;
var
  Val: Double;
begin
  Val := StrToFloatDef(FCurrentInput, 0.0);
  Push(Val);
  FCurrentInput := FormatDisplayFloat(Val);
  FIsNewInput := True;
  FJustEntered := True;
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
  FJustEntered := False;
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
  FJustEntered := False;
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
  FJustEntered := False;
end;

procedure TRPNEngine.InputDigit(const Ch: Char);
begin
  if FIsNewInput or (FCurrentInput = '0') then
  begin
    if FIsNewInput and not FJustEntered then
      Push(StrToFloatDef(FCurrentInput, 0.0));
    FCurrentInput := Ch;
    FIsNewInput := False;
    FJustEntered := False;
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
    if not FJustEntered then
      Push(StrToFloatDef(FCurrentInput, 0.0));
    FCurrentInput := '0.';
    FIsNewInput := False;
    FJustEntered := False;
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
  FJustEntered := False;
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
  FJustEntered := False;
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
