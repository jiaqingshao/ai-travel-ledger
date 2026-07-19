import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import 'core_providers.dart';

/// 费用仓库 Provider（纯本地模式：不传 remoteSync）
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final boxes = ref.watch(hiveBoxesProvider);
  return ExpenseRepository(box: boxes.expenses);
});

/// 指定 trip 的费用列表（响应式，默认排除软删除）
final expensesByTripProvider = StreamProvider.autoDispose
    .family<List<Expense>, String>((ref, tripId) async* {
  final repo = ref.watch(expenseRepositoryProvider);
  yield repo.listByTrip(tripId);
  await for (final _ in repo.watch()) {
    yield repo.listByTrip(tripId);
  }
});

/// 按 id 取单个费用（响应式：订阅 box.watch() 自动重建）
///
/// ISSUE-042 修复: 原版用 Provider.family + ref.watch(repoProvider) (no-op),
/// Hive box 写入时不会重建, 导致编辑后详情页仍显示旧值.
/// 现改为 StreamProvider.autoDispose.family 订阅 repo.watch() 流.
final expenseByIdProvider =
    StreamProvider.autoDispose.family<Expense?, String>((ref, id) async* {
  final repo = ref.watch(expenseRepositoryProvider);
  yield repo.getById(id);
  await for (final _ in repo.watch()) {
    yield repo.getById(id);
  }
});

/// 指定 trip 的总金额（响应式：订阅 box watch）
final totalByTripProvider =
    StreamProvider.autoDispose.family<double, String>((ref, tripId) async* {
  final repo = ref.watch(expenseRepositoryProvider);
  yield repo.totalByTrip(tripId);
  await for (final _ in repo.watch()) {
    yield repo.totalByTrip(tripId);
  }
});

/// 指定 trip 按类别分组的总金额（响应式）
final totalByCategoryProvider = StreamProvider.autoDispose
    .family<Map<ExpenseCategory, double>, String>((ref, tripId) async* {
  final repo = ref.watch(expenseRepositoryProvider);
  yield repo.totalByCategory(tripId);
  await for (final _ in repo.watch()) {
    yield repo.totalByCategory(tripId);
  }
});

/// 费用操作 Notifier（CRUD + 重复检测）
class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  ExpenseNotifier(this._repo) : super(const AsyncValue.data(null));

  final ExpenseRepository _repo;

  /// 创建费用
  /// - 返回 (expense, duplicate)
  /// - duplicate 非 null 时表示检测到重复，调用方应提示用户确认
  Future<({Expense expense, Expense? duplicate})> create({
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
    state = const AsyncValue.loading();
    try {
      final expense = await _repo.create(
        tripId: tripId,
        payerId: payerId,
        amount: amount,
        category: category,
        splitRuleJson: splitRuleJson,
        occurredAt: occurredAt,
        description: description,
        currency: currency,
        attachments: attachments,
        expenseId: expenseId,
      );
      state = const AsyncValue.data(null);
      // 创建后再做一次重复检测
      final dup = _repo.findDuplicate(tripId, expense, excludeId: expense.id);
      return (expense: expense, duplicate: dup);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 创建前预检重复（不写入）
  /// - 用于 UI 在保存前先提示
  Expense? precheckDuplicate({
    required String tripId,
    required String payerId,
    required double amount,
    required ExpenseCategory category,
    required DateTime occurredAt,
  }) {
    final candidate = Expense(
      id: '__preview__',
      tripId: tripId,
      payerId: payerId,
      amount: amount,
      category: category,
      occurredAt: occurredAt,
      createdAt: occurredAt,
      updatedAt: occurredAt,
      splitRuleJson: '',
    );
    return _repo.findDuplicate(tripId, candidate);
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
    state = const AsyncValue.loading();
    try {
      final e = await _repo.update(
        id,
        payerId: payerId,
        amount: amount,
        category: category,
        description: description,
        currency: currency,
        splitRuleJson: splitRuleJson,
        attachments: attachments,
        occurredAt: occurredAt,
      );
      state = const AsyncValue.data(null);
      return e;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 软删除
  Future<Expense> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      final e = await _repo.delete(id);
      state = const AsyncValue.data(null);
      return e;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 恢复
  Future<Expense> restore(String id) async {
    state = const AsyncValue.loading();
    try {
      final e = await _repo.restore(id);
      state = const AsyncValue.data(null);
      return e;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  return ExpenseNotifier(ref.watch(expenseRepositoryProvider));
});
