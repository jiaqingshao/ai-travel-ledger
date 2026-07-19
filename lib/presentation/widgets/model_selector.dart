import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai_config.dart';

/// 模型选择器（下拉 + 卡片两种风格）
class ModelSelector extends ConsumerWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentAIModelProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<AIModelConfig>(
        isExpanded: true,
        underline: const SizedBox(),
        value: current,
        items: AIModelConfig.allModels.map((model) {
          return DropdownMenuItem<AIModelConfig>(
            value: model,
            child: Row(
              children: [
                Icon(
                  model.isLocal ? Icons.computer : Icons.cloud,
                  size: 18,
                  color:
                      model.isPrimary ? const Color(0xFF2E7D32) : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(model.name),
                const Spacer(),
                if (model.isPrimary)
                  const Text('主力',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold)),
                if (model.isFree && !model.isPrimary)
                  const Text('免费',
                      style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          );
        }).toList(),
        onChanged: (model) {
          if (model != null) {
            ref.read(aiConfigProvider.notifier).switchModel(model);
          }
        },
      ),
    );
  }
}

/// 顶部状态指示器（显示当前模型 + 状态点）
class ModelStatusIndicator extends ConsumerWidget {
  const ModelStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentAIModelProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: current.isPrimary ? const Color(0xFF2E7D32) : Colors.orange,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          current.isPrimary ? 'M3' : (current.isLocal ? '本地' : '云端'),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
