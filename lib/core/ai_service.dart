import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'ai_config.dart';

/// AI 服务类
/// - 统一封装 OpenAI 兼容 API 调用
/// - 支持 fallback：M3 失败自动用 Qwen3.6
class AIService {
  final AIModelConfig _config;
  final Duration _timeout;

  AIService({
    required AIModelConfig config,
    Duration timeout = const Duration(seconds: 60),
  })  : _config = config,
        _timeout = timeout;

  AIModelConfig get config => _config;

  /// 普通对话
  Future<String> chat({
    required String prompt,
    List<Map<String, String>>? history,
    int? maxTokens,
    double? temperature,
  }) async {
    final messages = <Map<String, String>>[
      ...?history,
      {'role': 'user', 'content': prompt},
    ];

    try {
      final response = await _postWithFallback(
        endpoint: 'chat/completions',
        body: {
          'model': _config.modelName,
          'messages': messages,
          if (maxTokens != null) 'max_tokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
        },
      );
      return _extractChatContent(response);
    } on TimeoutException {
      throw AIServiceException('请求超时（${_timeout.inSeconds}s）');
    } on SocketException {
      throw AIServiceException('网络连接失败，请检查网络或本地模型服务');
    } catch (e) {
      throw AIServiceException('请求失败: $e');
    }
  }

  /// 流式对话
  Stream<String> chatStream({
    required String prompt,
    List<Map<String, String>>? history,
    int? maxTokens,
    double? temperature,
  }) async* {
    final messages = <Map<String, String>>[
      ...?history,
      {'role': 'user', 'content': prompt},
    ];

    final request =
        http.Request('POST', Uri.parse('${_config.baseUrl}/chat/completions'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_config.apiKey}',
    });
    request.body = jsonEncode({
      'model': _config.modelName,
      'messages': messages,
      'stream': true,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
    });

    final response = await request.send();
    if (response.statusCode != 200) {
      throw AIServiceException('流式请求失败: ${response.statusCode}');
    }

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data.trim() == '[DONE]') break;
        try {
          final json = jsonDecode(data);
          final content = json['choices']?[0]?['delta']?['content'];
          if (content != null) yield content as String;
        } catch (_) {
          // 忽略解析错误
        }
      }
    }
  }

  /// 代码补全
  Future<String> complete(String prompt, {int? maxTokens}) async {
    try {
      final response = await _postWithFallback(
        endpoint: 'completions',
        body: {
          'model': _config.modelName,
          'prompt': prompt,
          if (maxTokens != null) 'max_tokens': maxTokens,
          'temperature': 0.3, // 代码补全用低温度
        },
      );
      return _extractCompletionText(response);
    } catch (e) {
      throw AIServiceException('代码补全失败: $e');
    }
  }

  /// 测试连接
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('${_config.baseUrl}/models'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST 请求 + 自动 fallback
  /// - 当前模型失败时，自动切换到 fallback 模型
  Future<http.Response> _postWithFallback({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _post(endpoint, body);
      if (response.statusCode == 200) return response;

      // 非 200，尝试 fallback
      debugPrint('AI 请求失败 (${response.statusCode})，尝试 fallback');
      final fallbackModel = _getFallbackModel();
      if (fallbackModel != null) {
        return await _postWithModel(endpoint, body, fallbackModel);
      }
      return response;
    } catch (e) {
      // 异常时 fallback
      debugPrint('AI 请求异常 ($e)，尝试 fallback');
      final fallbackModel = _getFallbackModel();
      if (fallbackModel != null) {
        return await _postWithModel(endpoint, body, fallbackModel);
      }
      rethrow;
    }
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) {
    return http
        .post(
          Uri.parse('${_config.baseUrl}/$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_config.apiKey}',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  Future<http.Response> _postWithModel(
    String endpoint,
    Map<String, dynamic> body,
    AIModelConfig model,
  ) {
    return http
        .post(
          Uri.parse('${model.baseUrl}/$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${model.apiKey}',
          },
          body: jsonEncode({...body, 'model': model.modelName}),
        )
        .timeout(_timeout);
  }

  /// 获取 fallback 模型
  /// 主力（M3）→ 备力（Qwen3.6 本地）→ 备选 1
  AIModelConfig? _getFallbackModel() {
    if (_config.type == AIModelType.cloudM3) {
      return AIModelConfig.localQwen36;
    }
    if (_config.type == AIModelType.localQwen36) {
      return AIModelConfig.cloudDeepSeek;
    }
    return null; // 没有更多 fallback
  }

  String _extractChatContent(http.Response response) {
    if (response.statusCode != 200) {
      throw AIServiceException(
          'API 返回 ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  String _extractCompletionText(http.Response response) {
    if (response.statusCode != 200) {
      throw AIServiceException(
          'API 返回 ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['choices'][0]['text'] as String;
  }
}

/// AI 服务异常
class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
