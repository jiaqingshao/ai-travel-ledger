/// 分摊规则引擎（W3 / E-003）
///
/// ## 5 + 1 种分摊方式
///
/// | 类型            | API                                            | 说明                                   |
/// | --------------- | ---------------------------------------------- | -------------------------------------- |
/// | `equalAll`      | `equalAll(total, memberIds)`                   | 总金额 / 人数，尾差补偿给第一个人       |
/// | `equalSelected` | `equalSelected(total, memberIds)`              | 同 equalAll（指定人），保留 API 差异    |
/// | `byRatio`       | `byRatio(total, ratios)`                       | 按比例分，尾差补偿给比例最大者          |
/// | `byShares`      | `byShares(total, shares)`                      | 按份数分，尾差补偿给份数最多者          |
/// | `byMember`      | `byMember(values)`                             | 固定金额（成员→金额），sum 校验        |
/// | 🆕 `byGroup`    | `byGroup(total, groups, members, memberToGroup)`| 按组分摊（组内均摊），W3 核心新功能    |
///
/// ## 设计原则
/// - **纯函数**：相同输入 → 相同输出，无副作用
/// - **尾差调整**：所有分摊（除 `byMember`）保证 sum == total
/// - **边界处理**：空数组 / 单人 / 零金额 不抛异常
/// - **货币精度**：保留 2 位小数（与现有 SettlementEngine 一致）
///
/// ## 关于 `byMember`
/// - 用户手动输入每人金额，**必须 sum == total**，否则抛 `ArgumentError`
/// - 不做尾差调整（用户输入即权威）
library;

import '../../data/models/group.dart';
import '../../data/models/member.dart';

/// 分摊类型枚举（业务语义层）
///
/// 与 `SplitRule.type` 字符串互为映射：
///   - `equal`  → [SplitType.equal]（同时覆盖 equalAll / equalSelected）
///   - `ratio`  → [SplitType.ratio]
///   - `shares` → [SplitType.shares]
///   - `specific`→ [SplitType.specific]
///   - `byGroup`→ [SplitType.byGroup]（W3 新增）
enum SplitType {
  /// 全部成员均摊
  equal,

  /// 指定成员均摊
  equalSelected,

  /// 按比例分摊
  ratio,

  /// 按份数分摊
  shares,

  /// 按固定金额分摊
  specific,

  /// 按组分摊（组内均摊）
  byGroup;

  /// 持久化到 SplitRule.type 的字符串
  String get dbValue {
    switch (this) {
      case SplitType.equal:
      case SplitType.equalSelected:
        return 'equal';
      case SplitType.ratio:
        return 'ratio';
      case SplitType.shares:
        return 'shares';
      case SplitType.specific:
        return 'specific';
      case SplitType.byGroup:
        return 'byGroup';
    }
  }

  /// 从字符串反向解析（容错）
  static SplitType fromDb(String? v) {
    switch (v) {
      case 'equal':
        return SplitType.equal;
      case 'ratio':
        return SplitType.ratio;
      case 'shares':
        return SplitType.shares;
      case 'specific':
        return SplitType.specific;
      case 'byGroup':
        return SplitType.byGroup;
      default:
        return SplitType.equal;
    }
  }
}

/// 按组分摊的"组配置"
///
/// groups 中每项：{ groupId, ratio }（可选 ratio；不传则各组按 1:1 均摊）
class GroupSplitInput {
  const GroupSplitInput({
    required this.groupId,
    this.ratio = 1.0,
  });

  final String groupId;
  final double ratio;
}

/// 单一成员的分摊结果
class SplitResultItem {
  const SplitResultItem({
    required this.memberId,
    required this.amount,
  });

  final String memberId;
  final double amount;

  @override
  String toString() => 'SplitResultItem($memberId: $amount)';

  @override
  bool operator ==(Object other) =>
      other is SplitResultItem &&
      other.memberId == memberId &&
      (other.amount - amount).abs() < 0.005;

  @override
  int get hashCode => Object.hash(memberId, amount);
}

/// 分摊规则引擎
///
/// 所有方法都是**纯函数**（输入相同 → 输出相同）。
class SplitCalculator {
  const SplitCalculator._();

  /// 浮点精度（2 位小数）。
  ///
  /// 用于尾差比较；不要用作业务金额比较（业务用 `(x * 100).round() / 100`）。
  static const double epsilon = 0.005;

  // ========================================================================
  // 1. equalAll - 全部成员均摊
  // ========================================================================

  /// **全部成员均摊**
  ///
  /// - total / count，尾差补偿给**第一个**成员
  /// - 空数组 / total == 0 / count == 1 都不抛异常
  ///
  /// 返回：每人的最终金额（顺序与 [memberIds] 一致，**数量不变**）
  static List<SplitResultItem> equalAll({
    required double total,
    required List<String> memberIds,
  }) =>
      _equalCore(total, memberIds, remainderReceiverIndex: 0);

  // ========================================================================
  // 2. equalSelected - 指定成员均摊（与 equalAll 同算法）
  // ========================================================================

  /// **指定成员均摊**（与 [equalAll] 算法一致）
  ///
  /// 保留两个 API 是为了语义清晰：
  /// - `equalAll`: 全部成员参加（无需选）
  /// - `equalSelected`: 用户手动选了若干成员
  static List<SplitResultItem> equalSelected({
    required double total,
    required List<String> memberIds,
  }) =>
      _equalCore(total, memberIds, remainderReceiverIndex: 0);

  /// 共用的均摊核心实现
  ///
  /// 算法：
  ///   1) perHead = total / n
  ///   2) perHeadRounded = round2(perHead)
  ///   3) sumRounded = perHeadRounded * n
  ///   4) remainder = round2(total - sumRounded)
  ///   5) 把 remainder 加到第 [remainderReceiverIndex] 个人
  ///
  /// 为什么放在"第一个人"：
  ///   - 稳定（顺序一致 → 结果可复现 → 纯函数）
  ///   - 避免 UI 显示"小费"分摊给最后一个人造成困惑
  static List<SplitResultItem> _equalCore(
    double total,
    List<String> memberIds, {
    required int remainderReceiverIndex,
  }) {
    if (memberIds.isEmpty) return const <SplitResultItem>[];

    final n = memberIds.length;
    final perHead = total / n;
    final perHeadRounded = _round2(perHead);
    final sumRounded = perHeadRounded * n;
    // 尾差
    final remainder = _round2(total - sumRounded);

    return List<SplitResultItem>.generate(n, (i) {
      final amount = i == remainderReceiverIndex
          ? _round2(perHeadRounded + remainder)
          : perHeadRounded;
      return SplitResultItem(
        memberId: memberIds[i],
        amount: amount,
      );
    });
  }

  // ========================================================================
  // 3. byRatio - 按比例分摊
  // ========================================================================

  /// **按比例分摊**
  ///
  /// - ratios: { memberId: ratio }（如 {alice: 1, bob: 2} → alice 1/3, bob 2/3）
  /// - 比例和**不必为 1**（会自动归一化）
  /// - 负数 / 0 / 空数组 处理：
  ///   - 空 → 返回空
  ///   - 全 0 → 抛 [ArgumentError]（无法归一化）
  ///   - 总和为 0 → 同上
  ///   - 负数 → 视为 0（防御）
  /// - 尾差补偿给**比例最大**的成员
  ///
  /// 抛出 [ArgumentError] 当 ratios 为空或全为 0
  static List<SplitResultItem> byRatio({
    required double total,
    required Map<String, double> ratios,
  }) {
    if (ratios.isEmpty) return const <SplitResultItem>[];

    // 防御性：负数视为 0
    final sanitized = <String, double>{
      for (final e in ratios.entries) e.key: e.value < 0 ? 0.0 : e.value,
    };
    final sumRatio = sanitized.values.fold<double>(0.0, (a, b) => a + b);
    if (sumRatio <= 0) {
      throw ArgumentError(
        'SplitCalculator.byRatio: ratios 全部为 0 或负数，无法分摊',
      );
    }

    // 找出比例最大的成员（用于尾差补偿）
    String maxMember = sanitized.keys.first;
    double maxRatio = sanitized[maxMember] ?? 0;
    sanitized.forEach((k, v) {
      if (v > maxRatio) {
        maxRatio = v;
        maxMember = k;
      }
    });

    final entries = sanitized.entries.toList();
    final amounts = <String, double>{};
    double allocated = 0;
    for (final e in entries) {
      final raw = total * e.value / sumRatio;
      final rounded = _round2(raw);
      amounts[e.key] = rounded;
      allocated = _round2(allocated + rounded);
    }
    // 尾差补偿
    final remainder = _round2(total - allocated);
    if (remainder.abs() >= epsilon) {
      amounts[maxMember] = _round2((amounts[maxMember] ?? 0) + remainder);
    }

    return [
      for (final id in ratios.keys)
        SplitResultItem(memberId: id, amount: amounts[id] ?? 0),
    ];
  }

  // ========================================================================
  // 4. byShares - 按份数分摊
  // ========================================================================

  /// **按份数分摊**
  ///
  /// - shares: { memberId: shares }（整数或浮点都可；如 {alice: 2, bob: 1}）
  /// - 份数和**不必为整数**（自动归一化）
  /// - 边界：空 → 空；全 0 → 抛 [ArgumentError]
  /// - 尾差补偿给**份数最多**的成员
  ///
  /// 抛出 [ArgumentError] 当 shares 为空或全为 0
  static List<SplitResultItem> byShares({
    required double total,
    required Map<String, double> shares,
  }) {
    if (shares.isEmpty) return const <SplitResultItem>[];

    // 防御性：负数视为 0
    final sanitized = <String, double>{
      for (final e in shares.entries) e.key: e.value < 0 ? 0.0 : e.value,
    };
    final sumShares = sanitized.values.fold<double>(0.0, (a, b) => a + b);
    if (sumShares <= 0) {
      throw ArgumentError(
        'SplitCalculator.byShares: shares 全部为 0 或负数，无法分摊',
      );
    }

    // 找出份数最多的成员（用于尾差补偿）
    String maxMember = sanitized.keys.first;
    double maxShare = sanitized[maxMember] ?? 0;
    sanitized.forEach((k, v) {
      if (v > maxShare) {
        maxShare = v;
        maxMember = k;
      }
    });

    final amounts = <String, double>{};
    double allocated = 0;
    sanitized.forEach((k, v) {
      final raw = total * v / sumShares;
      final rounded = _round2(raw);
      amounts[k] = rounded;
      allocated = _round2(allocated + rounded);
    });
    // 尾差补偿
    final remainder = _round2(total - allocated);
    if (remainder.abs() >= epsilon) {
      amounts[maxMember] = _round2((amounts[maxMember] ?? 0) + remainder);
    }

    return [
      for (final id in shares.keys)
        SplitResultItem(memberId: id, amount: amounts[id] ?? 0),
    ];
  }

  // ========================================================================
  // 5. byMember - 固定金额
  // ========================================================================

  /// **按固定金额分摊**（用户手动指定每人金额）
  ///
  /// - values: { memberId: amount }
  /// - 业务约束：`sum(values) == total`（尾差 < 0.01 视为相等）
  /// - **不做尾差补偿**（用户输入即权威）
  ///
  /// 抛出 [ArgumentError] 当 sum 与 total 偏差 > 0.01
  static List<SplitResultItem> byMember({
    required Map<String, double> values,
    double? total,
  }) {
    if (values.isEmpty) return const <SplitResultItem>[];

    final sum = values.values.fold<double>(0.0, (a, b) => a + b);
    final sumRounded = _round2(sum);

    if (total != null && (sumRounded - total).abs() > 0.01) {
      throw ArgumentError(
        'SplitCalculator.byMember: 每人金额之和 ($sumRounded) 与总额 ($total) 不一致（误差 > 0.01）',
      );
    }

    return [
      for (final e in values.entries)
        SplitResultItem(memberId: e.key, amount: _round2(e.value)),
    ];
  }

  // ========================================================================
  // 6. byGroup - 按组分摊（W3 核心新功能）
  // ========================================================================

  /// **按组分摊**（组内均摊）
  ///
  /// 算法：
  ///   1) 过滤掉**空组**（没成员）和**未选中的组**（成员归属不在 groups 内）
  ///   2) 把 total 按 ratio 拆分到剩下的**非空组**（_splitTotalByWeights）
  ///   3) 每个组内：组金额 / 组人数，**组内均摊**（尾差给组内第一个人）
  ///
  /// - groups: 每组一个 [GroupSplitInput]（groupId + 可选 ratio）
  /// - 默认 ratio = 1.0（每组按 1:1:1... 拆 total）
  /// - **空组会被完全跳过**（其 ratio 也不计入权重分摊），保证 total 不丢
  /// - 跨组：组成员按所在组归属，不会出现在多个组里
  /// - 边界：total=0 → 返回空；groups 空 / 全部空组 → 返回空；members 空 → 返回空
  ///
  /// 不抛异常（但建议在 UI 层校验 group 至少选 1 个 + 至少 1 个非空组）
  static List<SplitResultItem> byGroup({
    required double total,
    required List<GroupSplitInput> groups,
    required List<Member> members,
  }) {
    if (groups.isEmpty || members.isEmpty || total == 0) {
      return const <SplitResultItem>[];
    }

    // 1) 索引：groupId → 该组成员（只算"选中且有成员"的组）
    final byGroupId = <String, List<Member>>{};
    for (final m in members) {
      final gid = m.groupId;
      if (gid == null) continue;
      if (!groups.any((g) => g.groupId == gid)) continue; // 成员归属不在选中组里
      byGroupId.putIfAbsent(gid, () => []).add(m);
    }

    // 2) 只对"非空组"拆分 total（避免空组把 total 吃掉）
    final nonEmptyGroups = groups
        .where((g) => (byGroupId[g.groupId]?.isNotEmpty ?? false))
        .toList();
    if (nonEmptyGroups.isEmpty) return const <SplitResultItem>[];

    final groupAmounts = _splitTotalByWeights(
      total: total,
      weights: {
        for (final g in nonEmptyGroups) g.groupId: g.ratio,
      },
    );

    // 3) 每个组内均摊
    final results = <SplitResultItem>[];
    for (final g in nonEmptyGroups) {
      final groupTotal = groupAmounts[g.groupId] ?? 0;
      final groupMembers = byGroupId[g.groupId] ?? const <Member>[];
      // 组内均摊，尾差给组内第一个人
      final inner = _equalCore(
        groupTotal,
        groupMembers.map((m) => m.id).toList(),
        remainderReceiverIndex: 0,
      );
      results.addAll(inner);
    }
    return results;
  }

  /// 按 weights 拆 total（与 [byRatio] 类似，但目标是组）
  ///
  /// - weights 为空 / 全 0 → 返回空
  /// - 尾差补偿给 weight 最大者
  static Map<String, double> _splitTotalByWeights({
    required double total,
    required Map<String, double> weights,
  }) {
    if (weights.isEmpty) return const <String, double>{};

    final sanitized = <String, double>{
      for (final e in weights.entries) e.key: e.value < 0 ? 0.0 : e.value,
    };
    final sumW = sanitized.values.fold<double>(0.0, (a, b) => a + b);
    if (sumW <= 0) return const <String, double>{};

    String maxId = sanitized.keys.first;
    double maxW = sanitized[maxId] ?? 0;
    sanitized.forEach((k, v) {
      if (v > maxW) {
        maxW = v;
        maxId = k;
      }
    });

    final result = <String, double>{};
    double allocated = 0;
    sanitized.forEach((k, w) {
      final raw = total * w / sumW;
      final rounded = _round2(raw);
      result[k] = rounded;
      allocated = _round2(allocated + rounded);
    });
    final remainder = _round2(total - allocated);
    if (remainder.abs() >= epsilon) {
      result[maxId] = _round2((result[maxId] ?? 0) + remainder);
    }
    return result;
  }

  // ========================================================================
  // 7. 总和校验
  // ========================================================================

  /// 校验一组分摊结果的金额之和是否等于 [total]（用于 UI 反馈 / 测试）
  ///
  /// 返回 `(actualSum, diff)`：`diff = actualSum - total`，epsilon 视为相等
  static ({double actualSum, double diff}) validateSum({
    required double total,
    required List<SplitResultItem> items,
  }) {
    final sum = items.fold<double>(0.0, (a, b) => a + b.amount);
    final sumRounded = _round2(sum);
    final totalRounded = _round2(total);
    return (
      actualSum: sumRounded,
      diff: _round2(sumRounded - totalRounded),
    );
  }

  // ========================================================================
  // 8. 通用入口（按 SplitType 分发）
  // ========================================================================

  /// **统一入口**：根据 [SplitType] + 参数分发
  ///
  /// 用于 UI 层"一键调用"（不用 if/else 分支）
  ///
  /// - [byRatio] 需要 [ratios]
  /// - [byShares] 需要 [shares]
  /// - [specific] 需要 [specificValues]
  /// - [byGroup] 需要 [groups] 和 [members]
  /// - 其它不需要额外参数
  ///
  /// 抛出 [ArgumentError] 当参数缺失
  static List<SplitResultItem> compute({
    required SplitType type,
    required double total,
    required List<String> memberIds,
    Map<String, double>? ratios,
    Map<String, double>? shares,
    Map<String, double>? specificValues,
    List<GroupSplitInput>? groups,
    List<Member>? members,
  }) {
    switch (type) {
      case SplitType.equal:
      case SplitType.equalSelected:
        return _equalCore(total, memberIds, remainderReceiverIndex: 0);
      case SplitType.ratio:
        if (ratios == null) {
          throw ArgumentError('compute(ratio): ratios 必填');
        }
        return byRatio(total: total, ratios: ratios);
      case SplitType.shares:
        if (shares == null) {
          throw ArgumentError('compute(shares): shares 必填');
        }
        return byShares(total: total, shares: shares);
      case SplitType.specific:
        if (specificValues == null) {
          throw ArgumentError('compute(specific): specificValues 必填');
        }
        return byMember(values: specificValues, total: total);
      case SplitType.byGroup:
        if (groups == null || members == null) {
          throw ArgumentError('compute(byGroup): groups 和 members 必填');
        }
        return byGroup(total: total, groups: groups, members: members);
    }
  }

  // ========================================================================
  // 9. 工具方法
  // ========================================================================

  /// 金额保留 2 位小数（half-to-even / 四舍五入，Dart 默认 banker's rounding）
  ///
  /// 注意：Dart `double.round()` 是 banker's rounding（半数到偶数），
  /// 我们用 `(x * 100).round() / 100` 保持一致。
  static double _round2(double v) => (v * 100).round() / 100;

  /// 将一组 [SplitResultItem] 转为 `{memberId: amount}` Map（便于前端展示）
  static Map<String, double> toMap(List<SplitResultItem> items) {
    return {for (final item in items) item.memberId: item.amount};
  }

  /// 把一组 [TripGroup] 转成默认的 [GroupSplitInput] 列表（ratio=1）
  ///
  /// 便利工厂：UI 初次进入按组页时直接用
  static List<GroupSplitInput> groupsFromList(
    List<TripGroup> groups, {
    Map<String, double>? ratioOverrides,
  }) {
    return [
      for (final g in groups)
        GroupSplitInput(
          groupId: g.id,
          ratio: ratioOverrides?[g.id] ?? 1.0,
        ),
    ];
  }
}
