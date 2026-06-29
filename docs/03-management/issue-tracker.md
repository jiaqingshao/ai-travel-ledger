

### 🔧 ISSUE-013 — PM 进度报告严重失真(报告 0% 实际 75%)【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-013 |
| **等级** | P1 严重 |
| **模块** | PM Agent 工作规范 |
| **报告时间** | 2026-06-29 23:29 |
| **报告人** | 用户质疑 + PM 自报 |
| **修复时间** | 2026-06-30 00:46 |
| **修复人** | PM |
| **状态** | 🔧 部分修复(根因分析完成, 永久方案实施中)|

**症状**:
- PM 在 23:03 之前多次报告 "Phase 2 = 0%"
- 用户 23:29 质疑"代码还没开始?"
- PM 扫描后: lib/ 39 Dart 文件 (5 模型 + 5 仓库 + 11 屏幕 + 2 引擎 + 2 数据源 + 1 seed), test/ 13 测试文件
- 真实: **Phase 2 = 75%** (非 0%), **Phase 1 = 90%** (非 80%)

**根因**:
1. **主观估算代替客观验证**: 未执行 git log --stat / ls lib/
2. **历史记忆污染**: 6/14 讨论路径时脑补"代码还没开始", 此后基于错误前提
3. **未建立"汇报基于事实"规则**: SOUL.md 无强制验证要求

**教训**:
- 🚨 PM 不能凭印象判断项目进度 —— 必须用工具验证
- 🚨 历史记忆可能过期, 项目每天演进
- 🚨 "快速回答" ≠ "准确回答", **10 秒验证 > 10 分钟脑补**

**永久方案**(已实施 + 进行中):
1. ✅ PM 23:29 承认失职 + 修正数字
2. ✅ ISSUE-013 记录(本条)
3. 🔧 PM SOUL.md §7「进度汇报铁律」新增
4. 🔧 daily-reports/README 加「数据来源」章节
5. ⏳ 6/30 日报需基于验证命令,非凭记忆

**下次汇报检查表**:
- [ ] git log --oneline -20
- [ ] Get-ChildItem lib -Recurse | Measure-Object
- [ ] Get-ChildItem test -Recurse -File
- [ ] lutter analyze --no-fatal-infos
- [ ] lutter test



### ⚠️ ISSUE-014 — Windows VM 中无法启动 Android 模拟器【未解决】

| 字段 | 值 |
|---|---|---|
| **Issue ID** | ISSUE-014 |
| **等级** | P2 一般 |
| **模块** | Android 开发环境 / 模拟器 |
| **报告时间** | 2026-06-30 01:00 (凌晨调试开始) |
| **报告人** | PM 自报 (用户告知在虚拟机) |
| **当前状态** | ⏳ 未解决 (VM 嵌套虚拟化 + 无硬件 GPU, Pixel 5 API 34 无法 boot) |

**症状**:
- 用户告知"在虚拟机中" → 无硬件图形加速
- emulator 启动后卡在 vbmeta / AEHD operational 阶段
- Android 系统不启动, log 3 分钟 0 增量
- adb 持续显示 device offline
- 即便装了 Mesa3D 26.1.3 (opengl32.dll + opengl32sw.dll) + AVD (Pixel5_API34, 2560MB RAM) + swiftshader 软件渲染, 也无法 boot
- SwiftShader 加载成功 (Graphics Adapter SwiftShader 4.0.0.1), 但 guest Android OS 不起来

**已尝试方案**:
1. ✅ 装 Mesa3D 26.1.3 (提供 opengl32.dll) → C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator\lib64\qt\lib\
2. ✅ 复制 opengl32.dll → opengl32sw.dll (emulator 找这个特定文件名)
3. ✅ 用 -gpu swiftshader_indirect 强制软件渲染
4. ✅ 用 -gpu guest 纯 guest 端渲染
5. ✅ 用 -no-boot-anim 跳过 boot animation
6. ✅ 用 -no-snapshot 禁用快照加速
7. ✅ AVD 已建 (Pixel5_API34, Android 14, x86_64, 2560MB)
8. ✅ AEHD 服务 Running (Android Emulator Hypervisor Driver)
9. ❌ 所有方案 emulator-5554 始终 offline

**根因(推断)**:
- 用户的 Windows 是 VM (嵌套虚拟化)
- VM 内启动 Android Emulator = 三层虚拟化 (VM→VM→Android)
- 即便硬件 GPU 透传, Android Emulator 在嵌套虚拟化下仍极慢或卡住
- 软渲染 + 复杂 API 34 镜像组合不可行

**后续选项**:
- 选项 A: 用更轻量镜像 (API 30 + Pixel 3 + x86), 资源需求低得多
- 选项 B: 真机 USB 调试
- 选项 C: 云模拟器 (Appetize.io / BrowserStack)
- 选项 D: 放弃模拟器, 直接用 Chrome Web 模式继续开发 (推荐, 已在 59770 跑)

**临时方案** (实施):
- ✅ Flutter run -d chrome --web-port 59770 持续运行 (59770/61576 端口监听中)
- ✅ Hive 5 个 box 全部打开成功
- ✅ 5 次启动+boot 测试, 1 次 screenshot 验证 UI 正常显示

**教训**:
- 🚨 启动模拟器前必须先确认用户是否在 VM 中
- 🚨 嵌套虚拟化 + 软件渲染组合基本不可行, 不要尝试超过 1 小时
- 🚨 应直接给出备选方案 (Chrome Web 模式 / 真机 / 云), 让用户选

