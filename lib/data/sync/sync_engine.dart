import 'dart:async';
import 'dart:convert';

import '../../core/supabase/supabase_service.dart';
import '../../presentation/providers/core_providers.dart' show HiveBoxes;
import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/transfer_record.dart';
import '../models/trip.dart';

/// 同步引擎（离线优先）
///
/// 设计原则：
/// 1. **本地优先**：所有操作先写本地 Hive（确保离线可用）
/// 2. **后台同步**：网络可用时自动推送 pending 变更
/// 3. **拉取合并**：定时拉取云端变更，本地合并
/// 4. **冲突解决**：使用 updated_at last-write-wins
///
/// 注意：syncStatus 字段在 Expense 模型上是 SyncStatus 枚举
/// 但 Trip/Member/Group 当前没这个字段，所以用 `_cloudVersion` map 单独追踪
class SyncEngine {
  SyncEngine({
    required HiveBoxes boxes,
    SupabaseService? supabase,
  })  : _boxes = boxes,
        _supabase = supabase ?? SupabaseService.instance;

  final HiveBoxes _boxes;
  final SupabaseService _supabase;

  /// 上次同步时间
  DateTime? _lastSyncAt;

  /// 同步进行中
  bool _syncing = false;

  /// 同步状态变化通知
  final _syncStatusController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncStatus => _syncStatusController.stream;

  /// 启动定时同步
  void startAutoSync() {
    Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(syncOnce()),
    );
  }

  /// 触发一次完整同步
  Future<SyncResult> syncOnce() async {
    if (_syncing) {
      return SyncResult(skipped: true);
    }
    if (!_supabase.isInitialized || !_supabase.isSignedIn) {
      return SyncResult(skipped: true, reason: 'not signed in');
    }

    _syncing = true;
    _syncStatusController.add(SyncState.syncing);

    final result = SyncResult();
    try {
      // 1. 推本地 pending -> 云端
      result.pushed = await _pushPending();

      // 2. 拉云端变更 -> 本地
      result.pulled = await _pullChanges();

      _lastSyncAt = DateTime.now();
      result.completedAt = _lastSyncAt;
      _syncStatusController.add(SyncState.idle);
    } catch (e, st) {
      result.error = e;
      result.stackTrace = st;
      _syncStatusController.add(SyncState.error);
    } finally {
      _syncing = false;
    }
    return result;
  }

  /// 推送本地 pending 到云端
  Future<int> _pushPending() async {
    int pushed = 0;

    // 推送 trips
    for (final trip in _boxes.trips.values) {
      if (await _pushTrip(trip)) pushed++;
    }

    // 推送 members
    for (final member in _boxes.members.values) {
      if (await _pushMember(member)) pushed++;
    }

    // 推送 groups
    for (final group in _boxes.groups.values) {
      if (await _pushGroup(group)) pushed++;
    }

    // 推送 expenses（按 status 判断）
    for (final expense in _boxes.expenses.values) {
      if (expense.syncStatus == SyncStatus.pending ||
          expense.syncStatus == SyncStatus.failed) {
        if (await _pushExpense(expense)) pushed++;
      }
    }

    // 推送 transfer_records
    for (final transfer in _boxes.transferRecords.values) {
      if (await _pushTransfer(transfer)) pushed++;
    }

    return pushed;
  }

  /// 推送单个 trip
  Future<bool> _pushTrip(Trip trip) async {
    try {
      final client = _supabase.client;
      await client.from('trips').upsert({
        'id': trip.id,
        'name': trip.name,
        'destination': trip.destination,
        'start_date': trip.startDate.toIso8601String().substring(0, 10),
        'end_date': trip.endDate?.toIso8601String().substring(0, 10),
        'base_currency': trip.baseCurrency,
        'status': trip.status.dbValue,
        'created_by': _supabase.currentUserId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 推送单个 member
  Future<bool> _pushMember(Member member) async {
    try {
      final client = _supabase.client;
      await client.from('trip_members').upsert({
        'id': member.id,
        'trip_id': member.tripId,
        'user_id': member.userId,
        'nickname': member.nickname,
        'avatar_color': member.avatarColor,
        'role': member.role.dbValue,
        'group_id': member.groupId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 推送单个 group
  Future<bool> _pushGroup(TripGroup group) async {
    try {
      final client = _supabase.client;
      await client.from('trip_groups').upsert({
        'id': group.id,
        'trip_id': group.tripId,
        'name': group.name,
        'group_type': group.groupType.name,
        'color': group.color,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 推送单个 expense
  Future<bool> _pushExpense(Expense expense) async {
    try {
      final client = _supabase.client;
      await client.from('expenses').upsert({
        'id': expense.id,
        'trip_id': expense.tripId,
        'payer_id': expense.payerId,
        'amount_cents': (expense.amount * 100).round(),
        'currency': expense.currency,
        'category': expense.category.name,
        'description': expense.description,
        'occurred_at': expense.occurredAt.toIso8601String(),
        'split_rule_json': _parseSplitRule(expense.splitRuleJson),
        'created_by': _supabase.currentUserId,
      });
      // 标记为已同步
      expense.syncStatus = SyncStatus.synced;
      await expense.save();
      return true;
    } catch (_) {
      expense.syncStatus = SyncStatus.failed;
      await expense.save();
      return false;
    }
  }

  /// 推送单个 transfer
  Future<bool> _pushTransfer(TransferRecord transfer) async {
    try {
      final client = _supabase.client;
      await client.from('transfer_records').upsert({
        'id': transfer.id,
        'trip_id': transfer.tripId,
        'from_member_id': transfer.fromMemberId,
        'to_member_id': transfer.toMemberId,
        'amount_cents': (transfer.amount * 100).round(),
        'note': transfer.note,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 解析 split rule JSON 字符串
  Map<String, dynamic> _parseSplitRule(String json) {
    try {
      if (json.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'raw': json};
    } catch (_) {
      return <String, dynamic>{'raw': json};
    }
  }

  /// 拉取云端变更
  Future<int> _pullChanges() async {
    int pulled = 0;
    final client = _supabase.client;
    final userId = _supabase.currentUserId;
    if (userId == null) return 0;

    // 拉取我有权限的 trips（通过 trip_collaborators）
    final tripsResponse = await client
        .from('trips')
        .select('id, name, destination, start_date, end_date, base_currency, status')
        .or('created_by.eq.$userId');

    for (final row in tripsResponse as List) {
      await _mergeTrip(row as Map<String, dynamic>);
      pulled++;
    }
    return pulled;
  }

  /// 合并单个 trip（last-write-wins）
  Future<void> _mergeTrip(Map<String, dynamic> row) async {
    final tripId = row['id'] as String;
    final existing = _boxes.trips.get(tripId);
    final updatedAtStr = row['updated_at'] as String?;
    final cloudUpdatedAt =
        updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now();
    final createdBy = row['created_by'] as String? ?? '';

    // 本地没有 -> 直接写入
    if (existing == null) {
      await _boxes.trips.put(
        tripId,
        Trip.fromDb(
          id: tripId,
          name: row['name'] as String,
          startDate: DateTime.parse(row['start_date'] as String),
          endDate: row['end_date'] != null
              ? DateTime.parse(row['end_date'] as String)
              : null,
          destination: row['destination'] as String?,
          baseCurrency: (row['base_currency'] as String?) ?? 'CNY',
          status: row['status'] as String?,
          createdBy: createdBy,
          createdAt: cloudUpdatedAt,
          updatedAt: cloudUpdatedAt,
        ),
      );
      return;
    }

    // 本地有 -> 比较时间戳
    if (cloudUpdatedAt.isAfter(existing.updatedAt)) {
      existing
        ..name = row['name'] as String
        ..destination = row['destination'] as String?
        ..baseCurrency = (row['base_currency'] as String?) ?? 'CNY'
        ..status = TripStatusX.fromDb(row['status'] as String? ?? 'preparing')
        ..updatedAt = cloudUpdatedAt;
      await existing.save();
    }
  }

  Future<void> dispose() async {
    await _syncStatusController.close();
  }
}



/// 同步状态
enum SyncState { idle, syncing, error }

/// 同步结果
class SyncResult {
  SyncResult({
    this.skipped = false,
    this.reason,
    this.pushed = 0,
    this.pulled = 0,
    this.completedAt,
    this.error,
    this.stackTrace,
  });

  final bool skipped;
  final String? reason;
  int pushed;
  int pulled;
  DateTime? completedAt;
  Object? error;
  StackTrace? stackTrace;

  bool get hasError => error != null;

  @override
  String toString() {
    if (skipped) return 'SyncResult.SKIP($reason)';
    if (hasError) return 'SyncResult.ERROR($error)';
    return 'SyncResult.OK(pushed=$pushed, pulled=$pulled)';
  }
}