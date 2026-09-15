# 🧮 PCalc-Grade Advanced Calculator for Windows 10 & 11

> 🌟 **Benchmarking the macOS standard [PCalc](https://pcalc.com/mac/)**, a high-performance, high-precision, multi-mode native calculator crafted for Windows 10 & 11. Built with Free Pascal (FPC 3.2.2) and Lazarus, requiring zero external runtime dependencies (no .NET, no WebView2, no VC++ runtime, no Python/Node.js). Standalone single-file, instant cold launch, and minimal memory footprint.

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-blue.svg)](#)
[![Compiler](https://img.shields.io/badge/FPC-3.2.2-green.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](#)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passed%20(116%2F116)-brightgreen.svg)](#)

---

## 📖 Documentation
- 📘 **Complete User Manual**: [USER_MANUAL.md](USER_MANUAL.md) — In-depth tutorial covering algebraic formula calculation, RPN stack mechanics, programmer bit matrices, and unit conversions.
- 🇨🇳 **Chinese Documentation**: [README.md](README.md)

---

## ✨ Core Modes & Features

### 1. 🔬 Scientific & Algebraic Mode
- **Operator Precedence Scheduling**: Evaluates nested parentheses `( )` and standard precedence (multiplication/division before addition/subtraction).
- **Chained & Repeat Equals**: 
  - `2 + 3 + 4 =` results in `9`.
  - `5 + 2 =` (7), repeated `=` increments by 2 (9, 11...).
- **High-Precision Trigonometry with Zero-Point Alignment**:
  - `sin`, `cos`, `tan`, `asin`, `acos`, `atan`. Eliminates floating-point residual drift (e.g. `sin(180°)` outputs strict `0.0`).
  - Huge angles up to $10^{23}$ degrees reduce instantly in <10ms without overflow.
- **Hyperbolic Functions**: `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`.
- **Tri-State Angle Mode**: One-click switching between `DEG`, `RAD`, and `GRAD`.
- **Exponents & Logarithms**: `x²`, `x³`, `xʸ` (right-associative), `√x`, `∛x`, `y√x`, `log10`, `ln`, `log2`, `eˣ`, `10ˣ`, `2ˣ`.
- **Discrete Mathematics**: Factorials up to **170!**, permutations $nPr$, combinations $nCr$, modulo `MOD`, absolute value `|x|`, reciprocal `1/x`.
- **Memory System**: `MC`, `MR`, `MS`, `M+`, `M-` with persistent `[M]` indicator.

### 2. 🥞 RPN Mode (Reverse Polish Notation)
- **Classic 4-Level Stack Monitor**: Real-time display of X (top), Y, Z, and T registers.
- **Stack Instructions**: `ENTER` (push), `DROP` (pop), `x<>y` (swap), `R↓` (roll down), `R↑` (roll up), `CLEAR`.
- **Automatic Stack Drop**: Binary operators evaluate Y and X, store the result in X, and drop the stack automatically.

### 3. 💻 Programmer Mode
- **Simultaneous 4-Base Monitor**: HEX, DEC (signed/unsigned toggle), OCT, and BIN (4-bit grouped).
- **Hardware Word Sizes**: `64-bit (QWORD)`, `32-bit (DWORD)`, `16-bit (WORD)`, and `8-bit (BYTE)` with automatic bitmask truncation.
- **Bitwise Logic & Shifts**: `AND`, `OR`, `XOR`, `NOT`, `NAND`, `NOR`, `XNOR`, logical shifts `Lsh (<<)` / `Rsh (>>)`, and circular rotations `RoL` / `RoR`.
- **64-Bit Interactive Bit Matrix**: 64 clickable bit buttons (Bit 63 to 0). Click any bit to toggle state with instantaneous value synchronization across all bases.

### 4. 📐 Unit Converter & Physical Constants
- **10 Core Unit Categories**: Length, Area, Volume, Mass, Temperature (affine non-linear), Speed, Time, Data Storage (1024-based), Pressure, Energy.
- **16 High-Precision Constants**: $c, h, \hbar, G, g, k, N_A, e, m_e, m_p, R, \varepsilon_0, \mu_0, \pi, e, \phi$ with one-click insertion into the active calculation.

### 5. 📜 Paper Tape History
- Timestamped audit trail of all calculations (e.g. `[15:21:27] 2 + 3 = 5`).
- **One-Click Recall**: Double-click or click "Recall" to restore results directly into the active calculation mode.
- **Clipboard Integration**: Copy selected row or entire history tape.

### 6. 🎨 Modern Design System
- **Three Curated Themes**: Default Obsidian Black, Modern Light White, and Eye-Care Light Yellow.
- **DWM Immersive Dark Title Bar**: Native Windows 10/11 desktop window manager integration.
- **📌 Stay on Top**: Toggle pin button to keep calculator floating above other windows.
- **Full Keyboard Support**: Numpad, operators, Enter (=), Esc (AC), Backspace, Ctrl+C / Ctrl+V, with transparent pass-through for unit converter inputs.

---

## 🧪 Verification Matrix (100% Passed)

| Suite | Scope | Assertions | Status |
| :--- | :--- | :---: | :---: |
| **`audit_core.lpr`** | Engine math, operands, huge angle reduction, micro-floats, factorials | 52 / 52 | **100% PASSED** |
| **`audit_gui.lpr`** | Tape expressions, mode recall, converter typing, 440×600 compact layout | 9 / 9 | **100% PASSED** |
| **`test_calc.lpr`** | Regression suite (trig, hyperbolic, combinatorics, RPN, programmer, units) | 44 / 44 | **100% PASSED** |
| **`test_gui_calc.lpr`** | Full GUI click simulation, hotkeys, theme switching | 11 / 11 | **100% PASSED** |
| **Total** | **End-to-End System Coverage** | **116 / 116** | **100% PASSED** |

---

## 🏗️ Build & Distribution

### Run Pre-built Executable
Double-click `project1.exe` in the root directory or `releases/PCalc_Windows_Advanced_Calculator.exe`.

### Command-Line Build (PowerShell)
```powershell
# Run regression tests
& "C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe" -MObjFPC -Scghi -O1 -Fu. test_calc.lpr
.\test_calc.exe

# Build release application
& "C:\lazarus\lazbuild.exe" --build-all "project1.lpi"
```
