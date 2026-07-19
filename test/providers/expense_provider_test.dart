import 'dart:async';
import 'dart:io';

import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/attachment.dart';
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/data/models/transfer_record.dart';
import 'package:ai_travel_ledger/data/models/trip.dart';
import 'package:ai_travel_ledger/presentation/providers/core_providers.dart';
import 'package:ai_travel_ledger/presentation/providers/expense_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;
  late Box<Trip> tripsBox;
  late Box<Member> membersBox;
  late Box<TripGroup> groupsBox;
  late Box<Expense> expensesBox;
  late Box<TransferRecord> transferRecordsBox;
  late Box<dynamic> appSettingsBox;
  late Box<Attachment> attachmentsBox;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_expense_provider_');
    Hive.init(tmpDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TripStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MemberAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TripGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(GroupTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ExpenseCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(MemberRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(TransferRecordAdapter());
    }
  });

  setUp(() async {
    final ts = DateTime.now().microsecondsSinceEpoch;
    tripsBox = await Hive.openBox<Trip>('trips_$ts');
    membersBox = await Hive.openBox<Member>('members_$ts');
    groupsBox = await Hive.openBox<TripGroup>('groups_$ts');
    expensesBox = await Hive.openBox<Expense>('expenses_$ts');
    transferRecordsBox =
        await Hive.openBox<TransferRecord>('transfer_records_$ts');
    appSettingsBox = await Hive.openBox<dynamic>('app_settings_$ts');
    attachmentsBox = await Hive.openBox<Attachment>('attachments_$ts');
  });

  tearDown(() async {
    await tripsBox.close();
    await membersBox.close();
    await groupsBox.close();
    await expensesBox.close();
    await transferRecordsBox.close();
    await appSettingsBox.close();
    await attachmentsBox.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tmpDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(
          HiveBoxes(
            trips: tripsBox,
            members: membersBox,
            groups: groupsBox,
            expenses: expensesBox,
            transferRecords: transferRecordsBox,
            appSettings: appSettingsBox,
            attachments: attachmentsBox,
          ),
        ),
      ],
    );
  }

  group('expenseRepositoryProvider', () {
    test('返回有效仓库', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final repo = c.read(expenseRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.listByTrip('t1'), isEmpty);
    });
  });

  group('ExpenseNotifier', () {
    test('create 写入 box 并返回 expense', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);

      final result = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 88.0,
        category: ExpenseCategory.food,
        splitRuleJson: '{"type":"equal","participants":[]}',
      );
      expect(result.expense.amount, 88.0);
      expect(expensesBox.get(result.expense.id), isNotNull);
      // 单条新费用没有重复
      expect(result.duplicate, isNull);
    });

    test('create 触发 duplicate 检测（第二条相同 → 返回 duplicate）', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);

      final r1 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 50.0,
        category: ExpenseCategory.transport,
        splitRuleJson: '{}',
        occurredAt: DateTime(2026, 6, 1, 8),
      );
      expect(r1.duplicate, isNull);

      final r2 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 50.0,
        category: ExpenseCategory.transport,
        splitRuleJson: '{}',
        occurredAt: DateTime(2026, 6, 1, 20),
      );
      expect(r2.duplicate, isNotNull);
      expect(r2.duplicate!.id, r1.expense.id);
    });

    test('precheckDuplicate 在保存前检测', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);

      await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 50.0,
        category: ExpenseCategory.food,
        splitRuleJson: '{}',
        occurredAt: DateTime(2026, 6, 1, 12),
      );
      // 未写入前的预检
      final dup = c.read(expenseNotifierProvider.notifier).precheckDuplicate(
            tripId: 't1',
            payerId: 'm1',
            amount: 50.0,
            category: ExpenseCategory.food,
            occurredAt: DateTime(2026, 6, 1, 18),
          );
      expect(dup, isNotNull);
    });

    test('update 修改字段', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);
      final r1 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '{}',
      );
      final updated = await notifier.update(
        r1.expense.id,
        amount: 200,
        category: ExpenseCategory.lodging,
        description: '酒店',
      );
      expect(updated.amount, 200);
      expect(updated.category, ExpenseCategory.lodging);
      expect(updated.description, '酒店');
    });

    test('delete 软删除 + restore 恢复', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);
      final r1 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '{}',
      );
      await notifier.delete(r1.expense.id);
      expect(c.read(expenseRepositoryProvider).listByTrip('t1'), isEmpty);

      await notifier.restore(r1.expense.id);
      expect(c.read(expenseRepositoryProvider).listByTrip('t1'), hasLength(1));
    });
  });

  group('expensesByTripProvider (Stream)', () {
    test('首次 yield 当前 list，新写入后再次 yield', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);
      final repo = c.read(expenseRepositoryProvider);

      // 写入 1 条
      await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '{}',
      );

      // 订阅 stream
      final emitted = <List<Expense>>[];
      final completer = Completer<void>();
      final sub = c.listen<AsyncValue<List<Expense>>>(
        expensesByTripProvider('t1'),
        (prev, next) {
          if (next is AsyncData<List<Expense>>) {
            emitted.add(next.value);
            if (emitted.length == 2) completer.complete();
          }
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // 等首次 yield 完成
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(emitted, isNotEmpty);
      expect(emitted.first, hasLength(1));

      // 再写 1 条，应触发新 yield
      await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 20,
        category: ExpenseCategory.transport,
        splitRuleJson: '{}',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, greaterThanOrEqualTo(2));
      expect(emitted.last, hasLength(2));

      // 验证与 repo 一致
      expect(repo.listByTrip('t1'), hasLength(2));
    });
  });

  group('totalByTripProvider / expenseByIdProvider', () {
    test('totalByTripProvider 实时计算总金额', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);

      // 订阅 stream（首次 yield 必是 0.0）
      final stream = c.read(totalByTripProvider('t1').future);
      // 等待首次 yield
      expect(await stream.timeout(const Duration(seconds: 1)), 0.0);

      await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '{}',
      );
      // 重新订阅 → 拿到新 yield
      final next = await c
          .read(totalByTripProvider('t1').future)
          .timeout(const Duration(seconds: 1));
      expect(next, 10.0);
    });

    test('expenseByIdProvider 读取单条', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);
      final r1 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '{}',
      );
      // ISSUE-042 v2: expenseByIdProvider 恢复 Provider.family 同步读 Hive
      // ref.read 拿 Expense? 直接
      final fetched = c.read<Expense?>(expenseByIdProvider(r1.expense.id));
      expect(fetched, isNotNull);
      expect(fetched!.amount, 10.0);
    });

    // ISSUE-042 回归测试: invalidate 后 expenseByIdProvider 立刻反映新值
    // (Provider.family 不响应 box 写入, 必须靠调用方 invalidate)
    test('ISSUE-042: invalidate 后 expenseByIdProvider 立刻返回新值', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);

      final r1 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 10,
        category: ExpenseCategory.food,
        splitRuleJson: '{"type":"equal"}',
      );

      Expense? fetched = c.read<Expense?>(expenseByIdProvider(r1.expense.id));
      expect(fetched!.amount, 10.0);

      // 1. update 改 amount
      await notifier.update(r1.expense.id, amount: 99.5);

      // 2. 关键: 不 invalidate 直接读, 应该拿到旧值 (Provider.family 行为)
      fetched = c.read<Expense?>(expenseByIdProvider(r1.expense.id));
      expect(fetched!.amount, 10.0, reason: '未 invalidate 应该是旧值 (预期)');

      // 3. invalidate 后再读, 拿到新值
      c.invalidate(expenseByIdProvider(r1.expense.id));
      fetched = c.read<Expense?>(expenseByIdProvider(r1.expense.id));
      expect(fetched!.amount, 99.5, reason: 'ISSUE-042: invalidate 后应立即看到新值');
    });

    // ISSUE-042: 完整流程 - create → invalidate → 读
    test('ISSUE-042: create + invalidate 后立刻看到', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(expenseNotifierProvider.notifier);

      final r1 = await notifier.create(
        tripId: 't1',
        payerId: 'm1',
        amount: 100,
        category: ExpenseCategory.food,
        splitRuleJson: '{"type":"equal"}',
      );

      // create 后 Provider 不知道, invalidate 后才能看到
      c.invalidate(expenseByIdProvider(r1.expense.id));
      Expense? fetched = c.read<Expense?>(expenseByIdProvider(r1.expense.id));
      expect(fetched, isNotNull);
      expect(fetched!.amount, 100.0);

      // update category
      await notifier.update(r1.expense.id, category: ExpenseCategory.transport);
      c.invalidate(expenseByIdProvider(r1.expense.id));
      fetched = c.read<Expense?>(expenseByIdProvider(r1.expense.id));
      expect(fetched!.category, ExpenseCategory.transport,
          reason: 'ISSUE-042: 改 category 后 invalidate 应立即看到新值');
    });
  });
}
