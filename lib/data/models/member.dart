import 'package:hive/hive.dart';

part 'member.g.dart';

/// 成员角色
@HiveType(typeId: 13)
enum MemberRole {
  @HiveField(0)
  organizer,
  @HiveField(1)
  member,
}

extension MemberRoleX on MemberRole {
  String get label {
    switch (this) {
      case MemberRole.organizer:
        return '组织者';
      case MemberRole.member:
        return '成员';
    }
  }

  String get dbValue => name;

  static MemberRole fromDb(String? v) {
    switch (v) {
      case 'organizer':
        return MemberRole.organizer;
      case 'member':
      default:
        return MemberRole.member;
    }
  }
}

@HiveType(typeId: 2)
class Member extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String nickname;

  /// #RRGGBB
  @HiveField(3)
  String? avatarColor;

  @HiveField(4)
  MemberRole role;

  /// 可选关联真实用户
  @HiveField(5)
  String? userId;

  /// 所属组（一人最多一组）
  @HiveField(6)
  String? groupId;

  @HiveField(7)
  DateTime joinedAt;

  Member({
    required this.id,
    required this.tripId,
    required this.nickname,
    this.avatarColor,
    this.role = MemberRole.member,
    this.userId,
    this.groupId,
    required this.joinedAt,
  });

  bool get isOrganizer => role == MemberRole.organizer;

  Member copyWith({
    String? nickname,
    String? avatarColor,
    MemberRole? role,
    Object? groupId = _sentinel,
  }) {
    return Member(
      id: id,
      tripId: tripId,
      nickname: nickname ?? this.nickname,
      avatarColor: avatarColor ?? this.avatarColor,
      role: role ?? this.role,
      userId: userId,
      groupId: identical(groupId, _sentinel)
          ? this.groupId
          : groupId as String?,
      joinedAt: joinedAt,
    );
  }

  static const Object _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'nickname': nickname,
        'avatar_color': avatarColor,
        'role': role.dbValue,
        'user_id': userId,
        'group_id': groupId,
        'joined_at': joinedAt.toIso8601String(),
      };
}
