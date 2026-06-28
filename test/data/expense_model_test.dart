import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('ExpenseCategory', () {
    test('10 个内置类别 + displayName + icon 都不为空', () {
      expect(ExpenseCategory.values.length, 10);
      for (final c in ExpenseCategory.values) {
        expect(c.displayName, isNotEmpty);
        expect(c.icon, isNotEmpty);
      }
    });

    test('displayName 包含中文', () {
      // 抽样
      expect(ExpenseCategory.food.displayName, '餐饮');
      expect(ExpenseCategory.lodging.displayName, '住宿');
      expect(ExpenseCategory.transport.displayName, '交通');
    });
  });

  group('SplitRule', () {
    test('toJson / fromJson 双向', () {
      final rule = const SplitRule(
        type: 'equal',
        participants: [
          {'type': 'member', 'id': 'm1'},
          {'type': 'group', 'id': 'g1'},
        ],
        values: {'m1': 0.5, 'm2': 0.5},
      );
      final json = rule.toJson();
      final back = SplitRule.fromJson(json);
      expect(back.type, 'equal');
      expect(back.participants, hasLength(2));
      expect(back.values['m1'], 0.5);
    });

    test('SplitRule.equal 便利工厂生成 member 列表', () {
      final rule = SplitRule.equal(['m1', 'm2', 'm3']);
      expect(rule.type, 'equal');
      expect(rule.participants, hasLength(3));
      expect(rule.participants[0], isA<Map>());
      expect((rule.participants[0] as Map)['type'], 'member');
      expect((rule.participants[0] as Map)['id'], 'm1');
    });

    test('SplitRule.equalGroup 便利工厂生成 group', () {
      final rule = SplitRule.equalGroup('g1');
      expect(rule.type, 'equal');
      expect(rule.participants, hasLength(1));
      expect((rule.participants[0] as Map)['type'], 'group');
      expect((rule.participants[0] as Map)['id'], 'g1');
    });

    test('resolveParticipants 展开组', () {
      final rule = SplitRule(
        type: 'equal',
        participants: [
          {'type': 'group', 'id': 'family'},
          {'type': 'member', 'id': 'boss'},
        ],
      );
      final members = [
        makeMember(id: 'm1', groupId: 'family'),
        makeMember(id: 'm2', groupId: 'family'),
        makeMember(id: 'm3', groupId: 'work'),
        makeMember(id: 'boss'),
      ];
      final ids = rule.resolveParticipants(members);
      // 展开后：m1, m2, boss（按出现顺序）
      expect(ids, ['m1', 'm2', 'boss']);
    });

    test('Expense.splitRule getter 容错（损坏 JSON 返回空 rule）', () {
      final e = Expense(
        id: 'e1',
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        occurredAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
        splitRuleJson: 'not-valid-json',
      );
      // 不抛异常
      final rule = e.splitRule;
      expect(rule.type, 'equal'); // fallback
      expect(rule.participants, isEmpty);
    });

    test('Expense.splitRule setter 写入合法 JSON，getter 还原', () {
      final e = Expense(
        id: 'e1',
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        occurredAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
        splitRuleJson: '{}',
      );
      e.splitRule = SplitRule.equal(['a', 'b']);
      final restored = e.splitRule;
      expect(restored.participants, hasLength(2));
    });
  });
}
