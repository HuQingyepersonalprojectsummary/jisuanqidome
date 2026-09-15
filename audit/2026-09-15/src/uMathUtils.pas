unit uMathUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uCalcTypes;

function SanitizeFloat(const Val: Double): Double;
function AngleToRad(const Angle: Double; const Mode: TAngleMode): Double;
function RadToAngle(const Rad: Double; const Mode: TAngleMode): Double;

{ 三角函数 (根据角度模式自动换算) }
function CalcSin(const Val: Double; const Mode: TAngleMode): Double;
function CalcCos(const Val: Double; const Mode: TAngleMode): Double;
function CalcTan(const Val: Double; const Mode: TAngleMode): Double;
function CalcArcSin(const Val: Double; const Mode: TAngleMode): Double;
function CalcArcCos(const Val: Double; const Mode: TAngleMode): Double;
function CalcArcTan(const Val: Double; const Mode: TAngleMode): Double;

{ 双曲函数与反双曲函数 }
function CalcSinh(const Val: Double): Double;
function CalcCosh(const Val: Double): Double;
function CalcTanh(const Val: Double): Double;
function CalcArSinh(const Val: Double): Double;
function CalcArCosh(const Val: Double): Double;
function CalcArTanh(const Val: Double): Double;

{ 阶乘、排列组合 }
function CalcFactorial(const Val: Double): Double;
function CalcPermutation(const N, R: Double): Double;
function CalcCombination(const N, R: Double): Double;

{ 幂次与开方 }
function CalcPower(const BaseVal, ExpVal: Double): Double;
function CalcRoot(const Val, N: Double): Double;

{ 数值格式化显示 }
function FormatDisplayFloat(const Val: Double; const MaxPrecision: Integer = 14): string;

implementation

const
  EPSILON = 1.0e-14;

function SanitizeFloat(const Val: Double): Double;
var
  R: Double;
begin
  if IsNan(Val) or IsInfinite(Val) then
    Exit(Val);

  if Abs(Val) < EPSILON then
    Exit(0.0);

  if Abs(Val) < 1.0e14 then
  begin
    R := Round(Val);
    if Abs(Val - R) < EPSILON then
      Exit(R);
  end;

  Result := Val;
end;

function AngleToRad(const Angle: Double; const Mode: TAngleMode): Double;
begin
  case Mode of
    amDeg:  Result := Angle * (Pi / 180.0);
    amRad:  Result := Angle;
    amGrad: Result := Angle * (Pi / 200.0);
  end;
end;

function RadToAngle(const Rad: Double; const Mode: TAngleMode): Double;
begin
  case Mode of
    amDeg:  Result := Rad * (180.0 / Pi);
    amRad:  Result := Rad;
    amGrad: Result := Rad * (200.0 / Pi);
  end;
end;

function CalcSin(const Val: Double; const Mode: TAngleMode): Double;
var
  Rad, DegVal: Double;
begin
  if Mode = amDeg then
  begin
    DegVal := Val;
    // 模 360 度规整
    while DegVal >= 360.0 do DegVal := DegVal - 360.0;
    while DegVal < 0.0 do DegVal := DegVal + 360.0;

    if (Abs(DegVal) < EPSILON) or (Abs(DegVal - 180.0) < EPSILON) or (Abs(DegVal - 360.0) < EPSILON) then
      Exit(0.0);
    if Abs(DegVal - 90.0) < EPSILON then
      Exit(1.0);
    if Abs(DegVal - 270.0) < EPSILON then
      Exit(-1.0);
  end;

  Rad := AngleToRad(Val, Mode);
  Result := SanitizeFloat(Sin(Rad));
end;

function CalcCos(const Val: Double; const Mode: TAngleMode): Double;
var
  Rad, DegVal: Double;
begin
  if Mode = amDeg then
  begin
    DegVal := Val;
    while DegVal >= 360.0 do DegVal := DegVal - 360.0;
    while DegVal < 0.0 do DegVal := DegVal + 360.0;

    if (Abs(DegVal - 90.0) < EPSILON) or (Abs(DegVal - 270.0) < EPSILON) then
      Exit(0.0);
    if (Abs(DegVal) < EPSILON) or (Abs(DegVal - 360.0) < EPSILON) then
      Exit(1.0);
    if Abs(DegVal - 180.0) < EPSILON then
      Exit(-1.0);
  end;

  Rad := AngleToRad(Val, Mode);
  Result := SanitizeFloat(Cos(Rad));
end;

function CalcTan(const Val: Double; const Mode: TAngleMode): Double;
var
  CosVal: Double;
begin
  CosVal := CalcCos(Val, Mode);
  if Abs(CosVal) < EPSILON then
    raise Exception.Create('正切函数在该点无定义 (分母为0)');
  Result := SanitizeFloat(CalcSin(Val, Mode) / CosVal);
end;

function CalcArcSin(const Val: Double; const Mode: TAngleMode): Double;
begin
  if (Val < -1.0) or (Val > 1.0) then
    raise Exception.Create('反正弦函数参数必须在 [-1, 1] 区间内');
  Result := SanitizeFloat(RadToAngle(ArcSin(Val), Mode));
end;

function CalcArcCos(const Val: Double; const Mode: TAngleMode): Double;
begin
  if (Val < -1.0) or (Val > 1.0) then
    raise Exception.Create('反余弦函数参数必须在 [-1, 1] 区间内');
  Result := SanitizeFloat(RadToAngle(ArcCos(Val), Mode));
end;

function CalcArcTan(const Val: Double; const Mode: TAngleMode): Double;
begin
  Result := SanitizeFloat(RadToAngle(ArcTan(Val), Mode));
end;

function CalcSinh(const Val: Double): Double;
begin
  Result := SanitizeFloat(Sinh(Val));
end;

function CalcCosh(const Val: Double): Double;
begin
  Result := SanitizeFloat(Cosh(Val));
end;

function CalcTanh(const Val: Double): Double;
begin
  Result := SanitizeFloat(Tanh(Val));
end;

function CalcArSinh(const Val: Double): Double;
begin
  Result := SanitizeFloat(ArSinh(Val));
end;

function CalcArCosh(const Val: Double): Double;
begin
  if Val < 1.0 then
    raise Exception.Create('反双曲余弦参数必须大于等于 1');
  Result := SanitizeFloat(ArCosh(Val));
end;

function CalcArTanh(const Val: Double): Double;
begin
  if (Val <= -1.0) or (Val >= 1.0) then
    raise Exception.Create('反双曲正切参数必须在 (-1, 1) 开区间内');
  Result := SanitizeFloat(ArTanh(Val));
end;

function CalcFactorial(const Val: Double): Double;
var
  N, i: Integer;
  Res: Double;
begin
  if Frac(Val) <> 0 then
    raise Exception.Create('阶乘运算仅支持非负整数');
  if Val < 0 then
    raise Exception.Create('负数无阶乘');
  if Val > 170.0 then
    raise Exception.Create('数值过大 (超出浮点数上限 170!)');

  N := Trunc(Val);
  if N <= 1 then
    Exit(1.0);

  Res := 1.0;
  for i := 2 to N do
    Res := Res * i;

  Result := Res;
end;

function CalcPermutation(const N, R: Double): Double;
var
  i, IntN, IntR: Integer;
  Res: Double;
begin
  if (Frac(N) <> 0) or (Frac(R) <> 0) or (N < 0) or (R < 0) or (R > N) then
    raise Exception.Create('排列参数无效 (需满足 0 <= r <= n 为整数)');
  IntN := Trunc(N);
  IntR := Trunc(R);
  Res := 1.0;
  for i := 0 to IntR - 1 do
    Res := Res * (IntN - i);
  Result := Res;
end;

function CalcCombination(const N, R: Double): Double;
var
  i, IntN, IntR: Integer;
  Res: Double;
begin
  if (Frac(N) <> 0) or (Frac(R) <> 0) or (N < 0) or (R < 0) or (R > N) then
    raise Exception.Create('组合参数无效 (需满足 0 <= r <= n 为整数)');
  IntN := Trunc(N);
  IntR := Trunc(R);
  if (IntR = 0) or (IntR = IntN) then Exit(1.0);
  if IntR > IntN - IntR then
    IntR := IntN - IntR; // 对称性

  Res := 1.0;
  for i := 1 to IntR do
  begin
    Res := Res * (IntN - i + 1);
    Res := Res / i;
  end;
  Result := Round(Res);
end;

function CalcPower(const BaseVal, ExpVal: Double): Double;
begin
  if (BaseVal = 0.0) and (ExpVal < 0.0) then
    raise Exception.Create('0 的负数次方未定义')
  else if (BaseVal < 0.0) and (Frac(ExpVal) <> 0.0) then
    raise Exception.Create('负数的非整数次幂为复数')
  else
    Result := SanitizeFloat(Power(BaseVal, ExpVal));
end;

function CalcRoot(const Val, N: Double): Double;
begin
  if N = 0.0 then
    raise Exception.Create('开方次数不能为 0');
  if (Val < 0.0) and (Frac(N) = 0.0) and (Trunc(N) mod 2 = 0) then
    raise Exception.Create('负数不能开偶数次方根');

  if Val < 0.0 then
    Result := -Power(-Val, 1.0 / N)
  else
    Result := Power(Val, 1.0 / N);

  Result := SanitizeFloat(Result);
end;

function FormatDisplayFloat(const Val: Double; const MaxPrecision: Integer = 14): string;
var
  FS: TFormatSettings;
  AbsVal: Double;
  S: string;
begin
  if IsNan(Val) then Exit('NaN');
  if IsInfinite(Val) then
  begin
    if Val > 0 then Exit('Infinity') else Exit('-Infinity');
  end;

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  AbsVal := Abs(Val);
  if (AbsVal <> 0.0) and ((AbsVal >= 1.0e15) or (AbsVal < 1.0e-9)) then
  begin
    // 采用科学计数法
    S := FloatToStrF(Val, ffExponent, 10, 2, FS);
  end
  else
  begin
    // 采用常规浮点格式
    S := FloatToStrF(Val, ffGeneral, MaxPrecision, 0, FS);
  end;

  Result := S;
end;

end.
