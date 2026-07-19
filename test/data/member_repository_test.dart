import 'dart:io';

import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/data/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;
  late Box<Member> box;
  late MemberRepository repo;
  int syncCalls = 0;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('hive_member_test_');
    Hive.init(tmpDir.path);
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(MemberRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MemberAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<Member>(
      'members_${DateTime.now().microsecondsSinceEpoch}',
    );
    syncCalls = 0;
    repo = MemberRepository(
      box: box,
      remoteSync: (_, __) async {
        syncCalls++;
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

  group('MemberRepository.add', () {
    test('持久化 + 触发远程 upsert', () async {
      final m = await repo.add(
        tripId: 'trip-1',
        nickname: '小明',
        avatarColor: '#1976D2',
        role: MemberRole.organizer,
      );
      expect(m.nickname, '小明');
      expect(m.role, MemberRole.organizer);
      expect(box.get(m.id), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
    });

    test('invite 等价于 add（userId=null）', () async {
      final m = await repo.invite(
        tripId: 'trip-1',
        nickname: '妈妈',
      );
      expect(m.userId, isNull);
      expect(m.tripId, 'trip-1');
    });
  });

  group('MemberRepository.listByTrip / listByGroup', () {
    test('按 tripId 过滤，按 joinedAt 升序', () async {
      final a = await repo.add(tripId: 't1', nickname: 'A');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final b = await repo.add(tripId: 't1', nickname: 'B');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.add(tripId: 't2', nickname: 'C');

      final listT1 = repo.listByTrip('t1');
      expect(listT1, hasLength(2));
      expect(listT1.first.id, a.id);
      expect(listT1.last.id, b.id);

      final listT2 = repo.listByTrip('t2');
      expect(listT2, hasLength(1));
      expect(listT2.first.nickname, 'C');
    });

    test('listByGroup 支持 null 组（未分组）', () async {
      final a = await repo.add(tripId: 't1', nickname: 'A');
      final b = await repo.add(
        tripId: 't1',
        nickname: 'B',
        groupId: 'g1',
      );
      expect(repo.listByGroup('t1', null), [a]);
      expect(repo.listByGroup('t1', 'g1'), [b]);
    });
  });

  group('MemberRepository.assignToGroup / promote', () {
    test('assignToGroup 切换 groupId', () async {
      final m = await repo.add(tripId: 't1', nickname: 'A');
      await repo.assignToGroup(m.id, 'g1');
      expect(box.get(m.id)!.groupId, 'g1');
      await repo.assignToGroup(m.id, null);
      expect(box.get(m.id)!.groupId, isNull);
    });

    test('promoteToOrganizer 设置 role', () async {
      final m = await repo.add(tripId: 't1', nickname: 'A');
      expect(m.role, MemberRole.member);
      final promoted = await repo.promoteToOrganizer(m.id);
      expect(promoted.role, MemberRole.organizer);
    });
  });

  group('MemberRepository.delete', () {
    test('删除成员 + 远程同步', () async {
      final m = await repo.add(tripId: 't1', nickname: 'A');
      syncCalls = 0;
      await repo.delete(m.id);
      expect(box.get(m.id), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 1);
    });

    test('deleteAllByTrip 级联删除某旅程下全部成员', () async {
      await repo.add(tripId: 't1', nickname: 'A');
      await repo.add(tripId: 't1', nickname: 'B');
      await repo.add(tripId: 't2', nickname: 'C');

      await repo.deleteAllByTrip('t1');
      expect(repo.listByTrip('t1'), isEmpty);
      expect(repo.listByTrip('t2'), hasLength(1));
    });
  });

  group('MemberRepository - 纯本地模式', () {
    test('无 remoteSync 时不报错', () async {
      final localRepo = MemberRepository(box: box);
      final m = await localRepo.add(tripId: 't1', nickname: 'X');
      expect(box.get(m.id), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalls, 0);
    });
  });
}
