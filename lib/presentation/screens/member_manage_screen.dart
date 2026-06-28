import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../providers/group_provider.dart';
import '../providers/member_provider.dart';

/// 成员管理页面
class MemberManageScreen extends ConsumerWidget {
  const MemberManageScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersByTripProvider(tripId));
    final groupsAsync = ref.watch(groupsByTripProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('成员管理')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (members) {
          if (members.isEmpty) {
            return _EmptyView(onAdd: () => _showAddSheet(context, ref));
          }
          return ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = members[i];
              final groups = groupsAsync.maybeWhen(
                data: (g) => g,
                orElse: () => const <TripGroup>[],
              );
              final currentGroup = groups
                  .where((g) => g.id == m.groupId)
                  .cast<TripGroup?>()
                  .firstWhere((_) => true, orElse: () => null);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _parseColor(m.avatarColor) ??
                      Theme.of(context).colorScheme.primary,
                  child: Text(
                    m.nickname.isNotEmpty
                        ? m.nickname[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Text(m.nickname),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.isOrganizer
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.role.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  currentGroup != null
                      ? '${currentGroup.icon} ${currentGroup.name}'
                      : '未分组',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'organize') {
                      await ref
                          .read(memberNotifierProvider.notifier)
                          .promoteToOrganizer(m.id);
                    } else if (v == 'group') {
                      await _showAssignGroupSheet(context, ref, m, groups);
                    } else if (v == 'delete') {
                      await _confirmDelete(context, ref, m);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!m.isOrganizer)
                      const PopupMenuItem(
                        value: 'organize',
                        child: Row(
                          children: [
                            Icon(Icons.workspace_premium, size: 18),
                            SizedBox(width: 8),
                            Text('设为组织者'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'group',
                      child: Row(
                        children: [
                          Icon(Icons.group_work, size: 18),
                          SizedBox(width: 8),
                          Text('调整分组'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('添加成员'),
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
        child: _AddMemberSheet(tripId: tripId),
      ),
    );
  }

  Future<void> _showAssignGroupSheet(
    BuildContext context,
    WidgetRef ref,
    Member member,
    List<TripGroup> groups,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('调整分组',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('不分组'),
              selected: member.groupId == null,
              onTap: () async {
                await ref
                    .read(memberNotifierProvider.notifier)
                    .assignToGroup(member.id, null);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ...groups.map((g) => ListTile(
                  leading: Text(g.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(g.name),
                  selected: member.groupId == g.id,
                  onTap: () async {
                    await ref
                        .read(memberNotifierProvider.notifier)
                        .assignToGroup(member.id, g.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确定要删除「${m.nickname}」吗？'),
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
      await ref.read(memberNotifierProvider.notifier).delete(m.id);
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
            const Icon(Icons.people_outline, size: 96, color: Colors.grey),
            const SizedBox(height: 24),
            Text('还没有成员',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('添加成员，或邀请未注册用户参与记账',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('添加第一个成员'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加成员底部表单
class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet({required this.tripId});
  final String tripId;

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _nicknameCtrl = TextEditingController();
  String _color = '#2E7D32';
  bool _asOrganizer = false;
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
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('添加成员',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nicknameCtrl,
            decoration: const InputDecoration(
              labelText: '昵称 *',
              hintText: '例如：小明 / 妈妈 / 张总',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Text('头像颜色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36,
                  height: 36,
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
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('设为组织者'),
            subtitle: const Text('可管理成员、分组、归档'),
            value: _asOrganizer,
            onChanged: (v) => setState(() => _asOrganizer = v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '添加中…' : '添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nicknameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入昵称')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(memberNotifierProvider.notifier).add(
            tripId: widget.tripId,
            nickname: _nicknameCtrl.text.trim(),
            avatarColor: _color,
            role: _asOrganizer ? MemberRole.organizer : MemberRole.member,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}