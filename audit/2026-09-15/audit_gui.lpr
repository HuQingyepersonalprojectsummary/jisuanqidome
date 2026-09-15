program audit_gui;
{$mode objfpc}{$H+}{$codepage utf8}
uses Interfaces, Classes, SysUtils, Math, Types, Controls, Forms, StdCtrls,
  uCalcTypes, Unit1, uCalcButton;
var F:TForm1; Total,Failed,I,N:Integer; Ch:Char; Key:Word; T:QWord;
  L:TListBox; Input:TEdit; StartHeap:PtrUInt;
procedure Check(const Name:string; Good:Boolean; const Detail:string='');
begin
  Inc(Total); if not Good then Inc(Failed);
  if Good then Write('[PASS] ') else Write('[FAIL] '); WriteLn(Name,' ',Detail);
end;
function Button(P:TWinControl; const Cap:string):TCalcButton;
var I:Integer; C:TControl;
begin
  Result:=nil;
  for I:=0 to P.ControlCount-1 do begin
    C:=P.Controls[I]; if not C.Visible then Continue;
    if (C is TCalcButton) and (TCalcButton(C).Caption=Cap) then Exit(TCalcButton(C));
    if C is TWinControl then begin Result:=Button(TWinControl(C),Cap); if Assigned(Result) then Exit; end;
  end;
end;
procedure Click(const Cap:string);
var B:TCalcButton;
begin B:=Button(F,Cap); if B=nil then raise Exception.Create('Missing button '+Cap); B.Click; end;
function ListBox(P:TWinControl):TListBox;
var I:Integer; C:TControl;
begin Result:=nil; for I:=0 to P.ControlCount-1 do begin
  C:=P.Controls[I]; if not C.Visible then Continue;
  if C is TListBox then Exit(TListBox(C));
  if C is TWinControl then begin Result:=ListBox(TWinControl(C)); if Result<>nil then Exit; end;
end; end;
function Editable(P:TWinControl):TEdit;
var I:Integer; C:TControl;
begin Result:=nil; for I:=0 to P.ControlCount-1 do begin
  C:=P.Controls[I]; if not C.Visible then Continue;
  if (C is TEdit) and not TEdit(C).ReadOnly then Exit(TEdit(C));
  if C is TWinControl then begin Result:=Editable(TWinControl(C)); if Result<>nil then Exit; end;
end; end;
procedure LayoutAudit(P:TWinControl; const Path:string);
var I,J:Integer; C,D:TControl; R:TRect;
begin
  for I:=0 to P.ControlCount-1 do begin
    C:=P.Controls[I]; if not C.Visible then Continue;
    if (C.Left<0) or (C.Top<0) or (C.Left+C.Width>P.ClientWidth) or (C.Top+C.Height>P.ClientHeight) then
      WriteLn('[LAYOUT] overflow ',Path,'/',C.ClassName,' ',C.Caption,' bounds=',C.Left,',',C.Top,',',C.Width,',',C.Height,' parent=',P.ClientWidth,',',P.ClientHeight);
    if C is TCalcButton then begin
      for J:=I+1 to P.ControlCount-1 do begin
        D:=P.Controls[J]; if D.Visible and (D is TCalcButton) and IntersectRect(R,C.BoundsRect,D.BoundsRect) then
          WriteLn('[LAYOUT] overlap ',C.Caption,' / ',D.Caption,' width=',R.Right-R.Left);
      end;
      if not TCalcButton(C).TabStop then Inc(N);
    end;
    if C is TWinControl then LayoutAudit(TWinControl(C),Path+'/'+C.ClassName);
  end;
end;
begin
  Application.Initialize;
  T:=GetTickCount64; Application.CreateForm(TForm1,F);
  WriteLn('[BENCH] form construction ms=',GetTickCount64-T,' handle=',F.Handle,' visible=',F.Visible,' size=',F.Width,'x',F.Height,' ppi=',F.PixelsPerInch);
  if ParamStr(1)='show' then begin F.Show; WriteLn('after Show visible=',F.Visible); Flush(Output); Application.Run; Halt(0); end;
  F.Show; Application.ProcessMessages;
  try
    Click('2'); Click('+'); Click('9'); Click('√x'); Click('+'); Click('4'); Click('=');
    Check('GUI unary operand retention',F.GetMainDisplayText='9','actual='+F.GetMainDisplayText);
    Click('AC'); Click('2'); Click('+'); Click('3'); Click('=');
    F.SetMode(cmTape); L:=ListBox(F);
    Check('history stores full 2+3 expression',Pos('2 + 3',L.Items[L.Items.Count-1])>0,L.Items[L.Items.Count-1]);
    F.SetMode(cmAlgebraic); Click('AC'); Click('9');
    F.SetMode(cmTape); L:=ListBox(F); L.ItemIndex:=L.Items.Count-1;
    Click('📥 回填结果'); Check('history recall restores 5',F.GetMainDisplayText='5','actual='+F.GetMainDisplayText);
    F.SetMode(cmConverter); Input:=Editable(F);
    Ch:='2'; F.FormKeyPress(F,Ch); Check('converter digit reaches edit',Ch='2','returned Ord='+IntToStr(Ord(Ch)));
    Ch:='.'; F.FormKeyPress(F,Ch); Check('converter decimal reaches edit',Ch='.','returned Ord='+IntToStr(Ord(Ch)));
    Key:=8; F.FormKeyDown(F,Key,[]); Check('converter backspace reaches edit',Key=8,'returned key='+IntToStr(Key));
    Key:=Ord('V'); F.FormKeyDown(F,Key,[ssCtrl]); Check('converter paste shortcut reaches edit',Key=Ord('V'),'returned key='+IntToStr(Key));
    Input.Text:='abc';
    WriteLn('[OBSERVE] converter invalid text=',Input.Text);
    F.SetMode(cmAlgebraic); Click('AC'); Click('1'); Click('÷'); Click('0'); Click('=');
    Check('GUI division by zero visible error',F.GetMainDisplayText='Error','actual='+F.GetMainDisplayText);
    Click('AC'); F.SetMode(cmRPN); Click('8'); Click('ENTER'); Click('0');
    Ch:='/';
    try F.FormKeyPress(F,Ch); Check('keyboard RPN zero division caught by handler',True);
    except on E:Exception do Check('keyboard RPN zero division caught by handler',False,E.ClassName); end;
    F.SetMode(cmAlgebraic); F.Width:=440; F.Height:=600; Application.ProcessMessages; F.FormResize(nil);
    N:=0; WriteLn('[LAYOUT] minimum science ',F.ClientWidth,'x',F.ClientHeight); LayoutAudit(F,'Form');
    WriteLn('[ACCESS] visible buttons without TabStop=',N);
    F.SetMode(cmProgrammer); WriteLn('[LAYOUT] minimum programmer'); LayoutAudit(F,'Form');
    F.SetMode(cmConverter); WriteLn('[LAYOUT] minimum converter'); LayoutAudit(F,'Form');
    F.Width:=540; F.Height:=750; Application.ProcessMessages; F.FormResize(nil); WriteLn('[LAYOUT] default converter'); LayoutAudit(F,'Form');
    T:=GetTickCount64; StartHeap:=GetHeapStatus.TotalAllocated;
    for I:=1 to 200 do F.SetMode(TCalcMode(I mod 5));
    WriteLn('[BENCH] 200 mode changes ms=',GetTickCount64-T,' heap_delta=',Int64(GetHeapStatus.TotalAllocated)-Int64(StartHeap));
    F.SetMode(cmAlgebraic); Click('AC'); Click('1'); Click('+'); Click('1');
    T:=GetTickCount64; StartHeap:=GetHeapStatus.TotalAllocated;
    for I:=1 to 5000 do Click('=');
    F.SetMode(cmTape); L:=ListBox(F);
    WriteLn('[BENCH] 5000 history entries ms=',GetTickCount64-T,' heap_delta=',Int64(GetHeapStatus.TotalAllocated)-Int64(StartHeap),' count=',L.Items.Count);
  finally F.Free; end;
  WriteLn('TOTAL=',Total,' PASSED=',Total-Failed,' FAILED=',Failed);
  if Failed>0 then Halt(1);
end.
