import 'dart:io';

import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/repositories/expense_repository.dart';
import 'package:ai_travel_ledger/data/repositories/trip_repository.dart'
    show RemoteSyncOp;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;
  late Box<Expense> box;
  late ExpenseRepository repo;
  int syncCalls = 0;
  Expense? lastSyncedExpense;
  RemoteSyncOp? lastOp;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_expense_test_');
    Hive.init(tmpDir.path);
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ExpenseCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<Expense>(
      'expenses_${DateTime.now().microsecondsSinceEpoch}',
    );
    syncCalls = 0;
    lastSyncedExpense = null;
    lastOp = null;
    repo = ExpenseRepository(
      box: box,
      remoteSync: (e, op) async {
        syncCalls++;
        lastSyncedExpense = e;
        lastOp = op;
      },
    );
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tmpDir.delete(recursive: true);
  });

  // 共享的 splitRuleJson 工厂
  String _splitJson(List<String> ids) => '{"type":"equal","participants":[]}';

  group('ExpenseRepository.create', () {
    test('创建费用并持久化', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 100.0,
        category: ExpenseCategory.food,
        splitRuleJson: _splitJson(['m1']),
        occurredAt: DateTime(2026, 6, 1, 12, 0),
      );
      expect(e.id, isNotEmpty);
      expect(e.tripId, 't1');
      expect(e.amount, 100.0);
      expect(e.category, ExpenseCategory.food);
      expect(e.deletedAt, isNull);
      expect(e.syncStatus, SyncStatus.synced);
      expect(box.get(e.id), isNotNull);
    });

    test('创建后触发远程 upsert', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 50.0,
        category: ExpenseCategory.transport,
        splitRuleJson: _splitJson(['m1']),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.upsert);
      expect(lastSyncedExpense?.amount, 50.0);
    });

    test('默认币种 CNY, 默认 attachments 为空', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10.0,
        category: ExpenseCategory.other,
        splitRuleJson: '',
      );
      expect(e.currency, 'CNY');
      expect(e.attachments, isEmpty);
    });
  });

  group('ExpenseRepository.read', () {
    setUp(() async {
      // 注入若干测试数据
      box = await Hive.openBox<Expense>(
        'expenses_${DateTime.now().microsecondsSinceEpoch}_r',
      );
      syncCalls = 0;
      repo = ExpenseRepository(box: box);
    });

    test('listByTrip 仅返回指定 trip，且排除软删除', () async {
      final t1a = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 1),
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 20,
        category: ExpenseCategory.transport,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 2),
      );
      await repo.create(
        tripId: 't2',
        payerId: 'm1',
        amount: 30,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      // 软删一条 t1
      await repo.delete(t1a.id);

      final t1List = repo.listByTrip('t1');
      expect(t1List, hasLength(1));
      expect(t1List.first.amount, 20);
      // 显式 includeDeleted
      expect(repo.listByTrip('t1', includeDeleted: true), hasLength(2));
      // 另一个 trip
      expect(repo.listByTrip('t2'), hasLength(1));
    });

    test('listByTrip 按 occurredAt 倒序', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 1,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 1),
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 2,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 3),
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 3,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 2),
      );
      final list = repo.listByTrip('t1');
      expect(list.map((e) => e.amount).toList(), [2, 3, 1]);
    });

    test('listByCategory + listByDateRange', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 1),
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 20,
        category: ExpenseCategory.transport,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 5),
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 30,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 10),
      );
      expect(repo.listByCategory('t1', ExpenseCategory.food), hasLength(2));
      expect(repo.listByDateRange(
        't1',
        from: DateTime(2026, 6, 2),
        to: DateTime(2026, 6, 8),
      ), hasLength(1));
    });

    test('totalByTrip / totalByCategory', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 20,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 30,
        category: ExpenseCategory.transport,
        splitRuleJson: '',
      );
      await repo.create(
        tripId: 't2',
        payerId: 'm1',
        amount: 999,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );

      expect(repo.totalByTrip('t1'), 60);
      expect(repo.totalByTrip('t2'), 999);
      final byCat = repo.totalByCategory('t1');
      expect(byCat[ExpenseCategory.food], 30);
      expect(byCat[ExpenseCategory.transport], 30);
    });

    test('lastByPayer 返回该付款人最近一笔', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 1),
      );
      final newer = await repo.create(
        tripId: 't1',
        payerId: 'm2',
        amount: 50,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 5),
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 20,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 3),
      );
      expect(repo.lastByPayer('t1', 'm1')?.amount, 20);
      expect(repo.lastByPayer('t1', 'm2')?.id, newer.id);
      expect(repo.lastByPayer('t1', 'm3'), isNull);
    });
  });

  group('ExpenseRepository.update', () {
    test('更新字段并触发远程 upsert', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      syncCalls = 0;
      final updated = await repo.update(
        e.id,
        amount: 99.0,
        category: ExpenseCategory.lodging,
        description: '酒店',
      );
      expect(updated.amount, 99.0);
      expect(updated.category, ExpenseCategory.lodging);
      expect(updated.description, '酒店');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
    });

    test('更新不存在的 id 抛 StateError', () async {
      expect(
        () => repo.update('missing', amount: 1.0),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ExpenseRepository.soft delete + restore', () {
    test('delete 设置 deletedAt，不物理删除，触发远程 delete', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      syncCalls = 0;
      final deleted = await repo.delete(e.id);
      expect(deleted.deletedAt, isNotNull);
      // 物理上还在 box 里
      expect(box.get(e.id), isNotNull);
      // 默认查询过滤掉
      expect(repo.listByTrip('t1'), isEmpty);
      // 远程同步
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.delete);
    });

    test('二次 delete 幂等（不重复触发远程）', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      await repo.delete(e.id);
      syncCalls = 0;
      await repo.delete(e.id);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 0);
    });

    test('restore 清除 deletedAt，再次出现在列表中', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      await repo.delete(e.id);
      expect(repo.listByTrip('t1'), isEmpty);
      final restored = await repo.restore(e.id);
      expect(restored.deletedAt, isNull);
      expect(repo.listByTrip('t1'), hasLength(1));
    });

    test('deleteAllByTrip 级联物理删除某 trip 下所有费用', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 20,
        category: ExpenseCategory.transport,
        splitRuleJson: '',
      );
      await repo.create(
        tripId: 't2',
        payerId: 'm1',
        amount: 999,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      await repo.deleteAllByTrip('t1');
      expect(repo.listByTrip('t1', includeDeleted: true), isEmpty);
      expect(repo.listByTrip('t2'), hasLength(1));
    });
  });

  group('ExpenseRepository.findDuplicate', () {
    test('完全匹配（同一天+同金额+同类别+同付款人）应命中', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 100.0,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 1, 9, 0),
      );
      final candidate = Expense(
        id: 'cand',
        tripId: 't1',
        payerId: 'm1',
        amount: 100.0,
        category: ExpenseCategory.food,
        occurredAt: DateTime(2026, 6, 1, 18, 30),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
        splitRuleJson: '',
      );
      final dup = repo.findDuplicate('t1', candidate);
      expect(dup, isNotNull);
      expect(dup!.id, e.id);
    });

    test('不同 trip 不命中（pool 范围隔离）', () async {
      await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 100.0,
        category: ExpenseCategory.food,
        splitRuleJson: '',
        occurredAt: DateTime(2026, 6, 1),
      );
      final candidate = Expense(
        id: 'cand',
        tripId: 't2',
        payerId: 'm1',
        amount: 100.0,
        category: ExpenseCategory.food,
        occurredAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
        splitRuleJson: '',
      );
      expect(repo.findDuplicate('t2', candidate), isNull);
    });

    test('excludeId 用于编辑时排除自身', () async {
      final e = await repo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 100.0,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      // 用自身做 candidate + excludeId 自身
      final dup = repo.findDuplicate('t1', e, excludeId: e.id);
      expect(dup, isNull);
    });
  });

  group('ExpenseRepository - 纯本地模式', () {
    test('无 remoteSync 时不报错', () async {
      final localRepo = ExpenseRepository(box: box);
      final e = await localRepo.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '',
      );
      expect(box.get(e.id), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 0);
    });
  });
}
