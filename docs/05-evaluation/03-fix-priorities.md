# 修复优先级与行动方案

**基于**:`01-evaluation-checklist.md` 81 条 + `02-by-category.md` 横向汇总
**修复窗口**:立即(今天) / 本周 / 下周 / 月度 / 决策窗口

**核心原则**:
- **同一根因的问题一起修**(避免散乱 PR,降低 review 成本)
- **发布前必须全修** 🔴 S-1 ~ S-27(27 条)
- **决策问题** 🔵 N-1 / N-2 必须**先决策**再动手(否则文档没法修)

---

## ⏰ 立即修(今天内,4 个 PR)

> **为什么今天**:这些是**用户能立刻看到**或者**能阻止部署**的 bug。
> 不修等于产品里有 4 颗"裸露"的地雷。

### PR-1: 隐私硬编码移除(15 分钟)

**问题**:S-3 / S-4

**改动**:
- 删 `lib/presentation/screens/about_screen.dart:14` 的 `_authorEmail` 常量,改为留邮箱引导
- 改 `auth_screen.dart:113` 的 `litiboy@163.com` 文字 → `请联系开发者(应用内 → 关于 → 项目主页)`
- 改 `supabase_settings_screen.dart:190` 的真实 URL → `https://YOUR-PROJECT.supabase.co`
- 改 `supabase_settings_screen.dart:415` 同样替换

**验证**:
```bash
cd "C:/Users/jiaqi/.openclaw/workspace/projects/ai-travel-ledger"
grep -rn 'litiboy@163.com' lib/  # 应 0 命中
grep -rn 'zvqnawllsdmisntkxdwp' lib/  # 应 0 命中
```

**风险**:无(纯字符串替换)

---

### PR-2: 00003 SQL 两个 bug(30 分钟)

**问题**:S-1 / S-2

**改动**:
- `supabase/migrations/00003_expense_attachments_storage.sql:65,76,91`:`public.collaborators` → `public.trip_collaborators`
- `supabase/migrations/00003_expense_attachments_storage.sql:113-123`:触发器改写
  ```sql
  -- 原:NEW.attachments := ARRAY(SELECT jsonb_array_elements_text(COALESCE(NEW.attachment_metadata->'items', '[]'::jsonb)));
  -- 新:
  NEW.attachments := ARRAY(
    SELECT (item->>'url')
    FROM jsonb_array_elements(NEW.attachment_metadata->'items') AS item
  );
  ```

**验证**(需本地 staging Supabase):
```sql
-- 部署后跑:
UPDATE expenses SET attachment_metadata = '{"items":[{"url":"https://x.com/a.jpg","fileName":"a","sizeBytes":1,"mimeType":"image/jpeg","uploadedAt":"2026-01-01"}]}'::jsonb WHERE id = 'test';
SELECT attachments FROM expenses WHERE id = 'test';
-- 期望: {https://x.com/a.jpg}  不是 {"url":...,"fileName":...} 这种 JSON 字符串
```

**风险**:**低**(只是 RLS 修名 + 触发器改写,生产没部署过这条)

---

### PR-3: 启动 sync engine + 修默认 syncStatus(1 小时)

**问题**:S-5 / S-6 / S-8 / S-9 / S-10 / S-26

**这是最关键的一个 PR,5 个问题同根因,必须一起改**

**改动**:
1. `lib/main.dart:80-98`,`runApp` 之前加:
   ```dart
   final engine = SyncEngine(boxes: boxes);
   engine.startAutoSync();
   ```
2. `lib/data/repositories/expense_repository.dart:186`:`syncStatus: SyncStatus.synced` → `syncStatus: SyncStatus.pending`
3. `lib/presentation/providers/trip_provider.dart:17`:`kCurrentUserId` 改为从 Supabase 读
4. `lib/presentation/providers/sync_providers.dart:56-68` + 增加 dispose:StreamSubscription 取消
5. `lib/data/sync/sync_engine.dart:20-21` 删 `_cloudVersion` 注释,加 `Map<String, int>` 字段追踪(本期只加骨架,完整实现放到 S-26 修复)

**验证**:
- 装 v0.2.0+2 APK
- 创建 trip
- Supabase Dashboard 看 trips 表有新行
- 断网 → 重连 → 看 syncStatus 从 pending 变 synced

**风险**:**中**(改默认 syncStatus 会让所有现有 local 数据的 syncStatus 重置为 pending,首次 push 后正常)

---

### PR-4: 修 _SettlementView 空成员崩溃(10 分钟)

**问题**:S-7

**改动**:`lib/presentation/screens/settlement_screen.dart:476`
```dart
// 原:tripId: members.first.tripId,
// 新:
tripId: members.isNotEmpty ? members.first.tripId : widget.tripId,
```

**风险**:**极低**(纯 if 守卫)

---

## 📅 本周内修(5 个 PR)

> 覆盖 S 类剩余 13 个 + 高优先级 M 类

### PR-5: 修 build 里 mutate state 系列(S-11 / S-12 / S-21 / S-22)

**改动**:
- `expense_create_screen.dart:86-87`:用 `addPostFrameCallback` 包 `_initDefaultPayer`
- `expense_detail_screen.dart:83-85`:同样改
- `expense_create_screen.dart:207-226`:失败时弹 Snackbar
- `expense_create_screen.dart:180-189`:数字键盘锁位震动反馈

**风险**:**中**(改 setState 模式可能引起 widget rebuild 时序问题,需手动测)

---

### PR-6: 4 层 when 改用 combine(S-24 / M-1)

**改动**:
- `lib/presentation/providers/settlement_provider.dart:65-129`:改成 `ref.watch([expenses, members, groups, records]).combine(...)`
- `lib/presentation/screens/settlement_screen.dart:43-66`:对应 UI 改
- `lib/presentation/screens/group_settlement_screen.dart:32-50`:对应 UI 改

**风险**:**中**(UI 重构,可能引入新 bug)

---

### PR-7: 改 5 个仓库 update 入口加"级联影响"检查(S-19 / S-26 / S-27 / M-9 / M-18 / M-25)

**改动**:
- `expense_repository.dart:update()` 改 amount 时,弹"会撤销已结清记录"确认
- `sync_engine.dart:_pushExpense` 不推 syncStatus/deletedAt
- `sync_engine.dart`:补 4 个 entity 的 `cloudVersion` 追踪
- `trip_repository.dart:delete()` 调其他 4 个 repo 的 `deleteAllByTrip`
- `trip_repository.dart:update()` 改 baseCurrency 联动 expense.currency

**风险**:**高**(级联逻辑易漏;一次性改多个 repository 风险大)

---

### PR-8: 重新生成 release keystore 强密码(S-14 / S-25)

**改动**:
```powershell
# 新密码 24+ 字符(用密码管理器)
keytool -genkey -v -keystore C:\Users\jiaqi\.android\ai-travel-ledger-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias ai-travel-ledger `
  -storepass "<新密码>" -keypass "<新密码>" `
  -dname "CN=AI Travel Ledger, O=jiaqi, C=CN"
```
- keystore 备份到 2+ 位置(密码管理器 + 加密 U 盘)
- `android/key.properties` 改新密码
- 旧 keystore 标记为"已废弃,仅用于本地测试"

**风险**:**极高**(丢失新 keystore = APP 永远无法升级)

---

### PR-9: PRD 三大 P0 决策 + 文档更新(S-15 / S-16 / S-17 / S-18 / M-22 / M-23 / M-24)

**问题**:N-1 战略决策

**改动**:**先决策再动文档**
- (1) 决策 N-1(详见 04-strategic-decisions.md)
- (2) 决策后:
  - 改 `docs/01-requirements/02-prd.md`:3 个 P0 改成 V1.1(如果选砍)
  - 改 `docs/02-architecture/03-data-model.md`:用 00001 SQL 重写
  - 改 `项目文件目录结构一览表.md`:用 `find` 重写
  - 改 `roadmap.md`:E-001/002/003/004 标"已完成",E-005/006/007 标"V1.1 Backlog"
  - 加 `pubspec.yaml` 的 app_links override 原因到 tech-stack.md

**风险**:**低**(纯文档)

### PR-9b: 输入校验 + 模型名校验(S-13 / S-20)

**问题**:S-13(附件 URL 不校验) + S-20(ai_config modelName 与实际端点不匹配)

**改动**:
- `expense_detail_screen.dart:414-444`:`Uri.tryParse` + scheme 校验 + 数量 ≤ 3
- `ai_config.dart:60`:`localQwen36.modelName` 改为可配置或拉 `/v1/models` 自动取
- `ai_config.dart`:本地 baseUrl 改成可设置(默认值仍 `http://192.168.1.60:8033/v1`)

**风险**:**中**(改 modelName 字段会影响所有现有选择)

---

## 🗓 下周内修(8 个 PR)

> 覆盖 M 类 30 个

### PR-10: 输入精度全面整改(S-23 / M-12 / M-27 / M-28 / M-32 / M-33)

**改动**:
- `expense_detail_screen.dart:230-238`:`inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))]`
- `expense.dart:175`:`double amount` → `int amountCents`,UI 用 `cents / 100` 渲染
- `sync_engine.dart:182`:用 cents 直接传
- `settlement_engine.dart:457-460`:累加 cents,UI 再除
- 5 个 repo create/update 加 `assert(amount > 0)`
- `Trip.baseCurrency` 字段加 `assert(value.length == 3)`
- expense_create 详情页加 currency 下拉,默认 inherit from trip

**风险**:**高**(改数据模型,需要数据迁移)

---

### PR-11: 测试补全(M-8 / M-14 / M-29 / L-8)

**改动**:
- `test/domain/split_calculator_test.dart`:改 `==` 为 `closeTo`
- 加 `test/data/trip_repository_test.dart`:`Trip.fromDb` 'active' 分支 3 个 case
- 加 `test/data/sync_e2e_test.dart`:5 个 entity 的 push/pull 测试
- 加 `test/data/attachment_repository_test.dart`(或删附件代码)

**风险**:**低**

---

### PR-12: 错误处理统一(M-5 / M-6 / M-16 / M-19)

**改动**:
- `lib/core/logging.dart` 新建:简易 logger
- `auth_screen.dart:76`:`if (e is AuthException && e.code == 'email_not_confirmed')` (不用字符串匹配)
- `sync_providers.dart:81-83, 100-103`:catch 用 logger.error + i18n 映射
- 5 个 repo 的 `_fireRemote`:`catchError((e, st) => logger.error('sync failed: $e', e, st))`
- `supabase_settings_screen.dart:107-108`:只显示友好提示,详细 error 写 logger

**风险**:**中**

---

### PR-13: Lint + 分析规则(M-21 / L-11 / L-16)

**改动**:
- `analysis_options.yaml`:启用 `unawaited_futures`、`always_declare_return_types`、`prefer_const_constructors`、`avoid_print`(只 disable 必要)
- 删 `ai_config.dart:46` TODO
- 删 `analysis_options.yaml:24-25` 注释

**风险**:**低**

---

### PR-14: 修复 push 残留问题(M-7 / M-8 / M-18)

**改动**:
- `sync_engine.dart:_pullChanges` 补 4 个 entity 的 pull
- `sync_engine.dart:_pushExpense` 失败 save 失败时用 logger
- 5 个 entity 的 push 都加 `cloudVersion` 字段更新

**风险**:**中**

---

### PR-15: UI 反馈 + 输入限制(M-3 / M-11 / M-13 / M-20 / M-10 / L-7)

**改动**:
- `_parseColor` 提到 `core/utils/color_utils.dart`,支持 3/8 位 hex(消除 M-2/M-3 重复)
- 4 处 8 色硬编码改成 8 + 自定义拾色器
- 数字键盘 0 开头逻辑重写
- 删除 trip 弹窗加"输名字确认"
- 详情页 attachment 加 `>=3` 校验
- `trip_create_screen` destination validator 限 100 字

**风险**:**低**

---

### PR-16: 数据迁移 + 备份(M-24 / M-25)

**改动**:
- 合并 `daily-reports/` 和 `meeting-notes/daily-*.md` 成 `daily-logs/`
- `TripRepository.delete` 调 4 个 `deleteAllByTrip`
- 5 个 repository 各自 `deleteAllByTrip` 已存在,串联调用

**风险**:**中**(级联删除易漏)

---

### PR-17: 修 `tripByIdProvider` 响应式 + 颜色主题(M-4 / L-6)

**改动**:
- `trip_provider.dart:40-45` 改 `StreamProvider.autoDispose.family`
- `expense_provider.dart:24-29` 同上
- `lib/core/theme/colors.dart` 新建,集中 6 个主色

**风险**:**低**

---

## 📆 月度清理(13 个 L + 7 个 M = 20 条)

> 代码风格 / 一致性 / 优化点,大扫除时统一修

### L-1: 重复代码提取(L-3 / L-5)

- `Member.copyWith` sentinel 提到项目级
- `_DatePickerTile` 提到 `lib/presentation/widgets/date_picker_tile.dart`
- 4 处 `_parseColor` 提到 `color_utils.dart`

### L-2: 死代码清理(L-2 / L-9 / L-11 / L-14 / L-15 / L-16)

- `TransferRecord` 加 `currency` 字段
- 删 `ai_config.dart:46` TODO
- 删 `seed_data.dart` demo hardcoded createdBy
- 修 `trip_list_screen.dart:218-222` "即将同步"空话
- 删 `analysis_options.yaml:24-25` 注释

### L-3: 测试补充(L-8 / M-29)

- 各 repository 补 unit test

### L-4: i18n 基础(L-12 / L-13)

- 抽 `l10n/` 文件,准备 V1.1 多语言

### L-5: UI polish(L-6 / L-13)

- 颜色主题集中
- 类别筛选 chip 加渐变 fade 提示

### L-6: 技术债(L-10)

- `StateNotifierProvider` → `NotifierProvider`(全项目重构)

### L-7: 小修(M-29 / M-31)

- `Trip.fromDb` 'active' 分支加测试
- `equalSelected` 合并到 `equal`

### L-8: 模型一致性(M-2 已合并,跳过)

- 已在 M-2 处理

---

## 🔵 战略决策(在动手前必须做)

> **不决策,代码会越改越乱**

### D-1: PRD v0.3 三大 P0 决策(N-1)

**选项**:
- (A) 砍掉,降级 V1.1(推荐)
- (B) 加快实现(预计 1-2 周)
- (C) 继续"在路上" — 不推荐,产品诚信风险

**详见** `04-strategic-decisions.md` N-1

**影响**:
- (A) → 改 PRD / roadmap / 用户故事 / 一览表,删除 feature request
- (B) → 补 3 个 model + 1 个 statistics screen + 1 个 recurring expenses worker
- (C) → 现状维持,所有文档/代码脱节继续

### D-2: 领先 20 commit 推送策略(N-2)

**选项**:
- (A) 推 Gitee(国内快)+ GitHub(代理)
- (B) 推 Gitee 单仓
- (C) 暂存不推,本地发布新版本

**详见** `04-strategic-decisions.md` N-2

**影响**:
- (A) → 设 main 只读,dev 开发,PR review 流程
- (B) → 简单,但只有国内访问
- (C) → 团队单干 OK,有外部协作者会失联

---

## 📊 修复后状态预测

假设所有 P0 全部修完,**未修 N 类**前后的对比:

| 指标 | 修复前 | 修复后 | 提升 |
|---|---|---|---|
| 已知严重 bug | 27 | 0 | 100% |
| 已知中等问题 | 35 | 0 | 100% |
| 代码覆盖率 | ~85% | ~95% | +10% |
| 文档 vs 代码一致度 | 60% | 95% | +35% |
| APK 大小 | 24.9 MB | ~25.5 MB | 几乎不变 |
| 真机崩溃率 | 估计 > 0.1% | < 0.01% | -99% |
| 同步可用性 | 0% | 100% | **从 0 到 1** |
| 隐私泄露面 | 3 个文件 | 0 | 100% |

---

## ⏱ 时间估算

| 阶段 | 工作量 | 累计 |
|---|---|---|
| 今天(4 个 PR) | 2 小时 | 2h |
| 本周(5 个 PR) | 12-16 小时 | ~16h |
| 下周(8 个 PR) | 20-30 小时 | ~40h |
| 月度(20 个 L/M) | 16-20 小时 | ~60h |
| 决策(2 个) | 1-2 小时讨论 | ~62h |

**约 8 个工作日**(1.5 周单人)可全部完成,前提是 D-1 / D-2 决策已做。

---

## 🚦 风险等级(修每个 PR 前要看的)

| PR | 风险 | 需要 reviewer 数量 |
|---|---|---|
| PR-1 (隐私) | 🟢 极低 | 1 |
| PR-2 (SQL) | 🟡 低(没生产) | 1 + DBA |
| PR-3 (sync) | 🟠 中(改默认状态) | 2 |
| PR-4 (崩溃守卫) | 🟢 极低 | 1 |
| PR-5 (build mutate) | 🟡 中 | 1 |
| PR-6 (when 重构) | 🟠 中(UI 重构) | 2 |
| PR-7 (级联) | 🔴 高(级联) | 2 + 架构 |
| PR-8 (keystore) | 🔴 极高(丢失不可逆) | 用户亲自 |
| PR-9 (文档) | 🟢 低 | 1 |
| PR-10 (精度) | 🟠 中(数据迁移) | 2 |
| PR-11 (测试) | 🟢 低 | 1 |
| PR-12 (错误处理) | 🟡 中 | 1 |
| PR-13 (lint) | 🟢 低 | 1 |
| PR-14 (push 残留) | 🟡 中 | 1 |
| PR-15 (UI 反馈) | 🟢 低 | 1 |
| PR-16 (级联) | 🟡 中 | 1 |
| PR-17 (响应式) | 🟢 低 | 1 |

---

## ✅ 完成定义(Definition of Done)

每个 PR 必须满足:

- [ ] 代码通过 `flutter analyze`
- [ ] 相关单元测试加 + 通过
- [ ] 至少一次真机/模拟器验证(除 PR-2/8/9)
- [ ] 如果改了 schema,跑了 `supabase db reset + 重新应用 00001/00002/00003`
- [ ] 关联 issue 状态在 issue-tracker.md 更新
- [ ] 一览表跟实际一致(改了 lib/ 就要回写一览表)

---

*完成时间:2026-07-12 | 总工作量:约 62 工时 | 决策阻塞:2 个 N-类*
