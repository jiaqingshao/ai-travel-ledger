/// SettlementEngine 单元测试（W4 / E-004）
///
/// 覆盖：
/// - 净收支计算（5 个）
/// - 最优转账贪心算法（10 个：2 人 / 3 人 / 5 人 / 15 人 / 混合正负 / 边界）
/// - 按组聚合（10 个：单组 / 多组 / 嵌套）
/// - 性能测试（1 个：100 笔 < 1 秒）
/// - TripSettlement / Transfer 等值类型（4 个）
/// - 合计：约 30 个测试
library;

import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/domain/services/settlement_engine.dart';
import 'package:ai_travel_ledger/domain/services/split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helpers
  Member makeMember({
    String id = 'm1',
    String tripId = 't1',
    String? groupId,
    String nickname = 'Test',
  }) {
    return Member(
      id: id,
      tripId: tripId,
      nickname: '$nickname$id',
      groupId: groupId,
      joinedAt: DateTime(2026, 6, 1),
    );
  }

  TripGroup makeGroup({
    String id = 'g1',
    String tripId = 't1',
    String name = 'Group',
  }) {
    return TripGroup(
      id: id,
      tripId: tripId,
      name: name,
      createdAt: DateTime(2026, 6, 1),
    );
  }

  Expense makeExpense({
    String id = 'e1',
    String tripId = 't1',
    String payerId = 'm1',
    double amount = 100,
    SplitRule? rule,
    DateTime? occurredAt,
  }) {
    final occ = occurredAt ?? DateTime(2026, 6, 1, 12);
    return Expense(
      id: id,
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      category: ExpenseCategory.food,
      occurredAt: occ,
      createdAt: occ,
      updatedAt: occ,
      splitRuleJson: rule != null
          ? '{"type":"${rule.type}","participants":[]}'
          : '{"type":"equal","participants":[]}',
    );
  }

  List<Transfer> runTransfers(Map<String, double> balances) =>
      SettlementEngine.minimizeTransfers(balances);

  // Transfer / TripSettlement 数据类
  group('Transfer', () {
    test('相等性 + hashCode（金额相同）', () {
      final a = const Transfer(fromId: 'a', toId: 'b', amount: 30);
      final b = const Transfer(fromId: 'a', toId: 'b', amount: 30.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('不相等（金额不同）', () {
      final a = const Transfer(fromId: 'a', toId: 'b', amount: 30);
      final b = const Transfer(fromId: 'a', toId: 'b', amount: 31);
      expect(a, isNot(equals(b)));
    });

    test('toJson', () {
      const t = Transfer(fromId: 'a', toId: 'b', amount: 30.5);
      expect(t.toJson(), {'from': 'a', 'to': 'b', 'amount': 30.5});
    });
  });

  group('TripSettlement', () {
    test('perCapita', () {
      final s = TripSettlement(
        balances: {},
        transfers: const [],
        groups: const [],
        totalAmount: 300,
        memberCount: 3,
      );
      expect(s.perCapita, 100);
    });

    test('perCapita = 0 when no members', () {
      final s = TripSettlement(
        balances: {},
        transfers: const [],
        groups: const [],
        totalAmount: 100,
        memberCount: 0,
      );
      expect(s.perCapita, 0);
    });

    test('isBalanced', () {
      final balanced = TripSettlement(
        balances: {'a': 0.0, 'b': 0.0},
        transfers: const [],
        groups: const [],
        totalAmount: 0,
        memberCount: 2,
      );
      expect(balanced.isBalanced, isTrue);

      final unbalanced = TripSettlement(
        balances: {'a': 30.0, 'b': -30.0},
        transfers: const [],
        groups: const [],
        totalAmount: 0,
        memberCount: 2,
      );
      expect(unbalanced.isBalanced, isFalse);
    });
  });

  // 净收支计算（5 个）
  group('calculateNetBalances', () {
    test('单笔费用：payer 实付，其余应分摊', () {
      // m1 付 30，m1/m2/m3 均摊 → 每人 10
      // m1 实付 30 - 应分 10 = +20
      // m2/m3 实付 0 - 应分 10 = -10
      final e = makeExpense(
        id: 'e1',
        payerId: 'm1',
        amount: 30,
        rule: const SplitRule(
          type: 'equal',
          participants: [],
          values: {},
        ),
      );
      final splits = {
        'e1': const [
          SplitResultItem(memberId: 'm1', amount: 10),
          SplitResultItem(memberId: 'm2', amount: 10),
          SplitResultItem(memberId: 'm3', amount: 10),
        ],
      };
      final net = SettlementEngine.calculateNetBalances(
        expenses: [e],
        splits: splits,
      );
      expect(net['m1'], closeTo(20, 0.01));
      expect(net['m2'], closeTo(-10, 0.01));
      expect(net['m3'], closeTo(-10, 0.01));
    });

    test('多笔费用累加', () {
      // m1 付 30，m1/m2 均摊 → m1 应分 15, m2 应分 15
      // m2 付 20，m1/m2 均摊 → m1 应分 10, m2 应分 10
      // 合计: m1 实付 30, 应分 25 → +5
      //       m2 实付 20, 应分 25 → -5
      final e1 = makeExpense(id: 'e1', payerId: 'm1', amount: 30);
      final e2 = makeExpense(id: 'e2', payerId: 'm2', amount: 20);
      final splits = {
        'e1': const [
          SplitResultItem(memberId: 'm1', amount: 15),
          SplitResultItem(memberId: 'm2', amount: 15),
        ],
        'e2': const [
          SplitResultItem(memberId: 'm1', amount: 10),
          SplitResultItem(memberId: 'm2', amount: 10),
        ],
      };
      final net = SettlementEngine.calculateNetBalances(
        expenses: [e1, e2],
        splits: splits,
      );
      expect(net['m1'], closeTo(5, 0.01));
      expect(net['m2'], closeTo(-5, 0.01));
    });

    test('软删除费用被忽略（paid + splits）', () {
      final e1 = makeExpense(id: 'e1', payerId: 'm1', amount: 100);
      final e2 = makeExpense(id: 'e2', payerId: 'm2', amount: 50);
      e2.deletedAt = DateTime(2026, 6, 2);
      final splits = {
        'e1': const [
          SplitResultItem(memberId: 'm1', amount: 50),
          SplitResultItem(memberId: 'm2', amount: 50),
        ],
        'e2': const [
          SplitResultItem(memberId: 'm1', amount: 25),
          SplitResultItem(memberId: 'm2', amount: 25),
        ],
      };
      final net = SettlementEngine.calculateNetBalances(
        expenses: [e1, e2],
        splits: splits,
      );
      // 只算 e1: m1 +50, m2 -50（e2 的 splits 也被过滤）
      expect(net['m1'], closeTo(50, 0.01));
      expect(net['m2'], closeTo(-50, 0.01));
    });

    test('无人参与（空 splits）→ 不出现在结果中', () {
      final e = makeExpense(payerId: 'm1', amount: 100);
      final net = SettlementEngine.calculateNetBalances(
        expenses: [e],
        splits: {},
      );
      expect(net['m1'], 100);
      expect(net.containsKey('m2'), isFalse);
    });

    test('空 expenses / 空 splits → 空 map', () {
      expect(
        SettlementEngine.calculateNetBalances(expenses: [], splits: {}),
        isEmpty,
      );
    });
  });

  // 最优转账（贪心） — 10 个
  group('minimizeTransfers', () {
    test('2 人：1 笔转账', () {
      final t = runTransfers({'a': 30.0, 'b': -30.0});
      expect(t, hasLength(1));
      expect(t.first.fromId, 'b');
      expect(t.first.toId, 'a');
      expect(t.first.amount, 30);
    });

    test('3 人：最多 2 笔转账', () {
      final Map<String, double> balances = {'a': 30, 'b': -20, 'c': -10};
      final t = runTransfers(balances);
      expect(t, hasLength(2));
      final total = t.fold<double>(0, (s, x) => s + x.amount);
      expect(total, closeTo(30, 0.01));
      expect(t.every((x) => x.toId == 'a'), isTrue);
    });

    test('5 人：A→B→C→D→E 链式', () {
      final Map<String, double> balances = {
        'a': 50,
        'b': 30,
        'c': -20,
        'd': -40,
        'e': -20,
      };
      final t = runTransfers(balances);
      final totalIn = t.fold<double>(0, (s, x) => s + x.amount);
      expect(totalIn, closeTo(80, 0.01));
      expect(t.length, lessThanOrEqualTo(4));
    });

    test('15 人：性能 + 正确性', () {
      // 8 人应收 + 7 人应付（总和平衡 = 440）
      final balances = <String, double>{
        'm0': 20.0,
        'm1': 30.0,
        'm2': 40.0,
        'm3': 50.0,
        'm4': 60.0,
        'm5': 70.0,
        'm6': 80.0,
        'm7': 90.0,
        'm8': -60.0,
        'm9': -60.0,
        'm10': -60.0,
        'm11': -60.0,
        'm12': -60.0,
        'm13': -60.0,
        'm14': -80.0,
      };
      double posSum = 0, negSum = 0;
      balances.forEach((_, v) {
        if (v > 0)
          posSum += v;
        else
          negSum += v.abs();
      });
      expect(posSum, closeTo(negSum, 0.01));
      expect(posSum, 440); // sanity

      final t = runTransfers(balances);
      final totalIn = t.fold<double>(0, (s, x) => s + x.amount);
      expect(totalIn, closeTo(440, 0.01));
      expect(t.length, lessThanOrEqualTo(14));
    });

    test('纯正余额（无人应付）→ 空', () {
      expect(runTransfers({'a': 10.0, 'b': 20.0}), isEmpty);
    });

    test('纯负余额（无人应收）→ 空', () {
      expect(runTransfers({'a': -10.0, 'b': -20.0}), isEmpty);
    });

    test('空 map → 空', () {
      expect(runTransfers({}), isEmpty);
    });

    test('全 0 / 近似 0 → 空', () {
      expect(runTransfers({'a': 0.0, 'b': 0.001}), isEmpty);
    });

    test('混合正负：4 人 + 一人完全平衡', () {
      final Map<String, double> balances = {
        'a': 30,
        'b': 20,
        'c': -50,
        'd': 0,
      };
      final t = runTransfers(balances);
      expect(t, hasLength(2));
      final total = t.fold<double>(0, (s, x) => s + x.amount);
      expect(total, closeTo(50, 0.01));
    });

    test('贪心：总是先配对最大债权 ↔ 最大债务', () {
      final Map<String, double> balances = {
        'a': 100,
        'b': 10,
        'c': -50,
        'd': -60,
      };
      final t = runTransfers(balances);
      expect(t, hasLength(3));
      final total = t.fold<double>(0, (s, x) => s + x.amount);
      expect(total, closeTo(110, 0.01));
    });
  });

  // 按组聚合（10 个）
  group('byGroup', () {
    test('单组：所有成员归同一组', () {
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm2', groupId: 'g1'),
        makeMember(id: 'm3', groupId: 'g1'),
      ];
      final groups = [makeGroup(id: 'g1', name: 'Family')];
      final Map<String, double> balances = {'m1': 30, 'm2': 10, 'm3': -40};

      final result = SettlementEngine.byGroup(
        members: members,
        groups: groups,
        balances: balances,
      );
      expect(result, hasLength(1));
      expect(result.first.groupId, 'g1');
      expect(result.first.groupName, 'Family');
      expect(result.first.balance, closeTo(0, 0.01));
      expect(result.first.memberIds, ['m1', 'm2', 'm3']);
    });

    test('两组：A 组应收，B 组应付', () {
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm2', groupId: 'g2'),
        makeMember(id: 'm3', groupId: 'g2'),
      ];
      final groups = [
        makeGroup(id: 'g1', name: 'A'),
        makeGroup(id: 'g2', name: 'B'),
      ];
      final Map<String, double> balances = {'m1': 50, 'm2': -20, 'm3': -30};

      final result = SettlementEngine.byGroup(
        members: members,
        groups: groups,
        balances: balances,
      );
      expect(result, hasLength(2));
      final g1 = result.firstWhere((g) => g.groupId == 'g1');
      final g2 = result.firstWhere((g) => g.groupId == 'g2');
      expect(g1.balance, closeTo(50, 0.01));
      expect(g2.balance, closeTo(-50, 0.01));
    });

    test('未分组成员归到虚拟组 ungrouped', () {
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm2', groupId: null),
      ];
      final groups = [makeGroup(id: 'g1', name: 'A')];
      final Map<String, double> balances = {'m1': 20, 'm2': -20};

      final result = SettlementEngine.byGroup(
        members: members,
        groups: groups,
        balances: balances,
      );
      expect(result, hasLength(2));
      expect(result.last.groupId, 'ungrouped');
      expect(result.last.groupName, '未分组');
      expect(result.last.memberIds, ['m2']);
    });

    test('无组（空 groups）→ 所有人为 ungrouped', () {
      final members = [makeMember(id: 'm1'), makeMember(id: 'm2')];
      final Map<String, double> balances = {'m1': 30, 'm2': -30};
      final result = SettlementEngine.byGroup(
        members: members,
        groups: [],
        balances: balances,
      );
      expect(result, hasLength(1));
      expect(result.first.groupId, 'ungrouped');
      expect(result.first.balance, closeTo(0, 0.01));
    });

    test('自定义 memberToGroup 覆盖', () {
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm2', groupId: 'g1'),
      ];
      final groups = [makeGroup(id: 'g1'), makeGroup(id: 'g2')];
      final Map<String, double> balances = {'m1': 50, 'm2': -50};

      final result = SettlementEngine.byGroup(
        members: members,
        groups: groups,
        balances: balances,
        memberToGroup: {'m1': 'g1', 'm2': 'g2'},
      );
      final g1 = result.firstWhere((g) => g.groupId == 'g1');
      final g2 = result.firstWhere((g) => g.groupId == 'g2');
      expect(g1.balance, closeTo(50, 0.01));
      expect(g2.balance, closeTo(-50, 0.01));
    });

    test('组间转账：纯函数（3 组）', () {
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm2', groupId: 'g2'),
        makeMember(id: 'm3', groupId: 'g3'),
      ];
      final groups = [
        makeGroup(id: 'g1', name: 'A'),
        makeGroup(id: 'g2', name: 'B'),
        makeGroup(id: 'g3', name: 'C'),
      ];
      final Map<String, double> balances = {'m1': 50, 'm2': -20, 'm3': -30};

      final transfers = SettlementEngine.transfersBetweenGroups(
        members: members,
        groups: groups,
        balances: balances,
      );
      final total = transfers.fold<double>(0, (s, x) => s + x.amount);
      expect(total, closeTo(50, 0.01));
      expect(transfers.length, lessThanOrEqualTo(2));
    });

    test('组已平衡 → 空转账', () {
      final transfers = SettlementEngine.transfersBetweenGroups(
        members: [
          makeMember(id: 'm1', groupId: 'g1'),
          makeMember(id: 'm2', groupId: 'g1'),
        ],
        groups: [makeGroup(id: 'g1')],
        balances: {'m1': 10.0, 'm2': -10.0},
      );
      expect(transfers, isEmpty);
    });

    test('嵌套：成员 id 重复（mapping 覆盖）', () {
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm1', groupId: 'g2'),
      ];
      final groups = [makeGroup(id: 'g1'), makeGroup(id: 'g2')];
      final Map<String, double> balances = {'m1': 30};

      final result = SettlementEngine.byGroup(
        members: members,
        groups: groups,
        balances: balances,
      );
      final g2 = result.firstWhere((g) => g.groupId == 'g2');
      expect(g2.balance, closeTo(30, 0.01));
    });

    test('组按原始顺序返回，ungrouped 在最后', () {
      final members = [
        makeMember(id: 'm1', groupId: null),
        makeMember(id: 'm2', groupId: 'g2'),
        makeMember(id: 'm3', groupId: 'g1'),
      ];
      final groups = [
        makeGroup(id: 'g1', name: 'A'),
        makeGroup(id: 'g2', name: 'B'),
      ];
      final Map<String, double> balances = {'m1': 0.0, 'm2': 10, 'm3': -10};

      final result = SettlementEngine.byGroup(
        members: members,
        groups: groups,
        balances: balances,
      );
      expect(result.first.groupId, 'g1');
      expect(result[1].groupId, 'g2');
      expect(result.last.groupId, 'ungrouped');
    });

    test('空成员 → 只包含真实组（不出现 ungrouped）', () {
      final result = SettlementEngine.byGroup(
        members: [],
        groups: [makeGroup(id: 'g1')],
        balances: {},
      );
      expect(result, hasLength(1));
      expect(result.first.groupId, 'g1');
      expect(result.first.balance, 0);
    });
  });

  // 一站式 compute（3 个）
  group('compute', () {
    test('完整计算：含 transfer + group + total', () {
      final e = makeExpense(
        payerId: 'm1',
        amount: 60,
        rule: const SplitRule(type: 'equal', participants: []),
      );
      final members = [
        makeMember(id: 'm1', nickname: 'Alice', groupId: 'g1'),
        makeMember(id: 'm2', nickname: 'Bob', groupId: 'g1'),
        makeMember(id: 'm3', nickname: 'Carol', groupId: 'g1'),
      ];
      final groups = [
        makeGroup(id: 'g1', name: 'Family'),
      ];

      final result = SettlementEngine.compute(
        expenses: [e],
        members: members,
        groups: groups,
      );

      expect(result.totalAmount, 60);
      expect(result.memberCount, 3);
      expect(result.perCapita, 20);
      expect(result.balances['m1'], closeTo(40, 0.01));
      expect(result.balances['m2'], closeTo(-20, 0.01));
      expect(result.balances['m3'], closeTo(-20, 0.01));
      expect(result.transfers, hasLength(2));
      expect(result.groups, hasLength(1));
    });

    test('compute 跳过软删除', () {
      final e1 = makeExpense(id: 'e1', payerId: 'm1', amount: 100);
      final e2 = makeExpense(id: 'e2', payerId: 'm2', amount: 50);
      e2.deletedAt = DateTime(2026, 6, 2);
      final members = [makeMember(id: 'm1'), makeMember(id: 'm2')];

      final result = SettlementEngine.compute(
        expenses: [e1, e2],
        members: members,
        groups: [],
      );
      expect(result.totalAmount, 100);
    });

    test('compute + byGroup 互相一致', () {
      final e = makeExpense(
        payerId: 'm1',
        amount: 90,
        rule: const SplitRule(type: 'equal', participants: []),
      );
      final members = [
        makeMember(id: 'm1', groupId: 'g1'),
        makeMember(id: 'm2', groupId: 'g1'),
        makeMember(id: 'm3', groupId: 'g2'),
        makeMember(id: 'm4', groupId: 'g2'),
      ];
      final groups = [makeGroup(id: 'g1'), makeGroup(id: 'g2')];

      final result = SettlementEngine.compute(
        expenses: [e],
        members: members,
        groups: groups,
      );
      expect(result.balances['m1'], closeTo(67.5, 0.01));
      expect(result.balances['m2'], closeTo(-22.5, 0.01));
      expect(result.balances['m3'], closeTo(-22.5, 0.01));
      expect(result.balances['m4'], closeTo(-22.5, 0.01));
      final g1 = result.groups.firstWhere((g) => g.groupId == 'g1');
      final g2 = result.groups.firstWhere((g) => g.groupId == 'g2');
      expect(g1.balance, closeTo(45, 0.01));
      expect(g2.balance, closeTo(-45, 0.01));
      final transfers = SettlementEngine.transfersBetweenGroups(
        members: members,
        groups: groups,
        balances: result.balances,
      );
      expect(transfers, hasLength(1));
      expect(transfers.first.fromId, 'g2');
      expect(transfers.first.toId, 'g1');
      expect(transfers.first.amount, closeTo(45, 0.01));
    });
  });

  // 性能测试
  group('performance', () {
    test('100 笔费用 + 15 人 < 1 秒', () {
      final members = List.generate(15, (i) => makeMember(id: 'm$i'));
      final expenses = <Expense>[];
      for (int i = 0; i < 100; i++) {
        expenses.add(makeExpense(
          id: 'e$i',
          payerId: 'm${i % 15}',
          amount: (i * 3.7 + 10),
        ));
      }

      final stopwatch = Stopwatch()..start();
      final result = SettlementEngine.compute(
        expenses: expenses,
        members: members,
        groups: [],
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(result.transfers.isNotEmpty, isTrue);
      expect(result.balances.length, 15);
    });

    test('minimizeTransfers 1000 次重复 < 1 秒', () {
      final balances = <String, double>{
        for (int i = 0; i < 15; i++)
          'm$i': (i % 2 == 0 ? 1 : -1) * (i * 10 + 5).toDouble(),
      };
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        SettlementEngine.minimizeTransfers(balances);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  // GroupSettlement 数据类
  group('GroupSettlement', () {
    test('toString 含 group name', () {
      const gs = GroupSettlement(
        groupId: 'g1',
        groupName: 'Family',
        balance: 50,
        memberIds: ['m1', 'm2'],
        transfers: [],
      );
      expect(gs.toString(), contains('Family'));
    });

    test('balance 保留 2 位小数', () {
      const gs = GroupSettlement(
        groupId: 'g1',
        groupName: 'G',
        balance: 30.5,
        memberIds: [],
        transfers: [],
      );
      expect(gs.balance, 30.5);
    });
  });

  // round2 / epsilon 工具
  group('round2 + epsilon', () {
    test('round2 保留 2 位小数', () {
      expect(SettlementEngine.round2(1.234), 1.23);
      expect(SettlementEngine.round2(1.236), 1.24);
      expect(SettlementEngine.round2(2.5), 2.5);
      expect(SettlementEngine.round2(100.123), 100.12);
    });

    test('epsilon = 0.005', () {
      expect(SettlementEngine.epsilon, 0.005);
    });
  });
}
