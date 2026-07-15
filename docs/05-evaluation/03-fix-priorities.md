# 修复优先级与行动方案 (v2)

**基于**:`01-evaluation-checklist.md` 86 条(v2)+ `02-by-category.md` 横向汇总
**修复窗口**:立即(今天) / 本周 / 下周 / 月度 / 决策窗口

**v2 修复原则**:
- **同一根因的问题一起修**(避免散乱 PR,降低 review 成本)
- **发布前必须全修** 🔴 S-1 ~ S-27(27 条,全部 ❌ 未修)
- **新增 v2 项** 🆕 V2-1 ~ V2-8 必须并入对应窗口处理
- **决策问题** 🔵 N-1 / N-2 必须**先决策**再动手(否则文档没法修)

**v2 与 v1 区别**:
- v1 修复后状态预测:**27 个 S → 0 个 S**;**v2 现实是 S 类 0 修复**
- v1 估计工作量 ~62 工时;**v2 实际工作量 = 60 + v2 新增 8 项 ≈ 68 工时**
- v2 不重写 PR 计划(沿用 v1),只**追加 v2 新发现项到对应窗口**

---

## ⏰ 立即修(今天内,4 + 1 = 5 个 PR)

> **为什么今天**:这些是**用户能立刻看到**或者**能阻止部署**的 bug。
> 不修等于产品里有 5 颗"裸露"的地雷。

### PR-1: 隐私硬编码移除(15 分钟) — **沿用 v1**

**问题**:S-3 / S-4

**改动**:
- 改 `lib/presentation/screens/about_screen.dart:20` 的 `_authorEmail` 常量 → `请联系开发者(应用内 → 关于 → 项目主页)`
- 改 `auth_screen.dart:112` 的 `litiboy@163.com` 文字
- 改 `supabase_settings_screen.dart:190` 的真实 URL → `https://YOUR-PROJECT.supabase.co`
- 改 `supabase_settings_screen.dart:415` 同样替换

**验证**:
```bash
cd "C:/Users/jiaqi/.openclaw/workspace/projects/ai-travel-ledger"
grep -rn 'litiboy@163.com' lib/  # 应 0 命中
grep -rn 'zvqnawllsdmisntkxdwp' lib/  # 应 0 命中
```

**风险**:无(纯字符串替换)

### PR-2: 00003 SQL 两个 bug(30 分钟) — **沿用 v1**

**问题**:S-1 / S-2

**改动**:
- `supabase/migrations/00003_expense_attachments_storage.sql:65,76,91`:`public.collaborators` → `public.trip_collaborators`
- `supabase/migrations/00003_expense_attachments_storage.sql:113-123`:触发器改写

**验证**(需本地 staging Supabase):
```sql
UPDATE expenses SET attachment_metadata = '{"items":[{"url":"https://x.com/a.jpg","fileName":"a","sizeBytes":1,"mimeType":"image/jpeg","uploadedAt":"2026-01-01"}]}'::jsonb WHERE id = 'test';
SELECT attachments FROM expenses WHERE id = 'test';
```

**风险**:**低**(只是 RLS 修名 + 触发器改写,生产没部署过这条)

### PR-3: 启动 sync engine + 修默认 syncStatus(1 小时) — **沿用 v1**

**问题**:S-5 / S-6 / S-8 / S-9 / S-10 / S-26

**改动**:
1. `lib/main.dart:80-98`,`runApp` 之前加:
   ```dart
   final engine = SyncEngine(boxes: boxes);
   engine.startAutoSync();
   ```
2. `lib/data/repositories/expense_repository.dart:186`:`syncStatus: SyncStatus.synced` → `syncStatus: SyncStatus.pending`
3. `lib/presentation/providers/trip_provider.dart:17`:`kCurrentUserId` 改为从 Supabase 读
4. `lib/presentation/providers/sync_providers.dart:56-68` + 增加 dispose:StreamSubscription 取消
5. `lib/data/sync/sync_engine.dart:20-21` 删 `_cloudVersion` 注释,加 `Map<String, int>` 字段追踪

**风险**:**中**(改默认 syncStatus 会让所有现有 local 数据的 syncStatus 重置为 pending,首次 push 后正常)

### PR-4: 修 _SettlementView 空成员崩溃(10 分钟) — **沿用 v1**

**问题**:S-7

**改动**:`lib/presentation/screens/settlement_screen.dart:476`
```dart
// 原:tripId: members.first.tripId,
// 新:
tripId: members.isNotEmpty ? members.first.tripId : widget.tripId,
```

**风险**:**极低**

### PR-5(🆕 v2): 删 `_addAttachment` stub + 修 SupabaseConfig 命名冲突(15 分钟)

**问题**:V2-1 + V2-3

**改动**:
- `lib/presentation/screens/expense_detail_screen.dart:466`:删 `_addAttachment` 函数 + 第 465 行注释
- `lib/core/supabase/supabase_config.dart`:整个文件**删掉**(因为 `lib/config/supabase_config.dart` 已替代)
- 验证:`grep -rn "class SupabaseConfig" lib/` 应只 1 命中

**风险**:**低**(删 dead code + 1 个文件)

**验证**:
```bash
cd "C:/Users/jiaqi/.openclaw/workspace/projects/ai-travel-ledger"
grep -n "class SupabaseConfig" lib/config/supabase_config.dart lib/core/supabase/supabase_config.dart
# 期望: 只 lib/config/supabase_config.dart 有 1 命中
grep -rn "_addAttachment\|public.collaborators" lib/
# 期望: 0 命中
```

---

## 📅 本周内修(5 + 2 = 7 个 PR)

> 覆盖 S 类剩余 13 个 + 高优先级 M 类 + v2 新增 2 项

### PR-5a(🆕 v2): 3 个 release 目录补 README(30 分钟)

**问题**:V2-5

**改动**:
- `release/v1.2-step2-local/README.md`:版本日期 + SHA1 + 改了什么 + 已知问题
- `release/v1.2-step3-local/README.md`:同上
- `release/v1.2-step4-local/README.md`:同上

**风险**:**极低**(纯文档)

### PR-5b(🆕 v2): app_links override 文档化 + 一览表重写(45 分钟)

**问题**:V2-6 + V2-4(部分)+ S-16 + S-17

**改动**:
- `docs/02-architecture/01-tech-stack.md`:加 "Known workaround: app_links 6.4.1 与 Flutter 3.x 不兼容,锁 6.3.1,见 ISSUE-2026-07-09-01"
- `docs/03-management/项目文件目录结构一览表.md`:用 `find` 跑一遍重写,数字精确

**风险**:**极低**(纯文档)

### PR-6: 修 build 里 mutate state 系列(S-11 / S-12 / S-21 / S-22) — 沿用 v1

**改动**:
- `expense_create_screen.dart:91`:用 `addPostFrameCallback` 包 `_initDefaultPayer`
- `expense_detail_screen.dart`:同样改
- `expense_create_screen.dart:_submitAndContinue`:失败时弹 Snackbar
- `expense_create_screen.dart:180-189`:数字键盘锁位震动反馈

**风险**:**中**

### PR-7: 4 层 when 改用 combine(S-24 / M-1) — 沿用 v1

**改动**:
- `lib/presentation/providers/settlement_provider.dart:65-129`:改成 `ref.watch([expenses, members, groups, records]).combine(...)`
- `lib/presentation/screens/settlement_screen.dart:43-66`:对应 UI 改
- `lib/presentation/screens/group_settlement_screen.dart:32-50`:对应 UI 改

**风险**:**中**

### PR-8: 改 5 个仓库 update 入口加"级联影响"检查(S-19 / S-26 / S-27 / M-9 / M-18 / M-25) — 沿用 v1

**风险**:**高**

### PR-9: 重新生成 release keystore 强密码(S-14 / S-25) — 沿用 v1

**风险**:**极高**

### PR-10: PRD 三大 P0 决策 + 文档更新(S-15 / S-16 / S-17 / S-18 / M-22 / M-23 / M-24) — 沿用 v1

**问题**:N-1 战略决策

---

## 🗓 下周内修(8 + 1 = 9 个 PR)

> 覆盖 M 类 30 个 + v2 新增 1 项

### PR-11(🆕 v2): issue-tracker 增量更新(V2-8)

**问题**:V2-8

**改动**:
- 跑 `git log --oneline 2026-07-12..HEAD | wc -l`
- 找 V1.2 step 1/2/3/4 + cloud + milestone 相关的 commit
- 每个对应 1 个 ISSUE 条目(参考已有 ISSUE-026 风格)
- 改 issue-tracker.md 头部"最后同步"时间戳

**风险**:**低**

### PR-12: 输入精度全面整改(S-23 / M-12 / M-27 / M-28 / M-32 / M-33) — 沿用 v1

### PR-13: 测试补全(M-8 / M-14 / M-29 / L-8) — 沿用 v1

### PR-14: 错误处理统一(M-5 / M-6 / M-16 / M-19) — 沿用 v1

### PR-15: Lint + 分析规则(M-21 / L-8 / L-11 / L-13) — 沿用 v1

### PR-16: 修复 push 残留问题(M-7 / M-8 / M-18) — 沿用 v1

### PR-17: UI 反馈 + 输入限制(M-3 / M-11 / M-13 / M-20 / L-5) — 沿用 v1

### PR-18: 数据迁移 + 备份(M-24 / M-25) — 沿用 v1

### PR-19: 修 `tripByIdProvider` 响应式 + 颜色主题(M-4 / L-4) — 沿用 v1

### PR-9b: 输入校验 + 模型名校验(S-13 / S-20) — 沿用 v1(**注**:S-13 状态已改 → N-1 替代)

---

## 📆 月度清理(13 个 L + 7 个 M = 20 条)

> 沿用 v1 + v2 新增可加入

---

## 🔵 战略决策(在动手前必须做) — 沿用 v1

### D-1: PRD v0.3 三大 P0 决策(N-1)

**v2 状态**:仍未决。**v2 评估进一步强化了"必须砍"的论据**:V1.2 已经把 attachment 完整实现了(E-005 的子集),但 E-008/009/010 仍然 0 行代码。

**新决策选项(在 v1 基础上增加)**:
- (A) 砍掉,降级 V1.1(推荐) — v2 没新增反对理由
- (B) 加快实现(预计 1-2 周) — v2 显示 V1.2 期间**资源可以投入 7 个新 dart 文件,所以 1-2 周实现是可行的**
- (C) 维持现状 — 仍然不推荐

### D-2: 领先 origin/main commit 何时推?推到哪?(N-2)

**v2 状态**:仍未决。**v2 评估显示领先量更大**(V1.2 期间加了 7 个 dart + 4 个 test + 3 个 doc,共 ~14 个 commit 增量)。

### D-3: Android 模拟器问题(已决策跳过) — 沿用 v1

---

## 📊 v2 修复后状态预测

假设所有 v1 + v2 项全部修完,**未修 N 类**前后的对比:

| 指标 | v1 评估前 | v2 评估后(未修) | v2 修复后 |
|---|---|---|---|
| 已知严重 bug | 27 | 27 | 0 |
| 已知中等问题 | 35 | 34 | 0 |
| v2 新增问题 | 0 | 8 | 0 |
| 代码覆盖率 | ~85% | ~90%(V1.2 加了 4 test) | ~95% |
| 文档 vs 代码一致度 | 60% | 50%(V2-4 一览表更失修) | 95% |
| 同步可用性 | 0% | 0% | 100% |
| 隐私泄露面 | 3 个文件 | 3 个文件 | 0 |

---

## ⏱ 时间估算(v2)

| 阶段 | 工作量 | 累计 | 备注 |
|---|---|---|---|
| 立即(5 个 PR) | 2.25 小时 | 2.25h | 含 v2 新增的 PR-5(V2-1 + V2-3) |
| 本周(7 个 PR) | 13-17 小时 | ~17h | 含 v2 新增的 PR-5a / PR-5b |
| 下周(9 个 PR) | 21-31 小时 | ~42h | 含 v2 新增的 PR-11(V2-8) |
| 月度清理 | 16-20 小时 | ~62h | 沿用 v1 |
| 决策(2 个) | 1-2 小时讨论 | ~64h | D-1 / D-2 |
| **总计** | **~64-70 工时** | — | **约 8-9 个工作日** |

---

## 🚦 风险等级(v2)

| PR | v2 风险 | 变化(vs v1) |
|---|---|---|
| PR-1 (隐私) | 🟢 极低 | — |
| PR-2 (SQL) | 🟡 低 | — |
| PR-3 (sync) | 🟠 中 | — |
| PR-4 (崩溃守卫) | 🟢 极低 | — |
| PR-5 (v2:删 stub + 命名冲突) | 🟢 极低 | 🆕 新增 |
| PR-5a (v2:release README) | 🟢 极低 | 🆕 新增 |
| PR-5b (v2:override 文档 + 一览表) | 🟢 极低 | 🆕 新增 |
| PR-6 (build mutate) | 🟡 中 | — |
| PR-7 (when 重构) | 🟠 中 | — |
| PR-8 (级联) | 🔴 高 | — |
| PR-9 (keystore) | 🔴 极高 | — |
| PR-10 (文档) | 🟢 低 | — |
| PR-11 (v2:issue-tracker 增量) | 🟢 低 | 🆕 新增 |

---

## ✅ 完成定义(Definition of Done) — 沿用 v1 + v2 项

每个 PR 必须满足:

- [ ] 代码通过 `flutter analyze`
- [ ] 相关单元测试加 + 通过
- [ ] 至少一次真机/模拟器验证(除 PR-2/9/10)
- [ ] 如果改了 schema,跑了 `supabase db reset + 重新应用 00001/00002/00003`
- [ ] 关联 issue 状态在 issue-tracker.md 更新(PR-11 已规划)
- [ ] **v2 新增**:一览表跟实际一致(改了 lib/ 就要回写一览表,PR-5b 部分涵盖)
- [ ] **v2 新增**:`grep -rn "litiboy\|zvqnawllsdmisntkxdwp\|public.collaborators" lib/` 必须 0 命中
- [ ] **v2 新增**:`grep -rn "class SupabaseConfig" lib/` 必须只 1 命中

---

*完成时间:2026-07-14 | v2 总工作量:约 64-70 工时 | v1→v2 净增工作量:8-10 工时 | 决策阻塞:2 个 N-类*