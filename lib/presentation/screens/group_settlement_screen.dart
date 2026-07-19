import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../../domain/services/settlement_engine.dart';
import '../providers/group_provider.dart';
import '../providers/member_provider.dart';
import '../providers/settlement_provider.dart';

/// 按组粒度结算页（v0.3 独家）
///
/// - 顶部：每个组的净收支
/// - 下部：组间转账列表
/// - 点击组展开：组内成员明细
class GroupSettlementScreen extends ConsumerWidget {
  const GroupSettlementScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider(tripId));
    final membersAsync = ref.watch(membersByTripProvider(tripId));
    final groupsAsync = ref.watch(groupsByTripProvider(tripId));
    final groupTransfersAsync = ref.watch(groupTransfersProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('按组结算'),
      ),
      body: Builder(builder: (context) {
        // [PR-X4 修复 M-1] 3 层 when 重构为扁平化 + 短路逻辑
        // 任一 loading/error 独立处理,行为保持一致
        if (settlementAsync.isLoading ||
            membersAsync.isLoading ||
            groupsAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (settlementAsync.hasError) {
          return Center(child: Text('加载失败：${settlementAsync.error}'));
        }
        if (membersAsync.hasError) {
          return Center(child: Text('加载成员失败：${membersAsync.error}'));
        }
        if (groupsAsync.hasError) {
          return Center(child: Text('加载分组失败：${groupsAsync.error}'));
        }
        return _GroupSettlementView(
          settlement: settlementAsync.requireValue,
          members: membersAsync.requireValue,
          groups: groupsAsync.requireValue,
          groupTransfers: groupTransfersAsync,
        );
      }),
    );
  }
}

class _GroupSettlementView extends StatelessWidget {
  const _GroupSettlementView({
    required this.settlement,
    required this.members,
    required this.groups,
    required this.groupTransfers,
  });

  final TripSettlement settlement;
  final List<Member> members;
  final List<TripGroup> groups;
  final List<Transfer> groupTransfers;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');

    // 组间转账（from/to 是 groupId）
    final groupMap = {for (final g in groups) g.id: g};
    final groupNameOf = (String? gid) {
      if (gid == null || gid == 'ungrouped') return '未分组';
      return groupMap[gid]?.name ?? gid;
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 顶部说明
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.group_work_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '按组聚合结算：把每个成员余额累加到所属组，得到组级别的净收支和组间转账',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 每个组的卡片
        const Text(
          '各组净收支',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...settlement.groups.map(
          (gs) => _GroupCard(
            groupSettlement: gs,
            members: members,
          ),
        ),
        const SizedBox(height: 24),

        // 组间转账
        if (groupTransfers.isNotEmpty) ...[
          const Text(
            '组间最优转账',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '组与组之间的资金流动（组内已自平衡）',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...groupTransfers.asMap().entries.map((e) {
                    final t = e.value;
                    final isUngrouped =
                        t.fromId == 'ungrouped' || t.toId == 'ungrouped';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor:
                            isUngrouped ? Colors.grey[200] : Colors.indigo[100],
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            color: isUngrouped ? Colors.grey : Colors.indigo,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              groupNameOf(t.fromId),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(groupNameOf(t.toId)),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '¥ ${df.format(t.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      groups.isEmpty ? '该旅程暂无分组' : '所有组之间已平衡',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.groupSettlement,
    required this.members,
  });

  final GroupSettlement groupSettlement;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');
    final balance = groupSettlement.balance;
    final isCreditor = balance > 0.005;
    final isDebtor = balance < -0.005;
    final isBalanced = !isCreditor && !isDebtor;

    // 组内成员
    final groupMembers =
        members.where((m) => groupSettlement.memberIds.contains(m.id)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  groupSettlement.groupId == 'ungrouped'
                      ? Icons.help_outline
                      : Icons.group_work,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groupSettlement.groupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCreditor
                        ? Colors.green[100]
                        : isDebtor
                            ? Colors.red[100]
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isBalanced
                        ? '已平衡'
                        : '${isCreditor ? '+' : ''}¥ ${df.format(balance)}',
                    style: TextStyle(
                      color: isCreditor
                          ? Colors.green
                          : isDebtor
                              ? Colors.red
                              : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 组内成员
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: groupMembers
                  .map(
                    (m) => Chip(
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor: _parseColor(m.avatarColor) ??
                            Theme.of(context).colorScheme.primary,
                        child: Text(
                          m.nickname.isNotEmpty
                              ? m.nickname[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                      label: Text(m.nickname,
                          style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final v = hex.replaceFirst('#', '');
  if (v.length != 6) return null;
  return Color(int.parse('FF$v', radix: 16));
}
