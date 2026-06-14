/// 结算引擎 - 核心业务逻辑
/// 计算每个成员的净收支 + 最优转账路径
class SettlementEngine {
  /// 计算每个成员的净收支
  ///
  /// 输入：
  ///   - expenses: 所有账目
  ///   - splits: 所有分摊明细（expense_id -> [(member_id, amount)]）
  /// 输出：
  ///   - {member_id: net_amount}
  ///     正数 = 应收（别人欠我）
  ///     负数 = 应付（我欠别人）
  static Map<String, double> calculateNetBalances({
    required List<Map<String, dynamic>> expenses,
    required Map<String, List<Map<String, dynamic>>> splits,
  }) {
    final paid = <String, double>{};
    final shouldPay = <String, double>{};

    // 1. 累加每人付了多少
    for (final exp in expenses) {
      final payerId = exp['payer_id'] as String;
      final amount = (exp['amount'] as num).toDouble();
      paid[payerId] = (paid[payerId] ?? 0) + amount;
    }

    // 2. 累加每人应分摊多少
    for (final entry in splits.entries) {
      for (final split in entry.value) {
        final memberId = split['member_id'] as String;
        final amount = (split['amount'] as num).toDouble();
        shouldPay[memberId] = (shouldPay[memberId] ?? 0) + amount;
      }
    }

    // 3. 计算净收支
    final net = <String, double>{};
    final allMemberIds = {...paid.keys, ...shouldPay.keys};
    for (final id in allMemberIds) {
      net[id] = (paid[id] ?? 0) - (shouldPay[id] ?? 0);
    }
    return net;
  }

  /// 最优转账路径（贪心算法）
  /// 时间复杂度 O(n log n)
  ///
  /// 输入：{member_id: net_amount}（正数=应收，负数=应付）
  /// 输出：[(from, to, amount)] 转账列表
  static List<Map<String, dynamic>> minimizeTransfers(
      Map<String, double> balances) {
    // 过滤零金额
    final nonZero = Map<String, double>.from(balances);
    nonZero.removeWhere((_, v) => v.abs() < 0.01);

    // 分为债务人和债权人
    final debtors = <MapEntry<String, double>>[];
    final creditors = <MapEntry<String, double>>[];
    for (final entry in nonZero.entries) {
      if (entry.value < 0) {
        debtors.add(MapEntry(entry.key, -entry.value));  // 转成正数
      } else if (entry.value > 0) {
        creditors.add(MapEntry(entry.key, entry.value));
      }
    }

    // 按金额降序
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    final transfers = <Map<String, dynamic>>[];
    int i = 0, j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      final transferAmount =
          debtor.value < creditor.value ? debtor.value : creditor.value;

      // 浮点尾差处理：低于 0.01 视为零
      if (transferAmount >= 0.01) {
        transfers.add({
          'from': debtor.key,
          'to': creditor.key,
          'amount': _round2(transferAmount),
        });
      }

      // 更新余额
      debtors[i] = MapEntry(debtor.key, debtor.value - transferAmount);
      creditors[j] = MapEntry(creditor.key, creditor.value - transferAmount);

      if (debtors[i].value < 0.01) i++;
      if (creditors[j].value < 0.01) j++;
    }

    return transfers;
  }

  /// 按组维度聚合结算
  /// 输入：成员 net 余额 + 成员→组的映射
  /// 输出：组 net 余额 + 组间转账
  static Map<String, dynamic> aggregateByGroup({
    required Map<String, double> memberBalances,
    required Map<String, String> memberToGroup,  // member_id -> group_id
    required Map<String, String> groupNames,      // group_id -> name
  }) {
    // 1. 按组累加
    final groupBalances = <String, double>{};
    for (final entry in memberBalances.entries) {
      final groupId = memberToGroup[entry.key] ?? 'ungrouped';
      groupBalances[groupId] = (groupBalances[groupId] ?? 0) + entry.value;
    }

    // 2. 跑最优转账
    final transfers = minimizeTransfers(groupBalances);

    // 3. 加上组名
    final namedTransfers = transfers.map((t) {
      return {
        ...t,
        'from_name': groupNames[t['from']] ?? t['from'],
        'to_name': groupNames[t['to']] ?? t['to'],
      };
    }).toList();

    return {
      'group_balances': groupBalances,
      'transfers': namedTransfers,
    };
  }

  /// 金额保留 2 位小数
  static double _round2(double v) {
    return (v * 100).roundToDouble() / 100;
  }
}
