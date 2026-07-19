import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_service.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/trip_repository.dart';
import 'core_providers.dart';

/// 旅程仓库 Provider（纯本地模式：不传 remoteSync）
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final boxes = ref.watch(hiveBoxesProvider);
  return TripRepository(box: boxes.trips);
});

/// 当前用户的 "createdBy" 标识。
///
/// [PR-3 修复 S-8] 优先从 Supabase Auth 读 (已登录时), 未登录回退本地固定值
/// 这样云端模式下创建的 expense/trip 归属真正的 user_id, RLS 才能正常隔离
String kCurrentUserId() {
  final userId = SupabaseService.instance.currentUserId;
  if (userId != null) return userId;
  return 'local-user';
}

/// 活跃旅程列表（自动响应 Box 变更）
final activeTripsProvider =
    StreamProvider.autoDispose<List<Trip>>((ref) async* {
  final repo = ref.watch(tripRepositoryProvider);
  yield repo.listActive();
  await for (final _ in repo.watch()) {
    yield repo.listActive();
  }
});

/// 已归档旅程列表
final archivedTripsProvider =
    StreamProvider.autoDispose<List<Trip>>((ref) async* {
  final repo = ref.watch(tripRepositoryProvider);
  yield repo.listArchived();
  await for (final _ in repo.watch()) {
    yield repo.listArchived();
  }
});

/// 按 id 取单个旅程（同步读 Hive）
///
/// ISSUE-042 修复: 保留 Provider.family 同步读 Hive (无 loading 状态),
/// 靠调用方 ref.invalidate(tripByIdProvider) 手动重建.
///
/// 原因同 expenseByIdProvider: 避免 StreamProvider.autoDispose 的中间 loading 状态.
final tripByIdProvider = Provider.family<Trip?, String>((ref, id) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getById(id);
});

/// 旅程操作 Notifier（CRUD）
class TripNotifier extends StateNotifier<AsyncValue<void>> {
  TripNotifier(this._repo) : super(const AsyncValue.data(null));

  final TripRepository _repo;

  Future<Trip> create({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? destination,
    String baseCurrency = 'CNY',
  }) async {
    state = const AsyncValue.loading();
    try {
      final trip = await _repo.create(
        name: name,
        startDate: startDate,
        endDate: endDate,
        destination: destination,
        baseCurrency: baseCurrency,
        createdBy: kCurrentUserId(),
      );
      state = const AsyncValue.data(null);
      return trip;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Trip> update(
    String id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    String? baseCurrency,
    TripStatus? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final trip = await _repo.update(
        id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        destination: destination,
        baseCurrency: baseCurrency,
        status: status,
      );
      state = const AsyncValue.data(null);
      return trip;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> archive(String id) async {
    await update(id, status: TripStatus.archived);
  }

  Future<void> unarchive(String id) async {
    await update(id, status: TripStatus.preparing);
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final tripNotifierProvider =
    StateNotifierProvider<TripNotifier, AsyncValue<void>>((ref) {
  return TripNotifier(ref.watch(tripRepositoryProvider));
});
