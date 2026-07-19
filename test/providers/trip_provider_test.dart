import 'dart:io';

import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/attachment.dart';
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/data/models/transfer_record.dart';
import 'package:ai_travel_ledger/data/models/trip.dart';
import 'package:ai_travel_ledger/presentation/providers/core_providers.dart';
import 'package:ai_travel_ledger/presentation/providers/trip_provider.dart';
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
    tmpDir = Directory.systemTemp.createTempSync('hive_trip_provider_');
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

  test('tripRepositoryProvider 返回有效仓库', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final repo = c.read(tripRepositoryProvider);
    expect(repo, isNotNull);
    expect(repo.listAll(), isEmpty);
  });

  test('TripNotifier.create 写入 box 并可读出', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final notifier = c.read(tripNotifierProvider.notifier);

    final trip = await notifier.create(
      name: '测试旅程',
      startDate: DateTime(2026, 10, 1),
      destination: '云南',
    );
    expect(trip.name, '测试旅程');
    expect(tripsBox.get(trip.id), isNotNull);
    // ISSUE-042 v2: tripByIdProvider 恢复 Provider.family 同步读
    final fetched = c.read(tripByIdProvider(trip.id));
    expect(fetched?.name, '测试旅程');
  });

  test('TripNotifier.archive / unarchive 改变 listActive/Archived', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final notifier = c.read(tripNotifierProvider.notifier);
    final repo = c.read(tripRepositoryProvider);

    final trip = await notifier.create(
      name: 'T',
      startDate: DateTime(2026, 1, 1),
    );

    expect(repo.listActive(), hasLength(1));
    expect(repo.listArchived(), isEmpty);

    await notifier.archive(trip.id);
    expect(repo.listActive(), isEmpty);
    expect(repo.listArchived(), hasLength(1));

    await notifier.unarchive(trip.id);
    expect(repo.listActive(), hasLength(1));
    expect(repo.listArchived(), isEmpty);
  });

  test('TripNotifier.update 修改字段', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final notifier = c.read(tripNotifierProvider.notifier);
    final repo = c.read(tripRepositoryProvider);

    final t = await notifier.create(
      name: 'old',
      startDate: DateTime(2026, 1, 1),
    );
    await notifier.update(t.id, name: 'new', destination: '大理');

    final fetched = repo.getById(t.id);
    expect(fetched?.name, 'new');
    expect(fetched?.destination, '大理');
  });

  test('TripNotifier.delete 移除记录', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final notifier = c.read(tripNotifierProvider.notifier);
    final repo = c.read(tripRepositoryProvider);

    final t = await notifier.create(
      name: 'X',
      startDate: DateTime(2026, 1, 1),
    );
    expect(repo.listAll(), hasLength(1));
    await notifier.delete(t.id);
    expect(repo.listAll(), isEmpty);
  });
}
