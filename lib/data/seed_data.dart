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
    
    // ========== 场景2: 家庭自驾游 (周末 2 日) ==========
    final trip2 = Trip(
      id: 'trip-demo-002',
      name: '周末千岛湖自驾',
      startDate: DateTime(now.year, now.month - 1, 5),
      endDate: DateTime(now.year, now.month - 1, 6),
      destination: '浙江 杭州',
      baseCurrency: 'CNY',
      status: TripStatus.ended,
      createdBy: 'member-demo-201',
      createdAt: now,
      updatedAt: now,
    );
    final g2 = TripGroup(
      id: 'group-demo-002',
      tripId: trip2.id,
      name: '家庭组',
      groupType: GroupType.family,
      color: '#10B981',
      createdAt: now,
    );
    final dad = Member(id: 'member-demo-201', tripId: trip2.id, nickname: '爸爸', avatarColor: '#3B82F6', role: MemberRole.organizer, groupId: g2.id, joinedAt: now);
    final mom = Member(id: 'member-demo-202', tripId: trip2.id, nickname: '妈妈', avatarColor: '#EC4899', role: MemberRole.member, groupId: g2.id, joinedAt: now);
    final son = Member(id: 'member-demo-203', tripId: trip2.id, nickname: '小明', avatarColor: '#F59E0B', role: MemberRole.member, groupId: g2.id, joinedAt: now);
    final trip2Expenses = <Expense>[
      Expense(id: 'exp-002-001', tripId: trip2.id, payerId: dad.id, amount: 320.0, category: ExpenseCategory.transport, description: '油费 + 过路费', occurredAt: now.subtract(const Duration(days: 30)), createdAt: now, updatedAt: now, splitRuleJson: equalGroup(g2.id)),
      Expense(id: 'exp-002-002', tripId: trip2.id, payerId: mom.id, amount: 480.0, category: ExpenseCategory.food, description: '鱼头餐饮', occurredAt: now.subtract(const Duration(days: 30)), createdAt: now, updatedAt: now, splitRuleJson: equalGroup(g2.id)),
      Expense(id: 'exp-002-003', tripId: trip2.id, payerId: dad.id, amount: 680.0, category: ExpenseCategory.lodging, description: '准四酒店 1 晚', occurredAt: now.subtract(const Duration(days: 30)), createdAt: now, updatedAt: now, splitRuleJson: equalGroup(g2.id)),
      Expense(id: 'exp-002-004', tripId: trip2.id, payerId: son.id, amount: 240.0, category: ExpenseCategory.ticket, description: '千岛湖门票 3 张', occurredAt: now.subtract(const Duration(days: 30)), createdAt: now, updatedAt: now, splitRuleJson: equalGroup(g2.id)),
    ];
    boxes.trips.put(trip2.id, trip2);
    boxes.groups.put(g2.id, g2);
    boxes.members.put(dad.id, dad);
    boxes.members.put(mom.id, mom);
    boxes.members.put(son.id, son);
    for (final e in trip2Expenses) { boxes.expenses.put(e.id, e); }
    
    // ========== 场景3: 公司团建 (按部门分组 + 部分参与) ==========
    final trip3 = Trip(
      id: 'trip-demo-003',
      name: 'Q2 部门团建 (准备中)',
      startDate: DateTime(now.year, now.month + 1, 8),
      endDate: DateTime(now.year, now.month + 1, 9),
      destination: '莫干山民宿',
      baseCurrency: 'CNY',
      status: TripStatus.preparing,
      createdBy: 'member-demo-301',
      createdAt: now,
      updatedAt: now,
    );
    final engGroup = TripGroup(id: 'group-demo-003-eng', tripId: trip3.id, name: '研发部', groupType: GroupType.company, color: '#8B5CF6', createdAt: now);
    final saleGroup = TripGroup(id: 'group-demo-003-sale', tripId: trip3.id, name: '销售部', groupType: GroupType.company, color: '#EF4444', createdAt: now);
    final lead = Member(id: 'member-demo-301', tripId: trip3.id, nickname: 'Leader', avatarColor: '#8B5CF6', role: MemberRole.organizer, groupId: engGroup.id, joinedAt: now);
    final dev1 = Member(id: 'member-demo-302', tripId: trip3.id, nickname: '小陈', avatarColor: '#3B82F6', role: MemberRole.member, groupId: engGroup.id, joinedAt: now);
    final dev2 = Member(id: 'member-demo-303', tripId: trip3.id, nickname: '小赵', avatarColor: '#10B981', role: MemberRole.member, groupId: engGroup.id, joinedAt: now);
    final sale1 = Member(id: 'member-demo-304', tripId: trip3.id, nickname: '小孙', avatarColor: '#EF4444', role: MemberRole.member, groupId: saleGroup.id, joinedAt: now);
    final trip3Expenses = <Expense>[
      Expense(id: 'exp-003-001', tripId: trip3.id, payerId: lead.id, amount: 1280.0, category: ExpenseCategory.lodging, description: '团建民宿订金 (人均 320, 全员}', occurredAt: now.subtract(const Duration(days: 2)), createdAt: now, updatedAt: now, splitRuleJson: equalMembers([lead.id, dev1.id, dev2.id, sale1.id])),
      Expense(id: 'exp-003-002', tripId: trip3.id, payerId: dev1.id, amount: 96.0, category: ExpenseCategory.transport, description: '接驳车拼车', occurredAt: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now, splitRuleJson: equalGroup(engGroup.id)),
    ];
    boxes.trips.put(trip3.id, trip3);
    boxes.groups.put(engGroup.id, engGroup);
    boxes.groups.put(saleGroup.id, saleGroup);
    boxes.members.put(lead.id, lead);
    boxes.members.put(dev1.id, dev1);
    boxes.members.put(dev2.id, dev2);
    boxes.members.put(sale1.id, sale1);
    for (final e in trip3Expenses) { boxes.expenses.put(e.id, e); }
  }
}

String equalGroup(String groupId) {
  return '{"type":"equal","participants":[{"type":"group","id":"' + groupId + '"}]}';
}

String equalMembers(List<String> ids) {
  final parts = ids.map((id) => '{"type":"member","id":"' + id + '"}').join(',');
  return '{"type":"equal","participants":[' + parts + ']}';
}