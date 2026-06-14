import 'package:flutter/foundation.dart';

enum AIModelType {
  localQwen,
  cloudDeepSeek,
  cloudGlm4,
  cloudQianwen,
  custom,
}

class AIModelConfig {
  final AIModelType type;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final bool isLocal;

  const AIModelConfig({
    required this.type,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
    required this.isLocal,
  });

  static const AIModelConfig localQwen36 = AIModelConfig(
    type: AIModelType.localQwen,
    name: '本地 Qwen3.6',
    baseUrl: 'http://192.168.1.60:8033/v1',
    apiKey: 'sk-local-qwen36',
    modelName: 'Qwen3.6-35B-A3B-APEX-MTP-Balanced.gguf',
    isLocal: true,
  );

  static const AIModelConfig cloudDeepSeek = AIModelConfig(
    type: AIModelType.cloudDeepSeek,
    name: '云端 DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    apiKey: 'sk-your-deepseek-api-key',
    modelName: 'deepseek-chat',
    isLocal: false,
  );

  static const AIModelConfig cloudGlm4 = AIModelConfig(
    type: AIModelType.cloudGlm4,
    name: '云端 GLM-4',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    apiKey: 'your-glm4-api-key',
    modelName: 'glm-4',
    isLocal: false,
  );

  static const AIModelConfig cloudQianwen = AIModelConfig(
    type: AIModelType.cloudQianwen,
    name: '云端 通义千问',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    apiKey: 'sk-your-qianwen-api-key',
    modelName: 'qwen-max',
    isLocal: false,
  );

  static List<AIModelConfig> get allModels => [
        localQwen36,
        cloudDeepSeek,
        cloudGlm4,
        cloudQianwen,
      ];
}

class AIConfigProvider with ChangeNotifier {
  AIModelConfig _currentModel = AIModelConfig.localQwen36;

  AIModelConfig get currentModel => _currentModel;

  void switchModel(AIModelConfig model) {
    _currentModel = model;
    notifyListeners();
  }

  void updateApiKey(String newApiKey) {
    if (!_currentModel.isLocal) {
      _currentModel = AIModelConfig(
        type: _currentModel.type,
        name: _currentModel.name,
        baseUrl: _currentModel.baseUrl,
        apiKey: newApiKey,
        modelName: _currentModel.modelName,
        isLocal: _currentModel.isLocal,
      );
      notifyListeners();
    }
  }

  void updateBaseUrl(String newBaseUrl) {
    _currentModel = AIModelConfig(
      type: _currentModel.type,
      name: _currentModel.name,
      baseUrl: newBaseUrl,
      apiKey: _currentModel.apiKey,
      modelName: _currentModel.modelName,
      isLocal: _currentModel.isLocal,
    );
    notifyListeners();
  }
}
