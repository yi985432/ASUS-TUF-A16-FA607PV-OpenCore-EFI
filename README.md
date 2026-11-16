# ASUS TUF Gaming A16 (FA607PV) — macOS 26 OpenCore EFI

天选 5 Pro（FA607PV）的黑苹果 OpenCore 配置，基于 macOS 26.7.3 (25G342)。

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
| 声卡 | Realtek ALC256 | ⚠️ 能出声，但有破音/断流（见「已知问题」） |
| 网卡 | Intel AX210 (Wi-Fi 6E) | ✅ itlwm + HeliPort |
| 有线网卡 | Realtek RTL8111 | ✅ |
| 蓝牙 | Intel AX210 | ❓ 未验证 |
| 触控板 | I2C HID | ✅ |

## 系统

- macOS 26.7.3 (25G342) / Darwin 25.6.0
- OpenCore 1.0.x
- SMBIOS: `MacBookPro16,2`

## 目录结构

```
EFI/
├── BOOT/
│   └── BOOTx64.efi
└── OC/
    ├── ACPI/        7 个 SSDT（含自定义 AC 修复）
    ├── Drivers/     4 个驱动
    ├── Kexts/       31 个 kext
    ├── Resources/   OpenCanopy 图形界面资源
    ├── Tools/       NullMothSafe.efi
    ├── config.plist                    当前生效配置
    ├── config-installed.plist          显卡驱动装好后的配置
    ├── config-installer.plist          全新安装用（无 nvfb 参数）
    └── config-rollback-noacfix.plist   回滚用（关闭 AC 修复）
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

`SSDT-ADPFIX.aml`（103 字节）把 `_PSR` 改为读取 `IT55.ACIN`（`0xFE700600` 的 byte 64 bit 3），并加了 `_OSI("Darwin")` 判断，Windows 仍走原方法。

配套需要启用 ACPI 补丁 `_PSR → XPSR`（`TableSignature = DSDT`）。

### 3. 无线网卡

两条路线，二选一（`Kernel → Add` 里改 `Enabled`）：

| 方案 | kext | 优点 | 缺点 |
|---|---|---|---|
| **itlwm**（当前启用） | `itlwm.kext` | 不依赖 IO80211，跨版本稳 | 需 HeliPort app，系统设置里看不到 Wi-Fi |
| **AirportItlwm**（当前关闭） | `AirportItlwm.kext` | 原生界面 | 必须匹配系统大版本；控制中心磁贴可能不同步 |

`AirportItlwm` 版本要求 `MinKernel = 25.0.0`（Tahoe）。

### 4. 音频

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
| **内置扬声器破音、播放几秒后静音** | 采样率不匹配：系统默认 44.1 kHz，而 ALC256 layout 7 是按 48 kHz 调校的 | ✅ 已解决，改成 48 kHz 即可（见下） |
| **亮度每次开机都是最大** | NullMoth 驱动会写 `nvram nullmoth-backlight` 但开机不读 | 可用开机脚本兜底（见下） |
| 控制中心 Wi-Fi 磁贴显示"未连接" | AirportItlwm 的 `APPLE80211_IOC` 实现不完整 | 实际联网正常，仅显示问题 |
| 睡眠/唤醒 | 未充分测试 | — |

### 音频：必须把采样率改成 48 kHz

装好系统后**第一件事**：打开「音频 MIDI 设置」→ 选中「内建输出」→ 把「格式」从 `44100 Hz` 改成 `48000 Hz`。

不改成 48 kHz 的表现：
- 音量一调就爆音
- 播放 5–20 秒后突然静音，切歌或重开播放器才恢复

原因：ALC256 在 layout 7 下的时钟是按 48 kHz 配置的，系统默认给 44.1 kHz，采样率不匹配导致重采样溢出 + DMA 缓冲下溢。

> 排查过但**无效**的方向（别浪费时间去试）：
> - 换 layout-id（11 / 13 / 21 / 56 / 69 / 99）——SimpleHDA 只认内嵌的那一套配置，换任何值都会导致设备消失
> - 关闭 AppleALC——`layout-id` 会变成你设的值，但 SimpleHDA 初始化失败，设备直接没了
> - 关闭 `nvrmacpibl` 改善音频——那个参数只管背光，跟音频无关

### 亮度兜底方案

驱动把亮度存在 NVRAM 变量 `nullmoth-backlight`（格式：`02` + 16 位小端亮度），但开机不读回。

可以用 LaunchAgent 在登录时读出来再应用，脚本思路：

```python
# 原理：nvram -x nullmoth-backlight -> data[-2:] 为亮度（LE 16-bit）
# 再调 IOKit 的 IODisplaySetFloatParameter(service, 0, "brightness", level/65535)
```

---

## 首次使用

1. **生成自己的 SMBIOS**

   用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成 `MacBookPro16,2` 的三码：
   ```
   SystemSerialNumber / MLB / SystemUUID
   ```
   填进 `config.plist` → `PlatformInfo → Generic`。

   `ROM` 填你自己网卡 MAC 的前 6 字节十六进制（`SystemPreferences → 网络 → 高级 → 硬件`）。

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

6. **关掉自动登录**（如果有人给你装了 `finish-setup.sh` 之类的脚本）

   那类脚本为了绕过设置向导，会把密码以可逆形式写进 `/etc/kcpassword`。装好后去「系统设置 → 用户与群组 → 自动登录」关掉，并改一次密码。

---

## 引导参数说明

```
-v                                          启动日志（装好系统后可去掉）
keepsyms=1                                  保留内核符号
amfi_get_out_of_my_way=0x1 amfi=0x80        关闭 AMFI 校验
ipc_control_port_options=0
nvfb=1 nvaccel=1 nvfbheads=4                NullMoth 显卡
-nvkmsnosmooth                              NVKMS 不做平滑过渡
nvrmacpibl=1                                走 ACPI 背光（亮度键可用）
itlwm_he=1                                  Intel Wi-Fi 6 (HE) 支持
-ibtcompatbeta                              Intel 蓝牙兼容
revpatch=sbvmm                              CPU 型号伪装
```

---

## 致谢

- [OpenCore](https://github.com/acidanthera/OpenCorePkg) / [Lilu](https://github.com/acidanthera/Lilu) / [AppleALC](https://github.com/acidanthera/AppleALC) / [VirtualSMC](https://github.com/acidanthera/VirtualSMC)
- [NullMoth NVIDIA driver](https://github.com/nullmoth/nvidia-macos-driver)
- [SimpleHDA](https://github.com/laobamac/SimpleHDA) / [AirportItlwm fork](https://github.com/laobamac/itlwm)
- [itlwm](https://github.com/OpenIntelWireless/itlwm) / [HeliPort](https://github.com/OpenIntelWireless/HeliPort)
- [VisualTechStudio](https://github.com/VisualTechStudio/ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI) 的原始 A16 EFI
