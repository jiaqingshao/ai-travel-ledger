# 按类别横向汇总 (v2)

**目的**:同一个"问题类别"的所有问题放在一节,横向对比,看哪些是同根因 + v1 → v2 修复状态。

**总问题数 v2**:**86**(🔴 27 + 🟡 34 + 🟢 14 + 🔵 3 + 🆕 8)

---

## 1. 隐私 / 安全

| ID | v1 严重度 | v2 状态 | 一句话 | 文件:行 |
|---|---|---|---|---|
| **S-3** | 🔴 | ❌ 未修 | 真实邮箱硬编码 3 处 | `about_screen.dart:20` + `auth_screen.dart:112` + `supabase_settings_screen.dart:415` |
| **S-4** | 🔴 | ❌ 未修 | Supabase project URL 硬编码 | `supabase_settings_screen.dart:190` |
| S-13 | 🔴→🟡 | 🟡 部分修(被新流程替代) | 旧 URL 输入已废弃,但 stub 函数还在 | `expense_detail_screen.dart:466` |
| S-14 | 🔴 | ❌ 未修 | keystore 重新生成风险 | (同 v1) |
| S-25 | 🔴 | ❌ 未修 | keystore 密码弱 | (同 v1) |
| S-20 | 🔴 | ❌ 未修 | `ai_config.dart` modelName 与实际端点不匹配 | (同 v1) |
| M-19 | 🟡 | ❌ 未修 | supabase_settings 错误信息含 stack trace | (同 v1) |
| M-6 | 🟡 | ❌ 未修 | 异常 toString 直接给用户 | (同 v1) |
| M-5 | 🟡 | ❌ 未修 | 字符串匹配 email not confirmed | (同 v1) |
| L-2 | 🟢 | ❌ 未修 | TransferRecord 缺 currency 字段 | (同 v1) |

**v2 横向分析**:
- 隐私泄露 3 处**完全没动**(S-3 / S-4 / S-20)
- S-13 从 🔴 降级为 🟡,因为 V1.2 拍照/选图流程替代了 URL 输入,**但旧的 stub 函数和注释还在**(V2-1 已识别)
- 一次性 `grep -r 'litiboy\|zvqnawllsdmisntkxdwp' lib/` 应该 0 命中(目前 4 命中),一次 commit 能全清
- 新增的 `lib/config/supabase_config.dart` 已用编译时注入,**是架构改进**(URL/anon key 不再硬编码),但**旧的 `core/supabase/supabase_config.dart` 没删** —— **V2-3 命名冲突**

---

## 2. 数据库 / SQL

| ID | v1 严重度 | v2 状态 | 一句话 | 文件:行 |
|---|---|---|---|---|
| **S-1** | 🔴 | ❌ 未修 | `00003` RLS 引用不存在的 `public.collaborators` 表 | (同 v1) |
| **S-2** | 🔴 | ❌ 未修 | `00003` 触发器把 JSON 对象 stringify 进 text[] | (同 v1) |
| S-8 | 🔴 | ❌ 未修 | `kCurrentUserId = 'local-user'` 写死 | (同 v1) |
| S-17 | 🔴 | ❌ 未修 | `data-model.md` 描述跟真实 Supabase 不一致 | (同 v1) |
| S-19 | 🔴 | ❌ 未修 | `_pushExpense` 把本地 syncStatus/deletedAt 推到云 | (同 v1) |
| S-26 | 🔴 | ❌ 未修 | `_cloudVersion` 注释里有但代码里**没这 map** | (同 v1) |
| S-27 | 🔴 | ❌ 未修 | 改 expense amount 不撤销已结清 transfer | (同 v1) |
| M-9 | 🟡 | ❌ 未修 | 改 trip.baseCurrency 不联动 expense.currency | (同 v1) |
| M-25 | 🟡 | ❌ 未修 | TripRepository.delete 不级联删 | (同 v1) |
| M-27 | 🟡 | ❌ 未修 | Expense.amount 全链路 double | (同 v1) |
| M-28 | 🟡 | ❌ 未修 | SettlementEngine 累加 double | (同 v1) |
| M-29 | 🟡 | ❌ 未修 | `Trip.fromDb` 'active' 分支没测试 | (同 v1) |
| M-33 | 🟡 | ❌ 未修 | 5 个 repo create/update 不校验 amount > 0 | (同 v1) |
| M-34 | 🟡 | ❌ 未修 | `AppSettings.fromJson` 强转不可靠 | (同 v1) |
| **V2-2** | 🆕 | 🆕 新增 | `_cloudVersion` 注释仍是谎言 | `sync_engine.dart:21` |

**v2 横向分析**:
- 全部 S 类**完全没动**(S-1 / S-2 / S-17 / S-19 / S-26 / S-27)
- `00003` migration 写完后**没人跑 staging 测试** —— 这是 S-1/S-2 反复出现的根因
- v2 新增 V2-2 = 重新发现 v1 S-26,**严重度没降级,只是更明确**
- M-34 新发现(v1 没看到),`AppSettings.fromJson` 在 V1.2 加 `app_settings.dart` 时引入

---

## 3. 同步 / 离线

| ID | v1 严重度 | v2 状态 | 一句话 | 文件:行 |
|---|---|---|---|---|
| **S-5** | 🔴 | ❌ 未修 | `syncEngineProvider.startAutoSync()` 0 调用 | (同 v1) |
| **S-6** | 🔴 | ❌ 未修 | `ExpenseRepository.create` 默认 `SyncStatus.synced` | (同 v1) |
| **S-9** | 🔴 | ❌ 未修 | `main.dart` 没启动 sync engine | (同 v1) |
| S-10 | 🔴 | ❌ 未修 | `AuthNotifier._init()` StreamSubscription 泄漏 | (同 v1) |
| S-19 | 🔴 | ❌ 未修 | `_pushExpense` 推本地状态到云 | (见 #2) |
| S-26 | 🔴 | ❌ 未修 | `_cloudVersion` 注释存在但代码没 | (见 #2) |
| M-7 | 🟡 | ❌ 未修 | `_pullChanges` 只 pull trips | (同 v1) |
| M-8 | 🟡 | ❌ 未修 | `_pushExpense` 失败 save 失败状态丢失 | (同 v1) |
| M-18 | 🟡 | ❌ 未修 | 5 个 push 方法不更新 syncStatus | (同 v1) |
| M-16 | 🟡 | ❌ 未修 | `_fireRemote` 静默吞错 | (同 v1) |
| **V2-3** | 🆕 | 🆕 新增 | 2 个 `SupabaseConfig` 类名冲突 | `lib/config/supabase_config.dart` + `lib/core/supabase/supabase_config.dart` |

**v2 横向分析**:
- **5 个 S 类全部 0 修复**:S-5 / S-6 / S-9 / S-10 仍是死代码 / 假装已同步
- V1.2 期间**加了 `lib/config/supabase_config.dart`** 用 `String.fromEnvironment` 编译时注入,**架构改对了** —— 但旧 `core/supabase/supabase_config.dart` 没删,**类名冲突**(N-3)
- S-5 / S-6 / S-8 / S-9 同根因 → **修法**:同时改,一次 PR
- **唯一改进迹象**:`lib/config/supabase_config.dart` 的 `cloudDefaults` 是新架构,带 `AppSettings.mergeWith`(本评估范围外但值得肯定)

---

## 4. UI 状态管理 / 隐性 bug

| ID | v1 严重度 | v2 状态 | 一句话 | 文件:行 |
|---|---|---|---|---|
| **S-7** | 🔴 | ❌ 未修 | `members.first.tripId` 空成员崩溃 | `settlement_screen.dart:476` |
| **S-11** | 🔴 | ❌ 未修 | build 里 mutate state(无 setState) | `expense_create_screen.dart:91` |
| **S-12** | 🔴 | ❌ 未修 | build 里 mutate state(详情页) | `expense_detail_screen.dart` |
| S-21 | 🔴 | ❌ 未修 | `_submitAndContinue` 失败无提示 | (同 v1) |
| S-22 | 🟡 | ❌ 未修 | 数字键盘锁位无反馈 | (同 v1) |
| S-24 | 🔴 | ❌ 未修 | 4 层 AsyncValue.when 嵌套 | (同 v1) |
| M-1 | 🟡 | ❌ 未修 | `group_settlement_screen` 3 层 when | (同 v1) |
| M-13 | 🟡 | ❌ 未修 | 数字键盘 0 开头逻辑混乱 | (同 v1) |
| M-4 | 🟡 → 🔴 S-26 | ✅ 已修 (PR-Z5) | `expenseByIdProvider` 重复 watch + 不响应变化 | 2026-07-20 (升级 S-26) |
| M-20 | 🟡 | ❌ 未修 | 删除 trip 无二次校验 | (同 v1) |

**v2 横向分析**:
- **S-7 / S-11 / S-12 全部 0 修复** —— ISSUE-020 复发风险仍在
- 4 层 `when` 嵌套(S-24)仍是 settlement_provider 主结构
- V1.2 加了 3 个 attachment widget 但**没顺手修这些 UI state bug** —— 资源花在加新功能,bug 留着

---

## 5. 文档失修

| ID | v1 严重度 | v2 状态 | 一句话 | 文件 |
|---|---|---|---|---|
| **S-15** | 🔴 | ❌ 未修 | PRD v0.3 三大 P0 未实现但文档承诺 | (同 v1) |
| **S-16** | 🔴 | ❌ 未修(加重) | 一览表失修(7-8 → 7-14 全面失修) | (同 v1) |
| **S-17** | 🔴 | ❌ 未修 | data-model.md 跟真实 Supabase 不一致 | (同 v1) |
| **S-18** | 🔴 | ❌ 未修 | `app_links: 6.3.1` override 没文档化 | (同 v1) |
| M-22 | 🟡 | ❌ 未修 | `roadmap.md` Epic 状态全部"未开始" | (同 v1) |
| M-23 | 🟡 | ❌ 未修 | `roadmap.md` "原 E-008/009/010" 编号搞反 | (同 v1) |
| M-24 | 🟡 | ❌ 未修 | daily-reports vs meeting-notes 职责不清 | (同 v1) |
| M-29 | 🟡 | ❌ 未修 | `Trip.fromDb` 'active' 分支没测试 | (同 v1) |
| L-9 | 🟢 | ❌ 未修 | 中文硬编码 | (同 v1) |
| **V2-4** | 🆕 | 🆕 新增 | 一览表 7-8 后没更新,数字全错 | `项目文件目录结构一览表.md` |
| **V2-6** | 🆕 | 🆕 新增 | app_links override 仍未文档化 | `pubspec.yaml` |
| **V2-7** | 🆕 | 🆕 新增 | CHANGELOG/MILESTONE 与实际 commit 状态可能不对齐 | `CHANGELOG.md` + `MILESTONE.md` |
| **V2-8** | 🆕 | 🆕 新增 | issue-tracker 维护滞后 | `issue-tracker.md:737` |

**v2 横向分析**:
- V1.2 期间**新建了 `CHANGELOG.md` + `MILESTONE.md`** —— 但这是**新增文档,不是修复失修**
- 项目文件目录结构一览表.md 写 196/64/60/2,**实际 50/54/3/22 测试**,数字全面过时(V2-4 重申并量化)
- V2-7 / V2-8 反映"项目文档越多,失修点越多" —— 没有自动化校验机制
- **修复方法**:加 pre-commit hook + CI 校验"文档 vs 代码一致性"

---

## 6. V1.2 新增的代码(本评估 v2 新增分类)

### 6.1 Attachment 系统(全新功能,V1.2 step 1-4)

| 文件 | 状态 |
|---|---|
| `lib/data/models/attachment.dart` | ✅ 已实现 |
| `lib/data/models/attachment.g.dart` | ✅ build_runner 生成 |
| `lib/data/repositories/attachment_repository.dart` | ✅ 已实现 |
| `lib/presentation/widgets/attachment_picker_section.dart` | ✅ 已实现,267 行 |
| `lib/presentation/widgets/attachment_thumb.dart` | ✅ 已实现,171 行 |
| `lib/presentation/widgets/attachment_viewer.dart` | ✅ 已实现,96 行 |
| `lib/presentation/screens/expense_detail_screen.dart:466` | 🟡 旧 `_addAttachment` stub 还在(N-1) |
| `supabase/migrations/00003_expense_attachments_storage.sql` | 🔴 2 个 bug(S-1, S-2) |
| 4 个新 test 文件 | ✅ 都有 |

### 6.2 Release 流程(V1.2 step 2-4 + cloud + milestone)

| 路径 | 状态 |
|---|---|
| `scripts/build-apk.ps1` + `build-local.ps1` + `build-cloud.ps1` + `build-cloud-milestone.ps1` + `run-with-supabase.ps1` + `build-with-supabase.ps1` | ✅ 6 个 build 脚本完整 |
| `release/v0.2.0/` | ✅ 有 CHANGELOG + README |
| `release/v1.0.0-local/` | ✅ 有 CHANGELOG |
| **`release/v1.2-step2-local/`** | 🟡 **无 README/CHANGELOG**(V2-5) |
| **`release/v1.2-step3-local/`** | 🟡 **无 README/CHANGELOG**(V2-5) |
| **`release/v1.2-step4-local/`** | 🟡 **无 README/CHANGELOG**(V2-5) |
| `release/v1.2.0+0-cloud/` | ✅ 有 CHANGELOG |
| `release/v1.2.0+0-cloud-milestone/` | ✅ 有 CHANGELOG |

### 6.3 Supabase 可选化(V1.2 step 1 配套)

| 文件 | 状态 |
|---|---|
| `lib/config/supabase_config.dart` | ✅ 新,93 行,用 `String.fromEnvironment` |
| `lib/config/build_milestone.dart` | ✅ 新,92 行,里程碑元数据 |
| `lib/data/models/app_settings.dart` | ✅ 新,97 行 |
| `lib/data/repositories/app_settings_repository.dart` | ✅ 新,约 50 行 |
| `lib/presentation/screens/supabase_settings_screen.dart` | ✅ 新,422 行 |
| **`lib/core/supabase/supabase_config.dart`** | 🟡 **没删,类名冲突**(N-3) |

### 6.4 SplitRuleEditPage(V1.1 后期 / V1.2)

| 文件 | 状态 |
|---|---|
| `lib/presentation/screens/split_rule_edit_page.dart` | ✅ 178 行,5 种分摊模式全屏编辑 |
| `test/presentation/split_rule_edit_page_test.dart` | ✅ 配套 test |

---

## 7. 输入校验 / 精度

| ID | v1 严重度 | v2 状态 | 一句话 |
|---|---|---|---|
| **S-23** | 🔴 | ❌ 未修 | 详情页不限小数位,精度漂移 |
| M-12 | 🟡 | ❌ 未修 | 详情页没让用户选 currency |
| M-13 | 🟡 | ❌ 未修 | 数字键盘 0 开头逻辑混乱 |
| M-27 | 🟡 | ❌ 未修 | Expense.amount 全链路 double |
| M-28 | 🟡 | ❌ 未修 | SettlementEngine 累加 double |
| M-32 | 🟡 | ❌ 未修 | Trip.baseCurrency 没 assert 长度 |
| M-33 | 🟡 | ❌ 未修 | 5 个 repo create/update 不校验 amount > 0 |
| M-9 | 🟡 | ❌ 未修 | 改 trip 币种不联动 expense |
| L-5 | 🟢 | ❌ 未修 | destination 没长度校验 |
| L-7 | 🟢 | ❌ 未修 | (从 v1 M-29 移到 L) |

---

## 8. 测试 / 质量

| ID | v1 严重度 | v2 状态 | 一句话 |
|---|---|---|---|
| M-14 | 🟡 | ❌ 未修 | split_calculator_test.dart 期望值用 `==` |
| M-21 | 🟡 | ❌ 未修 | pubspec.yaml 缺 lint 自定义 |
| L-6 | 🟢 | 🟡 部分修复 | V1.2 加了 4 个 attachment 测试 |
| L-8 | 🟢 | ❌ 未修 | 多个 repository 缺 unit test |

**v2 测试现状**:
- V1 写"225/225 全绿"(7-4),7-14 daily-report 写"234/234",V1.2 cloud-milestone CHANGELOG 写"250/250"
- **数字不一致**(V2-7 部分)
- 测试文件 22 个,新增 4 个 attachment 测试,**新增的质量门禁 = 0**

---

## 9. 错误处理 / 可观测性

| ID | v1 严重度 | v2 状态 | 一句话 |
|---|---|---|---|
| M-5 | 🟡 | ❌ 未修 | 字符串匹配 email not confirmed |
| M-6 | 🟡 | ❌ 未修 | 异常 toString 直接给用户 |
| M-8 | 🟡 | ❌ 未修 | `_pushExpense` 失败 save 失败状态丢失 |
| M-16 | 🟡 | ❌ 未修 | `_fireRemote` 静默吞错 |
| M-19 | 🟡 | ❌ 未修 | supabase_settings 错误信息含 stack trace |

**v2 横向分析**:**全部 0 修复**。没有 logging / Sentry / Crashlytics 接入,debug 靠 `debugPrint`。

---

## 10. 战略(沿用 v1)

| ID | 严重度 | v2 状态 |
|---|---|---|
| N-1 | 🔵 | ❌ 未决(PRD 三大 P0) |
| N-2 | 🔵 | ❌ 未决(commit 推送) |
| N-3 | 🔵 | ✅ 已决(模拟器跳过) |

---

## 修复优先级矩阵(v2)

| 类别 | 严重项数 | v2 修复情况 | 一次性可修 | 关键依赖 |
|---|---|---|---|---|
| 1. 隐私/安全 | 4 S | 0/4 | ✅ 全在 Dart 文件 | — |
| 2. 数据库/SQL | 8 S | 0/8 | ✅ 3 个 SQL + 1 文档 | 修 S-1/S-2 才能部署 |
| 3. 同步/离线 | 5 S | 0/5 | ✅ 连锁,需一起改 | 修完 sync 才真 sync |
| 4. UI 状态 | 5 S | 0/5 | ✅ 改 Flutter widget | — |
| 5. 文档失修 | 4 S | 0/4 | ✅ 重写文档 | 等 N-1 |
| 6. 输入校验 | 1 S + 7 M | 0/8 | ✅ 改 form | 中等 |
| 7. 测试质量 | 0 S + 2 M | 0/2 | ✅ 加测试 | 持续 |
| 8. 错误处理 | 0 S + 5 M | 0/5 | ✅ 加 logger | 中等 |
| **v2 新增 5 类(attachment/release/可选化/SplitRuleEdit/配置)** | 0 S + 3 M | — | 部分 ✅ 部分 🟡 | — |
| 9. 战略 | 3 N | 0/3 | ❌ 用户决策 | 阻塞 |

**结论**:
- **隐私/安全 + SQL + 同步** 这 3 类 17 个 S, **0 修复**
- **V1.2 期间**新增的 7 个文件质量高,但**没有顺便修任何 S 类**
- **N-1 战略决策**不决策,所有文档修复都阻塞

---

## v1 → v2 总结

| 类别 | v1 数 | v2 数 | 变化 |
|---|---|---|---|
| S 严重 | 27 | 27 | 0 |
| M 中等 | 35 | 33 | **-2**(M-10/M-15 通过 V1.2 修复) |
| L 轻微 | 16 | 14 | -2(部分场景已修复) |
| N 战略 | 3 | 3 | 0 |
| V2-X 新增 | 0 | 8 | +8 |
| **总** | **81** | **86** | **+5** |

**最大的 v2 价值**:
1. **明确量化**了"全 0 修复"——v1 没明确说"修复率 = 0/27",v2 加了状态标注
2. **新增 8 项**反映 V1.2 引入的新问题(命名冲突、缺 release README、文档新增反而失修更严重)
3. **横向分析**更清楚"哪些同根因、哪些可以一起改"

---

*评估时间:2026-07-14 | v2 总问题数:86 | v1→v2 净增:5 | 修复率 S 类:0/27*