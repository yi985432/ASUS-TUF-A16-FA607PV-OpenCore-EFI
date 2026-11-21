# Credits / 来源与许可

## 原始项目

本仓库是以下项目的**衍生作品**：

- **VisualTechStudio / ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI**
  https://github.com/VisualTechStudio/ASUS-TUF-Gaming-A16-2024-CN-OpenCore-EFI

原始 EFI、`SSDT-BATT` 电池实现、OpenCore 基线配置、ACPI 补丁思路均来自原作者 **VisualTechStudio**。
原始部分的版权归原作者所有。本仓库仅在此基础上做针对本人机器的增量适配：

- Intel AX210 Wi-Fi / AirDrop（ForbiddenItlwm）
- AsusSMC 键盘背光（FA607PV 的 ASUS ATK/EC 路径）
- 内置摄像头 USB 端口映射（`XHC0.RHUB.PRT1`）
- NullMoth 屏幕亮度保存修复

本仓库**不是**原作者官方发布，也不代表原作者立场。转发、二次分发或再修改时，请保留本文件与 README 顶部的来源声明，并保留原仓库链接。

## 第三方组件

| 组件 | 用途 | 上游 / 许可 |
|---|---|---|
| OpenCorePkg | 引导器 | https://github.com/acidanthera/OpenCorePkg |
| Lilu | kext 补丁框架 | https://github.com/acidanthera/Lilu |
| VirtualSMC | SMC 模拟 | https://github.com/acidanthera/VirtualSMC |
| AppleALC | 音频 | https://github.com/acidanthera/AppleALC |
| WhateverGreen | 核显/显示补丁（未启用） | https://github.com/acidanthera/WhateverGreen |
| NullMoth NVIDIA driver | RTX 4060 驱动、背光 | https://github.com/nullmoth/nvidia-macos-driver （遵循上游许可，非商业使用） |
| SimpleHDA | macOS 26 HDA 栈 | https://github.com/laobamac/SimpleHDA |
| ForbiddenItlwm | Intel Wi-Fi + AWDL / AirDrop | https://github.com/retropineaple/ForbiddenItlwm （GPL-2.0） |
| BTLEAdvFixup | Intel 蓝牙 LE 广播 | https://github.com/retropineaple/ForbiddenItlwm （GPL-3.0） |
| AsusSMC | ASUS 键盘背光 / ALS / Fn | https://github.com/hieplpvip/AsusSMC （MIT） |
| USBToolBox / UTBMap | USB 端口映射 | https://github.com/USBToolBox/tool |
| VoodooI2C / VoodooI2CHID | I2C 触摸板 | https://github.com/VoodooI2C/VoodooI2C |
| VoodooPS2Controller | PS/2 键盘 / 触摸板 | https://github.com/acidanthera/VoodooPS2 |
| RealtekRTL8111 | 有线网卡 | https://github.com/Mieze/RTL8111_driver_for_OS_X （v3.0.0） |
| RyzenStatus / ryzenstatus-utils | AMD CPU 温度、频率、功耗监控（提供 3.40.3 版 kext 与菜单栏 App） | https://github.com/DrogaBox/ryzenstatus-utils （GPL-3.0） |
| IntelBluetoothFirmware | Intel 蓝牙固件 | https://github.com/OpenIntelWireless/IntelBluetoothFirmware |
| BlueToolFixup | 蓝牙协议栈修正 | https://github.com/acidanthera/BrcmPatchRAM |
| ECEnabler / SMCBatteryManager / SMCAMDProcessor / AMDRyzenCPUPowerManagement / NVMeFix / RestrictEvents / ForgedInvariant / AMFIPass / BrightnessKeys / HibernationFixup / AppleMCEReporterDisabler | 各自功能 | 见对应上游仓库 |

## 许可说明

- 本仓库中的**增量修改**（README、`SSDT-ASUS.dsl`、`tools/fix-nullmoth-backlight.sh`、配置改动）由仓库维护者提供，按原项目相同的使用条件分发。
- 原始 EFI 与 `SSDT-BATT` 的版权归 **VisualTechStudio**。
- 第三方 kext / 二进制遵循各自上游许可证（GPL-2.0、GPL-3.0、MIT、BSD 等）。分发本仓库时请保留对应许可证和上游链接；GPL 组件的源代码请从上游仓库获取。
- `ForbiddenItlwm` / `BTLEAdvFixup` 是实验性内核代码，作者明确提示可能 kernel panic。使用风险自负。
- `NullMoth` 驱动遵循其上游许可（非商业使用），本仓库不再分发其二进制，只提供使用说明和修复脚本。
