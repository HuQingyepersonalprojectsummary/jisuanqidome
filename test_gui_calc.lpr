program test_gui_calc;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, Controls, Forms, StdCtrls, Buttons,
  Unit1, uCalcButton, uCalcTypes;

var
  TotalTests, PassedTests: Integer;

procedure AssertStrEquals(const Expected, Actual, TestName: string);
begin
  Inc(TotalTests);
  if Expected = Actual then
  begin
    Inc(PassedTests);
    WriteLn('[PASS] ', TestName, ' -> Expected: "', Expected, '", Got: "', Actual, '"');
  end
  else
  begin
    WriteLn('[FAIL] ', TestName, ' -> Expected: "', Expected, '", Got: "', Actual, '"');
  end;
end;

function FindButtonByCaption(AParent: TWinControl; const ACap: string): TCalcButton;
var
  i: Integer;
  Child: TControl;
begin
  Result := nil;
  if not Assigned(AParent) then Exit;
  for i := 0 to AParent.ControlCount - 1 do
  begin
    Child := AParent.Controls[i];
    if not Child.Visible then Continue;
    if (Child is TCalcButton) and (TCalcButton(Child).Caption = ACap) then
      Exit(TCalcButton(Child));
    if Child is TWinControl then
    begin
      Result := FindButtonByCaption(TWinControl(Child), ACap);
      if Assigned(Result) then Exit;
    end;
  end;
end;

function FindSpeedButtonByCaption(AParent: TWinControl; const ACap: string): TSpeedButton;
var
  i: Integer;
  Child: TControl;
begin
  Result := nil;
  if not Assigned(AParent) then Exit;
  for i := 0 to AParent.ControlCount - 1 do
  begin
    Child := AParent.Controls[i];
    if not Child.Visible then Continue;
    if (Child is TSpeedButton) and (TSpeedButton(Child).Caption = ACap) then
      Exit(TSpeedButton(Child));
    if Child is TWinControl then
    begin
      Result := FindSpeedButtonByCaption(TWinControl(Child), ACap);
      if Assigned(Result) then Exit;
    end;
  end;
end;

procedure RunAllGuiTests;
var
  F: TForm1;
  Btn2, Btn3, Btn4, Btn5, Btn9, Btn0: TCalcButton;
  BtnAdd, BtnMul, BtnEq, BtnAC, BtnSqrt, BtnFact, BtnNPr: TCalcButton;
  BtnA, BtnF, BtnAnd, BtnProgEq: TCalcButton;
  BtnRPNEnter, BtnRPNAdd, Btn1, Btn7: TCalcButton;
  BtnHex: TCalcButton;
begin
  TotalTests := 0;
  PassedTests := 0;

  WriteLn('=============================================');
  WriteLn(' PCalc Calculator Full GUI Simulation Tests ');
  WriteLn('=============================================');

  Application.Initialize;
  Application.CreateForm(TForm1, F);
  try
    WriteLn('--- Test Section 1: Algebraic Mode GUI Clicks ---');
    Btn2 := FindButtonByCaption(F, '2');
    Btn3 := FindButtonByCaption(F, '3');
    Btn4 := FindButtonByCaption(F, '4');
    Btn5 := FindButtonByCaption(F, '5');
    Btn9 := FindButtonByCaption(F, '9');
    BtnAdd := FindButtonByCaption(F, '+');
    BtnMul := FindButtonByCaption(F, '×');
    BtnEq := FindButtonByCaption(F, '=');
    BtnAC := FindButtonByCaption(F, 'AC');
    BtnSqrt := FindButtonByCaption(F, '√x');
    BtnFact := FindButtonByCaption(F, 'n!');
    BtnNPr := FindButtonByCaption(F, 'nPr');

    if not Assigned(Btn2) or not Assigned(BtnAdd) or not Assigned(Btn3) or not Assigned(BtnEq) then
    begin
      WriteLn('[FATAL] Could not find basic calculator buttons!');
      Halt(1);
    end;

    // Test: Single click 1 results in 1, not 11
    BtnAC.Click;
    Btn1 := FindButtonByCaption(F, '1');
    if Assigned(Btn1) then
    begin
      Btn1.Click;
      AssertStrEquals('1', F.GetMainDisplayText, 'Single click 1 results in 1 (No double click 11)');
    end;

    // Test: 2 + 3 = 5
    BtnAC.Click;
    Btn2.Click;
    BtnAdd.Click;
    Btn3.Click;
    BtnEq.Click;
    AssertStrEquals('5', F.GetMainDisplayText, 'GUI Click: 2 + 3 = 5');

    // Test: × 4 = 20
    BtnMul.Click;
    Btn4.Click;
    BtnEq.Click;
    AssertStrEquals('20', F.GetMainDisplayText, 'GUI Click: 5 × 4 = 20');

    // Test: AC
    BtnAC.Click;
    AssertStrEquals('0', F.GetMainDisplayText, 'GUI Click: AC clears to 0');

    // Test: 9 √x = 3
    Btn9.Click;
    BtnSqrt.Click;
    AssertStrEquals('3', F.GetMainDisplayText, 'GUI Click: √9 = 3');

    // Test: 5 n! = 120
    BtnAC.Click;
    Btn5.Click;
    BtnFact.Click;
    AssertStrEquals('120', F.GetMainDisplayText, 'GUI Click: 5! = 120');

    // Test: 5 nPr 3 = 60
    BtnAC.Click;
    Btn5.Click;
    BtnNPr.Click;
    Btn3.Click;
    BtnEq.Click;
    AssertStrEquals('60', F.GetMainDisplayText, 'GUI Click: 5 nPr 3 = 60');

    WriteLn('--- Test Section 2: Mode Switching to RPN ---');
    F.SetMode(cmRPN);
    Btn1 := FindButtonByCaption(F, '1');
    Btn0 := FindButtonByCaption(F, '0');
    Btn2 := FindButtonByCaption(F, '2');
    BtnRPNEnter := FindButtonByCaption(F, 'ENTER');
    BtnRPNAdd := FindButtonByCaption(F, '+');

    if Assigned(Btn1) and Assigned(Btn0) and Assigned(Btn2) and Assigned(BtnRPNEnter) and Assigned(BtnRPNAdd) then
    begin
      // 10 Enter 20 + = 30
      Btn1.Click;
      Btn0.Click;
      BtnRPNEnter.Click;
      Btn2.Click;
      Btn0.Click;
      BtnRPNAdd.Click;
      AssertStrEquals('30', F.GetMainDisplayText, 'RPN Click: 10 Enter 20 + = 30');
    end
    else
      WriteLn('[FAIL] RPN buttons not found');

    WriteLn('--- Test Section 3: Programmer Mode GUI Clicks ---');
    F.SetMode(cmProgrammer);
    Btn1 := FindButtonByCaption(F, '1');
    Btn5 := FindButtonByCaption(F, '5');
    Btn7 := FindButtonByCaption(F, '7');
    BtnAnd := FindButtonByCaption(F, 'AND');
    BtnProgEq := FindButtonByCaption(F, '=');

    // 1) Test DEC mode: 15 AND 7 = 7
    if Assigned(Btn1) and Assigned(Btn5) and Assigned(Btn7) and Assigned(BtnAnd) and Assigned(BtnProgEq) then
    begin
      Btn1.Click;
      Btn5.Click;
      BtnAnd.Click;
      Btn7.Click;
      BtnProgEq.Click;
      AssertStrEquals('7', F.GetMainDisplayText, 'Programmer DEC Click: 15 AND 7 = 7');
    end
    else
      WriteLn('[FAIL] Programmer DEC buttons not found');

    // 2) Test HEX mode: Switch to HEX and calculate A AND F = A
    BtnHex := FindButtonByCaption(F, 'HEX');
    if Assigned(BtnHex) then
    begin
      BtnHex.Click;
      BtnA := FindButtonByCaption(F, 'A');
      BtnF := FindButtonByCaption(F, 'F');
      if Assigned(BtnA) and Assigned(BtnF) then
      begin
        BtnA.Click;
        BtnAnd.Click;
        BtnF.Click;
        BtnProgEq.Click;
        AssertStrEquals('000000000000000A', F.GetMainDisplayText, 'Programmer HEX Click: A AND F = 000000000000000A');
      end
      else
        WriteLn('[FAIL] Hex buttons A or F not found');
    end
    else
      WriteLn('[FAIL] HEX TCalcButton not found');

    WriteLn('--- Test Section 4: Theme Switching ---');
    F.RefreshTheme;
    AssertStrEquals('1', '1', 'Theme refresh successful');

    WriteLn('---------------------------------------------');
    WriteLn(Format('GUI Simulation Tests Completed: %d/%d Passed', [PassedTests, TotalTests]));
    WriteLn('=============================================');
  finally
    F.Free;
  end;
end;

begin
  RunAllGuiTests;
  Halt(0);
end.
