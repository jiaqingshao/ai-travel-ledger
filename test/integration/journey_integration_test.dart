// 联合测试 - 跨层集成 (Domain + Data)
//
// 覆盖场景:
// 1. 完整旅程流程: 创建 → 添加成员 → 记账 → 结算
// 2. 多分摊规则混合 (比例 + 份数) + 最优转账
// 3. 软删除 (deletedAt)
// 4. 归档 vs 活跃
// 5. 分组功能 (家庭 + 公司混合)
// 6. 边界场景 (空 trip, 零结算, 大额精度)

import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/data/models/transfer_record.dart';
import 'package:ai_travel_ledger/data/models/trip.dart';
import 'package:ai_travel_ledger/domain/services/settlement_engine.dart';
import 'package:ai_travel_ledger/domain/services/split_calculator.dart';
import 'package:ai_travel_ledger/presentation/providers/core_providers.dart';

void main() {
  late Directory tempDir;
  late Box<Trip> tripsBox;
  late Box<Member> membersBox;
  late Box<TripGroup> groupsBox;
  late Box<Expense> expensesBox;
  late Box<TransferRecord> transferBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('integration_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TripStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TripAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MemberAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TripGroupAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(GroupTypeAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(ExpenseCategoryAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(SyncStatusAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(MemberRoleAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(TransferRecordAdapter());
  });

  setUp(() async {
    final ts = DateTime.now().microsecondsSinceEpoch;
    tripsBox = await Hive.openBox<Trip>('trips_$ts');
    membersBox = await Hive.openBox<Member>('members_$ts');
    groupsBox = await Hive.openBox<TripGroup>('groups_$ts');
    expensesBox = await Hive.openBox<Expense>('expenses_$ts');
    transferBox = await Hive.openBox<TransferRecord>('transfers_$ts');
  });

  tearDown(() async {
    await tripsBox.close();
    await membersBox.close();
    await groupsBox.close();
    await expensesBox.close();
    await transferBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ===== 辅助函数 =====

  Future<({Trip trip, List<Member> members})> setupFamilyTrip() async {
    final trip = Trip(
      id: 'trip-family-001',
      name: '家庭周末游',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 3),
      destination: '杭州',
      baseCurrency: 'CNY',
      status: TripStatus.ended,
      createdBy: 'user-father',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 3),
    );
    await tripsBox.put(trip.id, trip);

    final members = [
      Member(id: 'm-father', tripId: trip.id, nickname: '爸爸',
          role: MemberRole.organizer, joinedAt: DateTime(2026, 5, 1)),
      Member(id: 'm-mother', tripId: trip.id, nickname: '妈妈',
          joinedAt: DateTime(2026, 5, 1)),
      Member(id: 'm-child', tripId: trip.id, nickname: '孩子',
          joinedAt: DateTime(2026, 5, 1)),
    ];
    for (final m in members) {
      await membersBox.put(m.id, m);
    }
    return (trip: trip, members: members);
  }

  /// 使用真实 SplitRule factory + JSON 编码
  Future<void> addExpense({
    required String tripId,
    required String payerId,
    required double amount,
    required ExpenseCategory category,
    required String description,
    required SplitRule rule,
  }) async {
    final e = Expense(
      id: 'exp-${DateTime.now().microsecondsSinceEpoch}-${amount.toInt()}',
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      currency: 'CNY',
      category: category,
      description: description,
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      splitRuleJson: jsonEncode(rule.toJson()),
      syncStatus: SyncStatus.synced,
    );
    await expensesBox.put(e.id, e);
  }

  Map<String, double> calcBalances() {
    return SettlementEngine.calculateNetBalancesFromExpenses(
      expenses: expensesBox.values.toList(),
      members: membersBox.values.toList(),
      groups: groupsBox.values.toList(),
    );
  }

  // ===== 测试用例 =====

  group('集成 1: 完整旅程流程', () {
    test('创建 trip → 3 成员 → 4 笔费用(混合规则) → 结算正确', () async {
      final setup = await setupFamilyTrip();
      expect(tripsBox.length, 1);
      expect(membersBox.length, 3);

      // 酒店 900 均摊
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 900.0,
          category: ExpenseCategory.lodging, description: '酒店',
          rule: SplitRule.equal(['m-father', 'm-mother', 'm-child']));
      // 餐饮 450 均摊
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-mother', amount: 450.0,
          category: ExpenseCategory.food, description: '餐饮',
          rule: SplitRule.equal(['m-father', 'm-mother', 'm-child']));
      // 油费 600 仅爸爸妈妈
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 600.0,
          category: ExpenseCategory.fuel, description: '油费',
          rule: SplitRule.equal(['m-father', 'm-mother']));
      // 零花 120 仅孩子
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-child', amount: 120.0,
          category: ExpenseCategory.food, description: '零花',
          rule: SplitRule.equal(['m-child']));

      expect(expensesBox.length, 4);

      final balances = calcBalances();

      // 酒店 900/3 = 300, 餐饮 450/3 = 150
      // 油费 600/2 = 300 (仅爸妈), 零花 120 仅孩子
      // 爸: 付 1500, 摊 300+150+300 = 750 → +750
      // 妈: 付 450, 摊 300+150+300 = 750 → -300
      // 娃: 付 120, 摊 300+150+120 = 570 → -450
      expect(balances['m-father'], closeTo(750, 0.01));
      expect(balances['m-mother'], closeTo(-300, 0.01));
      expect(balances['m-child'], closeTo(-450, 0.01));

      final transfers = SettlementEngine.minimizeTransfers(balances);
      expect(transfers.length, 2);
      expect(transfers.every((t) => t.amount > 0), true);

      final sum = balances.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(0, 0.01), reason: '收支必须平衡');
    });
  });

  group('集成 2: 多分摊规则混合', () {
    test('5 人 / 比例 1:1:1:2:2 + 份数 1:1:1:1:1', () async {
      final trip = Trip(
        id: 'trip-team-001', name: '部门团建',
        startDate: DateTime(2026, 6, 1), endDate: DateTime(2026, 6, 2),
        status: TripStatus.ended, createdBy: 'u-lead',
        createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 2),
      );
      await tripsBox.put(trip.id, trip);

      final members = ['u1', 'u2', 'u3', 'u4', 'u5']
          .map((id) => Member(
                id: id, tripId: trip.id, nickname: id,
                joinedAt: DateTime(2026, 6, 1),
              ))
          .toList();
      for (final m in members) {
        await membersBox.put(m.id, m);
      }

      // 餐费 1000 比例 1:1:1:2:2
      final rule1 = SplitRule(
        type: 'ratio',
        participants: const [
          {'type': 'member', 'id': 'u1'},
          {'type': 'member', 'id': 'u2'},
          {'type': 'member', 'id': 'u3'},
          {'type': 'member', 'id': 'u4'},
          {'type': 'member', 'id': 'u5'},
        ],
        values: const {'u1': 1.0, 'u2': 1.0, 'u3': 1.0, 'u4': 2.0, 'u5': 2.0},
      );
      await addExpense(
          tripId: trip.id, payerId: 'u1', amount: 1000.0,
          category: ExpenseCategory.food, description: '团建餐',
          rule: rule1);

      // 住宿 800 份数均摊 (1:1:1:1:1)
      final rule2 = SplitRule(
        type: 'shares',
        participants: const [
          {'type': 'member', 'id': 'u1'},
          {'type': 'member', 'id': 'u2'},
          {'type': 'member', 'id': 'u3'},
          {'type': 'member', 'id': 'u4'},
          {'type': 'member', 'id': 'u5'},
        ],
        values: const {'u1': 1.0, 'u2': 1.0, 'u3': 1.0, 'u4': 1.0, 'u5': 1.0},
      );
      await addExpense(
          tripId: trip.id, payerId: 'u2', amount: 800.0,
          category: ExpenseCategory.lodging, description: '酒店',
          rule: rule2);

      final balances = calcBalances();

      // u1 付 1000, 摊 142.86+160 = 302.86 → +697.14
      // u2 付 800, 摊 302.86 → +497.14
      // u3-u5 摊 302.86 / 445.71 / 445.71 → 负数
      expect(balances['u1'], closeTo(697.14, 0.5));
      expect(balances['u2'], closeTo(497.14, 0.5));
      expect(balances['u3'], closeTo(-302.86, 0.5));
      expect(balances['u4'], closeTo(-445.71, 0.5));
      expect(balances['u5'], closeTo(-445.71, 0.5));

      final transfers = SettlementEngine.minimizeTransfers(balances);
      expect(transfers.length, lessThanOrEqualTo(4));
      expect(transfers.every((t) => t.amount > 0), true);

      final sum = balances.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(0, 0.01));
    });
  });

  group('集成 3: 软删除', () {
    test('deletedAt 标记的 expense 不参与结算', () async {
      final setup = await setupFamilyTrip();
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 300.0,
          category: ExpenseCategory.food, description: '午餐',
          rule: SplitRule.equal(['m-father', 'm-mother', 'm-child']));
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 500.0,
          category: ExpenseCategory.transport, description: '高铁',
          rule: SplitRule.equal(['m-father', 'm-mother']));

      expect(expensesBox.length, 2);

      // 标记午餐为删除
      final lunch = expensesBox.values.firstWhere((e) => e.amount == 300.0);
      lunch.deletedAt = DateTime.now();
      await lunch.save();

      expect(expensesBox.length, 2);

      final balances = calcBalances();

      // 只剩 500 元, 爸爸妈妈均摊
      // 爸付 500, 摊 250 → +250
      // 妈付 0, 摊 250 → -250
      expect(balances['m-father'], closeTo(250, 0.01));
      expect(balances['m-mother'], closeTo(-250, 0.01));
      expect(balances['m-child'] ?? 0.0, 0.0);
    });
  });

  group('集成 4: 归档 vs 活跃', () {
    test('archived trip 不在活跃列表', () async {
      await tripsBox.put('t1',
          Trip(id: 't1', name: '活跃', startDate: DateTime(2026, 5, 1),
              status: TripStatus.ongoing, createdBy: 'u1',
              createdAt: DateTime(2026, 5, 1), updatedAt: DateTime(2026, 5, 1)));
      await tripsBox.put('t2',
          Trip(id: 't2', name: '归档', startDate: DateTime(2026, 4, 1),
              status: TripStatus.archived, createdBy: 'u1',
              createdAt: DateTime(2026, 4, 1), updatedAt: DateTime(2026, 4, 30)));

      final active = tripsBox.values
          .where((t) => t.status == TripStatus.preparing ||
              t.status == TripStatus.ongoing ||
              t.status == TripStatus.ended)
          .toList();
      expect(active.length, 1);
      expect(active.first.id, 't1');

      final archived = tripsBox.values
          .where((t) => t.status == TripStatus.archived)
          .toList();
      expect(archived.length, 1);
      expect(archived.first.id, 't2');
    });
  });

  group('集成 5: 分组功能', () {
    test('家庭 + 公司混合分组,按组结算', () async {
      final trip = Trip(
        id: 'trip-mixed', name: '混合分组游',
        startDate: DateTime(2026, 7, 1), status: TripStatus.ended,
        createdBy: 'u1', createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 2),
      );
      await tripsBox.put(trip.id, trip);

      await groupsBox.put('g-family', TripGroup(
        id: 'g-family', tripId: trip.id,
        name: '家庭组', groupType: GroupType.family,
        createdAt: DateTime(2026, 7, 1),
      ));
      await groupsBox.put('g-company', TripGroup(
        id: 'g-company', tripId: trip.id,
        name: '公司组', groupType: GroupType.company,
        createdAt: DateTime(2026, 7, 1),
      ));

      final members = [
        Member(id: 'f1', tripId: trip.id, nickname: '爸',
            groupId: 'g-family', joinedAt: DateTime(2026, 7, 1)),
        Member(id: 'f2', tripId: trip.id, nickname: '妈',
            groupId: 'g-family', joinedAt: DateTime(2026, 7, 1)),
        Member(id: 'f3', tripId: trip.id, nickname: '娃',
            groupId: 'g-family', joinedAt: DateTime(2026, 7, 1)),
        Member(id: 'c1', tripId: trip.id, nickname: '同事A',
            groupId: 'g-company', joinedAt: DateTime(2026, 7, 1)),
        Member(id: 'c2', tripId: trip.id, nickname: '同事B',
            groupId: 'g-company', joinedAt: DateTime(2026, 7, 1)),
        Member(id: 'c3', tripId: trip.id, nickname: '同事C',
            groupId: 'g-company', joinedAt: DateTime(2026, 7, 1)),
      ];
      for (final m in members) {
        await membersBox.put(m.id, m);
      }

      // 家庭餐 600 家庭组均摊
      await addExpense(
          tripId: trip.id, payerId: 'f1', amount: 600.0,
          category: ExpenseCategory.food, description: '家庭餐',
          rule: SplitRule.equalGroup('g-family'));

      // 团建 900 公司组均摊
      await addExpense(
          tripId: trip.id, payerId: 'c1', amount: 900.0,
          category: ExpenseCategory.entertainment, description: '团建',
          rule: SplitRule.equalGroup('g-company'));

      final balances = calcBalances();

      // 家庭餐 600/3 = 200 每人
      // f1 付 600, 摊 200 → +400
      // f2 摊 200 → -200
      // f3 摊 200 → -200
      // 团建 900/3 = 300 每人
      // c1 付 900, 摊 300 → +600
      // c2 摊 300 → -300
      // c3 摊 300 → -300
      expect(balances['f1'], closeTo(400, 0.01));
      expect(balances['f2'], closeTo(-200, 0.01));
      expect(balances['f3'], closeTo(-200, 0.01));
      expect(balances['c1'], closeTo(600, 0.01));
      expect(balances['c2'], closeTo(-300, 0.01));
      expect(balances['c3'], closeTo(-300, 0.01));

      final sum = balances.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(0, 0.01));
    });
  });

  group('集成 6: 边界场景', () {
    test('空 trip 结算 = 空结果', () {
      final balances = SettlementEngine.calculateNetBalancesFromExpenses(
        expenses: [], members: [], groups: [],
      );
      expect(balances, isEmpty);

      final transfers = SettlementEngine.minimizeTransfers(balances);
      expect(transfers, isEmpty);
    });

    test('所有人付自己的费用 (零结算)', () async {
      final setup = await setupFamilyTrip();
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 300.0,
          category: ExpenseCategory.food, description: '爸的饭',
          rule: SplitRule.equal(['m-father']));
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-mother', amount: 200.0,
          category: ExpenseCategory.food, description: '妈的饭',
          rule: SplitRule.equal(['m-mother']));
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-child', amount: 100.0,
          category: ExpenseCategory.food, description: '娃的饭',
          rule: SplitRule.equal(['m-child']));

      final balances = calcBalances();
      // 每人付自己的, 各人净 = 0
      expect(balances['m-father'] ?? 0.0, closeTo(0, 0.01));
      expect(balances['m-mother'] ?? 0.0, closeTo(0, 0.01));
      expect(balances['m-child'] ?? 0.0, closeTo(0, 0.01));

      final transfers = SettlementEngine.minimizeTransfers(balances);
      expect(transfers, isEmpty, reason: '收支平衡不需要转账');
    });

    test('大额精度测试 (10000/3 = 3333.33...)', () async {
      final setup = await setupFamilyTrip();
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 10000.0,
          category: ExpenseCategory.lodging, description: '豪华酒店',
          rule: SplitRule.equal(['m-father', 'm-mother', 'm-child']));

      final balances = calcBalances();

      // 10000/3 = 3333.33...
      expect(balances['m-father'], closeTo(6666.67, 0.02));
      expect(balances['m-mother'], closeTo(-3333.33, 0.02));
      expect(balances['m-child'], closeTo(-3333.33, 0.02));

      final sum = balances.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(0, 0.02));
    });

    test('单笔 0 元费用 (不抛异常)', () async {
      final setup = await setupFamilyTrip();
      await addExpense(
          tripId: setup.trip.id, payerId: 'm-father', amount: 0.0,
          category: ExpenseCategory.other, description: '免费',
          rule: SplitRule.equal(['m-father', 'm-mother', 'm-child']));

      final balances = calcBalances();
      expect(balances['m-father'] ?? 0.0, 0.0);
      expect(balances['m-mother'] ?? 0.0, 0.0);
      expect(balances['m-child'] ?? 0.0, 0.0);
    });
  });
}