import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member.dart';
import '../../data/repositories/member_repository.dart';
import 'core_providers.dart';

/// 成员仓库 Provider
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final boxes = ref.watch(hiveBoxesProvider);
  return MemberRepository(box: boxes.members);
});

/// 指定旅程的成员列表（响应式）
final membersByTripProvider = StreamProvider.autoDispose
    .family<List<Member>, String>((ref, tripId) async* {
  final repo = ref.watch(memberRepositoryProvider);
  yield repo.listByTrip(tripId);
  await for (final _ in repo.watch()) {
    yield repo.listByTrip(tripId);
  }
});

/// 指定旅程 + 组 的成员列表（同步读 Hive）
///
/// ISSUE-042 修复: 保留 Provider.family 同步读 Hive (无 loading 状态),
/// 靠调用方 ref.invalidate(membersByGroupProvider) 手动重建.
final membersByGroupProvider =
    Provider.family<List<Member>, ({String tripId, String? groupId})>(
        (ref, args) {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.listByGroup(args.tripId, args.groupId);
});

/// 成员操作 Notifier
class MemberNotifier extends StateNotifier<AsyncValue<void>> {
  MemberNotifier(this._repo) : super(const AsyncValue.data(null));

  final MemberRepository _repo;

  Future<Member> add({
    required String tripId,
    required String nickname,
    String? avatarColor,
    MemberRole role = MemberRole.member,
    String? userId,
    String? groupId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final m = await _repo.add(
        tripId: tripId,
        nickname: nickname,
        avatarColor: avatarColor,
        role: role,
        userId: userId,
        groupId: groupId,
      );
      state = const AsyncValue.data(null);
      return m;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Member> invite({
    required String tripId,
    required String nickname,
    String? avatarColor,
  }) async {
    state = const AsyncValue.loading();
    try {
      final m = await _repo.invite(
        tripId: tripId,
        nickname: nickname,
        avatarColor: avatarColor,
      );
      state = const AsyncValue.data(null);
      return m;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Member> update(
    String id, {
    String? nickname,
    String? avatarColor,
    MemberRole? role,
    String? groupId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final m = await _repo.update(
        id,
        nickname: nickname,
        avatarColor: avatarColor,
        role: role,
        groupId: groupId,
      );
      state = const AsyncValue.data(null);
      return m;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Member> assignToGroup(String memberId, String? groupId) =>
      update(memberId, groupId: groupId);

  Future<Member> promoteToOrganizer(String memberId) =>
      update(memberId, role: MemberRole.organizer);

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

final memberNotifierProvider =
    StateNotifierProvider<MemberNotifier, AsyncValue<void>>((ref) {
  return MemberNotifier(ref.watch(memberRepositoryProvider));
});
