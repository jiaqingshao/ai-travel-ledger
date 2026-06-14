import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ai_config.dart';

class AIService {
  final AIModelConfig _config;

  AIService({required AIModelConfig config}) : _config = config;

  Future<String> chat(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: jsonEncode({
          'model': _config.modelName,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('网络连接失败，请检查网络或本地模型服务');
    } catch (e) {
      throw Exception('请求失败: $e');
    }
  }

  Future<String> complete(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.baseUrl}/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: jsonEncode({
          'model': _config.modelName,
          'prompt': prompt,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['text'] as String;
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求失败: $e');
    }
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${_config.baseUrl}/models'),
        headers: {
          'Authorization': 'Bearer ${_config.apiKey}',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
