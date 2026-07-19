import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/transfer_record.dart';
import 'trip_repository.dart' show RemoteSyncOp;

/// 远程同步回调（已结算转账）
typedef RemoteTransferSync = Future<void> Function(
  TransferRecord record,
  RemoteSyncOp op,
);

/// 已结算转账仓库
///
/// - 持久化 Hive box
/// - 支持按 trip / member 维度查询
/// - 自动触发远程同步（可选）
class TransferRecordRepository {
  TransferRecordRepository({
    required Box<TransferRecord> box,
    RemoteTransferSync? remoteSync,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _box = box,
        _remoteSync = remoteSync,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Box<TransferRecord> _box;
  final RemoteTransferSync? _remoteSync;
  final Uuid _uuid;
  final DateTime Function() _clock;

  String newId() => _uuid.v4();

  // ========================================================================
  // Read
  // ========================================================================

  /// 按 id 读取
  TransferRecord? getById(String id) => _box.get(id);

  /// 列出某旅程下的所有已结算记录（按 settledAt 倒序）
  List<TransferRecord> listByTrip(String tripId) {
    final list = _box.values.where((r) => r.tripId == tripId).toList()
      ..sort((a, b) => b.settledAt.compareTo(a.settledAt));
    return list;
  }

  /// 列出某成员作为付款方的已结算记录
  List<TransferRecord> listByFromMember(String tripId, String memberId) {
    return listByTrip(tripId).where((r) => r.fromMemberId == memberId).toList();
  }

  /// 列出某成员作为收款方的已结算记录
  List<TransferRecord> listByToMember(String tripId, String memberId) {
    return listByTrip(tripId).where((r) => r.toMemberId == memberId).toList();
  }

  /// 统计某成员的"已收金额"（作为 toMember）
  double totalReceivedBy(String tripId, String memberId) {
    return listByToMember(tripId, memberId)
        .fold<double>(0, (sum, r) => sum + r.amount);
  }

  /// 统计某成员的"已付金额"（作为 fromMember）
  double totalPaidBy(String tripId, String memberId) {
    return listByFromMember(tripId, memberId)
        .fold<double>(0, (sum, r) => sum + r.amount);
  }

  // ========================================================================
  // Write
  // ========================================================================

  /// 创建已结算记录
  Future<TransferRecord> create({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    DateTime? settledAt,
    String? note,
    String? recordId,
  }) async {
    final record = TransferRecord(
      id: recordId ?? _uuid.v4(),
      tripId: tripId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      settledAt: settledAt ?? _clock(),
      note: note,
    );
    await _box.put(record.id, record);
    _fireRemote(record, RemoteSyncOp.upsert);
    return record;
  }

  /// 删除已结算记录（撤销标记）
  Future<void> delete(String id) async {
    final r = _box.get(id);
    await _box.delete(id);
    if (r != null) _fireRemote(r, RemoteSyncOp.delete);
  }

  /// 删除某旅程下的所有记录（旅程硬删除时级联）
  Future<void> deleteAllByTrip(String tripId) async {
    final ids = listByTrip(tripId).map((r) => r.id).toList();
    for (final id in ids) {
      final r = _box.get(id);
      await _box.delete(id);
      if (r != null) _fireRemote(r, RemoteSyncOp.delete);
    }
  }

  // ========================================================================
  // Watch
  // ========================================================================

  Stream<void> watch() => _box.watch().map((_) {});

  void _fireRemote(TransferRecord record, RemoteSyncOp op) {
    final sync = _remoteSync;
    if (sync == null) return;
    sync(record, op).catchError((_) {});
  }
}
