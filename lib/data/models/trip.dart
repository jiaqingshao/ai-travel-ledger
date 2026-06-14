import 'package:hive/hive.dart';

part 'trip.g.dart';

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

  @HiveField(6)
  String status;  // active | archived

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
    this.status = 'active',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';

  Trip copyWith({
    String? name,
    DateTime? endDate,
    String? destination,
    String? status,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      destination: destination ?? this.destination,
      baseCurrency: baseCurrency,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
