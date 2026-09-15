unit uCalcTypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { 计算器核心模式 }
  TCalcMode = (cmAlgebraic, cmRPN, cmProgrammer, cmConverter, cmTape);

  { 角度模式 }
  TAngleMode = (amDeg, amRad, amGrad);

  { 程序员模式字长 }
  TWordSize = (wsQword, wsDword, wsWord, wsByte);

  { 数值显示格式 }
  TDisplayFormat = (dfNormal, dfScientific, dfEngineering);

  { 主题风格：黑、白、浅黄三色切换 }
  TThemeType = (ttBlack, ttWhite, ttYellow);

  { 程序员模式当前输入进制 }
  TBaseRadix = (brHex, brDec, brOct, brBin);

const
  ThemeNames: array[TThemeType] of string = ('暗夜黑', '浅亮白', '温润浅黄');
  ThemeIconCaptions: array[TThemeType] of string = ('🌙 黑', '☀️ 白', '🌾 浅黄');

  { 字长对应位数与掩码 }
  WordSizeBits: array[TWordSize] of Integer = (64, 32, 16, 8);
  WordSizeMasks: array[TWordSize] of QWord = (
    QWord($FFFFFFFFFFFFFFFF),
    QWord($00000000FFFFFFFF),
    QWord($000000000000FFFF),
    QWord($00000000000000FF)
  );

  WordSizeNames: array[TWordSize] of string = ('64-bit (QWORD)', '32-bit (DWORD)', '16-bit (WORD)', '8-bit (BYTE)');
  AngleModeNames: array[TAngleMode] of string = ('DEG', 'RAD', 'GRAD');

implementation

end.
