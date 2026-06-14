import 'package:hive/hive.dart';

part 'member.g.dart';

@HiveType(typeId: 2)
class Member extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String nickname;

  @HiveField(3)
  String? avatarColor;  // #RRGGBB

  @HiveField(4)
  String role;  // organizer | member

  @HiveField(5)
  String? userId;  // 可选关联真实用户

  @HiveField(6)
  String? groupId;  // 🆕 所属组

  @HiveField(7)
  DateTime joinedAt;

  Member({
    required this.id,
    required this.tripId,
    required this.nickname,
    this.avatarColor,
    this.role = 'member',
    this.userId,
    this.groupId,
    required this.joinedAt,
  });

  bool get isOrganizer => role == 'organizer';

  Member copyWith({
    String? nickname,
    String? avatarColor,
    String? role,
    String? groupId,
  }) {
    return Member(
      id: id,
      tripId: tripId,
      nickname: nickname ?? this.nickname,
      avatarColor: avatarColor ?? this.avatarColor,
      role: role ?? this.role,
      userId: userId,
      groupId: groupId ?? this.groupId,
      joinedAt: joinedAt,
    );
  }
}
