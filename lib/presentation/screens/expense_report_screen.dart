/// AI 旅行账本 - 费用报告 (ADR-009 Phase 1: 汇总卡 MVP)
///
/// 4 个 section (无 fl_chart 依赖, 纯 ListView + ProgressBar):
/// 1. 总体统计 (总支出 / 笔数 / 人均)
/// 2. 类别占比 (按 ExpenseCategory 分组, 进度条)
/// 3. 成员支出 Top 5 (按 payerId 分组, 降序)
/// 4. 时间趋势 (按天分组, 最近 7 天, 简易柱条)
///
/// 后续阶段 (本次不做):
/// - Phase 2: fl_chart 饼图 / 柱图 / 折线 + PNG 分享 + Excel 导出
/// - Phase 3: AI 总结 (V2.0)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/expense.dart';
import '../../data/models/member.dart';
import '../providers/expense_provider.dart';
import '../providers/member_provider.dart';

class ExpenseReportScreen extends ConsumerWidget {
  const ExpenseReportScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesByTripProvider(tripId));
    final membersAsync = ref.watch(membersByTripProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('费用报告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(expensesByTripProvider(tripId)),
            tooltip: '刷新',
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return _EmptyReport();
          }
          final members = membersAsync.asData?.value ?? const <Member>[];
          return _ReportBody(expenses: expenses, members: members);
        },
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '本旅程还没有费用记录',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '添加费用后再来看报告吧',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.expenses, required this.members});

  final List<Expense> expenses;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverallCard(expenses: expenses, members: members),
        const SizedBox(height: 12),
        _CategoryCard(expenses: expenses),
        const SizedBox(height: 12),
        _MemberCard(expenses: expenses, members: members),
        const SizedBox(height: 12),
        _DailyCard(expenses: expenses),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '📊 ADR-009 Phase 1 MVP · 后续将加饼图/柱图/AI 总结',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

/// 1. 总体统计
class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.expenses, required this.members});
  final List<Expense> expenses;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (a, b) => a + b.amount);
    final perCapita = members.isEmpty ? 0.0 : total / members.length;
    final df = NumberFormat('#,##0.00');

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('总体统计',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _Stat(label: '总支出', value: '¥ ${df.format(total)}')),
                Expanded(
                    child: _Stat(label: '笔数', value: '${expenses.length}')),
                Expanded(
                    child:
                        _Stat(label: '人均', value: '¥ ${df.format(perCapita)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// 2. 类别占比 (按 ExpenseCategory 分组 + 进度条)
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (a, b) => a + b.amount);
    if (total == 0) return const SizedBox.shrink();

    // 按类别分组
    final byCat = <ExpenseCategory, double>{};
    for (final e in expenses) {
      byCat.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final df = NumberFormat('#,##0.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('类别占比',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            for (final entry in sorted)
              _CategoryRow(
                label: entry.key.displayName,
                amount: entry.value,
                total: total,
                color: _categoryColor(entry.key, context),
                df: df,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.df,
  });
  final String label;
  final double amount;
  final double total;
  final Color color;
  final NumberFormat df;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : amount / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13))),
              Text('¥ ${df.format(amount)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. 成员支出 (按 payerId 分组, Top 5)
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.expenses, required this.members});
  final List<Expense> expenses;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (a, b) => a + b.amount);
    if (total == 0 || members.isEmpty) return const SizedBox.shrink();

    // 按付款人分组
    final byMember = <String, double>{};
    for (final e in expenses) {
      byMember.update(e.payerId, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final memberNameById = {for (final m in members) m.id: m.nickname};
    final sorted = byMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    final df = NumberFormat('#,##0.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('谁花得最多 (Top 5)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            for (var i = 0; i < top.length; i++)
              _MemberRow(
                rank: i + 1,
                name: memberNameById[top[i].key] ?? '未知',
                amount: top[i].value,
                total: total,
                df: df,
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.rank,
    required this.name,
    required this.amount,
    required this.total,
    required this.df,
  });
  final int rank;
  final String name;
  final double amount;
  final double total;
  final NumberFormat df;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : amount / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '¥ ${df.format(amount)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. 时间趋势 (按天分组, 最近 7 天, 简易柱条)
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    // 按天分组 (最近 7 天)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      byDay[day] = 0;
    }
    for (final e in expenses) {
      final d =
          DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day);
      if (byDay.containsKey(d)) {
        byDay[d] = (byDay[d] ?? 0) + e.amount;
      }
    }
    final maxAmount = byDay.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxAmount == 0) return const SizedBox.shrink();

    final df = NumberFormat('#,##0.00');
    final dayLabel = DateFormat('M/d');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('最近 7 天',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final entry in byDay.entries) ...[
                    Expanded(
                      child: _DailyBar(
                        label: dayLabel.format(entry.key),
                        amount: entry.value,
                        maxAmount: maxAmount,
                        df: df,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyBar extends StatelessWidget {
  const _DailyBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.df,
  });
  final String label;
  final double amount;
  final double maxAmount;
  final NumberFormat df;

  @override
  Widget build(BuildContext context) {
    final pct = maxAmount == 0 ? 0.0 : amount / maxAmount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisSize.min,
        children: [
          Text(
            amount > 0 ? df.format(amount) : '',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: 100 * pct,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                if (pct == 0)
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// 类别颜色 (10 个类别各分配一个色相)
Color _categoryColor(ExpenseCategory c, BuildContext context) {
  final colors = <ExpenseCategory, Color>{
    ExpenseCategory.food: Colors.orange,
    ExpenseCategory.lodging: Colors.purple,
    ExpenseCategory.transport: Colors.blue,
    ExpenseCategory.fuel: Colors.red,
    ExpenseCategory.toll: Colors.brown,
    ExpenseCategory.parking: Colors.indigo,
    ExpenseCategory.ticket: Colors.pink,
    ExpenseCategory.shopping: Colors.teal,
    ExpenseCategory.entertainment: Colors.amber,
    ExpenseCategory.other: Colors.grey,
  };
  return colors[c] ?? Theme.of(context).colorScheme.primary;
}
