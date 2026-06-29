/// TransferRecord 单元测试（W4 / E-004）
///
/// 覆盖：
/// - 数据模型 toJson
/// - Repository CRUD
/// - Hive 序列化往返
/// - 远程同步触发
/// - 级联删除
library;

import 'dart:io';

import 'package:ai_travel_ledger/data/models/transfer_record.dart';
import 'package:ai_travel_ledger/data/repositories/transfer_record_repository.dart';
import 'package:ai_travel_ledger/data/repositories/trip_repository.dart'
    show RemoteSyncOp;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;
  late Box<TransferRecord> box;
  late TransferRecordRepository repo;
  int syncCalls = 0;
  TransferRecord? lastSynced;
  RemoteSyncOp? lastOp;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_transfer_record_test_');
    Hive.init(tmpDir.path);
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(TransferRecordAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<TransferRecord>(
      'transfer_records_${DateTime.now().microsecondsSinceEpoch}',
    );
    syncCalls = 0;
    lastSynced = null;
    lastOp = null;
    repo = TransferRecordRepository(
      box: box,
      remoteSync: (r, op) async {
        syncCalls++;
        lastSynced = r;
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

  group('TransferRecord.toJson', () {
    test('含全部字段', () {
      final r = TransferRecord(
        id: 'r1',
        tripId: 't1',
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: 30.5,
        settledAt: DateTime.utc(2026, 6, 1, 12, 30),
        note: '微信转账',
      );
      final json = r.toJson();
      expect(json['id'], 'r1');
      expect(json['trip_id'], 't1');
      expect(json['from_member_id'], 'alice');
      expect(json['to_member_id'], 'bob');
      expect(json['amount'], 30.5);
      expect(json['note'], '微信转账');
      expect(json['settled_at'], isA<String>());
    });

    test('note 可为空', () {
      final r = TransferRecord(
        id: 'r2',
        tripId: 't1',
        fromMemberId: 'a',
        toMemberId: 'b',
        amount: 10,
        settledAt: DateTime(2026, 6, 1),
      );
      expect(r.toJson()['note'], isNull);
    });
  });

  group('TransferRecordRepository.create', () {
    test('持久化到 Hive', () async {
      final r = await repo.create(
        tripId: 't1',
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: 30,
      );
      expect(r.id, isNotEmpty);
      expect(r.tripId, 't1');
      expect(r.amount, 30);
      expect(box.get(r.id), isNotNull);
    });

    test('触发远程 upsert', () async {
      await repo.create(
        tripId: 't1',
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: 30,
      );
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.upsert);
      expect(lastSynced?.fromMemberId, 'alice');
    });

    test('自定义 id / settledAt / note', () async {
      final fixedTime = DateTime.utc(2026, 6, 1, 12);
      final r = await repo.create(
        tripId: 't1',
        fromMemberId: 'a',
        toMemberId: 'b',
        amount: 50,
        settledAt: fixedTime,
        note: '现金',
        recordId: 'custom-id',
      );
      expect(r.id, 'custom-id');
      expect(r.settledAt, fixedTime);
      expect(r.note, '现金');
    });
  });

  group('TransferRecordRepository.read', () {
    test('listByTrip 按 settledAt 倒序', () async {
      await repo.create(
        tripId: 't1',
        fromMemberId: 'a',
        toMemberId: 'b',
        amount: 10,
        settledAt: DateTime(2026, 6, 1, 10),
      );
      await repo.create(
        tripId: 't1',
        fromMemberId: 'c',
        toMemberId: 'd',
        amount: 20,
        settledAt: DateTime(2026, 6, 1, 20),
      );
      await repo.create(
        tripId: 't2', // 不同 trip
        fromMemberId: 'e',
        toMemberId: 'f',
        amount: 30,
        settledAt: DateTime(2026, 6, 1, 15),
      );

      final list = repo.listByTrip('t1');
      expect(list, hasLength(2));
      expect(list.first.amount, 20); // 倒序：20 在前
      expect(list.last.amount, 10);
    });

    test('totalReceivedBy + totalPaidBy', () async {
      await repo.create(
        tripId: 't1',
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: 30,
      );
      await repo.create(
        tripId: 't1',
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: 20,
      );
      await repo.create(
        tripId: 't1',
        fromMemberId: 'carol',
        toMemberId: 'bob',
        amount: 10,
      );
      expect(repo.totalPaidBy('t1', 'alice'), 50);
      expect(repo.totalReceivedBy('t1', 'bob'), 60);
      expect(repo.totalPaidBy('t1', 'bob'), 0);
    });
  });

  group('TransferRecordRepository.delete', () {
    test('删除触发远程 delete', () async {
      final r = await repo.create(
        tripId: 't1',
        fromMemberId: 'a',
        toMemberId: 'b',
        amount: 30,
      );
      syncCalls = 0;
      await repo.delete(r.id);
      expect(box.get(r.id), isNull);
      expect(syncCalls, 1);
      expect(lastOp, RemoteSyncOp.delete);
    });

    test('deleteAllByTrip 级联清理', () async {
      await repo.create(
        tripId: 't1',
        fromMemberId: 'a',
        toMemberId: 'b',
        amount: 10,
      );
      await repo.create(
        tripId: 't1',
        fromMemberId: 'c',
        toMemberId: 'd',
        amount: 20,
      );
      await repo.create(
        tripId: 't2',
        fromMemberId: 'e',
        toMemberId: 'f',
        amount: 30,
      );

      await repo.deleteAllByTrip('t1');
      expect(repo.listByTrip('t1'), isEmpty);
      expect(repo.listByTrip('t2'), hasLength(1));
    });
  });

  group('Hive serialization', () {
    test('复杂对象序列化往返不失真', () async {
      final original = TransferRecord(
        id: 'complex-1',
        tripId: 't-complex',
        fromMemberId: 'alice',
        toMemberId: 'bob',
        amount: 99.99,
        settledAt: DateTime.utc(2026, 6, 1, 12, 30, 45),
        note: '特殊字符：🎉 & "quotes"',
      );
      await box.put(original.id, original);

      final restored = box.get(original.id);
      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.tripId, original.tripId);
      expect(restored.fromMemberId, original.fromMemberId);
      expect(restored.toMemberId, original.toMemberId);
      expect(restored.amount, original.amount);
      expect(restored.settledAt, original.settledAt);
      expect(restored.note, original.note);
    });
  });

  group('TransferRecordRepository.watch', () {
    test('box watch 流', () async {
      final stream = repo.watch();
      final future = stream.first;
      await repo.create(
        tripId: 't1',
        fromMemberId: 'a',
        toMemberId: 'b',
        amount: 30,
      );
      // 给 stream 时间触发
      await expectLater(future, completes);
    });
  });
}