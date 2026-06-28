import 'dart:convert';

import 'package:hive/hive.dart';

import 'member.dart';

part 'expense.g.dart';

/// 费用类别
@HiveType(typeId: 11)
enum ExpenseCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  lodging,
  @HiveField(2)
  transport,
  @HiveField(3)
  fuel,
  @HiveField(4)
  toll,
  @HiveField(5)
  parking,
  @HiveField(6)
  ticket,
  @HiveField(7)
  shopping,
  @HiveField(8)
  entertainment,
  @HiveField(9)
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return '餐饮';
      case ExpenseCategory.lodging:
        return '住宿';
      case ExpenseCategory.transport:
        return '交通';
      case ExpenseCategory.fuel:
        return '油费';
      case ExpenseCategory.toll:
        return '过路费';
      case ExpenseCategory.parking:
        return '停车费';
      case ExpenseCategory.ticket:
        return '门票';
      case ExpenseCategory.shopping:
        return '购物';
      case ExpenseCategory.entertainment:
        return '娱乐';
      case ExpenseCategory.other:
        return '其他';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.lodging:
        return '🏨';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.fuel:
        return '⛽';
      case ExpenseCategory.toll:
        return '🛣️';
      case ExpenseCategory.parking:
        return '🅿️';
      case ExpenseCategory.ticket:
        return '🎫';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.entertainment:
        return '🎮';
      case ExpenseCategory.other:
        return '📦';
    }
  }
}

/// 同步状态
@HiveType(typeId: 12)
enum SyncStatus {
  @HiveField(0)
  synced,
  @HiveField(1)
  pending,
  @HiveField(2)
  failed,
}

/// 分摊规则（JSON 存储在 splitRule 字段）
/// 类型：equal | ratio | shares | specific
/// 参与者：member_id 或 group_id
class SplitRule {
  final String type;  // equal | ratio | shares | specific
  final List<dynamic> participants;  // [{type: 'group', id: ...} 或 {type: 'member', id: ...}]
  final Map<String, double> values;  // 比例/份数/固定金额

  const SplitRule({
    required this.type,
    required this.participants,
    this.values = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'participants': participants,
        'values': values,
      };

  factory SplitRule.fromJson(Map<String, dynamic> json) => SplitRule(
        type: json['type'] as String,
        participants: json['participants'] as List<dynamic>,
        values: (json['values'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      );

  /// 解析为完整成员 ID 列表（展开组）
  List<String> resolveParticipants(List<Member> allMembers) {
    final result = <String>[];
    for (final p in participants) {
      if (p is String) {
        result.add(p);
      } else if (p is Map) {
        if (p['type'] == 'member') {
          result.add(p['id'] as String);
        } else if (p['type'] == 'group') {
          final groupId = p['id'] as String;
          result.addAll(
            allMembers.where((m) => m.groupId == groupId).map((m) => m.id),
          );
        }
      }
    }
    return result;
  }

  /// 便利工厂：默认均摊（指定若干成员）
  factory SplitRule.equal(List<String> memberIds) => SplitRule(
        type: 'equal',
        participants: memberIds
            .map((id) => <String, dynamic>{'type': 'member', 'id': id})
            .toList(),
      );

  /// 便利工厂：默认均摊整个组
  factory SplitRule.equalGroup(String groupId) => SplitRule(
        type: 'equal',
        participants: <Map<String, dynamic>>[
          <String, dynamic>{'type': 'group', 'id': groupId}
        ],
      );
}

@HiveType(typeId: 4)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String payerId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String currency;

  @HiveField(5)
  ExpenseCategory category;

  @HiveField(6)
  String? description;

  @HiveField(7)
  DateTime occurredAt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  String splitRuleJson;  // 存 SplitRule 的 JSON

  @HiveField(11)
  List<String> attachments;  // 附件 URL 列表

  @HiveField(12)
  SyncStatus syncStatus;

  @HiveField(13)
  DateTime? deletedAt;  // 软删除

  Expense({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.amount,
    this.currency = 'CNY',
    required this.category,
    this.description,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.splitRuleJson,
    this.attachments = const [],
    this.syncStatus = SyncStatus.synced,
    this.deletedAt,
  });

  SplitRule get splitRule {
    try {
      return SplitRule.fromJson(_parseJson(splitRuleJson));
    } catch (_) {
      return const SplitRule(type: 'equal', participants: []);
    }
  }

  set splitRule(SplitRule rule) {
    splitRuleJson = _stringifyJson(rule.toJson());
  }

  static Map<String, dynamic> _parseJson(String s) {
    if (s.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  static String _stringifyJson(Map<String, dynamic> m) {
    return jsonEncode(m);
  }
}
