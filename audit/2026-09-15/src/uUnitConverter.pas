unit uUnitConverter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uMathUtils;

type
  TUnitCategory = (
    ucLength, ucArea, ucVolume, ucMass, ucTemp,
    ucSpeed, ucTime, ucData, ucPressure, ucEnergy
  );

  TUnitItem = record
    Name: string;
    FactorToBase: Double; // 转换为基准单位的系数
    Offset: Double;       // 偏移量（用于温度换算）
  end;

  TConstantItem = record
    Symbol: string;
    Name: string;
    Value: Double;
    UnitStr: string;
  end;

function GetCategoryCount: Integer;
function GetCategoryName(const Cat: TUnitCategory): string;
function GetUnitCount(const Cat: TUnitCategory): Integer;
function GetUnitName(const Cat: TUnitCategory; const Index: Integer): string;
function ConvertValue(const Cat: TUnitCategory; const FromIdx, ToIdx: Integer; const Val: Double): Double;

function GetConstantCount: Integer;
function GetConstant(const Index: Integer): TConstantItem;

implementation

const
  CategoryNames: array[TUnitCategory] of string = (
    '长度 (Length)', '面积 (Area)', '体积 (Volume)', '质量 (Mass)', '温度 (Temperature)',
    '速度 (Speed)', '时间 (Time)', '数据 (Data)', '压力 (Pressure)', '能量 (Energy)'
  );

type
  TUnitArray = array of TUnitItem;

function GetUnitsForCategory(const Cat: TUnitCategory): TUnitArray;
var
  List: TUnitArray;

  procedure AddUnit(const AName: string; const AFactor: Double; const AOffset: Double = 0.0);
  var
    N: Integer;
  begin
    N := Length(List);
    SetLength(List, N + 1);
    List[N].Name := AName;
    List[N].FactorToBase := AFactor;
    List[N].Offset := AOffset;
  end;

begin
  SetLength(List, 0);
  case Cat of
    ucLength: // 基准：米 (m)
    begin
      AddUnit('米 (m)', 1.0);
      AddUnit('千米 (km)', 1000.0);
      AddUnit('厘米 (cm)', 0.01);
      AddUnit('毫米 (mm)', 0.001);
      AddUnit('微米 (μm)', 1.0e-6);
      AddUnit('纳米 (nm)', 1.0e-9);
      AddUnit('英寸 (inch)', 0.0254);
      AddUnit('英尺 (ft)', 0.3048);
      AddUnit('码 (yd)', 0.9144);
      AddUnit('英里 (mile)', 1609.344);
      AddUnit('海里 (nmi)', 1852.0);
    end;
    ucArea: // 基准：平方米 (m²)
    begin
      AddUnit('平方米 (m²)', 1.0);
      AddUnit('平方千米 (km²)', 1.0e6);
      AddUnit('公顷 (ha)', 10000.0);
      AddUnit('市亩', 666.666666667);
      AddUnit('平方厘米 (cm²)', 0.0001);
      AddUnit('平方英尺 (sq ft)', 0.09290304);
      AddUnit('平方码 (sq yd)', 0.83612736);
      AddUnit('英亩 (acre)', 4046.8564224);
    end;
    ucVolume: // 基准：升 (L)
    begin
      AddUnit('升 (L)', 1.0);
      AddUnit('毫升 (mL)', 0.001);
      AddUnit('立方米 (m³)', 1000.0);
      AddUnit('美制加仑 (gal)', 3.785411784);
      AddUnit('美制品脱 (pt)', 0.473176473);
      AddUnit('液体盎司 (fl oz)', 0.02957352956);
      AddUnit('立方英尺 (cu ft)', 28.316846592);
    end;
    ucMass: // 基准：千克 (kg)
    begin
      AddUnit('千克 (kg)', 1.0);
      AddUnit('克 (g)', 0.001);
      AddUnit('毫克 (mg)', 1.0e-6);
      AddUnit('公吨 (t)', 1000.0);
      AddUnit('市斤', 0.5);
      AddUnit('磅 (lb)', 0.45359237);
      AddUnit('盎司 (oz)', 0.028349523125);
      AddUnit('克拉 (ct)', 0.0002);
    end;
    ucTemp: // 特殊换算处理：基准为摄氏度 (°C)
    begin
      AddUnit('摄氏度 (°C)', 1.0, 0.0);
      AddUnit('华氏度 (°F)', 1.0, 0.0);
      AddUnit('开尔文 (K)', 1.0, 0.0);
    end;
    ucSpeed: // 基准：米/秒 (m/s)
    begin
      AddUnit('米/秒 (m/s)', 1.0);
      AddUnit('千米/时 (km/h)', 1.0 / 3.6);
      AddUnit('英里/时 (mph)', 0.44704);
      AddUnit('节 (knot)', 0.514444444);
      AddUnit('马赫 (Mach)', 340.29);
    end;
    ucTime: // 基准：秒 (s)
    begin
      AddUnit('秒 (s)', 1.0);
      AddUnit('毫秒 (ms)', 0.001);
      AddUnit('微秒 (μs)', 1.0e-6);
      AddUnit('分钟 (min)', 60.0);
      AddUnit('小时 (h)', 3600.0);
      AddUnit('天 (day)', 86400.0);
      AddUnit('星期 (week)', 604800.0);
      AddUnit('年 (365天)', 31536000.0);
    end;
    ucData: // 基准：Byte
    begin
      AddUnit('字节 (Byte)', 1.0);
      AddUnit('比特 (bit)', 0.125);
      AddUnit('KB (1024 B)', 1024.0);
      AddUnit('MB (1024 KB)', 1048576.0);
      AddUnit('GB (1024 MB)', 1073741824.0);
      AddUnit('TB (1024 GB)', 1099511627776.0);
      AddUnit('PB (1024 TB)', 1125899906842624.0);
    end;
    ucPressure: // 基准：帕斯卡 (Pa)
    begin
      AddUnit('帕斯卡 (Pa)', 1.0);
      AddUnit('千帕 (kPa)', 1000.0);
      AddUnit('标准大气压 (atm)', 101325.0);
      AddUnit('巴 (bar)', 100000.0);
      AddUnit('毫米汞柱 (mmHg)', 133.322387415);
      AddUnit('磅/平方英寸 (psi)', 6894.757293168);
    end;
    ucEnergy: // 基准：焦耳 (J)
    begin
      AddUnit('焦耳 (J)', 1.0);
      AddUnit('千焦 (kJ)', 1000.0);
      AddUnit('卡路里 (cal)', 4.184);
      AddUnit('千卡 (kcal)', 4184.0);
      AddUnit('千瓦·时 (度 kWh)', 3600000.0);
      AddUnit('瓦·时 (Wh)', 3600.0);
      AddUnit('电子伏特 (eV)', 1.602176634e-19);
    end;
  end;
  Result := List;
end;

function GetCategoryCount: Integer;
begin
  Result := Ord(High(TUnitCategory)) + 1;
end;

function GetCategoryName(const Cat: TUnitCategory): string;
begin
  Result := CategoryNames[Cat];
end;

function GetUnitCount(const Cat: TUnitCategory): Integer;
var
  Arr: TUnitArray;
begin
  Arr := GetUnitsForCategory(Cat);
  Result := Length(Arr);
end;

function GetUnitName(const Cat: TUnitCategory; const Index: Integer): string;
var
  Arr: TUnitArray;
begin
  Arr := GetUnitsForCategory(Cat);
  if (Index >= 0) and (Index < Length(Arr)) then
    Result := Arr[Index].Name
  else
    Result := '';
end;

function ConvertValue(const Cat: TUnitCategory; const FromIdx, ToIdx: Integer; const Val: Double): Double;
var
  Arr: TUnitArray;
  BaseVal: Double;
begin
  if FromIdx = ToIdx then Exit(Val);
  Arr := GetUnitsForCategory(Cat);
  if (FromIdx < 0) or (FromIdx >= Length(Arr)) or (ToIdx < 0) or (ToIdx >= Length(Arr)) then
    Exit(Val);

  if Cat = ucTemp then
  begin
    // 转为摄氏度
    case FromIdx of
      0: BaseVal := Val;                  // °C -> °C
      1: BaseVal := (Val - 32.0) * 5.0 / 9.0; // °F -> °C
      2: BaseVal := Val - 273.15;         // K -> °C
    else
      BaseVal := Val;
    end;

    // 从摄氏度转为目标单位
    case ToIdx of
      0: Result := BaseVal;               // °C
      1: Result := (BaseVal * 9.0 / 5.0) + 32.0; // °F
      2: Result := BaseVal + 273.15;      // K
    else
      Result := BaseVal;
    end;
    Exit(SanitizeFloat(Result));
  end;

  BaseVal := Val * Arr[FromIdx].FactorToBase;
  Result := SanitizeFloat(BaseVal / Arr[ToIdx].FactorToBase);
end;

const
  ConstantsList: array[0..15] of TConstantItem = (
    (Symbol: 'c';     Name: '真空光速 (Speed of Light)';         Value: 299792458.0;              UnitStr: 'm/s'),
    (Symbol: 'h';     Name: '普朗克常数 (Planck Constant)';       Value: 6.62607015e-34;           UnitStr: 'J·s'),
    (Symbol: 'ħ';     Name: '约化普朗克常数 (Reduced Planck)';    Value: 1.054571817e-34;          UnitStr: 'J·s'),
    (Symbol: 'G';     Name: '万有引力常数 (Gravitational Const)'; Value: 6.67430e-11;              UnitStr: 'm³/(kg·s²)'),
    (Symbol: 'g';     Name: '标准重力加速度 (Standard Gravity)';  Value: 9.80665;                  UnitStr: 'm/s²'),
    (Symbol: 'k';     Name: '玻尔兹曼常数 (Boltzmann Constant)';  Value: 1.380649e-23;             UnitStr: 'J/K'),
    (Symbol: 'N_A';   Name: '阿伏伽德罗常数 (Avogadro Constant)'; Value: 6.02214076e23;            UnitStr: 'mol⁻¹'),
    (Symbol: 'e';     Name: '基本电荷量 (Elementary Charge)';     Value: 1.602176634e-19;          UnitStr: 'C'),
    (Symbol: 'm_e';   Name: '电子静止质量 (Electron Mass)';       Value: 9.1093837015e-31;         UnitStr: 'kg'),
    (Symbol: 'm_p';   Name: '质子静止质量 (Proton Mass)';         Value: 1.67262192369e-27;        UnitStr: 'kg'),
    (Symbol: 'R';     Name: '摩尔气体常数 (Gas Constant)';        Value: 8.314462618;              UnitStr: 'J/(mol·K)'),
    (Symbol: 'ε_0';   Name: '真空介电常数 (Permittivity)';        Value: 8.8541878128e-12;         UnitStr: 'F/m'),
    (Symbol: 'μ_0';   Name: '真空磁导率 (Permeability)';          Value: 1.25663706212e-6;         UnitStr: 'N/A²'),
    (Symbol: 'π';     Name: '圆周率 (Pi)';                       Value: 3.14159265358979323846;   UnitStr: ''),
    (Symbol: 'e';     Name: '自然底数 (Euler Number)';            Value: 2.71828182845904523536;   UnitStr: ''),
    (Symbol: 'φ';     Name: '黄金分割比 (Golden Ratio)';          Value: 1.61803398874989484820;   UnitStr: '')
  );

function GetConstantCount: Integer;
begin
  Result := Length(ConstantsList);
end;

function GetConstant(const Index: Integer): TConstantItem;
begin
  if (Index >= 0) and (Index < Length(ConstantsList)) then
    Result := ConstantsList[Index]
  else
  begin
    Result.Symbol := '';
    Result.Name := '';
    Result.Value := 0.0;
    Result.UnitStr := '';
  end;
end;

end.
