# 🧮 PCalc-Grade Advanced Calculator for Windows 10 & 11 / 高级多功能科学计算器

> 🌟 **对标 macOS 标杆级计算器 [PCalc](https://pcalc.com/mac/)**，专为 Windows 10 与 11 原生打造的高性能、高精度、多模式专业生产力计算器。基于 Free Pascal (FPC 3.2.2) 与 Lazarus 原生编译，无需任何外部运行库（无需 .NET、无需 WebView2、无需 VC++ 运行库、无需 Python/Node），体积小巧、毫秒级冷启动、内存占用极低。

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-blue.svg)](#)
[![Compiler](https://img.shields.io/badge/FPC-3.2.2-green.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](#)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passed%20(116%2F116)-brightgreen.svg)](#)

---

## 📖 官方文档导航
- 📘 **用户功能教学指南**：[《计算器全功能用户使用手册 (USER_MANUAL.md)》](USER_MANUAL.md) —— 从基础代数、RPN 堆栈演练、程序员位矩阵到单位换算的保姆级教学。
- 🌍 **English Documentation**：[English README (README_EN.md)](README_EN.md)

---

## ✨ 核心特性与工作模式 (Core Modes & Features)

### 1. 🔬 科学与代数计算模式 (Scientific & Algebraic Mode)
- **四则运算优先级调度 (Operator Precedence)**：严格遵从先乘除后加减、嵌套括号 `(` 与 `)` 表达式求值。
- **连续链式累加与重复等号 (Repeat Equals)**：
  - 键入 `2 + 3 + 4 =` 得 9；
  - 计算 `5 + 2 =` 得 7，再次连续按 `=` 持续累加 2 (9, 11...)。
- **高精度三角函数与零点校准**：
  - `sin`, `cos`, `tan`, `asin`, `acos`, `atan`，彻底杜绝 `sin(180°)` 等浮点漂移残留（输出严格的 0.0）。
  - 百亿度超大角度（$10^9 \sim 10^{23}$ 度）瞬间完成纯浮点规约（<10ms），无任何溢出或卡顿。
- **双曲与反双曲函数**：`sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`。
- **角度度量三态一键切换**：`DEG` (角度制)、`RAD` (弧度制)、`GRAD` (百分度制)。
- **指数与高等对数**：`x²`, `x³`, `xʸ` (右结合), `√x`, `∛x`, `y√x`, `log10`, `ln`, `log2`, `eˣ`, `10ˣ`, `2ˣ`。
- **离散数学与高等统计**：
  - 阶乘 `n!`（最高支持 **170!** 高精度运算，解除传统 12! 限制）；
  - 排列数 $nPr$、组合数 $nCr$、模运算 `MOD`、绝对值 `|x|`、倒数 `1/x`。
- **物理常数快速键入**：圆周率 $\pi$ 与自然底数 $e$。
- **独立物理级记忆体系统**：`MC`, `MR`, `MS`, `M+`, `M-`，右上角常驻 `[M]` 状态标识，彻底取消打断式弹窗。

---

### 2. 🥞 RPN 逆波兰表达式模式 (Reverse Polish Notation)
- **经典 4 级 RPN 堆栈同屏监视器**：实时呈现 X（栈顶）、Y（次栈顶）、Z、T 寄存器数值。
- **经典堆栈调度指令**：
  - `ENTER`：压栈提升 (T <- Z <- Y <- X)；
  - `DROP`：丢弃当前栈顶 X，堆栈依次下落；
  - `x<>y (SWAP)`：极速对调 X 与 Y 寄存器；
  - `R↓ (Roll Down)`：4 级堆栈向下循环滚动；
  - `R↑ (Roll Up)`：4 级堆栈向上循环滚动；
  - `CLEAR`：一键清空堆栈。
- **单目与二元运算**：二元运算自动提取 Y 与 X 求值，结果落入 X 并自动触发堆栈下落 (Stack Drop)。

---

### 3. 💻 程序员模式 (Programmer Mode)
- **四进制同屏实时联动监视器**：
  - **HEX**（十六进制，带高位补零对齐）
  - **DEC**（十进制，支持有符号/无符号切换）
  - **OCT**（八进制）
  - **BIN**（二进制，4 位一组分段空格展示）
- **硬件级字长切换 (Word Size)**：
  - `64-bit (QWORD)`
  - `32-bit (DWORD)`
  - `16-bit (WORD)`
  - `8-bit (BYTE)`
  - 切换字长时自动套用硬件级截断掩码，精准模拟硬件溢出。
- **有符号与无符号模式 (Signed / Unsigned)**：负数二补码直观呈现。
- **全套位运算与移位指令**：`AND`, `OR`, `XOR`, `NOT`, `NAND`, `NOR`, `XNOR`，逻辑移位 `Lsh (<<)`、`Rsh (>>)`，循环移位 `RoL`、`RoR`。
- **64 位交互式点选比特矩阵 (Bit Matrix)**：
  - 4 行 x 16 列排布 64 个比特位（63 到 0）。
  - 每一个比特位均可直接点击翻转（0 变 1，1 变 0），实时同步至数值与所有进制。

---

### 4. 📐 单位换算与物理常数库 (Unit Converter & Constants)
- **10 大类日常生活与工程单位实时双向转换**：
  - 长度 (Length)、面积 (Area)、体积 (Volume)、质量 (Mass)、温度 (Temperature)、
    速度 (Speed)、时间 (Time)、数据存储 (Data)、压力 (Pressure)、能量与功 (Energy)。
- **16 大常用国际权威物理与数学常数速查库**：
  - 真空光速 $c$、普朗克常数 $h$、约化普朗克常数 $\hbar$、万有引力常数 $G$、重力加速度 $g$、玻尔兹曼常数 $k$、阿伏伽德罗常数 $N_A$、基本电荷 $e$、电子质量 $m_e$、质子质量 $m_p$、气体常数 $R$、介电常数 $\varepsilon_0$、磁导率 $\mu_0$、圆周率 $\pi$、自然底数 $e$、黄金分割比 $\phi$。
  - 支持**一键将选中的常数代入当前计算器**。

---

### 5. 📜 仿真纸带历史记录 (Paper Tape)
- 自动记录每一次计算的完整步骤、时间戳与结果，例如：`[15:21:27] 2 + 3 = 5`。
- **一键回填**：双击或点击“回填结果”，立即将历史数值重新送回当前模式（代数、RPN 或程序员）中继续计算。
- **剪贴板联动**：支持复制单行、复制全部纸带至剪贴板，方便粘贴备忘。
- **随时清空纸带**。

---

### 6. 🎨 现代主题系统与视觉交互
- **三款精心调校的高质感主题（一键循环切换）**：
  - 🌙 **经典极客黑 (Default Obsidian Black)**：沉浸深黑底色，PCalc 标志性赤陶红高亮主键，默认启动，暗光护眼防眩光。
  - ☀️ **现代浅亮白 (Modern Light White)**：通透清爽的现代极简浅色调，柔和高对比。
  - 🌾 **温润浅黄 (Eye-Care Light Yellow)**：舒适柔和的暖米黄调（Solarized Light 风格），长时间使用不累眼。
- **🖥️ 专属墨黑高对比液晶显示屏**：颜色恒定锁定防反光，红字非阻塞 `Error` 报错自愈。
- **Windows 10/11 DWM 沉浸式暗色标题栏**：调用原生 DWM API 自动适应深色标题栏。
- **📌 窗口置顶 (Stay-on-Top)**：点击右上角大头针图标即可自由开启/关闭悬浮置顶。
- **全键盘支持**：数字小键盘、回车等号、Esc 全清、退格删除、Ctrl+C 复制、Ctrl+V 粘贴、换算框键盘直通。

---

## 🏗️ 架构与源码结构

```
c:\XMWJJ\jisuanqidome\
├── project1.lpr           # 工程主程序入口
├── project1.lpi           # Lazarus 工程配置文件
├── unit1.pas              # 主窗体业务协调器与自适应排版引擎
├── unit1.lfm              # 主窗体描述文件 (纯代码构建)
├── uCalcTypes.pas         # 核心类型系统、按键角色枚举、字长掩码
├── uMathUtils.pas         # 高精度浮点安全运算库、角度规约、离散函数
├── uAlgebraicEngine.pas   # 代数表达式解析引擎、优先级双栈调度、括号匹配
├── uRPNEngine.pas         # 经典 4 级 RPN 逆波兰堆栈算法引擎
├── uProgrammerEngine.pas  # 程序员多进制联动、64 位位运算与位矩阵引擎
├── uUnitConverter.pas     # 10 大类单位换算引擎与 16 种物理常数数据字典
├── uThemeManager.pas      # 设计令牌调色板与 Win10/11 DWM 沉浸标题栏
├── uCalcButton.pas        # 语义化自绘圆角按键组件 (双缓冲无闪烁、无障碍 Tab)
├── USER_MANUAL.md         # 详细的用户操作与教学手册
├── README_EN.md           # 英文项目说明
├── test_calc.lpr          # 基础数学与引擎测试套件
├── test_gui_calc.lpr      # 完整窗体点击与快捷键模拟测试套件
├── project1.exe           # 编译生成的独立单文件 Win64 原生可执行文件
└── releases/              # 发布程序归档目录
```

---

## 🧪 自动化测试验证矩阵 (100% 通过)

本项目配备了完整的自动化回归与端到端测试体系，涵盖 116 项严格的断言检查：

| 测试套件 | 验证范围 | 断言数量 | 通过率 |
| :--- | :--- | :---: | :---: |
| **`audit_core.lpr`** | 核心代数运算、操作数传递、超大数角度规约、微小数精度、极值阶乘 | 52 / 52 | **100% PASSED** |
| **`audit_gui.lpr`** | 纸带算式完整性、多模式回填、换算器键盘穿透、440×600 布局自适应 | 9 / 9 | **100% PASSED** |
| **`test_calc.lpr`** | 基础回归套件（三角/双曲/排列组合/RPN/程序员/单位换算） | 44 / 44 | **100% PASSED** |
| **`test_gui_calc.lpr`** | 窗体组件点击模拟、按键模拟、主题切换 | 11 / 11 | **100% PASSED** |
| **总计** | **全模块全场景覆盖** | **116 / 116** | **100% PASSED** |

---

## 🚀 编译与运行

### 方式一：直接运行成品（免安装）
直接进入根目录或 `releases/` 目录，双击运行 **`project1.exe`** 即可。

### 方式二：使用命令行构建
在 PowerShell 中执行：
```powershell
# 1. 运行回归测试
& "C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O1 -Fu. test_calc.lpr
.\test_calc.exe

# 2. 构建生产程序
& "C:\lazarus\lazbuild.exe" --build-all "project1.lpi"
```

### 方式三：使用 Lazarus IDE
1. 打开 Lazarus IDE，点击菜单 `项目` -> `打开项目`，选择 `project1.lpi`；
2. 按 `Ctrl + F9` 编译，或按 `F9` 直接运行。
