import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/member.dart';
import '../../domain/services/settlement_engine.dart';
import '../providers/member_provider.dart';
import '../providers/settlement_provider.dart';
import 'group_settlement_screen.dart';

/// 个人粒度结算页
///
/// - 顶部：摘要（总支出 / 人均 / 最高应收应付 / 已结清）
/// - 中部：每人净收支列表
/// - 下部：最优转账建议 + 标记已结算按钮
class SettlementScreen extends ConsumerWidget {
  const SettlementScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider(tripId));
    final membersAsync = ref.watch(membersByTripProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('结算'),
        actions: [
          IconButton(
            tooltip: '按组结算',
            icon: const Icon(Icons.group_work_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupSettlementScreen(tripId: tripId),
                ),
              );
            },
          ),
        ],
      ),
      body: settlementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (settlement) {
          if (settlement.memberCount == 0) {
            return const _EmptyView();
          }
          // ISSUE-020: 即使 isBalanced 也显示完整余额和转账信息
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载成员失败：$e')),
            data: (members) {
              // 人数为空时显示空状态
              if (members.isEmpty) {
                return _EmptyView(settlement: settlement);
              }
              return _SettlementView(
                settlement: settlement,
                members: members,
                tripId: tripId,
              );
            },
          );
        },
      ),
    );
  }
}

/// 摘要卡片（总支出 / 人均 / 最高 / 最低）
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.settlement});
  final TripSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');
    final maxCr = settlement.maxCreditor;
    final maxDb = settlement.maxDebtor;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '结算总览',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (settlement.totalAmount == 0) ...[
              // ISSUE-029 修复：暂无费用时显示提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '本旅程还未记录任何费用,先添加一笔吧',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                    child:
                        _Stat('总支出', '¥ ${df.format(settlement.totalAmount)}')),
                Expanded(
                  child: _Stat(
                    '人均',
                    '¥ ${df.format(settlement.perCapita)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    '最高应收',
                    maxCr == null ? '—' : '¥ ${df.format(maxCr.amount)}',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    '最高应付',
                    maxDb == null ? '—' : '¥ ${df.format(maxDb.amount.abs())}',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${settlement.memberCount} 位成员 · ${settlement.transfers.length} 笔转账',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 个人净收支列表
class _BalancesCard extends StatelessWidget {
  const _BalancesCard({
    required this.balances,
    required this.members,
  });

  final Map<String, double> balances;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');
    final sortedEntries = balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ISSUE-029 修复：balances 为空时显示友好提示
    if (sortedEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                '暂无费用记录',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '添加费用后,这里会显示每人净收支',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '每人净收支',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...sortedEntries.map((entry) {
              final m = _findMember(members, entry.key);
              final isCreditor = entry.value > 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _parseColor(m?.avatarColor) ??
                      Theme.of(context).colorScheme.primary,
                  child: Text(
                    (m?.nickname ?? '?').isNotEmpty
                        ? m!.nickname[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(m?.nickname ?? entry.key),
                trailing: Text(
                  '${isCreditor ? '+' : ''}¥ ${df.format(entry.value)}',
                  style: TextStyle(
                    color: isCreditor ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Member? _findMember(List<Member> members, String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// 转账建议卡片（含标记已结算按钮）
class _TransfersCard extends ConsumerWidget {
  const _TransfersCard({
    required this.transfers,
    required this.members,
    required this.tripId,
  });

  final List<Transfer> transfers;
  final List<Member> members;
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '最优转账',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${transfers.length} 笔',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '按贪心算法（最大债权人 + 最大债务人配对）',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ...transfers.asMap().entries.map((e) => _TransferTile(
                  transfer: e.value,
                  members: members,
                  tripId: tripId,
                  index: e.key,
                )),
          ],
        ),
      ),
    );
  }
}

class _TransferTile extends ConsumerWidget {
  const _TransferTile({
    required this.transfer,
    required this.members,
    required this.tripId,
    required this.index,
  });

  final Transfer transfer;
  final List<Member> members;
  final String tripId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = NumberFormat('#,##0.00');
    final from = _findMember(members, transfer.fromId);
    final to = _findMember(members, transfer.toId);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: Text('${index + 1}',
            style: const TextStyle(color: Colors.orange, fontSize: 13)),
      ),
      title: Row(
        children: [
          Expanded(child: Text(from?.nickname ?? transfer.fromId)),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(to?.nickname ?? transfer.toId)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¥ ${df.format(transfer.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            tooltip: '标记已结清',
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _confirmMarkSettled(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMarkSettled(BuildContext context, WidgetRef ref) async {
    final df = NumberFormat('#,##0.00');
    final from = _findMember(members, transfer.fromId);
    final to = _findMember(members, transfer.toId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('标记已结清'),
        content: Text(
          '${from?.nickname ?? transfer.fromId} → ${to?.nickname ?? transfer.toId}\n金额：¥ ${df.format(transfer.amount)}\n\n确认已结清？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(settlementNotifierProvider.notifier).markSettled(
              tripId: tripId,
              fromMemberId: transfer.fromId,
              toMemberId: transfer.toId,
              amount: transfer.amount,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已标记为结清')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('标记失败：$e')),
          );
        }
      }
    }
  }

  Member? _findMember(List<Member> members, String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// 主视图
class _SettlementView extends StatelessWidget {
  const _SettlementView({
    required this.settlement,
    required this.members,
    required this.tripId,
  });

  final TripSettlement settlement;
  final List<Member> members;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(settlement: settlement),
        const SizedBox(height: 16),
        _BalancesCard(balances: settlement.balances, members: members),
        const SizedBox(height: 16),
        if (settlement.transfers.isNotEmpty)
          _TransfersCard(
            transfers: settlement.transfers,
            members: members,
            // [PR-4 修复 S-7] 空成员列表守卫 - 避免 members.first.tripId 在空列表上崩溃
            tripId: members.isNotEmpty ? members.first.tripId : tripId,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// 平衡态视图（所有人都已结清）
class _BalancedView extends StatelessWidget {
  const _BalancedView({required this.settlement});
  final TripSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 96, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              '所有账目已结清！',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '总支出 ¥ ${df.format(settlement.totalAmount)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${settlement.memberCount} 位成员已平账',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态（无成员 或 无人数据）
class _EmptyView extends StatelessWidget {
  const _EmptyView({this.settlement});
  final TripSettlement? settlement;

  @override
  Widget build(BuildContext context) {
    final s = settlement;
    final df = NumberFormat('#,##0.00');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 96, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '尚未添加成员',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '请先在旅程中添加成员、记录费用',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            // ISSUE-020: 如果有总额但无成员，显示提示
            if (s != null && s.totalAmount > 0) ...[
              const SizedBox(height: 16),
              Text(
                '总费用：¥ ${df.format(s.totalAmount)}',
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            ],
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
