import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../../data/models/trip.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../providers/member_provider.dart';
import '../providers/trip_provider.dart';
import 'expense_list_screen.dart';
import 'group_manage_screen.dart';
import 'member_manage_screen.dart';
import 'settlement_screen.dart';
import 'trip_edit_screen.dart';

/// 旅程详情 / Dashboard
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripByIdProvider(tripId));
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('旅程详情')),
        body: const Center(child: Text('旅程不存在或已删除')),
      );
    }

    final membersAsync = ref.watch(membersByTripProvider(tripId));
    final groupsAsync = ref.watch(groupsByTripProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        actions: [
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TripEditScreen(tripId: tripId),
                ),
              );
              if (updated == true) ref.invalidate(tripByIdProvider(tripId));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'archive') {
                await ref.read(tripNotifierProvider.notifier).archive(tripId);
                if (context.mounted) Navigator.pop(context, true);
              } else if (v == 'delete') {
                final ok = await _confirmDelete(context, trip);
                if (ok == true) {
                  await ref.read(tripNotifierProvider.notifier).delete(tripId);
                  if (context.mounted) Navigator.pop(context, true);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('归档'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TripInfoCard(trip: trip),
          const SizedBox(height: 16),
          _FinancialSummary(tripId: tripId),
          const SizedBox(height: 16),
          _SectionCard(
            title: '成员',
            icon: Icons.people_outline,
            count: membersAsync.maybeWhen(
              data: (list) => list.length,
              orElse: () => null,
            ),
            onMore: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberManageScreen(tripId: tripId),
                ),
              );
            },
            child: membersAsync.when(
              loading: () =>
                  const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              error: (e, _) => Text('加载失败：$e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无成员', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: list
                      .take(5)
                      .map((m) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _parseColor(m.avatarColor) ??
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                m.nickname.isNotEmpty
                                    ? m.nickname[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            title: Text(m.nickname),
                            subtitle: Text(m.role.label),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '分组',
            icon: Icons.group_work_outlined,
            count: groupsAsync.maybeWhen(
              data: (list) => list.length,
              orElse: () => null,
            ),
            onMore: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupManageScreen(tripId: tripId),
                ),
              );
            },
            child: groupsAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              error: (e, _) => Text('加载失败：$e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无分组', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: list
                      .take(5)
                      .map((g) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Text(g.icon, style: const TextStyle(fontSize: 20)),
                            title: Text(g.name),
                            subtitle: Text(g.groupType.displayName),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _ExpenseEntryCard(tripId: tripId),
          const SizedBox(height: 16),
          _SettlementEntryCard(tripId: tripId),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Trip trip) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除旅程'),
        content: Text('确定要删除「${trip.name}」吗？所有成员和分组也会被删除，且无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final v = hex.replaceFirst('#', '');
    if (v.length != 6) return null;
    return Color(int.parse('FF$v', radix: 16));
  }
}

/// 财务概览卡片 - 绿色渐变,总费用/笔数/人均
class _FinancialSummary extends ConsumerWidget {
  const _FinancialSummary({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesByTripProvider(tripId));
    final membersAsync = ref.watch(membersByTripProvider(tripId));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                '费用概览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          expensesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('加载失败：$e',
                style: const TextStyle(color: Colors.white)),
            data: (expenses) {
              final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
              final memberCount = membersAsync.maybeWhen(
                data: (m) => m.length,
                orElse: () => 0,
              );
              final perPerson = memberCount > 0 ? total / memberCount : 0.0;
              // ISSUE-026 step 4: 附件总数 = 所有费用 attachments.length 求和
              final attachmentCount = expenses.fold<int>(
                  0, (sum, e) => sum + e.attachments.length);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FinanceStat(
                    label: '总费用',
                    value: '¥${total.toStringAsFixed(2)}',
                    large: true,
                  ),
                  _FinanceDivider(),
                  _FinanceStat(
                    // 笔数 / 附件 (ISSUE-026 step 4: 附件统计)
                    label: '笔数',
                    value: '${expenses.length}',
                    large: true,
                  ),
                  _FinanceDivider(),
                  _FinanceStat(
                    // 原人均 + 附件数二选一 (冗余信息会压缩, 这里取人均)
                    label: '人均',
                    value: '¥${perPerson.toStringAsFixed(2)}',
                    large: true,
                  ),
                ],
              );
            },
          ),
          if (expensesAsync.maybeWhen(
            data: (l) => l.fold<int>(0, (s, e) => s + e.attachments.length),
            orElse: () => 0,
          ) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '本旅程 ${expensesAsync.maybeWhen(data: (l) => l.fold<int>(0, (s, e) => s + e.attachments.length), orElse: () => 0)} 张附件',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // 快速入口
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseListScreen(tripId: tripId),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF10B981),
                  ),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('所有费用'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettlementScreen(tripId: tripId),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF10B981),
                  ),
                  icon: const Icon(Icons.balance, size: 18),
                  label: const Text('查看结算'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  const _FinanceStat({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: large ? 16 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FinanceDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final dateRange = trip.endDate != null
        ? '${df.format(trip.startDate)} → ${df.format(trip.endDate!)}'
        : df.format(trip.startDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flight_takeoff,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusBadge(status: trip.status),
              ],
            ),
            const SizedBox(height: 12),
            if (trip.destination != null && trip.destination!.isNotEmpty)
              _InfoRow(icon: Icons.place, label: '目的地', value: trip.destination!),
            _InfoRow(icon: Icons.calendar_today, label: '日期', value: dateRange),
            _InfoRow(icon: Icons.attach_money, label: '基础币种', value: trip.baseCurrency),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label：', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == TripStatus.ongoing
        ? Colors.green
        : status == TripStatus.preparing
            ? Colors.orange
            : status == TripStatus.ended
                ? Colors.grey
                : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.count,
    this.onMore,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final int? count;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
                const Spacer(),
                if (onMore != null)
                  TextButton.icon(
                    onPressed: onMore,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('管理'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExpenseEntryCard extends ConsumerWidget {
  const _ExpenseEntryCard({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalByTripProvider(tripId));
    final total = totalAsync.maybeWhen(
      data: (v) => v,
      orElse: () => 0.0,
    );
    final df = NumberFormat('#,##0.00');
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseListScreen(tripId: tripId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '账本',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总支出 ¥ ${df.format(total)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// 结算入口卡片（接入 SettlementScreen）
class _SettlementEntryCard extends ConsumerWidget {
  const _SettlementEntryCard({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettlementScreen(tripId: tripId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calculate_outlined, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '结算',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '最优转账建议 · 标记已结清',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}