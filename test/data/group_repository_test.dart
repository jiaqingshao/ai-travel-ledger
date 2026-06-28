import 'dart:io';

import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/repositories/group_repository.dart';
import 'package:ai_travel_ledger/data/repositories/trip_repository.dart'
    show RemoteSyncOp;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;
  late Box<TripGroup> box;
  late GroupRepository repo;
  int syncCalls = 0;
  RemoteSyncOp? lastOp;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_group_test_');
    Hive.init(tmpDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(GroupTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TripGroupAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<TripGroup>(
      'groups_${DateTime.now().microsecondsSinceEpoch}',
    );
    syncCalls = 0;
    lastOp = null;
    repo = GroupRepository(
      box: box,
      remoteSync: (_, op) async {
        syncCalls++;
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

  group('GroupRepository.create', () {
    test('创建家庭组并持久化', () async {
      final g = await repo.create(
        tripId: 't1',
        name: '家人',
        groupType: GroupType.family,
        color: '#2E7D32',
      );
      expect(g.name, '家人');
      expect(g.groupType, GroupType.family);
      expect(g.color, '#2E7D32');
      expect(box.get(g.id), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.upsert);
    });

    test('默认类型为 other', () async {
      final g = await repo.create(tripId: 't1', name: '某组');
      expect(g.groupType, GroupType.other);
    });
  });

  group('GroupRepository.listByTrip', () {
    test('按 tripId 过滤', () async {
      await repo.create(tripId: 't1', name: 'A');
      await repo.create(tripId: 't1', name: 'B');
      await repo.create(tripId: 't2', name: 'C');

      expect(repo.listByTrip('t1'), hasLength(2));
      expect(repo.listByTrip('t2'), hasLength(1));
    });
  });

  group('GroupRepository.update', () {
    test('更新名称 + 类型', () async {
      final g = await repo.create(
        tripId: 't1',
        name: 'old',
        groupType: GroupType.family,
      );
      final updated = await repo.update(
        g.id,
        name: 'new',
        groupType: GroupType.company,
      );
      expect(updated.name, 'new');
      expect(updated.groupType, GroupType.company);
    });

    test('不存在的 id 抛 StateError', () async {
      expect(
        () => repo.update('missing', name: 'x'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('GroupRepository.delete', () {
    test('删除并触发远程同步', () async {
      final g = await repo.create(tripId: 't1', name: 'A');
      syncCalls = 0;
      await repo.delete(g.id);
      expect(box.get(g.id), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.delete);
    });

    test('deleteAllByTrip 级联删除某旅程下全部组', () async {
      await repo.create(tripId: 't1', name: 'A');
      await repo.create(tripId: 't1', name: 'B');
      await repo.create(tripId: 't2', name: 'C');

      await repo.deleteAllByTrip('t1');
      expect(repo.listByTrip('t1'), isEmpty);
      expect(repo.listByTrip('t2'), hasLength(1));
    });
  });

  group('GroupRepository - 纯本地模式', () {
    test('无 remoteSync 时正常工作', () async {
      final localRepo = GroupRepository(box: box);
      final g = await localRepo.create(tripId: 't1', name: 'local');
      expect(box.get(g.id), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 0);
    });
  });
}