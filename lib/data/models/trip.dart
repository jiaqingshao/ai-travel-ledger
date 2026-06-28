import 'package:hive/hive.dart';

part 'trip.g.dart';

/// 旅程状态机：
///   preparing → ongoing → ended → archived
///
/// - [preparing]: 准备中（出发前，默认新创建状态）
/// - [ongoing]:   进行中（startDate ≤ today ≤ endDate 或用户手动切换）
/// - [ended]:     已结束（endDate < today 或用户手动结束，仍可查看）
/// - [archived]:  已归档（用户主动归档，从主列表隐藏，进入「历史」）
@HiveType(typeId: 0)
enum TripStatus {
  @HiveField(0)
  preparing,
  @HiveField(1)
  ongoing,
  @HiveField(2)
  ended,
  @HiveField(3)
  archived,
}

extension TripStatusX on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.preparing:
        return '准备中';
      case TripStatus.ongoing:
        return '进行中';
      case TripStatus.ended:
        return '已结束';
      case TripStatus.archived:
        return '已归档';
    }
  }

  String get dbValue {
    // 与 Supabase ENUM 保持一致（小写）
    switch (this) {
      case TripStatus.preparing:
        return 'preparing';
      case TripStatus.ongoing:
        return 'ongoing';
      case TripStatus.ended:
        return 'ended';
      case TripStatus.archived:
        return 'archived';
    }
  }

  bool get isActiveHistory =>
      this == TripStatus.ended || this == TripStatus.archived;

  static TripStatus fromDb(String value) {
    switch (value) {
      case 'ongoing':
        return TripStatus.ongoing;
      case 'ended':
        return TripStatus.ended;
      case 'archived':
        return TripStatus.archived;
      case 'preparing':
      default:
        return TripStatus.preparing;
    }
  }
}

@HiveType(typeId: 1)
class Trip extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime startDate;

  @HiveField(3)
  DateTime? endDate;

  @HiveField(4)
  String? destination;

  @HiveField(5)
  String baseCurrency;

  /// 状态（默认 preparing）
  @HiveField(6)
  TripStatus status;

  @HiveField(7)
  String createdBy;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.destination,
    this.baseCurrency = 'CNY',
    this.status = TripStatus.preparing,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 后端用 active/archived 字符串迁移时的兼容构造
  factory Trip.fromDb({
    required String id,
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? destination,
    String baseCurrency = 'CNY',
    String? status,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final TripStatus s;
    switch (status) {
      case 'ongoing':
        s = TripStatus.ongoing;
        break;
      case 'ended':
        s = TripStatus.ended;
        break;
      case 'archived':
        s = TripStatus.archived;
        break;
      case 'active':
        // 兼容旧 active，按起止日期推断
        final today = DateTime.now();
        if (endDate != null && endDate.isBefore(today)) {
          s = TripStatus.ended;
        } else if (startDate.isAfter(today)) {
          s = TripStatus.preparing;
        } else {
          s = TripStatus.ongoing;
        }
        break;
      case 'preparing':
      default:
        s = TripStatus.preparing;
    }
    return Trip(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
      baseCurrency: baseCurrency,
      status: s,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isPreparing => status == TripStatus.preparing;
  bool get isOngoing => status == TripStatus.ongoing;
  bool get isEnded => status == TripStatus.ended;
  bool get isArchived => status == TripStatus.archived;

  /// 是否在活跃列表中展示（preparing / ongoing / ended 都展示；archived 隐藏）
  bool get isActive =>
      status == TripStatus.preparing ||
      status == TripStatus.ongoing ||
      status == TripStatus.ended;

  Trip copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? destination,
    String? baseCurrency,
    TripStatus? status,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      destination: destination ?? this.destination,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'destination': destination,
        'base_currency': baseCurrency,
        'status': status.dbValue,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}