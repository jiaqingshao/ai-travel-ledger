import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/group.dart';
import 'trip_repository.dart' show RemoteSyncOp;

/// 远程同步回调（组）
typedef RemoteGroupSync = Future<void> Function(
  TripGroup group,
  RemoteSyncOp op,
);

/// 组仓库（每旅程的组 / 家庭 / 部门 / 团队）
class GroupRepository {
  GroupRepository({
    required Box<TripGroup> box,
    RemoteGroupSync? remoteSync,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _box = box,
        _remoteSync = remoteSync,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Box<TripGroup> _box;
  final RemoteGroupSync? _remoteSync;
  final Uuid _uuid;
  final DateTime Function() _clock;

  String newId() => _uuid.v4();

  /// 列出某旅程的所有组
  List<TripGroup> listByTrip(String tripId) {
    final list = _box.values.where((g) => g.tripId == tripId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  TripGroup? getById(String id) => _box.get(id);

  /// 创建组
  Future<TripGroup> create({
    required String tripId,
    required String name,
    GroupType groupType = GroupType.other,
    String? color,
    String? groupId,
  }) async {
    final group = TripGroup(
      id: groupId ?? _uuid.v4(),
      tripId: tripId,
      name: name,
      groupType: groupType,
      color: color,
      createdAt: _clock(),
    );
    await _box.put(group.id, group);
    _fireRemote(group, RemoteSyncOp.upsert);
    return group;
  }

  /// 更新组
  Future<TripGroup> update(
    String id, {
    String? name,
    GroupType? groupType,
    String? color,
  }) async {
    final current = _box.get(id);
    if (current == null) {
      throw StateError('TripGroup not found: $id');
    }
    final updated = current.copyWith(
      name: name,
      groupType: groupType,
      color: color,
    );
    await _box.put(id, updated);
    _fireRemote(updated, RemoteSyncOp.upsert);
    return updated;
  }

  /// 删除组
  Future<void> delete(String id) async {
    final group = _box.get(id);
    await _box.delete(id);
    if (group != null) _fireRemote(group, RemoteSyncOp.delete);
  }

  /// 删除某旅程下的所有组（旅程删除时级联）
  Future<void> deleteAllByTrip(String tripId) async {
    final ids = listByTrip(tripId).map((g) => g.id).toList();
    for (final id in ids) {
      final g = _box.get(id);
      await _box.delete(id);
      if (g != null) _fireRemote(g, RemoteSyncOp.delete);
    }
  }

  Stream<void> watch() => _box.watch().map((_) => null);

  void _fireRemote(TripGroup group, RemoteSyncOp op) {
    final sync = _remoteSync;
    if (sync == null) return;
    sync(group, op).catchError((_) {});
  }
}