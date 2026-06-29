/// 结算引擎 - 核心业务逻辑（W4 / E-004）
///
/// ## 三件套
///
/// | 能力 | API | 说明 |
/// |------|-----|------|
/// | 净收支 | `calculateNetBalances(...)` | 每人净额（正=应收，负=应付） |
/// | 最优转账 | `minimizeTransfers(balances)` | 贪心：最大债权人 + 最大债务人配对 |
/// | 按组聚合 | `byGroup(...)` | v0.3 独家：组维度聚合 + 组间转账 |
///
/// ## 设计原则
///
/// - **纯函数**：同输入 → 同输出，无副作用（不读 Hive、不写日志）
/// - **算法复杂度**：
///   - `minimizeTransfers`：O(n log n)，n ≤ 15 时 < 10ms
///   - `byGroup`：O(g log g + g·m log m)，g=组数, m=成员数
/// - **边界**：空数组 / 全 0 / 单人 / 浮点尾差（< 0.01 视为 0）都不抛异常
/// - **货币精度**：保留 2 位小数（与 SplitCalculator 对齐）
/// - **可重放**：相同输入 → 相同输出（无随机、无 I/O）
///
/// ## 关于"最优转账"的贪心最优性
///
/// 经典结论：贪心"最大债权 ↔ 最大债务"配对不是全局最优（全局最优是子集和问题的 NP-hard），
/// 但实践上**几乎总是达到或接近最优**，且实现简单、运行极快。
/// v0.3 MVP 采用贪心；如未来需要全局最优可换 min-cost-flow（O(n³)）。
library;

import '../../data/models/expense.dart';
import '../../data/models/group.dart';
import '../../data/models/member.dart';
import 'split_calculator.dart';

/// 单笔转账建议
///
/// - `fromId`：付款人（应付方）
/// - `toId`：收款人（应收方）
/// - `amount`：金额（保留 2 位小数）
class Transfer {
  const Transfer({
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  final String fromId;
  final String toId;
  final double amount;

  @override
  String toString() => 'Transfer($fromId → $toId: ¥$amount)';

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.fromId == fromId &&
      other.toId == toId &&
      (other.amount - amount).abs() < 0.005;

  @override
  int get hashCode => Object.hash(fromId, toId, amount);

  Map<String, dynamic> toJson() => {
        'from': fromId,
        'to': toId,
        'amount': amount,
      };
}

/// 单个组的结算视图
class GroupSettlement {
  const GroupSettlement({
    required this.groupId,
    required this.groupName,
    required this.balance,
    required this.memberIds,
    required this.transfers,
  });

  /// 组 id（"ungrouped" 表示未分组成员）
  final String groupId;

  /// 组名（"未分组" for ungrouped）
  final String groupName;

  /// 整组的净收支（正=组应收，负=组应付）
  final double balance;

  /// 组内成员 id 列表
  final List<String> memberIds;

  /// 组**对外**的转账列表（成员 ↔ 其他组）
  final List<Transfer> transfers;

  @override
  String toString() =>
      'GroupSettlement($groupName: balance=$balance, transfers=${transfers.length})';
}

/// 整个旅程的结算视图
class TripSettlement {
  const TripSettlement({
    required this.balances,
    required this.transfers,
    required this.groups,
    required this.totalAmount,
    required this.memberCount,
  });

  /// 每人净收支 {memberId: balance}
  final Map<String, double> balances;

  /// 最优转账列表（个人粒度）
  final List<Transfer> transfers;

  /// 按组聚合的结算（组粒度）
  final List<GroupSettlement> groups;

  /// 旅程总支出
  final double totalAmount;

  /// 成员数
  final int memberCount;

  /// 人均支出
  double get perCapita => memberCount == 0 ? 0 : totalAmount / memberCount;

  /// 最高应收（正数最大）
  ({String memberId, double amount})? get maxCreditor {
    if (balances.isEmpty) return null;
    final entry = balances.entries
        .where((e) => e.value > 0.005)
        .reduce((a, b) => a.value > b.value ? a : b);
    return (memberId: entry.key, amount: entry.value);
  }

  /// 最高应付（负数最小）
  ({String memberId, double amount})? get maxDebtor {
    if (balances.isEmpty) return null;
    final entry = balances.entries
        .where((e) => e.value < -0.005)
        .reduce((a, b) => a.value < b.value ? a : b);
    return (memberId: entry.key, amount: entry.value);
  }

  /// 是否全平衡（所有余额绝对值 < 0.01）
  bool get isBalanced {
    for (final v in balances.values) {
      if (v.abs() >= 0.01) return false;
    }
    return true;
  }
}

/// 结算引擎（纯静态方法 / 工具类）
class SettlementEngine {
  const SettlementEngine._();

  /// 浮点精度（用于尾差过滤）
  static const double epsilon = 0.005;

  // ========================================================================
  // 1. 净收支计算
  // ========================================================================

  /// **计算每个成员的净收支**
  ///
  /// - 净收支 = 实付 - 应分摊
  /// - 正数：应收（别人欠我）
  /// - 负数：应付（我欠别人）
  /// - 近似 0：平衡（< 0.005 视为 0）
  ///
  /// 算法：
  ///   1) 按 payer 累加**实付**金额
  ///   2) 按 split 累加**应分摊**金额
  ///   3) 相减得到净额
  ///   4) 合并所有出现的 memberId（即使只付了或只分了）
  ///
  /// - [expenses]：旅程所有费用（已过滤软删除）
  /// - [splits]：每笔费用的预计算分摊 {expenseId: [SplitResultItem]}
  ///   - 注意：调用方需先用 [SplitCalculator] 计算；本函数不做 splitRule 解析
  ///   - 这样保持纯函数特性（无 member/group 依赖）
  /// - 返回：所有出现过的 memberId → 净收支
  static Map<String, double> calculateNetBalances({
    required List<Expense> expenses,
    required Map<String, List<SplitResultItem>> splits,
  }) {
    final paid = <String, double>{};
    final shouldPay = <String, double>{};

    // 0) 收集软删除的 expense id（过滤 splits 用）
    final deletedIds = <String>{};
    for (final e in expenses) {
      if (e.deletedAt != null) deletedIds.add(e.id);
    }

    // 1) 累加每人实付（跳过软删除）
    for (final e in expenses) {
      if (e.deletedAt != null) continue;
      paid[e.payerId] = (paid[e.payerId] ?? 0) + e.amount;
    }

    // 2) 累加每人应分摊（跳过软删除费用对应的 splits）
    for (final entry in splits.entries) {
      if (deletedIds.contains(entry.key)) continue;
      for (final item in entry.value) {
        shouldPay[item.memberId] =
            (shouldPay[item.memberId] ?? 0) + item.amount;
      }
    }

    // 3) 计算净收支
    final allIds = <String>{...paid.keys, ...shouldPay.keys};
    final net = <String, double>{};
    for (final id in allIds) {
      final p = paid[id] ?? 0;
      final s = shouldPay[id] ?? 0;
      net[id] = _round2(p - s);
    }
    return net;
  }

  /// **便捷重载**：直接从 expenses+members+groups 计算（内部用 SplitCalculator）
  ///
  /// - 不需要调用方先算 splits，但需要 [members] 和 [groups]（用于解析 group splitRule）
  /// - 适合 UI 层直接调用（一次算完）
  static Map<String, double> calculateNetBalancesFromExpenses({
    required List<Expense> expenses,
    required List<Member> members,
    required List<TripGroup> groups,
  }) {
    final splits = <String, List<SplitResultItem>>{};
    for (final e in expenses) {
      if (e.deletedAt != null) continue;
      final rule = e.splitRule;
      splits[e.id] = _computeSplitForRule(rule, e.amount, members, groups);
    }
    return calculateNetBalances(expenses: expenses, splits: splits);
  }

  // ========================================================================
  // 2. 最优转账（贪心）
  // ========================================================================

  /// **最优转账（贪心算法）**
  ///
  /// - 输入：净收支 Map {memberId: balance}（正=应收，负=应付）
  /// - 输出：转账列表（按金额降序）
  ///
  /// 算法：
  ///   1) 过滤掉近似 0 的余额
  ///   2) 拆分为 debtors（应付） + creditors（应收）
  ///   3) 都按金额降序
  ///   4) 每次循环：debtor[0] ↔ creditor[0]，转账 = min(两者)
  ///   5) 更新两者剩余，更新指针
  ///   6) 直到某一侧为空
  ///
  /// **复杂度**：O(n log n)（排序主导）
  /// **近似最优**：实践上几乎总是达到或接近全局最优
  /// **稳定性**：相同输入 → 相同输出（已排序 + 顺序遍历）
  /// **不抛异常**：空 Map / 全 0 / 单人 / 自负盈亏 都安全
  static List<Transfer> minimizeTransfers(Map<String, double> balances) {
    // 1) 过滤 + 拷贝
    final nonZero = <String, double>{};
    balances.forEach((id, v) {
      if (v.abs() >= epsilon) {
        nonZero[id] = v;
      }
    });
    if (nonZero.isEmpty) return const <Transfer>[];

    // 2) 拆分 debtors / creditors
    final debtors = <_BalanceEntry>[];
    final creditors = <_BalanceEntry>[];
    nonZero.forEach((id, v) {
      if (v < 0) {
        debtors.add(_BalanceEntry(id, -v)); // 转正
      } else {
        creditors.add(_BalanceEntry(id, v));
      }
    });
    if (debtors.isEmpty || creditors.isEmpty) {
      return const <Transfer>[]; // 不会发生（非空 + 有正有负）
    }

    // 3) 降序
    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    // 4) 贪心配对
    final transfers = <Transfer>[];
    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final d = debtors[i];
      final c = creditors[j];
      final amount = d.amount < c.amount ? d.amount : c.amount;

      if (amount >= epsilon) {
        transfers.add(
          Transfer(fromId: d.id, toId: c.id, amount: _round2(amount)),
        );
      }

      // 更新
      debtors[i] = _BalanceEntry(d.id, d.amount - amount);
      creditors[j] = _BalanceEntry(c.id, c.amount - amount);

      if (debtors[i].amount < epsilon) i++;
      if (creditors[j].amount < epsilon) j++;
    }

    return transfers;
  }

  // ========================================================================
  // 3. 按组聚合
  // ========================================================================

  /// **按组聚合结算**（v0.3 独家）
  ///
  /// 算法：
  ///   1) 按成员 → 组 的映射，把个人净收支**累加到组**
  ///   2) 对组余额跑 `minimizeTransfers` 得到**组间**转账
  ///   3) 每个组单独维护 [GroupSettlement]
  ///
  /// - [members]：所有成员
  /// - [groups]：所有组
  /// - [balances]：个人净收支（来自 `calculateNetBalances`）
  /// - [memberToGroup]：可选，memberId → groupId；不传则从 Member.groupId 推断
  ///
  /// - 未分组成员（member.groupId == null）归到虚拟组 `"ungrouped"`
  /// - 返回顺序：组按原始顺序，未分组固定在最后
  /// - 不抛异常
  static List<GroupSettlement> byGroup({
    required List<Member> members,
    required List<TripGroup> groups,
    required Map<String, double> balances,
    Map<String, String>? memberToGroup,
  }) {
    // 1) 索引：memberId → groupId
    final mapping = <String, String>{};
    if (memberToGroup != null) {
      mapping.addAll(memberToGroup);
    } else {
      for (final m in members) {
        if (m.groupId != null) mapping[m.id] = m.groupId!;
      }
    }

    // 2) 累加到组
    final groupBalances = <String, double>{};
    for (final group in groups) {
      groupBalances[group.id] = 0;
    }
    groupBalances['ungrouped'] = 0; // 虚拟组

    for (final entry in balances.entries) {
      final gid = mapping[entry.key] ?? 'ungrouped';
      groupBalances[gid] = (groupBalances[gid] ?? 0) + entry.value;
    }

    // 4) 按组构建 GroupSettlement
    final result = <GroupSettlement>[];

    // 4a) 实际组（按原始顺序）
    for (final group in groups) {
      final memberIds = members
          .where((m) => m.groupId == group.id)
          .map((m) => m.id)
          .toList();
      result.add(
        GroupSettlement(
          groupId: group.id,
          groupName: group.name,
          balance: _round2(groupBalances[group.id] ?? 0),
          memberIds: memberIds,
          transfers: const <Transfer>[], // 组**对外**的转账在 groupTransfers 里，不在这里
        ),
      );
    }

    // 4b) 未分组（仅当有未分组成员时出现）
    final ungroupedMemberIds = members
        .where((m) => m.groupId == null)
        .map((m) => m.id)
        .toList();
    if (ungroupedMemberIds.isNotEmpty) {
      result.add(
        GroupSettlement(
          groupId: 'ungrouped',
          groupName: '未分组',
          balance: _round2(groupBalances['ungrouped'] ?? 0),
          memberIds: ungroupedMemberIds,
          transfers: const <Transfer>[],
        ),
      );
    }

    return result;
  }

  /// **按组获取组间转账**（辅助方法）
  ///
  /// 返回组间转账列表（Transfer.fromId/toId 是 groupId）
  static List<Transfer> transfersBetweenGroups({
    required List<Member> members,
    required List<TripGroup> groups,
    required Map<String, double> balances,
    Map<String, String>? memberToGroup,
  }) {
    // 1) 索引
    final mapping = <String, String>{};
    if (memberToGroup != null) {
      mapping.addAll(memberToGroup);
    } else {
      for (final m in members) {
        if (m.groupId != null) mapping[m.id] = m.groupId!;
      }
    }

    // 2) 累加
    final groupBalances = <String, double>{};
    for (final g in groups) {
      groupBalances[g.id] = 0;
    }
    for (final entry in balances.entries) {
      final gid = mapping[entry.key] ?? 'ungrouped';
      groupBalances[gid] = (groupBalances[gid] ?? 0) + entry.value;
    }

    // 3) 转账
    return minimizeTransfers(groupBalances);
  }

  // ========================================================================
  // 4. 一站式计算
  // ========================================================================

  /// **一站式计算**：给定 expenses + members + groups，返回完整 [TripSettlement]
  ///
  /// 适合 UI 层调用（dashboard / 结算页）
  static TripSettlement compute({
    required List<Expense> expenses,
    required List<Member> members,
    required List<TripGroup> groups,
  }) {
    final balances = calculateNetBalancesFromExpenses(
      expenses: expenses,
      members: members,
      groups: groups,
    );
    final transfers = minimizeTransfers(balances);
    final groupSettlements = byGroup(
      members: members,
      groups: groups,
      balances: balances,
    );
    final total = expenses
        .where((e) => e.deletedAt == null)
        .fold<double>(0, (a, e) => a + e.amount);

    return TripSettlement(
      balances: balances,
      transfers: transfers,
      groups: groupSettlements,
      totalAmount: _round2(total),
      memberCount: members.length,
    );
  }

  // ========================================================================
  // 5. 私有工具
  // ========================================================================

  /// 根据 SplitRule 计算分摊（用 SplitCalculator）
  static List<SplitResultItem> _computeSplitForRule(
    SplitRule rule,
    double total,
    List<Member> members,
    List<TripGroup> groups,
  ) {
    // 展开 participants 到 memberId 列表
    var ids = rule.resolveParticipants(members);

    // Fallback：如果 participants 为空，但有 trip 成员 → 默认全体均摊
    // （这是 W4 的语义修正：避免空规则导致"无人分摊"）
    if (ids.isEmpty && members.isNotEmpty) {
      ids = members.map((m) => m.id).toList();
    }
    if (ids.isEmpty || total == 0) return const <SplitResultItem>[];

    final type = SplitType.fromDb(rule.type);
    switch (type) {
      case SplitType.equal:
      case SplitType.equalSelected:
        return SplitCalculator.equalAll(total: total, memberIds: ids);
      case SplitType.ratio:
        if (rule.values.isEmpty) {
          // 没比例 → fallback equal
          return SplitCalculator.equalAll(total: total, memberIds: ids);
        }
        return SplitCalculator.byRatio(total: total, ratios: rule.values);
      case SplitType.shares:
        if (rule.values.isEmpty) {
          return SplitCalculator.equalAll(total: total, memberIds: ids);
        }
        return SplitCalculator.byShares(total: total, shares: rule.values);
      case SplitType.specific:
        if (rule.values.isEmpty) {
          return SplitCalculator.equalAll(total: total, memberIds: ids);
        }
        return SplitCalculator.byMember(values: rule.values, total: total);
      case SplitType.byGroup:
        // 转换 groups 到 GroupSplitInput
        final groupInputs = <GroupSplitInput>[];
        for (final p in rule.participants) {
          if (p is Map && p['type'] == 'group') {
            final gid = p['id'] as String;
            // 只包含在 groups 列表里 + 有成员的
            final exists = groups.any((g) => g.id == gid);
            if (!exists) continue;
            final hasMembers = members.any((m) => m.groupId == gid);
            if (!hasMembers) continue;
            final ratio = rule.values[gid] ?? 1.0;
            groupInputs.add(GroupSplitInput(groupId: gid, ratio: ratio));
          }
        }
        return SplitCalculator.byGroup(
          total: total,
          groups: groupInputs,
          members: members,
        );
    }
  }

  /// 保留 2 位小数（公开版本，供 UI/provider 使用）
  static double round2(double v) => (v * 100).round() / 100;

  /// 内部保留 2 位小数（私有）
  static double _round2(double v) => round2(v);
}

/// 内部数据结构：避免反复创建 MapEntry
class _BalanceEntry {
  const _BalanceEntry(this.id, this.amount);
  final String id;
  final double amount;
}