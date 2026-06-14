import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ai_config.dart';
import '../../core/ai_service.dart';
import '../widgets/model_selector.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  bool _isChecking = false;
  bool? _connectionStatus;

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    
    final provider = Provider.of<AIConfigProvider>(context, listen: false);
    final service = AIService(config: provider.currentModel);
    
    try {
      final status = await service.checkConnection();
      setState(() => _connectionStatus = status);
    } catch (_) {
      setState(() => _connectionStatus = false);
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 模型设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前模型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ModelStatusIndicator(),
            const SizedBox(height: 24),
            const Text(
              '切换模型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const ModelSelector(),
            ),
            const SizedBox(height: 24),
            const Text(
              '模型信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<AIConfigProvider>(
              builder: (context, provider, child) {
                final model = provider.currentModel;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('模型名称', model.name),
                        _infoRow('基础 URL', model.baseUrl),
                        _infoRow('模型 ID', model.modelName),
                        _infoRow('类型', model.isLocal ? '本地模型' : '云端 API'),
                        _infoRow('API Key', model.apiKey),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkConnection,
                child: _isChecking
                    ? const CircularProgressIndicator(size: 20)
                    : const Text('测试连接'),
              ),
            ),
            if (_connectionStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    _connectionStatus! ? '✓ 连接成功' : '✗ 连接失败',
                    style: TextStyle(
                      color: _connectionStatus! ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
