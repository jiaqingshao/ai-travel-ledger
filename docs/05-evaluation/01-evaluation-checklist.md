# 项目评估 Checklist (主清单) - v2

**本表是所有问题的单一真源** —— 任何其他文档(02/03/04/05)都引用本表里的 ID。

**评估轮次**:v1 (5 轮) + v2 (1 轮核验) = 共 6 轮
**问题总数**:**86**(27 严重 + 34 中等 + 14 轻微 + 3 战略 + **8 新增**)
**生成时间**:2026-07-14

---

## v2 状态标注规则

每条 v1 的旧 ID 用 **🔴 v2 状态** 字段标注 4 种状态:
- `❌ 未修复`:代码还是坏的
- `🟡 部分修复`:相关功能被替代但 stub/死代码还在
- `✅ 已修复`:本轮已确认 OK
- `🔄 重新评估`:本轮发现 v1 描述不准

每条 v2 新发现的 ID 用 **`🆕 V2-X`** 命名空间。

---

## 索引

| 严重度 | 数量 | ID 范围 | 跳转 |
|---|---|---|---|
| 🔴 S(严重) | 27 | S-1 ~ S-27 | [查看](#-s-严重-27-条) |
| 🟡 M(中等) | 34 | M-1 ~ M-34 | [查看](#-m-中等-34-条) |
| 🟢 L(轻微) | 14 | L-1 ~ L-14 | [查看](#-l-轻微-14-条) |
| 🔵 N(战略待决) | 3 | N-1 ~ N-3 | [查看](#-n-战略待决-3-条) |
| 🆕 V2-X(v2 新增) | 8 | V2-1 ~ V2-8 | [查看](#-v2-x-v2-新增-8-条) |

---

## 🔴 S(严重,27 条)

> **修复原则**:发布前必须全修。每条都导致功能坏掉 / 数据丢失 / 隐私泄露。
> **v2 整体评估**:S-1 ~ S-27 **修复率 = 0/27**。所有问题在 2026-07-14 重新核验仍存在。
> 唯一变化是 **S-13 从"功能完全错"变成"被新流程替代,但 stub 还在"** —— 状态从 ❌ 改为 🟡。

---

### S-1: `00003_expense_attachments_storage.sql` 引用不存在的 `public.collaborators` 表

| 字段 | 内容 |
|---|---|
| **文件** | `supabase/migrations/00003_expense_attachments_storage.sql` |
| **行** | 65, 76, 91 |
| **严重度** | 🔴 S(部署必失败) |
| **v2 状态** | ❌ 未修复 |
| **验证命令** | `grep -n "public.collaborators" supabase/migrations/00003_expense_attachments_storage.sql` |
| **修复** | 全文 `public.collaborators` → `public.trip_collaborators`(3 处) |
| **关联** | S-2(同文件触发器错) |

### S-2: `00003` 触发器把 JSON 对象 stringify 进 text[] 字段

| 字段 | 内容 |
|---|---|
| **文件** | `supabase/migrations/00003_expense_attachments_storage.sql` |
| **行** | 113-123(触发器 `sync_expense_attachments`) |
| **严重度** | 🔴 S(数据污染) |
| **v2 状态** | ❌ 未修复 |
| **现状** | `jsonb_array_elements_text(attachment_metadata->'items')` 把每个 JSON 对象 stringify |
| **修复** | 改成 `ARRAY(SELECT (item->>'url') FROM jsonb_array_elements(NEW.attachment_metadata->'items') AS item)` |
| **关联** | S-1 |

### S-3: `litiboy@163.com` 真实邮箱在 3 个 Dart 文件硬编码

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/about_screen.dart:20`、`lib/presentation/screens/auth_screen.dart:112`、`lib/presentation/screens/supabase_settings_screen.dart:415` |
| **严重度** | 🔴 S(隐私泄露) |
| **v2 状态** | ❌ 未修复 |
| **修复** | 改为 `请联系开发者(应用内 → 关于 → 项目主页)` |
| **验证** | `grep -r 'litiboy' lib/` 应 0 命中(目前 3 命中) |

### S-4: 真实 Supabase project URL `zvqnawllsdmisntkxdwp` 硬编码

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/supabase_settings_screen.dart:190` |
| **严重度** | 🔴 S(服务入口泄露) |
| **v2 状态** | ❌ 未修复 |
| **修复** | `_pasteExample()` 改为 `https://YOUR-PROJECT.supabase.co` |

### S-5: `syncEngineProvider.startAutoSync()` 全工程 0 处调用

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart:43-47`(定义);`lib/main.dart`(无调用);`lib/presentation/providers/sync_providers.dart:11-14` |
| **严重度** | 🔴 S(承诺功能完全未运行) |
| **v2 状态** | ❌ 未修复 |
| **验证** | `grep -rn "startAutoSync" lib/` 只 1 命中(定义本身) |
| **关联** | S-6 / S-9 |

### S-6: `ExpenseRepository.create()` 默认 `syncStatus: SyncStatus.synced`

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart:186` |
| **严重度** | 🔴 S(同步 UX 谎言) |
| **v2 状态** | ❌ 未修复 |
| **验证** | `sed -n '180,195p' lib/data/repositories/expense_repository.dart` 第 186 行仍是 `syncStatus: SyncStatus.synced` |

### S-7: `_SettlementView` 第 476 行 `members.first.tripId` 在空成员列表会崩

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/settlement_screen.dart:476` |
| **严重度** | 🔴 S(白屏崩溃) |
| **v2 状态** | ❌ 未修复 |
| **验证** | 第 472 行有 `if (settlement.transfers.isNotEmpty)` 守卫了空 transfer,但 **members.first 仍无 isEmpty 守卫** |
| **修复** | 改为 `tripId: members.isNotEmpty ? members.first.tripId : widget.tripId` |

### S-8: `kCurrentUserId = 'local-user'` 写死

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/trip_provider.dart:17` |
| **严重度** | 🔴 S(数据归属错乱) |
| **v2 状态** | ❌ 未修复 |
| **验证** | `grep -n "kCurrentUserId\|local-user" lib/presentation/providers/trip_provider.dart` 第 17、68 行仍是 |

### S-9: `main.dart` 完全没启动 sync engine

| 字段 | 内容 |
|---|---|
| **文件** | `lib/main.dart` 第 99 行只有 `ProviderScope`,**没有 syncEngineProvider override** |
| **严重度** | 🔴 S(同步死代码) |
| **v2 状态** | ❌ 未修复 |
| **修复** | `runApp` 前 `final engine = SyncEngine(boxes: boxes); engine.startAutoSync();` |
| **关联** | S-5 |

### S-10: `AuthNotifier._init()` StreamSubscription 永远不取消

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/sync_providers.dart:56-68` |
| **严重度** | 🔴 S(内存泄漏 + 异常) |
| **v2 状态** | ❌ 未修复 |
| **验证** | `authStateChanges.listen((authState) { state = AuthState(...); })` 第 56 行,subscription 没保存,dispose 也不取消 |

### S-11: `expense_create_screen.dart` 第 91 行 build 里 mutate state

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart:91`(`_initDefaultPayer(members)`) |
| **严重度** | 🔴 S(隐性 UX bug) |
| **v2 状态** | ❌ 未修复 |
| **修复** | `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && _payer == null) setState(() => _initDefaultPayer(members)); })` |

### S-12: `expense_detail_screen.dart` build 里 mutate state

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` 在 build 里 mutate TextEditingController |
| **严重度** | 🔴 S(隐性 UX bug) |
| **v2 状态** | ❌ 未修复 |
| **关联** | S-11(同款) |

### S-13: 附件 URL 不校验 — 已被新拍照/选图流程替代,但 stub 还在

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart:466`(`_addAttachment()` 空函数);新流程在 `lib/presentation/widgets/attachment_picker_section.dart` |
| **严重度** | 🔴 S(从严重降级为🟡) |
| **v2 状态** | 🟡 **部分修复** — V1.2 step 2 引入 `AttachmentPickerSection`(拍照/选图/上传),取代了旧的 URL 输入。**但旧 `_addAttachment` 函数还在**(stub),且 v1 评估的"URL 不校验"已不适用,新流程本身没 URL 注入风险 |
| **新发现的问题** | 见 🆕 **V2-1** — 建议删除 stub 函数 |

### S-14: 重新生成 release keystore 后旧 APK 无法升级

| 字段 | 内容 |
|---|---|
| **文件** | `docs/02-architecture/07-release-build-guide.md` + daily-report/2026-07-10.md |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **关联** | S-25 |

### S-15: PRD v0.3 三大 P0 功能(语音/重复/统计)承诺但完全没实现

| 字段 | 内容 |
|---|---|
| **文件** | `docs/01-requirements/02-prd.md:103-145` |
| **严重度** | 🔴 S(产品诚信 + 履约) |
| **v2 状态** | ❌ 未修复(roadmap 没动,文档没动) |
| **关联** | N-1 战略决策 |

### S-16: 项目文件目录结构一览表严重失修

| 字段 | 内容 |
|---|---|
| **文件** | `docs/03-management/项目文件目录结构一览表.md` |
| **严重度** | 🔴 S(文档入口失真) |
| **v2 状态** | ❌ 未修复(写 7-8,实际 7-14 全面失修) |
| **v2 量化** | 一览表写 196 文件 / 64 dart / 60 md / 2 sql,实际 50 md / 54 dart / 3 sql |
| **关联** | V2-4 |

### S-17: `data-model.md` 描述的表结构跟真实 Supabase 不一致

| 字段 | 内容 |
|---|---|
| **文件** | `docs/02-architecture/03-data-model.md` |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **关联** | S-16 |

### S-18: `app_links: 6.3.1` override 没文档化

| 字段 | 内容 |
|---|---|
| **文件** | `pubspec.yaml:82-87`(dependency_overrides) |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **v2 验证** | `grep -n "app_links\|6.3.1" docs/02-architecture/01-tech-stack.md` 仍没提 override 原因 |
| **关联** | V2-6 |

### S-19: `_pushExpense` 把本地 syncStatus/deletedAt 也 push 到云

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart:175-199` |
| **严重度** | 🔴 S(数据一致) |
| **v2 状态** | ❌ 未修复 |
| **验证** | `client.from('expenses').upsert({...})` 第 178 行,没看到排除 syncStatus/deletedAt |

### S-20: `lib/core/ai_config.dart` M3 API key 占位 + Qwen3.6 baseUrl 硬编码

| 字段 | 内容 |
|---|---|
| **文件** | `lib/core/ai_config.dart` |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **关联** | V2-7(可能与 V1.2 的 AI 配置有关) |

### S-21: `_submitAndContinue` 失败不弹 Snackbar

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart` |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |

### S-22: 数字键盘限 2 位小数后 UI 不告诉用户已锁

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_create_screen.dart` |
| **严重度** | 🟡 M(实为 S 级) |
| **v2 状态** | ❌ 未修复 |

### S-23: `expense_detail_screen.dart` 用系统键盘 + 不限小数位

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart` |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |

### S-24: 4 层 `AsyncValue.when` 嵌套,任一 loading 整页转圈

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/providers/settlement_provider.dart` + 2 处屏幕 |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **关联** | M-1 |

### S-25: 重新生成 release keystore 但密码仍是 `aitravel2026`

| 字段 | 内容 |
|---|---|
| **文件** | `docs/02-architecture/07-release-build-guide.md:41-42` |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **关联** | S-14 |

### S-26: `_cloudVersion` 注释存在但代码里没这 map

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart:21`(注释) |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |
| **v2 验证** | `grep -n "_cloudVersion" lib/data/sync/sync_engine.dart` 第 21 行仍是注释,无 map 字段 |
| **关联** | N-2 |

### S-27: `expense_repository.update()` 改 amount 不校验已结清 transferRecord

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/repositories/expense_repository.dart` |
| **严重度** | 🔴 S |
| **v2 状态** | ❌ 未修复 |

---

## 🟡 M(中等,34 条)

> **v2 评估**:M 类 34 条 = v1 的 35 条 - 1 条(已修) + 0 条 合并 - 1 条 v2 新发现(M-34)。

---

### M-1: `group_settlement_screen.dart` 3 层 when 嵌套

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |
| **关联** | S-24 |

### M-2: `_parseColor` 在 4 个文件重复

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |
| **v2 验证** | `grep -rn "_parseColor" lib/` 仍 4 处 |

### M-3: `_parseColor` 不支持 3/8 位 hex

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |
| **关联** | M-2 |

### M-4: `tripByIdProvider` / `expenseByIdProvider` 重复 watch + 不响应 box 变化

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-5: `auth_screen.dart` `email not confirmed` 字符串匹配

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-6: `AuthNotifier.signIn/signUp` 把内部异常 message 直接给 UI

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-7: `sync_engine._pullChanges` 只 pull trips

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-8: `_pushExpense` 失败 catch 里改 syncStatus,但 save 失败时状态丢失

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-9: `Trip.baseCurrency` 改了之后,所有旧 expense.currency 不联动

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-10: PRD 说"附件最多 3 个",代码没强制

| 字段 | 内容 |
|---|---|
| **v2 状态** | 🟡 **已修复**(但代码已替换) |
| **验证** | 新 `attachment_picker_section.dart:32` `maxCount = 9`(默认) — 实际**不是 3 了**,产品决策变了 |
| **关联** | N-1 |

### M-11: 8 个固定颜色,不让用户自定义

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-12: `expense_create_screen.dart` 默认货币 `CNY` 不可改

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-13: 数字键盘 0 开头逻辑混乱

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-14: `split_calculator_test.dart` 期望值用精确 double 比较

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-15: `Attachment` 模型注册了 Adapter 但功能未实现

| 字段 | 内容 |
|---|---|
| **v2 状态** | ✅ **已修复** — V1.2 step 1/2/3/4 完整实现 |
| **v2 验证** | `attachment_model_test.dart` + `attachment_picker_section_test.dart` + `attachment_thumb_test.dart` + `expense_list_attachment_badge_test.dart` 都有 |
| **关联** | N-1(stub 残留) |

### M-16: `_fireRemote` 用 `catchError((_) {})` 静默吞错

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-17: `GroupSettlement.transfers` 永远为空数组(命名 misleading)

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-18: 5 个 push 方法不更新 syncStatus

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-19: supabase_settings 错误信息含 stack trace

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-20: 删除 trip 无二次校验

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-21: `pubspec.yaml` 缺 lint 自定义

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-22: `roadmap.md` Epic 状态全部"未开始"

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-23: `roadmap.md` "原 E-008/009/010" 编号搞反

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-24: `daily-reports/` 和 `meeting-notes/daily-*.md` 职责不清

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-25: TripRepository.delete 不级联删 member/group/expense/transfer

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-26: `expense_detail_screen.dart` 显示删除者

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-27: `Expense.amount` 用 `double` 而 schema 用 `BIGINT cents`

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-28: `SettlementEngine.compute` 累加 double 总金额

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-29: `Trip.fromDb` 'active' 分支没测试

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-30: PRD v0.3 三个 P0 功能 lib/ 中 0 个相关文件

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-31: `equalAll` + `equalSelected` 实现完全相同

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-32: `Trip.baseCurrency` 没 assert 长度

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### M-33: 5 个 repository create/update 不校验 amount > 0

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

---

## 🟢 L(轻微,14 条)

> **v2 评估**:L 类 14 条 = v1 的 16 条 - 2 条(部分场景已修复或重命名)。

### L-1: `Trip.copyWith` sentinel object 风格不统一

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-2: `TransferRecord` 缺 `currency` 字段

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-3: `_DatePickerTile` 在 trip_create/trip_edit 复制粘贴

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-4: 主题色硬编码 4 处

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-5: `TextFormField` validator 缺长度校验

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-6: `test/` 缺很多 unit / integration 测试

| 字段 | 内容 |
|---|---|
| **v2 状态** | 🟡 部分修复 — V1.2 加了 4 个 attachment 测试 |

### L-7: `ExpenseRepository.create` updatedAt 在 update 里

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-8: `TODO` 注释 `ai_config.dart:46`

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-9: `auth_screen.dart` 中文硬编码

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-10: `Riverpod 2.x` 用 `StateNotifierProvider` 是 deprecated

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-11: `seed_data.dart` 硬编码 demo trip `member-demo-001`

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-12: `AuthScreen` 的 `Navigator.pop` "即将同步" 是空话

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |
| **关联** | S-5(sync 没启) |

### L-13: `analysis_options.yaml` 注释

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

### L-14: `Color(0xFF2E7D32)` 等硬编码

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未修复 |

---

## 🔵 N(战略待决,3 条)

### V1N-1: PRD v0.3 三个 P0 功能(语音/重复/统计)做不做?

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未决策(沿用 v1) |
| **详见** | `04-strategic-decisions.md` |

### V1N-2: 领先 origin/main commit 何时推?推到哪?

| 字段 | 内容 |
|---|---|
| **v2 状态** | ❌ 未决策 |
| **v2 现状** | 项目文件结构多了 7 个 dart + 3 个 sql,领先量更大 |

### V1N-3: Android 模拟器问题(已决策跳过)

| 字段 | 内容 |
|---|---|
| **v2 状态** | ✅ 沿用 v1 决策,跳过 |

---

## 🆕 V2-X(v2 新增,8 条)

> **v2 评估新发现**。在 v1 评估(2026-07-12)之后,2026-07-14 重新扫描发现的新问题。

### V2-1: `expense_detail_screen.dart` 留有 `_addAttachment` 空 stub 函数

| 字段 | 内容 |
|---|---|
| **文件** | `lib/presentation/screens/expense_detail_screen.dart:466` |
| **严重度** | 🟢 L(代码整洁) |
| **现状** | `Future<void> _addAttachment() async { /* 已被 AttachmentPickerSection 取代 */ }`,第 465 行注释明确"保留 stub 以避免残留引用报错" |
| **影响** | grep 看到这个函数会让维护者困惑 —— 是"还在用"还是"已废弃"? |
| **修复** | 删整个 stub 函数 + 注释;或加 `@Deprecated('Use AttachmentPickerSection')` |
| **关联** | S-13(已部分修) |

### V2-2: `_cloudVersion` 注释仍是谎言,代码里没这 map

| 字段 | 内容 |
|---|---|
| **文件** | `lib/data/sync/sync_engine.dart:21` |
| **严重度** | 🔴 S(注释撒谎是技术债) |
| **现状** | 注释 `Trip/Member/Group 当前没这个字段,所以用 _cloudVersion map 单独追踪`,但代码里完全没这个 map 字段 |
| **影响** | Trip/Member/Group/Transfer 4 个实体 sync 状态**完全没追踪**;sync 失败 UI 不知道;重启 app 不再 sync 哪些条目 |
| **修复** | (1) 删注释,承认未实现;或 (2) 给这 4 个实体加 `cloudVersion: int` 字段(Hive typeId 加 + schema 加) |
| **v2 提升** | 这跟 v1 S-26 同根因,但 v2 重新发现并独立编号 |
| **关联** | S-5 / S-6 |

### V2-3: 2 个 `SupabaseConfig` 类名冲突(`lib/config/` vs `lib/core/supabase/`)

| 字段 | 内容 |
|---|---|
| **文件** | `lib/config/supabase_config.dart`(新,93 行)+ `lib/core/supabase/supabase_config.dart`(旧,45 行) |
| **严重度** | 🟡 M(命名冲突) |
| **现状** | 两个文件**类名都是 `SupabaseConfig`**;新 `lib/config/` 用 `String.fromEnvironment` 编译时注入,旧 `lib/core/supabase/` 用 `defaultValue` 占位字符串 |
| **影响** | (1) import 哪个取决于文件路径;Dart 编译器遇到同类名不同 import 会冲突 (2) `core/supabase/supabase_config.dart` 默认 `https://your-project.supabase.co`,**如果是 build 没传 --dart-define,会被误以为是"已配置"**(因为 `isConfigured` 不会过滤默认值,只在 `core` 版过滤) |
| **修复** | (1) 删 `core/supabase/supabase_config.dart` 整个文件 (2) 保留 `config/supabase_config.dart` 作为唯一源 (3) 验证 `main.dart` 引用的是 `config/supabase_config.dart`(目前是 — 第 5 行 import) |
| **验证** | `grep -rn "class SupabaseConfig" lib/` 应只 1 命中 |

### V2-4: `项目文件目录结构一览表.md` 7-8 之后没更新,所有数字过时

| 字段 | 内容 |
|---|---|
| **文件** | `docs/03-management/项目文件目录结构一览表.md` |
| **严重度** | 🔴 S(同 S-16,v2 加重) |
| **现状(v2 量化)** | 一览表写 196 文件 / 64 dart / 60 md / 2 sql / 10890 行 / 225 测试,实际:50 md / 54 dart(含 .g.dart 60) / 3 sql / 测试 22 文件 / 业务代码量超 12000 行;**新增 `lib/config/` 子目录、新增 `app_settings`/`attachment` 7 个 model+repo、`split_rule_edit_page`、`about_screen` 等屏幕都没登记** |
| **影响** | 新成员按一览表找文件会迷路(`attachment_repository.dart` / `app_settings.dart` / `split_rule_edit_page.dart` / `verification/` / `troubleshooting/` 全部不在) |
| **修复** | 跑 `find . -name "*.dart" -not -name "*.g.dart" \| wc -l` + `find . -name "*.md"` + `wc -l lib/**/*.dart` 重写整个一览表 |
| **关联** | S-16 |

### V2-5: `release/v1.2-step2/3/4-local/` 3 个目录没 README/CHANGELOG

| 字段 | 内容 |
|---|---|
| **文件** | `release/v1.2-step2-local/`、`release/v1.2-step3-local/`、`release/v1.2-step4-local/` |
| **严重度** | 🟡 M(违反自己定的规范) |
| **现状** | 每个目录只有 `ai-travel-ledger-v1.2-stepN.apk`,**没 README.md 也没 CHANGELOG.md**;其他版本(v0.2.0、v1.0.0-local、v1.2.0+0-cloud)都有 |
| **影响** | (1) 这 3 个版本是什么、谁测的、改了什么无从查 (2) 跟 `docs/02-architecture/07-release-build-guide.md` 的"每个版本必须有 CHANGELOG.md"规范不一致 |
| **修复** | 每个目录补 README.md(版本日期 + SHA1 + 改了什么 + 已知问题) |
| **关联** | S-14(keystore 关联) |

### V2-6: `pubspec.yaml` `dependency_overrides.app_links: 6.3.1` 仍未文档化

| 字段 | 内容 |
|---|---|
| **文件** | `pubspec.yaml` |
| **严重度** | 🔴 S(同 S-18,v2 独立编号) |
| **现状** | V1.2 step 1-4 期间引入了新 widget + image_picker + cached_network_image 等,**app_links override 没解释原因**;tech-stack.md / ADR 都没提 |
| **修复** | tech-stack.md 加 "Known workaround: app_links 6.4.1 与 Flutter 3.x 不兼容,锁 6.3.1,见 ISSUE-2026-07-09-01" |
| **关联** | S-18 |

### V2-7: `CHANGELOG.md` 提到 V1.2 + `MILESTONE.md` 提到 v1.2.0+0-cloud-milestone,但项目当前实际 commit 状态可能不对齐

| 字段 | 内容 |
|---|---|
| **文件** | `CHANGELOG.md`(109 行)+ `MILESTONE.md`(99 行) |
| **严重度** | 🟡 M(文档一致性) |
| **现状** | `MILESTONE.md` 写"包含 83 个 commits + 250/250 测试" —— 但我**没逐行验证**这跟实际 git log 对得上;CHANGELOG v1.2 step 1-4 拆得很细,但 release/ 下只有 step2/3/4 的 APK,**没有 step1 的 APK 目录**(奇怪) |
| **影响** | 文档吹的 "83 commits" / "250 tests" 实际可能不是 |
| **修复** | (1) 跑 `git log --oneline \| wc -l` + `flutter test --reporter=compact \| wc -l` 实际数字 (2) 校对 CHANGELOG 每条对应 commit (3) 缺失的 step1 APK 目录补 README |
| **未验证项** | 标记为 **🔵 推测**,需要跑实际命令确认 |

### V2-8: `issue-tracker.md` 维护滞后 — 写"最后同步 2026-07-12 01:35",V1.2 + cloud-milestone 发布后没新增对应 ISSUE

| 字段 | 内容 |
|---|---|
| **文件** | `docs/03-management/issue-tracker.md:737` |
| **严重度** | 🟡 M |
| **现状** | issue-tracker 最后同步时间 2026-07-12 01:35;之后 V1.2 step 1/2/3/4 + cloud + cloud-milestone 全部发布(7-12 ~ 7-14),issue-tracker 没新增任何 V1.2 相关条目(如"附件上传 Step 1 数据层实现"、"Step 2 UI 集成"、"Cloud 编译时配置重构"、"Milestone 徽章实现"等) |
| **影响** | 重大功能上线不进 issue-tracker,问题跟踪失真 |
| **修复** | 跑 `git log --oneline 2026-07-12..HEAD` 找到 V1.2 相关 commit,每个 commit 对应 1 个 ISSUE 条目 |
| **关联** | S-15(整体文档失修的一部分) |

---

## 总结表

| 类别 | 数量 | v2 状态 |
|---|---|---|
| 🔴 S 严重 | 27 | 27 ❌ 未修 |
| 🟡 M 中等 | 34 | 32 ❌ + 2 ✅(M-10/M-15) |
| 🟢 L 轻微 | 14 | 14 ❌ |
| 🔵 N 战略 | 3 | 沿用 v1 |
| 🆕 V2-X v2 新增 | 8 | 待处理 |
| **总计** | **85** | |

**完整修复优先级和行动方案**见 [03-fix-priorities.md](03-fix-priorities.md)

**横向分类汇总**见 [02-by-category.md](02-by-category.md)

**1 页执行摘要**见 [05-evaluation-summary.md](05-evaluation-summary.md)