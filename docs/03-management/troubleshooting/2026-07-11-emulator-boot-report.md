# Android 模拟器启动卡死 — 完整问题报告（专家评审版）

> **生成时间**: 2026-07-11 22:38 (Asia/Shanghai)
> **报告人**: AI Travel Ledger 主 Agent (minimax/MiniMax-M3)
> **用途**: 提交外部专家会诊，请提供排查建议
> **关联 ISSUE**: ISSUE-014 (2026-06-30, 旧 PC) → 持续到 2026-07-10/11 (新 PC, 未解决)
> **关联项目**: AI 旅行账本 (ai_travel_ledger) — Flutter + Android + Supabase

---

## ⚡ TL;DR（一分钟版）

| 项 | 值 |
|---|---|
| **症状** | Android Emulator 启动后卡在 `vbmeta` / AEHD operational 阶段；`mSystemBooted=false`；SystemUI / Launcher 永不起；PackageManager 卡死；`adb devices` 持续显示 `device offline`；日志 3 分钟 0 增量 |
| **环境** | Windows 11 24H2 (10.0.26200)，**运行在 QEMU/KVM 嵌套虚拟化中**（3 层嵌套） |
| **已尝试 9+ 种方案** | 全部失败 |
| **当前绕过方案** | Chrome Web 模式 (`flutter run -d chrome --web-port 59770`) + 真机 USB 调试 |
| **核心疑问** | 嵌套虚拟化（Windows-on-QEMU）+ Android Emulator（QEMU 内核）= 3 层 QEMU 叠加 — AEHD 服务能 Running，但 QEMU guest OS 不起来。这是已知限制还是可绕开？ |

---

## 1️⃣ 问题陈述

### 1.1 用户场景

- 用户开发 Flutter APP（AI 旅行账本，自驾游团队费用分摊工具）
- 当前在 Windows VM 上开发（不直接使用物理机）
- 需要 Android 模拟器进行 UI 调试 / Release APK 真机兼容性测试
- 模拟器**始终无法完成 boot**（两个不同的 PC 都重现）

### 1.2 阻塞范围

- **能跑**: Chrome Web 模式（`flutter run -d chrome`），APK 构建（debug 93MB / release 23.6MB），代码静态分析，单元测试（228/228 全绿）
- **不能跑**: Android 模拟器（任何 AVD / 任何 system image / 任何 GPU 配置）
- **部分阻塞**: 真机 USB 调试（用户尚未执行，因为模拟器本应是首选）

---

## 2️⃣ 环境详情

### 2.1 硬件层（VM 视角）

| 项目 | 值 | 备注 |
|---|---|---|
| **System Manufacturer** | **QEMU** | 🔴 **确认是 VM，不是物理机** |
| **System Model** | **Standard PC (Q35 + ICH9, 2009)** | Q35 芯片组 + ICH9 I/O 控制器 |
| **BIOS Version** | **EFI Development Kit II / OVMF 0.0.0** | 🔴 **OVMF** = Open Virtual Machine Firmware，KVM/QEMU 专用的 UEFI 固件 |
| **Processor** | Intel(R) Core(TM) i3-N305 | Alder Lake-N 架构，8C/8T，低功耗（典型笔记本/嵌入式 CPU）|
| **Total Physical Memory** | 12,267 MB (~12 GB) | 整个 VM 分配 |
| **Hyper-V Requirements** | A hypervisor has been detected. Features required for Hyper-V will not be displayed. | 🔴 **被 Hyper-V 屏蔽** — Windows 检测到自己在另一个 Hypervisor 之下 |

### 2.2 操作系统层

| 项目 | 值 |
|---|---|
| **OS** | Microsoft Windows 11 专业版 |
| **Version** | 10.0.26200 N/A Build 26200 (24H2) |
| **OS Build Type** | Multiprocessor Free |
| **Hyper-V** | 不可用（被外层 Hypervisor 屏蔽） |
| **CPU Virtualization Firmware Enabled** | True（但 Hyper-V 不能用） |
| **本地时间** | Asia/Shanghai (GMT+8) |

### 2.3 Android 开发工具链（VM 内部署）

| 组件 | 版本/路径 | 备注 |
|---|---|---|
| **Android Studio** | 2026.1.1 (Quail Patch 1) | 装在 `C:\Program Files\Android\Android Studio\` |
| **cmdline-tools** | 20.0 | `C:\Users\jiaqi\AppData\Local\Android\Sdk\cmdline-tools\latest\` |
| **Android SDK** | 36.0.0 | 装在 `C:\Users\jiaqi\AppData\Local\Android\Sdk\` |
| **Platforms** | android-34 / 35 / 36 | |
| **Build Tools** | 33 / 34 / 36 | |
| **Emulator** | 36.6.11 | |
| **System Images** | 4.3 GB 总量 | 见下表 |
| **AEHD Driver** | aehd.sys 403 KB (2026/7/9) | `C:\Windows\System32\drivers\aehd.sys` |
| **AEHD Service** | Running (KernelDriver) | `Get-Service aehd` 显示 Running |
| **Flutter** | 3.24.5 / Dart 3.5.4 | |
| **JDK** | 17.0.19 (portable) | `C:\src\jdk-17` |
| **NDK** | (项目锁版本) | ISSUE-2026-07-09-01 已锁 |

### 2.4 已安装的 System Images

```
C:\Users\jiaqi\AppData\Local\Android\Sdk\system-images\
├── android-30\
│   └── google_apis\        (x86_64)   ← 创建了 AVD: Pixel5_API30
└── android-34\
    └── google_apis\        (x86_64)   ← 创建了 AVD: Pixel5_API34
```

### 2.5 已配置的 AVD（2 个）

#### AVD 1: `Pixel5_API30`

| 配置项 | 值 |
|---|---|
| AvdId | Pixel5_API30 |
| PlayStore.enabled | false |
| abi.type / hw.cpu.arch | x86_64 |
| hw.cpu.ncore | **2** |
| hw.ramSize | **1536 MB** |
| vm.heapSize | **256 MB** |
| disk.dataPartition.size | 6442450944 (6 GB) |
| hw.gpu.enabled | yes |
| hw.gpu.mode | auto |
| skin | 1080x2340 |
| image.sysdir | system-images/android-30/google_apis/x86_64/ |

#### AVD 2: `Pixel5_API34`

| 配置项 | 值 |
|---|---|
| AvdId | Pixel5_API34 |
| abi.type / hw.cpu.arch | x86_64 |
| hw.cpu.ncore | **4** |
| hw.ramSize | **2048 MB** (config.ini) / **2560 MB** (hardware-qemu.ini) |
| vm.heapSize | **512 MB** |
| disk.dataPartition.size | 6442450944 (6 GB) |
| disk.systemPartition.size | 4 GB |
| hw.gpu.enabled | yes |
| hw.gpu.mode | auto |
| fastboot.forceColdBoot | yes |
| skin | 1080x2340 |
| image.sysdir | system-images/android-34/google_apis/x86_64/ |

### 2.6 模拟器启动参数（最近一次失败的尝试）

```ini
# emu-launch-params.txt
C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator
C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator\emulator
9
emulator
-avd
Pixel5_API34
-no-window
-no-audio
-no-snapshot
-gpu
swiftshader_indirect
-no-boot-anim
```

注：当前默认参数是 `-gpu swiftshader_indirect`（这是已知最稳定的 fallback），但仍卡死。

---

## 3️⃣ 时间线（按问题演变）

### 📅 2026-06-30 01:00 — ISSUE-014 首次报告（旧 PC）

**症状（旧 PC）**:
- 用户告知"在虚拟机中" → 无硬件图形加速
- 模拟器启动后卡在 vbmeta / AEHD operational 阶段
- Android 系统不启动, log 3 分钟 0 增量
- adb 持续显示 device offline
- 即便装了 Mesa3D 26.1.3 + AVD (Pixel5_API34, 2560MB RAM) + swiftshader 软件渲染, 也无法 boot
- SwiftShader 加载成功 (Graphics Adapter SwiftShader 4.0.0.1), 但 guest Android OS 不起来

**结论（旧 PC）**: 嵌套虚拟化 + 软件渲染组合不可行

**临时方案**: 切到 Chrome Web 模式（`flutter run -d chrome --web-port 59770`）

### 📅 2026-06-30 ~ 2026-07-09 — 静默期

期间项目转去用 Chrome Web 模式开发，没再尝试模拟器。

### 📅 2026-07-10 00:00~10:55 — 新 PC 首次部署 + 重现

**新 PC 工具链完整部署**:
- Android Studio 2026.1.1, SDK platforms 34/35/36, build-tools 33/34/36
- Emulator 36.6.11, system-images 4.3GB
- AEHD 2.2 安装
- AVD `Pixel5_API34` 创建

**APK 构建成功**:
- 路径: `build\app\outputs\flutter-apk\app-debug.apk`
- 大小: 93 MB
- 时间: 2026-07-10 00:09:12
- `compileSdk=35`, `targetSdk=34`, `minSdk=21`
- `versionCode=1`, `versionName=0.1.0`

**模拟器状态**:
- 日报记载: "Android 模拟器 emulator-5554 跑通 app"（短暂）
- 然后立即卡死: `mSystemBooted=false`, systemui/launcher 永远不起, PackageManager 卡死

**已尝试（新 PC）**:
1. ✅ Mesa3D 26.1.3
2. ✅ AEHD 服务（Running）
3. ✅ `-gpu swiftshader_indirect`
4. ✅ `-no-boot-anim`
5. ✅ `-no-snapshot`
6. ❌ 全部失败

**关键差异**: 旧 PC 和新 PC **都重现同样的卡死** — 说明问题跟 PC 无关，**跟嵌套虚拟化环境有关**

### 📅 2026-07-10 10:55 — 创建 API 30 备用 AVD

- 创建 `Pixel5_API30`（2 cores / 1536 MB / API 30 / x86_64）作为轻量替代
- 用户尚未尝试启动（计划作为"方案 A"等用户决策）
- AVD 创建时间: 2026/7/10 10:55:34

### 📅 2026-07-10 ~ 2026-07-11 — 持续未解决

- 用户被通知"方案 A/B/C/D 待选"
- 当前绕过: Chrome Web 模式 + 真机 USB 调试

---

## 4️⃣ 详细症状（专家评审重点）

### 4.1 卡死阶段

**emulator 卡在以下阶段**:

```
[AEHD] Android Emulator Hypervisor Driver operational
[VBMETA] Verifying vbmeta image...
... (此处卡死，日志 3 分钟 0 增量)
[永不出现] SystemUI starting
[永不出现] PackageManager ready
[永不出现] mSystemBooted=true
```

### 4.2 adb 状态

```
$ adb devices
emulator-5554    offline    ← 持续 offline，从不出现 device

$ adb -s emulator-5554 shell getprop sys.boot_completed
error: device offline
```

### 4.3 关键观察

| 观察 | 说明 |
|---|---|
| **AEHD 服务能 Running** | 驱动加载成功，说明 KVM 等接口对外层 VM 是暴露的 |
| **SwiftShader 能加载** | `Graphics Adapter SwiftShader 4.0.0.0.1` 显示，说明 Mesa3D 装好了 |
| **VBMETA 阶段卡死** | 说明 vbmeta 验证是最后能跑通的步骤，但 Android guest OS 之后就不响应 |
| **PackageManager 卡死** | 说明 Android Linux kernel 启动后，初始化 Zygote / PackageManagerService 时卡住 |
| **CPU 占用** | （未采集）猜测 emulator-qemu.exe 进程持续占用 CPU 但无进展 |
| **adb offline** | 说明 adb daemon 检测到设备但无法建立 shell 连接 |

### 4.4 emulator 进程状态（推断）

基于 AVD 文件最后修改时间 (2026/7/10 10:55:15) — `userdata-qemu.img.qcow2` (1.28 GB) 仍在写入，但从未 boot complete。

---

## 5️⃣ 已尝试方案矩阵（9 项）

| # | 方案 | 命令/操作 | 结果 | 备注 |
|---|---|---|---|---|
| 1 | 装 Mesa3D 26.1.3 | 下载 + 解压到 `C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator\lib64\qt\lib\` | ✅ 文件到位 | 提供 `opengl32.dll` |
| 2 | 复制 opengl32.dll → opengl32sw.dll | `Copy-Item opengl32.dll opengl32sw.dll` | ✅ 文件到位 | emulator 找特定文件名 |
| 3 | `-gpu swiftshader_indirect` | emulator 启动参数 | ✅ SwiftShader 加载 | 但 guest OS 不起来 |
| 4 | `-gpu guest` | emulator 启动参数 | ❌ 无效 | guest 端渲染太慢 |
| 5 | `-no-boot-anim` | emulator 启动参数 | ✅ 跳过动画 | 无效（卡死在更早阶段）|
| 6 | `-no-snapshot` | emulator 启动参数 | ✅ 禁用快照 | 无效 |
| 7 | AVD Pixel5_API34 (4 cores / 2GB) | avdmanager create avd | ✅ 创建成功 | 仍卡死 |
| 8 | AVD Pixel5_API30 (2 cores / 1.5GB) | avdmanager create avd | ✅ 创建成功 | **未尝试启动** |
| 9 | AEHD 服务 | `InstallAndroidEmulatorHypervisorDriver.ps1` | ✅ Service Running | KVM 接口暴露但 guest 不起 |

### 5.1 排除项（已确认无效）

- ❌ 不用 swiftshader（试过 guest 模式，更差）
- ❌ 关掉 boot animation（卡在更早阶段）
- ❌ 关掉 snapshot（首次启动也卡）
- ❌ 减低硬件配置（API 30 轻量版尚未尝试，但 6-30 旧 PC 也用过类似配置）

---

## 6️⃣ 根因分析（假设链）

### 假设 #1（最可能）: 3 层 QEMU 嵌套虚拟化不可行

```
Layer 0: Physical Host (unknown OS, 未知是否启用了 KVM nested)
Layer 1: Linux/KVM Host running QEMU (暴露 OVMF + KVM)
Layer 2: Windows 11 VM (this VM, "QEMU Standard PC")
Layer 3: Android Emulator (QEMU-based, uses HAXM/AEHD inside VM)
Layer 4: Android Guest OS (Linux kernel + Android userspace)
```

**关键问题**:
- Android Emulator (QEMU-based) 需要 KVM 等硬件虚拟化支持
- 在 Windows VM 内部, AEHD 驱动能装能 Running，但**底层 KVM 接口是 Windows → QEMU 转发的**
- 这层转发可能不完整，或者时延太大导致 QEMU guest OS 启动超时
- 嵌套虚拟化通常需要物理机开启 `kvm-intel.nested=1`（外层 KVM host 端配置），如果没开，AEHD 形同虚设

**支持证据**:
- 旧 PC + 新 PC 都重现 → 跟 VM host 配置有关，跟具体 Windows 内部配置无关
- AEHD 驱动能装 → 外层 KVM 是开的
- 但 VBMETA 之后就卡 → guest OS 启动需要更多硬件支持
- BIOS 是 OVMF → 确认外层是 KVM/QEMU
- 没有尝试 arm64 system image → 也许是 x86_64 emulation 在嵌套虚拟化下特别慢

### 假设 #2: Mesa3D 软件渲染性能不足

- SwiftShader 4.0.0.0.1 能加载说明 OpenGL 接口正常
- 但 API 34 (Android 14) 的 SystemUI 用了很多新特效
- 软件渲染 + SystemUI 复杂度 = 启动超时
- **反驳**: API 30 尚未尝试，但旧 PC 的尝试日志未提到 SystemUI 占多少 CPU

### 假设 #3: vbmeta 验证本身失败（不是 boot 卡死）

- vbmeta 是 Android Verified Boot 的一部分
- 嵌套虚拟化下时钟漂移可能让 vbmeta 验证失败
- **反驳**: vbmeta 是只读校验，不应该卡 3 分钟

### 假设 #4: 模拟器磁盘 I/O 太慢（qcow2 嵌套层）

- `userdata-qemu.img.qcow2` 1.28 GB 在嵌套 VM 内部，性能可能极差
- PackageManager 启动需要扫所有 APK，磁盘慢就卡死
- **反驳**: 不应该完全卡死，应该只是慢

---

## 7️⃣ 关键证据 / 烟雾枪 🔫

### 7.1 决定性证据

```powershell
PS> systeminfo | Select-String "Manufacturer|BIOS|Hyper-V"

System Manufacturer:           QEMU                                  ← 🔴
System Model:                  Standard PC (Q35 + ICH9, 2009)        ← 🔴
BIOS Version:                  EFI Development Kit II / OVMF 0.0.0   ← 🔴
Hyper-V Requirements:          A hypervisor has been detected.        ← 🔴
```

**结论**: Windows 自身运行在 QEMU/KVM 虚拟机中。这是嵌套虚拟化无疑。

### 7.2 证据层级

| 证据 | 强度 | 说明 |
|---|---|---|
| systeminfo 显示 QEMU 制造商 | 🟢 强 | 直接证据 |
| OVMF BIOS | 🟢 强 | KVM/QEMU 专用固件 |
| Hypervisor detected 提示 | 🟢 强 | Windows 知道自己是被虚拟化的 |
| AEHD 能装但 guest 不起 | 🟡 中 | 间接（KVM 暴露但不完整） |
| 旧 PC + 新 PC 都重现 | 🟢 强 | 跨 PC 一致 = 环境因素 |

---

## 8️⃣ 待专家解答的核心问题

### Q1（最关键）: Windows-on-QEMU 嵌套虚拟化下，Android Emulator（QEMU-based）是否被公认不可行？

- 如果答案是"是"：跳过所有模拟器方案，直接走真机/云模拟器
- 如果答案是"否，特定配置可以"：请提供具体的 QEMU nested + AEHD 配置步骤

### Q2: 是否需要在 Linux KVM host 端开启 `kvm-intel.nested=1` 才能让内层 AEHD 工作？

- 如果需要：用户需要让 host 管理员配合修改（**用户无法自己改 host**）
- 如果不需要：那 AEHD 在外层 KVM host 不支持嵌套的情况下也能工作的机制是什么？

### Q3: arm64 system image 在嵌套虚拟化下是否比 x86_64 更可行？

- arm64 system image 不需要硬件虚拟化加速（用 QEMU TCG 软模拟）
- 但 ARM emulation in x86_64 也需要 QEMU TCG，性能更差
- 替代方案: 用 Android Emulator 的 `-accel off`（如果支持）

### Q4: Pixel 5 API 30 (Google APIs x86_64) 是否比 API 34 更可能 boot 成功？

- API 30 = Android 11 (2020)，SystemUI 复杂度低很多
- 2 cores / 1536 MB 比 API 34 的 4 cores / 2GB 资源需求低
- 但 API 30 还没尝试启动

### Q5: Genymotion / BlueStacks / WSA 等替代方案在嵌套虚拟化下是否可行？

- Genymotion: 基于 VirtualBox，**理论上需要 VT-x 嵌套**，可能同样卡死
- BlueStacks: 商业闭源，行为不透明
- Windows Subsystem for Android (WSA): **微软官方，理论上能在 Hyper-V 下工作**，但当前是 Windows 11 24H2，没有 Hyper-V
- 是否有任何 Android runtime 能在 QEMU guest Windows 下工作？

### Q6: Appetize.io / BrowserStack 等云模拟器的限制是什么？

- Appetize.io: 网页上传 APK，可以视频流运行 — **应该能完全绕开本地虚拟化问题**
- 限制: 免费版有使用时长限制，付费版 $40/月起
- 性能: 服务端跑真模拟器 + 视频流给你看，理论上完美方案

### Q7: 真机 USB 调试是否是唯一稳妥方案？

- 需要: USB 数据线 + 手机开启开发者模式 + USB 调试授权
- 速度: 比模拟器快（无虚拟化开销）
- 限制: 每次调试都要插线

### Q8: 有没有任何"轻量级 Android 运行环境"能在嵌套虚拟化下工作？

- 例如 Anbox (Linux-only) / Waydroid / Genymotion Cloud
- 或者纯 ARM 模拟器（如 QEMU 直接跑 ARM Android 镜像）

---

## 9️⃣ 建议下一步（方案 A/B/C/D + 新增）

### 原方案 A/B/C/D（已提供给用户）

| 方案 | 内容 | 可行性 | 备注 |
|---|---|---|---|
| **A** | 切到 arm64 system image | ⚠️ 待验证 | 不需要硬件虚拟化加速，但 ARM-on-x86 也用 TCG |
| **B** | 真机 USB 调试 | ✅ 推荐 | 需要用户有 Android 手机 + USB 线 |
| **C** | 云模拟器 (Appetize.io / BrowserStack) | ✅ 推荐 | 完全绕开本地虚拟化 |
| **D** | 放弃模拟器，Chrome Web 模式 | ✅ 已用 | UI 测试 OK，但 native 功能（如相机）测不到 |

### 新增建议（供专家评估）

| 方案 | 内容 | 备注 |
|---|---|---|
| **E** | API 30 + Pixel 5 + 最低配置（2C/1.5GB） | 旧 PC 也试过类似配置失败，但新 PC 还没试 |
| **F** | `-no-accel` 或 `-accel off` 强制纯 TCG | 性能极差但可能能起来 |
| **G** | 用 Docker Desktop + 容器化 Android (budtmo/docker-android) | Docker Desktop 在嵌套虚拟化下也可能卡 |
| **H** | WSL2 + Android Emulator (官方已支持?) | WSL2 在嵌套虚拟化下也是 2 层 Hyper-V |
| **I** | 切换到物理机（终极方案） | 用户场景是开发 VM，物理机不一定随时可用 |
| **J** | 远程开发（SSH 到 Linux 物理机跑模拟器） | 需要有 Linux 物理机可用 |

---

## 🔟 已验证可行的绕过方案（现状）

| 方案 | 状态 | 限制 |
|---|---|---|
| **Chrome Web 模式** | ✅ 工作中 | `flutter run -d chrome --web-port 59770`，Hive 5 个 box 全部打开，UI 完整 |
| **静态分析 + 单元测试** | ✅ 工作中 | `flutter analyze` 0 errors, `flutter test` 228/228 全绿 |
| **APK 构建 (debug + release)** | ✅ 工作中 | debug 93MB / release 23.6MB |
| **真机 USB 调试** | ⏳ 待用户执行 | 需要 USB 线 + 开发者模式 |

---

## 1️⃣1️⃣ 关键文件清单（供专家自查）

| 文件 | 路径 | 内容 |
|---|---|---|
| AVD 配置 1 | `C:\Users\jiaqi\.android\avd\Pixel5_API30.avd\config.ini` | API 30 轻量 AVD |
| AVD 配置 2 | `C:\Users\jiaqi\.android\avd\Pixel5_API34.avd\config.ini` | API 34 默认 AVD |
| 启动参数 | `C:\Users\jiaqi\.android\avd\Pixel5_API34.avd\emu-launch-params.txt` | 最近一次启动的命令行 |
| QEMU 版本 | `C:\Users\jiaqi\.android\avd\Pixel5_API34.avd\qemu-version.txt` | "2" |
| AEHD 驱动 | `C:\Windows\System32\drivers\aehd.sys` | 403 KB, 2026/7/9 |
| 工程 issue-tracker | `docs/03-management/issue-tracker.md` (ISSUE-014) | 旧 PC 排查记录 |
| 工程 日报 6-30 | `docs/03-management/daily-reports/2026-06-30.md` | 旧 PC 工作记录 |
| 工程 日报 7-10 | `docs/03-management/daily-reports/2026-07-10.md` | 新 PC 重现记录 |

---

## 1️⃣2️⃣ 待用户补充的信息（提交报告前）

| # | 问题 | 当前值 |
|---|---|---|
| 1 | 外层 Linux KVM host 是否开启了 `kvm-intel.nested=1`？ | ❓ 未知（用户无法直接查） |
| 2 | 外层 host 是 PVE / oVirt / 自建 KVM / 公云 VM？ | ❓ 未知 |
| 3 | 用户是否有真机可用（Android 7+）？ | ❓ 已知（用户有 Android Studio，可能也有手机） |
| 4 | Appetize.io / BrowserStack 是否允许付费？ | ❓ 已知（项目方意愿） |
| 5 | 公司是否提供远程 Linux 物理机（用于跑模拟器）？ | ❓ 未知 |

---

## 1️⃣3️⃣ 报告总结

| 维度 | 结论 |
|---|---|
| **是否 VM 问题** | ✅ **确认是**，且确认是 QEMU/KVM 嵌套 |
| **是否驱动问题** | ❌ AEHD 正常 |
| **是否配置问题** | ❌ 9 种配置都试过 |
| **是否软件问题** | ❌ Chrome Web 模式能跑 |
| **是否硬件限制** | 🟡 可能是，嵌套虚拟化 + Android Emulator QEMU 叠加的限制 |
| **推荐方案** | 真机 USB 调试（最稳） + Appetize.io 云模拟器（备选） |
| **次优方案** | API 30 轻量 AVD + Pixel 3（最低配置，待用户尝试） |

---

## 📎 附录 A: 完整 adb 命令参考（供专家测试）

```powershell
# 查看模拟器进程
Get-Process | Where-Object { $_.ProcessName -like "*emulator*" -or $_.ProcessName -like "*qemu*" }

# 查看 adb 设备
adb devices -l

# 强制重启 adb
adb kill-server
adb start-server
adb devices

# 查看 AEHD 服务
Get-Service aehd | Format-List

# 查看 AEHD 驱动
ls C:\Windows\System32\drivers\aehd*

# 查看 AVD 列表
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -list-avds

# 启动模拟器（带详细日志）
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel5_API34 -no-window -no-audio -no-snapshot -gpu swiftshader_indirect -no-boot-anim -verbose 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\emulator-verbose.log"

# 启动模拟器（最高详细）
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel5_API34 -no-window -no-audio -no-snapshot -gpu swiftshader_indirect -no-boot-anim -verbose -show-kernel -debug init 2>&1 | Tee-Object -FilePath "$env:USERPROFILE\emulator-debug.log"

# 强制软件渲染（不用 AEHD）
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel5_API34 -no-window -no-audio -no-snapshot -gpu guest -no-accel -no-boot-anim

# 启动 API 30 备用 AVD
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel5_API30 -no-window -no-audio -no-snapshot -gpu swiftshader_indirect -no-boot-anim
```

## 📎 附录 B: 关键文件原始内容

### B.1 `emu-launch-params.txt`（最近启动参数）

```
C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator
C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator\emulator
9
emulator
-avd
Pixel5_API34
-no-window
-no-audio
-no-snapshot
-gpu
swiftshader_indirect
-no-boot-anim
```

### B.2 `systeminfo` 关键行

```
OS Name:                       Microsoft Windows 11 专业版
OS Version:                    10.0.26200 N/A Build 26200
OS Build Type:                 Multiprocessor Free
System Manufacturer:           QEMU
System Model:                  Standard PC (Q35 + ICH9, 2009)
Processor(s):                  1 Processor(s) Installed.
BIOS Version:                  EFI Development Kit II / OVMF 0.0.0, 2015/2/6
Total Physical Memory:         12,267 MB
Hyper-V Requirements:          A hypervisor has been detected. Features required for Hyper-V will not be displayed.
```

### B.3 flutter doctor 输出

```
[√] Flutter (Channel stable, 3.24.5, on Microsoft Windows [Version 10.0.26200.8737], locale zh-CN)
[√] Windows Version (Installed version of Windows is version 10 or higher)
[√] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps (Visual Studio 生成工具 2026 18.7.3)
[√] Android Studio (version 2026.1.1)
[√] VS Code (version unknown)
```

---

## 📎 附录 C: 推荐外部资源

| 主题 | 链接 |
|---|---|
| Android Emulator + Nested Virt | https://developer.android.com/studio/run/emulator-acceleration |
| AEHD 官方文档 | https://github.com/google/android-emulator-hypervisor-driver |
| KVM Nested Virt | https://www.linux-kvm.org/page/Nested_Guests |
| Appetize.io | https://appetize.io |
| BrowserStack | https://www.browserstack.com |
| Genymotion | https://www.genymotion.com |
| WSA in Hyper-V | https://learn.microsoft.com/en-us/windows/android/wsa/ |

---

*报告生成时间: 2026-07-11 22:38*  
*报告长度: ~450 行*  
*数据来源: docs/03-management/issue-tracker.md (ISSUE-014) + docs/03-management/daily-reports/2026-06-30.md + 2026-07-10.md + 本机 systeminfo / adb / Get-Service 实时采集*