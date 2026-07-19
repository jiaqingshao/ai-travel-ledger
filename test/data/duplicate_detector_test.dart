import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 重复检测算法的单元测试。
///
/// **W2 单笔检测规则**（同一天 + 同金额 + 同类别 + 同支付人）4 个条件 **全满足** 才算重复。
/// 排除任一条件 → 不重复。
/// 软删除记录不参与匹配。
void main() {
  Expense makeExpense({
    String id = 'e1',
    String payerId = 'm1',
    double amount = 100.0,
    ExpenseCategory category = ExpenseCategory.food,
    DateTime? occurredAt,
    DateTime? deletedAt,
  }) {
    final t = occurredAt ?? DateTime(2026, 6, 1, 12);
    return Expense(
      id: id,
      tripId: 't1',
      payerId: payerId,
      amount: amount,
      category: category,
      occurredAt: t,
      createdAt: t,
      updatedAt: t,
      splitRuleJson: '',
      deletedAt: deletedAt,
    );
  }

  group('DuplicateDetector.isSameDay', () {
    test('同一天不同时间应判定相同', () {
      expect(
        DuplicateDetector.isSameDay(
          DateTime(2026, 6, 1, 9),
          DateTime(2026, 6, 1, 23, 59, 59),
        ),
        isTrue,
      );
    });

    test('跨天应判定不同', () {
      expect(
        DuplicateDetector.isSameDay(
          DateTime(2026, 6, 1, 23, 59),
          DateTime(2026, 6, 2, 0, 0, 1),
        ),
        isFalse,
      );
    });
  });

  group('DuplicateDetector.isDuplicate - 4 大匹配场景', () {
    test('场景 1：全匹配 → 重复', () {
      final a = makeExpense(occurredAt: DateTime(2026, 6, 1, 8));
      final b = makeExpense(
        id: 'b',
        occurredAt: DateTime(2026, 6, 1, 20),
      );
      expect(DuplicateDetector.isDuplicate(a, b), isTrue);
    });

    test('场景 2：金额不同 → 不重复', () {
      final a = makeExpense(amount: 100);
      final b = makeExpense(id: 'b', amount: 100.01);
      expect(DuplicateDetector.isDuplicate(a, b), isFalse);
    });

    test('场景 3：类别不同 → 不重复', () {
      final a = makeExpense(category: ExpenseCategory.food);
      final b = makeExpense(id: 'b', category: ExpenseCategory.transport);
      expect(DuplicateDetector.isDuplicate(a, b), isFalse);
    });

    test('场景 4：支付人不同 → 不重复', () {
      final a = makeExpense(payerId: 'm1');
      final b = makeExpense(id: 'b', payerId: 'm2');
      expect(DuplicateDetector.isDuplicate(a, b), isFalse);
    });

    test('场景 5：跨天（occurredAt 不同日）→ 不重复', () {
      final a = makeExpense(occurredAt: DateTime(2026, 6, 1, 23));
      final b = makeExpense(
        id: 'b',
        occurredAt: DateTime(2026, 6, 2, 0, 1),
      );
      expect(DuplicateDetector.isDuplicate(a, b), isFalse);
    });

    test('existing 被软删除 → 不重复', () {
      final a = makeExpense(deletedAt: DateTime(2026, 6, 2));
      final b = makeExpense(id: 'b');
      expect(DuplicateDetector.isDuplicate(a, b), isFalse);
    });

    test('candidate 被软删除 → 不重复', () {
      final a = makeExpense();
      final b = makeExpense(id: 'b', deletedAt: DateTime(2026, 6, 2));
      expect(DuplicateDetector.isDuplicate(a, b), isFalse);
    });
  });

  group('DuplicateDetector.findDuplicate', () {
    test('在 pool 中找到第一个匹配', () {
      final pool = [
        makeExpense(id: 'p1', occurredAt: DateTime(2026, 6, 5)),
        makeExpense(id: 'p2', occurredAt: DateTime(2026, 6, 1)),
        makeExpense(id: 'p3', occurredAt: DateTime(2026, 6, 3)),
      ];
      final candidate = makeExpense(
        occurredAt: DateTime(2026, 6, 1, 18),
      );
      final dup = DuplicateDetector.findDuplicate(pool, candidate);
      expect(dup?.id, 'p2');
    });

    test('excludeId 跳过自身', () {
      final pool = [
        makeExpense(id: 'me', occurredAt: DateTime(2026, 6, 1, 9)),
      ];
      final me = makeExpense(id: 'me', occurredAt: DateTime(2026, 6, 1, 20));
      expect(
          DuplicateDetector.findDuplicate(pool, me, excludeId: 'me'), isNull);
    });

    test('无任何匹配返回 null', () {
      final pool = [
        makeExpense(id: 'p1', amount: 50),
      ];
      final candidate = makeExpense(amount: 100);
      expect(DuplicateDetector.findDuplicate(pool, candidate), isNull);
    });
  });
}
