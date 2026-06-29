import 'models/expense.dart';
import 'models/group.dart';
import 'models/member.dart';
import 'models/transfer_record.dart';
import 'models/trip.dart';
import '../presentation/providers/core_providers.dart';

/// 演示数据 seed（仅在 build 时 --dart-define=SEED=demo 触发）。
class DemoSeed {
  static void apply(HiveBoxes boxes) {
    if (boxes.trips.isNotEmpty) return;
    final now = DateTime.now();
    final trip = Trip(
      id: 'trip-demo-001',
      name: '京都·大阪赏樱 7 日',
      startDate: DateTime(now.year, now.month, now.day - 2),
      endDate: DateTime(now.year, now.month, now.day + 5),
      destination: '日本 关西',
      baseCurrency: 'CNY',
      status: TripStatus.ongoing,
      createdBy: 'member-demo-001',
      createdAt: now,
      updatedAt: now,
    );
    final groupFamily = TripGroup(
      id: 'group-demo-family',
      tripId: trip.id,
      name: '家庭组',
      groupType: GroupType.family,
      color: '#FF6B6B',
      createdAt: now,
    );
    final groupCompany = TripGroup(
      id: 'group-demo-company',
      tripId: trip.id,
      name: '公司组',
      groupType: GroupType.company,
      color: '#4ECDC4',
      createdAt: now,
    );
    final mAlice = Member(
      id: 'member-demo-001',
      tripId: trip.id,
      nickname: 'Alice',
      avatarColor: '#FF6B6B',
      role: MemberRole.organizer,
      groupId: groupFamily.id,
      joinedAt: now,
    );
    final mBob = Member(
      id: 'member-demo-002',
      tripId: trip.id,
      nickname: 'Bob',
      avatarColor: '#FFD93D',
      role: MemberRole.member,
      groupId: groupFamily.id,
      joinedAt: now,
    );
    final mCarol = Member(
      id: 'member-demo-003',
      tripId: trip.id,
      nickname: 'Carol',
      avatarColor: '#4ECDC4',
      role: MemberRole.member,
      groupId: groupCompany.id,
      joinedAt: now,
    );
    final expenses = <Expense>[
      Expense(
        id: 'exp-demo-001',
        tripId: trip.id,
        payerId: mAlice.id,
        amount: 1200.0,
        category: ExpenseCategory.lodging,
        description: '京都塔酒店 2 晚',
        occurredAt: now.subtract(const Duration(days: 1, hours: 4)),
        createdAt: now,
        updatedAt: now,
        splitRuleJson: equalGroup(groupFamily.id),
      ),
      Expense(
        id: 'exp-demo-002',
        tripId: trip.id,
        payerId: mBob.id,
        amount: 480.0,
        category: ExpenseCategory.food,
        description: '居酒屋晚餐',
        occurredAt: now.subtract(const Duration(hours: 6)),
        createdAt: now,
        updatedAt: now,
        splitRuleJson: equalGroup(groupFamily.id),
      ),
      Expense(
        id: 'exp-demo-003',
        tripId: trip.id,
        payerId: mCarol.id,
        amount: 300.0,
        category: ExpenseCategory.transport,
        description: '机场巴士',
        occurredAt: now.subtract(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
        splitRuleJson: equalGroup(groupCompany.id),
      ),
      Expense(
        id: 'exp-demo-004',
        tripId: trip.id,
        payerId: mAlice.id,
        amount: 200.0,
        category: ExpenseCategory.ticket,
        description: '清水寺门票',
        occurredAt: now.subtract(const Duration(hours: 10)),
        createdAt: now,
        updatedAt: now,
        splitRuleJson: equalMembers([mAlice.id, mBob.id, mCarol.id]),
      ),
    ];
    boxes.trips.put(trip.id, trip);
    boxes.groups.put(groupFamily.id, groupFamily);
    boxes.groups.put(groupCompany.id, groupCompany);
    boxes.members.put(mAlice.id, mAlice);
    boxes.members.put(mBob.id, mBob);
    boxes.members.put(mCarol.id, mCarol);
    for (final e in expenses) {
      boxes.expenses.put(e.id, e);
    }
  }
}

String equalGroup(String groupId) {
  return '{"type":"equal","participants":[{"type":"group","id":"' + groupId + '"}]}';
}

String equalMembers(List<String> ids) {
  final parts = ids.map((id) => '{"type":"member","id":"' + id + '"}').join(',');
  return '{"type":"equal","participants":[' + parts + ']}';
}