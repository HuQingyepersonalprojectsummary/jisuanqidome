# PCalc 计算器应用加壳保护与高安全安装包技术白皮书

## 一、概述与核心目标

PCalc 高级多功能科学计算器（Windows 原生 x64）包含高精度数学函数校准算法、170! 阶乘运算逻辑、经典 4 级 RPN 堆栈引擎、64 位硬件级位矩阵运算模拟及多套高质感 UI 交互系统。

为了保障核心算法的安全性、防止商业逆向分析、内存挂钩与二进制补丁篡改，本项目构建了一套**双层纵深防御体系**：
1. **内层保护（内核代码虚拟化与加壳）**：由 **Oreans Themida 3.2.6.0 SecureEngine** 驱动，将原生 x64 机器码转换为多架构私有虚拟机指令，辅以全方位反调试、反 Dump 与内存防篡改机制。
2. **外层分发（现代化固实压缩安装容器）**：由 **Inno Setup 6** 驱动，采用 `lzma2/ultra64` 固实压缩容器，提供干净可控的安装/卸载生命周期管理与 SHA256 完整性防爆破校验。

---

## 二、双层防护架构 (Dual-Layer Defense Model)

```
+-----------------------------------------------------------------------------------+
|                        外层: Inno Setup 6 分发容器                                |
|  - LZMA2/Ultra64 固实压缩 (降低体积，防单文件篡改)                                |
|  - Windows 10/11 沉浸式安装向导，桌面/开始菜单快捷方式                            |
|  - SHA256 发布指纹校验 (.sha256 独立校验文件)                                     |
|  - Windows 标准应用卸载注册表与自清理                                            |
|                                                                                   |
|    +-------------------------------------------------------------------------+    |
|    |               内层: Themida 3.2.6.0 SecureEngine 加壳防护               |    |
|    |                                                                         |    |
|    |  [1. 多架构虚拟机体系 Multi-VM Engine]                                  |    |
|    |     - TIGER-RED / FISH-BLACK / PUMA-WHITE 多重嵌套架构                  |    |
|    |     - 真实 x64 指令被翻译为动态随机 Opcode，IDA/Ghidra 无法生成伪代码   |    |
|    |                                                                         |    |
|    |  [2. 反调试体系 Anti-Debugger System]                                   |    |
|    |     - 用户态调试器阻断 (x64dbg, OllyDbg, Cheat Engine)                  |    |
|    |     - 内核态调试器检测 (WinDbg, Hypervisor 检测)                        |    |
|    |     - 硬件断点 (DR0-DR7) 与内存断点 (PAGE_GUARD) 实时清空               |    |
|    |                                                                         |    |
|    |  [3. 内存防护体系 Memory Protection]                                    |    |
|    |     - Anti-Dump: 破坏 PE 内存映射，拦截 Scylla / Process Hacker 转储   |    |
|    |     - Real-Time CRC: 实时内存页面哈希轮询，发现 Hook / 补丁直接崩溃     |    |
|    |                                                                         |    |
|    |  [4. 资源与代码高强度加密 Protection Layer]                             |    |
|    |     - 代码段与数据段 AES/Blowfish 强加密，启动时动态多态解密            |    |
|    |     - 入口点深度混淆 (AEP Obfuscation)，隐藏原始 OEP                    |    |
|    +-------------------------------------------------------------------------+    |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

## 三、机密隔离与防泄密策略 (Zero-Leak Policy)

在构建企业级保护与安装包时，必须防止开发者本机的私密路径、商业授权特征和加壳工程密钥泄漏至公共代码托管平台（如 GitHub）：

| 资产类型 | 存放位置 | Git 状态 | 安全说明 |
| :--- | :--- | :---: | :--- |
| **本机私有配置** | `build.secrets.local.json` | 🚫 **已全局忽略** | 存储开发机真实私有 Themida 路径，由用户本地填写，永不提交 |
| **公开发布模板** | `build.secrets.example.json` | ✅ **安全提交** | 纯占位符模板，供其他人员或 CI 构建机参考配置 |
| **Themida 加壳工程** | `*.tmd` / `*.tm` | 🚫 **已全局忽略** | 包含二进制密钥种子与 VM 映射逻辑，禁止入库 |
| **安装包产物** | `artifacts/*.exe` | 🚫 **已全局忽略** | 最终分发大二进制文件不占用 Git 存储树 |
| **代码与测试脚本** | `scripts/*.ps1`, `scripts/*.iss` | ✅ **安全提交** | 纯逻辑自动化代码，解耦具体私有路径 |

### 敏感数据配置规范：
在本地开发机器中，开发者自行创建 `build.secrets.local.json` 并填写本机私有路径：
```json
{
  "Themida": {
    "ExecutablePath": "<THEMIDA_INSTALL_DIR>\\Themida.exe",
    "ProjectPath": "PCalc_HighSecurity.tmd"
  }
}
```
脚本优先读取该文件；若文件不存在，则从环境变量 `$env:THEMIDA_PATH` 或命令行参数 `-ThemidaPath` 中获取，实现完全解耦。

---

## 四、终端自动化流水线实施细节

打包驱动脚本位于 [`scripts/Package-ProtectedInstaller.ps1`](../scripts/Package-ProtectedInstaller.ps1)，共划分为 5 个原子阶段：

### 阶段 1：前置自动化回归验证
- 自动调用 `test_calc.exe` 验证 44 项核心数学引擎测试；
- 自动调用 `test_gui_calc.exe` 验证 11 项 GUI 点击仿真测试；
- 任意一项测试异常则直接中断流水线，防止故障二进制流出。

### 阶段 2：独立分装（Staging Isolation）
- 创建带有唯一 GUID 的临时隔离工作区：`artifacts/installer-staging-<GUID>`；
- 将 `project1.exe`（或 `releases/PCalc_Windows_Advanced_Calculator.exe`）规范化重命名为 `PCalc.exe`；
- 抓取应用高清图标 `project1.ico`、使用说明 `USER_MANUAL.md`、自述文件 `README.md`；
- 自动清理残余的 Free Pascal 临时编译中间文件（`.o`, `.ppu`, `.obj`, `.bak`）。

### 阶段 3：Themida 命令行无缝加壳
- 如果本地存在 `PCalc_HighSecurity.tmd`，自动执行：
  ```cmd
  Themida.exe /protect "PCalc_HighSecurity.tmd" /inputfile "PCalc.unprotected.exe" /outputfile "PCalc.exe" /shareconsole /q
  ```
- 严格解析 Themida 进程退出码（Exit Code）：
  - `0`：加壳成功
  - `1`：工程文件不存在或损坏
  - `2`：待保护文件无法打开
  - `3`：文件已加壳
  - `5`：内部加密引擎异常
  - `6`：目标磁盘无写入权限
- 若加壳成功，自动销毁 `PCalc.unprotected.exe`。

### 阶段 4：Inno Setup 6 现代化安装包编译
- 定位 `iscc.exe`；
- 传入版本宏、隔离分装路径与图标宏，启动 `lzma2/ultra64` 固实压缩引擎；
- 生成支持 Windows 10/11 高分屏 DPI 缩放的原生 x64 安装程序 `artifacts/PCalc-1.0.0-win-x64-Setup.exe`。

### 阶段 5：发布校验与 SHA256 指纹生成
- 计算最终 Setup 安装包的 SHA256 哈希；
- 写入同名 `.sha256` 校验和文件，供终端用户或分发渠道做防篡改验证；
- 销毁临时 Staging 隔离目录。

---

## 五、常用终端命令备忘

```powershell
# 1. 执行全套打包流水线（测试 -> 加壳 -> 制作安装包）
pwsh -File ./scripts/Package-ProtectedInstaller.ps1

# 2. 指定自定义版本号并跳过测试
pwsh -File ./scripts/Package-ProtectedInstaller.ps1 -Version 1.1.0 -SkipTests

# 3. 首次未配置 TMD 时调出 Themida 界面
pwsh -File ./scripts/Package-ProtectedInstaller.ps1 -OpenThemidaGui

# 4. 仅测试安装包编译流程（不加壳）
pwsh -File ./scripts/Package-ProtectedInstaller.ps1 -SkipThemida -SkipTests
```
