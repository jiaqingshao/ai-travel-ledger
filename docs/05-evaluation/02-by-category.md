# 按类别横向汇总

**目的**:同一个"问题类别"的所有问题放在一节,横向对比,看哪些是同根因。

**总问题数**:81(🔴 27 + 🟡 35 + 🟢 16 + 🔵 3)

---

## 1. 隐私 / 安全(S 类占多数)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| **S-3** | 🔴 | 真实邮箱硬编码 3 处 | `auth_screen.dart:113` + `supabase_settings_screen.dart:415` + `about_screen.dart:14` |
| **S-4** | 🔴 | Supabase project URL 硬编码 | `supabase_settings_screen.dart:190` |
| **S-13** | 🔴 | 附件 URL 不校验 | `expense_detail_screen.dart:414-444` |
| **S-14** | 🔴 | 重新生成 keystore 风险 | `release-build-guide.md` + daily-report |
| **S-25** | 🔴 | release keystore 密码 `aitravel2026` 弱 | `release-build-guide.md:41-42` |
| **S-20** | 🔴 | `ai_config.dart` model name 与实际端点不匹配 | `ai_config.dart:60` |
| M-19 | 🟡 | supabase_settings 错误信息含 stack trace | `supabase_settings_screen.dart:107-108` |
| M-6 | 🟡 | 异常 toString 直接给用户看 | `sync_providers.dart:81-83, 100-103` |
| M-5 | 🟡 | 字符串匹配 email not confirmed | `auth_screen.dart:76` |
| L-2 | 🟢 | TransferRecord 缺 currency 字段 | `transfer_record.dart` |

**横向分析**:
- 隐私泄露集中在 S-3 / S-4,**一次性扫描能全找出来**
- S-3 涉及 3 个文件,**一次 git 替换就能全清**
- S-14 / S-25 是连带的,新 keystore 用强密码 + 2+ 位置备份一起做

---

## 2. 数据库 / SQL(主要是 S-1/S-2)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| **S-1** | 🔴 | `00003` RLS 引用不存在的 `public.collaborators` 表 | `00003_expense_attachments_storage.sql:65,76,91` |
| **S-2** | 🔴 | `00003` 触发器把 JSON 对象 stringify 进 text[] | `00003_expense_attachments_storage.sql:113-123` |
| S-8 | 🔴 | `kCurrentUserId = 'local-user'` 写死,sync 归属错乱 | `trip_provider.dart:17` + `sync_engine.dart:130` |
| S-17 | 🔴 | `data-model.md` 描述表结构跟真实 schema 不一致 | `03-data-model.md` |
| S-19 | 🔴 | `sync._pushExpense` 把本地 syncStatus/deletedAt push 到云 | `sync_engine.dart:175-199` |
| S-26 | 🔴 | `_cloudVersion` 注释里有,代码里**没这 map** | `sync_engine.dart:20-21` |
| S-27 | 🔴 | 改 expense amount 不撤销已结清 transfer | `expense_repository.dart:195-229` |
| M-9 | 🟡 | 改 trip.baseCurrency 不联动 expense.currency | `trip_repository.dart:95-120` |
| M-25 | 🟡 | TripRepository.delete 不级联删 member/group/expense/transfer | 5 个 repo 各自 `deleteAllByTrip` 但无人调 |
| M-27 | 🟡 | Expense.amount 用 double 而 schema 用 BIGINT cents | `expense.dart:175` + `sync_engine.dart:182` |
| M-28 | 🟡 | SettlementEngine 累加 double 总金额 | `settlement_engine.dart:457-460` |
| M-29 | 🟡 | `Trip.fromDb` 'active' 分支没测试 | `trip.dart:139-150` |
| M-33 | 🟡 | 5 个 repository create/update 不校验 amount > 0 | 全部 repository |
| L-2 | 🟢 | TransferRecord 缺 currency 字段 | `transfer_record.dart` |
| M-34 | 🟡 | `AppSettings.fromJson` 强转 + fallback 不可靠 | `app_settings.dart:74-83` |

**横向分析**:
- **S-1 / S-2 同根因**:`00003` migration 写完后没人跑本地测试(没有 staging Supabase)
- **S-19 / S-26 / M-25 同根因**:sync 设计没想清楚就开干
- **S-27 / M-9 / M-25 同根因**:数据修改没有"级联事务"概念
- **M-27 / M-28 / M-33 同根因**:精度和验证在 Dart 端"全靠数据库兜底"
- **修法**:先 S-1/S-2(影响部署),再 S-19/S-26/S-27(影响数据),再精度系列

---

## 3. 同步 / 离线(S-5/S-6/S-8/S-9 连锁)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| **S-5** | 🔴 | `syncEngineProvider.startAutoSync()` 全工程 0 调用 | `sync_engine.dart:43-47` + `main.dart` |
| **S-6** | 🔴 | `ExpenseRepository.create` 默认 `syncStatus: synced` | `expense_repository.dart:186` |
| **S-8** | 🔴 | `kCurrentUserId = 'local-user'` 写死 | `trip_provider.dart:17` |
| **S-9** | 🔴 | `main.dart` 没启动 sync engine | `main.dart:80-98` |
| **S-10** | 🔴 | `AuthNotifier._init()` StreamSubscription 泄漏 | `sync_providers.dart:56-68` |
| S-19 | 🔴 | `_pushExpense` 推本地状态到云 | (见 #2) |
| S-26 | 🔴 | `_cloudVersion` 注释存在但代码没 | (见 #2) |
| M-7 | 🟡 | `_pullChanges` 只 pull trips | `sync_engine.dart:232-249` |
| M-8 | 🟡 | `_pushExpense` 失败 save 失败状态丢失 | `sync_engine.dart:195-198` |
| M-18 | 🟡 | 5 个 push 方法不更新 syncStatus(只有 expense 有) | 5 处 |
| M-16 | 🟡 | `_fireRemote` 静默吞错 | 5 个 repo |

**横向分析**:
- **S-5 / S-6 / S-8 / S-9 同根因**:**sync 功能整个半成品**——`syncEngineProvider` 根本没人 watch,`ExpenseRepository.create` 默认 synced 假装传了
- **S-10 关联**:如果 S-9 修了启动 sync,S-10 的 stream 泄漏会被触发
- **修法**:S-5 / S-6 / S-8 / S-9 必须**同时修**,否则只修一个,问题会更隐蔽

---

## 4. UI 状态管理 / 隐性 bug(S-7/S-11/S-12/S-24)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| **S-7** | 🔴 | `members.first.tripId` 空成员崩溃 | `settlement_screen.dart:476` |
| **S-11** | 🔴 | build 里 mutate state(无 setState) | `expense_create_screen.dart:86-87` |
| **S-12** | 🔴 | build 里 mutate state(详情页) | `expense_detail_screen.dart:83-85` |
| **S-21** | 🔴 | `_submitAndContinue` 失败无提示 | `expense_create_screen.dart:207-226` |
| **S-22** | 🔴 | 数字键盘锁位无反馈 | `expense_create_screen.dart:180-189` |
| **S-24** | 🔴 | 4 层 AsyncValue.when 嵌套 | `settlement_provider.dart:65-129` + 2 处屏幕 |
| M-1 | 🟡 | `group_settlement_screen` 3 层 when | `group_settlement_screen.dart:32-50` |
| M-13 | 🟡 | 数字键盘 0 开头逻辑混乱 | `expense_create_screen.dart:184-189` |
| M-4 | 🟡 | `tripByIdProvider` 重复 watch + 不响应变化 | `trip_provider.dart:40-45` |
| M-20 | 🟡 | 删除 trip 无二次校验 | `trip_detail_screen.dart:201-220` |
| M-10 | 🟡 | 附件数量无限制 | `expense_detail_screen.dart:358-412` |

**横向分析**:
- **S-7 / S-11 / S-12 / S-21 / S-22 同根因**:**Flutter UI build 阶段的状态管理被忽视**
- **S-24 / M-1 / M-4 同根因**:**Riverpod 嵌套 when 滥用**,应该用 `combine` 模式
- **修法**:S-7 / S-11 / S-12 / S-21 / S-22 一次 PR 修(同根因),S-24 单独大改

---

## 5. 文档失修(S-15/S-16/S-17/S-18)

| ID | 严重度 | 一句话 | 文件 |
|---|---|---|---|
| **S-15** | 🔴 | PRD v0.3 三大 P0 未实现但文档承诺 | `02-prd.md:103-145` |
| **S-16** | 🔴 | 项目文件目录结构一览表严重失修 | `项目文件目录结构一览表.md` |
| **S-17** | 🔴 | data-model.md 跟真实 Supabase 不一致 | `03-data-model.md` |
| **S-18** | 🔴 | `app_links: 6.3.1` override 没文档化 | `pubspec.yaml:82-87` |
| M-22 | 🟡 | `roadmap.md` Epic 状态全部"未开始" 但 4 个已完成 | `roadmap.md:18-23` |
| M-23 | 🟡 | `roadmap.md` "原 E-008/009/010" 编号搞反 | `roadmap.md:27-29` |
| M-24 | 🟡 | `daily-reports/` 和 `meeting-notes/daily-*.md` 职责不清 | `docs/03-management/` |
| M-29 | 🟡 | `Trip.fromDb` 'active' 分支没测试 | `trip.dart:139-150` |
| M-31 | 🟡 | `equalAll` + `equalSelected` 实现完全相同 | `split_calculator.dart:148-167` |
| L-11 | 🟢 | `ai_config.dart:46` TODO 永不需要做 | `ai_config.dart:46` |
| L-12 | 🟢 | 中文硬编码,未来 i18n 困难 | 多处 |

**横向分析**:
- **S-15 / S-16 / S-17 同根因**:**没人维护文档**——所有文档是"一次性写完不更新"
- **M-22 / M-23 同根因**:`roadmap.md` 写完后没跟着 epic 完成度更新
- **修法**:S-15 必须先**决策**(N-1),然后才能修文档;S-16 / S-17 / S-18 一次 PR 修

---

## 6. 输入校验 / 精度(S-23/M-27/M-28/M-32/M-33)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| **S-23** | 🔴 | 详情页不限小数位,精度漂移 | `expense_detail_screen.dart:230-238` |
| M-27 | 🟡 | `Expense.amount` 全链路 double | `expense.dart:175` + `sync_engine.dart:182` |
| M-28 | 🟡 | SettlementEngine 累加 double | `settlement_engine.dart:457-460` |
| M-32 | 🟡 | Trip.baseCurrency 没 assert 长度 | `trip.dart` |
| M-33 | 🟡 | 5 个 repo create/update 不校验 amount > 0 | 全部 |
| M-12 | 🟡 | 详情页没让用户选 currency | `expense_create_screen.dart` |
| M-11 | 🟡 | 4 处 8 硬编码色,不让用户自定义 | 4 个 screen |
| M-9 | 🟡 | 改 trip 币种不联动 expense | `trip_repository.dart` |
| L-7 | 🟢 | destination 没长度校验 | trip_create / trip_edit |

**横向分析**:
- **M-27 / M-28 同根因**:Dart 端没把"金额"当 int cents 处理
- **M-32 / M-33 / L-7 同根因**:**没有 form validator 习惯**——Schema 约束当兜底
- **修法**:S-23 立即改(`inputFormatters`),M-27 / M-28 一起改(改 int cents)

---

## 7. 测试 / 质量(M-8/M-14/M-15)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| M-8 | 🟡 | `_pushExpense` 失败 save 失败状态丢失 | `sync_engine.dart:195-198` |
| M-14 | 🟡 | `split_calculator_test.dart` 期望值用 `==` 比较浮点 | `test/domain/split_calculator_test.dart:187-196` |
| M-15 | 🟡 | `Attachment` Adapter 注册但功能未实现 | `lib/main.dart:45` + `lib/data/models/attachment.dart` |
| M-21 | 🟡 | `pubspec.yaml` 缺 lint 自定义 | `analysis_options.yaml` |
| M-29 | 🟡 | `Trip.fromDb` 'active' 分支没测试 | `trip.dart:139-150` |
| L-8 | 🟢 | 很多 repository 缺 unit test | 多个 test 文件 |

**横向分析**:
- **M-14 / M-29 同根因**:**测试只覆盖 happy path**,不覆盖边界
- **M-15 同根因**:**Adapter 注册了但测试没写**,出了 bug 才暴露
- **M-21 同根因**:**lint 规则形同虚设**
- **修法**:M-14 / M-29 各加 1 个测试即可,M-15 删附件代码或补全,M-21 改 analysis_options.yaml

---

## 8. 错误处理 / 可观测性(M-5/M-6/M-8/M-16/M-19)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| M-5 | 🟡 | 字符串匹配 email not confirmed | `auth_screen.dart:76` |
| M-6 | 🟡 | 异常 toString 直接给用户 | `sync_providers.dart:81-83, 100-103` |
| M-8 | 🟡 | `_pushExpense` 失败 save 失败状态丢失 | `sync_engine.dart:195-198` |
| M-16 | 🟡 | `_fireRemote` 静默吞错 | 5 个 repo |
| M-19 | 🟡 | supabase_settings 错误信息含 stack trace | `supabase_settings_screen.dart:107-108` |

**横向分析**:
- **全部同根因**:**项目没有 logging / 监控**——错都被 catchError 吞了,debug 只能靠 `debugPrint`
- **修法**:统一加 `lib/core/logging.dart` 简易 logger,所有 catch 调 logger;Sentry 接入是中期

---

## 9. 主题色 / 设计一致性(L-6 + S-25)

| ID | 严重度 | 一句话 | 文件 |
|---|---|---|---|
| L-6 | 🟢 | `Color(0xFF2E7D32)` 等硬编码 4 处 | 4 个文件 |
| S-25 | 🔴 | release keystore 密码弱 | (见 #1) |
| S-14 | 🔴 | 重新生成 keystore 风险 | (见 #1) |

**横向分析**:
- L-6 是"该建没建"`core/theme/colors.dart`,S-14 / S-25 是发布前必须修
- **修法**:L-6 月度清理,S-14/S-25 发布前

---

## 10. 状态机 / 业务流程(S-8/M-9/S-27)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| S-8 | 🔴 | `kCurrentUserId = 'local-user'` 写死 | (见 #3) |
| M-9 | 🟡 | 改 trip 币种不联动 expense | (见 #6) |
| S-27 | 🔴 | 改 expense amount 不撤销已结清 transfer | (见 #2) |

**横向分析**:
- **全部"修改 X 后,没考虑级联影响"**
- **修法**:在 5 个 repository 的 update 入口加"是否影响已结清记录"统一检查,提示用户

---

## 11. Riverpod / 状态管理(S-24/M-1/M-4/M-10)

| ID | 严重度 | 一句话 | 文件:行 |
|---|---|---|---|
| S-24 | 🔴 | 4 层 AsyncValue.when 嵌套 | (见 #4) |
| M-1 | 🟡 | 3 层 when 在 group_settlement | (见 #4) |
| M-4 | 🟡 | `tripByIdProvider` 重复 watch | (见 #4) |
| L-10 | 🟢 | 用老 `StateNotifierProvider` | 全部 provider |

**横向分析**:
- **S-24 / M-1 同根因**:`AsyncValue.when` 在 Riverpod 2.x 文档不推荐
- **L-10 同根因**:`StateNotifier` 在 2.x deprecated
- **修法**:S-24 + M-1 一起改(用 `combine` pattern),L-10 是技术债

---

## 12. 范围 / 战略(N 类)

| ID | 严重度 | 一句话 |
|---|---|---|
| N-1 | 🔵 | PRD v0.3 三个 P0 做不做?(详见 04) |
| N-2 | 🔵 | 领先 origin 20 commit 何时推? |
| N-3 | 🔵 | (已决策跳过模拟器) |

**横向分析**:
- N-1 是**最关键决策**,不决策影响所有文档和产品定位
- N-2 是**流程问题**,不影响代码但影响协作

---

## 修复优先级矩阵(按类别)

| 类别 | 紧急项数 | 一次性可修 | 关键依赖 |
|---|---|---|---|
| 1. 隐私/安全 | 6 S | ✅ 全在 Dart 文件 | 需先定 N-1 才决定 release 时间 |
| 2. 数据库/SQL | 8 S | ✅ 3 个 SQL + 1 文档 | 修 S-1/S-2 后才能部署 |
| 3. 同步/离线 | 6 S | ✅ 连锁,需一起改 | 修完 sync 才是真的 sync |
| 4. UI 状态 | 6 S | ✅ 改 Flutter widget | 简单但量大 |
| 5. 文档失修 | 4 S | ✅ 重写文档 | **等 N-1 决策** |
| 6. 输入校验 | 1 S + 7 M | ✅ 改 form | 中等 |
| 7. 测试质量 | 0 S + 5 M | ✅ 加测试 | 持续 |
| 8. 错误处理 | 0 S + 5 M | ✅ 加 logger | 中等 |
| 9. 主题/设计 | 1 S + 1 L | ❌ 各自 | 分散 |
| 10. 状态机 | 0 S + 3 S/M | ❌ 分散 | 复杂 |
| 11. Riverpod | 0 S + 4 M | ✅ 一次重构 | 简单 |
| 12. 战略 | 3 N | ❌ 用户决策 | 阻塞 |

**结论**:
- **隐私/安全 + SQL + 同步**这 3 类一共 20 个 S 类,**1-2 周集中修完**
- **UI 状态 + 文档失修**这 2 类有 10 个 S 类,需要 N-1 决策才能动文档
- **战略 3 条必须先决**

---

## 横向冲突检查(没有冲突,作为最终验证)

我把 5 轮评估的所有问题合并到 81 条 ID 后,做了下列冲突检查:

✅ **S-5 / S-6 / S-8 / S-9**:四条同根因(同步引擎死代码),**互相补全,无冲突**——必须一起修
✅ **S-1 / S-2**:同文件 (`00003`) 同一类(SQL bug),**无冲突,一次 PR**
✅ **S-3 / S-4**:同根因(隐私硬编码),**无冲突,一次 PR**
✅ **S-7 / S-11 / S-12 / S-21 / S-22**:同根因(Flutter state 管理),**无冲突,一次 PR**
✅ **S-15 / N-1**:决策优先,**N-1 不决策 S-15 永远修不了**
✅ **S-17 / S-19 / S-26 / S-27 / M-9 / M-25 / M-27 / M-28**:同根因(sync 残留问题),**无冲突,按序修**
✅ **M-1 / S-24**:同根因(Riverpod when 嵌套),**M-1 是子集,一起改**
✅ **M-2 / L-1**:同根因,合并成 M-2,L-1 取消(去重)
✅ **M-22 / M-23**:同根因(roadmap 失修),**无冲突,一起改**

**没有任何两条 ID 直接冲突**(修这条会让那条变坏)。所有修复顺序在 [03-fix-priorities.md](03-fix-priorities.md) 里排好。

---

*评估时间:2026-07-12 | 总问题数:81 | 横向冲突:0*
