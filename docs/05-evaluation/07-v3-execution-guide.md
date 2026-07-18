# AI 旅行账本 — v3 修复执行指南(给 OpenClaw 继续使用)

> **生成时间**:2026-07-15 14:35
> **来源**:v3 评估报告(`06-v3-post-fix-report.md`)的 14 个未修 S + 战略决策
> **目标用户**:OpenClaw (其他 agent) 继续执行修复
> **状态**:**本报告只描述,不动手** — 由 OpenClaw 按 PR 编号逐个执行

---

## 📊 当前状态摘要(给 OpenClaw 上下文)

**项目**:`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\`

| 指标 | 数值 |
|---|---|
| 7-15 修复率 | 19.8%(17/86) |
| S 严重类未修 | **14 项** |
| M 中等类未修 | 33 项 |
| L 轻微类未修 | 14 项 |
| 🆕 V2-X 未修 | 6 项 |
| 战略未决 | 1 项(V1N-2:领先 commit 推送) |
| 总待修 | **68 项** |

**已完成**(不要再动):
- ✅ PR-1 隐私硬编码移除
- ✅ PR-2 SQL bug 修复
- ✅ PR-3 sync engine 启动 + 默认 pending + kCurrentUserId 函数化
- ✅ PR-4 空成员崩溃守卫
- ✅ PR-5 命名冲突 + stub 删除
- ✅ V1N-1 PRD 三大 P0 砍掉
- ✅ S-14/S-25 keystore 强密码

---

## 🎯 优先级(按发布前必须 → 月度)

### 第一梯队(本周修,4 个 PR,4 小时,8 个 S)

#### PR-A:UI state 隐性 bug 修复(90 分钟) — 修 S-10 / S-11 / S-12

| ID | 严重度 | 文件 | 行 | 简述 |
|---|---|---|---|---|
| S-10 | 🔴 S | `lib/presentation/providers/sync_providers.dart` | 38-68 | `AuthNotifier._init()` 的 `authStateChanges.listen()` StreamSubscription 永远不取消 |
| S-11 | 🔴 S | `lib/presentation/screens/expense_create_screen.dart` | 91 | `if (_payer == null) { _initDefaultPayer(members); }` 在 build 里 mutate state |
| S-12 | 🔴 S | `lib/presentation/screens/expense_detail_screen.dart` | (build 内) | build 里 mutate TextEditingController |

**修复要求**:

**S-10**:
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.signedOut) {
    _init();
  }

  StreamSubscription? _authSub;  // ← 新增

  void _init() {
    if (!SupabaseService.instance.isInitialized) return;
    final user = SupabaseService.instance.auth.currentUser;
    if (user != null) {
      state = AuthState(isSignedIn: true, email: user.email, userId: user.id);
    }
    _authSub = SupabaseService.instance.authStateChanges.listen((authState) {
      // ... 现有代码
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
```

**S-11**:
```dart
// 改前 (line 91):
if (_payer == null) {
  _initDefaultPayer(members);
}

// 改后:
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted && _payer == null) {
    setState(() => _initDefaultPayer(members));
  }
});
```

**S-12**:
跟 S-11 同款 — 用 `addPostFrameCallback` 包 `_initFromExpense(expense)`

**验证**:
- `flutter analyze` 0 errors
- 反复登录/登出 10 次,logcat 不报 "setState() called after dispose()"
- 清数据 → 开 app → 点 "记一笔" → 第一次 build 立即显示默认 payer

**风险**:中 — setState 时序可能引起 widget rebuild 问题,需手动测

---

#### PR-B:同步推云端字段清理(30 分钟) — 修 S-19

| ID | 严重度 | 文件 | 行 | 简述 |
|---|---|---|---|---|
| S-19 | 🔴 S | `lib/data/sync/sync_engine.dart` | 175-200 | `_pushExpense` 把本地 syncStatus/deletedAt 推到云 |

**修复要求**:
```dart
// 改前 (line 178-189):
await client.from('expenses').upsert({
  'id': expense.id,
  'trip_id': expense.tripId,
  'payer_id': expense.payerId,
  'amount_cents': (expense.amount * 100).round(),
  'currency': expense.currency,
  'category': expense.category.name,
  'description': expense.description,
  'occurred_at': expense.occurredAt.toIso8601String(),
  'split_rule_json': _parseSplitRule(expense.splitRuleJson),
  'created_by': _supabase.currentUserId,
});

// 改后:删掉 syncStatus 和 deletedAt 字段 (它们是本地状态,不该同步)
await client.from('expenses').upsert({
  'id': expense.id,
  'trip_id': expense.tripId,
  'payer_id': expense.payerId,
  'amount_cents': (expense.amount * 100).round(),
  'currency': expense.currency,
  'category': expense.category.name,
  'description': expense.description,
  'occurred_at': expense.occurredAt.toIso8601String(),
  'split_rule_json': _parseSplitRule(expense.splitRuleJson),
  'created_by': _supabase.currentUserId,
});
```

**验证**:
- Supabase Dashboard 看 `expenses` 表无 `sync_status` 字段值
- 云端不应有 `deleted_at`(本地软删除标记,不该同步)

**风险**:低 — 纯字段删除

---

#### PR-C:数据精度 + 改 amount 撤销(90 分钟) — 修 S-23 / S-27

| ID | 严重度 | 文件 | 行 | 简述 |
|---|---|---|---|---|
| S-23 | 🔴 S | `lib/presentation/screens/expense_detail_screen.dart` | 230-238 | 详情页不限小数位,精度漂移 |
| S-27 | 🔴 S | `lib/data/repositories/expense_repository.dart` | 195-229 | 改 amount 不撤销已结清 transfer |

**S-23 修复**:
```dart
TextField(
  controller: _amountCtrl,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),  // ← 新增
  ],
  ...
)
```

**S-27 修复**:
在 `expense_repository.dart:update()` 入口加校验:
```dart
Future<Expense> update(String id, {double? amount, ...}) async {
  final current = _box.get(id);
  if (current == null) throw StateError('Expense not found');
  
  // 如果 amount 或 currency 改变,检查已结清的 transferRecords
  if (amount != null && amount != current.amount) {
    final affectedRecords = await _findSettledTransfersForExpense(id);
    if (affectedRecords.isNotEmpty) {
      throw ConflictingSettledTransferException(
        '该费用关联 ${affectedRecords.length} 笔已结清转账,'
        '改金额前需先撤销结清记录'
      );
    }
  }
  // ... 继续 update 逻辑
}
```

或者:让 `update()` 自动撤销相关 settled transferRecords(更激进,**不推荐,需用户确认**)。

**验证**:
- 详情页输入 `1.999999` → 被拒
- 制造一个 expense + transferRecord,改 amount → 抛 ConflictingSettledTransferException

**风险**:中 — 改数据模型可能影响 UI

---

#### PR-D:UX 反馈缺失修复(30 分钟) — 修 S-21 / S-22

| ID | 严重度 | 文件 | 行 | 简述 |
|---|---|---|---|---|
| S-21 | 🔴 S | `lib/presentation/screens/expense_create_screen.dart` | 207-226 | `_submitAndContinue` 失败不弹 Snackbar |
| S-22 | 🟡 M(实为 S 级) | `lib/presentation/screens/expense_create_screen.dart` | 180-189 | 数字键盘锁位无反馈 |

**S-21 修复**:
```dart
Future<void> _submitAndContinue() async {
  final ok = await _submit();
  if (!mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存失败,请重试')),
    );
    return;
  }
  // ... 现有成功代码
}
```

**S-22 修复**:
```dart
// 改前:
if (_amountInput.length - dotIdx > 2) return;

// 改后:
if (_amountInput.length - dotIdx > 2) {
  HapticFeedback.lightImpact();  // ← 震动反馈
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('已到 2 位小数'),
      duration: Duration(milliseconds: 500),
    ),
  );
  return;
}
```

**验证**:
- 模拟网络断开 → 失败 → 应看到 Snackbar
- 数字键盘输到 2 位小数后再按 → 震动 + Snackbar

**风险**:低

---

### 第二梯队(本周补,3 个 PR,5-6 小时)

#### PR-E:文档失修全套修复(2 小时) — 修 S-16 / S-17 / S-18 / V2-4 / V2-6 / V2-7 / V2-8

| ID | 严重度 | 文件 | 简述 |
|---|---|---|---|
| S-16 | 🔴 | `项目文件目录结构一览表.md` | 数字全面失修(7-8 后没更新) |
| S-17 | 🔴 | `03-data-model.md` | 跟真实 Supabase schema 不一致 |
| S-18 | 🔴 | `pubspec.yaml` | `app_links: 6.3.1` override 没文档化 |
| V2-4 | 🆕 | `项目文件目录结构一览表.md` | 7-8 后没更新,数字全错 |
| V2-6 | 🆕 | `pubspec.yaml` | app_links override 仍未文档化 |
| V2-7 | 🆕 | `CHANGELOG.md` + `MILESTONE.md` | 与实际 commit 状态可能不对齐 |
| V2-8 | 🆕 | `issue-tracker.md` | 维护滞后,7-12 后 V1.2 没新 ISSUE |

**修复要求**:

1. **重写一览表**(跑 find 实际数字):
```bash
cd "C:/Users/jiaqi/.openclaw/workspace/projects/ai-travel-ledger"
echo "md: $(find . -name "*.md" -not -path "*/.git/*" -not -path "*/05-evaluation/*" -not -path "*/99-archive/*" | wc -l)"
echo "dart: $(find lib -name "*.dart" -not -name "*.g.dart" | wc -l)"
echo "test: $(find test -name "*.dart" | wc -l)"
echo "sql: $(find supabase -name "*.sql" | wc -l)"
```

2. **重写 03-data-model.md**:基于 `supabase/migrations/00001_initial_schema.sql` 重写,加 JSONB 字段说明
3. **tech-stack.md 加 app_links override 说明**:
   ```markdown
   ### Known Workarounds
   
   - `app_links: 6.3.1` dependency override in `pubspec.yaml` 
     - **Reason**: `app_links 6.4.1` 引入的 API breaking changes 与 Flutter 3.x 不兼容
     - **Tracking**: ISSUE-2026-07-09-01
     - **Last verified**: 2026-07-15(可删除当 Flutter 升级到 3.27+ 后)
   ```
4. **校对 CHANGELOG/MILESTONE**:
   - 跑 `git log --oneline 2026-07-12..HEAD` 实际 commits
   - 跑 `find test -name "*.dart" | wc -l` 实际 test 数
   - 校对"83 commits + 250/250"等数字
5. **issue-tracker 增量**:
   - 跑 `git log --oneline 2026-07-12..HEAD`
   - 找 V1.2 step 1/2/3/4 + cloud + milestone 相关 commit
   - 加 ISSUE-031(V1.2 step 1) / ISSUE-032(V1.2 step 2) 等
   - 改"最后同步"时间戳

**风险**:低(纯文档)

---

#### PR-F:`ai_config.dart` 隐私修复(30 分钟) — 修 S-20

| ID | 严重度 | 文件 | 简述 |
|---|---|---|---|
| S-20 | 🔴 | `lib/core/ai_config.dart` | M3 API key 占位 + Qwen3.6 baseUrl 硬编码 |

**修复**:
```dart
// 改前:baseUrl 硬编码 http://192.168.1.60:8033/v1
// 改后:从 AppSettings 读
static String? getLocalQwen36BaseUrl(AppSettings settings) {
  return settings.localQwen36BaseUrl ?? 'http://192.168.1.60:8033/v1';
}
```

需要在 `AppSettings` 加 `localQwen36BaseUrl` 字段,UI 暴露给用户改。

**验证**:换到 .90 段网络,本地 Qwen 仍能连

**风险**:中(改 model 字段会影响所有现有选择)

---

#### PR-G:4 层 `AsyncValue.when` 重构(2 小时) — 修 S-24 / M-1

| ID | 严重度 | 文件 | 简述 |
|---|---|---|---|
| S-24 | 🔴 | `lib/presentation/providers/settlement_provider.dart` 第 65-129 | 4 层 when 嵌套 |
| M-1 | 🟡 | `group_settlement_screen.dart` 第 32-50 | 3 层 when |

**修复要求**:
```dart
// 改前 (settlement_provider.dart:65-129):
final settlementProvider = Provider.autoDispose.family<...>((ref, tripId) {
  final expensesAsync = ref.watch(...);
  final membersAsync = ref.watch(...);
  final groupsAsync = ref.watch(...);
  final recordsAsync = ref.watch(...);
  return expensesAsync.when(
    loading: ...,
    data: (e) => membersAsync.when(
      loading: ...,
      data: (m) => groupsAsync.when(  // ← 4 层
        ...
      ),
    ),
  );
});

// 改后:用 AsyncValue.guard + combine
final settlementProvider = Provider.autoDispose.family<AsyncValue<TripSettlement>, String>((ref, tripId) {
  final expenses = ref.watch(expensesByTripProvider(tripId));
  final members = ref.watch(membersByTripProvider(tripId));
  final groups = ref.watch(groupsByTripProvider(tripId));
  final records = ref.watch(transferRecordsByTripProvider(tripId));
  
  return AsyncValue.guard(() {
    final e = expenses.requireValue;
    final m = members.requireValue;
    final g = groups.requireValue;
    final r = records.requireValue;
    return TripSettlement(...);
  });
});
```

**验证**:
- 任一 loading 立即显示 partial data
- 代码从 4 层缩到 1 层

**风险**:中(UI 重构可能引入新 bug)

---

### 第三梯队(下月,13 个 L + 32 个 M)

| 类别 | 数量 | 主要内容 |
|---|---|---|
| 🟢 L 轻微 | 14 | 代码风格 / 一致性 / 优化点 |
| 🟡 M 中等 | 32 | 见 `01-evaluation-checklist.md` 详情 |
| 🆕 V2-X | 4 | V2-2(cloudVersion 注释)、V2-5(归档详情)、V2-7/V2-8 已并入 PR-E |

**M 类高频问题**:
- M-2 / M-3:`_parseColor` 4 处重复 → 提到 `core/utils/color_utils.dart`
- M-9:改 trip 币种不联动 expense.currency
- M-11:4 处 8 硬编码色 → 自定义拾色器
- M-16:`_fireRemote` 静默吞错 → 加 logger
- M-18:5 个 push 方法不更新 syncStatus
- M-19:supabase_settings 错误信息含 stack trace
- M-21:`pubspec.yaml` 缺 lint 自定义
- M-22:`roadmap.md` Epic 状态失修
- M-23:`roadmap.md` 编号搞反
- M-24:`daily-reports/` vs `meeting-notes/` 职责不清
- M-25:TripRepository.delete 不级联
- M-27:Expense.amount 全链路 double
- M-28:SettlementEngine 累加 double
- M-29:Trip.fromDb 'active' 分支没测试
- M-31:equalAll + equalSelected 实现完全相同
- M-32:Trip.baseCurrency 没 assert 长度
- M-33:5 个 repo create/update 不校验 amount > 0
- M-34:AppSettings.fromJson 强转(已修)

---

## 🔵 战略决策(阻塞其他)

### V1N-2:领先 origin/main commit 何时推?推到哪?

**当前状态**:
- 本地领先 ~10+ commits(v3 报告写完后又加了 2 个)
- GitHub 国内连接超时
- Gitee 单仓可考虑
- 推送前**必须**确认 RLS S-1 已修(已修 ✅)+ 隐私 S-3/S-4 已清(已清 ✅)

**3 个选项**:

**A. 推 Gitee + GitHub(推荐)**
- 注册 Gitee 账号 → 推 Gitee(国内快)
- 配置 GitHub 代理(Clash 端口)→ 推 GitHub
- 流程:dev → PR → main review → 双 remote 同步

**B. 推 Gitee 单仓**
- 简单,只推 Gitee
- 缺点:不能用于开源/招聘

**C. 暂存不推,继续本地开发**
- 零工作量
- 缺点:多人协作不可能,新 PC 必须手动 ZIP

---

## 📁 评估报告位置(OpenClaw 可读)

| 文件 | 路径 |
|---|---|
| v2 评估(已读) | `docs/05-evaluation/01-evaluation-checklist.md` + 02/03/04/05 |
| v3 评估(已读) | `docs/05-evaluation/06-v3-post-fix-report.md` |
| **本报告(v3 执行指南)** | `docs/05-evaluation/07-v3-execution-guide.md`(本文件) |
| 红线规则 | `docs/99-red-lines/RULES.md` |
| 512K 上下文设置 | `docs/99-red-lines/SET-512K-CONTEXT.md` |

---

## 🚦 重要红线(给 OpenClaw)

**只写白名单**:`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\` 下的所有文件

**完全禁止写**:
- `C:\Users\jiaqi\.openclaw\` 顶层任何文件(`openclaw.json`、`gateway.cmd`、`.bak*` 等)
- `C:\Users\jiaqi\.openclaw\agents\` 下任何文件
- `C:\Users\jiaqi\.openclaw\state\` 下任何文件
- `C:\Users\jiaqi\.openclaw\workspace\dev\` 下任何文件(`USER.md`、`MEMORY.md`、`memory/`)
- `C:\Users\jiaqi\.openclaw\workspace-attestations\` 下任何文件
- `C:\Users\jiaqi\.openclaw\logs\` 下任何文件

**任何疑似"全局配置"操作前必须报告路径 + 等用户单项同意**(详 `RULES.md`)

---

## ✅ 完成定义(每个 PR)

每个 PR 必须满足:

- [ ] 代码通过 `flutter analyze`
- [ ] 相关单元测试加 + 通过
- [ ] 至少一次真机/模拟器验证
- [ ] 改了 schema 跑 `supabase db reset`
- [ ] 关联 ISSUE 状态在 `issue-tracker.md` 更新
- [ ] **改 lib/ 必须回写 `项目文件目录结构一览表.md`**(已失修,可借 PR-E 一起重写)
- [ ] 写 commit message 明确标 `[PR-X 修复 S-Y]`
- [ ] push 之前在 PR 描述里写"修了哪几条 + 文件:行 + 验证步骤"

---

## 📊 工作量估算

| 阶段 | 数量 | 工作量 |
|---|---|---|
| 第一梯队(PR-A/B/C/D) | 4 个 PR / 8 个 S | ~4 小时 |
| 第二梯队(PR-E/F/G) | 3 个 PR / 9 个 S+V2 | ~5-6 小时 |
| 第三梯队(下月) | L+M = 46 条 | ~16-20 小时 |
| V1N-2 战略 | 1 个 | 决策 + 0.5-1 小时执行 |
| **总计** | **64 项** | **~25-30 工时** |

---

*归档位置:`C:\Users\jiaqi\.openclaw\workspace\projects\ai-travel-ledger\docs\05-evaluation\07-v3-execution-guide.md`*
*白名单内 ✅*
*v3 评估的 14 个未修 S 已转化为 7 个可执行 PR*