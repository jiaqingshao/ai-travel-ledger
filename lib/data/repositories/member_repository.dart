import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/member.dart';
import 'trip_repository.dart' show RemoteSyncOp;

/// 远程同步回调（成员）
typedef RemoteMemberSync = Future<void> Function(
  Member member,
  RemoteSyncOp op,
);

/// 成员仓库（每个旅程的成员列表）
/// - 与 TripRepository 一致的本地优先 + 纯本地模式策略
/// - 所有方法以 [tripId] 作用域过滤
class MemberRepository {
  MemberRepository({
    required Box<Member> box,
    RemoteMemberSync? remoteSync,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _box = box,
        _remoteSync = remoteSync,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Box<Member> _box;
  final RemoteMemberSync? _remoteSync;
  final Uuid _uuid;
  final DateTime Function() _clock;

  String newId() => _uuid.v4();

  /// 列出某旅程的所有成员（按 joinedAt 升序）
  List<Member> listByTrip(String tripId) {
    final list = _box.values.where((m) => m.tripId == tripId).toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return list;
  }

  /// 按 id 读取
  Member? getById(String id) => _box.get(id);

  /// 列出某旅程中的组织者
  List<Member> listOrganizers(String tripId) =>
      listByTrip(tripId).where((m) => m.isOrganizer).toList();

  /// 列出某组的所有成员
  List<Member> listByGroup(String tripId, String? groupId) =>
      listByTrip(tripId).where((m) => m.groupId == groupId).toList();

  /// 添加成员
  Future<Member> add({
    required String tripId,
    required String nickname,
    String? avatarColor,
    MemberRole role = MemberRole.member,
    String? userId,
    String? groupId,
    String? memberId,
  }) async {
    final member = Member(
      id: memberId ?? _uuid.v4(),
      tripId: tripId,
      nickname: nickname,
      avatarColor: avatarColor,
      role: role,
      userId: userId,
      groupId: groupId,
      joinedAt: _clock(),
    );
    await _box.put(member.id, member);
    _fireRemote(member, RemoteSyncOp.upsert);
    return member;
  }

  /// 邀请未注册用户（userId 为 null）
  Future<Member> invite({
    required String tripId,
    required String nickname,
    String? avatarColor,
    String? memberId,
  }) =>
      add(
        tripId: tripId,
        nickname: nickname,
        avatarColor: avatarColor,
        memberId: memberId,
      );

  /// 更新成员（昵称 / 颜色 / 角色 / 组）
  Future<Member> update(
    String id, {
    String? nickname,
    String? avatarColor,
    MemberRole? role,
    String? groupId,
  }) async {
    final current = _box.get(id);
    if (current == null) {
      throw StateError('Member not found: $id');
    }
    final updated = current.copyWith(
      nickname: nickname,
      avatarColor: avatarColor,
      role: role,
      groupId: groupId,
    );
    await _box.put(id, updated);
    _fireRemote(updated, RemoteSyncOp.upsert);
    return updated;
  }

  /// 把成员归组（groupId = null 表示移出组）
  Future<Member> assignToGroup(String memberId, String? groupId) =>
      update(memberId, groupId: groupId);

  /// 提升为组织者
  Future<Member> promoteToOrganizer(String memberId) =>
      update(memberId, role: MemberRole.organizer);

  /// 删除成员
  Future<void> delete(String id) async {
    final member = _box.get(id);
    await _box.delete(id);
    if (member != null) _fireRemote(member, RemoteSyncOp.delete);
  }

  /// 删除某旅程下的所有成员（旅程删除时级联）
  Future<void> deleteAllByTrip(String tripId) async {
    final ids = listByTrip(tripId).map((m) => m.id).toList();
    for (final id in ids) {
      final m = _box.get(id);
      await _box.delete(id);
      if (m != null) _fireRemote(m, RemoteSyncOp.delete);
    }
  }

  Stream<void> watch() => _box.watch().map((_) => null);

  void _fireRemote(Member member, RemoteSyncOp op) {
    final sync = _remoteSync;
    if (sync == null) return;
    sync(member, op).catchError((_) {});
  }
}
