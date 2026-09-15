unit uAlgebraicEngine;

{==============================================================================
  PCalc 高级科学与工程计算器 - 代数表达式求值引擎单元 (uAlgebraicEngine.pas)
  ------------------------------------------------------------------------------
  本单元实现了功能强大、鲁棒性极高的代数/科学模式计算核心：
  1. 支持完整的运算符优先级调度 (Shunting-yard 算法思想变种，双栈调度)
  2. 支持无限级嵌套括号运算 ( ) 与严格的不匹配/未闭合异常捕获
  3. 支持幂运算与多重幂的右结合性 (Right-Associative: 2^3^2 = 2^(3^2) = 512)
  4. 支持复合一元函数 (sin, cos, ln, x², sqrt 等) 在连续算式中无缝求值
  5. 支持连续按等号重复执行最后一步二元运算 (例如 5 + 2 = 7, 继续按 = 变为 9, 11)
  6. 完善的非阻塞除零与异常状态自愈机制 (报错置为 'Error'，后续键入自动重置)
  7. 独立物理级内存系统 (MC 清空, MR 读出, MS 写入, M+ 累加, M- 累减)
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uCalcTypes, uMathUtils;

type
  { 代数表达式词法标记类型 }
  TTokenType = (
    ttNumber,      { 数值操作数 (Double) }
    ttOperator,    { 二元运算符 (+, -, ×, ÷, MOD, ^, y√x, nPr, nCr) }
    ttOpenParen,   { 左括号 '(' }
    ttCloseParen   { 右括号 ')' }
  );

  { 表达式分词标记结构体 }
  TToken = record
    TokenType: TTokenType; { 标记类别 }
    Value: Double;         { 当为数值时的浮点字面量 }
    Op: string;            { 当为操作符或括号时的文本符号 }
  end;

  { 代数计算引擎类定义 }
  TAlgebraicEngine = class
  private
    FTokens: array of TToken;    { 当前已录入待求值的标记序列 }
    FCurrentInput: string;       { 当前主显示屏/输入寄存器的字符串表示 }
    FIsNewInput: Boolean;        { 下一次键入是否覆盖当前屏幕（新数起点） }
    FOperandReady: Boolean;      { 标识是否有通过函数/常数/内存提取准备好的操作数 }
    FMemory: Double;             { 独立记忆体存储槽 (MC/MR/MS/M+/M-) }
    FAngleMode: TAngleMode;      { 当前三角函数所遵从的角度制度 }
    FLastResult: Double;         { 最近一次计算得出的结果缓存 }
    FLastOp: string;             { 记录最近一次二元运算符，用于重复等号逻辑 }
    FLastOperand: Double;        { 记录最近一次二元运算右操作数，用于重复等号逻辑 }
    FHasLastOp: Boolean;         { 是否存在可供重复等号执行的历史二元操作 }
    FExpressionStr: string;      { 副显示屏完整公式预览字符串 (如 "2 + 3 × 4") }

    procedure AddToken(const AType: TTokenType; const AVal: Double; const AOp: string);
    function EvaluateTokens(out AResult: Double): Boolean;
    function GetPrecedence(const Op: string): Integer;
    function IsRightAssociative(const Op: string): Boolean;
    function ApplyBinaryOp(const A, B: Double; const Op: string): Double;
    procedure UpdateExpressionString;
  public
    constructor Create;
    destructor Destroy; override;

    { 状态清空与输入退格 }
    procedure ClearAll;          { 全部复位 (相当于 AC) }
    procedure ClearEntry;        { 清除当前输入寄存器 (相当于 CE) }
    procedure Backspace;         { 删除当前输入的末尾字符 (相当于 ⌫) }

    { 键盘与字符输入录入接口 }
    procedure InputDigit(const Ch: Char); { 键入数字字符 '0'..'9' }
    procedure InputDot;                   { 键入小数点 '.' }
    procedure InputSign;                  { 正负号翻转 '+/-' }
    procedure InputPi;                    { 键入常数 π }
    procedure InputE;                     { 键入常数 e }

    { 算式流程与控制求值接口 }
    procedure InputOperator(const Op: string);     { 键入二元运算符 }
    procedure InputOpenParen;                      { 键入左括号 '(' }
    procedure InputCloseParen;                     { 键入右括号 ')' }
    function ExecuteEquals(out AResultStr: string): Boolean; { 执行等号求值计算 }
    function ExecutePercent: Double;               { 执行百分比转换运算 }

    { 一元科学函数求值 }
    procedure ApplyUnary(const FuncName: string);  { 执行单目函数 (sin, cos, sqrt 等) }

    { 内存 (Memory) 记忆体操作 }
    procedure MemoryClear;                         { 清空内存 (MC) }
    function MemoryRecall: Double;                 { 调出内存值 (MR) }
    procedure MemoryStore(const Val: Double);      { 保存当前值至内存 (MS) }
    procedure MemoryAdd(const Val: Double);        { 将当前值累加至内存 (M+) }
    procedure MemorySub(const Val: Double);        { 将当前值自内存扣除 (M-) }
    function HasMemory: Boolean;                   { 判定当前内存中是否有非零有效值 }

    { 外部读写属性暴露 }
    property CurrentInput: string read FCurrentInput write FCurrentInput;
    property ExpressionStr: string read FExpressionStr;
    property AngleMode: TAngleMode read FAngleMode write FAngleMode;
    property MemoryValue: Double read FMemory;
    property IsNewInput: Boolean read FIsNewInput write FIsNewInput;
    property OperandReady: Boolean read FOperandReady write FOperandReady;
  end;

implementation

function ParseInputNumber(const S: string): Double;
var
  CleanS: string;
begin
  CleanS := Trim(S);
  if (CleanS = '') or (CleanS = '0.') or (CleanS = '-') then
    Exit(0.0);
  if not TryStrToFloat(CleanS, Result) then
    Result := NaN;
end;

constructor TAlgebraicEngine.Create;
begin
  inherited Create;
  FAngleMode := amDeg;
  FMemory := 0.0;
  ClearAll;
end;

destructor TAlgebraicEngine.Destroy;
begin
  SetLength(FTokens, 0);
  inherited Destroy;
end;

procedure TAlgebraicEngine.ClearAll;
begin
  SetLength(FTokens, 0);
  FCurrentInput := '0';
  FIsNewInput := True;
  FOperandReady := False;
  FLastResult := 0.0;
  FLastOp := '';
  FLastOperand := 0.0;
  FHasLastOp := False;
  FExpressionStr := '';
end;

procedure TAlgebraicEngine.ClearEntry;
begin
  FCurrentInput := '0';
  FIsNewInput := True;
  FOperandReady := False;
end;

procedure TAlgebraicEngine.Backspace;
begin
  if FCurrentInput = 'Error' then
  begin
    FCurrentInput := '0';
    FIsNewInput := True;
    Exit;
  end;
  if FIsNewInput then Exit;
  if Length(FCurrentInput) > 0 then
    Delete(FCurrentInput, Length(FCurrentInput), 1);

  if (FCurrentInput = '') or (FCurrentInput = '-') then
  begin
    FCurrentInput := '0';
    FIsNewInput := True;
    FOperandReady := False;
  end;
end;

procedure TAlgebraicEngine.InputDigit(const Ch: Char);
begin
  FOperandReady := False;
  if FIsNewInput or (FCurrentInput = '0') or (FCurrentInput = 'Error') then
  begin
    FCurrentInput := Ch;
    FIsNewInput := False;
  end
  else
  begin
    if Length(FCurrentInput) < 24 then
      FCurrentInput := FCurrentInput + Ch;
  end;
end;

procedure TAlgebraicEngine.InputDot;
begin
  FOperandReady := False;
  if FIsNewInput or (FCurrentInput = 'Error') then
  begin
    FCurrentInput := '0.';
    FIsNewInput := False;
    Exit;
  end;

  if Pos('.', FCurrentInput) = 0 then
    FCurrentInput := FCurrentInput + '.';
end;

procedure TAlgebraicEngine.InputSign;
begin
  if FCurrentInput = '0' then Exit;
  if Copy(FCurrentInput, 1, 1) = '-' then
    Delete(FCurrentInput, 1, 1)
  else
    FCurrentInput := '-' + FCurrentInput;
end;

procedure TAlgebraicEngine.InputPi;
begin
  FCurrentInput := FormatDisplayFloat(Pi);
  FIsNewInput := True;
  FOperandReady := True;
end;

procedure TAlgebraicEngine.InputE;
begin
  FCurrentInput := FormatDisplayFloat(Exp(1.0));
  FIsNewInput := True;
  FOperandReady := True;
end;

procedure TAlgebraicEngine.AddToken(const AType: TTokenType; const AVal: Double; const AOp: string);
var
  Idx: Integer;
begin
  Idx := Length(FTokens);
  SetLength(FTokens, Idx + 1);
  FTokens[Idx].TokenType := AType;
  FTokens[Idx].Value := AVal;
  FTokens[Idx].Op := AOp;
end;

procedure TAlgebraicEngine.UpdateExpressionString;
var
  i: Integer;
  S: string;
begin
  S := '';
  for i := 0 to High(FTokens) do
  begin
    case FTokens[i].TokenType of
      ttNumber:     S := S + FormatDisplayFloat(FTokens[i].Value) + ' ';
      ttOperator:   S := S + FTokens[i].Op + ' ';
      ttOpenParen:  S := S + '( ';
      ttCloseParen: S := S + ') ';
    end;
  end;
  FExpressionStr := Trim(S);
end;

procedure TAlgebraicEngine.InputOperator(const Op: string);
var
  CurVal: Double;
  LastIdx: Integer;
begin
  CurVal := ParseInputNumber(FCurrentInput);

  // 如果刚刚输入了数字，或者一元运算/常数/MR生成了操作数，或者 tokens 为空
  if (not FIsNewInput) or FOperandReady or (Length(FTokens) = 0) then
  begin
    AddToken(ttNumber, CurVal, '');
    FOperandReady := False;
  end
  else
  begin
    // 如果最后是操作符且用户又按了另一个操作符，替换之
    LastIdx := High(FTokens);
    if (LastIdx >= 0) and (FTokens[LastIdx].TokenType = ttOperator) then
    begin
      FTokens[LastIdx].Op := Op;
      UpdateExpressionString;
      Exit;
    end;
  end;

  AddToken(ttOperator, 0.0, Op);
  UpdateExpressionString;
  FIsNewInput := True;
  FOperandReady := False;
  FHasLastOp := False;
end;

procedure TAlgebraicEngine.InputOpenParen;
begin
  AddToken(ttOpenParen, 0.0, '(');
  UpdateExpressionString;
  FIsNewInput := True;
  FOperandReady := False;
end;

procedure TAlgebraicEngine.InputCloseParen;
var
  CurVal: Double;
begin
  if (not FIsNewInput) or FOperandReady then
  begin
    CurVal := ParseInputNumber(FCurrentInput);
    AddToken(ttNumber, CurVal, '');
    FOperandReady := False;
  end;

  AddToken(ttCloseParen, 0.0, ')');
  UpdateExpressionString;
  FIsNewInput := True;
  FOperandReady := False;
end;

function TAlgebraicEngine.GetPrecedence(const Op: string): Integer;
begin
  if (Op = '+') or (Op = '-') then Exit(1);
  if (Op = '×') or (Op = '*') or (Op = '÷') or (Op = '/') or (Op = 'MOD') then Exit(2);
  if (Op = '^') or (Op = 'xʸ') or (Op = 'y√x') or (Op = 'nPr') or (Op = 'nCr') then Exit(3);
  Result := 0;
end;

function TAlgebraicEngine.IsRightAssociative(const Op: string): Boolean;
begin
  Result := (Op = '^') or (Op = 'xʸ');
end;

function TAlgebraicEngine.ApplyBinaryOp(const A, B: Double; const Op: string): Double;
begin
  if Op = '+' then Result := A + B
  else if Op = '-' then Result := A - B
  else if (Op = '×') or (Op = '*') then Result := A * B
  else if (Op = '÷') or (Op = '/') then
  begin
    if B = 0.0 then raise Exception.Create('除数不能为 0');
    Result := A / B;
  end
  else if Op = 'MOD' then
  begin
    if B = 0.0 then raise Exception.Create('模运算除数不能为 0');
    Result := Trunc(A) mod Trunc(B);
  end
  else if (Op = '^') or (Op = 'xʸ') then Result := CalcPower(A, B)
  else if Op = 'y√x' then Result := CalcRoot(A, B)
  else if Op = 'nPr' then Result := CalcPermutation(A, B)
  else if Op = 'nCr' then Result := CalcCombination(A, B)
  else Result := B;

  Result := SanitizeFloat(Result);
end;

function TAlgebraicEngine.EvaluateTokens(out AResult: Double): Boolean;
var
  ValStack: array of Double;
  OpStack: array of string;
  ValTop, OpTop: Integer;

  procedure PushVal(const V: Double);
  begin
    Inc(ValTop);
    if ValTop >= Length(ValStack) then SetLength(ValStack, ValTop + 16);
    ValStack[ValTop] := V;
  end;

  function PopVal: Double;
  begin
    if ValTop < 0 then Exit(0.0);
    Result := ValStack[ValTop];
    Dec(ValTop);
  end;

  procedure PushOp(const O: string);
  begin
    Inc(OpTop);
    if OpTop >= Length(OpStack) then SetLength(OpStack, OpTop + 16);
    OpStack[OpTop] := O;
  end;

  function PopOp: string;
  begin
    if OpTop < 0 then Exit('');
    Result := OpStack[OpTop];
    Dec(OpTop);
  end;

  procedure EvalTop;
  var
    Op: string;
    B, A: Double;
  begin
    if OpTop < 0 then Exit;
    Op := PopOp;
    if ValTop < 1 then raise Exception.Create('缺少操作数');
    B := PopVal;
    A := PopVal;
    PushVal(ApplyBinaryOp(A, B, Op));
  end;

var
  i: Integer;
  Tok: TToken;
begin
  ValTop := -1;
  OpTop := -1;
  SetLength(ValStack, 32);
  SetLength(OpStack, 32);

  try
    for i := 0 to High(FTokens) do
    begin
      Tok := FTokens[i];
      case Tok.TokenType of
        ttNumber:
          PushVal(Tok.Value);

        ttOpenParen:
          PushOp('(');

        ttCloseParen:
        begin
          while (OpTop >= 0) and (OpStack[OpTop] <> '(') do
            EvalTop;
          if (OpTop >= 0) and (OpStack[OpTop] = '(') then
            PopOp // 弹出 '('
          else
            raise Exception.Create('未匹配的右括号');
        end;

        ttOperator:
        begin
          while (OpTop >= 0) and (OpStack[OpTop] <> '(') and
                ((GetPrecedence(OpStack[OpTop]) > GetPrecedence(Tok.Op)) or
                 ((GetPrecedence(OpStack[OpTop]) = GetPrecedence(Tok.Op)) and not IsRightAssociative(Tok.Op))) do
            EvalTop;
          PushOp(Tok.Op);
        end;
      end;
    end;

    while OpTop >= 0 do
    begin
      if OpStack[OpTop] = '(' then
        raise Exception.Create('未闭合的左括号')
      else
        EvalTop;
    end;

    if ValTop = 0 then
      AResult := PopVal
    else
      raise Exception.Create('表达式格式错误');

    Result := not IsNan(AResult) and not IsInfinite(AResult);
  except
    Result := False;
  end;
end;

function TAlgebraicEngine.ExecuteEquals(out AResultStr: string): Boolean;
var
  CurVal, Res: Double;
  LastIdx: Integer;
begin
  if FCurrentInput = 'Error' then
  begin
    AResultStr := 'Error';
    Exit(False);
  end;

  CurVal := ParseInputNumber(FCurrentInput);
  if IsNan(CurVal) and (Length(FTokens) = 0) then
  begin
    AResultStr := 'Error';
    FCurrentInput := 'Error';
    Exit(False);
  end;

  // 如果没有前置表达式，检查是否有重复按等号
  if Length(FTokens) = 0 then
  begin
    if FHasLastOp then
    begin
      try
        Res := ApplyBinaryOp(CurVal, FLastOperand, FLastOp);
        FCurrentInput := FormatDisplayFloat(Res);
        FExpressionStr := FormatDisplayFloat(CurVal) + ' ' + FLastOp + ' ' + FormatDisplayFloat(FLastOperand) + ' =';
        AResultStr := FCurrentInput;
        FIsNewInput := True;
        FOperandReady := True;
        Exit(True);
      except
        AResultStr := 'Error';
        FCurrentInput := 'Error';
        FExpressionStr := '';
        FIsNewInput := True;
        FOperandReady := False;
        FHasLastOp := False;
        Exit(False);
      end;
    end;
    AResultStr := FCurrentInput;
    Exit(True);
  end;

  // 将当前输入数字压入 tokens
  if (not FIsNewInput) or FOperandReady or (FTokens[High(FTokens)].TokenType = ttOperator) then
  begin
    AddToken(ttNumber, CurVal, '');
    FOperandReady := False;
    // 记录最后的操作符和操作数以备连续按等号
    LastIdx := High(FTokens);
    if (LastIdx >= 1) and (FTokens[LastIdx - 1].TokenType = ttOperator) then
    begin
      FLastOp := FTokens[LastIdx - 1].Op;
      FLastOperand := CurVal;
      FHasLastOp := True;
    end;
  end;

  UpdateExpressionString;

  if EvaluateTokens(Res) and not IsNan(Res) and not IsInfinite(Res) then
  begin
    FLastResult := Res;
    FCurrentInput := FormatDisplayFloat(Res);
    FExpressionStr := FExpressionStr + ' =';
    AResultStr := FCurrentInput;
    SetLength(FTokens, 0); // 计算完成，清空 tokens
    FIsNewInput := True;
    FOperandReady := True;
    Result := True;
  end
  else
  begin
    AResultStr := 'Error';
    FCurrentInput := 'Error';
    FExpressionStr := '';
    SetLength(FTokens, 0);
    FIsNewInput := True;
    FOperandReady := False;
    FHasLastOp := False;
    Result := False;
  end;
end;

function TAlgebraicEngine.ExecutePercent: Double;
var
  CurVal, BaseVal, Res: Double;
  i: Integer;
  LastOp: string;
begin
  CurVal := StrToFloatDef(FCurrentInput, 0.0);
  BaseVal := 0.0;
  LastOp := '';

  for i := High(FTokens) downto 0 do
  begin
    if FTokens[i].TokenType = ttOperator then
    begin
      LastOp := FTokens[i].Op;
      if (i > 0) and (FTokens[i - 1].TokenType = ttNumber) then
        BaseVal := FTokens[i - 1].Value
      else if Length(FTokens) > 0 then
        BaseVal := FTokens[0].Value;
      Break;
    end;
  end;

  if (LastOp = '+') or (LastOp = '-') then
    Res := BaseVal * (CurVal / 100.0)
  else
    Res := CurVal / 100.0;

  Res := SanitizeFloat(Res);
  FCurrentInput := FormatDisplayFloat(Res);
  FIsNewInput := True;
  FOperandReady := True;
  Result := Res;
end;

procedure TAlgebraicEngine.ApplyUnary(const FuncName: string);
var
  Val, Res: Double;
begin
  Val := StrToFloatDef(FCurrentInput, 0.0);

  if FuncName = 'sqrt' then
  begin
    if Val < 0.0 then raise Exception.Create('负数不能开平方根');
    Res := Sqrt(Val);
  end
  else if FuncName = 'sqr' then Res := Sqr(Val)
  else if FuncName = 'cube' then Res := Val * Val * Val
  else if FuncName = 'cbrt' then Res := CalcRoot(Val, 3.0)
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
  else if FuncName = 'asinh' then Res := CalcArSinh(Val)
  else if FuncName = 'acosh' then Res := CalcArCosh(Val)
  else if FuncName = 'atanh' then Res := CalcArTanh(Val)
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
  else if FuncName = 'log2' then
  begin
    if Val <= 0.0 then raise Exception.Create('以2为底对数真数必须大于 0');
    Res := Log2(Val);
  end
  else if FuncName = 'exp' then Res := Exp(Val)
  else if FuncName = 'exp10' then Res := Power(10.0, Val)
  else if FuncName = 'exp2' then Res := Power(2.0, Val)
  else if FuncName = 'fact' then Res := CalcFactorial(Val)
  else Res := Val;

  Res := SanitizeFloat(Res);
  FCurrentInput := FormatDisplayFloat(Res);
  FIsNewInput := True;
  FOperandReady := True;
end;

procedure TAlgebraicEngine.MemoryClear;
begin
  FMemory := 0.0;
end;

function TAlgebraicEngine.MemoryRecall: Double;
begin
  FCurrentInput := FormatDisplayFloat(FMemory);
  FIsNewInput := True;
  FOperandReady := True;
  Result := FMemory;
end;

procedure TAlgebraicEngine.MemoryStore(const Val: Double);
begin
  FMemory := Val;
end;

procedure TAlgebraicEngine.MemoryAdd(const Val: Double);
begin
  FMemory := FMemory + Val;
end;

procedure TAlgebraicEngine.MemorySub(const Val: Double);
begin
  FMemory := FMemory - Val;
end;

function TAlgebraicEngine.HasMemory: Boolean;
begin
  Result := FMemory <> 0.0;
end;

end.
