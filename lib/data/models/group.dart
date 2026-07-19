import 'package:hive/hive.dart';

part 'group.g.dart';

/// 组类型
@HiveType(typeId: 10)
enum GroupType {
  @HiveField(0)
  family,
  @HiveField(1)
  company,
  @HiveField(2)
  department,
  @HiveField(3)
  team,
  @HiveField(4)
  other,
}

extension GroupTypeExtension on GroupType {
  String get displayName {
    switch (this) {
      case GroupType.family:
        return '家庭';
      case GroupType.company:
        return '企业';
      case GroupType.department:
        return '部门';
      case GroupType.team:
        return '队伍';
      case GroupType.other:
        return '其他';
    }
  }

  String get icon {
    switch (this) {
      case GroupType.family:
        return '🏠';
      case GroupType.company:
        return '🏢';
      case GroupType.department:
        return '📊';
      case GroupType.team:
        return '👥';
      case GroupType.other:
        return '📦';
    }
  }
}

@HiveType(typeId: 3)
class TripGroup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String name;

  @HiveField(3)
  GroupType groupType;

  @HiveField(4)
  String? color; // #RRGGBB

  @HiveField(5)
  DateTime createdAt;

  TripGroup({
    required this.id,
    required this.tripId,
    required this.name,
    this.groupType = GroupType.other,
    this.color,
    required this.createdAt,
  });

  String get displayName => name;
  String get icon => groupType.icon;

  TripGroup copyWith({
    String? name,
    GroupType? groupType,
    String? color,
  }) {
    return TripGroup(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      groupType: groupType ?? this.groupType,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}
