import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai_config.dart';
import '../../core/ai_service.dart';
import '../widgets/model_selector.dart';

/// AI 设置页
class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  bool _isTesting = false;
  bool? _connectionOk;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentAIModelProvider);
    _apiKeyController.text = current.apiKey;
    _baseUrlController.text = current.baseUrl;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentAIModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI 模型设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 模型说明卡片
          Card(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text('当前模型',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(current.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(current.description ?? ''),
                  const SizedBox(height: 8),
                  Text('Base URL: ${current.baseUrl}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 模型选择
          const Text('切换模型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ModelSelector(),

          const SizedBox(height: 24),

          // 配置项（API Key、Base URL）
          if (!current.isLocal) ...[
            const Text('API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '请输入 API Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              onChanged: (v) {
                ref.read(aiConfigProvider.notifier).updateApiKey(v);
              },
            ),
            const SizedBox(height: 16),
          ],

          const Text('Base URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              hintText: 'https://api.example.com/v1',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (v) {
              ref.read(aiConfigProvider.notifier).updateBaseUrl(v);
            },
          ),

          const SizedBox(height: 24),

          // 连接测试
          FilledButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
            label: Text(_isTesting ? '测试中...' : '测试连接'),
          ),
          if (_connectionOk != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _connectionOk! ? Icons.check_circle : Icons.error,
                  color: _connectionOk! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _connectionOk! ? '连接成功' : '连接失败',
                  style: TextStyle(
                    color: _connectionOk! ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // 模型说明列表
          const Text('可用模型说明',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...AIModelConfig.allModels.map(_buildModelCard).toList(),
        ],
      ),
    );
  }

  Widget _buildModelCard(AIModelConfig model) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: model.isPrimary
              ? const Color(0xFF2E7D32)
              : Colors.grey[300],
          child: Icon(
            model.isLocal ? Icons.computer : Icons.cloud,
            color: model.isPrimary ? Colors.white : Colors.black54,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(model.name),
            const SizedBox(width: 8),
            if (model.isPrimary)
              const Chip(
                label: Text('主力', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            if (model.isFree)
              const Chip(
                label: Text('免费', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Color(0x332E7D32),
              ),
          ],
        ),
        subtitle: Text(model.description ?? '',
            style: const TextStyle(fontSize: 12)),
        trailing: model.costPer1kTokens > 0
            ? Text('\$${model.costPer1kTokens.toStringAsFixed(4)}/1k',
                style: const TextStyle(fontSize: 11, color: Colors.grey))
            : const Text('免费', style: TextStyle(fontSize: 11, color: Colors.green)),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionOk = null;
    });
    try {
      final service = AIService(config: ref.read(currentAIModelProvider));
      final ok = await service.checkConnection();
      if (mounted) setState(() => _connectionOk = ok);
    } catch (e) {
      if (mounted) setState(() => _connectionOk = false);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }
}
