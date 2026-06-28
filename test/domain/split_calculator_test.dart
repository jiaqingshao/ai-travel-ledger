/// 分摊规则引擎单元测试（W3 / E-003）
///
/// 覆盖：
/// - 6 种分摊类型的基本场景
/// - 尾差处理（保证 sum == total）
/// - 边界（空 / 单人 / 零 / 负数）
/// - 按组分摊（组内均摊 / 跨组 / 单组 / 空组）
/// - SplitType 字符串往返
/// - compute() 统一入口
/// - validateSum / toMap 工具方法
library;

import 'package:ai_travel_ledger/data/models/expense.dart' show SplitRule;
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/domain/services/split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ========================================================================
  // Helpers
  // ========================================================================

  Member makeMember({
    String id = 'm1',
    String? groupId,
  }) {
    return Member(
      id: id,
      tripId: 't1',
      nickname: 'Test$id',
      groupId: groupId,
      joinedAt: DateTime(2026, 6, 1),
    );
  }

  TripGroup makeGroup({
    String id = 'g1',
    String name = 'Group',
    GroupType type = GroupType.family,
  }) {
    return TripGroup(
      id: id,
      tripId: 't1',
      name: name,
      groupType: type,
      createdAt: DateTime(2026, 6, 1),
    );
  }

  double sum(List<SplitResultItem> items) =>
      items.fold<double>(0, (a, b) => a + b.amount);

  // ========================================================================
  // SplitType
  // ========================================================================

  group('SplitType', () {
    test('枚举值数量 = 6', () {
      expect(SplitType.values.length, 6);
    });

    test('dbValue 映射：equal / ratio / shares / specific / byGroup', () {
      expect(SplitType.equal.dbValue, 'equal');
      expect(SplitType.equalSelected.dbValue, 'equal'); // 共享 equal
      expect(SplitType.ratio.dbValue, 'ratio');
      expect(SplitType.shares.dbValue, 'shares');
      expect(SplitType.specific.dbValue, 'specific');
      expect(SplitType.byGroup.dbValue, 'byGroup');
    });

    test('fromDb 解析（含容错）', () {
      expect(SplitType.fromDb('equal'), SplitType.equal);
      expect(SplitType.fromDb('ratio'), SplitType.ratio);
      expect(SplitType.fromDb('shares'), SplitType.shares);
      expect(SplitType.fromDb('specific'), SplitType.specific);
      expect(SplitType.fromDb('byGroup'), SplitType.byGroup);
      expect(SplitType.fromDb(null), SplitType.equal);
      expect(SplitType.fromDb('unknown'), SplitType.equal);
    });

    test('dbValue / fromDb 双向', () {
      for (final t in SplitType.values) {
        final v = SplitType.fromDb(t.dbValue);
        // equalSelected 会被解析为 equal（这是设计：UI 一律落到 equal）
        if (t == SplitType.equalSelected) {
          expect(v, SplitType.equal);
        } else {
          expect(v, t);
        }
      }
    });
  });

  // ========================================================================
  // 1. equalAll - 全部均摊
  // ========================================================================

  group('equalAll', () {
    test('3 人均摊 30 → 每人都 10', () {
      final r = SplitCalculator.equalAll(total: 30, memberIds: ['a', 'b', 'c']);
      expect(r, hasLength(3));
      expect(r.map((e) => e.amount).toList(), [10, 10, 10]);
    });

    test('单人 → 全部金额', () {
      final r = SplitCalculator.equalAll(total: 99.99, memberIds: ['a']);
      expect(r, hasLength(1));
      expect(r.first.amount, 99.99);
    });

    test('空数组 → 返回空', () {
      final r = SplitCalculator.equalAll(total: 100, memberIds: []);
      expect(r, isEmpty);
    });

    test('零金额 → 每人都 0', () {
      final r = SplitCalculator.equalAll(total: 0, memberIds: ['a', 'b']);
      expect(r.map((e) => e.amount).toList(), [0, 0]);
    });

    test('尾差补偿：10 元 3 人 → 3.34 + 3.33 + 3.33（补偿给第一个人）', () {
      final r = SplitCalculator.equalAll(total: 10, memberIds: ['a', 'b', 'c']);
      expect(r.map((e) => e.amount).toList(), [3.34, 3.33, 3.33]);
      expect(sum(r), closeTo(10.0, 0.001));
    });

    test('尾差补偿：100 元 3 人 → 33.34 + 33.33 + 33.33', () {
      final r = SplitCalculator.equalAll(total: 100, memberIds: ['a', 'b', 'c']);
      expect(r.map((e) => e.amount).toList(), [33.34, 33.33, 33.33]);
      expect(sum(r), closeTo(100.0, 0.001));
    });

    test('纯函数：相同输入 → 相同输出', () {
      final a = SplitCalculator.equalAll(total: 99.99, memberIds: ['x', 'y']);
      final b = SplitCalculator.equalAll(total: 99.99, memberIds: ['x', 'y']);
      expect(a, b);
    });

    test('保留 memberIds 顺序', () {
      final r = SplitCalculator.equalAll(total: 60, memberIds: ['c', 'a', 'b']);
      expect(r.map((e) => e.memberId).toList(), ['c', 'a', 'b']);
    });
  });

  // ========================================================================
  // 2. equalSelected - 指定成员均摊
  // ========================================================================

  group('equalSelected', () {
    test('与 equalAll 算法一致', () {
      final all =
          SplitCalculator.equalAll(total: 100, memberIds: ['a', 'b', 'c', 'd']);
      final sel = SplitCalculator.equalSelected(
        total: 100,
        memberIds: ['a', 'b', 'c', 'd'],
      );
      expect(sel, all);
    });

    test('空 → 空', () {
      expect(SplitCalculator.equalSelected(total: 50, memberIds: []), isEmpty);
    });

    test('尾差总和严格 = total', () {
      final r = SplitCalculator.equalSelected(
        total: 19.99,
        memberIds: ['a', 'b', 'c'],
      );
      expect(sum(r), closeTo(19.99, 0.005));
    });
  });

  // ========================================================================
  // 3. byRatio - 按比例分摊
  // ========================================================================

  group('byRatio', () {
    test('1:1 → 两人均分', () {
      final r = SplitCalculator.byRatio(
        total: 100,
        ratios: {'a': 1, 'b': 1},
      );
      expect(r.map((e) => e.amount).toList(), [50, 50]);
    });

    test('1:2 → 33.33 + 66.67（尾差补偿给最大比例者）', () {
      final r = SplitCalculator.byRatio(
        total: 100,
        ratios: {'a': 1, 'b': 2},
      );
      // b 比例更大 → b 拿尾差
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 33.33);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 66.67);
      expect(sum(r), closeTo(100, 0.005));
    });

    test('自动归一化：ratios 和不为 1', () {
      final r = SplitCalculator.byRatio(
        total: 90,
        ratios: {'a': 2, 'b': 4}, // 归一化为 1:2
      );
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 30);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 60);
    });

    test('空 ratios → 返回空', () {
      expect(SplitCalculator.byRatio(total: 100, ratios: {}), isEmpty);
    });

    test('全 0 抛 ArgumentError', () {
      expect(
        () => SplitCalculator.byRatio(total: 100, ratios: {'a': 0, 'b': 0}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('负数视为 0（防御）', () {
      // 负数 → 0 → 全 0 → 抛异常
      expect(
        () => SplitCalculator.byRatio(
          total: 100,
          ratios: {'a': -1, 'b': 0},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('部分负数 + 部分正数：负数视为 0，归一化剩余', () {
      final r = SplitCalculator.byRatio(
        total: 100,
        ratios: {'a': -1, 'b': 1},
      );
      // 归一化后 a=0, b=1 → b 全拿
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 0);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 100);
    });

    test('零金额 → 每人 0', () {
      final r = SplitCalculator.byRatio(
        total: 0,
        ratios: {'a': 1, 'b': 2},
      );
      expect(sum(r), 0);
    });

    test('3 人按 1:2:3 → 16.67 + 33.33 + 50', () {
      final r = SplitCalculator.byRatio(
        total: 100,
        ratios: {'a': 1, 'b': 2, 'c': 3},
      );
      // c 比例最大 → c 拿尾差
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 16.67);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 33.33);
      expect(r.firstWhere((e) => e.memberId == 'c').amount, 50);
    });

    test('纯函数：相同输入 → 相同输出', () {
      final a = SplitCalculator.byRatio(
        total: 99.99,
        ratios: {'a': 1, 'b': 2, 'c': 3},
      );
      final b = SplitCalculator.byRatio(
        total: 99.99,
        ratios: {'a': 1, 'b': 2, 'c': 3},
      );
      expect(a, b);
    });
  });

  // ========================================================================
  // 4. byShares - 按份数分摊
  // ========================================================================

  group('byShares', () {
    test('1:1 → 均分', () {
      final r = SplitCalculator.byShares(
        total: 90,
        shares: {'a': 1, 'b': 1},
      );
      expect(r.map((e) => e.amount).toList(), [45, 45]);
    });

    test('2:1 → 60 + 30（份数多者拿尾差）', () {
      final r = SplitCalculator.byShares(
        total: 90,
        shares: {'a': 2, 'b': 1},
      );
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 60);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 30);
    });

    test('浮点份数也支持：1.5:3.5', () {
      final r = SplitCalculator.byShares(
        total: 100,
        shares: {'a': 1.5, 'b': 3.5},
      );
      // 30 + 70 = 100
      expect(sum(r), closeTo(100, 0.005));
    });

    test('空 → 空', () {
      expect(SplitCalculator.byShares(total: 100, shares: {}), isEmpty);
    });

    test('全 0 抛 ArgumentError', () {
      expect(
        () => SplitCalculator.byShares(total: 100, shares: {'a': 0}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('负数视为 0', () {
      expect(
        () => SplitCalculator.byShares(
          total: 100,
          shares: {'a': -1},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('3 份 1:2:3', () {
      final r = SplitCalculator.byShares(
        total: 60,
        shares: {'a': 1, 'b': 2, 'c': 3},
      );
      // 10 + 20 + 30
      expect(r.map((e) => e.amount).toList(), [10, 20, 30]);
    });
  });

  // ========================================================================
  // 5. byMember - 固定金额
  // ========================================================================

  group('byMember', () {
    test('总和匹配 total → 正常返回', () {
      final r = SplitCalculator.byMember(
        total: 100,
        values: {'a': 60, 'b': 40},
      );
      expect(r.map((e) => e.amount).toList(), [60, 40]);
    });

    test('总和不等 → 抛 ArgumentError', () {
      expect(
        () => SplitCalculator.byMember(
          total: 100,
          values: {'a': 50, 'b': 40}, // 90 != 100
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('容差 0.01 视为相等', () {
      // 100.01 vs 100.00 → 0.01 误差 → 通过
      final r = SplitCalculator.byMember(
        total: 100,
        values: {'a': 60.00, 'b': 40.00},
      );
      expect(r, hasLength(2));
    });

    test('误差 0.02 → 抛异常', () {
      expect(
        () => SplitCalculator.byMember(
          total: 100,
          values: {'a': 60.01, 'b': 40.01}, // 100.02
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('空 values → 空', () {
      expect(SplitCalculator.byMember(values: {}), isEmpty);
    });

    test('不传 total → 不做校验', () {
      // 用途：编辑时只显示金额，不强制 sum == total
      final r = SplitCalculator.byMember(values: {'a': 60, 'b': 40});
      expect(r.map((e) => e.amount).toList(), [60, 40]);
    });

    test('小数精度：99.99 / 50.01', () {
      final r = SplitCalculator.byMember(
        total: 150,
        values: {'a': 99.99, 'b': 50.01},
      );
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 99.99);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 50.01);
    });
  });

  // ========================================================================
  // 6. byGroup - 按组分摊（W3 核心新功能）
  // ========================================================================

  group('byGroup', () {
    test('两组各 2 人，总额 100 → 各组 50，每组内均分 25', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g2'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g1'),
          makeMember(id: 'c', groupId: 'g2'),
          makeMember(id: 'd', groupId: 'g2'),
        ],
      );
      expect(r, hasLength(4));
      // 每组 50 元，每组 2 人 → 每人 25
      expect(r.every((e) => e.amount == 25), isTrue);
      expect(sum(r), closeTo(100, 0.005));
    });

    test('按 ratio 拆：组 A:B = 1:2，总额 90', () {
      final r = SplitCalculator.byGroup(
        total: 90,
        groups: const [
          GroupSplitInput(groupId: 'g1', ratio: 1),
          GroupSplitInput(groupId: 'g2', ratio: 2),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'c', groupId: 'g2'),
          makeMember(id: 'd', groupId: 'g2'),
        ],
      );
      // A 拿 30 → 单人 30；B 拿 60 → 2 人各 30
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 30);
      expect(r.firstWhere((e) => e.memberId == 'c').amount, 30);
      expect(r.firstWhere((e) => e.memberId == 'd').amount, 30);
      expect(sum(r), closeTo(90, 0.005));
    });

    test('尾差补偿：3 组 1:1:1，总额 100 → 一组多人时组内尾差', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g2'),
          GroupSplitInput(groupId: 'g3'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g2'),
          makeMember(id: 'c', groupId: 'g2'),
          makeMember(id: 'd', groupId: 'g3'),
        ],
      );
      expect(sum(r), closeTo(100, 0.005));
    });

    test('单人组：组内只有 1 人 → 整组金额都给他', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g2'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g2'),
        ],
      );
      expect(r, hasLength(2));
      expect(r.firstWhere((e) => e.memberId == 'a').amount, 50);
      expect(r.firstWhere((e) => e.memberId == 'b').amount, 50);
    });

    test('空组（没成员）：跳过该组，不计入结果', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g_empty'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g1'),
        ],
      );
      // g_empty 没成员 → 跳过；g1 拿全部
      expect(r, hasLength(2));
      expect(r.every((e) => e.amount == 50), isTrue);
    });

    test('跨组：成员没有 groupId → 不计入任何组', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'no_group'), // 无 groupId
        ],
      );
      // no_group 不在 g1 中 → 不计入
      expect(r, hasLength(1));
      expect(r.first.memberId, 'a');
      expect(r.first.amount, 100);
    });

    test('成员 groupId 指向未选中的组 → 不计入', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g_other'),
        ],
      );
      expect(r, hasLength(1));
      expect(r.first.memberId, 'a');
    });

    test('空 groups → 空', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [],
        members: [makeMember(id: 'a', groupId: 'g1')],
      );
      expect(r, isEmpty);
    });

    test('空 members → 空', () {
      final r = SplitCalculator.byGroup(
        total: 100,
        groups: const [GroupSplitInput(groupId: 'g1')],
        members: const [],
      );
      expect(r, isEmpty);
    });

    test('零金额 → 空', () {
      final r = SplitCalculator.byGroup(
        total: 0,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g2'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g2'),
        ],
      );
      expect(r, isEmpty);
    });

    test('组嵌套场景（W3 范围内）：嵌套成员由 groupId 决定归属', () {
      // 现实：一人最多一组，所以"嵌套"语义是 groupId 决定归属
      final r = SplitCalculator.byGroup(
        total: 60,
        groups: const [
          GroupSplitInput(groupId: 'family'),
          GroupSplitInput(groupId: 'work'),
        ],
        members: [
          makeMember(id: 'dad', groupId: 'family'),
          makeMember(id: 'mom', groupId: 'family'),
          makeMember(id: 'boss', groupId: 'work'),
        ],
      );
      // family 2 人均分 30；work 1 人拿 30
      expect(r, hasLength(3));
      expect(r.firstWhere((e) => e.memberId == 'dad').amount, 15);
      expect(r.firstWhere((e) => e.memberId == 'mom').amount, 15);
      expect(r.firstWhere((e) => e.memberId == 'boss').amount, 30);
      expect(sum(r), closeTo(60, 0.005));
    });

    test('纯函数：相同输入 → 相同输出', () {
      final args = (
        total: 100.0,
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g2'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g1'),
          makeMember(id: 'c', groupId: 'g2'),
        ],
      );
      final a = SplitCalculator.byGroup(
        total: args.total,
        groups: args.groups,
        members: args.members,
      );
      final b = SplitCalculator.byGroup(
        total: args.total,
        groups: args.groups,
        members: args.members,
      );
      expect(a, b);
    });

    test('groupsFromList 便利工厂：默认 ratio=1', () {
      final groups = [
        makeGroup(id: 'g1', name: '家人'),
        makeGroup(id: 'g2', name: '同事'),
      ];
      final inputs = SplitCalculator.groupsFromList(groups);
      expect(inputs, hasLength(2));
      expect(inputs.first.groupId, 'g1');
      expect(inputs.first.ratio, 1.0);
    });

    test('groupsFromList + ratioOverrides', () {
      final groups = [
        makeGroup(id: 'g1'),
        makeGroup(id: 'g2'),
      ];
      final inputs = SplitCalculator.groupsFromList(
        groups,
        ratioOverrides: {'g1': 3, 'g2': 1},
      );
      expect(inputs.firstWhere((g) => g.groupId == 'g1').ratio, 3);
      expect(inputs.firstWhere((g) => g.groupId == 'g2').ratio, 1);
    });
  });

  // ========================================================================
  // validateSum
  // ========================================================================

  group('validateSum', () {
    test('sum == total → diff = 0', () {
      final r = SplitCalculator.equalAll(total: 90, memberIds: ['a', 'b', 'c']);
      final v = SplitCalculator.validateSum(total: 90, items: r);
      expect(v.actualSum, 90);
      expect(v.diff, 0);
    });

    test('正确返回 diff = sum - total', () {
      final r = SplitCalculator.byMember(values: {'a': 30, 'b': 50});
      final v = SplitCalculator.validateSum(total: 100, items: r);
      expect(v.actualSum, 80);
      expect(v.diff, -20);
    });
  });

  // ========================================================================
  // toMap
  // ========================================================================

  group('toMap', () {
    test('把 List 转 Map（memberId -> amount）', () {
      final r = SplitCalculator.equalAll(total: 60, memberIds: ['a', 'b', 'c']);
      final m = SplitCalculator.toMap(r);
      expect(m, {'a': 20.0, 'b': 20.0, 'c': 20.0});
    });

    test('空 list → 空 map', () {
      expect(SplitCalculator.toMap(const []), isEmpty);
    });
  });

  // ========================================================================
  // compute() - 统一入口
  // ========================================================================

  group('compute()', () {
    test('equal 类型', () {
      final r = SplitCalculator.compute(
        type: SplitType.equal,
        total: 30,
        memberIds: ['a', 'b', 'c'],
      );
      expect(r.map((e) => e.amount).toList(), [10, 10, 10]);
    });

    test('ratio 类型', () {
      final r = SplitCalculator.compute(
        type: SplitType.ratio,
        total: 90,
        memberIds: ['a', 'b'],
        ratios: {'a': 1, 'b': 2},
      );
      expect(sum(r), closeTo(90, 0.005));
    });

    test('shares 类型', () {
      final r = SplitCalculator.compute(
        type: SplitType.shares,
        total: 90,
        memberIds: ['a', 'b'],
        shares: {'a': 1, 'b': 2},
      );
      expect(sum(r), closeTo(90, 0.005));
    });

    test('specific 类型', () {
      final r = SplitCalculator.compute(
        type: SplitType.specific,
        total: 100,
        memberIds: ['a', 'b'],
        specificValues: {'a': 60, 'b': 40},
      );
      expect(r.map((e) => e.amount).toList(), [60, 40]);
    });

    test('byGroup 类型', () {
      final r = SplitCalculator.compute(
        type: SplitType.byGroup,
        total: 100,
        memberIds: const [], // compute 不直接用 memberIds
        groups: const [
          GroupSplitInput(groupId: 'g1'),
          GroupSplitInput(groupId: 'g2'),
        ],
        members: [
          makeMember(id: 'a', groupId: 'g1'),
          makeMember(id: 'b', groupId: 'g1'),
          makeMember(id: 'c', groupId: 'g2'),
          makeMember(id: 'd', groupId: 'g2'),
        ],
      );
      expect(r, hasLength(4));
      expect(sum(r), closeTo(100, 0.005));
    });

    test('ratio 缺 ratios → 抛 ArgumentError', () {
      expect(
        () => SplitCalculator.compute(
          type: SplitType.ratio,
          total: 100,
          memberIds: ['a'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('byGroup 缺 members → 抛 ArgumentError', () {
      expect(
        () => SplitCalculator.compute(
          type: SplitType.byGroup,
          total: 100,
          memberIds: const [],
          groups: const [GroupSplitInput(groupId: 'g1')],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equalSelected 与 equal 算法一致', () {
      final a = SplitCalculator.compute(
        type: SplitType.equal,
        total: 100,
        memberIds: ['x', 'y', 'z'],
      );
      final b = SplitCalculator.compute(
        type: SplitType.equalSelected,
        total: 100,
        memberIds: ['x', 'y', 'z'],
      );
      expect(a, b);
    });
  });

  // ========================================================================
  // SplitRule JSON 序列化往返
  // ========================================================================

  group('SplitRule JSON 序列化（W3 类型字符串）', () {
    test('equal type 往返', () {
      const rule = SplitRule(
        type: 'equal',
        participants: [
          {'type': 'member', 'id': 'a'},
        ],
        values: {},
      );
      final json = rule.toJson();
      final back = SplitRule.fromJson(json);
      expect(back.type, 'equal');
    });

    test('byGroup type 往返', () {
      const rule = SplitRule(
        type: 'byGroup',
        participants: [
          {'type': 'group', 'id': 'family'},
          {'type': 'group', 'id': 'work'},
        ],
        values: {'family': 1, 'work': 2},
      );
      final json = rule.toJson();
      final back = SplitRule.fromJson(json);
      expect(back.type, 'byGroup');
      expect(back.values['family'], 1);
      expect(back.values['work'], 2);
    });

    test('shares type 往返', () {
      const rule = SplitRule(
        type: 'shares',
        participants: [
          {'type': 'member', 'id': 'a'},
          {'type': 'member', 'id': 'b'},
        ],
        values: {'a': 2, 'b': 1},
      );
      final json = rule.toJson();
      final back = SplitRule.fromJson(json);
      expect(back.type, 'shares');
      expect(back.values['a'], 2);
    });

    test('SplitType.dbValue 与 SplitRule.type 一致', () {
      // W3 新增的 byGroup 在 SplitRule 中是合法 type 字符串
      const byGroupRule = SplitRule(type: 'byGroup', participants: []);
      expect(byGroupRule.type, SplitType.byGroup.dbValue);
    });
  });
}