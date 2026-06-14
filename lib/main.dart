import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ai_config.dart';
import 'core/ai_service.dart';
import 'presentation/screens/ai_settings_screen.dart';
import 'presentation/widgets/model_selector.dart';

/// AI 旅行账本 - 入口
void main() {
  runApp(
    const ProviderScope(
      child: AITravelLedgerApp(),
    ),
  );
}

class AITravelLedgerApp extends StatelessWidget {
  const AITravelLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AI 旅行账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),  // 旅行绿
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// 主页（开发中）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(currentAIModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 旅行账本'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ModelStatusIndicator(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.luggage, size: 80, color: Color(0xFF2E7D32)),
              const SizedBox(height: 24),
              Text(
                'AI 旅行账本',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '智能记账与分摊工具',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          const Text('当前 AI 模型',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('${currentModel.name}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(currentModel.description ?? '',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(currentModel.isPrimary ? '主力' : '备力'),
                            backgroundColor: currentModel.isPrimary
                                ? const Color(0xFF2E7D32).withOpacity(0.2)
                                : Colors.grey[200],
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(currentModel.isFree ? '免费' : '付费'),
                            backgroundColor: currentModel.isFree
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${currentModel.contextLength ~/ 1000}K 上下文'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('🚧 正在开发中...',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('下一步：旅程管理 (E-001)',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AISettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('AI 设置'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _testAI(context, ref),
                    icon: const Icon(Icons.chat),
                    label: const Text('测试对话'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testAI(BuildContext context, WidgetRef ref) async {
    final service = ref.read(aiServiceProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final reply = await service.chat(prompt: '你好，请用一句话介绍你自己。');
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('${service.config.name} 的回复'),
            content: Text(reply),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('调用失败'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    }
  }
}
