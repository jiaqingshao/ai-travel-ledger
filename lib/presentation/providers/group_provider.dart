import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/group.dart';
import '../../data/repositories/group_repository.dart';
import 'core_providers.dart';

/// 组仓库 Provider
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final boxes = ref.watch(hiveBoxesProvider);
  return GroupRepository(box: boxes.groups);
});

/// 指定旅程的组列表（响应式）
final groupsByTripProvider = StreamProvider.autoDispose
    .family<List<TripGroup>, String>((ref, tripId) async* {
  final repo = ref.watch(groupRepositoryProvider);
  yield repo.listByTrip(tripId);
  await for (final _ in repo.watch()) {
    yield repo.listByTrip(tripId);
  }
});

/// 组操作 Notifier
class GroupNotifier extends StateNotifier<AsyncValue<void>> {
  GroupNotifier(this._repo) : super(const AsyncValue.data(null));

  final GroupRepository _repo;

  Future<TripGroup> create({
    required String tripId,
    required String name,
    GroupType groupType = GroupType.other,
    String? color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final g = await _repo.create(
        tripId: tripId,
        name: name,
        groupType: groupType,
        color: color,
      );
      state = const AsyncValue.data(null);
      return g;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TripGroup> update(
    String id, {
    String? name,
    GroupType? groupType,
    String? color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final g = await _repo.update(
        id,
        name: name,
        groupType: groupType,
        color: color,
      );
      state = const AsyncValue.data(null);
      return g;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
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

final groupNotifierProvider =
    StateNotifierProvider<GroupNotifier, AsyncValue<void>>((ref) {
  return GroupNotifier(ref.watch(groupRepositoryProvider));
});
