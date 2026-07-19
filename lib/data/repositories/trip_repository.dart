import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';

/// 远程同步操作类型
enum RemoteSyncOp { upsert, delete }

/// 远程同步回调签名。
///
/// W1 阶段可选；调用方可在 init 时传入 Supabase 适配器。
/// **实现必须捕获所有异常并仅记录日志，绝不能抛出** —— 否则破坏纯本地模式。
typedef RemoteTripSync = Future<void> Function(
  Trip trip,
  RemoteSyncOp op,
);

/// 旅程仓库
/// - 本地优先：所有读写走 Hive（同步、零延迟）
/// - 异步同步：写入成功后**触发但不等待**远程同步回调
/// - 纯本地模式：[remoteSync] 传 null 时完全跳过网络
class TripRepository {
  TripRepository({
    required Box<Trip> box,
    RemoteTripSync? remoteSync,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _box = box,
        _remoteSync = remoteSync,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Box<Trip> _box;
  final RemoteTripSync? _remoteSync;
  final Uuid _uuid;
  final DateTime Function() _clock;

  /// 生成新 id（公开，方便测试/UI 预生成）
  String newId() => _uuid.v4();

  /// 列出所有**活跃**旅程（preparing / ongoing / ended）
  /// - 按 updatedAt 倒序
  List<Trip> listActive() {
    final all = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.where((t) => t.isActive).toList();
  }

  /// 列出所有已归档旅程
  List<Trip> listArchived() {
    final all = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.where((t) => t.isArchived).toList();
  }

  /// 列出全部
  List<Trip> listAll() {
    final all = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  /// 按 id 读取
  Trip? getById(String id) => _box.get(id);

  /// 创建新旅程（持久化并触发远程同步）
  Future<Trip> create({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? destination,
    String baseCurrency = 'CNY',
    String? tripId,
    required String createdBy,
  }) async {
    final now = _clock();
    final trip = Trip(
      id: tripId ?? _uuid.v4(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
      baseCurrency: baseCurrency,
      status: TripStatus.preparing,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(trip.id, trip);
    _fireRemote(trip, RemoteSyncOp.upsert);
    return trip;
  }

  /// 更新旅程字段
  Future<Trip> update(
    String id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    String? baseCurrency,
    TripStatus? status,
  }) async {
    final current = _box.get(id);
    if (current == null) {
      throw StateError('Trip not found: $id');
    }
    final updated = current.copyWith(
      name: name,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
      baseCurrency: baseCurrency,
      status: status,
      updatedAt: _clock(),
    );
    await _box.put(id, updated);
    _fireRemote(updated, RemoteSyncOp.upsert);
    return updated;
  }

  /// 归档
  Future<Trip> archive(String id) => update(id, status: TripStatus.archived);

  /// 取消归档（恢复为 preparing）
  Future<Trip> unarchive(String id) => update(id, status: TripStatus.preparing);

  /// 删除（本地 + 远程同步）
  Future<void> delete(String id) async {
    final trip = _box.get(id);
    await _box.delete(id);
    if (trip != null) _fireRemote(trip, RemoteSyncOp.delete);
  }

  /// 监听 Box 变更（用于 Provider 反应式更新）
  Stream<void> watch() => _box.watch().map((_) => null);

  /// 触发远程同步（不抛异常）
  void _fireRemote(Trip trip, RemoteSyncOp op) {
    final sync = _remoteSync;
    if (sync == null) return; // 纯本地模式
    // 异步执行，不 await，不抛错
    sync(trip, op).catchError((_) {});
  }
}
