program test_calc;

{$mode objfpc}{$H+}

uses
  SysUtils, Math,
  uCalcTypes, uMathUtils, uAlgebraicEngine, uRPNEngine, uProgrammerEngine, uUnitConverter;

var
  TotalTests, PassedTests: Integer;

procedure AssertTrue(const Condition: Boolean; const TestName: string);
begin
  Inc(TotalTests);
  if Condition then
  begin
    Inc(PassedTests);
    WriteLn('[PASS] ', TestName);
  end
  else
  begin
    WriteLn('[FAIL] ', TestName);
  end;
end;

procedure AssertFloatEquals(const Expected, Actual: Double; const Tolerance: Double; const TestName: string);
begin
  Inc(TotalTests);
  if Abs(Expected - Actual) <= Tolerance then
  begin
    Inc(PassedTests);
    WriteLn('[PASS] ', TestName, ' -> Expected: ', Expected:0:6, ', Actual: ', Actual:0:6);
  end
  else
  begin
    WriteLn('[FAIL] ', TestName, ' -> Expected: ', Expected:0:6, ', Actual: ', Actual:0:6);
  end;
end;

procedure TestMathUtils;
begin
  WriteLn('--- Testing uMathUtils ---');
  // 1. sin(180 deg) must be exact 0 (fixed precision leak)
  AssertFloatEquals(0.0, CalcSin(180.0, amDeg), 1e-12, 'CalcSin(180 deg) == 0.0');
  AssertFloatEquals(0.0, CalcSin(360.0, amDeg), 1e-12, 'CalcSin(360 deg) == 0.0');
  AssertFloatEquals(1.0, CalcSin(90.0, amDeg), 1e-12, 'CalcSin(90 deg) == 1.0');
  AssertFloatEquals(-1.0, CalcSin(270.0, amDeg), 1e-12, 'CalcSin(270 deg) == -1.0');
  AssertFloatEquals(0.0, CalcCos(90.0, amDeg), 1e-12, 'CalcCos(90 deg) == 0.0');
  AssertFloatEquals(1.0, CalcCos(0.0, amDeg), 1e-12, 'CalcCos(0 deg) == 1.0');
  AssertFloatEquals(-1.0, CalcCos(180.0, amDeg), 1e-12, 'CalcCos(180 deg) == -1.0');
  AssertFloatEquals(1.0, CalcTan(45.0, amDeg), 1e-12, 'CalcTan(45 deg) == 1.0');

  // 2. Factorial up to large numbers without false limits
  AssertFloatEquals(120.0, CalcFactorial(5.0), 1e-6, '5! == 120');
  AssertFloatEquals(3628800.0, CalcFactorial(10.0), 1e-6, '10! == 3628800');
  AssertFloatEquals(6227020800.0, CalcFactorial(13.0), 1e-6, '13! == 6227020800 (exceeded previous 12 limit)');
  AssertFloatEquals(2432902008176640000.0, CalcFactorial(20.0), 1e-6, '20! == 2432902008176640000');

  // 3. Permutations and Combinations
  AssertFloatEquals(60.0, CalcPermutation(5.0, 3.0), 1e-6, '5 P 3 == 60');
  AssertFloatEquals(10.0, CalcCombination(5.0, 3.0), 1e-6, '5 C 3 == 10');

  // 4. Power & Root
  AssertFloatEquals(1024.0, CalcPower(2.0, 10.0), 1e-6, '2^10 == 1024');
  AssertFloatEquals(18446744073709551616.0, CalcPower(2.0, 64.0), 1e-6, '2^64 evaluated without arbitrary limit');
  AssertFloatEquals(3.0, CalcRoot(27.0, 3.0), 1e-6, '3√27 == 3');
end;

procedure TestAlgebraicEngine;
var
  Eng: TAlgebraicEngine;
  ResStr: string;
begin
  WriteLn('--- Testing uAlgebraicEngine ---');
  Eng := TAlgebraicEngine.Create;
  try
    // Test 1: Chained operations 2 + 3 + 4 = 9 (previously broke and returned 7)
    Eng.ClearAll;
    Eng.InputDigit('2');
    Eng.InputOperator('+');
    Eng.InputDigit('3');
    Eng.InputOperator('+');
    Eng.InputDigit('4');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '9', 'Chained addition 2 + 3 + 4 = 9');

    // Test 2: Operator Precedence 2 + 3 * 4 = 14
    Eng.ClearAll;
    Eng.InputDigit('2');
    Eng.InputOperator('+');
    Eng.InputDigit('3');
    Eng.InputOperator('×');
    Eng.InputDigit('4');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '14', 'Operator precedence 2 + 3 × 4 = 14');

    // Test 3: Parentheses ( 2 + 3 ) * 4 = 20
    Eng.ClearAll;
    Eng.InputOpenParen;
    Eng.InputDigit('2');
    Eng.InputOperator('+');
    Eng.InputDigit('3');
    Eng.InputCloseParen;
    Eng.InputOperator('×');
    Eng.InputDigit('4');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '20', 'Parentheses (2 + 3) × 4 = 20');

    // Test 4: Repeated equals execution 5 + 2 = 7, = 9, = 11
    Eng.ClearAll;
    Eng.InputDigit('5');
    Eng.InputOperator('+');
    Eng.InputDigit('2');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '7', 'First equals: 5 + 2 = 7');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '9', 'Repeat equals 1: 7 + 2 = 9');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '11', 'Repeat equals 2: 9 + 2 = 11');

    // Test 5: Memory operations
    Eng.ClearAll;
    Eng.CurrentInput := '50';
    Eng.MemoryStore(50.0);
    AssertTrue(Eng.HasMemory, 'Memory has value');
    Eng.MemoryAdd(25.0);
    AssertFloatEquals(75.0, Eng.MemoryValue, 1e-6, 'Memory after M+ is 75');
    Eng.MemorySub(10.0);
    AssertFloatEquals(65.0, Eng.MemoryRecall, 1e-6, 'Memory after M- is 65');
    Eng.MemoryClear;
    AssertTrue(not Eng.HasMemory, 'Memory cleared');

    // Test 6: Permutation and Combination and MOD
    Eng.ClearAll;
    Eng.InputDigit('5');
    Eng.InputOperator('nPr');
    Eng.InputDigit('3');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '60', 'Algebraic 5 nPr 3 = 60');

    Eng.ClearAll;
    Eng.InputDigit('5');
    Eng.InputOperator('nCr');
    Eng.InputDigit('3');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '10', 'Algebraic 5 nCr 3 = 10');

    Eng.ClearAll;
    Eng.InputDigit('1');
    Eng.InputDigit('7');
    Eng.InputOperator('MOD');
    Eng.InputDigit('5');
    Eng.ExecuteEquals(ResStr);
    AssertTrue(ResStr = '2', 'Algebraic 17 MOD 5 = 2');
  finally
    Eng.Free;
  end;
end;

procedure TestRPNEngine;
var
  RPN: TRPNEngine;
begin
  WriteLn('--- Testing uRPNEngine ---');
  RPN := TRPNEngine.Create;
  try
    // Test: 3 [Enter] 4 [+] -> 7
    RPN.ClearAll;
    RPN.InputDigit('3');
    RPN.Enter;
    RPN.InputDigit('4');
    RPN.ApplyBinary('+');
    AssertFloatEquals(7.0, RPN.GetStackValue(0), 1e-6, 'RPN 3 Enter 4 + == 7');

    // Test: Swap X and Y
    RPN.ClearAll;
    RPN.InputDigit('1');
    RPN.Enter;
    RPN.InputDigit('2');
    RPN.SwapXY;
    AssertFloatEquals(1.0, RPN.GetStackValue(0), 1e-6, 'RPN Swap top is 1');
    AssertFloatEquals(2.0, RPN.GetStackValue(1), 1e-6, 'RPN Swap next is 2');

    // Test: Roll
    RPN.ClearAll;
    RPN.InputDigit('1'); RPN.Enter;
    RPN.InputDigit('2'); RPN.Enter;
    RPN.InputDigit('3'); RPN.Enter;
    RPN.InputDigit('4'); // Stack is X:4, Y:3, Z:2, T:1
    RPN.RollDown; // After RollDown, X becomes old Y (3), T becomes old X (4)
    AssertFloatEquals(3.0, RPN.GetStackValue(0), 1e-6, 'RPN RollDown moves Y to X (3)');
    RPN.RollUp; // RollUp reverses it, restoring X to 4
    AssertFloatEquals(4.0, RPN.GetStackValue(0), 1e-6, 'RPN RollUp restores X to 4');
  finally
    RPN.Free;
  end;
end;

procedure TestProgrammerEngine;
var
  Prog: TProgrammerEngine;
begin
  WriteLn('--- Testing uProgrammerEngine ---');
  Prog := TProgrammerEngine.Create;
  try
    Prog.ClearAll;
    // Set DEC 255
    Prog.BaseRadix := brDec;
    Prog.InputHexDigit('2');
    Prog.InputHexDigit('5');
    Prog.InputHexDigit('5');
    AssertTrue(Prog.GetHexStr = '00000000000000FF', 'Dec 255 == Hex 00FF');
    AssertTrue(Prog.GetOctStr = '377', 'Dec 255 == Oct 377');

    // Bitwise operations
    Prog.ClearAll;
    Prog.Value := $0F;
    Prog.InputOperator('AND');
    Prog.Value := $33;
    Prog.ExecuteEquals;
    AssertTrue(Prog.Value = $03, '0x0F AND 0x33 == 0x03');

    // Bit toggling
    Prog.ClearAll;
    Prog.Value := 0;
    Prog.ToggleBit(3); // 2^3 = 8
    AssertTrue(Prog.Value = 8, 'ToggleBit 3 yields 8');
    AssertTrue(Prog.GetBit(3) = True, 'GetBit 3 is True');
    Prog.ToggleBit(3);
    AssertTrue(Prog.Value = 0, 'ToggleBit 3 again yields 0');
  finally
    Prog.Free;
  end;
end;

procedure TestUnitConverter;
var
  Res: Double;
begin
  WriteLn('--- Testing uUnitConverter ---');
  // 100 °C to °F should be 212 °F
  Res := ConvertValue(ucTemp, 0, 1, 100.0);
  AssertFloatEquals(212.0, Res, 1e-6, '100 °C == 212 °F');

  // 1 km to m should be 1000 m
  Res := ConvertValue(ucLength, 1, 0, 1.0);
  AssertFloatEquals(1000.0, Res, 1e-6, '1 km == 1000 m');

  // 1024 MB to GB should be 1 GB
  Res := ConvertValue(ucData, 3, 4, 1024.0);
  AssertFloatEquals(1.0, Res, 1e-6, '1024 MB == 1 GB');
end;

begin
  TotalTests := 0;
  PassedTests := 0;
  DefaultFormatSettings.DecimalSeparator := '.';

  WriteLn('=============================================');
  WriteLn(' PCalc Calculator Comprehensive Test Suite   ');
  WriteLn('=============================================');

  TestMathUtils;
  TestAlgebraicEngine;
  TestRPNEngine;
  TestProgrammerEngine;
  TestUnitConverter;

  WriteLn('---------------------------------------------');
  WriteLn(Format('Tests Completed: %d/%d Passed (%.1f%%)', [PassedTests, TotalTests, (PassedTests / TotalTests) * 100.0]));
  WriteLn('=============================================');

  if PassedTests = TotalTests then
    Halt(0)
  else
    Halt(1);
end.
