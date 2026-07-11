import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense.dart' show SplitRule;
import '../../data/models/group.dart';
import '../../data/models/member.dart';
import '../../domain/services/split_calculator.dart';
import '../providers/group_provider.dart';

/// 分摊规则选择器（W3 / E-003）
///
/// ## 用法
/// ```dart
/// SplitTypeSelector(
///   total: amount,
///   members: tripMembers,
///   groups: tripGroups,
///   onChanged: (splitType, result) {
///     // splitType: SplitType 当前选中的类型
///     // result: List<SplitResultItem> 实时预览
///   },
/// )
/// ```
///
/// ## 行为
/// - **Tab 选类型**：均摊 / 比例 / 份数 / 固定金额 / 按组（5 种）
/// - **实时预览**：每次输入变化，自动调用 [SplitCalculator] 计算每人金额
/// - **按组**：弹出底部菜单选组，选完后组内自动均摊
/// - **空状态**：无成员时禁用 / 提示
class SplitTypeSelector extends ConsumerStatefulWidget {
  const SplitTypeSelector({
    super.key,
    required this.total,
    required this.members,
    required this.tripId,
    this.initialType = SplitType.equal,
    this.initialGroupIds,
    this.initialRatios,
    this.initialShares,
    this.initialSpecific,
    this.onChanged,
  });

  /// 总金额（驱动预览）
  final double total;

  /// 该旅程的所有成员
  final List<Member> members;

  /// 用于加载组列表
  final String tripId;

  /// 初始选中的分摊类型
  final SplitType initialType;

  /// 初始选中的组（按组分摊用）
  final List<String>? initialGroupIds;

  /// 初始比例（按比例用）：{ memberId: ratio }
  final Map<String, double>? initialRatios;

  /// 初始份数（按份数用）：{ memberId: shares }
  final Map<String, double>? initialShares;

  /// 初始固定金额（specific 用）：{ memberId: amount }
  final Map<String, double>? initialSpecific;

  /// 选择 / 数据变化回调（每次输入都会触发）
  final void Function(
    SplitType type,
    List<SplitResultItem> result,
  )? onChanged;

  @override
  ConsumerState<SplitTypeSelector> createState() => SplitTypeSelectorState();
}

/// SplitTypeSelector 的 State（公开以便父组件通过 GlobalKey 调用 exportRule()）
class SplitTypeSelectorState extends ConsumerState<SplitTypeSelector> {
  late SplitType _type;

  // 各类型的实时参数
  late Map<String, double> _ratios;
  late Map<String, double> _shares;
  late Map<String, double> _specific;
  late Set<String> _selectedGroupIds;
  late Map<String, double> _groupRatios;

  // TextField controller 与 FocusNode (按金额分摊用)
  // ISSUE-028 修复：之前在 build() 里 new controller 导致光标丢失/输入倒序
  late Map<String, TextEditingController> _specificCtrls;
  late Map<String, FocusNode> _specificFocuses;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _ratios = Map<String, double>.from(widget.initialRatios ?? const {});
    _shares = Map<String, double>.from(widget.initialShares ?? const {});
    _specific = Map<String, double>.from(widget.initialSpecific ?? const {});
    _selectedGroupIds = Set<String>.from(widget.initialGroupIds ?? const []);
    _groupRatios = <String, double>{};

    // 初始化 controllers + focus nodes (ISSUE-028 修复)
    _specificCtrls = {
      for (final m in widget.members)
        m.id: TextEditingController(text: _formatSpecific(_specific[m.id] ?? 0)),
    };
    _specificFocuses = {
      for (final m in widget.members) m.id: FocusNode(debugLabel: 'specific_${m.id}'),
    };

    // 默认值
    if (_type == SplitType.equal) {
      // 等所有成员均摊（默认）
    } else if (_type == SplitType.ratio) {
      _ratios = _ensureMemberKeys(_ratios);
    } else if (_type == SplitType.shares) {
      _shares = _ensureMemberKeys(_shares, defaultValue: 1.0);
    } else if (_type == SplitType.specific) {
      _specific = _ensureMemberKeys(_specific);
    } else if (_type == SplitType.byGroup) {
      // _selectedGroupIds 由 UI 选
    }
    // 计算初始预览
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void didUpdateWidget(SplitTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.members.map((m) => m.id).toSet();
    // 新增成员
    for (final m in widget.members) {
      _specificCtrls.putIfAbsent(
        m.id,
        () => TextEditingController(text: _formatSpecific(_specific[m.id] ?? 0)),
      );
      _specificFocuses.putIfAbsent(
        m.id,
        () => FocusNode(debugLabel: 'specific_${m.id}'),
      );
    }
    // 移除已删除成员
    _specificCtrls.removeWhere((id, ctrl) {
      if (!currentIds.contains(id)) {
        ctrl.dispose();
        return true;
      }
      return false;
    });
    _specificFocuses.removeWhere((id, focus) {
      if (!currentIds.contains(id)) {
        focus.dispose();
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    for (final ctrl in _specificCtrls.values) {
      ctrl.dispose();
    }
    for (final focus in _specificFocuses.values) {
      focus.dispose();
    }
    super.dispose();
  }

  String _formatSpecific(double v) => v > 0 ? v.toStringAsFixed(2) : '';

  /// 确保 map 包含所有成员（缺失填 0）
  Map<String, double> _ensureMemberKeys(
    Map<String, double> m, {
    double defaultValue = 0.0,
  }) {
    final result = Map<String, double>.from(m);
    for (final mem in widget.members) {
      result.putIfAbsent(mem.id, () => defaultValue);
    }
    return result;
  }

  // ========================================================================
  // 计算 + 回调
  // ========================================================================

  void _emit() {
    final result = _compute();
    widget.onChanged?.call(_type, result);
  }

  List<SplitResultItem> _compute() {
    final total = widget.total;
    final memberIds = widget.members.map((m) => m.id).toList();

    try {
      switch (_type) {
        case SplitType.equal:
        case SplitType.equalSelected:
          return SplitCalculator.equalAll(total: total, memberIds: memberIds);
        case SplitType.ratio:
          if (_ratios.values.every((v) => v == 0)) return const [];
          return SplitCalculator.byRatio(total: total, ratios: _ratios);
        case SplitType.shares:
          if (_shares.values.every((v) => v == 0)) return const [];
          return SplitCalculator.byShares(total: total, shares: _shares);
        case SplitType.specific:
          return SplitCalculator.byMember(values: _specific, total: total);
        case SplitType.byGroup:
          if (_selectedGroupIds.isEmpty) return const [];
          final groupInputs = [
            for (final gid in _selectedGroupIds)
              GroupSplitInput(
                groupId: gid,
                ratio: _groupRatios[gid] ?? 1.0,
              ),
          ];
          return SplitCalculator.byGroup(
            total: total,
            groups: groupInputs,
            members: widget.members,
          );
      }
    } catch (e) {
      // 参数不合法（byMember sum 不匹配等） → 返回空，前端显示错误
      return const [];
    }
  }

  // ========================================================================
  // UI
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) {
      return _emptyView();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTypeTabs(),
        const SizedBox(height: 12),
        _buildTypePanel(),
        const SizedBox(height: 16),
        _buildPreview(),
      ],
    );
  }

  Widget _emptyView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 8),
          Text('该旅程还没有成员，无法分摊'),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    final tabs = <(SplitType, IconData, String)>[
      (SplitType.equal, Icons.balance, '均摊'),
      (SplitType.ratio, Icons.percent, '比例'),
      (SplitType.shares, Icons.pie_chart_outline, '份数'),
      (SplitType.specific, Icons.attach_money, '固定'),
      (SplitType.byGroup, Icons.groups_2, '按组'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (type, icon, label) in tabs) ...[
            ChoiceChip(
              avatar: Icon(
                icon,
                size: 16,
                color: _type == type
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              label: Text(label),
              selected: _type == type,
              onSelected: (_) => _switchType(type),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  void _switchType(SplitType type) {
    setState(() {
      _type = type;
      // 切换类型时按需初始化
      if (type == SplitType.ratio) {
        _ratios = _ensureMemberKeys(_ratios);
      } else if (type == SplitType.shares) {
        _shares = _ensureMemberKeys(_shares, defaultValue: 1.0);
      } else if (type == SplitType.specific) {
        _specific = _ensureMemberKeys(_specific);
      }
    });
    _emit();
  }

  Widget _buildTypePanel() {
    switch (_type) {
      case SplitType.equal:
      case SplitType.equalSelected:
        return _equalPanel();
      case SplitType.ratio:
        return _ratioPanel();
      case SplitType.shares:
        return _sharesPanel();
      case SplitType.specific:
        return _specificPanel();
      case SplitType.byGroup:
        return _byGroupPanel();
    }
  }

  // ============================ 均摊 ============================

  Widget _equalPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '所有 ${widget.members.length} 人均摊，每人 ¥ ${(widget.total / widget.members.length).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================ 比例 ============================

  Widget _ratioPanel() {
    return Column(
      children: [
        _hintText('拖动滑块设置比例（自动归一化）'),
        for (final m in widget.members)
          _ratioSliderRow(m),
      ],
    );
  }

  Widget _ratioSliderRow(Member m) {
    final value = _ratios[m.id] ?? 0;
    final maxVal = _ratios.values.fold<double>(1, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              m.nickname,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0, math.max(maxVal, 1.0)),
              min: 0,
              max: 10,
              divisions: 100,
              label: value.toStringAsFixed(1),
              onChanged: (v) {
                setState(() {
                  _ratios[m.id] = v;
                });
                _emit();
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================ 份数 ============================

  Widget _sharesPanel() {
    return Column(
      children: [
        _hintText('每人份数（默认 1，可改）'),
        for (final m in widget.members)
          _sharesRow(m),
      ],
    );
  }

  Widget _sharesRow(Member m) {
    final value = (_shares[m.id] ?? 1).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(m.nickname,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value <= 1
                ? null
                : () {
                    setState(() {
                      _shares[m.id] = (value - 1).toDouble();
                    });
                    _emit();
                  },
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              setState(() {
                _shares[m.id] = (value + 1).toDouble();
              });
              _emit();
            },
          ),
        ],
      ),
    );
  }

  // ============================ 固定金额 ============================

  Widget _specificPanel() {
    return Column(
      children: [
        _hintText('输入每人金额（总和必须等于总额）'),
        for (final m in widget.members) _specificRow(m),
        const SizedBox(height: 8),
        _specificSumWarning(),
      ],
    );
  }

  Widget _specificRow(Member m) {
    // ISSUE-028 修复：从 state 字段取 controller (不再每次 rebuild 新建)
    final ctrl = _specificCtrls.putIfAbsent(
      m.id,
      () => TextEditingController(text: _formatSpecific(_specific[m.id] ?? 0)),
    );
    final focus = _specificFocuses.putIfAbsent(
      m.id,
      () => FocusNode(debugLabel: 'specific_${m.id}'),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              m.nickname,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              scrollPadding: const EdgeInsets.only(bottom: 200),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                prefixText: '￥ ',
                hintText: '0.00',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                setState(() {
                  _specific[m.id] = parsed;
                });
                _emit();
              },
              onSubmitted: (_) {
                // ISSUE-028 修复：自动跳到下一个成员输入框
                final memberIds = widget.members.map((m) => m.id).toList();
                final idx = memberIds.indexOf(m.id);
                if (idx >= 0 && idx < memberIds.length - 1) {
                  _specificFocuses[memberIds[idx + 1]]?.requestFocus();
                } else {
                  focus.unfocus(); // 最后一个成员，关闭键盘
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================ 按组 ============================

  Widget _specificSumWarning() {
    final sum = _specific.values.fold<double>(0, (a, b) => a + b);
    final diff = sum - widget.total;
    final ok = diff.abs() < 0.01;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ok
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 16,
            color: ok ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ok
                  ? '总和匹配总额'
                  : '差 ¥ ${diff.toStringAsFixed(2)}（${sum.toStringAsFixed(2)} / ${widget.total.toStringAsFixed(2)}）',
              style: TextStyle(
                fontSize: 12,
                color: ok ? Colors.green : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _byGroupPanel() {
    final groupsAsync = ref.watch(groupsByTripProvider(widget.tripId));
    return groupsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('加载组失败：$e'),
      data: (groups) {
        if (groups.isEmpty) {
          return _noGroupsHint();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hintText('选择要参与分摊的组（组内自动均摊）'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in groups)
                  FilterChip(
                    avatar: Text(g.icon),
                    label: Text(g.name),
                    selected: _selectedGroupIds.contains(g.id),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _selectedGroupIds.add(g.id);
                          _groupRatios.putIfAbsent(g.id, () => 1.0);
                        } else {
                          _selectedGroupIds.remove(g.id);
                          _groupRatios.remove(g.id);
                        }
                      });
                      _emit();
                    },
                  ),
              ],
            ),
            if (_selectedGroupIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              _groupRatiosEditor(groups),
            ],
            const SizedBox(height: 8),
            _selectedGroupsMembers(),
          ],
        );
      },
    );
  }

  Widget _groupRatiosEditor(List<TripGroup> groups) {
    final selected =
        groups.where((g) => _selectedGroupIds.contains(g.id)).toList();
    if (selected.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 16),
        const Text(
          '组间比例（可选，默认 1:1）',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        for (final g in selected)
          _groupRatioRow(g),
      ],
    );
  }

  Widget _groupRatioRow(TripGroup g) {
    final value = _groupRatios[g.id] ?? 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              g.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0.1, 5.0),
              min: 0.1,
              max: 5.0,
              divisions: 49,
              label: value.toStringAsFixed(1),
              onChanged: (v) {
                setState(() {
                  _groupRatios[g.id] = v;
                });
                _emit();
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedGroupsMembers() {
    final selectedMembers = widget.members
        .where((m) =>
            m.groupId != null && _selectedGroupIds.contains(m.groupId))
        .toList();
    if (selectedMembers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '涉及 ${selectedMembers.length} 人：${selectedMembers.map((m) => m.nickname).join('、')}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noGroupsHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '该旅程还没有组。请先在旅程详情中创建组，再使用按组分摊。',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  // ============================ 预览 ============================

  Widget _buildPreview() {
    final result = _compute();
    if (result.isEmpty) {
      return _previewPlaceholder();
    }
    final v = SplitCalculator.validateSum(total: widget.total, items: result);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, size: 16),
              const SizedBox(width: 6),
              const Text(
                '实时预览',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              if (v.diff.abs() >= SplitCalculator.epsilon)
                Text(
                  '差 ¥ ${v.diff.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const Text(
                  '✓ 总和匹配',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Divider(height: 12),
          for (final item in result) _previewRow(item),
        ],
      ),
    );
  }

  Widget _previewRow(SplitResultItem item) {
    final nickname = widget.members
        .firstWhere(
          (m) => m.id == item.memberId,
          orElse: () => widget.members.first,
        )
        .nickname;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              nickname,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '¥ ${item.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _type == SplitType.byGroup
                  ? '请选择至少 1 个组'
                  : _type == SplitType.specific
                      ? '请输入每人金额'
                      : '请调整参数',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // 公开 API：让父组件读取当前状态
  // ========================================================================

  /// 父组件提交时调用：用当前选择的分摊方式生成 [SplitRule] JSON
  ///
  /// 返回 `(type, splitRuleJson)`，可直接传给 `expenseRepository.create`
  SplitRuleExport exportRule() {
    return SplitRuleExport(
      type: _type,
      rule: _buildSplitRule(),
      result: _compute(),
    );
  }

  /// 重置为默认状态 (ISSUE-023 修复: 保存并继续时复用)
  void reset() {
    setState(() {
      _type = SplitType.equal;
      _ratios.clear();
      _shares.clear();
      _specific.clear();
      _selectedGroupIds.clear();
      _groupRatios.clear();
      // ISSUE-028 修复：同步清空 controllers 避免残留
      for (final ctrl in _specificCtrls.values) {
        ctrl.clear();
      }
    });
  }

  /// 构造 SplitRule（供父组件提交 + 测试用）
  SplitRule _buildSplitRule() {
    switch (_type) {
      case SplitType.equal:
      case SplitType.equalSelected:
        // equal：所有成员（参与人均摊）
        return SplitRule.equal(widget.members.map((m) => m.id).toList());
      case SplitType.ratio:
        return SplitRule(
          type: 'ratio',
          participants: widget.members
              .map((m) => <String, dynamic>{'type': 'member', 'id': m.id})
              .toList(),
          values: Map<String, double>.from(_ratios),
        );
      case SplitType.shares:
        return SplitRule(
          type: 'shares',
          participants: widget.members
              .map((m) => <String, dynamic>{'type': 'member', 'id': m.id})
              .toList(),
          values: Map<String, double>.from(_shares),
        );
      case SplitType.specific:
        return SplitRule(
          type: 'specific',
          participants: widget.members
              .map((m) => <String, dynamic>{'type': 'member', 'id': m.id})
              .toList(),
          values: Map<String, double>.from(_specific),
        );
      case SplitType.byGroup:
        return SplitRule(
          type: 'byGroup',
          participants: _selectedGroupIds
              .map((id) => <String, dynamic>{'type': 'group', 'id': id})
              .toList(),
          values: Map<String, double>.from(_groupRatios),
        );
    }
  }
}

/// 导出结果（父组件调用 exportRule() 获取）
class SplitRuleExport {
  const SplitRuleExport({
    required this.type,
    required this.rule,
    required this.result,
  });

  final SplitType type;
  final SplitRule rule;
  final List<SplitResultItem> result;
}