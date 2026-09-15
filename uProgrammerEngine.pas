unit uProgrammerEngine;

{==============================================================================
  PCalc 高级科学与工程计算器 - 程序员位运算与进制转换引擎 (uProgrammerEngine.pas)
  ------------------------------------------------------------------------------
  本单元专为软件工程师、嵌入式开发者与逆向安全人员设计：
  1. 四进制同屏联动监视与输入转换：
     - HEX (十六进制): 支持 0~9, A~F 输入与高位补零格式化
     - DEC (十进制): 支持有符号 (补码模式) 与无符号 (64位大整数) 自由切换
     - OCT (八进制): 0~7 快速转换
     - BIN (二进制): 4 位一组分段空格展示，增强阅读体验
  2. 硬件级四种字长规格与自动溢出掩码 (Word Size Truncation)：
     - QWORD (64-bit): 0x0000000000000000 ~ 0xFFFFFFFFFFFFFFFF
     - DWORD (32-bit): 0x00000000 ~ 0xFFFFFFFF
     - WORD  (16-bit): 0x0000 ~ 0xFFFF
     - BYTE  (8-bit) : 0x00 ~ 0xFF
  3. 全套硬件级位逻辑运算：
     - 基本位运算: AND, OR, XOR, NOT (按位取反), Negate (求补码 -X)
     - 扩展位运算: NAND, NOR, XNOR
     - 逻辑移位: Lsh (<<), Rsh (>>)
     - 循环移位: RoL (循环左移), RoR (循环右移)，精确适配当前字长比特边界
  4. 64 位点选式比特矩阵翻转 (Interactive Bit-Matrix Toggles)：
     - 每一个比特位独立响应点选翻转，同步联动所有进制与数值寄存器
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uCalcTypes;

type
  { 程序员模式计算引擎类定义 }
  TProgrammerEngine = class
  private
    FValue: QWord;               { 当前寄存器所持有的 64 位无符号底层数值 }
    FOperand: QWord;             { 二元运算左操作数缓存 }
    FCurrentOp: string;          { 当前等待执行的位操作符/算术符 }
    FWordSize: TWordSize;        { 当前生效的字长规格 (QWORD/DWORD/WORD/BYTE) }
    FBaseRadix: TBaseRadix;      { 当前接收键盘输入的活动进制 (HEX/DEC/OCT/BIN) }
    FIsSigned: Boolean;          { 是否处于十进制有符号补码显示模式 }
    FIsNewInput: Boolean;        { 下一次键入是否重开新数 }

    function MaskValue(const V: QWord): QWord;
    function ToSigned(const V: QWord): Int64;
    function FromSigned(const V: Int64): QWord;
  public
    constructor Create;

    { 寄存器复位与输入退格 }
    procedure ClearAll;          { 全部复位清零 }
    procedure ClearEntry;        { 清除当前输入 }
    procedure Backspace;         { 当前活动进制下删除一位字符 }

    { 输入与二元运算求值 }
    procedure InputHexDigit(const Ch: Char);   { 录入十六进制字符 '0'..'9', 'A'..'F' }
    procedure InputOperator(const Op: string); { 录入运算符 (+, -, AND, OR, XOR, Lsh 等) }
    function ExecuteEquals: QWord;             { 执行等号运算并应用字长掩码 }

    { 一元位操作与比特翻转 }
    procedure BitwiseNot;                      { 按位取反 NOT }
    procedure Negate;                          { 取相反数 (二补码负数) }
    procedure ToggleBit(const BitIndex: Integer); { 翻转指定序号比特位 (0~63) }
    function GetBit(const BitIndex: Integer): Boolean; { 查询指定序号比特位是否为 1 }

    { 字长与进制切换 }
    procedure SetWordSize(const ASize: TWordSize);     { 切换当前生效字长 }
    procedure SetBaseRadix(const ARadix: TBaseRadix);  { 切换当前输入进制 }
    procedure ToggleSigned;                            { 切换十进制有符号/无符号 }

    { 多进制格式化串导出 }
    function GetHexStr: string;                        { 获取规范高位对齐十六进制串 }
    function GetDecStr: string;                        { 获取十进制串 (依据有符号状态) }
    function GetOctStr: string;                        { 获取八进制串 }
    function GetBinStr(const Grouped: Boolean = True): string; { 获取二进制串 (4位分段) }
    function GetCurrentDisplayStr: string;             { 获取当前活动进制下的显示串 }

    { 属性暴露 }
    property Value: QWord read FValue write FValue;
    property WordSize: TWordSize read FWordSize write SetWordSize;
    property BaseRadix: TBaseRadix read FBaseRadix write SetBaseRadix;
    property IsSigned: Boolean read FIsSigned write FIsSigned;
    property CurrentOp: string read FCurrentOp;
    property IsNewInput: Boolean read FIsNewInput write FIsNewInput;
  end;

implementation

constructor TProgrammerEngine.Create;
begin
  inherited Create;
  FWordSize := wsQword;
  FBaseRadix := brDec;
  FIsSigned := False;
  ClearAll;
end;

function TProgrammerEngine.MaskValue(const V: QWord): QWord;
begin
  Result := V and WordSizeMasks[FWordSize];
end;

function TProgrammerEngine.ToSigned(const V: QWord): Int64;
begin
  case FWordSize of
    wsByte:  Result := ShortInt(Byte(V));
    wsWord:  Result := SmallInt(Word(V));
    wsDword: Result := LongInt(LongWord(V));
    wsQword: Result := Int64(V);
  end;
end;

function TProgrammerEngine.FromSigned(const V: Int64): QWord;
begin
  Result := MaskValue(QWord(V));
end;

procedure TProgrammerEngine.ClearAll;
begin
  FValue := 0;
  FOperand := 0;
  FCurrentOp := '';
  FIsNewInput := True;
end;

procedure TProgrammerEngine.ClearEntry;
begin
  FValue := 0;
  FIsNewInput := True;
end;

procedure TProgrammerEngine.Backspace;
var
  Base: Integer;
begin
  if FIsNewInput then Exit;
  case FBaseRadix of
    brHex: Base := 16;
    brDec: Base := 10;
    brOct: Base := 8;
    brBin: Base := 2;
  end;

  FValue := MaskValue(FValue div Base);
  if FValue = 0 then
    FIsNewInput := True;
end;

procedure TProgrammerEngine.InputHexDigit(const Ch: Char);
var
  DigitVal: Integer;
  Base: Integer;
  UpperCh: Char;
begin
  UpperCh := UpCase(Ch);
  case FBaseRadix of
    brHex:
    begin
      Base := 16;
      if UpperCh in ['0'..'9'] then DigitVal := Ord(UpperCh) - Ord('0')
      else if UpperCh in ['A'..'F'] then DigitVal := Ord(UpperCh) - Ord('A') + 10
      else Exit;
    end;
    brDec:
    begin
      Base := 10;
      if UpperCh in ['0'..'9'] then DigitVal := Ord(UpperCh) - Ord('0')
      else Exit;
    end;
    brOct:
    begin
      Base := 8;
      if UpperCh in ['0'..'7'] then DigitVal := Ord(UpperCh) - Ord('0')
      else Exit;
    end;
    brBin:
    begin
      Base := 2;
      if UpperCh in ['0'..'1'] then DigitVal := Ord(UpperCh) - Ord('0')
      else Exit;
    end;
  end;

  if FIsNewInput then
  begin
    if QWord(DigitVal) > WordSizeMasks[FWordSize] then Exit;
    FValue := QWord(DigitVal);
    FIsNewInput := False;
  end
  else
  begin
    if (WordSizeMasks[FWordSize] < QWord(DigitVal)) or
       ((WordSizeMasks[FWordSize] - QWord(DigitVal)) div QWord(Base) < FValue) then
      Exit;
    FValue := (FValue * QWord(Base)) + QWord(DigitVal);
  end;
end;

procedure TProgrammerEngine.InputOperator(const Op: string);
begin
  if (FCurrentOp <> '') and (not FIsNewInput) then
  begin
    ExecuteEquals;
  end;
  FOperand := FValue;
  FCurrentOp := Op;
  FIsNewInput := True;
end;

function TProgrammerEngine.ExecuteEquals: QWord;
var
  A, B: QWord;
  ShiftBits: Integer;
  Bits: Integer;
begin
  A := FOperand;
  B := FValue;
  Bits := WordSizeBits[FWordSize];

  if FCurrentOp = '+' then FValue := A + B
  else if FCurrentOp = '-' then FValue := A - B
  else if (FCurrentOp = '×') or (FCurrentOp = '*') then FValue := A * B
  else if (FCurrentOp = '÷') or (FCurrentOp = '/') then
  begin
    if FIsSigned then
    begin
      if ToSigned(B) = 0 then raise Exception.Create('除数不能为 0');
      FValue := FromSigned(ToSigned(A) div ToSigned(B));
    end
    else
    begin
      if B = 0 then raise Exception.Create('除数不能为 0');
      FValue := A div B;
    end;
  end
  else if FCurrentOp = 'MOD' then
  begin
    if FIsSigned then
    begin
      if ToSigned(B) = 0 then raise Exception.Create('除数不能为 0');
      FValue := FromSigned(ToSigned(A) mod ToSigned(B));
    end
    else
    begin
      if B = 0 then raise Exception.Create('除数不能为 0');
      FValue := A mod B;
    end;
  end
  else if FCurrentOp = 'AND' then FValue := A and B
  else if FCurrentOp = 'OR'  then FValue := A or B
  else if FCurrentOp = 'XOR' then FValue := A xor B
  else if FCurrentOp = 'NAND' then FValue := not (A and B)
  else if FCurrentOp = 'NOR'  then FValue := not (A or B)
  else if FCurrentOp = 'XNOR' then FValue := not (A xor B)
  else if (FCurrentOp = 'Lsh') or (FCurrentOp = '<<') then
  begin
    ShiftBits := Integer(B and 63);
    FValue := A shl ShiftBits;
  end
  else if (FCurrentOp = 'Rsh') or (FCurrentOp = '>>') then
  begin
    ShiftBits := Integer(B and 63);
    FValue := A shr ShiftBits;
  end
  else if FCurrentOp = 'RoL' then
  begin
    ShiftBits := Integer(B mod Bits);
    A := MaskValue(A);
    if ShiftBits > 0 then
      FValue := ((A shl ShiftBits) or (A shr (Bits - ShiftBits)))
    else
      FValue := A;
  end
  else if FCurrentOp = 'RoR' then
  begin
    ShiftBits := Integer(B mod Bits);
    A := MaskValue(A);
    if ShiftBits > 0 then
      FValue := ((A shr ShiftBits) or (A shl (Bits - ShiftBits)))
    else
      FValue := A;
  end;

  FValue := MaskValue(FValue);
  FCurrentOp := '';
  FIsNewInput := True;
  Result := FValue;
end;

procedure TProgrammerEngine.Negate;
begin
  FValue := MaskValue(not FValue + 1);
  FIsNewInput := True;
end;

procedure TProgrammerEngine.BitwiseNot;
begin
  FValue := MaskValue(not FValue);
  FIsNewInput := True;
end;

procedure TProgrammerEngine.ToggleBit(const BitIndex: Integer);
var
  BitMask: QWord;
begin
  if (BitIndex >= 0) and (BitIndex < WordSizeBits[FWordSize]) then
  begin
    BitMask := QWord(1) shl BitIndex;
    FValue := MaskValue(FValue xor BitMask);
  end;
end;

function TProgrammerEngine.GetBit(const BitIndex: Integer): Boolean;
begin
  if (BitIndex >= 0) and (BitIndex < 64) then
    Result := ((FValue shr BitIndex) and 1) = 1
  else
    Result := False;
end;

procedure TProgrammerEngine.SetWordSize(const ASize: TWordSize);
begin
  FWordSize := ASize;
  FValue := MaskValue(FValue);
  FOperand := MaskValue(FOperand);
end;

procedure TProgrammerEngine.SetBaseRadix(const ARadix: TBaseRadix);
begin
  FBaseRadix := ARadix;
end;

procedure TProgrammerEngine.ToggleSigned;
begin
  FIsSigned := not FIsSigned;
end;

function TProgrammerEngine.GetHexStr: string;
begin
  case FWordSize of
    wsQword: Result := IntToHex(FValue, 16);
    wsDword: Result := IntToHex(FValue, 8);
    wsWord:  Result := IntToHex(FValue, 4);
    wsByte:  Result := IntToHex(FValue, 2);
  end;
end;

function TProgrammerEngine.GetDecStr: string;
begin
  if FIsSigned then
  begin
    case FWordSize of
      wsQword: Result := IntToStr(Int64(FValue));
      wsDword: Result := IntToStr(LongInt(LongWord(FValue)));
      wsWord:  Result := IntToStr(SmallInt(Word(FValue)));
      wsByte:  Result := IntToStr(ShortInt(Byte(FValue)));
    end;
  end
  else
  begin
    Str(FValue, Result);
  end;
end;

function TProgrammerEngine.GetOctStr: string;
var
  V: QWord;
  S: string;
begin
  V := FValue;
  if V = 0 then Exit('0');
  S := '';
  while V > 0 do
  begin
    S := Chr(Ord('0') + (V mod 8)) + S;
    V := V div 8;
  end;
  Result := S;
end;

function TProgrammerEngine.GetBinStr(const Grouped: Boolean = True): string;
var
  i, Bits: Integer;
  S: string;
begin
  Bits := WordSizeBits[FWordSize];
  S := '';
  for i := Bits - 1 downto 0 do
  begin
    if ((FValue shr i) and 1) = 1 then
      S := S + '1'
    else
      S := S + '0';

    if Grouped and (i > 0) and (i mod 4 = 0) then
      S := S + ' ';
  end;
  Result := S;
end;

function TProgrammerEngine.GetCurrentDisplayStr: string;
begin
  case FBaseRadix of
    brHex: Result := GetHexStr;
    brDec: Result := GetDecStr;
    brOct: Result := GetOctStr;
    brBin: Result := GetBinStr(False);
  end;
end;

end.
