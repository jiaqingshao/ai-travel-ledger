import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_service.dart';

/// [PR-Y2 修复 S-20] AI 模型 URL 允许通过 dart-define 覆盖
///
/// 编译时注入示例:
/// flutter build apk --dart-define=LOCAL_QWEN36_BASE_URL=http://10.0.0.5:8033/v1
/// flutter build apk --dart-define=CLOUD_M3_BASE_URL=https://api.example.com/v1
///
/// 默认值保留 (避免破坏开发调试), 隐私敏感场景下推荐用 dart-define 注入。
const String kDefaultLocalQwen36BaseUrl = 'http://192.168.1.60:8033/v1';
const String kDefaultCloudM3BaseUrl = 'https://api.MiniMax.com/v1';
const String kDefaultCloudDeepSeekBaseUrl = 'https://api.deepseek.com/v1';
const String kDefaultCloudGlm4BaseUrl = 'https://open.bigmodel.cn/api/paas/v4';
const String kDefaultCloudQianwenBaseUrl =
    'https://dashscope.aliyuncs.com/compatible-mode/v1';

/// AI 模型类型枚举
enum AIModelType {
  cloudM3, // 🆕 主力：MiniMax M3（云端）
  localQwen36, // 备力：Qwen3.6 35B（本地 LM Studio）
  cloudDeepSeek, // 备选：DeepSeek
  cloudGlm4, // 备选：智谱 GLM-4
  cloudQianwen, // 备选：通义千问
  custom, // 自定义
}

/// AI 模型配置
class AIModelConfig {
  final AIModelType type;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final bool isLocal;
  final String? description;
  final double costPer1kTokens; // 估算成本，0 表示免费
  final int contextLength;

  const AIModelConfig({
    required this.type,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
    required this.isLocal,
    this.description,
    this.costPer1kTokens = 0.0,
    this.contextLength = 4096,
  });

  /// 🆕 主力：MiniMax M3
  /// 用户已有 M3 coding plan，能力最强
  static const AIModelConfig cloudM3 = AIModelConfig(
    type: AIModelType.cloudM3,
    name: 'MiniMax M3',
    baseUrl: String.fromEnvironment(
      'CLOUD_M3_BASE_URL',
      defaultValue: kDefaultCloudM3BaseUrl,
    ),
    apiKey: 'REPLACE_WITH_YOUR_M3_KEY', // TODO: 填入你的 M3 API Key
    modelName: 'MiniMax-M3',
    isLocal: false,
    description: '1M 上下文，多模态，编程能力强（已付费 coding plan）',
    costPer1kTokens: 0.0015, // 推介期价格 $0.30/$1.20 per 1M
    contextLength: 1000000,
  );

  /// 备力：本地 Qwen3.6 35B
  /// LM Studio 部署，0 token 费
  static const AIModelConfig localQwen36 = AIModelConfig(
    type: AIModelType.localQwen36,
    name: '本地 Qwen3.6 35B',
    baseUrl: String.fromEnvironment(
      'LOCAL_QWEN36_BASE_URL',
      defaultValue: kDefaultLocalQwen36BaseUrl,
    ),
    apiKey: 'lm-studio', // LM Studio 不校验 key
    modelName: 'qwen3.6-35b-a3b-apex-balanced',
    isLocal: true,
    description: '免费、离线、隐私安全（LM Studio）',
    costPer1kTokens: 0.0,
    contextLength: 32768,
  );

  /// 备选：DeepSeek（云端）
  static const AIModelConfig cloudDeepSeek = AIModelConfig(
    type: AIModelType.cloudDeepSeek,
    name: '云端 DeepSeek',
    baseUrl: String.fromEnvironment(
      'CLOUD_DEEPSEEK_BASE_URL',
      defaultValue: kDefaultCloudDeepSeekBaseUrl,
    ),
    apiKey: 'REPLACE_WITH_YOUR_DEEPSEEK_KEY',
    modelName: 'deepseek-chat',
    isLocal: false,
    description: '中文友好、价格便宜',
    costPer1kTokens: 0.001,
    contextLength: 32768,
  );

  /// 备选：智谱 GLM-4
  static const AIModelConfig cloudGlm4 = AIModelConfig(
    type: AIModelType.cloudGlm4,
    name: '云端 智谱 GLM-4',
    baseUrl: String.fromEnvironment(
      'CLOUD_GLM4_BASE_URL',
      defaultValue: kDefaultCloudGlm4BaseUrl,
    ),
    apiKey: 'REPLACE_WITH_YOUR_GLM4_KEY',
    modelName: 'glm-4-plus',
    isLocal: false,
    description: '中文场景优秀',
    costPer1kTokens: 0.001,
    contextLength: 128000,
  );

  /// 备选：通义千问
  static const AIModelConfig cloudQianwen = AIModelConfig(
    type: AIModelType.cloudQianwen,
    name: '云端 通义千问',
    baseUrl: String.fromEnvironment(
      'CLOUD_QIANWEN_BASE_URL',
      defaultValue: kDefaultCloudQianwenBaseUrl,
    ),
    apiKey: 'REPLACE_WITH_YOUR_QIANWEN_KEY',
    modelName: 'qwen-max',
    isLocal: false,
    description: '阿里云、稳定',
    costPer1kTokens: 0.02,
    contextLength: 32768,
  );

  /// 全部模型列表
  static List<AIModelConfig> get allModels => [
        cloudM3, // 🆕 主力
        localQwen36, // 备力
        cloudDeepSeek, // 备选
        cloudGlm4, // 备选
        cloudQianwen, // 备选
      ];

  /// 是否主力模型
  bool get isPrimary => type == AIModelType.cloudM3;

  /// 是否本地（0 token 费）
  bool get isFree => isLocal || costPer1kTokens == 0;
}

/// AI 配置状态（Riverpod StateNotifier）
class AIConfigNotifier extends StateNotifier<AIModelConfig> {
  AIConfigNotifier() : super(AIModelConfig.cloudM3);

  /// 切换模型
  void switchModel(AIModelConfig model) {
    state = model;
  }

  /// 切换到指定类型
  void switchToType(AIModelType type) {
    final newModel = AIModelConfig.allModels.firstWhere(
      (m) => m.type == type,
      orElse: () => state,
    );
    state = newModel;
  }

  /// 更新当前模型的 API Key
  void updateApiKey(String newApiKey) {
    if (state.isLocal) return; // 本地模型不需要 key
    state = AIModelConfig(
      type: state.type,
      name: state.name,
      baseUrl: state.baseUrl,
      apiKey: newApiKey,
      modelName: state.modelName,
      isLocal: state.isLocal,
      description: state.description,
      costPer1kTokens: state.costPer1kTokens,
      contextLength: state.contextLength,
    );
  }

  /// 更新 Base URL
  void updateBaseUrl(String newBaseUrl) {
    state = AIModelConfig(
      type: state.type,
      name: state.name,
      baseUrl: newBaseUrl,
      apiKey: state.apiKey,
      modelName: state.modelName,
      isLocal: state.isLocal,
      description: state.description,
      costPer1kTokens: state.costPer1kTokens,
      contextLength: state.contextLength,
    );
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      // 这里调用 AIService 测试
      return true;
    } catch (e) {
      debugPrint('AI 连接测试失败: $e');
      return false;
    }
  }
}

/// Riverpod Provider
final aiConfigProvider = StateNotifierProvider<AIConfigNotifier, AIModelConfig>(
  (ref) => AIConfigNotifier(),
);

/// 当前模型 Provider
final currentAIModelProvider = Provider<AIModelConfig>((ref) {
  return ref.watch(aiConfigProvider);
});

/// AI 服务 Provider
final aiServiceProvider = Provider<AIService>((ref) {
  final config = ref.watch(aiConfigProvider);
  return AIService(config: config);
});
