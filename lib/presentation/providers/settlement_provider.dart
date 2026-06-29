import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../../data/models/transfer_record.dart';
import '../../data/repositories/transfer_record_repository.dart';
import '../../domain/services/settlement_engine.dart';
import 'core_providers.dart';
import 'group_provider.dart';
import 'member_provider.dart';
import 'expense_provider.dart';

// ========================================================================
// Helpers
// ========================================================================

/// 调整余额：把已结算记录的影响减去
Map<String, double> adjustBalancesForRecords(
  Map<String, double> balances,
  List<TransferRecord> records,
) {
  final adjusted = Map<String, double>.from(balances);
  for (final r in records) {
    adjusted[r.fromMemberId] = (adjusted[r.fromMemberId] ?? 0) + r.amount;
    adjusted[r.toMemberId] = (adjusted[r.toMemberId] ?? 0) - r.amount;
  }
  // 四舍五入 + 过滤近似 0
  final cleaned = <String, double>{};
  adjusted.forEach((id, v) {
    final rounded = SettlementEngine.round2(v);
    if (rounded.abs() >= SettlementEngine.epsilon) {
      cleaned[id] = rounded;
    }
  });
  return cleaned;
}

// ========================================================================
// Repository provider
// ========================================================================

/// 已结算转账仓库 Provider
final transferRecordRepositoryProvider =
    Provider<TransferRecordRepository>((ref) {
  final boxes = ref.watch(hiveBoxesProvider);
  return TransferRecordRepository(box: boxes.transferRecords);
});

/// 指定旅程下的已结算转账记录（响应式）
final transferRecordsByTripProvider = StreamProvider.autoDispose
    .family<List<TransferRecord>, String>((ref, tripId) async* {
  final repo = ref.watch(transferRecordRepositoryProvider);
  yield repo.listByTrip(tripId);
  await for (final _ in repo.watch()) {
    yield repo.listByTrip(tripId);
  }
});

// ========================================================================
// Settlement Provider (main)
// ========================================================================

/// 完整结算视图（个人粒度 + 按组聚合 + 已结算记录合并）
final settlementProvider =
    Provider.autoDispose.family<AsyncValue<TripSettlement>, String>((ref, tripId) {
  final expensesAsync = ref.watch(expensesByTripProvider(tripId));
  final membersAsync = ref.watch(membersByTripProvider(tripId));
  final groupsAsync = ref.watch(groupsByTripProvider(tripId));
  final recordsAsync = ref.watch(transferRecordsByTripProvider(tripId));

  return expensesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (expenses) {
      return membersAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (members) {
          return groupsAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (e, st) => AsyncValue.error(e, st),
            data: (groups) {
              // Step 1: 原始净额
              final rawBalances =
                  SettlementEngine.calculateNetBalancesFromExpenses(
                expenses: expenses,
                members: members,
                groups: groups,
              );

              // Step 2: 应用已结算记录
              final records = recordsAsync.maybeWhen(
                data: (r) => r,
                orElse: () => const <TransferRecord>[],
              );
              final adjustedBalances =
                  adjustBalancesForRecords(rawBalances, records);

              // Step 3: 最优转账（基于调整后）
              final transfers =
                  SettlementEngine.minimizeTransfers(adjustedBalances);

              // Step 4: 按组聚合（基于调整后）
              final groupSettlements = SettlementEngine.byGroup(
                members: members,
                groups: groups,
                balances: adjustedBalances,
              );

              // Step 5: 总金额
              final total = expenses
                  .where((e) => e.deletedAt == null)
                  .fold<double>(0, (a, e) => a + e.amount);

              return AsyncValue.data(
                TripSettlement(
                  balances: adjustedBalances,
                  transfers: transfers,
                  groups: groupSettlements,
                  totalAmount: SettlementEngine.round2(total),
                  memberCount: members.length,
                ),
              );
            },
          );
        },
      );
    },
  );
});

// ========================================================================
// Group Transfers (provider)
// ========================================================================

/// 组间转账视图（fromId/toId 是 groupId）
final groupTransfersProvider =
    Provider.autoDispose.family<List<Transfer>, String>((ref, tripId) {
  final settlementAsync = ref.watch(settlementProvider(tripId));
  final settlement = settlementAsync.maybeWhen(
    data: (s) => s,
    orElse: () => null,
  );
  if (settlement == null) return const <Transfer>[];

  final membersAsync = ref.watch(membersByTripProvider(tripId));
  final groupsAsync = ref.watch(groupsByTripProvider(tripId));
  final members = membersAsync.maybeWhen<List<Member>>(
    data: (m) => m,
    orElse: () => const <Member>[],
  );
  final groups = groupsAsync.maybeWhen<List<TripGroup>>(
    data: (g) => g,
    orElse: () => const <TripGroup>[],
  );

  return SettlementEngine.transfersBetweenGroups(
    members: members,
    groups: groups,
    balances: settlement.balances,
  );
});

// ========================================================================
// Settlement Notifier (actions)
// ========================================================================

/// 结算操作 Notifier（标记已结算 + 撤销）
class SettlementNotifier extends StateNotifier<AsyncValue<void>> {
  SettlementNotifier(this._repo) : super(const AsyncValue.data(null));

  final TransferRecordRepository _repo;

  /// 标记一笔转账已结清
  Future<TransferRecord> markSettled({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final r = await _repo.create(
        tripId: tripId,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amount: amount,
        note: note,
      );
      state = const AsyncValue.data(null);
      return r;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 撤销已结算
  Future<void> unmarkSettled(String recordId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.delete(recordId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final settlementNotifierProvider =
    StateNotifierProvider<SettlementNotifier, AsyncValue<void>>((ref) {
  return SettlementNotifier(ref.watch(transferRecordRepositoryProvider));
});