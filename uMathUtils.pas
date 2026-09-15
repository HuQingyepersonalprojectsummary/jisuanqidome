unit uMathUtils;

{==============================================================================
  PCalc 高级科学与工程计算器 - 高精度数学与浮点安全算法库 (uMathUtils.pas)
  ------------------------------------------------------------------------------
  本单元为核心计算引擎提供高可靠性、高精度的数值运算支持：
  1. 浮点微小累积误差修剪与合法微小数保护 (SanitizeFloat)
  2. 角度单位全自动转换 (DEG 角度, RAD 弧度, GRAD 百分度)
  3. 纯浮点大数取模规约函数 (FloatMod)，杜绝超大浮点数 Int64 溢出与卡死
  4. 三角函数极值零点矫正 (杜绝 sin(180°) = 1.22e-16 伪零点，返回严谨 0.0)
  5. 完整双曲函数与反双曲函数簇 (sinh, cosh, tanh, asinh, acosh, atanh)
  6. 阶乘计算 (解除旧版 12! 人为限制，支持高达 170! 浮点上限)
  7. 排列数 (nPr) 与组合数 (nCr) 对称性优化与防溢出保护
  8. 幂运算 (xʸ) 与开方运算 (y√x) 边界检查与负数偶次根校验
  9. 智能数值显示格式化 (大整数保全、常规浮点与超大/微小科学计数法)
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, uCalcTypes;

{ 浮点数值安全整规：仅消除近似整数的尾数累积误差，绝不抹除合法的微小物理常数 }
function SanitizeFloat(const Val: Double): Double;

{ 角度制换算为弧度制 }
function AngleToRad(const Angle: Double; const Mode: TAngleMode): Double;

{ 弧度制换算为目标角度制度 }
function RadToAngle(const Rad: Double; const Mode: TAngleMode): Double;

{ 纯浮点数取模范围规约：采用 Int(X/Y) 实现，防止超大浮点引发 Int64 溢出 }
function FloatMod(const X, Y: Double): Double;

{ 三角函数 (根据当前设定的 DEG/RAD/GRAD 角度模式全自动换算并进行关键角零点校准) }
function CalcSin(const Val: Double; const Mode: TAngleMode): Double;
function CalcCos(const Val: Double; const Mode: TAngleMode): Double;
function CalcTan(const Val: Double; const Mode: TAngleMode): Double;
function CalcArcSin(const Val: Double; const Mode: TAngleMode): Double;
function CalcArcCos(const Val: Double; const Mode: TAngleMode): Double;
function CalcArcTan(const Val: Double; const Mode: TAngleMode): Double;

{ 双曲函数与反双曲函数簇 }
function CalcSinh(const Val: Double): Double;
function CalcCosh(const Val: Double): Double;
function CalcTanh(const Val: Double): Double;
function CalcArSinh(const Val: Double): Double;
function CalcArCosh(const Val: Double): Double;
function CalcArTanh(const Val: Double): Double;

{ 离散数学函数：阶乘 (最高 170!)、排列数 nPr、组合数 nCr }
function CalcFactorial(const Val: Double): Double;
function CalcPermutation(const N, R: Double): Double;
function CalcCombination(const N, R: Double): Double;

{ 幂次与开方运算 (包含负数偶次开根等非法数学定义异常防御) }
function CalcPower(const BaseVal, ExpVal: Double): Double;
function CalcRoot(const Val, N: Double): Double;

{ 屏幕数值格式化：智能权衡大整数不损失精度、普通浮点美观与微小/超大数科学计数法 }
function FormatDisplayFloat(const Val: Double; const MaxPrecision: Integer = 16): string;

implementation

const
  EPSILON = 1.0e-14;

function SanitizeFloat(const Val: Double): Double;
var
  R: Double;
begin
  if IsNan(Val) or IsInfinite(Val) then
    Exit(Val);

  // 仅对较大且接近整数的计算浮点累积误差进行整数规整；绝不粗暴清零合法微小浮点数（如 1e-19, 1e-34）
  if (Abs(Val) >= 1.0) and (Abs(Val) < 1.0e14) then
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

function FloatMod(const X, Y: Double): Double;
var
  D: Double;
begin
  if Y = 0.0 then Exit(0.0);
  D := Int(X / Y);
  Result := X - D * Y;
  if Result < 0.0 then Result := Result + Abs(Y);
end;

function CalcSin(const Val: Double; const Mode: TAngleMode): Double;
var
  Rad, DegVal: Double;
begin
  if Mode = amDeg then
  begin
    DegVal := FloatMod(Val, 360.0);

    if (Abs(DegVal) < EPSILON) or (Abs(DegVal - 180.0) < EPSILON) or (Abs(DegVal - 360.0) < EPSILON) then
      Exit(0.0);
    if Abs(DegVal - 90.0) < EPSILON then
      Exit(1.0);
    if Abs(DegVal - 270.0) < EPSILON then
      Exit(-1.0);
    Rad := DegVal * (Pi / 180.0);
  end
  else if Mode = amGrad then
  begin
    DegVal := FloatMod(Val, 400.0);

    if (Abs(DegVal) < EPSILON) or (Abs(DegVal - 200.0) < EPSILON) or (Abs(DegVal - 400.0) < EPSILON) then
      Exit(0.0);
    if Abs(DegVal - 100.0) < EPSILON then
      Exit(1.0);
    if Abs(DegVal - 300.0) < EPSILON then
      Exit(-1.0);
    Rad := DegVal * (Pi / 200.0);
  end
  else
  begin
    Rad := FloatMod(Val, 2.0 * Pi);

    if (Abs(Rad) < EPSILON) or (Abs(Rad - Pi) < EPSILON) or (Abs(Rad - 2.0 * Pi) < EPSILON) then
      Exit(0.0);
    if Abs(Rad - (Pi / 2.0)) < EPSILON then
      Exit(1.0);
    if Abs(Rad - (3.0 * Pi / 2.0)) < EPSILON then
      Exit(-1.0);
  end;

  Result := SanitizeFloat(Sin(Rad));
end;

function CalcCos(const Val: Double; const Mode: TAngleMode): Double;
var
  Rad, DegVal: Double;
begin
  if Mode = amDeg then
  begin
    DegVal := FloatMod(Val, 360.0);

    if (Abs(DegVal - 90.0) < EPSILON) or (Abs(DegVal - 270.0) < EPSILON) then
      Exit(0.0);
    if (Abs(DegVal) < EPSILON) or (Abs(DegVal - 360.0) < EPSILON) then
      Exit(1.0);
    if Abs(DegVal - 180.0) < EPSILON then
      Exit(-1.0);
    Rad := DegVal * (Pi / 180.0);
  end
  else if Mode = amGrad then
  begin
    DegVal := FloatMod(Val, 400.0);

    if (Abs(DegVal - 100.0) < EPSILON) or (Abs(DegVal - 300.0) < EPSILON) then
      Exit(0.0);
    if (Abs(DegVal) < EPSILON) or (Abs(DegVal - 400.0) < EPSILON) then
      Exit(1.0);
    if Abs(DegVal - 200.0) < EPSILON then
      Exit(-1.0);
    Rad := DegVal * (Pi / 200.0);
  end
  else
  begin
    Rad := FloatMod(Val, 2.0 * Pi);

    if (Abs(Rad - (Pi / 2.0)) < EPSILON) or (Abs(Rad - (3.0 * Pi / 2.0)) < EPSILON) then
      Exit(0.0);
    if (Abs(Rad) < EPSILON) or (Abs(Rad - 2.0 * Pi) < EPSILON) then
      Exit(1.0);
    if Abs(Rad - Pi) < EPSILON then
      Exit(-1.0);
  end;

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
  i, K: Int64;
  Res: Double;
begin
  if (Frac(N) <> 0) or (Frac(R) <> 0) or (N < 0) or (R < 0) or (R > N) then
    raise Exception.Create('排列参数无效 (需满足 0 <= r <= n 为整数)');
  if R = 0 then Exit(1.0);
  K := Round(R);
  Res := 1.0;
  for i := 0 to K - 1 do
  begin
    Res := Res * (N - i);
    if IsInfinite(Res) then
      raise Exception.Create('排列数超出浮点数上限');
  end;
  Result := Res;
end;

function CalcCombination(const N, R: Double): Double;
var
  i, K: Int64;
  EffectiveR: Double;
  Res: Double;
begin
  if (Frac(N) <> 0) or (Frac(R) <> 0) or (N < 0) or (R < 0) or (R > N) then
    raise Exception.Create('组合参数无效 (需满足 0 <= r <= n 为整数)');
  if (R = 0) or (R = N) then Exit(1.0);
  EffectiveR := R;
  if EffectiveR > N - EffectiveR then
    EffectiveR := N - EffectiveR; // 对称性

  K := Round(EffectiveR);
  if (K > 1000) and (N > 2000) then
    raise Exception.Create('组合数超出浮点数上限');

  Res := 1.0;
  for i := 1 to K do
  begin
    Res := Res * (N - i + 1);
    Res := Res / i;
    if IsInfinite(Res) then
      raise Exception.Create('组合数超出浮点数上限');
  end;
  Result := Res;
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

function FormatDisplayFloat(const Val: Double; const MaxPrecision: Integer): string;
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

  // 精确大整数保留完整数字串，避免科学计数法损失低位有效数字
  if (Frac(Val) = 0.0) and (AbsVal < 9.0e15) then
  begin
    if AbsVal < 2147483647 then
      Exit(IntToStr(Trunc(Val)))
    else
      Exit(IntToStr(Round(Val)));
  end;

  if (AbsVal <> 0.0) and ((AbsVal >= 1.0e16) or (AbsVal < 1.0e-9)) then
  begin
    // 采用高精度科学计数法
    S := FloatToStrF(Val, ffExponent, 14, 2, FS);
  end
  else
  begin
    // 采用常规浮点格式
    S := FloatToStrF(Val, ffGeneral, MaxPrecision, 0, FS);
  end;

  Result := S;
end;

end.
