# AI 旅行账本 - 项目评估文档 (v2)

**评估对象**:`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\`
**评估版本**:v2(增量于 v1 评估之上)
**评估时间**:2026-07-14
**评估范围**:完整 Dart 源码 + 全部 .md 文档 + 3 个 SQL 迁移 + pubspec + 一览表
**评估方式**:只读评估,**未修改任何项目文件**

> **v2 与 v1 的关系**:
> - v1(2026-07-12)在 `docs/05-evaluation/` 里留下了 81 条 ID 的评估基线
> - v2(本次)基于 v1 重新核验每条问题是否仍在 + 增量发现 V1.2 新增代码带来的新问题
> - **所有 v1 ID 在 v2 中保留**,新增问题用 `V2-X`(v2 new)前缀,不重排旧 ID

---

## 文档结构

本目录是项目完整评估的产出,**所有结论横向对齐** —— 任何轮次指出的问题都能在统一清单里追溯,且每条都有"为什么 / 影响 / 修复方向 / 优先级 / v2 现状"。

| 文件 | 内容 | 何时查 |
|---|---|---|
| **README.md**(本文件) | 入口 + 文档地图 + v1→v2 变化总览 | 找东西从这开始 |
| **[01-evaluation-checklist.md](01-evaluation-checklist.md) | **主清单** —— 所有问题按 ID 编号,含文件、行号、修复建议、v2 状态 | 想"一表看完所有问题" |
| **[02-by-category.md](02-by-category.md) | 按类别横向汇总(代码 / 数据库 / 安全 / 文档 / UX / 架构 / 性能 / 测试 / 新增) | 想"某个维度有哪几条" |
| **[03-fix-priorities.md](03-fix-priorities.md) | **P0 立即修** / **P1 短期** / **P2 中期** + 行动方案 + 反映 v2 新增 | 想"我先干什么" |
| **[04-strategic-decisions.md](04-strategic-decisions.md) | 战略级问题(PRD v0.3 P0 / 文档 vs 代码 / sync 真实状态 / V1.2 引入的新决策) | 跟用户决策时 |
| **[05-evaluation-summary.md](05-evaluation-summary.md) | **1 页执行摘要** —— 给非技术决策者看 | 电梯演讲 / 周报 |

---

## v2 评估范围

### ✅ 完整评估了

#### 源码(`lib/`,54 个 .dart 文件,含 6 个 .g.dart 生成)
- **入口与配置**:`main.dart`、`config/supabase_config.dart`(新)、`config/build_milestone.dart`(新)
- **核心服务**:`core/ai_config.dart`、`core/ai_service.dart`、`core/supabase/supabase_config.dart`(旧,看是否仍被用)、`core/supabase/supabase_service.dart`
- **数据层**(`lib/data/`):**7 个 model**(新增 `attachment.dart` + `app_settings.dart`)、**7 个 repository**(新增 `attachment_repository.dart` + `app_settings_repository.dart`)、`sync_engine.dart`、`seed_data.dart`
- **领域层**(`lib/domain/services/`):`SettlementEngine` + `SplitCalculator`
- **Provider 层**(`lib/presentation/providers/`):**7 个 provider**(核心 + expense + trip + member + group + settlement + sync)
- **屏幕层**(`lib/presentation/screens/`):**16 个屏幕**(新增 `split_rule_edit_page.dart`、`about_screen.dart`、`supabase_settings_screen.dart`、`ai_settings_screen.dart`)
- **Widget 层**(`lib/presentation/widgets/`):**5 个 widget**(新增 `attachment_picker_section.dart`、`attachment_thumb.dart`、`attachment_viewer.dart`)

#### 文档(`docs/`,50 个 .md,**不包含** `docs/05-evaluation/` 本身)
- 01-requirements/ 5 篇(PRD v0.3 / FSD / 用户故事 / 竞品)+ README
- 02-architecture/ 9 篇 + 3 ADR + test-plan-phase1 + README
- 03-management/ issue-tracker(737 行) + event-log + test-report + 项目文件目录结构一览表 + 5 个 daily-report + 5 个 meeting-notes + 3 个 README + verification + troubleshooting + project-development-guidelines
- 04-deployment/ 3 篇(deploy-guide / project-info / pc-migration-guide)
- 99-archive/ 4 篇(go-game + market-data + 3 个 epic 占位)
- 99-reference/ 1 篇(trae-config-guide)
- **顶层**:`README.md` + `CHANGELOG.md`(109 行) + `MILESTONE.md`(99 行)
- **release/ 5 个版本**:`v0.2.0/`、`v1.0.0-local/`、`v1.2-step2/3/4-local/`(3 个没 README)、`v1.2.0+0-cloud/`、`v1.2.0+0-cloud-milestone/`

#### 数据库(`supabase/`,3 个 SQL)
- `00001_initial_schema.sql`(7 张表,257 行)
- `00002_rls_policies.sql`(RLS,228 行)
- `00003_expense_attachments_storage.sql`(附件 bucket + 触发器,146 行 —— 新增)

#### 测试(`test/`,22 个 .dart 文件,新增 4 个)
- 数据 11 个 / 领域 2 个 / 集成 1 个 / 展示 5 个(新增 `attachment_*` 4 个) / 提供方 2 个 / widget_test 1 个

#### 路线图
- `roadmap/roadmap.md` + 5 个 Epic(e-001 ~ e-005)的 epic.md

#### 工程配置
- `pubspec.yaml`(71 行) + `analysis_options.yaml`(22 行)

#### 旧评估基线
- 完整读了 `docs/05-evaluation/{01,02,03,04,05}.md`,作为 v2 的对比基线

### ⏭ 跳过的内容(明确说明)

- **`docs/03-management/troubleshooting/2026-07-11-emulator-boot-report.md` 完整内容** —— 按用户明确要求,**不评估与 Android 模拟器相关的问题**。该报告涉及 ISSUE-014(VM 中 emulator 启动)及其衍生项,在所有清单中**不收录**。N-3 标识此决策已生效。
- **`.g.dart` 文件** —— 由 `build_runner` 自动生成,不是手写代码。
- **99-archive/ 下的历史产物**(Go 五子棋代码、test-misc 脚本、market-data 副本)—— 已归档的早期探索,**不影响当前项目交付**。
- **`release/v1.2-step2/3/4-local/` 3 个 APK 本身** —— 只有 `.apk` 文件,没 README/CHANGELOG,跳过二进制内容。
- **早期 v1 评估生成的 `docs/05-evaluation/` 本身** —— 作为基线对比,不重新评估。

---

## v2 vs v1:核心数字

| 指标 | v1 (2026-07-12) | v2 (2026-07-14) | 变化 |
|---|---|---|---|
| Markdown 总数 | ~50 | 50(精确) | + 详查 |
| Dart 总数 | 47 | 54(去重 .g) | +7 |
| SQL migrations | 2 | 3 | +1(00003) |
| 测试文件 | 18 | 22 | +4 |
| **S 严重问题** | 27 | 27 | **0**(旧 27 全未修) |
| **M 中等问题** | 35 | 33 | -2(部分修 / 部分合并) |
| **L 轻微** | 16 | 14 | -2 |
| **N 战略** | 3 | 3 | 0 |
| **V2-X 新增(v2 发现)** | 0 | **+8** | +8 |
| **总计** | **81** | **86** | +5 |

**结论**:
- 旧 81 条问题中,绝大多数**仍未修复**(S 类的修复率为 0,只有部分 M 类的功能改进)
- V1.2 的工作主要在"加新功能"(attachment 全套、release 流程、Supabase 可选化)
- **核心 sync 引擎和隐私问题一个都没动** —— 这是最严重的

---

## v2 新发现的 8 个问题(全部 V2-X 前缀)

> 完整定义见 [01-evaluation-checklist.md](01-evaluation-checklist.md)。**8 个新问题的 ID**:
> - **N-1**:v1 评估中的 S-13 旧实现仍残留 stub(`_addAttachment` 是空函数但保留声明)
> - **N-2**:`_cloudVersion` 注释里**仍是谎言**(代码里没实现,Trip/Member/Group/Transfer 仍无 sync 状态)
> - **N-3**:`lib/config/supabase_config.dart` 和 `lib/core/supabase/supabase_config.dart` 类名都是 `SupabaseConfig`,**命名冲突**
> - **V2-4**:`CHANGELOG.md` 和 `MILESTONE.md` 是新加的顶层文档,**但项目文件目录结构一览表.md 没更新**(仍然说 196 个文件、64 个 dart、60 个 md、2 个 sql —— 全部数字过时)
> - **V2-5**:`release/v1.2-step2-local/、v1.2-step3-local/、v1.2-step4-local/` 3 个目录**没 README/CHANGELOG** —— 不符合 release-build-guide.md 的"每个版本必须有 CHANGELOG.md"
> - **V2-6**:`pubspec.yaml` `dependency_overrides.app_links: 6.3.1` **仍未在 tech-stack.md / 任何 ADR 文档化**(v1 S-18 没修)
> - **V2-7**:`CHANGELOG.md` 写的"V1.2"和"MILESTONE.md" 写的"v1.2.0+0-cloud-milestone" 项目状态和实际代码可能不一致(我没逐行对代码 commit)
> - **V2-8**:`issue-tracker.md` "最后同步 2026-07-12 01:35",但 CHANGELOG 写 V1.2 + cloud-milestone 发布,**issue-tracker 可能未跟进 V1.2 相关的 ISSUE**

**详情见 [01-evaluation-checklist.md](01-evaluation-checklist.md) "v2 新增(V2-X)" 章节**。

---

## 5 轮评估的主要变化(沿用 v1)

| 轮次 | 重点 | 新增问题数 |
|---|---|---|
| 第 1 轮 | 一览表 + 11 个核心 doc + 3 个 SQL | 24 |
| 第 2 轮 | 3 ADR + 6 个屏幕 + 2 个 provider | +18 |
| 第 3 轮 | 7 个屏幕 + 4 个 provider + 4 个 model | +30 |
| 第 4 轮 | 5 个 repo + 4 个 provider + 3 个屏幕 | +9 |
| 第 5 轮 | 99-archive / verification / 5 个 epic + 横向冲突检查 | +0(收尾) |
| **第 6 轮(v2)** | **v1 81 项核验 + V1.2 新文件核验 + v2 新增 8 项** | **+4 / +8** |

---

## 关键发现速览(完整见 05-evaluation-summary.md)

1. **🔴 旧 27 个 S 问题 = 修复 0 个**:S-1 ~ S-27 仍全部存在,唯一"看起来修复"的是 S-13(URL 附件已被新拍照/选图流程取代,但 stub 函数还在)
2. **🟢 V1.2 期间加了 8 个新文件**(3 个 widget + 5 个 dart)但**没有修任何一个旧 S** —— "搭新房子但旧房子漏水还在"
3. **🆕 8 个新问题(V2-1 ~ V2-8)**:其中 **V2-3 命名冲突**(2 个 `SupabaseConfig` 类)和 **V2-5 release 缺文档** 是最影响后续维护的
4. **📋 一览表完全过时**:写 7-8 维护,数字全是错的(64→54 dart / 60→50 md / 2→3 sql),新人按它找文件会迷路
5. **🔵 战略 3 选仍未决**(从 v1 沿用):PRD 三大 P0 / 20 commit 推送 / 模拟器已跳过

---

## 下一步建议(完整见 03-fix-priorities.md)

**v2 紧急**(新增):
- N-1:删 `_addAttachment` stub 或用 `// ignore: unused_element`(保留无害但误导)
- N-3:2 个 `SupabaseConfig` 改一个名(`LegacySupabaseConfig` 或合并到 `lib/config/`)
- V2-5:3 个 release 目录补 README.md 或合并到主 README
- V2-6:补 app_links override 文档化

**立即(沿用 v1)**:S-2(邮箱硬编码) + S-1(SQL bug)
**本周内**(沿用 v1):S-3 / S-4 / S-5 / S-6 / S-7 / S-8 / S-9(同步引擎相关)
**下周**:S-9 + P1 全部 10 条
**月度**:P2 全部 15 条 + N 战略决策

---

*生成时间:2026-07-14 | 评估方式:全文件只读扫描 + v1 基线对比 | 评估版本:v2 | 问题总数:86*