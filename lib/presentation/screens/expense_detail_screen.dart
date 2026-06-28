import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/member_provider.dart';

/// 费用详情 - 查看 / 编辑 / 删除
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.tripId,
    required this.expenseId,
  });

  final String tripId;
  final String expenseId;

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;

  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  late ExpenseCategory _category;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _category = ExpenseCategory.food;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _initFromExpense(Expense e) {
    _amountCtrl.text = e.amount.toStringAsFixed(2);
    _descCtrl.text = e.description ?? '';
    _category = e.category;
  }

  @override
  Widget build(BuildContext context) {
    final expense = ref.watch(expenseByIdProvider(widget.expenseId));
    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('费用详情')),
        body: const Center(child: Text('费用不存在或已删除')),
      );
    }
    if (!_editing) {
      _initFromExpense(expense);
    }

    final membersAsync = ref.watch(membersByTripProvider(widget.tripId));
    final payerName = membersAsync.maybeWhen(
      data: (m) {
        for (final x in m) {
          if (x.id == expense.payerId) return x.nickname;
        }
        return '?';
      },
      orElse: () => '?',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? '编辑费用' : '费用详情'),
        actions: [
          if (!_editing)
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: _editing ? _buildEdit(expense) : _buildView(expense, payerName),
      bottomNavigationBar: _editing
          ? _EditBottomBar(
              saving: _saving,
              onCancel: () {
                setState(() {
                  _editing = false;
                  _initFromExpense(expense);
                });
              },
              onSave: () => _save(expense),
            )
          : null,
    );
  }

  Widget _buildView(Expense e, String payerName) {
    final df = NumberFormat('#,##0.00');
    final fullDate = DateFormat('yyyy-MM-dd HH:mm').format(e.occurredAt);
    final isDeleted = e.deletedAt != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: isDeleted
              ? Theme.of(context).colorScheme.errorContainer
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(e.category.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text(
                      e.category.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '¥ ${df.format(e.amount)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _InfoRow(icon: Icons.person, label: '付款人', value: payerName),
                _InfoRow(icon: Icons.access_time, label: '时间', value: fullDate),
                if (e.description?.isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.notes,
                    label: '备注',
                    value: e.description!,
                  ),
                _InfoRow(
                  icon: Icons.account_balance_wallet,
                  label: '币种',
                  value: e.currency,
                ),
                if (e.attachments.isNotEmpty)
                  _InfoRow(
                    icon: Icons.attach_file,
                    label: '附件',
                    value: e.attachments.length.toString(),
                  ),
                if (isDeleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '已删除（${DateFormat('yyyy-MM-dd HH:mm').format(e.deletedAt!)}）',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!isDeleted)
          FilledButton.icon(
            onPressed: _deleting ? null : () => _confirmDelete(e),
            icon: _deleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_outline),
            label: const Text('删除'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildEdit(Expense e) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '金额 *',
            prefixText: '¥ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ExpenseCategory>(
          value: _category,
          decoration: const InputDecoration(
            labelText: '类别',
            border: OutlineInputBorder(),
          ),
          items: ExpenseCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Text(c.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(c.displayName),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _category = v);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: '备注',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _save(Expense e) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _snack('请输入有效金额');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(expenseNotifierProvider.notifier).update(
            e.id,
            amount: amount,
            category: _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (mounted) {
        _snack('已保存');
        setState(() => _editing = false);
      }
    } catch (err) {
      if (mounted) _snack('保存失败：$err');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除费用'),
        content: const Text('确定要删除这条费用吗？删除后可在历史中查看。'),
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
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(expenseNotifierProvider.notifier).delete(e.id);
      if (mounted) {
        _snack('已删除');
        Navigator.pop(context, true);
      }
    } catch (err) {
      if (mounted) _snack('删除失败：$err');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text('$label：', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EditBottomBar extends StatelessWidget {
  const _EditBottomBar({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
