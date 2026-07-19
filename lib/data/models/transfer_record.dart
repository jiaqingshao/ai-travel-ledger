import 'package:hive/hive.dart';

part 'transfer_record.g.dart';

/// 已结算转账记录（"我已收款" / "我已付款"）
///
/// - 业务语义：当用户标记某笔转账已结清，落地一条 TransferRecord
/// - settlement 视图会过滤掉对应金额的 transfer（让"还剩多少"准确）
/// - 这是单独的 Hive 实体，不依附于 Expense（因为 Expense 是费用，不是债务）
///
/// 字段：
/// - id：UUID
/// - tripId：所属旅程
/// - fromMemberId：付款人（应付方）
/// - toMemberId：收款人（应收方）
/// - amount：金额（保留 2 位小数）
/// - settledAt：结算时间
/// - note：备注（可选，如"微信转账"）
@HiveType(typeId: 14)
class TransferRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String fromMemberId;

  @HiveField(3)
  String toMemberId;

  @HiveField(4)
  double amount;

  @HiveField(5)
  DateTime settledAt;

  @HiveField(6)
  String? note;

  TransferRecord({
    required this.id,
    required this.tripId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.settledAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'from_member_id': fromMemberId,
        'to_member_id': toMemberId,
        'amount': amount,
        'settled_at': settledAt.toIso8601String(),
        'note': note,
      };
}
