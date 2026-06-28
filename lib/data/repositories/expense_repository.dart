import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import 'trip_repository.dart' show RemoteSyncOp;

/// 远程同步回调（费用）
typedef RemoteExpenseSync = Future<void> Function(
  Expense expense,
  RemoteSyncOp op,
);

/// 重复检测匹配场景（用于测试 / 文档）
///
/// **W2 的"重复检测"是单笔检测，不是规则**（E-009 才做规则）。
/// 判定条件：同一天 + 同金额 + 同类别 + 同支付人 + 未删除。
class DuplicateDetector {
  const DuplicateDetector._();

  /// 时间窗口（同一天 = yyyy-MM-dd 相同）。null 表示"完全精确到分钟"。
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判定 [candidate] 是否与 [existing] 视为重复。
  ///
  /// 匹配条件（**全部满足**）：
  /// 1. 同一天（occurredAt 的 yyyy-MM-dd 相同）
  /// 2. 金额相等（[double] 精确比较；后续可放宽为 epsilon）
  /// 3. 类别相同
  /// 4. 支付人相同
  /// 5. 都不是软删除
  static bool isDuplicate(Expense existing, Expense candidate) {
    if (existing.deletedAt != null) return false;
    if (candidate.deletedAt != null) return false;
    if (!isSameDay(existing.occurredAt, candidate.occurredAt)) return false;
    if (existing.amount != candidate.amount) return false;
    if (existing.category != candidate.category) return false;
    if (existing.payerId != candidate.payerId) return false;
    return true;
  }

  /// 在 [pool] 中找与 [candidate] 重复的记录（排除自身）。
  static Expense? findDuplicate(
    List<Expense> pool,
    Expense candidate, {
    String? excludeId,
  }) {
    for (final e in pool) {
      if (excludeId != null && e.id == excludeId) continue;
      if (isDuplicate(e, candidate)) return e;
    }
    return null;
  }
}

/// 费用仓库
/// - 本地优先：所有读写走 Hive（同步、零延迟）
/// - 异步同步：写入成功后**触发但不等待**远程同步回调
/// - 软删除：[delete] 不会物理移除，仅设置 [Expense.deletedAt]
/// - 列表查询默认**过滤软删除**（除非显式传 includeDeleted）
class ExpenseRepository {
  ExpenseRepository({
    required Box<Expense> box,
    RemoteExpenseSync? remoteSync,
    Uuid? uuid,
    DateTime Function()? clock,
  })  : _box = box,
        _remoteSync = remoteSync,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Box<Expense> _box;
  final RemoteExpenseSync? _remoteSync;
  final Uuid _uuid;
  final DateTime Function() _clock;

  String newId() => _uuid.v4();

  // ========================================================================
  // Read
  // ========================================================================

  /// 按 id 读取（包含软删除）
  Expense? getById(String id) => _box.get(id);

  /// 列出某旅程下**未软删除**的费用，按 [Expense.occurredAt] 倒序
  List<Expense> listByTrip(String tripId, {bool includeDeleted = false}) {
    final all = _box.values.where((e) => e.tripId == tripId);
    final filtered = includeDeleted
        ? all
        : all.where((e) => e.deletedAt == null);
    final list = filtered.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  /// 按类别筛选（**默认排除软删除**）
  List<Expense> listByCategory(
    String tripId,
    ExpenseCategory category, {
    bool includeDeleted = false,
  }) {
    return listByTrip(tripId, includeDeleted: includeDeleted)
        .where((e) => e.category == category)
        .toList();
  }

  /// 按时间区间筛选（**默认排除软删除**）
  List<Expense> listByDateRange(
    String tripId, {
    DateTime? from,
    DateTime? to,
    bool includeDeleted = false,
  }) {
    final list = listByTrip(tripId, includeDeleted: includeDeleted);
    return list.where((e) {
      if (from != null && e.occurredAt.isBefore(from)) return false;
      if (to != null && e.occurredAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  /// 某旅程下所有未删除费用的总金额
  double totalByTrip(String tripId) {
    return listByTrip(tripId)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// 某旅程下按类别分组的总金额
  Map<ExpenseCategory, double> totalByCategory(String tripId) {
    final result = <ExpenseCategory, double>{};
    for (final e in listByTrip(tripId)) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  /// 某旅程下最近一次"费用时间"
  DateTime? lastExpenseAt(String tripId) {
    final list = listByTrip(tripId);
    if (list.isEmpty) return null;
    return list.first.occurredAt;
  }

  /// 某成员最近一次作为付款人创建的费用
  Expense? lastByPayer(String tripId, String payerId) {
    final list = listByTrip(tripId)
        .where((e) => e.payerId == payerId)
        .toList();
    if (list.isEmpty) return null;
    return list.first; // 已按 occurredAt 倒序
  }

  // ========================================================================
  // Write
  // ========================================================================

  /// 创建费用
  Future<Expense> create({
    required String tripId,
    required String payerId,
    required double amount,
    required ExpenseCategory category,
    required String splitRuleJson,
    DateTime? occurredAt,
    String? description,
    String currency = 'CNY',
    List<String> attachments = const [],
    String? expenseId,
  }) async {
    final now = _clock();
    final expense = Expense(
      id: expenseId ?? _uuid.v4(),
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      currency: currency,
      category: category,
      description: description,
      occurredAt: occurredAt ?? now,
      createdAt: now,
      updatedAt: now,
      splitRuleJson: splitRuleJson,
      attachments: attachments,
      syncStatus: SyncStatus.synced,
      deletedAt: null,
    );
    await _box.put(expense.id, expense);
    _fireRemote(expense, RemoteSyncOp.upsert);
    return expense;
  }

  /// 更新费用
  Future<Expense> update(
    String id, {
    String? payerId,
    double? amount,
    ExpenseCategory? category,
    String? description,
    String? currency,
    String? splitRuleJson,
    List<String>? attachments,
    DateTime? occurredAt,
  }) async {
    final current = _box.get(id);
    if (current == null) {
      throw StateError('Expense not found: $id');
    }
    final updated = Expense(
      id: current.id,
      tripId: current.tripId,
      payerId: payerId ?? current.payerId,
      amount: amount ?? current.amount,
      currency: currency ?? current.currency,
      category: category ?? current.category,
      description: description ?? current.description,
      occurredAt: occurredAt ?? current.occurredAt,
      createdAt: current.createdAt,
      updatedAt: _clock(),
      splitRuleJson: splitRuleJson ?? current.splitRuleJson,
      attachments: attachments ?? current.attachments,
      syncStatus: current.syncStatus,
      deletedAt: current.deletedAt,
    );
    await _box.put(id, updated);
    _fireRemote(updated, RemoteSyncOp.upsert);
    return updated;
  }

  /// 软删除（设置 [Expense.deletedAt]，**保留历史**）
  Future<Expense> delete(String id) async {
    final current = _box.get(id);
    if (current == null) {
      throw StateError('Expense not found: $id');
    }
    if (current.deletedAt != null) {
      // 已删除，原样返回（幂等）
      return current;
    }
    final updated = Expense(
      id: current.id,
      tripId: current.tripId,
      payerId: current.payerId,
      amount: current.amount,
      currency: current.currency,
      category: current.category,
      description: current.description,
      occurredAt: current.occurredAt,
      createdAt: current.createdAt,
      updatedAt: _clock(),
      splitRuleJson: current.splitRuleJson,
      attachments: current.attachments,
      syncStatus: current.syncStatus,
      deletedAt: _clock(),
    );
    await _box.put(id, updated);
    _fireRemote(updated, RemoteSyncOp.delete);
    return updated;
  }

  /// 恢复软删除的费用（clear [deletedAt]）
  Future<Expense> restore(String id) async {
    final current = _box.get(id);
    if (current == null) {
      throw StateError('Expense not found: $id');
    }
    if (current.deletedAt == null) return current;
    final updated = Expense(
      id: current.id,
      tripId: current.tripId,
      payerId: current.payerId,
      amount: current.amount,
      currency: current.currency,
      category: current.category,
      description: current.description,
      occurredAt: current.occurredAt,
      createdAt: current.createdAt,
      updatedAt: _clock(),
      splitRuleJson: current.splitRuleJson,
      attachments: current.attachments,
      syncStatus: current.syncStatus,
      deletedAt: null,
    );
    await _box.put(id, updated);
    _fireRemote(updated, RemoteSyncOp.upsert);
    return updated;
  }

  /// 物理删除某旅程下的所有费用（仅在测试 / 旅程硬删除时使用）
  Future<void> deleteAllByTrip(String tripId) async {
    final ids = _box.values
        .where((e) => e.tripId == tripId)
        .map((e) => e.id)
        .toList();
    for (final id in ids) {
      final e = _box.get(id);
      await _box.delete(id);
      if (e != null) _fireRemote(e, RemoteSyncOp.delete);
    }
  }

  // ========================================================================
  // Duplicate
  // ========================================================================

  /// 在某旅程下找 [candidate] 的重复项。
  /// - [excludeId]：编辑时排除自身
  /// - 默认**只看未软删除**的池
  Expense? findDuplicate(
    String tripId,
    Expense candidate, {
    String? excludeId,
  }) {
    final pool = listByTrip(tripId);
    return DuplicateDetector.findDuplicate(
      pool,
      candidate,
      excludeId: excludeId,
    );
  }

  // ========================================================================
  // Watch + remote
  // ========================================================================

  Stream<void> watch() => _box.watch().map((_) => null);

  void _fireRemote(Expense expense, RemoteSyncOp op) {
    final sync = _remoteSync;
    if (sync == null) return; // 纯本地模式
    // 异步执行，不 await，不抛错
    sync(expense, op).catchError((_) {});
  }
}
