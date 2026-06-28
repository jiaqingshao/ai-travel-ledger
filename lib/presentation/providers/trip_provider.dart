import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// W1 阶段尚未接入 Auth，使用本地固定用户 ID。
/// 后续接入 Supabase Auth 后改为 auth.currentUser!.id。
const String kCurrentUserId = 'local-user';

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

/// 按 id 取单个旅程（同步取 Box 值）
final tripByIdProvider = Provider.family<Trip?, String>((ref, id) {
  final repo = ref.watch(tripRepositoryProvider);
  // 订阅 box 变更以触发重建
  ref.watch(tripRepositoryProvider);
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
        createdBy: kCurrentUserId,
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