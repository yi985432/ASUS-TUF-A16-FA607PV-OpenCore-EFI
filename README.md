# ASUS TUF Gaming A16 (FA607PV) — macOS 26 OpenCore EFI

天选 5 Pro（FA607PV）的黑苹果 OpenCore 配置，基于 macOS 26.7.3 (25G342)。

> **项目来源声明 / Attribution**
>
> 本仓库是在 [VisualTechStudio/ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI](https://github.com/VisualTechStudio/ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI) 基础上修改的**衍生项目**。
> 原始 EFI、`SSDT-BATT` 电池实现、OpenCore 基线配置均来自原作者 **VisualTechStudio**，版权归原作者所有。
> 本仓库只针对本人机器的 Intel AX210、AsusSMC 键盘背光、内置摄像头 USB 端口等做增量适配，**不是原作者官方发布，也不代表原作者立场**。
> 使用、转载或二次分发时请保留本声明和原仓库链接。

> ⚠️ **使用前必读**：本仓库已清除 SMBIOS 身份信息（序列号 / MLB / UUID / ROM 均为占位符）。
> 直接使用会**无法登录 iCloud / iMessage / App Store**，需要你自己生成一套。
> 方法见下方「首次使用」。

---

## 硬件

| 部件 | 型号 | 状态 |
|---|---|---|
| CPU | AMD Ryzen 9 7940HX | ✅ 全部核心，电源管理正常 |
| 独显 | NVIDIA RTX 4060 Laptop (8 GB) | ✅ Metal 加速（NullMoth 驱动） |
| 核显 | Radeon 610M | ❌ 已禁用（macOS 无驱动） |
| 声卡 | Realtek ALC256 | ✅ 扬声器 + 麦克风正常（采样率需设为 48 kHz） |
| 无线网卡 | Intel AX210 (Wi-Fi 6E) | ✅ ForbiddenItlwm（AWDL / AirDrop） |
| 有线网卡 | Realtek RTL8111 | ✅ |
| 蓝牙 | Intel AX210 | ✅ IntelBluetoothFirmware + BlueToolFixup + BTLEAdvFixup |
| 触控板 | Synaptics I2C HID | ✅ |
| 内置摄像头 | USB2.0 HD UVC WebCam (Sonix `0x322e:0x2233`) | ✅ |
| 键盘背光 | ASUS ATK / EC | ✅ AsusSMC，Fn+F2/F3 + 系统滑块 |

## 系统

- macOS 26.7.3 (25G342) / Darwin 25.6.0
- OpenCore 1.0.x
- SMBIOS: `MacBookPro16,2`（仓库内为占位符）

---

## 本次同步内容（2026-11-22）

1. **AirDrop**：用 `ForbiddenItlwm` + `BTLEAdvFixup` 替换 `itlwm` / `AirportItlwm`，启用 AWDL。
2. **键盘背光**：新增 `AsusSMC.kext` + `SSDT-ASUS.aml`，Fn+F2/F3 和系统滑块都可调。
3. **内置摄像头**：`UTBMap` 补上 `XHC0.RHUB.PRT1`（port 1），摄像头正常枚举。
4. **屏幕亮度持久化**：修复 NullMoth `backlight.sh` 的解析 bug，并提供 `tools/fix-nullmoth-backlight.sh`。
5. `config.plist` 和 `config-installed.plist` 均已同步；SMBIOS 占位符未改动。

---

## 目录结构

```
EFI/
├── BOOT/
│   └── BOOTx64.efi
└── OC/
    ├── ACPI/        9 个 SSDT（含自定义 AC 修复、AsusSMC 键盘背光）
    ├── Drivers/     4 个驱动
    ├── Kexts/       34 个 kext
    ├── Resources/   OpenCanopy 图形界面资源
    ├── Tools/       NullMothSafe.efi
    ├── config.plist                    当前生效配置
    ├── config-installed.plist          显卡驱动装好后的配置（已同步本次改动）
    ├── config-installer.plist          全新安装用（无 nvfb 参数）
    └── config-rollback-noacfix.plist   回滚用（关闭 AC 修复）
docs/
└── SSDT-ASUS.dsl                       AsusSMC 键盘背光 SSDT 源码
tools/
└── fix-nullmoth-backlight.sh           NullMoth 亮度保存修复脚本
CREDITS.md                              来源与第三方许可
```

---

## 关键配置说明

### 1. 显卡（NVIDIA RTX 4060）

macOS 26 没有 NVIDIA 驱动，靠 [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) 项目。

驱动**不在 EFI 里**，需要单独安装到 `/Library/Extensions`：

```
boot-args: nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth nvrmacpibl=1 ...
```

安装完成后用 `config-installed.plist`。

### 2. AC 电源检测（自定义 SSDT）

华硕这代笔记本的 `ADP0._PSR` 读取 `EXBU` 区域（`0x96CBC0A0`），而该地址在 macOS 下不可访问，导致插电不识别。

`SSDT-ADPFIX.aml` 把 `_PSR` 改为读取 `IT55.ACIN`（`0xFE700600` 的 byte 64 bit 3），并加了 `_OSI("Darwin")` 判断，Windows 仍走原方法。

配套需要启用 ACPI 补丁 `_PSR → XPSR`（`TableSignature = DSDT`）。

### 3. 无线网卡 / AirDrop

当前使用 **ForbiddenItlwm 0.6.0-beta.2（Tahoe）**，它是 AirportItlwm 的分支，增加了 AWDL，用于 AirDrop。

| 项目 | 配置 |
|---|---|
| Wi-Fi kext | `ForbiddenItlwm.kext` |
| 蓝牙广播 | `BTLEAdvFixup.kext` 0.9.3 |
| 禁用 | `itlwm.kext`、`AirportItlwm.kext`、`IntelBTPatcher.kext` |
| 必需 boot-args | `-btleadv` + 一整套 `-itlawdl*` 参数（见 `config.plist`） |

注意事项：

- AirDrop 需要 Mac 已连接一个 Wi-Fi 网络；没连网络会一直“等待”。
- 5 GHz 首选信道 149；iPhone 用 44 的国家/地区会跟到 44。中国区 149 是 passive，需要先听到该信道上的网络。
- **升级 macOS 前**先带 `-btleadvoff` 启动一次，或临时禁用 `BTLEAdvFixup.kext`，否则增量更新可能失败。
- 这是 beta 内核驱动，可能 panic；保留 Windows / U 盘恢复手段。

### 4. 键盘背光（AsusSMC）

ASUS 的键盘背光不走 `NMKbdBacklight`（它只支持 Lenovo VPC2004 / 通用 EC `KBLC` / SMC key），而是 ASUS ATK/WMI。

本仓库使用：

- `AsusSMC.kext` 1.4.1
- `SSDT-ASUS.aml`：
  - 假 ALS 设备 `ALS0`（`ACPI0008`），因为本机没有环境光传感器；
  - `ATKD.SKBV` 调用 `\_SB.PCI0.SBRG.SECC(0x05, 0x80|level)`，直接写 EC 的键盘背光命令。
- 禁用 `SMCLightSensor.kext`、`NMKbdBacklight.kext`。

已知差异：

- macOS 原生 UI 是 16 级，本机 EC 只有 3 级（0 关，1–3 亮），所以 16 个滑块位置里只有 4 个有效状态。
- Fn+F2/F3 已可用；滑块和 Fn 都走同一条 EC 写入路径。
- `SSDT-ASUS.dsl` 源码在 `docs/`，改完用 `iasl` 编译成 `SSDT-ASUS.aml`。

### 5. 内置摄像头

摄像头在 ACPI 里是 `\_SB.PCI0.GP17.XHC0.RHUB.PRT1.WCAM`（USB，Sonix `0x322e:0x2233`）。

原 `UTBMap.kext` 只映射了 XHC0 的 port 2，漏了 port 1，导致摄像头不枚举。本仓库已补：

```
Controller-1 (XHC0) -> PRT1, port 1, UsbConnector 255 (internal)
```

重启后 `system_profiler SPCameraDataType` 应能看到 `USB2.0 HD UVC WebCam`。首次使用需要在「系统设置 → 隐私与安全性 → 摄像头」给 App 授权。

### 6. 屏幕亮度持久化

NullMoth 驱动把亮度保存在 NVRAM `nullmoth-backlight`，但开机不读回；它自带的 `/Library/NullMoth/backlight.sh` 里 `cur()` 解析写错了：

```bash
# 错误：nvram -x -p 输出的 key 没有 GUID 前缀
nvram -x -p | plutil -extract "7C436110-...:nullmoth-backlight" ...
# 正确
nvram -x nullmoth-backlight | plutil -extract nullmoth-backlight ...
```

结果是 `backlight.level` 从未生成，开机永远最大亮度。本仓库提供修复脚本：

```bash
sudo bash tools/fix-nullmoth-backlight.sh
```

脚本会备份原 `backlight.sh`、修正解析、写入当前 `backlight.level`，并重启 `com.nullmoth.backlight`。之后每 30 秒 / 关机时保存一次，开机恢复。

### 7. 音频

macOS 26 移除了 `AppleHDA.kext`（面向 Apple Silicon），所以用 [SimpleHDA](https://github.com/laobamac/SimpleHDA) 补回 HDA 栈。

必须满足：

- 顺序 `Lilu → AppleALC → SimpleHDA`
- `Kernel → Quirks → DisableLinkeditJettison = True`
- `Arch = x86_64`
- `MinKernel = 25.0.0`

> 注意：**不能关闭 AppleALC**。关掉后 `layout-id` 虽然会变成你设的值，但 SimpleHDA 初始化失败，设备直接消失。

---

## 已知问题

| 问题 | 原因 | 状态 |
|---|---|---|
| 内置扬声器破音、播放几秒后静音 | 采样率不匹配：系统默认 44.1 kHz，而 ALC256 layout 7 是按 48 kHz 调校的 | ✅ 改成 48 kHz 即可 |
| 亮度每次开机都是最大 | NullMoth `backlight.sh` 的 `cur()` 解析 bug | ✅ 已修复，见 `tools/` |
| 键盘背光只有 3 级，系统 UI 16 级 | EC 只实现 0–3，macOS 按 Apple 标准上报 16 级 | ⚠️ 可用，但中间档位重复 |
| 控制中心 Wi-Fi 磁贴显示“未连接” | 驱动 `APPLE80211_IOC` 实现不完整 | 实际联网正常，仅显示问题 |
| 睡眠/唤醒 | 未充分测试 | — |

### 音频：必须把采样率改成 48 kHz

装好系统后**第一件事**：打开「音频 MIDI 设置」→ 选中「内建输出」→ 把「格式」从 `44100 Hz` 改成 `48000 Hz`。

不改成 48 kHz 的表现：

- 音量一调就爆音
- 播放 5–20 秒后突然静音，切歌或重开播放器才恢复

原因：ALC256 在 layout 7 下的时钟是按 48 kHz 配置的，系统默认给 44.1 kHz，采样率不匹配导致重采样溢出 + DMA 缓冲下溢。

> 实测：改成 48 kHz 后，扬声器破音和断流消失，内置麦克风也正常（输入输出都可用）。

> 排查过但**无效**的方向（别浪费时间）：
> - 换 layout-id（11 / 13 / 21 / 56 / 69 / 99）——SimpleHDA 只认内嵌的那一套配置，换任何值都会导致设备消失
> - 关闭 AppleALC——`layout-id` 会变成你设的值，但 SimpleHDA 初始化失败，设备直接没了
> - 关闭 `nvrmacpibl` 改善音频——那个参数只管背光，跟音频无关

---

## 首次使用

1. **生成自己的 SMBIOS**

   用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成 `MacBookPro16,2` 的三码：

   ```
   SystemSerialNumber / MLB / SystemUUID
   ```

   填进 `config.plist` → `PlatformInfo → Generic`。

   `ROM` 填你自己网卡 MAC 的前 6 字节十六进制（`系统设置 → 网络 → 高级 → 硬件`）。

2. **确认 BIOS 设置**

   - Secure Boot：关
   - Fast Boot：关
   - CSM：关（仅 UEFI）
   - Above 4G Decoding：开
   - VT-d：关

3. **把 EFI 放进 ESP**

   ```
   EFI/  ->  ESP 根目录
   ```

4. **装显卡驱动**

   参考 [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) 的 README。装完后把 `config-installed.plist` 复制成 `config.plist`。

5. **把音频采样率改成 48 kHz**（否则会破音、播几秒就哑）

   「音频 MIDI 设置」→ 内建输出 → 格式 → `48000 Hz`。详见上面「音频」一节。

6. **修亮度保存**（可选，但强烈建议）

   ```bash
   sudo bash tools/fix-nullmoth-backlight.sh
   ```

7. **关掉自动登录**（如果有人给你装了 `finish-setup.sh` 之类的脚本）

   那类脚本为了绕过设置向导，会把密码以可逆形式写进 `/etc/kcpassword`。装好后去「系统设置 → 用户与群组 → 自动登录」关掉，并改一次密码。

---

## 引导参数说明

当前 `config.plist` 的 boot-args（节选，完整见文件）：

```
-v keepsyms=1 amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0
nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth
nvfbhidpi=1 nvrmacpibl=1 nvrmtgp=1 nvrmgps=1 nvrmnvpcf=1 nvfbigpu=1
nmxvt=1 nmhybrid20=1 nvrtd3=1 nvrmaspm=1 nmhdavol=1
itlwm_he=1 -ibtcompatbeta revpatch=sbvmm
-btleadv -itlawdlcoexprobe -itlawdliface -itlawdlnativeup ...
itlawdltxqueue=4096
```

| 参数 | 作用 |
|---|---|
| `nvfb=1 nvaccel=1 -nvkmsnosmooth` | NullMoth 显卡 |
| `nvrmacpibl=1` | 走 ACPI 背光（屏幕亮度键） |
| `-btleadv` | BTLEAdvFixup 开启，允许 Intel 蓝牙 LE 广播 |
| `-itlawdl*` | ForbiddenItlwm 的 AWDL / AirDrop 参数 |
| `itlawdltxqueue=4096` | awdl0 发送队列 |
| `-ibtcompatbeta` | Intel 蓝牙兼容 |
| `revpatch=sbvmm` | CPU 型号伪装 |

---

## 致谢与许可

**原始项目与原作者：**

- [VisualTechStudio/ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI](https://github.com/VisualTechStudio/ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI) —— 原始 A16 EFI、`SSDT-BATT` 电池实现、OpenCore 基线。**本仓库是它的衍生项目，原始版权归 VisualTechStudio。**

**第三方 kext / 项目：**

- [OpenCore](https://github.com/acidanthera/OpenCorePkg) / [Lilu](https://github.com/acidanthera/Lilu) / [VirtualSMC](https://github.com/acidanthera/VirtualSMC) / [AppleALC](https://github.com/acidanthera/AppleALC) / [WhateverGreen](https://github.com/acidanthera/WhateverGreen) —— Acidanthera
- [NullMoth NVIDIA driver](https://github.com/nullmoth/nvidia-macos-driver) —— NullMoth（非商业许可）
- [SimpleHDA](https://github.com/laobamac/SimpleHDA) —— laobamac
- [ForbiddenItlwm](https://github.com/retropineaple/ForbiddenItlwm) —— GPL-2.0（Wi-Fi 驱动）/ GPL-3.0（BTLEAdvFixup）
- [AsusSMC](https://github.com/hieplpvip/AsusSMC) —— MIT
- [USBToolBox](https://github.com/USBToolBox/tool) —— USBToolBox
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) / [VoodooPS2Controller](https://github.com/acidanthera/VoodooPS2)
- [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) —— Mieze
- [IntelBluetoothFirmware](https://github.com/OpenIntelWireless/IntelBluetoothFirmware) / [BlueToolFixup](https://github.com/acidanthera/BrcmPatchRAM) —— OpenIntelWireless / Acidanthera

第三方 kext 的版权和许可归各自作者所有；分发时请保留对应许可证与上游链接。详细清单见 [CREDITS.md](CREDITS.md)。

---

本 EFI 仅针对上述机型。修改 ACPI、引导配置与刷写 EFI 均存在风险，请务必备份可用的 EFI，并保留 Windows 与 U 盘恢复手段。作者不对任何后果负责。
