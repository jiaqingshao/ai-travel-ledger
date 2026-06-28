import 'dart:io';

import 'package:ai_travel_ledger/data/models/trip.dart';
import 'package:ai_travel_ledger/data/repositories/trip_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;
  late Box<Trip> box;
  late TripRepository repo;
  int syncCalls = 0;
  Trip? lastSyncedTrip;
  RemoteSyncOp? lastOp;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_trip_test_');
    Hive.init(tmpDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TripStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TripAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<Trip>(
      'trips_${DateTime.now().microsecondsSinceEpoch}',
    );
    syncCalls = 0;
    lastSyncedTrip = null;
    lastOp = null;
    repo = TripRepository(
      box: box,
      remoteSync: (trip, op) async {
        syncCalls++;
        lastSyncedTrip = trip;
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

  group('TripRepository.create', () {
    test('creates trip with default status=preparing and persists', () async {
      final t = await repo.create(
        name: '国庆自驾',
        startDate: DateTime(2026, 10, 1),
        createdBy: 'u1',
      );
      expect(t.id, isNotEmpty);
      expect(t.name, '国庆自驾');
      expect(t.status, TripStatus.preparing);
      expect(box.get(t.id), isNotNull);
      expect(box.get(t.id)!.name, '国庆自驾');
    });

    test('triggers remote upsert after create', () async {
      await repo.create(
        name: 'T',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u1',
      );
      // 等待 microtask 跑完 _fireRemote
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.upsert);
      expect(lastSyncedTrip?.name, 'T');
    });
  });

  group('TripRepository.update / archive', () {
    test('updates fields and bumps updatedAt', () async {
      final t = await repo.create(
        name: 'old',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u1',
      );
      final oldUpdated = t.updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final updated = await repo.update(
        t.id,
        name: 'new',
        destination: '大理',
      );
      expect(updated.name, 'new');
      expect(updated.destination, '大理');
      expect(updated.updatedAt.isAfter(oldUpdated), isTrue);
    });

    test('archive moves trip to archived list', () async {
      final t = await repo.create(
        name: 'T',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u1',
      );
      expect(repo.listActive(), hasLength(1));
      expect(repo.listArchived(), isEmpty);

      await repo.archive(t.id);

      expect(repo.listActive(), isEmpty);
      expect(repo.listArchived(), hasLength(1));
      expect(repo.listArchived().first.status, TripStatus.archived);
    });

    test('unarchive restores trip to active', () async {
      final t = await repo.create(
        name: 'T',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u1',
      );
      await repo.archive(t.id);
      await repo.unarchive(t.id);
      expect(repo.listActive(), hasLength(1));
      expect(repo.listArchived(), isEmpty);
    });
  });

  group('TripRepository.delete', () {
    test('removes from box and triggers remote delete', () async {
      final t = await repo.create(
        name: 'T',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u1',
      );
      syncCalls = 0;
      await repo.delete(t.id);
      expect(box.get(t.id), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.delete);
    });

    test('throws on update missing trip', () async {
      expect(
        () => repo.update('nope', name: 'x'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('TripRepository - 纯本地模式', () {
    test('无 remoteSync 时不抛异常', () async {
      final localRepo = TripRepository(box: box);
      final t = await localRepo.create(
        name: 'local',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u1',
      );
      expect(t.id, isNotEmpty);
      expect(box.get(t.id), isNotNull);
      // 等待 microtask，确保 _fireRemote 空操作没炸
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 0);
    });

    test('listActive 按 updatedAt 倒序', () async {
      final t1 = await repo.create(
        name: 'A',
        startDate: DateTime(2026, 1, 1),
        createdBy: 'u',
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final t2 = await repo.create(
        name: 'B',
        startDate: DateTime(2026, 2, 1),
        createdBy: 'u',
      );
      final list = repo.listActive();
      expect(list.first.id, t2.id); // 最新在前
      expect(list.last.id, t1.id);
    });
  });
}