import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/expense.dart';
import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../../data/models/transfer_record.dart';
import '../../data/models/trip.dart';

/// 集中管理 Hive Boxes。
///
/// **Override 由 main.dart 在启动时注入**（已打开的 boxes）。
/// 不允许在此处 `openBox`：测试场景需要可控。
class HiveBoxes {
  HiveBoxes({
    required this.trips,
    required this.members,
    required this.groups,
    required this.expenses,
    required this.transferRecords,
  });

  final Box<Trip> trips;
  final Box<Member> members;
  final Box<TripGroup> groups;
  final Box<Expense> expenses;
  final Box<TransferRecord> transferRecords;
}

final hiveBoxesProvider = Provider<HiveBoxes>((ref) {
  throw UnimplementedError(
    'hiveBoxesProvider 必须在 main.dart 中用 override 提供已打开的 Hive boxes。',
  );
});