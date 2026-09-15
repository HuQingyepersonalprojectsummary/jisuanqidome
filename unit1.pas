unit Unit1;

{==============================================================================
  PCalc 高级科学与工程计算器 - 主窗体界面与协调控制器 (Unit1.pas)
  ------------------------------------------------------------------------------
  本单元是计算器的前台调度中枢与视图协调器 (View-Controller)：
  1. 纯代码组件构建体系 (Procedural Component Construction)：
     - 脱离庞大静态 LFM 束缚，全代码动态构建并接管所有面板、按键、显示器
  2. 响应式布局排版引擎 (Responsive Layout Algorithm)：
     - 自适应窗体宽度与高度，支持从 440×600 紧凑微型窗体平滑放大至全屏
     - 程序员模式 64 比特位与进制按钮在极端尺寸下智能折叠收缩
  3. 五大工作模式协调调度：
     - 代数与高级科学计算模式 (cmAlgebraic)
     - 经典 4 级 RPN 逆波兰表达式堆栈模式 (cmRPN)
     - 程序员四进制与 64 位点选位翻转模式 (cmProgrammer)
     - 10 大类物理单位换算器与物理常数速查库 (cmConverter)
     - 仿真纸带历史记录与带时间戳表达式一键回填 (cmTape)
  4. 全局键盘智能钩子系统 (Intelligent Key Routing)：
     - 捕获全局数字小键盘、运算符、回车等号、Esc 全清、Ctrl+C / Ctrl+V
     - 在单位换算器或活动可编辑输入框中主动让行，保证原生键入体验
  5. 现代 UI 设计令牌与 Windows DWM 沉浸式暗色标题栏深度整合
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Buttons, Clipbrd, Math,
  uCalcTypes, uMathUtils, uAlgebraicEngine, uRPNEngine, uProgrammerEngine,
  uUnitConverter, uThemeManager, uCalcButton;

type
  { 主窗体类：统一调度显示、按键交互、引擎计算与响应式布局 }
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormResize(Sender: TObject);
  private
    { 响应式状态与引擎 }
    FIsInitialized: Boolean;
    FAlgEngine: TAlgebraicEngine;
    FRPNEngine: TRPNEngine;
    FProgEngine: TProgrammerEngine;
    FTapeList: TStringList;

    { 状态机状态 }
    FCurMode: TCalcMode;
    FLastCalcMode: TCalcMode;
    FAngleMode: TAngleMode;
    FCurTheme: TThemeType;
    FAlwaysOnTop: Boolean;
    FSecondFunc: Boolean; // 2nd 功能反转开关

    { 顶部与显示区控件 }
    PanelTopBar: TPanel;
    BtnModeAlg: TCalcButton;
    BtnModeRPN: TCalcButton;
    BtnModeProg: TCalcButton;
    BtnModeConv: TCalcButton;
    BtnModeTape: TCalcButton;
    BtnAngle: TCalcButton;
    BtnTopMost: TCalcButton;
    BtnTheme: TCalcButton;

    PanelDisplay: TPanel;
    LabelExpr: TLabel;
    LabelMem: TLabel;
    EditMainDisplay: TEdit;

    { 程序员模式四进制实时指示器 }
    PanelProgBases: TPanel;
    LabelHexBase: TLabel;
    LabelDecBase: TLabel;
    LabelOctBase: TLabel;
    LabelBinBase: TLabel;

    { 多模式页面容器 (使用原生 TPanel 保证纯色自绘，避免 UxTheme 强制画白底) }
    PanelModes: TPanel;
    PanelScientific: TPanel;
    PanelRPN: TPanel;
    PanelProgrammer: TPanel;
    PanelConverter: TPanel;
    PanelTape: TPanel;

    { 科学模式动态按钮与按键表 }
    Btn2nd: TCalcButton;
    BtnSin, BtnCos, BtnTan: TCalcButton;
    BtnSinh, BtnCosh, BtnTanh: TCalcButton;
    BtnXSq, BtnCube, BtnSqrt: TCalcButton;
    FScientificRows: array[0..6] of array of TCalcButton;

    { RPN 堆栈界面控件 }
    PanelRPNStack: TPanel;
    LabelStackT: TLabel;
    LabelStackZ: TLabel;
    LabelStackY: TLabel;
    LabelStackX: TLabel;
    FRPNRows: array[0..5] of array of TCalcButton;

    { 程序员模式交互比特位按钮 }
    FPanelBits: TPanel;
    BitButtons: array[0..63] of TCalcButton;
    BtnWordSize: TCalcButton;
    BtnSigned: TCalcButton;
    BtnRadixHex, BtnRadixDec, BtnRadixOct, BtnRadixBin: TCalcButton;
    HexButtons: array['A'..'F'] of TCalcButton;
    DigitButtons: array['0'..'9'] of TCalcButton;
    FProgRows: array[0..5] of array of TCalcButton;

    { 单位换算与常数控件 }
    LblCat, LblFrom, LblTo, LblConst: TLabel;
    ComboCat: TComboBox;
    ComboFromUnit: TComboBox;
    ComboToUnit: TComboBox;
    EditFromVal: TEdit;
    EditToVal: TEdit;
    BtnSwapUnits: TCalcButton;
    ListConstants: TListBox;
    BtnInsertConst: TCalcButton;

    { 纸带控件 }
    ListTape: TListBox;
    BtnTapeUse: TCalcButton;
    BtnTapeCopySel: TCalcButton;
    BtnTapeCopyAll: TCalcButton;
    BtnTapeClear: TCalcButton;

    { 界面初始化子流程 }
    procedure BuildTopBar;
    procedure BuildDisplayArea;
    procedure BuildScientificTab;
    procedure BuildRPNTab;
    procedure BuildProgrammerTab;
    procedure BuildConverterTab;
    procedure BuildTapeTab;

    { 响应式动态布局重排 }
    procedure LayoutTopBar;
    procedure LayoutDisplayArea;
    procedure LayoutScientificTab;
    procedure LayoutRPNTab;
    procedure LayoutProgrammerTab;
    procedure LayoutConverterTab;
    procedure LayoutTapeTab;

    { 事件处理 }
    procedure OnModeBtnClick(Sender: TObject);
    procedure OnAngleBtnClick(Sender: TObject);
    procedure OnTopMostBtnClick(Sender: TObject);
    procedure OnThemeBtnClick(Sender: TObject);

    { 科学/代数计算事件 }
    procedure OnAlgNumClick(Sender: TObject);
    procedure OnAlgOpClick(Sender: TObject);
    procedure OnAlgEqualsClick(Sender: TObject);
    procedure OnAlgClearClick(Sender: TObject);
    procedure OnAlgClearEntryClick(Sender: TObject);
    procedure OnAlgBackClick(Sender: TObject);
    procedure OnAlgSignClick(Sender: TObject);
    procedure OnAlgDotClick(Sender: TObject);
    procedure OnAlgPercentClick(Sender: TObject);
    procedure OnAlgParenOpenClick(Sender: TObject);
    procedure OnAlgParenCloseClick(Sender: TObject);
    procedure OnAlgUnaryClick(Sender: TObject);
    procedure OnAlgMemoryClick(Sender: TObject);
    procedure OnAlg2ndClick(Sender: TObject);

    { RPN 模式事件 }
    procedure OnRPNNumClick(Sender: TObject);
    procedure OnRPNEnterClick(Sender: TObject);
    procedure OnRPNDropClick(Sender: TObject);
    procedure OnRPNSwapClick(Sender: TObject);
    procedure OnRPNRollDownClick(Sender: TObject);
    procedure OnRPNRollUpClick(Sender: TObject);
    procedure OnRPNClearClick(Sender: TObject);
    procedure OnRPNOpClick(Sender: TObject);
    procedure OnRPNUnaryClick(Sender: TObject);

    { 程序员模式事件 }
    procedure OnProgRadixClick(Sender: TObject);
    procedure OnProgWordSizeClick(Sender: TObject);
    procedure OnProgSignedClick(Sender: TObject);
    procedure OnProgBitClick(Sender: TObject);
    procedure OnProgDigitClick(Sender: TObject);
    procedure OnProgOpClick(Sender: TObject);
    procedure OnProgEqualsClick(Sender: TObject);
    procedure OnProgNotClick(Sender: TObject);
    procedure OnProgClearClick(Sender: TObject);
    procedure OnProgBackClick(Sender: TObject);

    { 换算模式事件 }
    procedure OnConvCategoryChange(Sender: TObject);
    procedure OnConvFromChange(Sender: TObject);
    procedure OnConvToChange(Sender: TObject);
    procedure OnConvInputChange(Sender: TObject);
    procedure OnConvSwapClick(Sender: TObject);
    procedure OnInsertConstantClick(Sender: TObject);

    { 纸带历史事件 }
    procedure OnTapeUseClick(Sender: TObject);
    procedure OnTapeCopySelClick(Sender: TObject);
    procedure OnTapeCopyAllClick(Sender: TObject);
    procedure OnTapeClearClick(Sender: TObject);

    { 刷新与界面更新 }
    procedure UpdateDisplays;
    procedure UpdateRPNStackLabels;
    procedure UpdateProgrammerBasesAndBits;
    procedure AppendToTape(const ExprText, ResultText: string);
  public
    procedure RefreshTheme;
    procedure SetMode(const AMode: TCalcMode);
    function GetMainDisplayText: string;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ 辅助：创建带高质感自绘样式的计算器按钮 (彻底摆脱系统白底限制) }
function CreateCalcBtn(AParent: TWinControl; const ACaption: string;
  AClick: TNotifyEvent; const ATag: Integer = 0;
  const ARole: TCalcButtonRole = cbrFunction): TCalcButton;
begin
  Result := TCalcButton.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Tag := ATag;
  Result.Role := ARole;
  Result.Font.Name := 'Microsoft YaHei UI';
  Result.Font.Size := 11;
  Result.Font.Style := [];
  Result.CornerRadius := 8;
  Result.OnClick := AClick;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FIsInitialized := False;

  // 强制本地化小数点为英文句号 '.'，杜绝多语言 Windows 区域设置崩溃
  DefaultFormatSettings.DecimalSeparator := '.';

  // 初始化引擎与状态
  FAlgEngine := TAlgebraicEngine.Create;
  FRPNEngine := TRPNEngine.Create;
  FProgEngine := TProgrammerEngine.Create;
  FTapeList := TStringList.Create;

  FCurMode := cmAlgebraic;
  FLastCalcMode := cmAlgebraic;
  FAngleMode := amDeg;
  FCurTheme := ttBlack; // 默认采用沉浸暗夜黑主题，解决整体界面过白问题
  FAlwaysOnTop := False;
  FSecondFunc := False;

  // 基础窗体属性与自适应约束
  Caption := 'PCalc 高级计算器 (Windows 10/11)';
  Width := 540;
  Height := 750;
  Constraints.MinWidth := 440;
  Constraints.MinHeight := 600;
  Position := poScreenCenter;
  KeyPreview := True;

  // 构建核心界面层级
  BuildTopBar;
  BuildDisplayArea;
  PanelTopBar.Top := 0;
  PanelDisplay.Top := 46;
  PanelProgBases.Top := 150;

  // 模式页面容器 (使用独立 TPanel 彻底杜绝 Windows UxTheme 强制刷白底问题)
  PanelModes := TPanel.Create(Self);
  PanelModes.Parent := Self;
  PanelModes.Align := alClient;
  PanelModes.BevelOuter := bvNone;
  PanelModes.ParentBackground := False;

  PanelScientific := TPanel.Create(PanelModes);
  PanelScientific.Parent := PanelModes;
  PanelScientific.Align := alClient;
  PanelScientific.BevelOuter := bvNone;
  PanelScientific.ParentBackground := False;

  PanelRPN := TPanel.Create(PanelModes);
  PanelRPN.Parent := PanelModes;
  PanelRPN.Align := alClient;
  PanelRPN.BevelOuter := bvNone;
  PanelRPN.ParentBackground := False;

  PanelProgrammer := TPanel.Create(PanelModes);
  PanelProgrammer.Parent := PanelModes;
  PanelProgrammer.Align := alClient;
  PanelProgrammer.BevelOuter := bvNone;
  PanelProgrammer.ParentBackground := False;

  PanelConverter := TPanel.Create(PanelModes);
  PanelConverter.Parent := PanelModes;
  PanelConverter.Align := alClient;
  PanelConverter.BevelOuter := bvNone;
  PanelConverter.ParentBackground := False;

  PanelTape := TPanel.Create(PanelModes);
  PanelTape.Parent := PanelModes;
  PanelTape.Align := alClient;
  PanelTape.BevelOuter := bvNone;
  PanelTape.ParentBackground := False;

  // 构建各个页面的按键与布局
  BuildScientificTab;
  BuildRPNTab;
  BuildProgrammerTab;
  BuildConverterTab;
  BuildTapeTab;

  // 刷新模式与主题
  SetMode(cmAlgebraic);
  RefreshTheme;
  UpdateDisplays;

  FIsInitialized := True;
  FormResize(nil);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAlgEngine);
  FreeAndNil(FRPNEngine);
  FreeAndNil(FProgEngine);
  FreeAndNil(FTapeList);
end;

{ 响应式动态重排主入口 }
procedure TForm1.FormResize(Sender: TObject);
begin
  if not FIsInitialized then Exit;

  LayoutTopBar;
  LayoutDisplayArea;
  LayoutScientificTab;
  LayoutRPNTab;
  LayoutProgrammerTab;
  LayoutConverterTab;
  LayoutTapeTab;
end;

{ 构建顶部工具栏 }
procedure TForm1.BuildTopBar;
begin
  PanelTopBar := TPanel.Create(Self);
  PanelTopBar.Parent := Self;
  PanelTopBar.Align := alTop;
  PanelTopBar.Height := 46;
  PanelTopBar.BevelOuter := bvNone;

  // 模式切换按钮
  BtnModeAlg := TCalcButton.Create(PanelTopBar);
  BtnModeAlg.Parent := PanelTopBar;
  BtnModeAlg.Caption := '🔬 科学';
  BtnModeAlg.Role := cbrNavigation;
  BtnModeAlg.IsDown := True;
  BtnModeAlg.CornerRadius := 6;
  BtnModeAlg.OnClick := @OnModeBtnClick;

  BtnModeRPN := TCalcButton.Create(PanelTopBar);
  BtnModeRPN.Parent := PanelTopBar;
  BtnModeRPN.Caption := '🥞 RPN';
  BtnModeRPN.Role := cbrNavigation;
  BtnModeRPN.CornerRadius := 6;
  BtnModeRPN.OnClick := @OnModeBtnClick;

  BtnModeProg := TCalcButton.Create(PanelTopBar);
  BtnModeProg.Parent := PanelTopBar;
  BtnModeProg.Caption := '💻 程序员';
  BtnModeProg.Role := cbrNavigation;
  BtnModeProg.CornerRadius := 6;
  BtnModeProg.OnClick := @OnModeBtnClick;

  BtnModeConv := TCalcButton.Create(PanelTopBar);
  BtnModeConv.Parent := PanelTopBar;
  BtnModeConv.Caption := '📐 换算';
  BtnModeConv.Role := cbrNavigation;
  BtnModeConv.CornerRadius := 6;
  BtnModeConv.OnClick := @OnModeBtnClick;

  BtnModeTape := TCalcButton.Create(PanelTopBar);
  BtnModeTape.Parent := PanelTopBar;
  BtnModeTape.Caption := '📜 纸带';
  BtnModeTape.Role := cbrNavigation;
  BtnModeTape.CornerRadius := 6;
  BtnModeTape.OnClick := @OnModeBtnClick;

  // 右侧辅助开关
  BtnAngle := TCalcButton.Create(PanelTopBar);
  BtnAngle.Parent := PanelTopBar;
  BtnAngle.Caption := 'DEG';
  BtnAngle.Role := cbrFunction;
  BtnAngle.CornerRadius := 6;
  BtnAngle.OnClick := @OnAngleBtnClick;

  BtnTopMost := TCalcButton.Create(PanelTopBar);
  BtnTopMost.Parent := PanelTopBar;
  BtnTopMost.Caption := '📌';
  BtnTopMost.Role := cbrFunction;
  BtnTopMost.Hint := '窗口置顶';
  BtnTopMost.ShowHint := True;
  BtnTopMost.CornerRadius := 6;
  BtnTopMost.OnClick := @OnTopMostBtnClick;

  BtnTheme := TCalcButton.Create(PanelTopBar);
  BtnTheme.Parent := PanelTopBar;
  BtnTheme.Caption := '🌙';
  BtnTheme.Role := cbrFunction;
  BtnTheme.Hint := '切换主题风格';
  BtnTheme.ShowHint := True;
  BtnTheme.CornerRadius := 6;
  BtnTheme.OnClick := @OnThemeBtnClick;
end;

{ 布局顶部工具栏 }
procedure TForm1.LayoutTopBar;
var
  RightEdge, ModeAvailW, ModeBtnW, Gap, RightW: Integer;
  ThemeBtnW, PinBtnW, AngleBtnW, BtnFontSize: Integer;
begin
  if not Assigned(PanelTopBar) then Exit;
  Gap := 4;
  RightEdge := PanelTopBar.ClientWidth - 8;
  ThemeBtnW := 72;
  PinBtnW := 34;
  AngleBtnW := 48;

  // 右侧辅助按钮靠右：主题按钮赋予 72px 宽度，彻底解决 "🌙 黑" / "☀️ 白" / "🌾 浅黄" 文本截断问题
  BtnTheme.SetBounds(RightEdge - ThemeBtnW, 6, ThemeBtnW, 34);
  BtnTopMost.SetBounds(RightEdge - ThemeBtnW - Gap - PinBtnW, 6, PinBtnW, 34);

  if BtnAngle.Visible then
  begin
    BtnAngle.SetBounds(RightEdge - ThemeBtnW - Gap - PinBtnW - Gap - AngleBtnW, 6, AngleBtnW, 34);
    RightW := ThemeBtnW + Gap + PinBtnW + Gap + AngleBtnW;
  end
  else
    RightW := ThemeBtnW + Gap + PinBtnW;

  // 左侧 5 个模式切换按钮自适应平分剩余空间，决不越界与右侧重叠
  ModeAvailW := (RightEdge - RightW - Gap) - 8;
  ModeBtnW := Min(125, Max(38, (ModeAvailW - 4 * Gap) div 5));
  BtnFontSize := Min(11, Max(9, ModeBtnW div 11));

  BtnModeAlg.SetBounds(8 + 0 * (ModeBtnW + Gap), 6, ModeBtnW, 34);
  BtnModeRPN.SetBounds(8 + 1 * (ModeBtnW + Gap), 6, ModeBtnW, 34);
  BtnModeProg.SetBounds(8 + 2 * (ModeBtnW + Gap), 6, ModeBtnW, 34);
  BtnModeConv.SetBounds(8 + 3 * (ModeBtnW + Gap), 6, ModeBtnW, 34);
  BtnModeTape.SetBounds(8 + 4 * (ModeBtnW + Gap), 6, ModeBtnW, 34);

  BtnModeAlg.Font.Size := BtnFontSize;
  BtnModeRPN.Font.Size := BtnFontSize;
  BtnModeProg.Font.Size := BtnFontSize;
  BtnModeConv.Font.Size := BtnFontSize;
  BtnModeTape.Font.Size := BtnFontSize;
end;

{ 构建显示屏区域 }
procedure TForm1.BuildDisplayArea;
begin
  PanelDisplay := TPanel.Create(Self);
  PanelDisplay.Parent := Self;
  PanelDisplay.Align := alTop;
  PanelDisplay.Height := 90;
  PanelDisplay.BevelOuter := bvNone;

  LabelExpr := TLabel.Create(PanelDisplay);
  LabelExpr.Parent := PanelDisplay;
  LabelExpr.Alignment := taRightJustify;
  LabelExpr.AutoSize := False;
  LabelExpr.Font.Size := 10;
  LabelExpr.Caption := '';

  LabelMem := TLabel.Create(PanelDisplay);
  LabelMem.Parent := PanelDisplay;
  LabelMem.Font.Size := 10;
  LabelMem.Font.Style := [fsBold];
  LabelMem.Caption := '';

  EditMainDisplay := TEdit.Create(PanelDisplay);
  EditMainDisplay.Parent := PanelDisplay;
  EditMainDisplay.Alignment := taRightJustify;
  EditMainDisplay.BorderStyle := bsNone;
  EditMainDisplay.ReadOnly := True;
  EditMainDisplay.Font.Size := 26;
  EditMainDisplay.Font.Style := [fsBold];
  EditMainDisplay.Text := '0';

  // 程序员模式四进制同屏指示器
  PanelProgBases := TPanel.Create(Self);
  PanelProgBases.Parent := Self;
  PanelProgBases.Align := alTop;
  PanelProgBases.Height := 88;
  PanelProgBases.BevelOuter := bvNone;
  PanelProgBases.Visible := False;

  LabelHexBase := TLabel.Create(PanelProgBases);
  LabelHexBase.Parent := PanelProgBases;
  LabelHexBase.AutoSize := False;
  LabelHexBase.Font.Name := 'Consolas';
  LabelHexBase.Caption := 'HEX: 0000 0000 0000 0000';

  LabelDecBase := TLabel.Create(PanelProgBases);
  LabelDecBase.Parent := PanelProgBases;
  LabelDecBase.AutoSize := False;
  LabelDecBase.Font.Name := 'Consolas';
  LabelDecBase.Caption := 'DEC: 0';

  LabelOctBase := TLabel.Create(PanelProgBases);
  LabelOctBase.Parent := PanelProgBases;
  LabelOctBase.AutoSize := False;
  LabelOctBase.Font.Name := 'Consolas';
  LabelOctBase.Caption := 'OCT: 0';

  LabelBinBase := TLabel.Create(PanelProgBases);
  LabelBinBase.Parent := PanelProgBases;
  LabelBinBase.AutoSize := False;
  LabelBinBase.Font.Name := 'Consolas';
  LabelBinBase.Caption := 'BIN: 0000 0000 0000 0000';
end;

{ 布局显示区域 }
procedure TForm1.LayoutDisplayArea;
var
  DispW, DispH: Integer;
begin
  if not Assigned(PanelDisplay) then Exit;
  // 响应式自适应高度：根据窗体高度在 85~130 之间弹性扩展
  PanelDisplay.Height := Min(130, Max(85, ClientHeight div 7));
  DispW := PanelDisplay.ClientWidth - 32;
  DispH := PanelDisplay.ClientHeight;

  // 内存标记靠左，表达式靠右，二者水平并列决不重叠
  LabelMem.SetBounds(16, 6, 36, 20);
  LabelExpr.SetBounds(56, 6, DispW - 40, 22);
  LabelExpr.Font.Size := Min(13, Max(9, DispH div 8));

  EditMainDisplay.SetBounds(16, 28, DispW, DispH - 34);
  EditMainDisplay.Font.Size := Min(42, Max(22, (DispH - 34) * 5 div 9));

  if Assigned(PanelProgBases) and PanelProgBases.Visible then
  begin
    LabelHexBase.SetBounds(16, 4, PanelProgBases.ClientWidth - 32, 18);
    LabelDecBase.SetBounds(16, 24, PanelProgBases.ClientWidth - 32, 18);
    LabelOctBase.SetBounds(16, 44, PanelProgBases.ClientWidth - 32, 18);
    LabelBinBase.SetBounds(16, 64, PanelProgBases.ClientWidth - 32, 18);
  end;
end;

{ 构建科学模式键盘 (7 列 x 7 行) }
procedure TForm1.BuildScientificTab;
var
  Btn: TCalcButton;
begin
  // 第 0 行：括号与内存
  SetLength(FScientificRows[0], 7);
  FScientificRows[0][0] := CreateCalcBtn(PanelScientific, '(', @OnAlgParenOpenClick, 0, cbrFunction);
  FScientificRows[0][1] := CreateCalcBtn(PanelScientific, ')', @OnAlgParenCloseClick, 0, cbrFunction);
  FScientificRows[0][2] := CreateCalcBtn(PanelScientific, 'MC', @OnAlgMemoryClick, 1, cbrFunction);
  FScientificRows[0][3] := CreateCalcBtn(PanelScientific, 'MR', @OnAlgMemoryClick, 2, cbrFunction);
  FScientificRows[0][4] := CreateCalcBtn(PanelScientific, 'MS', @OnAlgMemoryClick, 3, cbrFunction);
  FScientificRows[0][5] := CreateCalcBtn(PanelScientific, 'M+', @OnAlgMemoryClick, 4, cbrFunction);
  FScientificRows[0][6] := CreateCalcBtn(PanelScientific, 'M-', @OnAlgMemoryClick, 5, cbrFunction);

  // 第 1 行：2nd、三角函数、常数与 AC
  SetLength(FScientificRows[1], 7);
  Btn2nd := CreateCalcBtn(PanelScientific, '2nd', @OnAlg2ndClick, 0, cbrFunction);
  FScientificRows[1][0] := Btn2nd;
  BtnSin := CreateCalcBtn(PanelScientific, 'sin', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[1][1] := BtnSin;
  BtnCos := CreateCalcBtn(PanelScientific, 'cos', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[1][2] := BtnCos;
  BtnTan := CreateCalcBtn(PanelScientific, 'tan', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[1][3] := BtnTan;
  FScientificRows[1][4] := CreateCalcBtn(PanelScientific, 'π', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[1][5] := CreateCalcBtn(PanelScientific, 'e', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[1][6] := CreateCalcBtn(PanelScientific, 'AC', @OnAlgClearClick, 0, cbrUtility);

  // 第 2 行：幂次、对数与除法
  SetLength(FScientificRows[2], 7);
  BtnXSq := CreateCalcBtn(PanelScientific, 'x²', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[2][0] := BtnXSq;
  FScientificRows[2][1] := CreateCalcBtn(PanelScientific, 'xʸ', @OnAlgOpClick, 0, cbrOperator);
  BtnSqrt := CreateCalcBtn(PanelScientific, '√x', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[2][2] := BtnSqrt;
  FScientificRows[2][3] := CreateCalcBtn(PanelScientific, '1/x', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[2][4] := CreateCalcBtn(PanelScientific, 'log', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[2][5] := CreateCalcBtn(PanelScientific, 'ln', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[2][6] := CreateCalcBtn(PanelScientific, '÷', @OnAlgOpClick, 0, cbrOperator);

  // 第 3 行：双曲函数与数字 7, 8, 9, 乘法
  SetLength(FScientificRows[3], 7);
  BtnSinh := CreateCalcBtn(PanelScientific, 'sinh', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[3][0] := BtnSinh;
  BtnCosh := CreateCalcBtn(PanelScientific, 'cosh', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[3][1] := BtnCosh;
  BtnTanh := CreateCalcBtn(PanelScientific, 'tanh', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[3][2] := BtnTanh;
  FScientificRows[3][3] := CreateCalcBtn(PanelScientific, '7', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[3][4] := CreateCalcBtn(PanelScientific, '8', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[3][5] := CreateCalcBtn(PanelScientific, '9', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[3][6] := CreateCalcBtn(PanelScientific, '×', @OnAlgOpClick, 0, cbrOperator);

  // 第 4 行：阶乘、绝对值、立方与数字 4, 5, 6, 减法
  SetLength(FScientificRows[4], 7);
  FScientificRows[4][0] := CreateCalcBtn(PanelScientific, 'n!', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[4][1] := CreateCalcBtn(PanelScientific, '|x|', @OnAlgUnaryClick, 0, cbrFunction);
  BtnCube := CreateCalcBtn(PanelScientific, 'x³', @OnAlgUnaryClick, 0, cbrFunction);
  FScientificRows[4][2] := BtnCube;
  FScientificRows[4][3] := CreateCalcBtn(PanelScientific, '4', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[4][4] := CreateCalcBtn(PanelScientific, '5', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[4][5] := CreateCalcBtn(PanelScientific, '6', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[4][6] := CreateCalcBtn(PanelScientific, '-', @OnAlgOpClick, 0, cbrOperator);

  // 第 5 行：排列组合、MOD 与数字 1, 2, 3, 加法
  SetLength(FScientificRows[5], 7);
  FScientificRows[5][0] := CreateCalcBtn(PanelScientific, 'nPr', @OnAlgOpClick, 0, cbrOperator);
  FScientificRows[5][1] := CreateCalcBtn(PanelScientific, 'nCr', @OnAlgOpClick, 0, cbrOperator);
  FScientificRows[5][2] := CreateCalcBtn(PanelScientific, 'MOD', @OnAlgOpClick, 0, cbrOperator);
  FScientificRows[5][3] := CreateCalcBtn(PanelScientific, '1', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[5][4] := CreateCalcBtn(PanelScientific, '2', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[5][5] := CreateCalcBtn(PanelScientific, '3', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[5][6] := CreateCalcBtn(PanelScientific, '+', @OnAlgOpClick, 0, cbrOperator);

  // 第 6 行：正负、百分比、退格、0、点、等号 (等号跨 2 列)
  SetLength(FScientificRows[6], 6);
  FScientificRows[6][0] := CreateCalcBtn(PanelScientific, '+/-', @OnAlgSignClick, 0, cbrFunction);
  FScientificRows[6][1] := CreateCalcBtn(PanelScientific, '%', @OnAlgPercentClick, 0, cbrFunction);
  FScientificRows[6][2] := CreateCalcBtn(PanelScientific, '⌫', @OnAlgBackClick, 0, cbrUtility);
  FScientificRows[6][3] := CreateCalcBtn(PanelScientific, '0', @OnAlgNumClick, 0, cbrNumber);
  FScientificRows[6][4] := CreateCalcBtn(PanelScientific, '.', @OnAlgDotClick, 0, cbrNumber);
  Btn := CreateCalcBtn(PanelScientific, '=', @OnAlgEqualsClick, 0, cbrPrimary);
  FScientificRows[6][5] := Btn;
end;

{ 布局科学模式键盘 }
procedure TForm1.LayoutScientificTab;
const
  PadX = 6;
  PadY = 6;
var
  AvailW, AvailH, ColW, RowH, r, c: Integer;
  BtnFontSize, CurFontSize: Integer;
  Btn: TCalcButton;
begin
  if not Assigned(PanelScientific) then Exit;
  AvailW := PanelScientific.ClientWidth - 20;
  AvailH := PanelScientific.ClientHeight - 20;
  if (AvailW < 100) or (AvailH < 100) then Exit;

  ColW := (AvailW - 6 * PadX) div 7;
  RowH := (AvailH - 6 * PadY) div 7;
  BtnFontSize := Max(10, Min(22, RowH div 3));

  for r := 0 to 6 do
  begin
    for c := 0 to High(FScientificRows[r]) do
    begin
      Btn := FScientificRows[r][c];
      if not Assigned(Btn) then Continue;

      if (r = 6) and (c = 5) then
        Btn.SetBounds(10 + c * (ColW + PadX), 10 + r * (RowH + PadY), ColW * 2 + PadX, RowH)
      else
        Btn.SetBounds(10 + c * (ColW + PadX), 10 + r * (RowH + PadY), ColW, RowH);

      CurFontSize := BtnFontSize;
      if Length(Btn.Caption) >= 4 then
        CurFontSize := Max(9, BtnFontSize - 3)
      else if Length(Btn.Caption) = 3 then
        CurFontSize := Max(9, BtnFontSize - 2);

      Btn.Font.Size := CurFontSize;
      if Btn.Role in [cbrNumber, cbrOperator, cbrPrimary] then
        Btn.Font.Style := [fsBold]
      else
        Btn.Font.Style := [];
    end;
  end;
end;

{ 构建 RPN 模式界面 }
procedure TForm1.BuildRPNTab;
var
  Btn: TCalcButton;
begin
  // 上部堆栈显示视图
  PanelRPNStack := TPanel.Create(PanelRPN);
  PanelRPNStack.Parent := PanelRPN;
  PanelRPNStack.BevelOuter := bvNone;

  LabelStackT := TLabel.Create(PanelRPNStack);
  LabelStackT.Parent := PanelRPNStack;
  LabelStackT.Font.Name := 'Consolas';
  LabelStackT.Caption := 'T: 0';

  LabelStackZ := TLabel.Create(PanelRPNStack);
  LabelStackZ.Parent := PanelRPNStack;
  LabelStackZ.Font.Name := 'Consolas';
  LabelStackZ.Caption := 'Z: 0';

  LabelStackY := TLabel.Create(PanelRPNStack);
  LabelStackY.Parent := PanelRPNStack;
  LabelStackY.Font.Name := 'Consolas';
  LabelStackY.Caption := 'Y: 0';

  LabelStackX := TLabel.Create(PanelRPNStack);
  LabelStackX.Parent := PanelRPNStack;
  LabelStackX.Font.Name := 'Consolas';
  LabelStackX.Font.Style := [fsBold];
  LabelStackX.Caption := 'X: 0';

  // 下部按键：6 行 x 6 列
  // 第 0 行：ENTER(跨2列), DROP, x<>y, R↓, CLEAR
  SetLength(FRPNRows[0], 5);
  FRPNRows[0][0] := CreateCalcBtn(PanelRPN, 'ENTER', @OnRPNEnterClick);
  FRPNRows[0][1] := CreateCalcBtn(PanelRPN, 'DROP', @OnRPNDropClick);
  FRPNRows[0][2] := CreateCalcBtn(PanelRPN, 'x<>y', @OnRPNSwapClick);
  FRPNRows[0][3] := CreateCalcBtn(PanelRPN, 'R↓', @OnRPNRollDownClick);
  FRPNRows[0][4] := CreateCalcBtn(PanelRPN, 'CLEAR', @OnRPNClearClick);

  // 第 1 行：sin, cos, tan, xʸ, √x, 1/x
  SetLength(FRPNRows[1], 6);
  FRPNRows[1][0] := CreateCalcBtn(PanelRPN, 'sin', @OnRPNUnaryClick);
  FRPNRows[1][1] := CreateCalcBtn(PanelRPN, 'cos', @OnRPNUnaryClick);
  FRPNRows[1][2] := CreateCalcBtn(PanelRPN, 'tan', @OnRPNUnaryClick);
  FRPNRows[1][3] := CreateCalcBtn(PanelRPN, 'xʸ', @OnRPNOpClick);
  FRPNRows[1][4] := CreateCalcBtn(PanelRPN, '√x', @OnRPNUnaryClick);
  FRPNRows[1][5] := CreateCalcBtn(PanelRPN, '1/x', @OnRPNUnaryClick);

  // 第 2 行：log, ln, 7, 8, 9, ÷
  SetLength(FRPNRows[2], 6);
  FRPNRows[2][0] := CreateCalcBtn(PanelRPN, 'log', @OnRPNUnaryClick);
  FRPNRows[2][1] := CreateCalcBtn(PanelRPN, 'ln', @OnRPNUnaryClick);
  FRPNRows[2][2] := CreateCalcBtn(PanelRPN, '7', @OnRPNNumClick);
  FRPNRows[2][3] := CreateCalcBtn(PanelRPN, '8', @OnRPNNumClick);
  FRPNRows[2][4] := CreateCalcBtn(PanelRPN, '9', @OnRPNNumClick);
  FRPNRows[2][5] := CreateCalcBtn(PanelRPN, '÷', @OnRPNOpClick);

  // 第 3 行：x², n!, 4, 5, 6, ×
  SetLength(FRPNRows[3], 6);
  FRPNRows[3][0] := CreateCalcBtn(PanelRPN, 'x²', @OnRPNUnaryClick);
  FRPNRows[3][1] := CreateCalcBtn(PanelRPN, 'n!', @OnRPNUnaryClick);
  FRPNRows[3][2] := CreateCalcBtn(PanelRPN, '4', @OnRPNNumClick);
  FRPNRows[3][3] := CreateCalcBtn(PanelRPN, '5', @OnRPNNumClick);
  FRPNRows[3][4] := CreateCalcBtn(PanelRPN, '6', @OnRPNNumClick);
  FRPNRows[3][5] := CreateCalcBtn(PanelRPN, '×', @OnRPNOpClick);

  // 第 4 行：π, e, 1, 2, 3, -
  SetLength(FRPNRows[4], 6);
  FRPNRows[4][0] := CreateCalcBtn(PanelRPN, 'π', @OnRPNUnaryClick);
  FRPNRows[4][1] := CreateCalcBtn(PanelRPN, 'e', @OnRPNUnaryClick);
  FRPNRows[4][2] := CreateCalcBtn(PanelRPN, '1', @OnRPNNumClick);
  FRPNRows[4][3] := CreateCalcBtn(PanelRPN, '2', @OnRPNNumClick);
  FRPNRows[4][4] := CreateCalcBtn(PanelRPN, '3', @OnRPNNumClick);
  FRPNRows[4][5] := CreateCalcBtn(PanelRPN, '-', @OnRPNOpClick);

  // 第 5 行：+/-, ⌫, 0, ., + (+ 跨两列)
  SetLength(FRPNRows[5], 5);
  FRPNRows[5][0] := CreateCalcBtn(PanelRPN, '+/-', @OnRPNUnaryClick);
  FRPNRows[5][1] := CreateCalcBtn(PanelRPN, '⌫', @OnRPNClearClick, 1);
  FRPNRows[5][2] := CreateCalcBtn(PanelRPN, '0', @OnRPNNumClick);
  FRPNRows[5][3] := CreateCalcBtn(PanelRPN, '.', @OnRPNNumClick);
  Btn := CreateCalcBtn(PanelRPN, '+', @OnRPNOpClick);
  FRPNRows[5][4] := Btn;
end;

{ 布局 RPN 模式界面 }
procedure TForm1.LayoutRPNTab;
const
  PadX = 6;
  PadY = 6;
var
  StackH, LblH, AvailW, AvailH, ColW, RowH, r, c: Integer;
  BtnFontSize, CurFontSize: Integer;
  Btn: TCalcButton;
begin
  if not Assigned(PanelRPN) or not Assigned(PanelRPNStack) then Exit;
  StackH := Min(150, Max(85, PanelRPN.ClientHeight div 6));
  PanelRPNStack.SetBounds(10, 8, PanelRPN.ClientWidth - 20, StackH);

  LblH := (StackH - 8) div 4;
  LabelStackT.SetBounds(14, 4 + 0 * LblH, PanelRPNStack.ClientWidth - 28, LblH);
  LabelStackZ.SetBounds(14, 4 + 1 * LblH, PanelRPNStack.ClientWidth - 28, LblH);
  LabelStackY.SetBounds(14, 4 + 2 * LblH, PanelRPNStack.ClientWidth - 28, LblH);
  LabelStackX.SetBounds(14, 4 + 3 * LblH, PanelRPNStack.ClientWidth - 28, LblH);

  LabelStackT.Font.Size := Min(13, Max(9, LblH div 2));
  LabelStackZ.Font.Size := Min(13, Max(9, LblH div 2));
  LabelStackY.Font.Size := Min(13, Max(9, LblH div 2));
  LabelStackX.Font.Size := Min(14, Max(9, LblH div 2));

  AvailW := PanelRPN.ClientWidth - 20;
  AvailH := PanelRPN.ClientHeight - (StackH + 16) - 10;
  if (AvailW < 100) or (AvailH < 100) then Exit;

  ColW := (AvailW - 5 * PadX) div 6;
  RowH := (AvailH - 5 * PadY) div 6;
  BtnFontSize := Max(10, Min(22, RowH div 3));

  for r := 0 to 5 do
  begin
    for c := 0 to High(FRPNRows[r]) do
    begin
      Btn := FRPNRows[r][c];
      if not Assigned(Btn) then Continue;

      if (r = 0) and (c = 0) then
        Btn.SetBounds(10 + 0 * (ColW + PadX), StackH + 16 + r * (RowH + PadY), ColW * 2 + PadX, RowH)
      else if (r = 0) and (c > 0) then
        Btn.SetBounds(10 + (c + 1) * (ColW + PadX), StackH + 16 + r * (RowH + PadY), ColW, RowH)
      else if (r = 5) and (c = 4) then
        Btn.SetBounds(10 + c * (ColW + PadX), StackH + 16 + r * (RowH + PadY), ColW * 2 + PadX, RowH)
      else
        Btn.SetBounds(10 + c * (ColW + PadX), StackH + 16 + r * (RowH + PadY), ColW, RowH);

      CurFontSize := BtnFontSize;
      if Length(Btn.Caption) >= 4 then
        CurFontSize := Max(9, BtnFontSize - 3)
      else if Length(Btn.Caption) = 3 then
        CurFontSize := Max(9, BtnFontSize - 2);

      Btn.Font.Size := CurFontSize;
      Btn.Font.Style := [fsBold];
    end;
  end;
end;

{ 构建程序员模式界面 }
procedure TForm1.BuildProgrammerTab;
var
  i, bitIdx: Integer;
  Btn: TCalcButton;
begin
  // 顶部字长与进制切换条
  BtnRadixHex := TCalcButton.Create(PanelProgrammer);
  BtnRadixHex.Parent := PanelProgrammer;
  BtnRadixHex.Caption := 'HEX';
  BtnRadixHex.CornerRadius := 4;
  BtnRadixHex.OnClick := @OnProgRadixClick;

  BtnRadixDec := TCalcButton.Create(PanelProgrammer);
  BtnRadixDec.Parent := PanelProgrammer;
  BtnRadixDec.Caption := 'DEC';
  BtnRadixDec.CornerRadius := 4;
  BtnRadixDec.IsDown := True;
  BtnRadixDec.OnClick := @OnProgRadixClick;

  BtnRadixOct := TCalcButton.Create(PanelProgrammer);
  BtnRadixOct.Parent := PanelProgrammer;
  BtnRadixOct.Caption := 'OCT';
  BtnRadixOct.CornerRadius := 4;
  BtnRadixOct.OnClick := @OnProgRadixClick;

  BtnRadixBin := TCalcButton.Create(PanelProgrammer);
  BtnRadixBin.Parent := PanelProgrammer;
  BtnRadixBin.Caption := 'BIN';
  BtnRadixBin.CornerRadius := 4;
  BtnRadixBin.OnClick := @OnProgRadixClick;

  BtnWordSize := TCalcButton.Create(PanelProgrammer);
  BtnWordSize.Parent := PanelProgrammer;
  BtnWordSize.Caption := '64-bit (QWORD)';
  BtnWordSize.CornerRadius := 4;
  BtnWordSize.OnClick := @OnProgWordSizeClick;

  BtnSigned := TCalcButton.Create(PanelProgrammer);
  BtnSigned.Parent := PanelProgrammer;
  BtnSigned.Caption := 'Unsigned';
  BtnSigned.CornerRadius := 4;
  BtnSigned.OnClick := @OnProgSignedClick;

  // 64 位交互式二进制位翻转网格 (4 行 x 16 列)
  FPanelBits := TPanel.Create(PanelProgrammer);
  FPanelBits.Parent := PanelProgrammer;
  FPanelBits.BevelOuter := bvNone;

  for i := 0 to 63 do
  begin
    bitIdx := 63 - i;
    BitButtons[bitIdx] := TCalcButton.Create(FPanelBits);
    BitButtons[bitIdx].Parent := FPanelBits;
    BitButtons[bitIdx].Caption := '0';
    BitButtons[bitIdx].Tag := bitIdx;
    BitButtons[bitIdx].CornerRadius := 2;
    BitButtons[bitIdx].Font.Name := 'Consolas';
    BitButtons[bitIdx].Font.Size := 9;
    BitButtons[bitIdx].OnClick := @OnProgBitClick;
  end;

  // 程序员操作按键 (6 行 x 6 列)
  // 第 0 行：AND, OR, XOR, NOT, CE, AC
  SetLength(FProgRows[0], 6);
  FProgRows[0][0] := CreateCalcBtn(PanelProgrammer, 'AND', @OnProgOpClick);
  FProgRows[0][1] := CreateCalcBtn(PanelProgrammer, 'OR', @OnProgOpClick);
  FProgRows[0][2] := CreateCalcBtn(PanelProgrammer, 'XOR', @OnProgOpClick);
  FProgRows[0][3] := CreateCalcBtn(PanelProgrammer, 'NOT', @OnProgNotClick);
  FProgRows[0][4] := CreateCalcBtn(PanelProgrammer, 'CE', @OnProgClearClick);
  FProgRows[0][5] := CreateCalcBtn(PanelProgrammer, 'AC', @OnProgClearClick, 1);

  // 第 1 行：Lsh, Rsh, RoL, RoR, A, B
  SetLength(FProgRows[1], 6);
  FProgRows[1][0] := CreateCalcBtn(PanelProgrammer, 'Lsh', @OnProgOpClick);
  FProgRows[1][1] := CreateCalcBtn(PanelProgrammer, 'Rsh', @OnProgOpClick);
  FProgRows[1][2] := CreateCalcBtn(PanelProgrammer, 'RoL', @OnProgOpClick);
  FProgRows[1][3] := CreateCalcBtn(PanelProgrammer, 'RoR', @OnProgOpClick);
  HexButtons['A'] := CreateCalcBtn(PanelProgrammer, 'A', @OnProgDigitClick);
  FProgRows[1][4] := HexButtons['A'];
  HexButtons['B'] := CreateCalcBtn(PanelProgrammer, 'B', @OnProgDigitClick);
  FProgRows[1][5] := HexButtons['B'];

  // 第 2 行：NAND, NOR, 7, 8, 9, C
  SetLength(FProgRows[2], 6);
  FProgRows[2][0] := CreateCalcBtn(PanelProgrammer, 'NAND', @OnProgOpClick);
  FProgRows[2][1] := CreateCalcBtn(PanelProgrammer, 'NOR', @OnProgOpClick);
  DigitButtons['7'] := CreateCalcBtn(PanelProgrammer, '7', @OnProgDigitClick);
  FProgRows[2][2] := DigitButtons['7'];
  DigitButtons['8'] := CreateCalcBtn(PanelProgrammer, '8', @OnProgDigitClick);
  FProgRows[2][3] := DigitButtons['8'];
  DigitButtons['9'] := CreateCalcBtn(PanelProgrammer, '9', @OnProgDigitClick);
  FProgRows[2][4] := DigitButtons['9'];
  HexButtons['C'] := CreateCalcBtn(PanelProgrammer, 'C', @OnProgDigitClick);
  FProgRows[2][5] := HexButtons['C'];

  // 第 3 行：XNOR, MOD, 4, 5, 6, D
  SetLength(FProgRows[3], 6);
  FProgRows[3][0] := CreateCalcBtn(PanelProgrammer, 'XNOR', @OnProgOpClick);
  FProgRows[3][1] := CreateCalcBtn(PanelProgrammer, 'MOD', @OnProgOpClick);
  DigitButtons['4'] := CreateCalcBtn(PanelProgrammer, '4', @OnProgDigitClick);
  FProgRows[3][2] := DigitButtons['4'];
  DigitButtons['5'] := CreateCalcBtn(PanelProgrammer, '5', @OnProgDigitClick);
  FProgRows[3][3] := DigitButtons['5'];
  DigitButtons['6'] := CreateCalcBtn(PanelProgrammer, '6', @OnProgDigitClick);
  FProgRows[3][4] := DigitButtons['6'];
  HexButtons['D'] := CreateCalcBtn(PanelProgrammer, 'D', @OnProgDigitClick);
  FProgRows[3][5] := HexButtons['D'];

  // 第 4 行：÷, ×, 1, 2, 3, E
  SetLength(FProgRows[4], 6);
  FProgRows[4][0] := CreateCalcBtn(PanelProgrammer, '÷', @OnProgOpClick);
  FProgRows[4][1] := CreateCalcBtn(PanelProgrammer, '×', @OnProgOpClick);
  DigitButtons['1'] := CreateCalcBtn(PanelProgrammer, '1', @OnProgDigitClick);
  FProgRows[4][2] := DigitButtons['1'];
  DigitButtons['2'] := CreateCalcBtn(PanelProgrammer, '2', @OnProgDigitClick);
  FProgRows[4][3] := DigitButtons['2'];
  DigitButtons['3'] := CreateCalcBtn(PanelProgrammer, '3', @OnProgDigitClick);
  FProgRows[4][4] := DigitButtons['3'];
  HexButtons['E'] := CreateCalcBtn(PanelProgrammer, 'E', @OnProgDigitClick);
  FProgRows[4][5] := HexButtons['E'];

  // 第 5 行：-, +, 0, ⌫, F, =
  SetLength(FProgRows[5], 6);
  FProgRows[5][0] := CreateCalcBtn(PanelProgrammer, '-', @OnProgOpClick);
  FProgRows[5][1] := CreateCalcBtn(PanelProgrammer, '+', @OnProgOpClick);
  DigitButtons['0'] := CreateCalcBtn(PanelProgrammer, '0', @OnProgDigitClick);
  FProgRows[5][2] := DigitButtons['0'];
  FProgRows[5][3] := CreateCalcBtn(PanelProgrammer, '⌫', @OnProgBackClick);
  HexButtons['F'] := CreateCalcBtn(PanelProgrammer, 'F', @OnProgDigitClick);
  FProgRows[5][4] := HexButtons['F'];
  Btn := CreateCalcBtn(PanelProgrammer, '=', @OnProgEqualsClick);
  Btn.Font.Style := [fsBold];
  FProgRows[5][5] := Btn;
end;

{ 布局程序员模式界面 }
procedure TForm1.LayoutProgrammerTab;
const
  PadX = 6;
  PadY = 6;
var
  AvailW, AvailH, ColW, RowH, r, c, i, bitIdx: Integer;
  BitColW, BitRowH, BtnFontSize, CurFontSize: Integer;
  Btn: TCalcButton;
  RadixW, Gap, StartX, WordW: Integer;
  BitsH, KeypadTop: Integer;
begin
  if not Assigned(PanelProgrammer) or not Assigned(FPanelBits) then Exit;
  AvailW := PanelProgrammer.ClientWidth - 20;

  // 顶部进制与字长栏自适应：比例均衡排布，杜绝溢出或畸形拉伸
  Gap := 4;
  if AvailW < 480 then
  begin
    RadixW := 44;
    BtnRadixHex.SetBounds(10, 8, RadixW, 32);
    BtnRadixDec.SetBounds(10 + 1 * (RadixW + Gap), 8, RadixW, 32);
    BtnRadixOct.SetBounds(10 + 2 * (RadixW + Gap), 8, RadixW, 32);
    BtnRadixBin.SetBounds(10 + 3 * (RadixW + Gap), 8, RadixW, 32);

    StartX := 10 + 4 * (RadixW + Gap) + 2;
    WordW := (AvailW - (StartX - 10) - Gap) div 2;
    BtnWordSize.SetBounds(StartX, 8, WordW, 32);
    BtnSigned.SetBounds(StartX + WordW + Gap, 8, AvailW - (StartX - 10) - WordW - Gap, 32);
  end
  else
  begin
    RadixW := Min(70, (AvailW - 220) div 4);
    BtnRadixHex.SetBounds(10, 8, RadixW, 32);
    BtnRadixDec.SetBounds(10 + 1 * (RadixW + Gap), 8, RadixW, 32);
    BtnRadixOct.SetBounds(10 + 2 * (RadixW + Gap), 8, RadixW, 32);
    BtnRadixBin.SetBounds(10 + 3 * (RadixW + Gap), 8, RadixW, 32);

    StartX := 10 + 4 * (RadixW + Gap) + 6;
    WordW := Min(130, (AvailW - (StartX - 10) - Gap) div 2);
    BtnWordSize.SetBounds(StartX, 8, WordW, 32);
    BtnSigned.SetBounds(StartX + WordW + Gap, 8, WordW, 32);
  end;

  // 64 位比特矩阵自适应
  BitsH := Min(120, Max(86, PanelProgrammer.ClientHeight div 7));
  FPanelBits.SetBounds(10, 46, AvailW, BitsH);
  BitColW := (FPanelBits.ClientWidth - 10) div 16;
  BitRowH := (FPanelBits.ClientHeight - 8) div 4;

  for i := 0 to 63 do
  begin
    bitIdx := 63 - i;
    r := i div 16;
    c := i mod 16;
    if Assigned(BitButtons[bitIdx]) then
      BitButtons[bitIdx].SetBounds(c * BitColW + (c div 4) * 2 + 2, r * BitRowH + 2, Max(16, BitColW - 3), Max(14, BitRowH - 3));
  end;

  // 键盘自适应
  KeypadTop := 46 + BitsH + 8;
  AvailH := PanelProgrammer.ClientHeight - KeypadTop - 10;
  if (AvailW < 100) or (AvailH < 100) then Exit;

  ColW := (AvailW - 5 * PadX) div 6;
  RowH := (AvailH - 5 * PadY) div 6;
  BtnFontSize := Max(10, Min(22, RowH div 3));

  for r := 0 to 5 do
  begin
    for c := 0 to High(FProgRows[r]) do
    begin
      Btn := FProgRows[r][c];
      if not Assigned(Btn) then Continue;
      Btn.SetBounds(10 + c * (ColW + PadX), KeypadTop + r * (RowH + PadY), ColW, RowH);

      CurFontSize := BtnFontSize;
      if Length(Btn.Caption) >= 4 then
        CurFontSize := Max(9, BtnFontSize - 3)
      else if Length(Btn.Caption) = 3 then
        CurFontSize := Max(9, BtnFontSize - 2);

      Btn.Font.Size := CurFontSize;
      Btn.Font.Style := [fsBold];
    end;
  end;
end;

{ 构建单位换算与常数面板 }
procedure TForm1.BuildConverterTab;
var
  i: Integer;
begin
  LblCat := TLabel.Create(PanelConverter);
  LblCat.Parent := PanelConverter;
  LblCat.Caption := '换算类别:';

  ComboCat := TComboBox.Create(PanelConverter);
  ComboCat.Parent := PanelConverter;
  ComboCat.Style := csDropDownList;
  for i := 0 to GetCategoryCount - 1 do
    ComboCat.Items.Add(GetCategoryName(TUnitCategory(i)));
  ComboCat.ItemIndex := 0;
  ComboCat.OnChange := @OnConvCategoryChange;

  LblFrom := TLabel.Create(PanelConverter);
  LblFrom.Parent := PanelConverter;
  LblFrom.Caption := '源单位:';

  ComboFromUnit := TComboBox.Create(PanelConverter);
  ComboFromUnit.Parent := PanelConverter;
  ComboFromUnit.Style := csDropDownList;
  ComboFromUnit.OnChange := @OnConvFromChange;

  EditFromVal := TEdit.Create(PanelConverter);
  EditFromVal.Parent := PanelConverter;
  EditFromVal.Text := '1';
  EditFromVal.OnChange := @OnConvInputChange;

  BtnSwapUnits := CreateCalcBtn(PanelConverter, '⇄', @OnConvSwapClick);
  BtnSwapUnits.Parent := PanelConverter;
  BtnSwapUnits.Caption := '⇄';
  BtnSwapUnits.OnClick := @OnConvSwapClick;

  LblTo := TLabel.Create(PanelConverter);
  LblTo.Parent := PanelConverter;
  LblTo.Caption := '目标单位:';

  ComboToUnit := TComboBox.Create(PanelConverter);
  ComboToUnit.Parent := PanelConverter;
  ComboToUnit.Style := csDropDownList;
  ComboToUnit.OnChange := @OnConvToChange;

  EditToVal := TEdit.Create(PanelConverter);
  EditToVal.Parent := PanelConverter;
  EditToVal.ReadOnly := True;

  LblConst := TLabel.Create(PanelConverter);
  LblConst.Parent := PanelConverter;
  LblConst.Caption := '物理与数学常数库 (双击或点击代入):';

  ListConstants := TListBox.Create(PanelConverter);
  ListConstants.Parent := PanelConverter;
  ListConstants.Font.Name := 'Consolas';
  for i := 0 to GetConstantCount - 1 do
  begin
    ListConstants.Items.Add(Format('%-4s | %-28s = %g %s', [
      GetConstant(i).Symbol,
      GetConstant(i).Name,
      GetConstant(i).Value,
      GetConstant(i).UnitStr
    ]));
  end;
  ListConstants.ItemIndex := 0;

  BtnInsertConst := CreateCalcBtn(PanelConverter, '📥 将选中的常数代入当前计算器', @OnInsertConstantClick);
  BtnInsertConst.Parent := PanelConverter;
  BtnInsertConst.Caption := '📥 将选中的常数代入当前计算器';
  BtnInsertConst.OnClick := @OnInsertConstantClick;

  OnConvCategoryChange(nil);
end;

{ 布局单位换算面板 }
procedure TForm1.LayoutConverterTab;
var
  AvailW, LeftColW, RightColW, RightColX, FieldW: Integer;
  SwapLeft: Integer;
begin
  if not Assigned(PanelConverter) or not Assigned(ComboCat) then Exit;
  AvailW := PanelConverter.ClientWidth - 40;
  if AvailW < 100 then Exit;

  if PanelConverter.ClientWidth >= 680 then
  begin
    // 宽屏模式：左右双栏并列排版（左换算，右常数库，充分利用大屏空间）
    LeftColW := Min(440, (PanelConverter.ClientWidth - 60) div 2);
    RightColX := 20 + LeftColW + 20;
    RightColW := PanelConverter.ClientWidth - 20 - RightColX;

    // 左栏：单位换算区
    LblCat.SetBounds(20, 15, 80, 20);
    ComboCat.SetBounds(110, 12, LeftColW - 90, 28);

    FieldW := (LeftColW - 90 - 44) div 2;
    SwapLeft := 110 + 2 * FieldW + 8;

    LblFrom.SetBounds(20, 58, 80, 20);
    ComboFromUnit.SetBounds(110, 54, FieldW, 28);
    EditFromVal.SetBounds(110 + FieldW + 4, 54, FieldW, 28);
    BtnSwapUnits.SetBounds(SwapLeft, 54, 36, 70);

    LblTo.SetBounds(20, 98, 80, 20);
    ComboToUnit.SetBounds(110, 96, FieldW, 28);
    EditToVal.SetBounds(110 + FieldW + 4, 96, FieldW, 28);

    // 右栏：常数库
    LblConst.SetBounds(RightColX, 15, RightColW, 20);
    ListConstants.SetBounds(RightColX, 42, RightColW, Max(120, PanelConverter.ClientHeight - 42 - 50));
    BtnInsertConst.SetBounds(RightColX, PanelConverter.ClientHeight - 44, RightColW, 36);
  end
  else
  begin
    // 紧凑模式：单栏上下流式排版，各元素严格右对齐在 AvailW + 20 处，杜绝裁切溢出
    LblCat.SetBounds(20, 15, 80, 20);
    ComboCat.SetBounds(110, 12, AvailW - 90, 28);

    FieldW := (AvailW - 90 - 44) div 2;
    SwapLeft := 110 + 2 * FieldW + 8;

    LblFrom.SetBounds(20, 58, 80, 20);
    ComboFromUnit.SetBounds(110, 54, FieldW, 28);
    EditFromVal.SetBounds(110 + FieldW + 4, 54, FieldW, 28);
    BtnSwapUnits.SetBounds(SwapLeft, 54, 36, 70);

    LblTo.SetBounds(20, 98, 80, 20);
    ComboToUnit.SetBounds(110, 96, FieldW, 28);
    EditToVal.SetBounds(110 + FieldW + 4, 96, FieldW, 28);

    LblConst.SetBounds(20, 142, AvailW, 20);
    ListConstants.SetBounds(20, 168, AvailW, Max(100, PanelConverter.ClientHeight - 168 - 48));
    BtnInsertConst.SetBounds(20, PanelConverter.ClientHeight - 42, AvailW, 36);
  end;
end;

{ 构建仿真纸带历史面板 }
procedure TForm1.BuildTapeTab;
begin
  ListTape := TListBox.Create(PanelTape);
  ListTape.Parent := PanelTape;
  ListTape.Font.Name := 'Consolas';
  ListTape.Font.Size := 10;

  BtnTapeUse := CreateCalcBtn(PanelTape, '📥 回填结果', @OnTapeUseClick);
  BtnTapeUse.Parent := PanelTape;
  BtnTapeUse.Caption := '📥 回填结果';
  BtnTapeUse.OnClick := @OnTapeUseClick;

  BtnTapeCopySel := CreateCalcBtn(PanelTape, '📋 复制选中行', @OnTapeCopySelClick);
  BtnTapeCopySel.Parent := PanelTape;
  BtnTapeCopySel.Caption := '📋 复制选中行';
  BtnTapeCopySel.OnClick := @OnTapeCopySelClick;

  BtnTapeCopyAll := CreateCalcBtn(PanelTape, '📄 复制全部', @OnTapeCopyAllClick);
  BtnTapeCopyAll.Parent := PanelTape;
  BtnTapeCopyAll.Caption := '📄 复制全部';
  BtnTapeCopyAll.OnClick := @OnTapeCopyAllClick;

  BtnTapeClear := CreateCalcBtn(PanelTape, '🗑️ 清空纸带', @OnTapeClearClick);
  BtnTapeClear.Parent := PanelTape;
  BtnTapeClear.Caption := '🗑️ 清空纸带';
  BtnTapeClear.OnClick := @OnTapeClearClick;
end;

{ 布局仿真纸带历史面板 }
procedure TForm1.LayoutTapeTab;
var
  AvailW, ActionW, BtnFontSize: Integer;
begin
  if not Assigned(PanelTape) or not Assigned(ListTape) then Exit;
  AvailW := PanelTape.ClientWidth - 32;
  if AvailW < 100 then Exit;

  ListTape.SetBounds(16, 16, AvailW, Max(100, PanelTape.ClientHeight - 64));

  ActionW := Min(160, Max(80, (AvailW - 3 * 8) div 4));
  BtnFontSize := Min(12, Max(9, ActionW div 12));

  BtnTapeUse.SetBounds(16 + 0 * (ActionW + 8), PanelTape.ClientHeight - 42, ActionW, 34);
  BtnTapeCopySel.SetBounds(16 + 1 * (ActionW + 8), PanelTape.ClientHeight - 42, ActionW, 34);
  BtnTapeCopyAll.SetBounds(16 + 2 * (ActionW + 8), PanelTape.ClientHeight - 42, ActionW, 34);
  BtnTapeClear.SetBounds(16 + 3 * (ActionW + 8), PanelTape.ClientHeight - 42, ActionW, 34);

  BtnTapeUse.Font.Size := BtnFontSize;
  BtnTapeCopySel.Font.Size := BtnFontSize;
  BtnTapeCopyAll.Font.Size := BtnFontSize;
  BtnTapeClear.Font.Size := BtnFontSize;
end;

function TForm1.GetMainDisplayText: string;
begin
  if Assigned(EditMainDisplay) then
    Result := EditMainDisplay.Text
  else
    Result := '';
end;

{ 模式切换 }
procedure TForm1.SetMode(const AMode: TCalcMode);
begin
  if AMode in [cmAlgebraic, cmRPN, cmProgrammer] then
    FLastCalcMode := AMode;
  FCurMode := AMode;

  PanelScientific.Visible := (AMode = cmAlgebraic);
  PanelRPN.Visible := (AMode = cmRPN);
  PanelProgrammer.Visible := (AMode = cmProgrammer);
  PanelConverter.Visible := (AMode = cmConverter);
  PanelTape.Visible := (AMode = cmTape);

  BtnModeAlg.IsDown := (AMode = cmAlgebraic);
  BtnModeRPN.IsDown := (AMode = cmRPN);
  BtnModeProg.IsDown := (AMode = cmProgrammer);
  BtnModeConv.IsDown := (AMode = cmConverter);
  BtnModeTape.IsDown := (AMode = cmTape);

  case AMode of
    cmAlgebraic:
    begin
      PanelDisplay.Visible := True;
      PanelProgBases.Visible := False;
      BtnAngle.Visible := True;
      EditMainDisplay.Text := FAlgEngine.CurrentInput;
      LabelExpr.Caption := FAlgEngine.ExpressionStr;
    end;
    cmRPN:
    begin
      PanelDisplay.Visible := True;
      PanelProgBases.Visible := False;
      BtnAngle.Visible := True;
      EditMainDisplay.Text := FRPNEngine.CurrentInput;
      LabelExpr.Caption := 'RPN Stack Mode';
      UpdateRPNStackLabels;
    end;
    cmProgrammer:
    begin
      PanelDisplay.Visible := True;
      PanelProgBases.Visible := True;
      BtnAngle.Visible := False;
      EditMainDisplay.Text := FProgEngine.GetCurrentDisplayStr;
      LabelExpr.Caption := Format('Programmer (%s)', [WordSizeNames[FProgEngine.WordSize]]);
      UpdateProgrammerBasesAndBits;
    end;
    cmConverter:
    begin
      PanelDisplay.Visible := False;
      PanelProgBases.Visible := False;
      BtnAngle.Visible := False;
      LabelExpr.Caption := 'Unit Converter & Physical Constants';
    end;
    cmTape:
    begin
      PanelDisplay.Visible := False;
      PanelProgBases.Visible := False;
      BtnAngle.Visible := False;
      LabelExpr.Caption := 'Paper Tape History';
    end;
  end;
  RefreshTheme;
  FormResize(nil);
end;

procedure TForm1.OnModeBtnClick(Sender: TObject);
begin
  if Sender = BtnModeAlg then SetMode(cmAlgebraic)
  else if Sender = BtnModeRPN then SetMode(cmRPN)
  else if Sender = BtnModeProg then SetMode(cmProgrammer)
  else if Sender = BtnModeConv then SetMode(cmConverter)
  else if Sender = BtnModeTape then SetMode(cmTape);
end;

procedure TForm1.OnAngleBtnClick(Sender: TObject);
begin
  case FAngleMode of
    amDeg:  FAngleMode := amRad;
    amRad:  FAngleMode := amGrad;
    amGrad: FAngleMode := amDeg;
  end;
  BtnAngle.Caption := AngleModeNames[FAngleMode];
  FAlgEngine.AngleMode := FAngleMode;
  FRPNEngine.AngleMode := FAngleMode;
end;

procedure TForm1.OnTopMostBtnClick(Sender: TObject);
begin
  FAlwaysOnTop := not FAlwaysOnTop;
  BtnTopMost.IsDown := FAlwaysOnTop;
  if FAlwaysOnTop then
  begin
    FormStyle := fsStayOnTop;
    BtnTopMost.Caption := '📍';
  end
  else
  begin
    FormStyle := fsNormal;
    BtnTopMost.Caption := '📌';
  end;
end;

{ 主题黑、白、浅黄三色循环切换 }
procedure TForm1.OnThemeBtnClick(Sender: TObject);
begin
  case FCurTheme of
    ttBlack:  FCurTheme := ttWhite;
    ttWhite:  FCurTheme := ttYellow;
    ttYellow: FCurTheme := ttBlack;
  end;
  RefreshTheme;
end;

{ 主题应用刷新 }
procedure TForm1.RefreshTheme;
var
  P: TThemePalette;

  procedure StyleButton(B: TCalcButton);
  var
    Bg, Txt, Bor, Hov, Prs: TColor;
    R: TCalcButtonRole;
  begin
    if not Assigned(B) then Exit;
    R := B.Role;
    if R = cbrFunction then
    begin
      if (B.Caption = '=') or (B.Caption = 'ENTER') then R := cbrPrimary
      else if (Length(B.Caption) = 1) and (B.Caption[1] in ['0'..'9', '.', 'A'..'F']) then R := cbrNumber
      else if (B.Caption = '+') or (B.Caption = '-') or (B.Caption = '×') or (B.Caption = '÷') or
              (B.Caption = 'xʸ') or (B.Caption = 'MOD') or (B.Caption = 'nPr') or (B.Caption = 'nCr') or
              (B.Caption = 'AND') or (B.Caption = 'OR') or (B.Caption = 'XOR') or (B.Caption = 'NOT') or
              (B.Caption = 'NAND') or (B.Caption = 'NOR') or (B.Caption = 'XNOR') or
              (B.Caption = 'Lsh') or (B.Caption = 'Rsh') or (B.Caption = 'RoL') or (B.Caption = 'RoR') then R := cbrOperator
      else if (B.Caption = 'AC') or (B.Caption = 'CE') or (B.Caption = '⌫') or
              (B.Caption = 'MC') or (B.Caption = 'MR') or (B.Caption = 'MS') or
              (B.Caption = 'M+') or (B.Caption = 'M-') or (B.Caption = 'CLEAR') or (B.Caption = 'DROP') then R := cbrUtility;
      B.Role := R;
    end;

    GetRoleColors(P, B.Role, Bg, Txt, Bor, Hov, Prs);
    B.SetColors(Bg, Txt, Bor, Hov, Prs);
    B.FocusRingColor := P.FocusRing;
    B.DisabledTextColor := P.DisabledText;

    if B.Role in [cbrNumber, cbrPrimary] then
      B.Font.Style := [fsBold]
    else
      B.Font.Style := [];
  end;

  procedure RecurseStyleControls(ParentCtrl: TWinControl);
  var
    j: Integer;
    Ctrl: TControl;
  begin
    if (ParentCtrl = PanelTopBar) or (ParentCtrl = FPanelBits) then Exit;

    for j := 0 to ParentCtrl.ControlCount - 1 do
    begin
      Ctrl := ParentCtrl.Controls[j];
      if Ctrl is TCalcButton then
      begin
        if (Ctrl = BtnRadixHex) or (Ctrl = BtnRadixDec) or (Ctrl = BtnRadixOct) or
           (Ctrl = BtnRadixBin) or (Ctrl = BtnWordSize) or (Ctrl = BtnSigned) then
          Continue;

        StyleButton(TCalcButton(Ctrl));
      end
      else if Ctrl is TWinControl then
        RecurseStyleControls(TWinControl(Ctrl));
    end;
  end;

begin
  P := GetThemePalette(FCurTheme);
  ApplyThemeToForm(Self, FCurTheme);
  Self.Color := P.BgColor;

  // 顶部栏背景与各按钮样式
  PanelTopBar.Color := P.TopBarBg;

  BtnModeAlg.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnModeAlg.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
  BtnModeAlg.IsDown := (FCurMode = cmAlgebraic);

  BtnModeRPN.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnModeRPN.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
  BtnModeRPN.IsDown := (FCurMode = cmRPN);

  BtnModeProg.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnModeProg.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
  BtnModeProg.IsDown := (FCurMode = cmProgrammer);

  BtnModeConv.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnModeConv.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
  BtnModeConv.IsDown := (FCurMode = cmConverter);

  BtnModeTape.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnModeTape.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
  BtnModeTape.IsDown := (FCurMode = cmTape);

  BtnAngle.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnAngle.Font.Style := [fsBold];

  BtnTopMost.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnTopMost.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
  BtnTopMost.IsDown := FAlwaysOnTop;

  BtnTheme.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  BtnTheme.Caption := ThemeIconCaptions[FCurTheme];
  BtnTheme.Hint := '当前主题: ' + ThemeNames[FCurTheme] + ' (点击切换黑/白/浅黄)';

  if Assigned(BtnRadixHex) then
  begin
    BtnRadixHex.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
    BtnRadixHex.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
    BtnRadixHex.IsDown := (FProgEngine.BaseRadix = brHex);

    BtnRadixDec.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
    BtnRadixDec.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
    BtnRadixDec.IsDown := (FProgEngine.BaseRadix = brDec);

    BtnRadixOct.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
    BtnRadixOct.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
    BtnRadixOct.IsDown := (FProgEngine.BaseRadix = brOct);

    BtnRadixBin.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
    BtnRadixBin.SetDownColors(P.TopBtnActiveBg, P.TopBtnActiveText);
    BtnRadixBin.IsDown := (FProgEngine.BaseRadix = brBin);

    BtnWordSize.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
    BtnSigned.SetColors(P.TopBtnBg, P.TopBtnText, P.BorderColor, P.TopBtnHover, P.TopBtnPress);
  end;

  // 【核心要求】：输入框与显示屏颜色完全固定，不受黑/白/浅黄三种主题切换的影响
  PanelDisplay.Color := P.DisplayBg;
  EditMainDisplay.Color := P.DisplayBg;
  EditMainDisplay.Font.Color := P.DisplayText;
  LabelExpr.Font.Color := P.DisplaySubText;
  LabelMem.Font.Color := P.OpBtnBg;

  PanelProgBases.Color := P.DisplayBg;
  LabelHexBase.Font.Color := P.DisplayText;
  LabelDecBase.Font.Color := P.DisplayText;
  LabelOctBase.Font.Color := P.DisplayText;
  LabelBinBase.Font.Color := P.DisplayText;

  // 各模式面板背景跟随黑/白/浅黄主题自适应
  PanelModes.Color := P.BgColor;
  PanelScientific.Color := P.BgColor;
  PanelRPN.Color := P.BgColor;
  PanelProgrammer.Color := P.BgColor;
  PanelConverter.Color := P.BgColor;
  PanelTape.Color := P.BgColor;

  if Assigned(PanelRPNStack) then
  begin
    PanelRPNStack.Color := P.DisplayBg;
    LabelStackT.Font.Color := P.DisplaySubText;
    LabelStackZ.Font.Color := P.DisplaySubText;
    LabelStackY.Font.Color := P.DisplaySubText;
    LabelStackX.Font.Color := P.DisplayText;
  end;

  if Assigned(FPanelBits) then
    FPanelBits.Color := P.BgColor;

  if Assigned(ListConstants) then
  begin
    ListConstants.Color := P.NumBtnBg;
    ListConstants.Font.Color := P.NumBtnText;
  end;

  if Assigned(ListTape) then
  begin
    ListTape.Color := P.NumBtnBg;
    ListTape.Font.Color := P.NumBtnText;
  end;

  if Assigned(ComboCat) then
  begin
    ComboCat.Color := P.NumBtnBg;
    ComboCat.Font.Color := P.NumBtnText;
  end;

  if Assigned(ComboFromUnit) then
  begin
    ComboFromUnit.Color := P.NumBtnBg;
    ComboFromUnit.Font.Color := P.NumBtnText;
  end;

  if Assigned(ComboToUnit) then
  begin
    ComboToUnit.Color := P.NumBtnBg;
    ComboToUnit.Font.Color := P.NumBtnText;
  end;

  if Assigned(EditFromVal) then
  begin
    EditFromVal.Color := P.DisplayBg;
    EditFromVal.Font.Color := P.DisplayText;
  end;

  if Assigned(EditToVal) then
  begin
    EditToVal.Color := P.DisplayBg;
    EditToVal.Font.Color := P.DisplayText;
  end;

  RecurseStyleControls(Self);
end;

{ 纸带历史记录添加 }
procedure TForm1.AppendToTape(const ExprText, ResultText: string);
var
  Line: string;
begin
  Line := Format('[%s] %s = %s', [FormatDateTime('hh:nn:ss', Now), ExprText, ResultText]);
  FTapeList.Add(Line);
  if Assigned(ListTape) then
  begin
    ListTape.Items.Add(Line);
    ListTape.ItemIndex := ListTape.Items.Count - 1;
  end;
end;

{ 屏幕更新 }
procedure TForm1.UpdateDisplays;
begin
  case FCurMode of
    cmAlgebraic:
    begin
      EditMainDisplay.Text := FAlgEngine.CurrentInput;
      LabelExpr.Caption := FAlgEngine.ExpressionStr;
      if FAlgEngine.HasMemory then
        LabelMem.Caption := '[M]'
      else
        LabelMem.Caption := '';
    end;
    cmRPN:
    begin
      EditMainDisplay.Text := FRPNEngine.CurrentInput;
      UpdateRPNStackLabels;
    end;
    cmProgrammer:
    begin
      EditMainDisplay.Text := FProgEngine.GetCurrentDisplayStr;
      UpdateProgrammerBasesAndBits;
    end;
    cmConverter: ;
  end;
end;

{ RPN 堆栈显示更新 }
procedure TForm1.UpdateRPNStackLabels;
begin
  if not Assigned(LabelStackX) then Exit;
  LabelStackT.Caption := 'T: ' + FRPNEngine.GetStackFormatted(3);
  LabelStackZ.Caption := 'Z: ' + FRPNEngine.GetStackFormatted(2);
  LabelStackY.Caption := 'Y: ' + FRPNEngine.GetStackFormatted(1);
  LabelStackX.Caption := 'X: ' + FRPNEngine.GetStackFormatted(0);
end;

{ 程序员模式四进制与 64 位比特更新 }
procedure TForm1.UpdateProgrammerBasesAndBits;
var
  i, Bits: Integer;
  IsBitOne: Boolean;
  P: TThemePalette;
begin
  P := GetThemePalette(FCurTheme);

  LabelHexBase.Caption := 'HEX: ' + FProgEngine.GetHexStr;
  LabelDecBase.Caption := 'DEC: ' + FProgEngine.GetDecStr;
  LabelOctBase.Caption := 'OCT: ' + FProgEngine.GetOctStr;
  LabelBinBase.Caption := 'BIN: ' + FProgEngine.GetBinStr(True);

  Bits := WordSizeBits[FProgEngine.WordSize];
  for i := 0 to 63 do
  begin
    if Assigned(BitButtons[i]) then
    begin
      if i < Bits then
      begin
        BitButtons[i].Enabled := True;
        IsBitOne := FProgEngine.GetBit(i);
        if IsBitOne then
        begin
          BitButtons[i].Caption := '1';
          BitButtons[i].SetColors(P.OpBtnBg, clWhite, P.BorderColor, P.OpBtnHover, P.OpBtnPress);
          BitButtons[i].Font.Style := [fsBold];
        end
        else
        begin
          BitButtons[i].Caption := '0';
          BitButtons[i].SetColors(P.FuncBtnBg, P.DisplaySubText, P.BorderColor, P.FuncBtnHover, P.FuncBtnPress);
          BitButtons[i].Font.Style := [];
        end;
      end
      else
      begin
        BitButtons[i].Enabled := False;
        BitButtons[i].Caption := '-';
        BitButtons[i].SetColors(P.BgColor, clGray, P.BorderColor, P.BgColor, P.BgColor);
      end;
    end;
  end;
end;

{ ================= 代数/科学计算事件 ================= }

procedure TForm1.OnAlgNumClick(Sender: TObject);
begin
  if not (Sender is TControl) then Exit;
  if Length(TControl(Sender).Caption) = 1 then
    FAlgEngine.InputDigit(TControl(Sender).Caption[1]);
  UpdateDisplays;
end;

procedure TForm1.OnAlgOpClick(Sender: TObject);
begin
  if not (Sender is TControl) then Exit;
  FAlgEngine.InputOperator(TControl(Sender).Caption);
  UpdateDisplays;
end;

procedure TForm1.OnAlgEqualsClick(Sender: TObject);
var
  ResStr, ExprText: string;
  SavedExpr, SavedInput: string;
begin
  SavedExpr := FAlgEngine.ExpressionStr;
  SavedInput := FAlgEngine.CurrentInput;

  if FAlgEngine.ExecuteEquals(ResStr) then
  begin
    if SavedExpr <> '' then
      ExprText := Trim(SavedExpr + ' ' + SavedInput)
    else
      ExprText := SavedInput;
    AppendToTape(ExprText, ResStr);
  end;
  UpdateDisplays;
end;

procedure TForm1.OnAlgClearClick(Sender: TObject);
begin
  FAlgEngine.ClearAll;
  UpdateDisplays;
end;

procedure TForm1.OnAlgClearEntryClick(Sender: TObject);
begin
  FAlgEngine.ClearEntry;
  UpdateDisplays;
end;

procedure TForm1.OnAlgBackClick(Sender: TObject);
begin
  FAlgEngine.Backspace;
  UpdateDisplays;
end;

procedure TForm1.OnAlgDotClick(Sender: TObject);
begin
  FAlgEngine.InputDot;
  UpdateDisplays;
end;

procedure TForm1.OnAlgSignClick(Sender: TObject);
begin
  FAlgEngine.InputSign;
  UpdateDisplays;
end;

procedure TForm1.OnAlgPercentClick(Sender: TObject);
begin
  FAlgEngine.ExecutePercent;
  UpdateDisplays;
end;

procedure TForm1.OnAlgParenOpenClick(Sender: TObject);
begin
  FAlgEngine.InputOpenParen;
  UpdateDisplays;
end;

procedure TForm1.OnAlgParenCloseClick(Sender: TObject);
begin
  FAlgEngine.InputCloseParen;
  UpdateDisplays;
end;

procedure TForm1.OnAlgUnaryClick(Sender: TObject);
var
  Cap: string;
  ValBefore, ResStr: string;
begin
  if not (Sender is TControl) then Exit;
  Cap := TControl(Sender).Caption;
  ValBefore := FAlgEngine.CurrentInput;

  try
    if Cap = 'sin' then FAlgEngine.ApplyUnary('sin')
    else if Cap = 'asin' then FAlgEngine.ApplyUnary('asin')
    else if Cap = 'cos' then FAlgEngine.ApplyUnary('cos')
    else if Cap = 'acos' then FAlgEngine.ApplyUnary('acos')
    else if Cap = 'tan' then FAlgEngine.ApplyUnary('tan')
    else if Cap = 'atan' then FAlgEngine.ApplyUnary('atan')
    else if Cap = 'sinh' then FAlgEngine.ApplyUnary('sinh')
    else if Cap = 'asinh' then FAlgEngine.ApplyUnary('asinh')
    else if Cap = 'cosh' then FAlgEngine.ApplyUnary('cosh')
    else if Cap = 'acosh' then FAlgEngine.ApplyUnary('acosh')
    else if Cap = 'tanh' then FAlgEngine.ApplyUnary('tanh')
    else if Cap = 'atanh' then FAlgEngine.ApplyUnary('atanh')
    else if Cap = 'x²' then FAlgEngine.ApplyUnary('sqr')
    else if Cap = 'x³' then FAlgEngine.ApplyUnary('cube')
    else if Cap = '√x' then FAlgEngine.ApplyUnary('sqrt')
    else if Cap = '∛x' then FAlgEngine.ApplyUnary('cbrt')
    else if Cap = '1/x' then FAlgEngine.ApplyUnary('inv')
    else if Cap = 'log' then FAlgEngine.ApplyUnary('log10')
    else if Cap = 'ln' then FAlgEngine.ApplyUnary('ln')
    else if Cap = 'n!' then FAlgEngine.ApplyUnary('fact')
    else if Cap = '|x|' then FAlgEngine.ApplyUnary('abs')
    else if Cap = 'π' then FAlgEngine.InputPi
    else if Cap = 'e' then FAlgEngine.InputE;

    ResStr := FAlgEngine.CurrentInput;
    AppendToTape(Cap + '(' + ValBefore + ')', ResStr);
  except
    on E: Exception do
      ShowMessage('计算错误: ' + E.Message);
  end;
  UpdateDisplays;
end;

procedure TForm1.OnAlgMemoryClick(Sender: TObject);
var
  TagVal: Integer;
  CurV: Double;
begin
  if not (Sender is TControl) then Exit;
  TagVal := TControl(Sender).Tag;
  CurV := StrToFloatDef(FAlgEngine.CurrentInput, 0.0);

  case TagVal of
    1: FAlgEngine.MemoryClear;
    2: FAlgEngine.MemoryRecall;
    3: FAlgEngine.MemoryStore(CurV);
    4: FAlgEngine.MemoryAdd(CurV);
    5: FAlgEngine.MemorySub(CurV);
  end;
  UpdateDisplays;
end;

procedure TForm1.OnAlg2ndClick(Sender: TObject);
begin
  FSecondFunc := not FSecondFunc;
  if FSecondFunc then
  begin
    Btn2nd.Font.Style := [fsBold];
    BtnSin.Caption := 'asin';
    BtnCos.Caption := 'acos';
    BtnTan.Caption := 'atan';
    BtnSinh.Caption := 'asinh';
    BtnCosh.Caption := 'acosh';
    BtnTanh.Caption := 'atanh';
    BtnXSq.Caption := 'x³';
    BtnSqrt.Caption := '∛x';
  end
  else
  begin
    Btn2nd.Font.Style := [];
    BtnSin.Caption := 'sin';
    BtnCos.Caption := 'cos';
    BtnTan.Caption := 'tan';
    BtnSinh.Caption := 'sinh';
    BtnCosh.Caption := 'cosh';
    BtnTanh.Caption := 'tanh';
    BtnXSq.Caption := 'x²';
    BtnSqrt.Caption := '√x';
  end;
end;

{ ================= RPN 模式事件 ================= }

procedure TForm1.OnRPNNumClick(Sender: TObject);
var
  Cap: string;
begin
  if not (Sender is TControl) then Exit;
  Cap := TControl(Sender).Caption;
  if Cap = '.' then
    FRPNEngine.InputDot
  else if Length(Cap) = 1 then
    FRPNEngine.InputDigit(Cap[1]);
  UpdateDisplays;
end;

procedure TForm1.OnRPNEnterClick(Sender: TObject);
begin
  FRPNEngine.Enter;
  UpdateDisplays;
end;

procedure TForm1.OnRPNDropClick(Sender: TObject);
begin
  FRPNEngine.Drop;
  UpdateDisplays;
end;

procedure TForm1.OnRPNSwapClick(Sender: TObject);
begin
  FRPNEngine.SwapXY;
  UpdateDisplays;
end;

procedure TForm1.OnRPNRollDownClick(Sender: TObject);
begin
  FRPNEngine.RollDown;
  UpdateDisplays;
end;

procedure TForm1.OnRPNRollUpClick(Sender: TObject);
begin
  FRPNEngine.RollUp;
  UpdateDisplays;
end;

procedure TForm1.OnRPNClearClick(Sender: TObject);
var
  TagVal: Integer;
begin
  TagVal := TControl(Sender).Tag;
  if TagVal = 1 then
    FRPNEngine.Backspace
  else
    FRPNEngine.ClearAll;
  UpdateDisplays;
end;

procedure TForm1.OnRPNOpClick(Sender: TObject);
var
  Op: string;
  X, Y: string;
begin
  if not (Sender is TControl) then Exit;
  Op := TControl(Sender).Caption;
  X := FRPNEngine.GetStackFormatted(0);
  Y := FRPNEngine.GetStackFormatted(1);

  try
    FRPNEngine.ApplyBinary(Op);
    AppendToTape(Y + ' ' + Op + ' ' + X, FRPNEngine.GetStackFormatted(0));
  except
    on E: Exception do
      ShowMessage('RPN 运算错误: ' + E.Message);
  end;
  UpdateDisplays;
end;

procedure TForm1.OnRPNUnaryClick(Sender: TObject);
var
  Cap: string;
  XBefore: string;
begin
  if not (Sender is TControl) then Exit;
  Cap := TControl(Sender).Caption;
  XBefore := FRPNEngine.GetStackFormatted(0);

  try
    if Cap = '+/-' then FRPNEngine.InputSign
    else if Cap = 'sin' then FRPNEngine.ApplyUnary('sin')
    else if Cap = 'cos' then FRPNEngine.ApplyUnary('cos')
    else if Cap = 'tan' then FRPNEngine.ApplyUnary('tan')
    else if Cap = 'x²' then FRPNEngine.ApplyUnary('sqr')
    else if Cap = '√x' then FRPNEngine.ApplyUnary('sqrt')
    else if Cap = '1/x' then FRPNEngine.ApplyUnary('inv')
    else if Cap = 'log' then FRPNEngine.ApplyUnary('log10')
    else if Cap = 'ln' then FRPNEngine.ApplyUnary('ln')
    else if Cap = 'n!' then FRPNEngine.ApplyUnary('fact')
    else if Cap = 'π' then
    begin
      FRPNEngine.CurrentInput := FormatDisplayFloat(Pi);
      FRPNEngine.Enter;
    end
    else if Cap = 'e' then
    begin
      FRPNEngine.CurrentInput := FormatDisplayFloat(Exp(1.0));
      FRPNEngine.Enter;
    end;

    AppendToTape(Cap + '(' + XBefore + ')', FRPNEngine.GetStackFormatted(0));
  except
    on E: Exception do
      ShowMessage('计算错误: ' + E.Message);
  end;
  UpdateDisplays;
end;

{ ================= 程序员模式事件 ================= }

procedure TForm1.OnProgRadixClick(Sender: TObject);
begin
  if Sender = BtnRadixHex then FProgEngine.BaseRadix := brHex
  else if Sender = BtnRadixDec then FProgEngine.BaseRadix := brDec
  else if Sender = BtnRadixOct then FProgEngine.BaseRadix := brOct
  else if Sender = BtnRadixBin then FProgEngine.BaseRadix := brBin;

  BtnRadixHex.IsDown := (FProgEngine.BaseRadix = brHex);
  BtnRadixDec.IsDown := (FProgEngine.BaseRadix = brDec);
  BtnRadixOct.IsDown := (FProgEngine.BaseRadix = brOct);
  BtnRadixBin.IsDown := (FProgEngine.BaseRadix = brBin);

  UpdateDisplays;
end;

procedure TForm1.OnProgWordSizeClick(Sender: TObject);
begin
  case FProgEngine.WordSize of
    wsQword: FProgEngine.WordSize := wsDword;
    wsDword: FProgEngine.WordSize := wsWord;
    wsWord:  FProgEngine.WordSize := wsByte;
    wsByte:  FProgEngine.WordSize := wsQword;
  end;
  BtnWordSize.Caption := WordSizeNames[FProgEngine.WordSize];
  LabelExpr.Caption := Format('Programmer (%s)', [WordSizeNames[FProgEngine.WordSize]]);
  UpdateDisplays;
end;

procedure TForm1.OnProgSignedClick(Sender: TObject);
begin
  FProgEngine.ToggleSigned;
  if FProgEngine.IsSigned then
    BtnSigned.Caption := 'Signed'
  else
    BtnSigned.Caption := 'Unsigned';
  UpdateDisplays;
end;

procedure TForm1.OnProgBitClick(Sender: TObject);
var
  Idx: Integer;
begin
  if not (Sender is TControl) then Exit;
  Idx := TControl(Sender).Tag;
  FProgEngine.ToggleBit(Idx);
  UpdateDisplays;
end;

procedure TForm1.OnProgDigitClick(Sender: TObject);
var
  Ch: Char;
begin
  if not (Sender is TControl) then Exit;
  if Length(TControl(Sender).Caption) = 1 then
  begin
    Ch := TControl(Sender).Caption[1];
    FProgEngine.InputHexDigit(Ch);
  end;
  UpdateDisplays;
end;

procedure TForm1.OnProgOpClick(Sender: TObject);
var
  Op: string;
begin
  if not (Sender is TControl) then Exit;
  Op := TControl(Sender).Caption;
  FProgEngine.InputOperator(Op);
  UpdateDisplays;
end;

procedure TForm1.OnProgEqualsClick(Sender: TObject);
begin
  try
    FProgEngine.ExecuteEquals;
    AppendToTape('PROG: =', FProgEngine.GetCurrentDisplayStr);
  except
    on E: Exception do
      ShowMessage('程序员计算错误: ' + E.Message);
  end;
  UpdateDisplays;
end;

procedure TForm1.OnProgNotClick(Sender: TObject);
begin
  FProgEngine.BitwiseNot;
  UpdateDisplays;
end;

procedure TForm1.OnProgClearClick(Sender: TObject);
begin
  if TControl(Sender).Tag = 1 then
    FProgEngine.ClearAll
  else
    FProgEngine.ClearEntry;
  UpdateDisplays;
end;

procedure TForm1.OnProgBackClick(Sender: TObject);
begin
  FProgEngine.Backspace;
  UpdateDisplays;
end;

{ ================= 单位换算与常数事件 ================= }

procedure TForm1.OnConvCategoryChange(Sender: TObject);
var
  Cat: TUnitCategory;
  i: Integer;
begin
  Cat := TUnitCategory(ComboCat.ItemIndex);
  ComboFromUnit.Items.Clear;
  ComboToUnit.Items.Clear;

  for i := 0 to GetUnitCount(Cat) - 1 do
  begin
    ComboFromUnit.Items.Add(GetUnitName(Cat, i));
    ComboToUnit.Items.Add(GetUnitName(Cat, i));
  end;

  if ComboFromUnit.Items.Count > 0 then ComboFromUnit.ItemIndex := 0;
  if ComboToUnit.Items.Count > 1 then ComboToUnit.ItemIndex := 1
  else if ComboToUnit.Items.Count > 0 then ComboToUnit.ItemIndex := 0;

  OnConvInputChange(nil);
end;

procedure TForm1.OnConvFromChange(Sender: TObject);
begin
  OnConvInputChange(nil);
end;

procedure TForm1.OnConvToChange(Sender: TObject);
begin
  OnConvInputChange(nil);
end;

procedure TForm1.OnConvInputChange(Sender: TObject);
var
  Cat: TUnitCategory;
  Val, Res: Double;
begin
  Cat := TUnitCategory(ComboCat.ItemIndex);
  Val := StrToFloatDef(EditFromVal.Text, 0.0);
  Res := ConvertValue(Cat, ComboFromUnit.ItemIndex, ComboToUnit.ItemIndex, Val);
  EditToVal.Text := FormatDisplayFloat(Res);
end;

procedure TForm1.OnConvSwapClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := ComboFromUnit.ItemIndex;
  ComboFromUnit.ItemIndex := ComboToUnit.ItemIndex;
  ComboToUnit.ItemIndex := Idx;
  OnConvInputChange(nil);
end;

procedure TForm1.OnInsertConstantClick(Sender: TObject);
var
  Idx: Integer;
  C: TConstantItem;
begin
  Idx := ListConstants.ItemIndex;
  if Idx < 0 then Exit;
  C := GetConstant(Idx);

  case FCurMode of
    cmAlgebraic:
    begin
      FAlgEngine.CurrentInput := FormatDisplayFloat(C.Value);
      FAlgEngine.IsNewInput := True;
    end;
    cmRPN:
    begin
      FRPNEngine.CurrentInput := FormatDisplayFloat(C.Value);
      FRPNEngine.Enter;
    end;
    cmProgrammer:
    begin
      FProgEngine.Value := Trunc(C.Value);
      FProgEngine.IsNewInput := True;
    end;
  end;

  AppendToTape('CONST: ' + C.Symbol, FormatDisplayFloat(C.Value));
  ShowMessage(Format('已将常数 [%s: %s] 填入计算器: %g', [C.Symbol, C.Name, C.Value]));
  SetMode(cmAlgebraic);
end;

{ ================= 仿真纸带历史事件 ================= }

procedure TForm1.OnTapeUseClick(Sender: TObject);
var
  S, ResStr: string;
  PosEq: Integer;
  TargetMode: TCalcMode;
begin
  if ListTape.ItemIndex < 0 then Exit;
  S := ListTape.Items[ListTape.ItemIndex];
  PosEq := Pos('=', S);
  if PosEq > 0 then
    ResStr := Trim(Copy(S, PosEq + 1, Length(S)))
  else
    ResStr := S;

  TargetMode := FLastCalcMode;
  if (TargetMode = cmTape) or (TargetMode = cmConverter) then
    TargetMode := cmAlgebraic;

  case TargetMode of
    cmAlgebraic:
    begin
      FAlgEngine.CurrentInput := ResStr;
      FAlgEngine.IsNewInput := True;
      FAlgEngine.OperandReady := True;
    end;
    cmRPN:
    begin
      FRPNEngine.CurrentInput := ResStr;
      FRPNEngine.Enter;
    end;
    cmProgrammer:
    begin
      FProgEngine.Value := StrToInt64Def(ResStr, 0);
      FProgEngine.IsNewInput := True;
    end;
  end;
  SetMode(TargetMode);
  UpdateDisplays;
end;

procedure TForm1.OnTapeCopySelClick(Sender: TObject);
begin
  if ListTape.ItemIndex >= 0 then
    Clipboard.AsText := ListTape.Items[ListTape.ItemIndex];
end;

procedure TForm1.OnTapeCopyAllClick(Sender: TObject);
begin
  Clipboard.AsText := FTapeList.Text;
end;

procedure TForm1.OnTapeClearClick(Sender: TObject);
begin
  FTapeList.Clear;
  ListTape.Items.Clear;
end;

{ 全局键盘快捷键捕获 }
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // 当在换算模式或有处于编辑状态的文本框时，快捷键让行，直通原生输入框
  if (FCurMode = cmConverter) or (Assigned(ActiveControl) and (ActiveControl is TCustomEdit) and not TCustomEdit(ActiveControl).ReadOnly) then
    Exit;

  // Ctrl+C 复制当前显示数值
  if (ssCtrl in Shift) and (Key = Ord('C')) then
  begin
    Clipboard.AsText := EditMainDisplay.Text;
    Key := 0;
    Exit;
  end;

  // Ctrl+V 粘贴数字
  if (ssCtrl in Shift) and (Key = Ord('V')) then
  begin
    if Clipboard.HasFormat(CF_TEXT) then
    begin
      if FCurMode = cmAlgebraic then
      begin
        FAlgEngine.CurrentInput := Trim(Clipboard.AsText);
        FAlgEngine.IsNewInput := True;
      end
      else if FCurMode = cmRPN then
      begin
        FRPNEngine.CurrentInput := Trim(Clipboard.AsText);
        FRPNEngine.Enter;
      end;
      UpdateDisplays;
    end;
    Key := 0;
    Exit;
  end;

  // 退格键
  if Key = 8 then
  begin
    case FCurMode of
      cmAlgebraic: FAlgEngine.Backspace;
      cmRPN: FRPNEngine.Backspace;
      cmProgrammer: FProgEngine.Backspace;
    end;
    UpdateDisplays;
    Key := 0;
  end
  // Escape 清空
  else if Key = 27 then
  begin
    case FCurMode of
      cmAlgebraic: FAlgEngine.ClearAll;
      cmRPN: FRPNEngine.ClearAll;
      cmProgrammer: FProgEngine.ClearAll;
    end;
    UpdateDisplays;
    Key := 0;
  end
  // Enter 回车 (等号或 RPN Enter)
  else if Key = 13 then
  begin
    if FCurMode = cmAlgebraic then
      OnAlgEqualsClick(nil)
    else if FCurMode = cmRPN then
      OnRPNEnterClick(nil)
    else if FCurMode = cmProgrammer then
      OnProgEqualsClick(nil);
    Key := 0;
  end;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  // 当在换算模式或有处于编辑状态的文本框时，按键让行，直通原生输入框
  if (FCurMode = cmConverter) or (Assigned(ActiveControl) and (ActiveControl is TCustomEdit) and not TCustomEdit(ActiveControl).ReadOnly) then
    Exit;

  case Key of
    '0'..'9':
    begin
      if FCurMode = cmAlgebraic then FAlgEngine.InputDigit(Key)
      else if FCurMode = cmRPN then FRPNEngine.InputDigit(Key)
      else if FCurMode = cmProgrammer then FProgEngine.InputHexDigit(Key);
      UpdateDisplays;
      Key := #0;
    end;
    'a'..'f', 'A'..'F':
    begin
      if FCurMode = cmProgrammer then
      begin
        FProgEngine.InputHexDigit(Key);
        UpdateDisplays;
        Key := #0;
      end;
    end;
    '.':
    begin
      if FCurMode = cmAlgebraic then FAlgEngine.InputDot
      else if FCurMode = cmRPN then FRPNEngine.InputDot;
      UpdateDisplays;
      Key := #0;
    end;
    '+':
    begin
      try
        if FCurMode = cmAlgebraic then FAlgEngine.InputOperator('+')
        else if FCurMode = cmRPN then FRPNEngine.ApplyBinary('+')
        else if FCurMode = cmProgrammer then FProgEngine.InputOperator('+');
        UpdateDisplays;
      except
        on E: Exception do
          EditMainDisplay.Text := 'Error';
      end;
      Key := #0;
    end;
    '-':
    begin
      try
        if FCurMode = cmAlgebraic then FAlgEngine.InputOperator('-')
        else if FCurMode = cmRPN then FRPNEngine.ApplyBinary('-')
        else if FCurMode = cmProgrammer then FProgEngine.InputOperator('-');
        UpdateDisplays;
      except
        on E: Exception do
          EditMainDisplay.Text := 'Error';
      end;
      Key := #0;
    end;
    '*':
    begin
      try
        if FCurMode = cmAlgebraic then FAlgEngine.InputOperator('×')
        else if FCurMode = cmRPN then FRPNEngine.ApplyBinary('×')
        else if FCurMode = cmProgrammer then FProgEngine.InputOperator('×');
        UpdateDisplays;
      except
        on E: Exception do
          EditMainDisplay.Text := 'Error';
      end;
      Key := #0;
    end;
    '/':
    begin
      try
        if FCurMode = cmAlgebraic then FAlgEngine.InputOperator('÷')
        else if FCurMode = cmRPN then FRPNEngine.ApplyBinary('÷')
        else if FCurMode = cmProgrammer then FProgEngine.InputOperator('÷');
        UpdateDisplays;
      except
        on E: Exception do
          EditMainDisplay.Text := 'Error';
      end;
      Key := #0;
    end;
    '=':
    begin
      if FCurMode = cmAlgebraic then OnAlgEqualsClick(nil)
      else if FCurMode = cmProgrammer then OnProgEqualsClick(nil);
      Key := #0;
    end;
    '(':
    begin
      if FCurMode = cmAlgebraic then FAlgEngine.InputOpenParen;
      UpdateDisplays;
      Key := #0;
    end;
    ')':
    begin
      if FCurMode = cmAlgebraic then FAlgEngine.InputCloseParen;
      UpdateDisplays;
      Key := #0;
    end;
  end;
end;

end.