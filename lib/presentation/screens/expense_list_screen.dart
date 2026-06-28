import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/expense.dart';
import '../../data/models/member.dart';
import '../providers/expense_provider.dart';
import '../providers/member_provider.dart';
import 'expense_create_screen.dart';
import 'expense_detail_screen.dart';

/// 费用列表（某旅程下）
///
/// - 按 occurredAt 倒序
/// - 顶部按类别筛选 chips
/// - 底部显示总金额
/// - FAB → 新建
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  ExpenseCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesByTripProvider(widget.tripId));
    final membersAsync = ref.watch(membersByTripProvider(widget.tripId));
    final totalAsync = ref.watch(totalByTripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('账本'),
      ),
      body: Column(
        children: [
          _SummaryBar(
            total: totalAsync.maybeWhen(
              data: (v) => v,
              orElse: () => 0.0,
            ),
            count: expensesAsync.maybeWhen(
              data: (l) => l.length,
              orElse: () => null,
            ),
          ),
          _CategoryFilter(
            selected: _filter,
            onSelect: (c) => setState(() => _filter = c),
          ),
          const Divider(height: 1),
          Expanded(
            child: expensesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (list) {
                final filtered = _filter == null
                    ? list
                    : list.where((e) => e.category == _filter).toList();
                if (filtered.isEmpty) {
                  return _EmptyView(
                    hasFilter: _filter != null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return _ExpenseTile(
                      expense: e,
                      payerName: membersAsync.maybeWhen(
                        data: (m) => _findPayerName(m, e.payerId),
                        orElse: () => null,
                      ),
                      onTap: () => _openDetail(e),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }

  String? _findPayerName(List<Member> members, String payerId) {
    for (final m in members) {
      if (m.id == payerId) return m.nickname;
    }
    return null;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseCreateScreen(tripId: widget.tripId),
      ),
    );
    if (created == true) {
      ref.invalidate(expensesByTripProvider(widget.tripId));
    }
  }

  Future<void> _openDetail(Expense e) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          tripId: widget.tripId,
          expenseId: e.id,
        ),
      ),
    );
    if (changed == true) {
      ref.invalidate(expensesByTripProvider(widget.tripId));
    }
  }
}

/// 顶部汇总条
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.total, required this.count});
  final double total;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '总支出',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥ ${df.format(total)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  count != null ? '$count 笔' : '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 类别筛选 chips
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelect});
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _FilterChipWidget(
            label: '全部',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...ExpenseCategory.values.map(
            (c) => _FilterChipWidget(
              label: '${c.icon} ${c.displayName}',
              selected: c == selected,
              onTap: () => onSelect(c),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// 单条费用
class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.payerName,
    required this.onTap,
  });

  final Expense expense;
  final String? payerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat('#,##0.00');
    final dateLabel = DateFormat('MM-dd HH:mm').format(expense.occurredAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer,
        child: Text(expense.category.icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        expense.description?.isNotEmpty == true
            ? expense.description!
            : expense.category.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$dateLabel · ${payerName ?? "?"} 付'),
      trailing: Text(
        '¥ ${df.format(expense.amount)}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.filter_alt_off_outlined : Icons.receipt_long,
              size: 96,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? '该类别下没有费用' : '还没有记账',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter ? '试试切换其他类别' : '点击右下角按钮开始记账',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
