# AI 旅行账本 — 详细 FSD（PM 细化版）

**版本**: v0.4（基于 PRD v0.3 + 新增语音/重复/统计）
**日期**: 2026-06-28
**作者**: PM（主 Agent）
**状态**: 草稿

> 🆕 **v0.4 变更**：基于 2026-06-28 市场调研，新增 3 个章节：
> - §8 语音记账 (E-008)
> - §9 重复费用 (E-009)
> - §10 旅程统计 (E-010)

---

## 1. 旅程管理（E-001）

### 1.1 数据模型

```dart
// lib/data/models/trip.dart
class Trip {
  String id;              // UUID
  String name;            // 50 字内
  DateTime startDate;
  DateTime? endDate;
  String? destination;    // 100 字
  String baseCurrency;    // CNY 默认
  TripStatus status;      // preparing/ongoing/ended
  String createdBy;       // user_id
  DateTime createdAt;

  // 运行时计算（不入库）
  double get totalExpense => ...;
  int get memberCount => ...;
}

enum TripStatus { preparing, ongoing, ended }
```

### 1.2 完整 AC（验收标准）

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-1 | 可创建旅程（名称 1-50 字、起止日期、目的地可选）| `TripCreateScreen` | P0 |
| AC-2 | 可添加/删除/修改成员（昵称 1-20 字，不需注册）| `MemberManageScreen` | P0 |
| AC-3 | 邀请链接生成（30 天有效，二维码 + URL）| `InviteScreen` + `QRGenerator` | P0 |
| AC-4 | 旅程首页显示基本信息 + 实时总花费 | `TripDetailScreen` | P0 |
| AC-5 | 旅程状态流转：preparing → ongoing → ended | 状态机在 `TripProvider` | P0 |
| AC-6 | 创建/删除/重命名组（家庭/部门/团队/其他）| `GroupManageScreen` | P0 |
| AC-7 | 一个成员最多属于一个组 | `Member.groupId` 唯一约束 | P0 |
| AC-8 | 组变更不影响历史账目（split_groups JSON 快照）| `Expense.splitGroups` | P0 |

### 1.3 业务流程

```
创建旅程流程：
[点击 FAB+] → [TripCreateScreen] → 输入名称+日期 → 
   → 跳转 [MemberManageScreen] → 添加 3-15 成员 →
   → 跳转 [TripDetailScreen] (status=preparing)

邀请流程：
[TripDetailScreen] → 点击[邀请] → [InviteScreen] →
   生成链接: https://app/trip/join?token=xxx (30 天) →
   显示二维码 + 复制按钮 →
   对方扫码 → 跳转 [JoinTripScreen] → 输入昵称 → 加入

状态流转：
preparing (默认) → 手动点击"开始旅程" → ongoing
ongoing → 手动点击"结束旅程" → ended (只读)
```

---

## 2. 快速记账（E-002）— 详细 AC

### 2.1 数据模型

```dart
class Expense {
  String id;
  String tripId;
  String payerId;           // member_id
  double amount;             // > 0
  String currency;
  ExpenseCategory category;
  String? description;       // 200 字
  DateTime occurredAt;
  DateTime createdAt;
  SplitRule splitRule;       // JSON
  List<String> attachments;  // URL 列表，最多 3
  SyncStatus syncStatus;     // synced/pending/failed
  ApprovalStatus approvalStatus; // confirmed/unconfirmed（重复检测）
}

enum ExpenseCategory {
  food, lodging, transport, fuel, toll, parking,
  ticket, shopping, entertainment, other
}

class SplitRule {
  SplitType type;                    // equalAll/equalSelected/byGroup/byMember
  List<String> participantIds;       // 参与分摊的成员
  Map<String, double> values;        // 比例/份数/固定金额
  List<SplitGroupSnapshot> splitGroups;  // 🆕 组快照
}

class SplitGroupSnapshot {
  String groupId;
  String groupName;
  List<String> memberIds;
}

enum ApprovalStatus { confirmed, unconfirmed }
```

### 2.2 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-9 | 3 步完成记账（付款人→类别→金额）| `ExpenseCreateScreen` | P0 |
| AC-10 | 默认上次付款人、默认均摊所有人 | `ExpenseProvider` | P0 |
| AC-11 | 10 个费用类别（含图标+颜色）| `ExpenseCategory` enum + UI | P0 |
| AC-12 | 4 种分摊类型（默认均摊所有人）| `SplitCalculator` | P0 |
| AC-13 | 附件：最多 3 张，自动压缩 JPEG 1920px/80%/<200KB | `ImageCompressor` | P0 |
| AC-14 | 重复检测：同一天+同金额+同分类+同支付人 | `DuplicateDetector` | P0 |
| AC-15 | 重复账目标记"未采纳"+手动确认/删除 | `ExpenseApprovalService` | P0 |
| AC-16 | 列表按时间倒序，支持按类别筛选 | `ExpenseListScreen` | P0 |
| AC-17 | 24 小时内的账目可编辑（防作弊）| `ExpensePolicy` | P0 |

### 2.3 重复检测算法

```dart
class DuplicateDetector {
  /// 检测当前账目是否为重复
  /// 返回 true 如果检测到重复
  static bool isDuplicate(Expense newExpense, List<Expense> existing) {
    return existing.any((e) =>
      e.payerId == newExpense.payerId &&
      e.amount == newExpense.amount &&
      e.category == newExpense.category &&
      _isSameDay(e.occurredAt, newExpense.occurredAt)
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
```

---

## 3. 基础分摊（E-003）— 详细 AC

### 3.1 分摊算法（核心）

```dart
class SplitCalculator {
  /// 均摊所有人
  static Map<String, double> equalAll(
    double totalAmount,
    List<String> memberIds,
  ) {
    final perHead = totalAmount / memberIds.length;
    final result = {for (var id in memberIds) id: perHead};
    _adjustRounding(result, totalAmount);
    return result;
  }

  /// 均摊指定人
  static Map<String, double> equalSelected(
    double totalAmount,
    List<String> memberIds,
  ) {
    return equalAll(totalAmount, memberIds);
  }

  /// 按组（组内均摊）
  static Map<String, double> byGroup(
    double totalAmount,
    List<SplitGroupSnapshot> groups,
  ) {
    final memberCount = groups.fold<int>(
      0, (sum, g) => sum + g.memberIds.length
    );
    if (memberCount == 0) return {};
    final perHead = totalAmount / memberCount;
    final result = <String, double>{};
    for (final g in groups) {
      for (final m in g.memberIds) {
        result[m] = perHead;
      }
    }
    _adjustRounding(result, totalAmount);
    return result;
  }

  /// 按人指定（每人一笔）
  static Map<String, double> byMember(
    double totalAmount,
    Map<String, double> values,
  ) {
    final sum = values.values.fold<double>(0, (a, b) => a + b);
    assert((sum - totalAmount).abs() < 0.01);
    return Map.of(values);
  }

  /// 尾差调整（给第一个成员补偿）
  static void _adjustRounding(
    Map<String, double> result,
    double targetTotal,
  ) {
    final currentTotal = result.values.fold<double>(0, (a, b) => a + b);
    final diff = (targetTotal - currentTotal).abs();
    if (diff > 0 && diff < 0.01 && result.isNotEmpty) {
      final firstKey = result.keys.first;
      result[firstKey] = (result[firstKey]! + (targetTotal - currentTotal))
          .toDouble();
    }
  }
}
```

### 3.2 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-18 | 4 种分摊类型 UI（均摊/比例/份数/固定）| `SplitTypeSelector` | P0 |
| AC-19 | 比例分摊：自动归一化（总比例=100%）| `SplitCalculator.normalizeRatio` | P0 |
| AC-20 | 份数分摊：默认 1 份，可调 | `SplitCalculator.byShares` | P0 |
| AC-21 | 固定金额：sum 校验，不符报错 | `SplitCalculator.byMember` | P0 |
| AC-22 | 按组分摊：组内均摊，可手动调整 | `SplitCalculator.byGroup` | P0 |
| AC-23 | 分摊快照：组变更不影响历史账目 | `SplitGroupSnapshot` | P0 |
| AC-24 | 显示每个成员应分摊金额（实时预览）| `SplitPreview` | P0 |

---

## 4. 结算引擎（E-004）— 详细 AC

### 4.1 核心算法（贪心）

```dart
class SettlementEngine {
  /// 计算每人净收支 = 支付总额 - 应分摊总额
  static Map<String, double> calculateNetBalances(
    List<Member> members,
    List<Expense> expenses,
    Map<String, Map<String, double>> splits,  // expense_id -> {member_id: amount}
  ) {
    final balances = <String, double>{
      for (final m in members) m.id: 0.0
    };

    for (final expense in expenses) {
      if (expense.approvalStatus != ApprovalStatus.confirmed) continue;

      // 支付人 +amount
      balances[expense.payerId] = (balances[expense.payerId] ?? 0) + expense.amount;

      // 所有人按分摊 -amount
      final split = splits[expense.id] ?? {};
      split.forEach((memberId, amount) {
        balances[memberId] = (balances[memberId] ?? 0) - amount;
      });
    }

    return balances;
  }

  /// 最优转账路径（贪心：最大债权 + 最大债务）
  static List<Transfer> minimizeTransfers(Map<String, double> balances) {
    // 分离债权/债务
    final debtors = <MapEntry<String, double>>[];     // 余额 < 0
    final creditors = <MapEntry<String, double>>[];    // 余额 > 0

    balances.forEach((id, balance) {
      if (balance < -0.01) debtors.add(MapEntry(id, -balance));
      if (balance > 0.01) creditors.add(MapEntry(id, balance));
    });

    // 按金额降序排序
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    final transfers = <Transfer>[];
    var i = 0;
    var j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      final amount = [debtor.value, creditor.value].reduce(
        (a, b) => a < b ? a : b
      );

      transfers.add(Transfer(
        from: debtor.key,
        to: creditor.key,
        amount: amount,
      ));

      // 更新剩余
      final newDebtor = debtor.value - amount;
      final newCreditor = creditor.value - amount;

      debtors[i] = MapEntry(debtor.key, newDebtor);
      creditors[j] = MapEntry(creditor.key, newCreditor);

      if (newDebtor < 0.01) i++;
      if (newCreditor < 0.01) j++;
    }

    return transfers;
  }

  /// 按组聚合结算
  static List<GroupSettlement> byGroup(
    List<Member> members,
    List<Group> groups,
    Map<String, double> balances,
  ) {
    // 按 group_id 聚合
    final groupBalances = <String, double>{};
    for (final m in members) {
      final groupId = m.groupId ?? '__no_group__';
      groupBalances[groupId] = (groupBalances[groupId] ?? 0) +
          (balances[m.id] ?? 0);
    }

    // 转账路径在组维度上重跑贪心
    final transfers = minimizeTransfers(groupBalances);

    // 展开为 Settlement 对象
    return transfers.map((t) {
      final fromGroup = groups.firstWhere(
        (g) => g.id == t.from,
        orElse: () => Group(id: t.from, name: '未分组'),
      );
      final toGroup = groups.firstWhere(
        (g) => g.id == t.to,
        orElse: () => Group(id: t.to, name: '未分组'),
      );
      return GroupSettlement(
        fromGroupId: t.from,
        fromGroupName: fromGroup.name,
        toGroupId: t.to,
        toGroupName: toGroup.name,
        amount: t.amount,
      );
    }).toList();
  }
}

class Transfer {
  final String from;
  final String to;
  final double amount;
  Transfer({required this.from, required this.to, required this.amount});
}

class GroupSettlement {
  final String fromGroupId;
  final String fromGroupName;
  final String toGroupId;
  final String toGroupName;
  final double amount;
  GroupSettlement({
    required this.fromGroupId,
    required this.fromGroupName,
    required this.toGroupId,
    required this.toGroupName,
    required this.amount,
  });
}
```

### 4.2 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-25 | 计算每人净收支（paid - shouldPay）| `SettlementEngine.calculateNetBalances` | P0 |
| AC-26 | 输出最优转账路径（最少笔数）| `SettlementEngine.minimizeTransfers` | P0 |
| AC-27 | 生成结算单（总金额、人均、最高/最低）| `SettlementService` | P0 |
| AC-28 | 按组聚合结算（张家 +800，李家 -500）| `SettlementEngine.byGroup` | P0 |
| AC-29 | 组内展开可见个人明细 | `GroupSettlementDetail` UI | P0 |
| AC-30 | 标记已结算（点击"已转账"）| `Transfer.acknowledged` | P0 |
| AC-31 | 100 笔账目结算 < 1 秒 | 算法 O(n log n) | 性能 |

### 4.3 复杂度

- 时间：O(n log n) 排序 + O(n) 匹配，n=15 时 < 10ms
- 空间：O(n) 临时数组

---

## 5. 图片压缩（E-005）— 详细 AC

### 5.1 实现

```dart
class ImageCompressor {
  static const int MAX_WIDTH = 1920;
  static const int MAX_HEIGHT = 1920;
  static const int QUALITY = 80;
  static const int TARGET_SIZE_KB = 200;

  /// 压缩图片到目标大小
  static Future<File> compress(File original) async {
    // 1. 读取
    final bytes = await original.readAsBytes();
    var image = img.decodeImage(bytes);

    // 2. 缩放
    if (image!.width > MAX_WIDTH || image.height > MAX_HEIGHT) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? MAX_WIDTH : null,
        height: image.height > image.width ? MAX_HEIGHT : null,
      );
    }

    // 3. 质量压缩（迭代到 < 200KB）
    var quality = QUALITY;
    Uint8List result = img.encodeJpg(image, quality: quality);

    while (result.length / 1024 > TARGET_SIZE_KB && quality > 30) {
      quality -= 10;
      result = img.encodeJpg(image, quality: quality);
    }

    // 4. 保存
    final compressed = File(original.path.replaceAll('.', '_compressed.'));
    await compressed.writeAsBytes(result);
    return compressed;
  }
}
```

### 5.2 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-32 | 拍照/相册选图，最多 3 张 | `ImagePicker` + `AttachmentGrid` | P0 |
| AC-33 | 自动压缩（JPEG 1920px/80%/<200KB）| `ImageCompressor` | P0 |
| AC-34 | 上传时显示"压缩中..."进度 | `CompressIndicator` | P0 |
| AC-35 | 原图不保存，仅存压缩版 | `_compressed.jpg` 命名 | P0 |
| AC-36 | 命名规则：{trip_id}/{expense_id}_{index}.jpg | `StorageService.upload` | P0 |

---

## 6. 非功能性需求

| 维度 | 指标 | 验证方法 |
|---|---|---|
| 启动时间 | < 2 秒 | `flutter run` + 计时 |
| 记账响应 | < 500ms | 计时器埋点 |
| 100 笔账结算 | < 1 秒 | `Stopwatch` 包裹 |
| APK 体积 | < 30MB | `flutter build apk --release` |
| 离线可用 | 是 | 飞行模式测试 |
| 暗色模式 | 100% 适配 | MaterialApp darkTheme |
| Android 版本 | API 26+ | minSdkVersion 26 |

---

## 7. 测试用例清单（QA 验收）

### 单元测试

| 模块 | 用例数 | 覆盖率目标 |
|---|---|---|
| SettlementEngine | 15 个 | ≥90% |
| SplitCalculator | 12 个 | ≥90% |
| DuplicateDetector | 6 个 | ≥85% |
| ImageCompressor | 4 个 | ≥70% |
| ExpenseModel | 8 个 | ≥80% |

### 集成测试

| 场景 | 描述 |
|---|---|
| 创建旅程 → 添加 5 成员 → 记 10 笔账 → 结算 | 完整流程 |
| 组变更 → 历史账目仍正确 | 数据一致性 |
| 离线 → 联网 → 自动同步 | 网络切换 |

### E2E 测试

| 场景 | 验收 |
|---|---|
| 新用户首次使用 | 3 分钟内完成首次记账 |
| 多设备同步 | 30 秒内看到对方更新 |
| 异常恢复 | 网络中断不丢数据 |

---

## 8. ⏸️ 语音记账（E-008）— v0.3 制定，v0.3.1 暂缓至 V1.1

> **状态**: ⏸️ 暂缓，详见 [ADR-004](../../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md)
>
> **保留价值**: 国内差异化卖点（百事 AA / 来福记账 / 叨叨记账 已做）
> **依赖缺口**: `speech_to_text` 包未加；麦克风权限 UX 待设计
> **决策日期**: 2026-07-15

### 8.1 数据模型

```dart
class VoiceRecording {
  String id;
  String tripId;
  String rawText;          // 原始识别文本
  ParsedExpense? parsed;   // 解析结果
  String? audioFilePath;   // 临时音频（识别后删除）
  DateTime createdAt;
  VoiceRecognitionStatus status;  // pending/parsed/confirmed/failed
}

class ParsedExpense {
  String? payerNickname;   // "我" / "张三"
  double? amount;          // 200.0
  ExpenseCategory? category;  // fuel
  String? description;     // "在山西加油"
  double confidence;       // 0-1
}

enum VoiceRecognitionStatus { pending, parsed, confirmed, failed }
```

`Expense` 表扩展字段：
```dart
String? source;          // "manual" | "voice" | "recurring" | "import"
String? voiceRecordingId; // 反查录音记录
String? recurringRuleId;  // 反查重复费用规则
```

### 8.2 NLU 解析流程

```
录音 → Android 系统 STT → 原始文本 →
  ↓
[关键词快速匹配] → 高置信度直接生成账目
  ↓ (置信度 < 0.8)
[本地 LLM Qwen3.6 35B] → 结构化 JSON
  ↓
[解析结果预览页] → 用户确认 → 入库
```

### 8.3 关键词规则表

| 关键词 | 类别 | 示例 |
|--------|------|------|
| 加油、油费、gas、fuel | fuel | "刚才加油 200" |
| 吃饭、午餐、晚餐、早餐、餐饮 | food | "中午吃饭 80" |
| 酒店、民宿、住、住宿 | lodging | "今晚民宿 300" |
| 高速、过路费、etc | toll | "刚过路费 50" |
| 停车 | parking | "停车 20" |
| 门票、景区、票 | ticket | "门票 80" |
| 购物、买、东西 | shopping | "买水 10 块" |

### 8.4 LLM Prompt 模板

```
你是一个旅行账目解析助手。从用户的中文口语中提取：
- 付款人（"我"=默认当前用户，其他=查成员列表）
- 金额（数字+单位，"块/元/毛"=元，"k/千"=×1000）
- 类别（10 选 1：food/lodging/transport/fuel/toll/parking/ticket/shopping/entertainment/other）
- 备注（地点/对象等）

输出 JSON：{"payer":..., "amount":..., "category":..., "description":..., "confidence":0-1}

输入："刚才在山西加油 200 块"
输出：{"payer":"我", "amount":200, "category":"fuel", "description":"山西加油", "confidence":0.95}
```

### 8.5 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-37 | 麦克风权限友好申请 | `VoicePermissionService` | P0 |
| AC-38 | 按住录音 / 自动结束（停顿 1.5s）| `VoiceRecordButton` | P0 |
| AC-39 | Android 系统 STT 识别（中文）| `speech_to_text` 包 | P0 |
| AC-40 | 关键词快速匹配（< 50ms）| `KeywordMatcher` | P0 |
| AC-41 | 本地 LLM 解析（< 2s）| `QwenNLUService` | P0 |
| AC-42 | 识别结果预览页（可手动修正）| `VoiceResultScreen` | P0 |
| AC-43 | 离线降级（无网络 → 仅关键词匹配）| `OfflineFallback` | P0 |
| AC-44 | 置信度 < 0.7 → 强制手动选择 | `ConfidenceGate` | P0 |
| AC-45 | 历史识别记录（最近 30 天）| `VoiceHistoryScreen` | P1 |
| AC-46 | 方言识别（粤语/四川话）| `speech_to_text` locale | V1.1 |

### 8.6 隐私保证

- 音频不上传服务器，识别后立即删除本地临时文件
- LLM 调用走本地 API（192.168.1.60:8033）
- 用户可在设置里关闭语音记账

---

## 9. ⏸️ 重复费用（E-009）— v0.3 制定，v0.3.1 暂缓至 V1.1

> **状态**: ⏸️ 暂缓，详见 [ADR-004](../../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md)
>
> **保留价值**: 长期旅程（民宿/包车）的真实需求
> **依赖缺口**: `workmanager` 包未加；**国产手机后台调度已知不稳定**（risk-register 历史）
> **决策日期**: 2026-07-15

### 9.1 数据模型

新增表 `recurring_expenses`，详见 `docs/02-architecture/03-data-model.md` §2.8。

```dart
class RecurringExpense {
  String id;
  String tripId;
  ExpenseTemplate template;     // 账目模板
  RecurringFrequency frequency; // daily/weekly/monthly/yearly
  int interval;                 // 每 N 个周期（默认 1）
  int? dayOfWeek;               // 0-6（仅 weekly）
  int? dayOfMonth;              // 1-31（仅 monthly）
  DateTime startDate;
  DateTime? endDate;
  DateTime? lastGenerated;
  DateTime nextDue;
  bool enabled;
  DateTime createdAt;
}

enum RecurringFrequency { daily, weekly, monthly, yearly }

class ExpenseTemplate {
  String payerId;
  ExpenseCategory category;
  double amount;
  String currency;
  SplitRule splitRule;
  String? description;
}
```

### 9.2 周期计算算法

```dart
class RecurringCalculator {
  static DateTime? calculateNextDue({
    required DateTime fromDate,
    required RecurringFrequency frequency,
    int interval = 1,
    int? dayOfWeek,
    int? dayOfMonth,
  }) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return fromDate.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        if (dayOfWeek == null) return null;
        var next = fromDate.add(Duration(days: 7 * interval));
        while (next.weekday != dayOfWeek) {
          next = next.add(Duration(days: 1));
        }
        return next;
      case RecurringFrequency.monthly:
        if (dayOfMonth == null) return null;
        var next = DateTime(
          fromDate.year,
          fromDate.month + interval,
          dayOfMonth,
        );
        return next;
      case RecurringFrequency.yearly:
        return DateTime(
          fromDate.year + interval,
          fromDate.month,
          fromDate.day,
        );
    }
  }
}
```

### 9.3 自动生成流程

```
[本地 workmanager 定时任务，每天 00:05 触发] →
  ↓
[扫描所有 enabled 的 recurring_expenses] →
  ↓
[next_due ≤ 今天] →
  ↓
[用 template 生成 Expense 实体] →
  ↓
[写入 Hive（pending 状态）] →
  ↓
[更新 next_due 为下次日期] →
  ↓
[推送通知："已自动记账：¥XXX 民宿"]
```

### 9.4 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-47 | 创建重复费用规则（向导 UI）| `RecurringCreateScreen` | P0 |
| AC-48 | 4 种周期 + 自定义日期 | `RecurringFrequencySelector` | P0 |
| AC-49 | 自动生成账目（workmanager）| `RecurringGenerator` | P0 |
| AC-50 | 历史生成记录 | `RecurringHistoryScreen` | P0 |
| AC-51 | 暂停/恢复/编辑/删除 | `RecurringActions` | P0 |
| AC-52 | 提前 1 天通知 | `flutter_local_notifications` | P0 |
| AC-53 | 立即生成一笔（手动触发）| `RecurringGenerateNow` | P1 |
| AC-54 | 跨设备同步 | `RecurringSyncService` | V1.1 |
| AC-55 | 节假日跳过 | `ChineseHolidayCalendar` | V1.1 |

---

## 10. ⏸️ 旅程统计图表（E-010）— v0.3 制定，v0.3.1 暂缓至 V1.1

> **状态**: ⏸️ 暂缓，详见 [ADR-004](../../02-architecture/04-adr/ADR-004-prd-v0.3-p0-defer.md)
>
> **保留价值**: 旅程结束"消费回顾 + 自动出报告"
> **依赖现状**: `fl_chart 0.66.2` 已加 pubspec 但**无人 import**（V1.1 启用时无需重装）
> **决策日期**: 2026-07-15

### 10.1 数据流

```
[StatisticsService] 
  input: tripId
  process:
    1. 拉取该旅程所有 Expense
    2. 计算 KPI（总金额、人均、最高最低）
    3. 按类别聚合（饼图数据）
    4. 按成员聚合（柱状图数据）
    5. 按日期聚合（折线图数据）
  output: TripStatistics
```

### 10.2 数据模型

```dart
class TripStatistics {
  String tripId;
  
  // KPI
  double totalExpense;
  double perCapita;        // 总金额 / 成员数
  double maxSingleExpense;
  String maxPayerNickname;
  int expenseCount;
  
  // 图表数据
  List<CategoryStat> categoryBreakdown;  // 饼图
  List<MemberStat> memberBreakdown;      // 柱状图
  List<DailyStat> dailyTrend;            // 折线图
}

class CategoryStat {
  ExpenseCategory category;
  double amount;
  double percentage;  // 占比 %
}

class MemberStat {
  String memberId;
  String nickname;
  double totalPaid;
  double netBalance;  // 正数=应收，负数=应付
}

class DailyStat {
  DateTime date;
  double amount;
  int count;
}
```

### 10.3 UI 设计

```
┌────────────────────────────────────┐
│  📊 旅程统计          [分享] [设置]│
├────────────────────────────────────┤
│  总金额 ¥8,520  人均 ¥1,704       │
│  账目数 38  笔  最高 ¥1,200       │
├────────────────────────────────────┤
│  分类占比（饼图）                   │
│      🍽️ 28% 🏨 22% ⛽ 18%        │
│      🛣️ 12% 🎫 10% 🛍️ 10%       │
├────────────────────────────────────┤
│  人均支出（柱状图）                 │
│   张三 ████████████ ¥2,100         │
│   李四 ████████     ¥1,500         │
│   ...                              │
├────────────────────────────────────┤
│  每日趋势（折线图）                 │
│      /╲    /╲                      │
│  ___/  ╲__/  ╲___                  │
│  6/24 6/25 6/26 6/27               │
└────────────────────────────────────┘
```

### 10.4 完整 AC

| # | AC | 实现位置 | 优先级 |
|---|---|---|---|
| AC-56 | KPI 卡片（总金额/人均/最高最低/账目数）| `StatisticsKpiCards` | P0 |
| AC-57 | 分类饼图（10 类 + 颜色）| `CategoryPieChart` | P0 |
| AC-58 | 人均柱状图（按净支出排序）| `MemberBarChart` | P0 |
| AC-59 | 每日趋势折线图 | `DailyTrendChart` | P0 |
| AC-60 | 一屏可看（不滚动核心信息）| `StatisticsScreen` | P0 |
| AC-61 | 暗色模式适配 | fl_chart theme | P0 |
| AC-62 | 分享为图片 | screenshot + share_plus | P0 |
| AC-63 | 旅程结束自动生成报告 | Trip status → ended trigger | P0 |
| AC-64 | 空数据引导（没账时引导记账）| `EmptyState` | P0 |
| AC-65 | 多旅程对比 | `MultiTripComparison` | V1.1 |

---

*本文档为 PM 细化版，所有 AC 需用户确认*
