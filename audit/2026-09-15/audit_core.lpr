program audit_core;
{$mode objfpc}{$H+}{$codepage utf8}
uses SysUtils, Math, uCalcTypes, uMathUtils, uAlgebraicEngine, uRPNEngine,
  uProgrammerEngine, uUnitConverter;
var A:TAlgebraicEngine; R:TRPNEngine; P:TProgrammerEngine;
  Total,Failed,I,J,K:Integer; S:string; V,W:Double; OK:Boolean; T:QWord;
  Cat:TUnitCategory;
procedure Check(const Name:string; Good:Boolean; const Detail:string='');
begin
  Inc(Total); if not Good then Inc(Failed);
  if Good then Write('[PASS] ') else Write('[FAIL] ');
  WriteLn(Name,' ',Detail);
end;
procedure Near(const Name:string; Expected,Actual:Double; Rel:Double=1e-12);
begin
  Check(Name,not IsNan(Actual) and not IsInfinite(Actual) and
    (Abs(Expected-Actual)<=Max(Abs(Expected)*Rel,1e-300)),
    'expected='+FloatToStr(Expected)+' actual='+FloatToStr(Actual));
end;
procedure Dig(const S:string);
var C:Char;
begin for C in S do if C='.' then A.InputDot else A.InputDigit(C); end;
procedure Eq(const Name:string; Expected:Double);
begin OK:=A.ExecuteEquals(S); Check(Name+' success',OK,S); if OK then Near(Name,Expected,StrToFloatDef(S,NaN)); end;
procedure Probe;
begin
  if ParamStr(1)='sin-huge' then V:=CalcSin(1e23,amDeg)
  else if ParamStr(1)='sin-billion' then V:=CalcSin(1e9,amDeg)
  else if ParamStr(1)='sin-trillion' then V:=CalcSin(1e12,amDeg)
  else if ParamStr(1)='comb-huge' then V:=CalcCombination(2147483647,1000000000)
  else if ParamStr(1)='expr-bench' then begin
    A:=TAlgebraicEngine.Create; T:=GetTickCount64;
    for I:=1 to StrToInt(ParamStr(2)) do begin A.InputDigit('1'); A.InputOperator('+'); end;
    A.InputDigit('1'); A.ExecuteEquals(S);
    WriteLn('terms=',ParamStr(2),' ms=',GetTickCount64-T,' result=',S); A.Free; Exit;
  end else Halt(2);
  WriteLn(FloatToStr(V));
end;
begin
  DefaultFormatSettings.DecimalSeparator:='.';
  if ParamCount>0 then begin Probe; Halt(0); end;
  A:=TAlgebraicEngine.Create; R:=TRPNEngine.Create; P:=TProgrammerEngine.Create;
  try
    A.ClearAll; Dig('2'); A.InputOperator('+'); Dig('9'); A.ApplyUnary('sqrt'); A.InputOperator('+'); Dig('4'); Eq('unary operand 2+sqrt(9)+4',9);
    A.ClearAll; Dig('2'); A.InputOperator('*'); A.InputPi; A.InputOperator('+'); Dig('1'); Eq('constant operand 2*pi+1',2*Pi+1);
    A.ClearAll; Dig('2'); A.InputOperator('+'); A.MemoryStore(7); A.MemoryRecall; A.InputOperator('+'); Dig('1'); Eq('memory operand 2+MR(7)+1',10);
    A.ClearAll; A.InputOpenParen; Dig('9'); A.ApplyUnary('sqrt'); A.InputCloseParen; Eq('(sqrt(9))',3);
    A.ClearAll; Dig('200'); A.InputOperator('*'); Dig('10'); A.ExecutePercent; Eq('200*10%',20);
    A.ClearAll; Dig('200'); A.InputOperator('/'); Dig('10'); A.ExecutePercent; Eq('200/10%',2000);
    A.ClearAll; Dig('200'); A.InputOperator('+'); Dig('10'); A.ExecutePercent; Eq('200+10%',220);
    A.ClearAll; Dig('2'); A.InputOperator('^'); Dig('3'); A.InputOperator('^'); Dig('2'); Eq('right-associative power 2^3^2',512);
    A.ClearAll; Dig('1'); A.InputOperator('/'); Dig('0'); OK:=A.ExecuteEquals(S);
    Check('division by zero is rejected',not OK); Check('division error reflected in current input',A.CurrentInput='Error','display='+A.CurrentInput);
    try OK:=A.ExecuteEquals(S); Check('repeat after error does not report success',not OK,S);
    except on E:Exception do Check('repeat after error must not escape exception',False,E.ClassName); end;
    A.ClearAll; A.InputCloseParen; OK:=A.ExecuteEquals(S); Check('unmatched close parenthesis rejected',not OK,S);
    A.ClearAll; A.CurrentInput:='abc'; A.InputOperator('+'); Dig('1'); OK:=A.ExecuteEquals(S); Check('invalid text rejected rather than zero',not OK,S);
    A.ClearAll; Dig('1'); A.InputOperator('/'); Dig('3'); A.ExecuteEquals(S); A.InputOperator('*'); Dig('3'); Eq('(1/3)*3 preserves internal precision',1);
    A.ClearAll; Dig('1000000000000001'); A.InputOperator('+'); Dig('0'); A.ExecuteEquals(S); A.InputOperator('-'); Dig('1000000000000000'); Eq('large exact integer survives display roundtrip',1);
    A.ClearAll; A.CurrentInput:='1e-20'; A.InputOperator('*'); Dig('1'); Eq('tiny nonzero multiplication',1e-20);
    Near('power 10^-20',1e-20,CalcPower(10,-20));
    Near('1 eV to J',1.602176634e-19,ConvertValue(ucEnergy,6,0,1));
    Near('Planck h times 1',6.62607015e-34,SanitizeFloat(GetConstant(1).Value));
    try Near('67 choose 33',14226520737620288370.0,CalcCombination(67,33));
    except on E:Exception do Check('67 choose 33 representable in Double',False,E.ClassName); end;
    try Near('3000000000 permute 1',3000000000.0,CalcPermutation(3000000000.0,1));
    except on E:Exception do Check('large n permutation validated',False,E.ClassName); end;
    try V:=CalcFactorial(171); Check('171 factorial rejects overflow',False); except Check('171 factorial rejects overflow',True); end;
    try V:=CalcArcSin(2,amDeg); Check('asin domain rejection',False); except Check('asin domain rejection',True); end;
    try V:=CalcTan(90,amDeg); Check('tan pole rejection',False); except Check('tan pole rejection',True); end;
    Near('170 factorial finite',7.257415615307999e306,CalcFactorial(170));
    Near('negative cube root',-3,CalcRoot(-27,3));
    Near('RAD sin pi/2',1,CalcSin(Pi/2,amRad)); Near('GRAD sin 100',1,CalcSin(100,amGrad));
    R.ClearAll; R.InputDigit('3'); R.Enter; R.InputDigit('4'); R.ApplyBinary('+'); R.InputDigit('5'); R.ApplyBinary('*'); Near('RPN 3 ENTER 4 + 5 *',35,R.GetStackValue(0));
    R.ClearAll; R.InputDigit('8'); R.Enter; R.InputDigit('0');
    try R.ApplyBinary('/'); Check('RPN division by zero rejected',False); except Check('RPN division by zero rejected',True); end;
    Near('RPN error preserves Y',8,R.GetStackValue(1));
    P.ClearAll; P.WordSize:=wsByte; P.Value:=$81; P.InputOperator('RoL'); P.Value:=0; P.ExecuteEquals; Check('rotate left by 0 identity',P.Value=$81,'actual='+P.GetDecStr);
    P.ClearAll; P.Value:=$81; P.InputOperator('RoR'); P.Value:=8; P.ExecuteEquals; Check('rotate right by word size identity',P.Value=$81,'actual='+P.GetDecStr);
    P.ClearAll; P.IsSigned:=True; P.Value:=248; P.InputOperator('/'); P.Value:=2; P.ExecuteEquals; Check('signed byte -8/2=-4',P.GetDecStr='-4','actual='+P.GetDecStr);
    P.ClearAll; P.IsSigned:=False; P.InputHexDigit('2'); P.InputOperator('+'); P.InputHexDigit('3'); P.InputOperator('+'); P.InputHexDigit('4'); P.ExecuteEquals; Check('programmer chained 2+3+4',P.Value=9,'actual='+P.GetDecStr);
    P.ClearAll; P.InputHexDigit('2'); P.InputHexDigit('5'); P.InputHexDigit('6'); Check('byte input 256 must not silently become zero',P.Value<>0,'actual='+P.GetDecStr);
    P.ClearAll; P.Value:=255; P.InputOperator('+'); P.Value:=1; P.ExecuteEquals; Check('byte arithmetic wraps modulo 256',P.Value=0);
    P.WordSize:=wsQword; P.ClearAll; P.BaseRadix:=brHex;
    for I:=1 to 16 do P.InputHexDigit('F'); Check('uint64 max input',P.Value=High(QWord),P.GetDecStr);
    P.BaseRadix:=brBin; V:=P.Value; P.InputHexDigit('2'); Check('invalid binary digit ignored',P.Value=High(QWord));
    RandSeed:=20260915; K:=0;
    for I:=1 to 200 do begin
      J:=Random(10000); A.ClearAll; Dig(IntToStr(J)); A.InputOperator('+'); Dig('7'); A.InputOperator('*'); Dig('3'); A.ExecuteEquals(S);
      if StrToFloatDef(S,NaN)<>J+21 then Inc(K);
    end; Check('200 seeded precedence cases',K=0,'mismatches='+IntToStr(K));
    K:=0;
    for Cat:=Low(TUnitCategory) to High(TUnitCategory) do
      for I:=0 to GetUnitCount(Cat)-1 do for J:=0 to GetUnitCount(Cat)-1 do begin
        V:=ConvertValue(Cat,I,J,123.456); W:=ConvertValue(Cat,J,I,V);
        if Abs(W-123.456)>1e-7 then begin Inc(K); WriteLn('[ROUNDTRIP] cat=',Ord(Cat),' from=',I,' to=',J,' back=',FloatToStr(W)); end;
      end;
    Check('all category pair roundtrips at 123.456',K=0,'mismatches='+IntToStr(K));
    T:=GetTickCount64;
    for I:=1 to 10000 do begin A.ClearAll; Dig('2'); A.InputOperator('+'); Dig('3'); A.InputOperator('*'); Dig('4'); A.ExecuteEquals(S); end;
    WriteLn('[BENCH] 10000 short expressions ms=',GetTickCount64-T);
  finally A.Free; R.Free; P.Free; end;
  WriteLn('TOTAL=',Total,' PASSED=',Total-Failed,' FAILED=',Failed);
  if Failed>0 then Halt(1);
end.
