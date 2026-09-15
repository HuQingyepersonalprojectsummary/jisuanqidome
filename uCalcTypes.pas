unit uCalcTypes;

{==============================================================================
  PCalc 高级科学与工程计算器 - 核心类型与枚举定义单元 (uCalcTypes.pas)
  ------------------------------------------------------------------------------
  本单元定义了整个计算器系统所依赖的基础类型系统：
  1. 计算器工作模式枚举 (代数科学、RPN逆波兰、程序员、单位换算、仿真纸带)
  2. 角度度量制度枚举 (角度 DEG、弧度 RAD、百分度 GRAD)
  3. 程序员模式字长定义及对应的比特位数、截断掩码 (QWORD, DWORD, WORD, BYTE)
  4. 程序员模式多进制枚举 (HEX, DEC, OCT, BIN)
  5. 三色高质感现代主题类型与标签名称 (暗夜黑、浅亮白、温润浅黄)
  6. 按键语义角色与命令调度契约 (TCalcButtonRole, TCalcCommand)
==============================================================================}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { 计算器核心工作模式 }
  TCalcMode = (
    cmAlgebraic,   { 科学与代数表达式计算模式 (支持优先级、括号、函数) }
    cmRPN,         { 经典 4 级 RPN 逆波兰表达式堆栈模式 (X, Y, Z, T) }
    cmProgrammer,  { 程序员模式 (四进制实时联动、64位位运算与位矩阵点选) }
    cmConverter,   { 物理单位双向换算器与物理常数速查库 }
    cmTape         { 仿真纸带历史记录 (带时间戳、算式全流程、一键回填) }
  );

  { 三角函数角度度量模式 }
  TAngleMode = (
    amDeg,         { 角度制 (Degrees, 0~360°) }
    amRad,         { 弧度制 (Radians, 0~2π) }
    amGrad         { 百分度制 (Gradians, 0~400) }
  );

  { 程序员模式字长规格 (Word Size) }
  TWordSize = (
    wsQword,       { 64 位无符号/有符号整型 (四字 QWORD, 64-bit) }
    wsDword,       { 32 位整型 (双字 DWORD, 32-bit) }
    wsWord,        { 16 位整型 (单字 WORD, 16-bit) }
    wsByte         { 8 位整型 (单字节 BYTE, 8-bit) }
  );

  { 数值在主屏中的显示格式风格 }
  TDisplayFormat = (
    dfNormal,      { 标准定点与大数自适应格式 }
    dfScientific,  { 纯科学计数法格式 (例: 1.23e+10) }
    dfEngineering  { 工程计数法 (指数为 3 的整数倍) }
  );

  { 主题风格：黑、白、浅黄三色主题切换 }
  TThemeType = (
    ttBlack,       { 经典极客黑 (沉浸深黑底色，高对比度磨砂机身，默认启动) }
    ttWhite,       { 现代浅亮白 (极简清爽浅灰白调，柔和高对比) }
    ttYellow       { 温润浅黄 (护眼柔和暖黄/米黄风格，长时间使用舒适防眩) }
  );

  { 程序员模式当前输入与显示进制 }
  TBaseRadix = (
    brHex,         { 十六进制 (Base 16, 支持 0-9 与 A-F) }
    brDec,         { 十进制 (Base 10, 支持 0-9) }
    brOct,         { 八进制 (Base 8, 支持 0-7) }
    brBin          { 二进制 (Base 2, 支持 0 与 1) }
  );

  { 按键语义角色：取代脆弱的字符串标题样式判定，实现高可靠性主题渲染 }
  TCalcButtonRole = (
    cbrNumber,      { 数字按键 (0-9, 小数点, 正负号) }
    cbrFunction,    { 科学与工程单目函数 (sin, cos, ln, x² 等) }
    cbrOperator,    { 二元运算符 (+, -, ×, ÷, MOD, 幂等) }
    cbrPrimary,     { 核心强调求值动作键 (=, ENTER) }
    cbrNavigation,  { 顶部模式导航栏按键 }
    cbrUtility,     { 辅助控制按键 (AC 清空, CE 撤销, ⌫ 退格, 内存键) }
    cbrBit          { 程序员模式 64 位交互式点选比特位按钮 }
  );

  { 计算器动作事件类型定义 }
  TCalcAction = (
    caDigit, caDecimal, caBinary, caUnary, caEquals,
    caClearAll, caClearEntry, caBackspace,
    caMemory, caSwitchMode, caRecallValue
  );

  { 计算器命令载荷结构 }
  TCalcCommand = record
    Action: TCalcAction;  { 动作指令类别 }
    Argument: string;     { 命令参数：数字、运算符符号、函数名或命令标识 }
  end;

const
  { 主题显示名称与切换图标文字 }
  ThemeNames: array[TThemeType] of string = ('暗夜黑', '浅亮白', '温润浅黄');
  ThemeIconCaptions: array[TThemeType] of string = ('🌙 黑', '☀️ 白', '🌾 浅黄');

  { 字长规格对应有效比特位数 }
  WordSizeBits: array[TWordSize] of Integer = (64, 32, 16, 8);

  { 各字长对应的 64 位截断无符号掩码 }
  WordSizeMasks: array[TWordSize] of QWord = (
    QWord($FFFFFFFFFFFFFFFF),
    QWord($00000000FFFFFFFF),
    QWord($000000000000FFFF),
    QWord($00000000000000FF)
  );

  { 字长与角度制国际化/标准化名称 }
  WordSizeNames: array[TWordSize] of string = ('64-bit (QWORD)', '32-bit (DWORD)', '16-bit (WORD)', '8-bit (BYTE)');
  AngleModeNames: array[TAngleMode] of string = ('DEG', 'RAD', 'GRAD');

implementation

end.
