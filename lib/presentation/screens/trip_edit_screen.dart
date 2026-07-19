import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/trip.dart';
import '../providers/trip_provider.dart';

/// 编辑旅程
class TripEditScreen extends ConsumerStatefulWidget {
  const TripEditScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends ConsumerState<TripEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _destinationCtrl;
  late String _currency;
  late DateTime _startDate;
  DateTime? _endDate;
  late TripStatus _status;
  bool _submitting = false;

  static const _currencies = ['CNY', 'USD', 'EUR', 'JPY', 'HKD', 'GBP', 'THB'];

  @override
  void initState() {
    super.initState();
    // ISSUE-042: tripByIdProvider 现在是 StreamProvider, ref.read 拿 AsyncValue
    final trip = ref.read(tripByIdProvider(widget.tripId)).valueOrNull;
    _nameCtrl = TextEditingController(text: trip?.name ?? '');
    _destinationCtrl = TextEditingController(text: trip?.destination ?? '');
    _currency = trip?.baseCurrency ?? 'CNY';
    _startDate = trip?.startDate ?? DateTime.now();
    _endDate = trip?.endDate;
    _status = trip?.status ?? TripStatus.preparing;
  }

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
      appBar: AppBar(title: const Text('编辑旅程')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '旅程名称 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入旅程名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                labelText: '目的地（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(
                labelText: '基础币种',
                border: OutlineInputBorder(),
              ),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'CNY'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TripStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: '状态',
                border: OutlineInputBorder(),
              ),
              items: TripStatus.values
                  .where((s) => s != TripStatus.archived)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 16),
            _DatePickerTile(
              label: '出发日期 *',
              value: _startDate,
              formatter: df,
              onPick: _pickStartDate,
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
                  : const Icon(Icons.save),
              label: Text(_submitting ? '保存中…' : '保存'),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(tripNotifierProvider.notifier).update(
            widget.tripId,
            name: _nameCtrl.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            destination: _destinationCtrl.text.trim().isEmpty
                ? null
                : _destinationCtrl.text.trim(),
            baseCurrency: _currency,
            status: _status,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存')),
        );
        // ISSUE-042 免底: 强制 invalidate
        ref.invalidate(tripByIdProvider(widget.tripId));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: value == null
            ? const Icon(Icons.arrow_drop_down)
            : onClear != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  )
                : null,
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
