import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ai_config.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AIConfigProvider>(
      builder: (context, provider, child) {
        return DropdownButton<AIModelConfig>(
          value: provider.currentModel,
          hint: const Text('选择AI模型'),
          items: AIModelConfig.allModels.map((model) {
            return DropdownMenuItem<AIModelConfig>(
              value: model,
              child: Row(
                children: [
                  Icon(
                    model.isLocal ? Icons.computer : Icons.cloud,
                    size: 16,
                    color: model.isLocal ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(model.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (model) {
            if (model != null) {
              provider.switchModel(model);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已切换到: ${model.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class ModelStatusIndicator extends StatelessWidget {
  const ModelStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AIConfigProvider>(
      builder: (context, provider, child) {
        final model = provider.currentModel;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: model.isLocal ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                model.isLocal ? Icons.computer : Icons.cloud,
                size: 14,
                color: model.isLocal ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                model.name,
                style: TextStyle(
                  fontSize: 12,
                  color: model.isLocal ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
