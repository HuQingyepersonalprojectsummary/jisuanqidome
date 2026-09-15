unit uAlgebraicEngine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uCalcTypes, uMathUtils;

type
  { 代数表达式标记类型 }
  TTokenType = (ttNumber, ttOperator, ttOpenParen, ttCloseParen);

  TToken = record
    TokenType: TTokenType;
    Value: Double;
    Op: string;
  end;

  { 代数计算引擎 }
  TAlgebraicEngine = class
  private
    FTokens: array of TToken;
    FCurrentInput: string;
    FIsNewInput: Boolean;
    FMemory: Double;
    FAngleMode: TAngleMode;
    FLastResult: Double;
    FLastOp: string;
    FLastOperand: Double;
    FHasLastOp: Boolean;
    FExpressionStr: string;

    procedure AddToken(const AType: TTokenType; const AVal: Double; const AOp: string);
    function EvaluateTokens(out AResult: Double): Boolean;
    function GetPrecedence(const Op: string): Integer;
    function ApplyBinaryOp(const A, B: Double; const Op: string): Double;
    procedure UpdateExpressionString;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ClearAll;
    procedure ClearEntry;
    procedure Backspace;

    procedure InputDigit(const Ch: Char);
    procedure InputDot;
    procedure InputSign;
    procedure InputPi;
    procedure InputE;

    procedure InputOperator(const Op: string);
    procedure InputOpenParen;
    procedure InputCloseParen;
    function ExecuteEquals(out AResultStr: string): Boolean;
    function ExecutePercent: Double;

    { 一元运算 }
    procedure ApplyUnary(const FuncName: string);

    { 内存操作 }
    procedure MemoryClear;
    function MemoryRecall: Double;
    procedure MemoryStore(const Val: Double);
    procedure MemoryAdd(const Val: Double);
    procedure MemorySub(const Val: Double);
    function HasMemory: Boolean;

    property CurrentInput: string read FCurrentInput write FCurrentInput;
    property ExpressionStr: string read FExpressionStr;
    property AngleMode: TAngleMode read FAngleMode write FAngleMode;
    property MemoryValue: Double read FMemory;
    property IsNewInput: Boolean read FIsNewInput write FIsNewInput;
  end;

implementation

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
end;

procedure TAlgebraicEngine.Backspace;
begin
  if FIsNewInput then Exit;
  if Length(FCurrentInput) > 0 then
    Delete(FCurrentInput, Length(FCurrentInput), 1);

  if (FCurrentInput = '') or (FCurrentInput = '-') then
  begin
    FCurrentInput := '0';
    FIsNewInput := True;
  end;
end;

procedure TAlgebraicEngine.InputDigit(const Ch: Char);
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
end;

procedure TAlgebraicEngine.InputDot;
begin
  if FIsNewInput then
  begin
    FCurrentInput := '0.';
    FIsNewInput := False;
    Exit;
  end;

  if Pos('.', FCurrentInput) = 0 then
    FCurrentInput := FCurrentInput + '.';
end;

procedure TAlgebraicEngine.InputSign;
var
  Val: Double;
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
end;

procedure TAlgebraicEngine.InputE;
begin
  FCurrentInput := FormatDisplayFloat(Exp(1.0));
  FIsNewInput := True;
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
  CurVal := StrToFloatDef(FCurrentInput, 0.0);

  // 如果刚刚输入了数字，将数字压入 tokens
  if not FIsNewInput or (Length(FTokens) = 0) then
  begin
    AddToken(ttNumber, CurVal, '');
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
  FHasLastOp := False;
end;

procedure TAlgebraicEngine.InputOpenParen;
begin
  AddToken(ttOpenParen, 0.0, '(');
  UpdateExpressionString;
  FIsNewInput := True;
end;

procedure TAlgebraicEngine.InputCloseParen;
var
  CurVal: Double;
begin
  if not FIsNewInput then
  begin
    CurVal := StrToFloatDef(FCurrentInput, 0.0);
    AddToken(ttNumber, CurVal, '');
  end;

  AddToken(ttCloseParen, 0.0, ')');
  UpdateExpressionString;
  FIsNewInput := True;
end;

function TAlgebraicEngine.GetPrecedence(const Op: string): Integer;
begin
  if (Op = '+') or (Op = '-') then Exit(1);
  if (Op = '×') or (Op = '*') or (Op = '÷') or (Op = '/') or (Op = 'MOD') then Exit(2);
  if (Op = '^') or (Op = 'xʸ') or (Op = 'y√x') or (Op = 'nPr') or (Op = 'nCr') then Exit(3);
  Result := 0;
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
    Op := PopOp;
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
            PopOp; // 弹出 '('
        end;

        ttOperator:
        begin
          while (OpTop >= 0) and (OpStack[OpTop] <> '(') and
                (GetPrecedence(OpStack[OpTop]) >= GetPrecedence(Tok.Op)) do
            EvalTop;
          PushOp(Tok.Op);
        end;
      end;
    end;

    while OpTop >= 0 do
    begin
      if OpStack[OpTop] = '(' then
        PopOp
      else
        EvalTop;
    end;

    if ValTop >= 0 then
      AResult := PopVal
    else
      AResult := 0.0;

    Result := True;
  except
    Result := False;
  end;
end;

function TAlgebraicEngine.ExecuteEquals(out AResultStr: string): Boolean;
var
  CurVal, Res: Double;
  LastIdx: Integer;
begin
  CurVal := StrToFloatDef(FCurrentInput, 0.0);

  // 如果没有前置表达式，检查是否有重复按等号
  if Length(FTokens) = 0 then
  begin
    if FHasLastOp then
    begin
      Res := ApplyBinaryOp(CurVal, FLastOperand, FLastOp);
      FCurrentInput := FormatDisplayFloat(Res);
      FExpressionStr := FormatDisplayFloat(CurVal) + ' ' + FLastOp + ' ' + FormatDisplayFloat(FLastOperand) + ' =';
      AResultStr := FCurrentInput;
      FIsNewInput := True;
      Exit(True);
    end;
    AResultStr := FCurrentInput;
    Exit(True);
  end;

  // 将当前输入数字压入 tokens
  if not FIsNewInput or (FTokens[High(FTokens)].TokenType = ttOperator) then
  begin
    AddToken(ttNumber, CurVal, '');
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

  if EvaluateTokens(Res) then
  begin
    FLastResult := Res;
    FCurrentInput := FormatDisplayFloat(Res);
    FExpressionStr := FExpressionStr + ' =';
    AResultStr := FCurrentInput;
    SetLength(FTokens, 0); // 计算完成，清空 tokens
    FIsNewInput := True;
    Result := True;
  end
  else
  begin
    AResultStr := 'Error';
    SetLength(FTokens, 0);
    FIsNewInput := True;
    Result := False;
  end;
end;

function TAlgebraicEngine.ExecutePercent: Double;
var
  CurVal, Res: Double;
begin
  CurVal := StrToFloatDef(FCurrentInput, 0.0);
  if Length(FTokens) > 0 then
  begin
    // 例如 200 + 10% -> 200 + (200 * 0.10)
    Res := FTokens[0].Value * (CurVal / 100.0);
  end
  else
  begin
    Res := CurVal / 100.0;
  end;

  FCurrentInput := FormatDisplayFloat(Res);
  FIsNewInput := True;
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
end;

procedure TAlgebraicEngine.MemoryClear;
begin
  FMemory := 0.0;
end;

function TAlgebraicEngine.MemoryRecall: Double;
begin
  FCurrentInput := FormatDisplayFloat(FMemory);
  FIsNewInput := True;
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
