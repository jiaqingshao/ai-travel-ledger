import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/trip_provider.dart';

/// 新建旅程表单
class TripCreateScreen extends ConsumerStatefulWidget {
  const TripCreateScreen({super.key});

  @override
  ConsumerState<TripCreateScreen> createState() => _TripCreateScreenState();
}

class _TripCreateScreenState extends ConsumerState<TripCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  String _currency = 'CNY';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  static const _currencies = ['CNY', 'USD', 'EUR', 'JPY', 'HKD', 'GBP', 'THB'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(title: const Text('新建旅程')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '旅程名称 *',
                hintText: '例如：云南自驾 7 日游',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入旅程名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                labelText: '目的地（可选）',
                hintText: '例如：云南 / 大理',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(
                labelText: '基础币种',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'CNY'),
            ),
            const SizedBox(height: 16),
            _DatePickerTile(
              label: '出发日期 *',
              value: _startDate,
              formatter: df,
              onPick: _pickStartDate,
              onClear: () => setState(() => _startDate = null),
            ),
            const SizedBox(height: 8),
            _DatePickerTile(
              label: '结束日期（可选）',
              value: _endDate,
              formatter: df,
              onPick: _pickEndDate,
              onClear: () => setState(() => _endDate = null),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_submitting ? '创建中…' : '创建旅程'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      _showSnack('请选择出发日期');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(tripNotifierProvider.notifier).create(
            name: _nameCtrl.text.trim(),
            startDate: _startDate!,
            endDate: _endDate,
            destination: _destinationCtrl.text.trim().isEmpty
                ? null
                : _destinationCtrl.text.trim(),
            baseCurrency: _currency,
          );
      if (mounted) {
        _showSnack('旅程创建成功');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnack('创建失败：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: value == null
            ? const Icon(Icons.arrow_drop_down)
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
      ),
      child: InkWell(
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value == null ? '点击选择日期' : formatter.format(value!),
            style: TextStyle(
              fontSize: 16,
              color: value == null ? Colors.grey : null,
            ),
          ),
        ),
      ),
    );
  }
}