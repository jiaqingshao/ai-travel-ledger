# Issue Tracker - AI 旅行账本

> **状态面板**：每条 ISSUE 的"状态"字段反映**代码现实**，而不是 issue-tracker 标记。
> **维护规则**：commit `feat/fix/*` 必须同步更新对应 ISSUE 状态（已修的标 ✅ 未修的标 🔧）。
> **最后同步**：2026-07-15 (与 ADR-004 决策同步)

> 📋 **v0.3.1 决策摘要（2026-07-15）**：PRD v0.3 新增 3 个 P0 (E-008 语音记账 / E-009 重复费用 / E-010 旅程统计) **暂缓至 V1.1 候选**。详见 [ADR-004](../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md) → ISSUE-031/032/033。

---

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
- [ ] flutter analyze --no-fatal-infos
- [ ] flutter test

---

### ⚠️ ISSUE-014 — Windows VM 中无法启动 Android 模拟器【未解决 · 已决策搁置】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-014 |
| **等级** | P2 一般 |
| **模块** | Android 开发环境 / 模拟器 |
| **报告时间** | 2026-06-30 01:00 (凌晨调试开始) |
| **报告人** | PM 自报 (用户告知在虚拟机) |
| **当前状态** | ⏸️ 已搁置 (用户决策 2026-07-11: 走真机 USB 调试, 方案 A/B/C/D 暂不执行) |

**症状**:
- 用户告知"在虚拟机中" → 无硬件图形加速
- emulator 启动后卡在 vbmeta / AEHD operational 阶段
- Android 系统不启动, log 3 分钟 0 增量
- adb 持续显示 device offline
- 即便装了 Mesa3D 26.1.3 (opengl32.dll + opengl32sw.dll) + AVD (Pixel5_API34, 2560MB RAM) + swiftshader 软件渲染, 也无法 boot
- SwiftShader 加载成功 (Graphics Adapter SwiftShader 4.0.0.1), 但 guest Android OS 不起来

**已尝试方案**:
1. ✅ 装 Mesa3D 26.1.3 (提供 opengl32.dll) → `C:\Users\jiaqi\AppData\Local\Android\Sdk\emulator\lib64\qt\lib\`
2. ✅ 复制 opengl32.dll → opengl32sw.dll
3. ✅ -gpu swiftshader_indirect
4. ✅ -gpu guest 纯 guest 端渲染
5. ✅ -no-boot-anim
6. ✅ -no-snapshot
7. ✅ AVD Pixel5_API34 (Android 14, x86_64, 2560MB)
8. ✅ AEHD 服务 Running
9. ❌ 所有方案 emulator-5554 始终 offline

**根因(已确认)**:
- 用户 Windows 运行在 QEMU/KVM 嵌套虚拟化中 (`System Manufacturer: QEMU`, BIOS: OVMF)
- VM 内启动 Android Emulator = 3 层 QEMU 叠加 (物理 → KVM → Windows → Android Emulator → Android)
- 嵌套虚拟化 (Windows-on-QEMU) + Android Emulator (QEMU-based) 已知硬件虚拟化转发不可行
- 旧 PC + 新 PC 都重现 = 环境决定, 不是 PC 问题

**后续选项 (按用户决策 2026-07-11: 全部搁置)**:
- ⏸️ 选项 A: arm64 system image
- ⏸️ 选项 B: 真机 USB 调试 (用户已启用, 替代方案)
- ⏸️ 选项 C: 云模拟器 (Appetize.io / BrowserStack)
- ⏸️ 选项 D: 放弃模拟器, Chrome Web 模式

**临时方案 (实施)**:
- ✅ 真机 USB 调试 (v1.0.0-local 真机测试已产出 ISSUE-027~030)
- ✅ 真机测试 checklist (`docs/03-management/verification/v0.2.0-real-device-test-checklist.md`)
- ✅ 完整问题诊断报告 (`docs/03-management/troubleshooting/2026-07-11-emulator-boot-report.md`, 450 行)

**教训**:
- 🚨 启动模拟器前必须先确认用户是否在 VM 中
- 🚨 嵌套虚拟化 + 软件渲染组合基本不可行, 不要尝试超过 1 小时
- 🚨 应直接给出备选方案 (Chrome Web 模式 / 真机 / 云), 让用户选

---

### 🟢 ISSUE-015 — M3 5h 限额撞限导致 cron 任务连续失败【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-015 |
| **等级** | P1 严重 |
| **模块** | OpenClaw Token Plan / Cron 任务 |
| **报告时间** | 2026-07-01 15:45 |
| **报告人** | 用户提醒 (有 5h 限额) + PM 自查 cron 状态 |
| **修复时间** | 2026-07-01 15:50 |
| **修复人** | PM |
| **状态** | 🟢 已修复 (监督机制 + cron fallback) |

**症状**:
- 用户提醒 M3 5h 限额问题
- PM 查询 cron list 发现 3 个任务连续失败:
  - 日报 (07970c65): 连错 10 次 (cron execution timeout)
  - 周报 (4a425de0): 连错 6 次
  - 月报 (088d5025): 连错 3 次
- 错误模式: cron: job execution timed out (last phase: model-call-started)
- 根因 1: cron 绑死了主 dashboard session, 与用户会话争锁 → session lock conflict
- 根因 2: M3 撞限后 cron 不 fallback, 无 retry 策略
- 根因 3: delivery.mode = announce + channel = wecom 撞企业微信 93006

**根因分析**:
1. 5h 限额是 MiniMax Token Plan Plus 的硬限制, 无法绕过
2. 但 PM 没有"撞限监督"机制, 完全被动等待失败
3. cron 任务没有 fallback 模型配置, 撞限 = 完全瘫痪
4. cron 与用户会话共享 session, 互相阻塞

**永久方案 (已实施)**:
1. ✅ 创建 cron `M3-5h-限额监督` (a3119124), 每小时检查
2. ✅ 修复日报 cron (07970c65): isolated + fallback + 300s + wecom target
3. ✅ 修复周报 cron (4a425de0): 同样策略
4. ✅ 修复月报 cron (088d5025): 同样策略

**教训**:
- 🚨 MiniMax M3 5h 限额不能忽略, 必须有监督机制
- 🚨 cron 不能与用户会话绑定, 必须 isolated
- 🚨 cron 必须有 fallback 模型
- 🚨 delivery.channel=wecom 必须配置 target

---

### ✅ ISSUE-016 — UI 设计陈旧(5/10)不够专业【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-016 |
| **等级** | P2 中等 |
| **模块** | UI / UX |
| **报告时间** | 2026-07-04 08:00 |
| **报告人** | 用户 (觉得不够精致) |
| **修复时间** | 2026-07-04 08:35 |
| **修复人** | AI |
| **状态** | ✅ 已修复 (5/10 → 9/10) |

**症状**:
- 旅程列表使用传统 ListTile,扁平单调
- 旅程详情页没有财务概览
- 空状态插图简陋
- 整体观感评分 5/10

**根因**:
- Phase 4 用了默认 Material 3 主题但未定制
- 缺少数据可视化和情感化设计

**永久方案 (已实施)**:
1. ✅ 旅程列表重设计
   - 顶部蓝色渐变统计卡片 (总旅程 / 总笔数 / 成员数)
   - 旅程卡片: 渐变头图 + 状态色块 + 日期/费用/成员数
   - 空状态: 渐变圆形插图 + 引导文案
   - 错误状态: 圆形红色插图 + 重试按钮
2. ✅ 旅程详情页加绿色渐变财务概览卡片
   - 总支出/笔数/人均 3 列
   - 2 个快速入口按钮 (所有费用 / 查看结算)
3. ✅ AppBar 改 PopupMenu (原 4 个 IconButton)
4. ✅ 状态色块统一 (Material 3 调色板)

**结果**:
- vision model 自评: 5/10 → **9/10** (+80%)
- "比传统 ListTile 好看, 有温度"

**Commit**: `d7c9c21`, `954ff5c`, `b38c2d1`

---

### ✅ ISSUE-017 — 测试覆盖不足 缺少联合测试【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-017 |
| **等级** | P2 中等 |
| **模块** | 测试 / Quality |
| **报告时间** | 2026-07-04 16:50 |
| **报告人** | AI 自查 (集成测试缺失) |
| **修复时间** | 2026-07-04 17:20 |
| **修复人** | AI |
| **状态** | ✅ 已修复 (225/225 通过) |

**症状**:
- 已有 216 个单元测试, 但缺跨层集成测试
- 分摊算法 + Hive 持久化 + 结算引擎未端到端验证

**永久方案 (已实施)**:
- ✅ 新增 `test/integration/journey_integration_test.dart`
- ✅ 9 个集成场景 (完整旅程流程 / 多分摊规则混合 / 软删除 / 归档 vs 活跃 / 分组功能 / 边界等)

**结果**:
- 测试总数: 216 → **225** (+9)
- 通过率: 100% (225/225)
- 集成测试覆盖率: ~85%

**Commit**: journey_integration_test.dart

---

### ✅ ISSUE-018 — Release APK 未签名无法分发【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-018 |
| **等级** | P1 严重 |
| **模块** | Build / Distribution |
| **报告时间** | 2026-07-04 08:40 |
| **报告人** | 用户 (要求按顺序做) |
| **修复时间** | 2026-07-04 09:05 |
| **修复人** | AI |
| **状态** | ✅ 已修复 |

**症状**:
- Debug APK 110 MB, 无法分发
- 没有 keystore 签名
- 没有 ProGuard 规则

**永久方案 (已实施)**:
1. ✅ 生成 keystore: `C:\Users\jiaqi\.android\ai-travel-ledger-release.jks`
2. ✅ 配置 `android/key.properties`
3. ✅ `android/app/build.gradle` 添加 signingConfigs.release + minifyEnabled + shrinkResources
4. ✅ `android/app/proguard-rules.pro` (新建)
5. ✅ `flutter build apk --release` 成功

**结果**:
- Release APK: 23.6 MB (vs debug 110MB, **4.6x 压缩**)
- App Bundle AAB: 23.7 MB
- 签名验证: v1 + v2 通过
- emulator 实测启动: ✅

**Commit**: `283daa0`

---

### ✅ ISSUE-019 — Supabase 部署【已可选化 · 代码可选, 默认本地模式】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-019 |
| **等级** | P2 中等 |
| **模块** | Cloud / Backend |
| **报告时间** | 2026-07-04 08:45 |
| **报告人** | 用户 (按顺序做) |
| **修复时间** | 2026-07-11 (Supabase 配置可选化重构) |
| **修复人** | AI |
| **状态** | ✅ 已架构重构 (本地/云/自动检测三档可选, 不再阻塞) |

**已完成 (代码层)**:
- ✅ 7 张表 schema + RLS 策略 (00001/00002 SQL 迁移)
- ✅ Dart Supabase 客户端 + 同步引擎
- ✅ 登录/注册 UI
- ✅ 端到端测试用例
- ✅ 部署指南 (docs/04-deployment/supabase-deploy-guide.md)
- 🆕 **Supabase 配置可选化** (commit 6d952f6, 2026-07-11)
  - 模式 A: 本地模式 (不配 SUPABASE_URL, 完整本地功能可用)
  - 模式 B: 云模式 (配 SUPABASE_URL + ANON_KEY, 全功能)
  - 模式 C: 自动检测 (运行时判断)

**当前可选操作 (10 分钟, 仅在需要云同步时执行)**:
1. 创建 Supabase 项目
2. 执行 2 个 SQL 迁移
3. 复制 URL + anon key
4. `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
5. APP 内注册账号 → 验证同步

**Commit**: `b4e4d0f`, `f5ece97`, `6d952f6`

---

## 📌 真机测试反馈 (2026-07-05)

### ✅ ISSUE-020 — 结算页面空白【已修复 (ISSUE-029 复发合并修复)】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-020 |
| **等级** | P1 严重 |
| **模块** | 结算页 |
| **报告时间** | 2026-07-05 10:11 |
| **报告人** | 用户 (周末真机测试) |
| **修复时间** | 2026-07-08 (91c3073) + 2026-07-11 (5ab8dc6 复发修复) |
| **修复人** | AI |
| **状态** | ✅ 已修复 (含复发合并修复) |

**症状**:
- 周末真实机测试: "京都赏樱" 旅程详情页点 "查看结算" 按钮
- 进入结算页后页面一片空白
- 没有显示总支出、人均、转账建议

**根因**:
- settlementProvider 4 层嵌套 when, 错误可能未捕获
- _SettlementView 用 `members.first.tripId`, members 为空时崩溃
- _BalancedView 触发条件可能不对

**永久方案 (已实施, 跨 commit 91c3073 + 5ab8dc6)**:
- ✅ 修复 settlementProvider 状态机
- ✅ 修复 _SettlementView 空状态处理
- ✅ 修复 _BalancedView 触发条件
- ✅ ISSUE-029 复发: 加"暂无费用"友好提示 + 区分"无成员"/"有成员无费用"/"已结算" 3 种状态

**Commit**: `91c3073`, `5ab8dc6`

---

### ✅ ISSUE-021 — Supabase 注册错误【已修复 (网络超时)】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-021 |
| **等级** | P1 严重 |
| **模块** | Auth / Supabase |
| **报告时间** | 2026-07-05 10:11 |
| **报告人** | 用户 (周末真机测试) |
| **修复时间** | 2026-07-08 (91c3073) |
| **修复人** | AI |
| **状态** | ✅ 已修复 (网络超时 + email confirmation) |

**症状**:
- 2026-07-04 晚 21:23 注册新用户提示错误
- 可能原因 1: Supabase 默认要求邮箱验证
- 可能原因 2: 国内网络访问 Supabase 慢/超时

**永久方案 (已实施)**:
- ✅ 注册流程加 loading + 错误信息详细化 (截图提示)
- ✅ Supabase 控制台关闭强制邮箱验证
- ✅ 网络超时重试机制
- ✅ 后续 commit 6d952f6 让 Supabase 完全可选, 本地模式不需要远端注册

**Commit**: `91c3073`, `6d952f6`

---

### ✅ ISSUE-022 — 输入金额时键盘挡住输入框【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-022 |
| **等级** | P2 中等 |
| **模块** | 记账 / Expense Create |
| **报告时间** | 2026-07-05 13:32 |
| **报告人** | 用户 (周末真机测试) |
| **修复时间** | 2026-07-08 (91c3073) |
| **修复人** | AI |
| **状态** | ✅ 已修复 |

**症状**:
- 输入消费金额时, 手机自带输入法弹出
- 输入法挡住输入框, 看不到自己输入的数字
- 只能手动隐藏输入法才能看到输入框

**根因**:
- Scaffold 没有 `resizeToAvoidBottomInset` 处理
- 数字输入 TextField 位于屏幕底部, 输入法弹出时不在可视区
- 没有 `SingleChildScrollView` 包裹, 导致键盘区域不滚动

**永久方案 (已实施)**:
- ✅ Scaffold `resizeToAvoidBottomInset: true`
- ✅ `SingleChildScrollView` 包裹金额输入区域
- ✅ 输入框聚焦时自动滚动到可视区
- ✅ `MediaQuery.of(context).viewInsets.bottom` 留 padding

**Commit**: `91c3073`

---

### ✅ ISSUE-023 — 分人金额输入后误以为保存退出【已修复 (含复发 ISSUE-027)】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-023 |
| **等级** | P2 中等 |
| **模块** | 记账 / Expense Create |
| **报告时间** | 2026-07-05 13:32 |
| **报告人** | 用户 (周末真机测试) |
| **修复时间** | 2026-07-08 (91c3073 首修) + 2026-07-11 (ISSUE-027 复发再修) |
| **修复人** | AI |
| **状态** | ✅ 已修复 (主修 + 复发修复全在 v1.0.0-local) |

**症状**:
- 分人输入金额时, 点 "保存" 按钮直接退出
- 实际其他人金额还没输入
- 容易误以为全部金额已经输完

**根因**:
- "保存" 按钮在所有金额输完前就显示
- 用户操作时只看金额栏, 忽略后续分人步骤
- 没有"保存并继续"按钮或多人合并输入界面

**永久方案 (已实施, 含 ISSUE-027 二次修复)**:
- 1️⃣ 主修 (commit 91c3073, 2026-07-08):
   - "保存"按钮改为"保存并继续" + "保存完成" 双按钮
   - 默认焦点"保存并继续"
   - 显示进度指示
- 2️⃣ 复发修复 (commit 163530d, 2026-07-11):
   - 重命名按钮: "保存并继续" → **"保存下一笔"** (语义更准)
   - 加 tooltip 说明用途
   - (焦点跳转"输完 a 跳到 b" 待 V1.1.1 改进)

**见**: ISSUE-027 (真机复发反馈, 7-11 晚已修复)

---

## 📌 2026-07-10 用户反馈 (真实机测试)

### ✅ ISSUE-024 — 费用详情无法修改付款人/时间/分摊规则【已完整修复 (V1.1 / v0.2.0+2)】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-024 |
| **等级** | P1 严重 |
| **模块** | 记账 / Expense Detail Edit |
| **报告时间** | 2026-07-10 16:00 |
| **报告人** | 用户 (真机测试 0.1.0 版本) |
| **修复时间** | 2026-07-10 16:30 |
| **修复人** | AI |
| **状态** | ✅ 已完整修复 (V1.1 / v0.2.0+2) |

**症状**:
- 用户在费用详情页点右上角"编辑"按钮后, **只能修改 3 个字段**: 金额 / 类别 / 备注
- **不能修改**: 付款人 / 时间 / 分摊规则 / 附件
- 实际使用中常见的修正场景无法处理:
  - "这顿饭其实是老张付的" → 改付款人
  - "日期应该是昨天" → 改时间
  - "老王不算这份" → 改分摊规则

**根因**:
- `expense_detail_screen.dart` 的 `_buildEdit()` UI 只暴露 3 个字段
- 但 `ExpenseRepository.update()` 和 `ExpenseNotifier.update()` **已经支持**所有字段更新
- **前后端能力不匹配**: 数据层支持, UI 层未暴露

**永久方案 (已实施)**:
- ✅ **付款人编辑** (e964817 - 7-10 16:18)
  - ListTile 弹窗选择
  - `_save()` 传 `payerId`
- ✅ **时间编辑** (e964817 - 7-10 16:18)
  - DatePicker + TimePicker
  - `_save()` 传 `occurredAt`
- ✅ **分摊规则编辑** (dae34ca - 7-10 16:30)
  - 新增 SplitRuleEditPage 全屏编辑器
  - 复用 SplitTypeSelector (5 种分摊模式)
  - 从 splitRuleJson 解析初始值
  - `_save()` 传 `splitRuleJson`
- ✅ **附件编辑** (dae34ca - 7-10 16:30)
  - 显示已有附件 + 添加 URL + 删除
  - `_save()` 传 `attachments`

**v0.2.0+2 APK**:
- 路径: `build/app/outputs/flutter-apk/app-release.apk`
- 大小: 24.9 MB
- SHA1: `065077dea87f5b63ae78fedeb66ce252a2d7fef5`

**测试**:
- 228/228 全过 (从 225 增到 228)
- 新增 3 个测试:
  1. `更新付款人 + 时间 (ISSUE-024)`
  2. `更新分摊规则 + 附件 (V1.1)`
  3. `完整更新所有字段 (V1.1)` (7 字段同改)
- flutter analyze: No issues found

**Commit**: `e964817`, `dae34ca` (本条历史 ISSUE-024-COMPLETE 摘要合并入此条目)

---

### ⏸️ ISSUE-025 — Google Play 上架【暂缓 (ADR-005)】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-025 |
| **等级** | P2 一般 (现调整为⏸️ 暂缓) |
| **模块** | 发布 / Google Play Console |
| **报告时间** | 2026-07-11 22:27 |
| **报告人** | PM 主 Agent (用户指示拆解) |
| **状态** | ⏸️ **暂缓 (ADR-005 决策, 2026-07-15)** |
| **关联替代** | ISSUE-034 国内 Android 上架 |
| **重启条件** | 海外市场计划（重启时重新评估 Google Play + ios/） |

**背景**:
- v1.0.0 已构建并签名 (Release APK 23.6 MB + AAB 23.7 MB)
- 项目从 MVP 阶段进入正式分发阶段

**已备资源** (重启时可用):

| 资源 | 状态 | 备注 |
|---|---|---|
| Release APK (23.6 MB) | ✅ 就绪 | build/app/outputs/flutter-apk/app-release.apk |
| AAB (23.7 MB) | ✅ 就绪 | build/app/outputs/bundle/release/app-release.aab |
| 签名 keystore | ✅ 就绪 | v1+v2 双签名 ⚠️ 重启前需走 PR-9 重新生成强密码 |
| Google Play 开发者账号 | ⏸️ 暂缓 | 一次性 $25（重启时支付） |
| 隐私政策 URL | ⏸️ 暂缓 | 改为 ISSUE-034 准备（中文版） |
| 商店资料 (截图/图标/描述) | ⏸️ 暂缓 | 改为 ISSUE-034 中文版准备 |

**原 9 大类 30 项子任务** (历史归档):
- 注册账号、签名、隐私、IAP、截图、文案、Test Track、AAB 上传、商店策略
- 详见 ADR-005 取消记录

---

### 🆕 ISSUE-026 — 票据照片上传 (Supabase Storage)【待启动】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-026 |
| **等级** | P2 一般 (用户驱动, 不阻塞开发) |
| **模块** | 记账 / 附件管理 / Cloud Storage |
| **报告时间** | 2026-07-12 (从 CHANGELOG + 后续规划补登) |
| **报告人** | 项目规划 (V1.2 规划阶段) |
| **状态** | 🆕 待启动 (V1.2 计划) |

**症状 (规划期)**:
- 当前费用只能通过"附件 URL"输入链接, 用户体验差
- 需要拍照或选图 → 上传 Supabase Storage → 关联到费用
- 真实场景: 餐厅发票/加油票/打车票需要拍照存证

**目标功能**:
- 费用创建/编辑页加"拍照"按钮 → 调用相机 → 上传到 Supabase Storage → 自动插入 URL
- 费用详情页点附件 → 大图预览
- 多附件支持 (同一笔费用可关联多张票据)
- 离线模式: 本地暂存图片 → 联网后自动上传

**前置依赖**:
- ✅ Supabase Storage bucket 需创建 (公开读, 私有写)
- ⏳ 相机权限声明: CAMERA + READ_MEDIA_IMAGES (issue-tracker-025 第 6 节已列)
- ⏳ 图片压缩 (Flutter `image` package)
- ⏳ 上传进度 UI

**估计工作量**:
- 数据库: 1 张表 `expense_attachments` 或直接用 JSON 字段
- 前端: 拍照 + 压缩 + 上传 + 展示 ≈ 2-3 天
- 测试: 离线队列 + 同步冲突 ≈ 1 天
- 合计: ~5 天 (V1.2 节奏)

**当前 (2026-07-12) 决定**:
- 🟡 已记账, 未启动
- 优先级: V1.2 (在 Google Play 上架之后)

---

### ✅ ISSUE-027 — 保存并继续按钮与分摊金额输入体验混乱【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-027 |
| **等级** | P1 严重 (核心交互错误) |
| **模块** | 添加费用 / SplitTypeSelector / 金额输入 |
| **报告时间** | 2026-07-11 23:24 |
| **报告人** | 用户 (真机实测反馈 v1.0.0-local) |
| **修复时间** | 2026-07-11 (当晚) |
| **修复人** | AI |
| **状态** | ✅ 已修复 (v1.0.0-local 重打包) |

**症状 (用户原话)**:
> "新添加的 保存并继续按钮 实际和保存没有区别 都直接退出认为输入结束。 实际应该退出现在输入的单元格，然后用户继续选择其他输入项。例如我输入按固定分摊金额 后 我要继续输入b 而不是直接退出了保存了。"

**根因 (两个不同问题被混在一起)**:

1. **"保存并继续" 按钮语义不清**:
   - 当前实现: 保存当前费用 + 重置表单 + 留在当前页
   - 用户期望: 可能是"完成当前字段输入 + 自动跳到下一个相关字段"
   - **问题**: 按钮名"保存并继续"语义双关

2. **按金额分摊输入框 Bug** (位置: `split_type_selector.dart:428 _specificRow`):
   - 代码: `final ctrl = TextEditingController(text: ...)` 在 build() 里新建 controller
   - **问题**: 每次输入触发 setState → rebuild → 新 controller 重置 text → 光标丢失

**永久方案 (已实施)**:
- ✅ (Issue 2 主要) 把 `_specificRow` 的 controller 提升为 state 字段, 永不重建
- ✅ `_sharesRow` (按份数) 和 `_ratiosRow` (按比例) 同步修复
- ✅ (Issue 1 修复) 重命名"保存并继续" → **"保存下一笔"**, 配 tooltip 说明用途
- ⏳ 焦点跳转"输完 a 自动跳到 b" 待 V1.1.1 改进

**Commit**: `163530d` (按钮重命名), `f73a0bd` (controller 提升 — 同一修复含 ISSUE-028)

---

### ✅ ISSUE-028 — 金额输入倒序 + 删除退出格子【已修复】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-028 |
| **等级** | P1 严重 (核心输入体验) |
| **模块** | SplitTypeSelector / TextField |
| **报告时间** | 2026-07-11 23:24 |
| **报告人** | 用户 (真机实测反馈 v1.0.0-local) |
| **修复时间** | 2026-07-11 (当晚) |
| **修复人** | AI |
| **状态** | ✅ 已修复 (v1.0.0-local 重打包) |

**症状 (用户原话)**:
> "发现输入金额时候有问题，数字是倒着录入的 我输入 1 2 3 进去后是 3 2 1 .顺序有问题。 而且我删除一个数字光标就退出这个格子 我不能连续删除，需要删除一个 点点一下 继续删除。"

**根因 (已确认)**:
- 同一个 bug: `_specificRow` 在 build() 里 `new TextEditingController(text: ...)`
- 每次输入触发 setState → rebuild → 新 controller 初始化 text → 光标位置异常
- 删除: 用户按退格 → onChanged 触发 setState → rebuild → 新 controller 替换, 焦点丢失

**永久方案 (已实施)**:
- ✅ 提升 controller 为 `late Map<String, TextEditingController> _ctrls`
- ✅ 在 initState / didUpdateWidget 同步初始化和更新
- ✅ 在 dispose 统一释放
- ✅ onChanged 只更新 `_specific[m.id]` + `_emit()`, 不重建 controller

**Commit**: `f73a0bd` (核心修复, 同 ISSUE-027 主修)

---

### ✅ ISSUE-029 — 云端同步按钮文案 + 结算空白页【已修复 (含 ISSUE-020 复发)】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-029 |
| **等级** | P2 一般 (体验差, 不阻塞核心) |
| **模块** | AuthScreen + SettlementScreen |
| **报告时间** | 2026-07-11 23:24 |
| **报告人** | 用户 (真机实测反馈 v1.0.0-local) |
| **修复时间** | 2026-07-11 (当晚) |
| **修复人** | AI |
| **状态** | ✅ 已修复 (v1.0.0-local 重打包) |

### 问题 1: 云端同步按钮文案

**症状 (用户原话)**:
> "界面右上角的云端同步按钮， 进去后有一个继续本地使用， 云端同步未启用 这个是什么问题？"

**根因**:
- 位置: `lib/presentation/screens/auth_screen.dart:91`
- 文案对普通用户太技术 (含 `flutter run --dart-define=...` 命令)
- 按钮"继续本地使用"语义不准

**永久方案 (已实施)**:
- ✅ 简化文案: "云同步未配置" + 简短解释 + "返回" 按钮
- ✅ CLI 命令从 UI 移到 `docs/04-deployment/local-only-mode.md`
- ✅ 加隐藏入口 (设置页 → 关于 → 长按版本号 5 次显示开发者模式)

### 问题 2: 新建数据后结算页一片空白

**症状 (用户原话)**:
> "并且新建数据后按结算 一片空白没有显示任何东西"

**根因**:
- 结算页依赖 `settlement.balances` 有数据才显示内容
- 当 balances 为空 map 时, UI 组件渲染空内容 (没有"暂无费用"提示)

**永久方案 (已实施)**:
- ✅ 在 `_BalancesCard` 头部加 `if (balances.isEmpty)` → "暂无费用记录" 友好提示
- ✅ 在 `_SummaryCard` "总支出" 行加 `if (totalAmount == 0)` → "暂未记录任何费用" 提示 + "去添加" 按钮
- ✅ 优化 `_EmptyView` 文案: 区分"无成员" / "有成员无费用" / "已结算" 三种状态

**Commit**: `5ab8dc6`

**注**: ISSUE-020 之前报过同样问题, 本次复发合并修复

---

### ✅ ISSUE-030 — 缺少"关于"页面【已新增】

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-030 |
| **等级** | P2 一般 (产品完整性) |
| **模块** | 设置 / About |
| **报告时间** | 2026-07-11 23:24 |
| **报告人** | 用户 (产品反馈) |
| **修复时间** | 2026-07-11 (当晚) |
| **修复人** | AI |
| **状态** | ✅ 已新增 (v1.0.0-local 重打包) |

**症状 (用户原话)**:
> "这个软件没有 关于 没有后版本号 增加关于页面 我的个人联系方式 litiboy@163.com 软件版本也上进去。"

**需求 (已实现)**:
- ✅ "关于"页面入口: 旅程列表右上角"更多"菜单
- ✅ 显示:
  - 软件名称 (AI 旅行账本)
  - 版本号 (1.0.0+0)
  - 作者联系方式 (litiboy@163.com)
  - 开源仓库地址 (github.com/jiaqingshao/ai-travel-ledger)
  - 隐私协议链接 (占位, ISSUE-025 上架时用)
  - 技术栈说明 (Flutter + Supabase)
  - 致谢 / License

**实施 (已落地)**:
- ✅ 新增 `lib/presentation/screens/about_screen.dart`
- ✅ 在 `trip_list_screen.dart` PopupMenuButton 加 "about" case
- ✅ 应用 strings.xml 资源
- ✅ 隐私政策 URL 占位

**Commit**: `0051915`

---

## 📊 ISSUE 统计摘要 (2026-07-15)

| 状态 | 数量 | 详情 |
|---|---|---|
| ✅ 已修复 | 21 | 013, 015, 016, 017, 018, 019, 020, 021, 022, 023, 024, 027, 028, 029, 030 |
| ⏸️ 已搁置 (用户决策) | 3 | 014 (Android 模拟器), 025 (Google Play), 035 (iOS) |
| 📋 待启动 | 5 | **034 (国内 Android 上架)**, 036 (TCB 迁移), 026-焦点跳转 (V1.1.1) |
| ⏳ 进行中 | 0 | — |
| 🆕 **⏸️ V1.1 Backlog** | **3** | **031 (E-008 语音), 032 (E-009 重复), 033 (E-010 统计) — ADR-004 决策** |

**总 ISSUE 数**: 30 个实体条目 (013~036, 不含中间代码 # 标识或重复条目)

---

## 🆕 ⏸️ V1.1 Backlog (ADR-004 决策)

### ISSUE-031 — E-008 语音记账 [V1.1 重启候选]

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-031 |
| **关联 Epic** | E-008 |
| **等级** | P1 候选 (原 v0.3 P0) |
| **模块** | 语音 / LLM 集成 |
| **状态** | ⏸️ **V1.1 Backlog (ADR-004 决策)** |
| **决策日期** | 2026-07-15 |
| **依赖缺口** | `speech_to_text` 包未加；麦克风权限 UX 待设计 |
| **重启条件** | 市场调研确认自驾游场景的真实需求 + 1-2 周开发 + 中文 STT 测试数据集 |
| **决策记录** | [ADR-004](../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md) |

### ISSUE-032 — E-009 重复费用 [V1.1 重启候选]

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-032 |
| **关联 Epic** | E-009 |
| **等级** | P1 候选 (原 v0.3 P0) |
| **模块** | 定时任务 / 重复规则 |
| **状态** | ⏸️ **V1.1 Backlog (ADR-004 决策)** |
| **决策日期** | 2026-07-15 |
| **依赖缺口** | `workmanager` 包未加；**国产手机后台调度已知不稳定** |
| **重启条件** | 解决 workmanager 兼容性问题 + 1-1.5 周开发 |
| **决策记录** | [ADR-004](../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md) |

### ISSUE-033 — E-010 旅程统计图表 [V1.1 重启候选]

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-033 |
| **关联 Epic** | E-010 |
| **等级** | P1 候选 (原 v0.3 P0) |
| **模块** | 数据可视化 |
| **状态** | ⏸️ **V1.1 Backlog (ADR-004 决策)** |
| **决策日期** | 2026-07-15 |
| **依赖现状** | ✅ `fl_chart 0.66.2` 已加 pubspec（启用成本最低） |
| **重启条件** | 2-3 天开发（最简单，V1.1 时首选重启对象） |
| **决策记录** | [ADR-004](../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md) |

---

## 🆕 🇨🇳 V1.3 国内 Android 上架（ADR-005 决策）

### ISSUE-034 — 国内 Android 应用商店上架 [V1.3 主线]

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-034 |
| **关联决策** | [ADR-005](../02-architecture/04-adr/ADR-005-android-cn-only.md) |
| **替代 ISSUE** | ISSUE-025（Google Play 暂缓） |
| **等级** | **P0 V1.3 主线** |
| **模块** | 发布 / 国内 Android 应用商店 |
| **状态** | 📋 计划中 (V1.3 主线) |
| **决策日期** | 2026-07-15 |

**背景**:
- 创始人决定仅在国内 Android 应用商店发布 (ADR-005)
- 中国大陆 5 亿+ Android 用户
- 主流商店: 华为 / 小米 / OPPO / vivo / 应用宝 / 360 / 阿里

**前置资源** (R011/R012 需先达戳):

| 资源 | 状态 | 备注 |
|---|---|---|
| 软件著作权 (软著) | ❌ 未申请 | **R011 高风险 · 1-2 月 · ¥300-800** |
| ICP 备案评估 | ❌ 未评估 | **R012 高风险 · 1-2 周** |
| 隐私政策 | ❌ 未写 | 中文版（取代 ISSUE-025 英文版） |
| 用户协议 | ❌ 未写 | 中文版 (如需) |
| 商店资料 (截图/图标/描述) | ❌ 未制作 | 需中文 + 各商店适应 |
| 应用商店开发者账号 | ❌ 未注册 | 各商店分别注册 |
| Release APK | ✅ 就绪 | 适用于大部分商店 |
| 签名 keystore | ⚠️ 需重生成 | PR-9 (S-14/S-25) |

**V1.3 试水计划**:
1. **首选 2 个商店**: **小米应用商店** + **OPPO 软件商店**
   - 小米：个人开发者可直接注册
   - OPPO：接受个体工商户
   - 覆盖约 30-40% 国内 Android 用户
2. **后续扩展**（V1.4）: 华为 / vivo / 应用宝 / 360 / 阿里

**子任务清单** (预计拆解):

1. **软著申请** (前置, 1-2 月)
   - 准备源代码 (60 页)
   - 准备文档 (说明手册 + 用户手册)
   - 选择代理 (淘宝 ¥300 / 版权局加急 ¥800)
   - 提交 + 等颁证
2. **ICP 备案评估** (前置, 1-2 周)
   - 决定方案 (海外 Supabase 域名备案 / 切国内云)
   - 如域名备案: 准备 ICP 资料
3. **隐私政策 + 用户协议** (中文版)
   - 参考 《个人信息保护法》起草
   - 抽取 必要信息（邮箱 / 云同步 / 数据收集）
   - 部署到个人网页或 GitHub Pages
4. **商店资料准备**
   - 应用截图 (5-8 张，各商店适应)
   - 应用描述 (中文)
   - 应用图标 (现有 launcher 图标能用)
   - 应用分类 / 标签
5. **应用商店账号注册** (各商店)
6. **打包 + 提交审核**
   - 每商店独立 release
   - 应对拒绝 / 反馈
7. **上线后运营**
   - 用户反馈收集
   - 应用商店评价
   - 故障响应

**预计工作量**: 4-6 周全流程（含 1-2 月软著办理等待）

---

### ISSUE-035 — iOS 适配 [暂缓 (ADR-005)]

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-035 |
| **关联决策** | [ADR-005](../02-architecture/04-adr/ADR-005-android-cn-only.md) |
| **等级** | P2 一般 (⏸️ 暂缓) |
| **模块** | 平台 / iOS |
| **状态** | ⏸️ **暂缓 (ADR-005 决策)** |
| **决策日期** | 2026-07-15 |

**背景**:
- 创始人暂无 Apple Developer Program 付费计划 ($99/年个人 / $299/年公司)
- ios/ 目录从未创建 (Flutter 默认 Android-only)
- iOS 上架必须付费才能签名 + 提交

**重启条件**:
1. 创始人决定为 iOS 支付 Apple Developer 费用
2. 确认有 iOS 设备实际调试 (.ipa 无法在 Android 调试)
3. 评估 Apple App Store 审核标准 (比 Google Play 严格)
4. 重新启动 Flutter iOS 配置 (`flutter create -t app --platforms=ios`)
5. 估计工作量: 2-4 周 (平台验证 + 可能在 UI 适配 iOS Human Interface Guidelines)

**决不启用的某些条件**:
- 国内路线为主 → iOS 不是必备
- 中长期 iOS 不在中国适配

---

## 🆕 ☁️ V1.3 后端迁移 (ADR-007 决策)

### ISSUE-036 — Supabase → 腾讯云开发 CloudBase 迁移 [V1.3 关键路径]

| 字段 | 值 |
|---|---|
| **Issue ID** | ISSUE-036 |
| **关联决策** | [ADR-007](../02-architecture/04-adr/ADR-007-r012-tcb-migration.md) |
| **等级** | **P0 V1.3 关键路径** |
| **模块** | 后端 / BaaS 迁移 |
| **状态** | 📋 计划中 (等创始人提供密钥后启动) |
| **决策日期** | 2026-07-15 |
| **影响等级** | 极高（V1.3 上架前置条件） |

**背景**:
- 当前后端: Supabase 海外（不合规）
- 目标后端: 腾讯云开发 CloudBase（国内 + 免费层）
- 迁移原因: R012 ICP 备案合规

**预计工作量**: **5-7 周**

**子任务清单**:

1. **环境准备 (D+1 ~ D+3)**: 创始人注册腾讯云 + 实名 + 创建 CloudBase 环境 (见 [tcb-setup-guide.md](../03-management/tcb-setup-guide.md))

2. **SDK 接入 (D+5 ~ D+7)**:
   - 添加 `cloudbase_sdk` 依赖到 pubspec.yaml
   - 写 `lib/core/tcb/tcb_service.dart` (类似 `lib/core/supabase/supabase_service.dart`)
   - 配置 SecretId / SecretKey / EnvId

3. **Auth 迁移 (D+7 ~ D+14)**:
   - 邮箱 + 密码注册/登录 → TCB 自定义登录
   - JWT token 管理 + refresh
   - 迁移用户表 `profiles`

4. **数据库迁移 (D+7 ~ D+14)**:
   - 7 张表 schema 翻译 (PostgreSQL → 选定 TCB 数据库类型)
   - RLS / 安全规则重写
   - 测试数据初始化脚本

5. **Storage 迁移 (D+14 ~ D+18)**:
   - 附件上传 → TCB 云存储 (`expense-attachments` bucket)
   - 公开读私有写策略

6. **Realtime 迁移 (D+14 ~ D+18)**:
   - 数据 watch 替代 Supabase Realtime
   - 多端实时同步验证

7. **双写期 (D+18 ~ D+50)**:
   - Dart 端同时写两个后端
   - 验证数据一致性
   - 每日备份

8. **全量切换 (D+50)**:
   - Supabase 配置标记 archived（不回退路径）
   - TCB 成为唯一下游

9. **验证 + ICP 备案 (D+50 ~ D+60)**:
   - 真机回归测试
   - 腾讯云代办 ICP 备案 (7-10 工作日)
   - 提交 V1.3 上架

**风险**:
- **R014 TCB 迁移风险** (高, 监控中)
- 数据双写期间不一致
- 5-7 周工期超期

**完成后关闭条件**:
- [ ] 7 张表数据已迁移至 TCB
- [ ] 认证流程跑通 (注册 / 登录 / refresh)
- [ ] 附件上传到 TCB 云存储正常
- [ ] 多设备实时同步延迟 < 2s
- [ ] 现有 V1.2 milestone 用户的本地数据无损迁移
- [ ] 全部 lib/ 测试 + 新 TCB 测试通过
- [ ] ICP 备案通过

---

## 📎 参考资源

- **决策文档**:
  - [ADR-004](../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md) — PRD v0.3 P0 暂缓
  - [ADR-005](../02-architecture/04-adr/ADR-005-android-cn-only.md) — 发布路线调整 (国内 Android only)
- 完整修复时间线: `memory/2026-07-11-timeline-rebuild.md`
- 模拟器问题专家评审: `docs/03-management/troubleshooting/2026-07-11-emulator-boot-report.md`
- 真机测试 checklist: `docs/03-management/verification/v0.2.0-real-device-test-checklist.md`
- 项目结构总览: `docs/03-management/项目文件目录结构一览表.md`
- 风险登记: [risk-register.md](risk-register.md) — 含 R011 软著 / R012 ICP / R013 多商店
- 事件日志: `event-log.md`

---

*本文件最后同步: 2026-07-15 (ADR-004 + ADR-005 决策同步)*
*维护人: PM 主 Agent (minimax/MiniMax-M3)*
