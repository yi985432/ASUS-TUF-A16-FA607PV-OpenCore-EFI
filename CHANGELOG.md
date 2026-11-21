# Changelog

## 2026-11-22（第二批）

### CPU 名称

- `PlatformInfo → Generic → ProcessorType` 从 `3841`（0x0F01，Xeon W 类型）改为 `0`，核心数显示恢复为 16。
- `boot-args` 的 `revpatch=sbvmm` 改为 `revpatch=sbvmm,cpuname`。boot-arg 优先级高于 NVRAM，之前把 NVRAM 里的 `sbvmm,cpuname` 覆盖掉了，导致 `revcpuname` 不生效。
- 名称现为 `AMD Ryzen 9 7940HX 16-Core Processor`。

### CPU 温度与频率

- `AMDRyzenCPUPowerManagement.kext` 0.7.2 → **3.40.3**。
- `SMCAMDProcessor.kext` 1.0.1（2020，SDK 12.3）→ **3.40.3**。旧版在 Tahoe 上 `!registered, !matched`，SMC 里没有任何传感器 key。
- 来源：`DrogaBox/ryzenstatus-utils` v1.85.0（官方 0.7.2 的活跃 fork，支持 macOS 13–26）。
- 配套 `RyzenStatus.app` 1.85.0，菜单栏显示每核频率、温度、PPT 功耗。
- 实测睿频（`powermetrics --samplers cpu_power`，nominal 2.4 GHz）：轻载单核 4635–4985 MHz，12 线程满载 4372 MHz。

### 有线网卡

- `RealtekRTL8111.kext` 2.4.2 → **3.0.4（release v3.0.0）**。
- 新特性：Tahoe 下的 AppleVTD 支持、无 fallback MAC 时生成随机 MAC、低内存下改进接收缓冲分配。

## 2026-11-22

### AirDrop / Wi-Fi

- 新增 `ForbiddenItlwm.kext` 0.6.0-beta.2 (Tahoe) 与 `BTLEAdvFixup.kext` 0.9.3。
- `Kernel → Add` 顺序调整为 `Lilu → IntelBluetoothFirmware → BlueToolFixup → BTLEAdvFixup → ForbiddenItlwm`。
- 禁用 `itlwm.kext`、`AirportItlwm.kext`、`IntelBTPatcher.kext`。
- `boot-args` 增加 `-btleadv` 及 AWDL 参数，移除 `nmkbl=1 nmkblhid=1`。
- AirDrop 可用；AirDrop 需要已连接 Wi-Fi，5 GHz 149/44 信道。

### 键盘背光

- 新增 `AsusSMC.kext` 1.4.1 与 `SSDT-ASUS.aml`（假 ALS + `ATKD.SKBV`）。
- `SKBV` 通过 `\_SB.PCI0.SBRG.SECC(0x05, 0x80|level)` 写 EC，而不是不存在的 `SLKI`。
- 增加 `ATKD._INI` 调用 `INIT(One)`，打开 `ATKP`，Fn 通知才能进入 AsusSMC。
- 禁用 `SMCLightSensor.kext`、`NMKbdBacklight.kext`。
- Fn+F2/F3 和系统键盘亮度滑块可用；macOS UI 16 级，EC 实际 3 级。

### 内置摄像头

- `UTBMap.kext` 的 `Controller-1`（XHC0）增加 `PRT1`（port 1，`UsbConnector 255`）。
- 摄像头识别为 `USB2.0 HD UVC WebCam`（Sonix `0x322e:0x2233`）。

### 屏幕亮度持久化

- 修复 NullMoth `/Library/NullMoth/backlight.sh` 的 `cur()` 解析 bug（`nvram -x -p` 的 key 没有 GUID 前缀）。
- 新增 `tools/fix-nullmoth-backlight.sh`，自动备份、修正、写入 `backlight.level` 并重启守护进程。

### 配置与文档

- `config.plist`、`config-installed.plist` 同步以上改动；SMBIOS 占位符保持不变。
- README 重写，增加来源声明、AirDrop、键盘背光、摄像头、亮度修复说明。
- 新增 `CREDITS.md`，声明项目来自 VisualTechStudio 的原始仓库，并列出第三方许可。
