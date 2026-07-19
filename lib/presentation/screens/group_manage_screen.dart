import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../providers/group_provider.dart';
import '../providers/member_provider.dart';

/// 分组管理页面
class GroupManageScreen extends ConsumerWidget {
  const GroupManageScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsByTripProvider(tripId));
    final membersAsync = ref.watch(membersByTripProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('分组管理')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (groups) {
          final allMembers = membersAsync.maybeWhen(
            data: (m) => m,
            orElse: () => const <Member>[],
          );
          if (groups.isEmpty) {
            return _EmptyView(onAdd: () => _showAddSheet(context, ref));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: groups.map((g) {
              final members =
                  allMembers.where((m) => m.groupId == g.id).toList();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ExpansionTile(
                  leading: Text(g.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(g.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      Text('${g.groupType.displayName} · ${members.length} 人'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _showEditSheet(context, ref, g);
                      } else if (v == 'delete') {
                        await _confirmDelete(context, ref, g, members.length);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    if (members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('该组暂无成员',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...members.map((m) => ListTile(
                            dense: true,
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
                          )),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建分组'),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _GroupEditorSheet(tripId: tripId),
      ),
    );
  }

  Future<void> _showEditSheet(
      BuildContext context, WidgetRef ref, TripGroup g) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _GroupEditorSheet(tripId: tripId, existing: g),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TripGroup g, int memberCount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除分组'),
        content: Text(memberCount > 0
            ? '「${g.name}」下还有 $memberCount 个成员，删除后这些成员将变为未分组状态。确定吗？'
            : '确定要删除「${g.name}」吗？'),
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
    if (ok == true) {
      // 先把组内成员移到未分组
      if (memberCount > 0) {
        final members =
            ref.read(memberRepositoryProvider).listByGroup(tripId, g.id);
        for (final m in members) {
          await ref
              .read(memberNotifierProvider.notifier)
              .assignToGroup(m.id, null);
        }
      }
      await ref.read(groupNotifierProvider.notifier).delete(g.id);
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final v = hex.replaceFirst('#', '');
    if (v.length != 6) return null;
    return Color(int.parse('FF$v', radix: 16));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_work_outlined, size: 96, color: Colors.grey),
            const SizedBox(height: 24),
            Text('还没有分组', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('把成员分成家庭、部门或队伍，方便分摊',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('创建第一个分组'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分组编辑表单
class _GroupEditorSheet extends ConsumerStatefulWidget {
  const _GroupEditorSheet({required this.tripId, this.existing});
  final String tripId;
  final TripGroup? existing;

  @override
  ConsumerState<_GroupEditorSheet> createState() => _GroupEditorSheetState();
}

class _GroupEditorSheetState extends ConsumerState<_GroupEditorSheet> {
  late final TextEditingController _nameCtrl;
  late GroupType _type;
  late String _color;
  bool _submitting = false;

  static const _colors = [
    '#2E7D32',
    '#1976D2',
    '#D32F2F',
    '#7B1FA2',
    '#F57C00',
    '#0097A7',
    '#5D4037',
    '#616161',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _type = widget.existing?.groupType ?? GroupType.family;
    _color = widget.existing?.color ?? '#1976D2';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? '编辑分组' : '新建分组',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '分组名称 *',
              hintText: '例如：家人 / 财务部 / 篮球队',
              border: OutlineInputBorder(),
            ),
            autofocus: !_isEdit,
          ),
          const SizedBox(height: 16),
          const Text('类型'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GroupType.values.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text('${t.icon} ${t.displayName}'),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('颜色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(int.parse('FF${c.substring(1)}', radix: 16)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting
                    ? (_isEdit ? '保存中…' : '创建中…')
                    : (_isEdit ? '保存' : '创建')),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分组名称')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await ref.read(groupNotifierProvider.notifier).update(
              widget.existing!.id,
              name: _nameCtrl.text.trim(),
              groupType: _type,
              color: _color,
            );
      } else {
        await ref.read(groupNotifierProvider.notifier).create(
              tripId: widget.tripId,
              name: _nameCtrl.text.trim(),
              groupType: _type,
              color: _color,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '已保存' : '已创建')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
