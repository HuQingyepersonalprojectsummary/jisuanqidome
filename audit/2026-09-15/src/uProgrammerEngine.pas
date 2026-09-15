unit uProgrammerEngine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uCalcTypes;

type
  { 程序员模式计算引擎 }
  TProgrammerEngine = class
  private
    FValue: QWord;
    FOperand: QWord;
    FCurrentOp: string;
    FWordSize: TWordSize;
    FBaseRadix: TBaseRadix;
    FIsSigned: Boolean;
    FIsNewInput: Boolean;

    function MaskValue(const V: QWord): QWord;
  public
    constructor Create;

    procedure ClearAll;
    procedure ClearEntry;
    procedure Backspace;

    procedure InputHexDigit(const Ch: Char);
    procedure InputOperator(const Op: string);
    function ExecuteEquals: QWord;

    { 一元位运算 }
    procedure BitwiseNot;
    procedure ToggleBit(const BitIndex: Integer);
    function GetBit(const BitIndex: Integer): Boolean;

    { 字长与进制切换 }
    procedure SetWordSize(const ASize: TWordSize);
    procedure SetBaseRadix(const ARadix: TBaseRadix);
    procedure ToggleSigned;

    { 各进制格式化输出 }
    function GetHexStr: string;
    function GetDecStr: string;
    function GetOctStr: string;
    function GetBinStr(const Grouped: Boolean = True): string;
    function GetCurrentDisplayStr: string;

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
    FValue := MaskValue(QWord(DigitVal));
    FIsNewInput := False;
  end
  else
  begin
    FValue := MaskValue((FValue * QWord(Base)) + QWord(DigitVal));
  end;
end;

procedure TProgrammerEngine.InputOperator(const Op: string);
begin
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
    if B = 0 then raise Exception.Create('除数不能为 0');
    FValue := A div B;
  end
  else if FCurrentOp = 'MOD' then
  begin
    if B = 0 then raise Exception.Create('除数不能为 0');
    FValue := A mod B;
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
    if ShiftBits > 0 then
      FValue := ((A shl ShiftBits) or (A shr (Bits - ShiftBits)));
  end
  else if FCurrentOp = 'RoR' then
  begin
    ShiftBits := Integer(B mod Bits);
    if ShiftBits > 0 then
      FValue := ((A shr ShiftBits) or (A shl (Bits - ShiftBits)));
  end;

  FValue := MaskValue(FValue);
  FCurrentOp := '';
  FIsNewInput := True;
  Result := FValue;
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
