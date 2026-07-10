import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member.dart';
import '../../domain/services/split_calculator.dart' show SplitType;
import '../widgets/split_type_selector.dart';

/// 分摊规则编辑页 (V1.1 / ISSUE-024 完整版)
/// 
/// 用法:
/// ```dart
/// final result = await Navigator.push<SplitRuleExport>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => SplitRuleEditPage(
///       total: amount,
///       members: members,
///       tripId: tripId,
///       initialSplitRuleJson: e.splitRuleJson,
///     ),
///   ),
/// );
/// if (result != null) {
///   // 用户保存了新规则
///   setState(() => _editingSplitRule = result.rule);
/// }
/// ```
class SplitRuleEditPage extends ConsumerStatefulWidget {
  const SplitRuleEditPage({
    super.key,
    required this.total,
    required this.members,
    required this.tripId,
    this.initialSplitRuleJson,
  });

  final double total;
  final List<Member> members;
  final String tripId;
  final String? initialSplitRuleJson;

  @override
  ConsumerState<SplitRuleEditPage> createState() => _SplitRuleEditPageState();
}

class _SplitRuleEditPageState extends ConsumerState<SplitRuleEditPage> {
  final _selectorKey = GlobalKey<SplitTypeSelectorState>();

  @override
  void initState() {
    super.initState();
    // 注意: SplitTypeSelector 的 initialXxx 参数在 initState 设置
    // 我们通过 initialXxx 传入从 JSON 解析的初始值
  }

  /// 从 splitRuleJson 解析初始参数
  Map<String, dynamic> get _initialParams {
    if (widget.initialSplitRuleJson == null ||
        widget.initialSplitRuleJson!.isEmpty) {
      return {};
    }
    try {
      final json = jsonDecode(widget.initialSplitRuleJson!);
      return json is Map<String, dynamic> ? json : {};
    } catch (_) {
      return {};
    }
  }

  /// 构造初始参数
  SplitType? get _initialType {
    final t = _initialParams['type'] as String?;
    if (t == null) return null;
    switch (t) {
      case 'equal':
        return SplitType.equal;
      case 'ratio':
        return SplitType.ratio;
      case 'shares':
        return SplitType.shares;
      case 'specific':
        return SplitType.specific;
      case 'byGroup':
        return SplitType.byGroup;
    }
    return null;
  }

  Map<String, double>? get _initialRatios {
    final values = _initialParams['values'];
    if (values is Map) {
      return values.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return null;
  }

  List<String>? get _initialGroupIds {
    final participants = _initialParams['participants'];
    if (participants is List) {
      return participants
          .where((p) => p is Map && p['type'] == 'group')
          .map<String>((p) => p['id'] as String)
          .toList();
    }
    return null;
  }

  void _save() {
    final export = _selectorKey.currentState?.exportRule();
    if (export == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop<SplitRuleExport>(context, export);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑分摊规则'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('确定'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '分摊总金额',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '¥ ${widget.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SplitTypeSelector(
                key: _selectorKey,
                total: widget.total,
                members: widget.members,
                tripId: widget.tripId,
                initialType: _initialType ?? SplitType.equal,
                initialRatios: _initialRatios,
                initialGroupIds: _initialGroupIds,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
