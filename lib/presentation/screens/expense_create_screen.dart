import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense.dart';
import '../../data/models/member.dart';
import '../providers/expense_provider.dart';
import '../providers/member_provider.dart';
import '../widgets/split_type_selector.dart';

/// 新建费用 - 3 步流程
///
/// 步骤：
///  1) 选择付款人（默认上次付款人）
///  2) 选择类别（10 个内置 + 其他）
///  3) 输入金额（自定义数字键盘）+ 分摊规则选择（W3 / SplitTypeSelector）
///
/// 默认分摊 = 均摊全部成员（W3 / E-003）。
/// W2 hardcode 的"付款人 + 同 group"逻辑被 [SplitTypeSelector] 取代。
class ExpenseCreateScreen extends ConsumerStatefulWidget {
  const ExpenseCreateScreen({
    super.key,
    required this.tripId,
    this.defaultPayerId,
  });

  final String tripId;
  final String? defaultPayerId;

  @override
  ConsumerState<ExpenseCreateScreen> createState() =>
      _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends ConsumerState<ExpenseCreateScreen> {
  int _step = 0; // 0=payer, 1=category, 2=amount
  Member? _payer;
  ExpenseCategory? _category;
  String _amountInput = '';
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  /// 分摊规则选择器的 GlobalKey（用于提交时导出 SplitRule）
  final _splitSelectorKey = GlobalKey<SplitTypeSelectorState>();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountInput) ?? 0.0;
  bool get _canNext => _step != 0 || _payer != null;
  bool get _canSubmit =>
      _payer != null && _category != null && _amount > 0 && !_submitting;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByTripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _StepIndicator(
            current: _step,
            labels: const ['付款人', '类别', '金额'],
          ),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载成员失败：$e')),
        data: (members) {
          if (members.isEmpty) {
            return _NoMemberView(tripId: widget.tripId);
          }
          // 首次进入时设置默认付款人
          if (_payer == null) {
            _initDefaultPayer(members);
          }
          return Column(
            children: [
              Expanded(child: _buildStep(members)),
              _BottomBar(
                canNext: _canNext,
                canSubmit: _canSubmit,
                isLast: _step == 2,
                submitting: _submitting,
                onPrev: _step > 0 ? _prev : null,
                onNext: _step < 2 ? _next : null,
                onSubmit: _submit,
              ),
            ],
          );
        },
      ),
    );
  }

  void _initDefaultPayer(List<Member> members) {
    // 1) 显式 defaultPayerId
    if (widget.defaultPayerId != null) {
      final m = members.firstWhere(
        (m) => m.id == widget.defaultPayerId,
        orElse: () => members.first,
      );
      _payer = m;
      return;
    }
    // 2) 优先取组织者
    final organizer = members.where((m) => m.isOrganizer).toList();
    if (organizer.isNotEmpty) {
      _payer = organizer.first;
      return;
    }
    // 3) 否则第一个成员
    _payer = members.first;
  }

  Widget _buildStep(List<Member> members) {
    switch (_step) {
      case 0:
        return _PayerStep(
          members: members,
          selected: _payer,
          onSelect: (m) => setState(() => _payer = m),
        );
      case 1:
        return _CategoryStep(
          selected: _category,
          onSelect: (c) => setState(() => _category = c),
        );
      case 2:
      default:
        return _AmountStep(
          amount: _amount,
          input: _amountInput,
          descriptionCtrl: _descCtrl,
          members: members,
          tripId: widget.tripId,
          splitSelectorKey: _splitSelectorKey,
          onKey: _onKey,
          onBackspace: _onBackspace,
          onClear: _onClear,
        );
    }
  }

  void _next() {
    if (!_canNext) return;
    setState(() {
      if (_step == 0 && _category == null) {
        // 默认餐饮（最常用）
        _category = ExpenseCategory.food;
      }
      if (_step < 2) _step++;
    });
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  void _onKey(String k) {
    setState(() {
      if (k == '.') {
        if (_amountInput.contains('.')) return;
        if (_amountInput.isEmpty) _amountInput = '0';
        _amountInput += '.';
      } else {
        // 限 2 位小数
        if (_amountInput.contains('.')) {
          final dotIdx = _amountInput.indexOf('.');
          if (_amountInput.length - dotIdx > 2) return;
        }
        // 防 0 开头
        if (_amountInput == '0') {
          _amountInput = k;
        } else {
          _amountInput += k;
        }
      }
    });
  }

  void _onBackspace() {
    if (_amountInput.isEmpty) return;
    setState(() {
      _amountInput = _amountInput.substring(0, _amountInput.length - 1);
    });
  }

  void _onClear() {
    setState(() => _amountInput = '');
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      // 优先使用 SplitTypeSelector（W3）导出的规则
      SplitRule splitRule;
      final selectorState = _splitSelectorKey.currentState;
      if (selectorState != null) {
        final exported = selectorState.exportRule();
        splitRule = exported.rule;
      } else {
        // 退化路径：selector 未构建（不应发生）→ 默认均摊全部成员
        final members =
            ref.read(membersByTripProvider(widget.tripId)).asData?.value ?? [];
        splitRule = SplitRule.equal(members.map((m) => m.id).toList());
      }
      final splitJson = jsonEncode(splitRule.toJson());

      final result = await ref.read(expenseNotifierProvider.notifier).create(
            tripId: widget.tripId,
            payerId: _payer!.id,
            amount: _amount,
            category: _category!,
            splitRuleJson: splitJson,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );

      if (!mounted) return;
      if (result.duplicate != null) {
        final ok = await _confirmDuplicate(result.duplicate!);
        if (ok != true) {
          setState(() => _submitting = false);
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记账成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记账失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool?> _confirmDuplicate(Expense existing) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('检测到相似费用'),
        content: Text(
          '${existing.category.displayName} ${existing.amount.toStringAsFixed(2)} 元 '
          '已存在（同一天 / 同金额 / 同付款人）。\n仍要继续记账吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('仍要记账'),
          ),
        ],
      ),
    );
  }
}

/// 步骤指示器
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels});
  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final passed = i ~/ 2 < current;
            return Expanded(
              child: Container(
                height: 2,
                color: passed
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
              ),
            );
          }
          final idx = i ~/ 2;
          final isActive = idx == current;
          final isDone = idx < current;
          final color = isActive || isDone
              ? Theme.of(context).colorScheme.primary
              : Colors.grey;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[idx],
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// 步骤 1：付款人
class _PayerStep extends StatelessWidget {
  const _PayerStep({
    required this.members,
    required this.selected,
    required this.onSelect,
  });

  final List<Member> members;
  final Member? selected;
  final ValueChanged<Member> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '谁付的款？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        ...members.map((m) {
          final isSel = selected?.id == m.id;
          return Card(
            color: isSel
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  m.nickname.isNotEmpty
                      ? m.nickname[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              title: Text(
                m.nickname,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(m.role.label),
              trailing: isSel
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => onSelect(m),
            ),
          );
        }),
      ],
    );
  }
}

/// 步骤 2：类别
class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.selected, required this.onSelect});
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.95,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: ExpenseCategory.values.length,
      itemBuilder: (context, i) {
        final c = ExpenseCategory.values[i];
        final isSel = c == selected;
        return InkWell(
          onTap: () => onSelect(c),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSel
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isSel
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(
                  c.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 步骤 3：金额 + 自定义数字键盘 + 分摊规则选择（W3）
class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.amount,
    required this.input,
    required this.descriptionCtrl,
    required this.members,
    required this.tripId,
    required this.splitSelectorKey,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
  });

  final double amount;
  final String input;
  final TextEditingController descriptionCtrl;
  final List<Member> members;
  final String tripId;
  final GlobalKey<SplitTypeSelectorState> splitSelectorKey;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '多少钱？',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥ ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (input.isNotEmpty)
                        Text(
                          '已输入：$input',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '例如：晚餐 / 加油 / 酒店',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                // W3：分摊规则选择器
                SplitTypeSelector(
                  key: splitSelectorKey,
                  total: amount,
                  members: members,
                  tripId: tripId,
                ),
              ],
            ),
          ),
        ),
        _NumPad(
          onKey: onKey,
          onBackspace: onBackspace,
          onClear: onClear,
        ),
      ],
    );
  }
}

/// 自定义数字键盘（不用系统键盘）
class _NumPad extends StatelessWidget {
  const _NumPad({
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _keys
              .map(
                (row) => Row(
                  children: row
                      .map(
                        (k) => Expanded(
                          child: _KeyButton(
                            label: k,
                            onTap: () {
                              if (k == 'back') onBackspace();
                              else onKey(k);
                            },
                            onLongPress: k == 'back' ? onClear : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isBack = label == 'back';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: isBack
                ? const Icon(Icons.backspace_outlined)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 底部按钮栏
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canNext,
    required this.canSubmit,
    required this.isLast,
    required this.submitting,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  final bool canNext;
  final bool canSubmit;
  final bool isLast;
  final bool submitting;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            if (onPrev != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrev,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('上一步'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: onPrev == null ? 1 : 1,
              child: FilledButton(
                onPressed: !canNext && !canSubmit
                    ? null
                    : (isLast
                        ? (canSubmit && !submitting ? onSubmit : null)
                        : (canNext ? onNext : null)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isLast ? '保存' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 旅程没有成员时的提示
class _NoMemberView extends StatelessWidget {
  const _NoMemberView({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 96, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '该旅程还没有成员',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '请先在旅程详情中添加成员，再来记账',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
