import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/attachment.dart';
import '../../data/models/expense.dart';
import '../../data/models/member.dart';
import '../providers/expense_provider.dart';
import '../providers/member_provider.dart';
import '../widgets/attachment_picker_section.dart';
import '../widgets/attachment_thumb.dart';
import '../widgets/attachment_viewer.dart';
import '../widgets/split_type_selector.dart' show SplitRuleExport;
import 'split_rule_edit_page.dart';

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
  // ISSUE-024: 编辑付款人 + 时间
  String? _editingPayerId;
  late DateTime _editingOccurredAt;
  // V1.1: 编辑分摊规则 + 附件
  String? _editingSplitRuleJson;
  // ISSUE-026 step 2: 附件改为 Attachment 对象列表（保留元数据）
  late List<Attachment> _editingAttachments;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _category = ExpenseCategory.food;
    _editingPayerId = null;
    _editingOccurredAt = DateTime.now();
    _editingSplitRuleJson = null;
    _editingAttachments = [];
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // [PR-X3 加固 S-12] 用 addPostFrameCallback 避免在 build/回调中同步 mutate state
  // 当前调用点 (line 115, 148) 不在 build 里, 但未来重构时加一道防线
  void _initFromExpense(Expense e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _descCtrl.text = e.description ?? '';
      _category = e.category;
      _editingPayerId = e.payerId;
      _editingOccurredAt = e.occurredAt;
      _editingSplitRuleJson = e.splitRuleJson;
      // ISSUE-026 step 2: 从 URL 列表重建 Attachment（仅用于预览, 元数据无)
      _editingAttachments = e.attachments
          .where((u) => u.isNotEmpty)
          .map((u) => Attachment(
                url: u,
                fileName: _fileNameFromUrl(u),
                sizeBytes: 0,
                mimeType: _mimeFromUrl(u),
                uploadedAt: '',
              ))
          .toList();
    });
  }

  static String _fileNameFromUrl(String url) {
    final last =
        url.contains('/') ? url.substring(url.lastIndexOf('/') + 1) : url;
    return last.isEmpty ? url : last;
  }

  static String _mimeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return 'image/jpeg';
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    // ISSUE-042: expenseByIdProvider 改为 StreamProvider.autoDispose.family,
    // 现在是 AsyncValue<Expense?>, 用 .when 处理 3 个状态
    final expenseAsync = ref.watch(expenseByIdProvider(widget.expenseId));
    final expense = expenseAsync.maybeWhen(
      data: (e) => e,
      orElse: () => null,
    );
    if (expenseAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('费用详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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
          color:
              isDeleted ? Theme.of(context).colorScheme.errorContainer : null,
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
    final membersAsync = ref.watch(membersByTripProvider(widget.tripId));
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currentDateLabel = dateFormat.format(_editingOccurredAt);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // [PR-X1 修复 S-23] 限 2 位小数 + 数字格式
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
          ],
          decoration: const InputDecoration(
            labelText: '金额 *',
            prefixText: '¥ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // ISSUE-024: 付款人选择
        membersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text('加载成员失败: $err'),
          data: (members) {
            final payerName = _findPayerName(members, _editingPayerId);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('付款人'),
                subtitle: Text(payerName ?? '未选择'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPayerPicker(members),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // ISSUE-024: 时间选择
        Card(
          child: ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('时间'),
            subtitle: Text(currentDateLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDateTimePicker,
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
        const SizedBox(height: 16),
        // V1.1: 分摊规则编辑
        _buildSplitRuleTile(membersAsync.value ?? const []),
        const SizedBox(height: 16),
        // V1.1: 附件编辑
        _buildAttachmentsSection(),
      ],
    );
  }

  // V1.1: 分摊规则编辑入口
  Widget _buildSplitRuleTile(List<Member> members) {
    final hasRule =
        _editingSplitRuleJson != null && _editingSplitRuleJson!.isNotEmpty;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pie_chart_outline),
        title: const Text('分摊规则'),
        subtitle: Text(
          hasRule ? '已设置 (点击修改)' : '默认均摊 (点击设置)',
          style: TextStyle(
            color:
                hasRule ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: members.isEmpty ? null : () => _openSplitRuleEditor(members),
      ),
    );
  }

  Future<void> _openSplitRuleEditor(List<Member> members) async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      _snack('请先输入有效金额');
      return;
    }
    final result = await Navigator.push<SplitRuleExport>(
      context,
      MaterialPageRoute(
        builder: (_) => SplitRuleEditPage(
          total: amount,
          members: members,
          tripId: widget.tripId,
          initialSplitRuleJson: _editingSplitRuleJson,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _editingSplitRuleJson = jsonEncode(result.rule.toJson());
      });
    }
  }

  // ISSUE-026 step 2: 附件管理 (拍照/选图模式)
  Widget _buildAttachmentsSection() {
    if (!_editing) {
      // 只读模式：显示缩略图列表 + 点击全屏预览
      return _buildReadOnlyAttachments();
    }
    // 编辑模式：使用 AttachmentPickerSection (受控)
    return AttachmentPickerSection(
      tripId: widget.tripId,
      expenseId: widget.expenseId,
      attachments: _editingAttachments,
      onChanged: (list) => setState(() => _editingAttachments = list),
    );
  }

  Widget _buildReadOnlyAttachments() {
    if (_editingAttachments.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 8),
                const Text(
                  '附件',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${_editingAttachments.length} 张',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _editingAttachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final a = _editingAttachments[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AttachmentThumb(
                      attachment: a,
                      onTap: () => _openAttachmentViewer(idx),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAttachmentViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttachmentViewer(
          attachments:
              _editingAttachments.where((a) => a.url.isNotEmpty).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // V1.1: 附件管理 - URL 输入模式已废弃 (ISSUE-026 step 2 改为拍照/选图)
// [PR-5 修复 V2-1] 删除 _addAttachment stub 函数
// 原因: 实际代码里没人调用, 留着会让维护者误以为是"还在用的旧代码"
// 替代方案: 使用 AttachmentPickerSection widget (lib/presentation/widgets/attachment_picker_section.dart)

  // ISSUE-024: 付款人选择弹窗
  Future<void> _showPayerPicker(List<Member> members) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择付款人'),
        children: members
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, m.id),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          m.nickname.isNotEmpty
                              ? m.nickname[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(m.nickname),
                      if (m.id == _editingPayerId) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() => _editingPayerId = selected);
    }
  }

  // ISSUE-024: 日期 + 时间选择
  Future<void> _showDateTimePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _editingOccurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(_editingOccurredAt),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _editingOccurredAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String? _findPayerName(List<Member> members, String? payerId) {
    if (payerId == null) return null;
    for (final m in members) {
      if (m.id == payerId) return m.nickname;
    }
    return null;
  }

  Future<void> _save(Expense e) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _snack('请输入有效金额');
      return;
    }
    if (_editingPayerId == null) {
      _snack('请选择付款人');
      return;
    }
    setState(() => _saving = true);
    try {
      // ISSUE-024 + V1.1: 包含 payerId + occurredAt + splitRuleJson + attachments
      await ref.read(expenseNotifierProvider.notifier).update(
            e.id,
            payerId: _editingPayerId,
            amount: amount,
            category: _category,
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            occurredAt: _editingOccurredAt,
            splitRuleJson: _editingSplitRuleJson,
            attachments: _editingAttachments
                .where((a) => a.url.isNotEmpty)
                .map((a) => a.url)
                .toList(),
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
