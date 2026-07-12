# AI 旅行账本 - 项目评估文档

**评估对象**:`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\`
**评估时间**:2026-07-12
**评估范围**:完整 Dart 源码 + 全部 .md 文档 + 3 个 SQL 迁移 + pubspec + 一览表
**评估轮次**:5 轮(2026-07-12)
**评估方式**:只读评估,**未修改任何项目文件**

---

## 文档结构

本目录是项目完整评估的产出,**所有结论横向对齐**——任何轮次指出的问题都能在统一清单里追溯,且每条都有"为什么 / 影响 / 修复方向 / 优先级"。

| 文件 | 内容 | 何时查 |
|---|---|---|
| **README.md**(本文件) | 入口 + 文档地图 | 找东西从这开始 |
| **[01-evaluation-checklist.md](01-evaluation-checklist.md) | **主清单**——所有问题按 ID 编号,含文件、行号、修复建议 | 想"一表看完所有问题" |
| **[02-by-category.md](02-by-category.md) | 按类别横向汇总(代码 / 数据库 / 安全 / 文档 / UX / 架构 / 性能 / 测试) | 想"某个维度有哪几条" |
| **[03-fix-priorities.md](03-fix-priorities.md) | **P0 立即修** / **P1 短期** / **P2 中期** + 行动方案 | 想"我先干什么" |
| **[04-strategic-decisions.md](04-strategic-decisions.md) | 战略级问题(PRD v0.3 P0 功能 / 文档 vs 代码 / sync 真实状态) | 跟用户决策时 |
| **[05-evaluation-summary.md](05-evaluation-summary.md) | **1 页执行摘要**——给非技术决策者看 | 电梯演讲 / 周报 |

---

## 评估范围

### ✅ 完整评估了

#### 源码(`lib/`,47 个 .dart 文件)
- **入口与配置**:`main.dart`、`core/supabase/supabase_service.dart`、`core/ai_config.dart`、`core/ai_service.dart`
- **数据层**(`lib/data/`):5 个 model(trip / member / group / expense / transfer_record / attachment / app_settings)+ 5 个 repository + 1 个 seed_data + 1 个 sync_engine
- **领域层**(`lib/domain/services/`):SettlementEngine + SplitCalculator(项目最核心的两个纯函数模块)
- **Provider 层**(`lib/presentation/providers/`):core_providers + expense_provider + trip_provider + member_provider + group_provider + settlement_provider + sync_providers
- **屏幕层**(`lib/presentation/screens/`):14 个屏幕(trip_list / trip_detail / trip_create / trip_edit / archived_trips / expense_list / expense_create / expense_detail / settlement / group_settlement / group_manage / member_manage / archived_trips / auth / supabase_settings / ai_settings / about)
- **Widget 层**:`split_type_selector`(957 行) + `model_selector`

#### 文档(`docs/`,**全部**)
- 01-requirements/ 6 篇(PRD v0.3 / FSD v0.1 + v0.4 / 用户故事 / 竞品 / brain-storm)
- 02-architecture/ 11 篇 + 3 ADR(tech-stack / ui-design / data-model / system-design / supabase-schema / e2e 报告 / release build 指南 / split 规则 / settlement 算法 / 4 篇代码结构 + ADR-001/002/003)
- 03-management/ 全部(issue-tracker / event-log / 测试报告 / 真机 checklist / daily-reports / meeting-notes / verification / troubleshooting 全部读完)
- 04-deployment/ 3 篇(deploy-guide / project-info / pc-migration-guide)
- 99-archive/ 目录
- 99-reference/ 1 篇(trae-config-guide)
- 项目文件目录结构一览表(项目"目录入口"文档)

#### 数据库(`supabase/`)
- `00001_initial_schema.sql`(主 schema,257 行)
- `00002_rls_policies.sql`(RLS 策略,228 行)
- `00003_expense_attachments_storage.sql`(附件 bucket + 触发器,146 行)

#### 路线图
- `roadmap/roadmap.md` + 5 个 Epic(e-001/002/003/004/005)的 epic.md

#### 工程配置
- `pubspec.yaml` + `analysis_options.yaml`

### ⏭ 跳过的内容(明确说明)

- **`docs/03-management/troubleshooting/2026-07-11-emulator-boot-report.md` 完整内容** —— 按用户明确要求,**不评估与 Android 模拟器相关的问题**。该报告涉及 ISSUE-014(VM 中 emulator 启动)及其衍生项,在所有清单中**不收录**。
- **`.g.dart` 文件** —— 由 `build_runner` 自动生成,不是手写代码。
- **99-archive/ 下的历史产物**(Go 五子棋代码、test-misc 脚本、market-data 副本)—— 已归档的早期探索,**不影响当前项目交付**。
- **每日的 daily-reports / meeting-notes 历史 8-10 天** —— 抽读了最新 1-2 份做背景了解,全部不评估。
- **README 早期版本 `99-archive/test-misc/AI旅行账本-项目文件目录结构一览表.md`** —— 已归档的历史版本。

---

## 评估原则(横向一致性)

为了保证 5 轮评估**没有冲突或者不完整**,我用了以下统一原则:

### 1. 问题 ID 编号规则
- **按发现顺序**(不按文件),保证回溯清晰
- **格式**:`# + 类别代码 + 数字` —— 例如 `#S-1` 严重(英文 Severe),`#M-12` 中等(Medium),`#L-30` 轻微(Low)
- 每条问题有**唯一 ID**,任何文档里出现都能用 `Ctrl+F 搜 #S-1` 找到

### 2. 严重度定义
- **🔴 S (Severe)**:导致功能坏掉 / 数据丢失 / 隐私泄露 / 必须立即修
- **🟡 M (Medium)**:会导致 UX 差 / 数据漂移 / 文档失真,短期修
- **🟢 L (Low)**:代码风格 / 一致性 / 优化点,中期修
- **🔵 N (Note)**:不是 bug 但需要决策的战略问题

### 3. 修复方向统一
每条问题给出**至少一个具体可执行的修复**——文件 / 行号 / 修改方向,**不写空泛的"应该优化 X"**。

### 4. 横向冲突检查
每条问题回答:
- **"和 X 问题的关系是什么?"**(因果 / 重复 / 互斥)
- **"修这条要碰哪些文件?"**(避免散乱改)

### 5. 不完整标记
- **🔵 "未确认"**:文件我没读到 / 涉及第三方 / 需要用户确认
- 任何**猜测**都标注 **(推测)** 而不是当作事实

---

## 5 轮评估的主要变化

| 轮次 | 重点 | 新增问题数 |
|---|---|---|
| 第 1 轮 | 一览表 + 11 个核心 doc + 3 个 SQL | 9 严重 + 15 中等 = 24 |
| 第 2 轮 | 3 ADR + 6 个屏幕 + 2 个 provider | +18 严重 = 42 |
| 第 3 轮 | 7 个屏幕 + 4 个 provider + 4 个 model | +30 = 72 |
| 第 4 轮 | 5 个 repo + 4 个 provider + 3 个屏幕 | +9 = 81 |
| 第 5 轮 | 99-archive / verification / troubleshooting 摘要 + 5 个 epic + 横向冲突检查 | +0(收尾,做一致性) |

**最终总数:81 条问题**(其中 27 严重、35 中等、16 轻微、3 战略待决)。

---

## 关键发现速览(完整见 05-evaluation-summary.md)

1. **🔴 S-1**:3 个 SQL bug(00003 schema 错误 + collaborators 表名错 + 触发器 JSON 解析错)
2. **🔴 S-2**:真实邮箱 `litiboy@163.com` 在 3 个 Dart 文件硬编码 → 任何用户反编译都能拿到
3. **🔴 S-3**:**`syncEngineProvider` 根本没启动** —— `startAutoSync()` 全工程 0 处调用,sync 引擎是死代码
4. **🔴 S-4**:`ExpenseRepository.create` 默认 `SyncStatus.synced` —— UI 看到 synced 实际没传
5. **🔴 S-5**:`_SettlementView.members.first.tripId` 在空成员列表会崩(ISSUE-020 复发风险)
6. **🔴 S-6**:`AuthNotifier._init()` 监听 authStateChanges 但 StreamSubscription 没保存,泄漏且会在 dispose 后 setState
7. **🔴 S-7**:`expense_create_screen.dart` 和 `expense_detail_screen.dart` build 里 mutate state(隐性 UX bug)
8. **🔴 S-8**:`kCurrentUserId = 'local-user'` 写死 —— 接 Supabase Auth 后老数据全成幽灵用户
9. **🔴 S-9**:`main.dart` 完全没启动 `syncEngineProvider.startAutoSync()`,sync 整个死代码
10. **🔵 N-1**:PRD v0.3 三个 P0 功能(语音/重复/统计)全未实现,但文档承诺 P0

---

## 下一步建议(完整见 03-fix-priorities.md)

**立即(今天内)**:S-2(邮箱硬编码)+ S-1(SQL bug)
**本周内**:S-3 / S-4 / S-5 / S-6 / S-7 / S-8(同步引擎相关)
**下周**:S-9 + P1 全部 10 条
**月度**:P2 全部 15 条 + N 战略决策

---

*生成时间:2026-07-12 | 评估方式:全文件只读扫描 | 评估轮次:5 轮 | 问题总数:81*
