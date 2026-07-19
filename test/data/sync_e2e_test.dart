// 端到端验证：模拟"本地写入 → 标记 pending → 同步 → 标记 synced"完整流程
// 不需要真实 Supabase，使用 mock client

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/attachment.dart';
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/data/models/transfer_record.dart';
import 'package:ai_travel_ledger/data/models/trip.dart';
import 'package:ai_travel_ledger/data/sync/sync_engine.dart';
import 'package:ai_travel_ledger/presentation/providers/core_providers.dart';

import 'helpers/mock_supabase_service.dart';

void main() {
  late Directory tempDir;
  late Box<Trip> tripsBox;
  late Box<Member> membersBox;
  late Box<TripGroup> groupsBox;
  late Box<Expense> expensesBox;
  late Box<TransferRecord> transferBox;
  late Box<dynamic> appSettingsBox;
  late Box<Attachment> attachmentsBox;
  late HiveBoxes boxes;
  late MockSupabaseService mock;
  late SyncEngine engine;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_e2e_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TripStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TripAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MemberAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TripGroupAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(GroupTypeAdapter());
    if (!Hive.isAdapterRegistered(11))
      Hive.registerAdapter(ExpenseCategoryAdapter());
    if (!Hive.isAdapterRegistered(12))
      Hive.registerAdapter(SyncStatusAdapter());
    if (!Hive.isAdapterRegistered(13))
      Hive.registerAdapter(MemberRoleAdapter());
    if (!Hive.isAdapterRegistered(14))
      Hive.registerAdapter(TransferRecordAdapter());
  });

  setUp(() async {
    tripsBox = await Hive.openBox<Trip>(
        'trips_${DateTime.now().microsecondsSinceEpoch}');
    membersBox = await Hive.openBox<Member>(
        'members_${DateTime.now().microsecondsSinceEpoch}');
    groupsBox = await Hive.openBox<TripGroup>(
        'groups_${DateTime.now().microsecondsSinceEpoch}');
    expensesBox = await Hive.openBox<Expense>(
        'expenses_${DateTime.now().microsecondsSinceEpoch}');
    transferBox = await Hive.openBox<TransferRecord>(
        'transfers_${DateTime.now().microsecondsSinceEpoch}');
    appSettingsBox = await Hive.openBox<dynamic>(
        'app_settings_${DateTime.now().microsecondsSinceEpoch}');
    attachmentsBox = await Hive.openBox<Attachment>(
        'attachments_${DateTime.now().microsecondsSinceEpoch}');
    boxes = HiveBoxes(
      trips: tripsBox,
      members: membersBox,
      groups: groupsBox,
      expenses: expensesBox,
      transferRecords: transferBox,
      appSettings: appSettingsBox,
      attachments: attachmentsBox,
    );
    mock = MockSupabaseService();
    mock.signInMock('test@example.com', 'password123');
    engine = SyncEngine(boxes: boxes, supabase: mock);
  });

  tearDown(() async {
    await engine.dispose();
    await tripsBox.close();
    await membersBox.close();
    await groupsBox.close();
    await expensesBox.close();
    await transferBox.close();
    await appSettingsBox.close();
    await attachmentsBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('E2E 1: 完整同步流程 - 创建 → pending → 同步 → synced', () async {
    // 1. 创建本地数据（trip + member + expense）
    final trip = Trip(
      id: 'trip-001',
      name: '京都赏樱',
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 7),
      destination: '日本京都',
      baseCurrency: 'JPY',
      status: TripStatus.ongoing,
      createdBy: 'user-test-001',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tripsBox.put(trip.id, trip);

    final member = Member(
      id: 'm-001',
      tripId: 'trip-001',
      nickname: '张三',
      role: MemberRole.organizer,
      joinedAt: DateTime.now(),
    );
    await membersBox.put(member.id, member);

    final expense = Expense(
      id: 'exp-001',
      tripId: 'trip-001',
      payerId: 'm-001',
      amount: 5000.0,
      currency: 'JPY',
      category: ExpenseCategory.food,
      description: '午餐',
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      splitRuleJson: '{"type":"equal","participants":[]}',
      syncStatus: SyncStatus.pending,
    );
    await expensesBox.put(expense.id, expense);

    // 2. 验证本地状态
    expect(tripsBox.length, 1);
    expect(membersBox.length, 1);
    expect(expensesBox.length, 1);
    expect(expensesBox.get('exp-001')!.syncStatus, SyncStatus.pending);

    // 3. 触发同步
    final result = await engine.syncOnce();

    // 4. 验证同步结果
    expect(result.skipped, false, reason: '应执行同步（已登录+已初始化）');
    expect(result.pushed, greaterThan(0), reason: '应推送本地数据');
    expect(mock.upsertedTrips.length, 1);
    expect(mock.upsertedMembers.length, 1);
    expect(mock.upsertedExpenses.length, 1);

    // 5. 验证 expense 状态变为 synced
    final synced = expensesBox.get('exp-001');
    expect(synced, isNotNull);
    expect(synced!.syncStatus, SyncStatus.synced, reason: '成功后应为 synced');
  });

  test('E2E 2: 网络失败重试 - syncStatus 变为 failed', () async {
    // 1. 创建 expense 标记 pending
    final expense = Expense(
      id: 'exp-fail',
      tripId: 'trip-002',
      payerId: 'm-002',
      amount: 100.0,
      currency: 'CNY',
      category: ExpenseCategory.transport,
      description: '高铁票',
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      splitRuleJson: '{"type":"equal"}',
      syncStatus: SyncStatus.pending,
    );
    await expensesBox.put(expense.id, expense);

    // 2. 模拟网络失败
    mock.simulateNetworkError = true;

    // 3. 触发同步
    final result = await engine.syncOnce();

    // 4. 验证 expense 状态变为 failed
    final failed = expensesBox.get('exp-fail');
    expect(failed, isNotNull);
    expect(failed!.syncStatus, SyncStatus.failed, reason: '网络失败后应为 failed');
  });

  test('E2E 3: 未登录 - 同步跳过', () async {
    mock.signOutMock();
    final result = await engine.syncOnce();
    expect(result.skipped, true);
    expect(result.reason, contains('not signed in'));
  });

  test('E2E 4: Supabase 未初始化 - 同步跳过', () async {
    final uninitMock = MockSupabaseService();
    uninitMock.simulateUninitialized = true;
    final localEngine = SyncEngine(boxes: boxes, supabase: uninitMock);

    final result = await localEngine.syncOnce();
    expect(result.skipped, true);
    expect(result.reason, contains('not signed in'));

    await localEngine.dispose();
  });

  test('E2E 5: last-write-wins 冲突解决', () async {
    // 1. 本地有 trip updatedAt = T1
    final trip = Trip(
      id: 'trip-conflict',
      name: '旧名称',
      startDate: DateTime(2026, 5, 1),
      baseCurrency: 'CNY',
      status: TripStatus.preparing,
      createdBy: 'user-001',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1, 10, 0), // T1
    );
    await tripsBox.put(trip.id, trip);

    // 2. 云端有更新的 trip updatedAt = T2 (T2 > T1)
    final cloudTrip = {
      'id': 'trip-conflict',
      'name': '新名称',
      'destination': '云南',
      'start_date': '2026-05-01',
      'end_date': null,
      'base_currency': 'CNY',
      'status': 'ongoing',
      'created_by': 'user-001',
      'updated_at': DateTime(2026, 5, 1, 12, 0).toIso8601String(), // T2
    };
    mock.remoteTrips = [cloudTrip];

    // 3. 拉取云端
    final result = await engine.syncOnce();

    // 4. 验证本地被云端覆盖
    final merged = tripsBox.get('trip-conflict');
    expect(merged, isNotNull);
    expect(merged!.name, '新名称', reason: '云端更新应覆盖本地');
    expect(merged.status, TripStatus.ongoing);
  });

  test('E2E 6: 并发同步防护', () async {
    // 两次并发 syncOnce 调用，第二次应被跳过
    final results = await Future.wait([
      engine.syncOnce(),
      engine.syncOnce(),
    ]);

    final skippedCount = results.where((r) => r.skipped).length;
    expect(skippedCount, 1, reason: '第二次应被跳过（_syncing 锁）');
  });
}
