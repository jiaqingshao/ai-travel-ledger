import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';

/// 应用设置仓库
///
/// 存储在 Hive box 'app_settings' (单例 key='settings')
/// 监听变化,其他模块可以 watch() 实时响应
class AppSettingsRepository {
  AppSettingsRepository({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;
  static const String _key = 'settings';

  /// 读取当前设置 (不存在则返回默认)
  AppSettings load() {
    final raw = _box.get(_key);
    if (raw == null) {
      return const AppSettings();
    }
    try {
      if (raw is String) {
        return AppSettings.fromJson(jsonDecode(raw) as Map<dynamic, dynamic>);
      } else if (raw is Map) {
        return AppSettings.fromJson(raw);
      }
      return const AppSettings();
    } catch (_) {
      return const AppSettings();
    }
  }

  /// 保存设置
  Future<void> save(AppSettings settings) async {
    await _box.put(_key, jsonEncode(settings.toJson()));
  }

  /// 重置为默认
  Future<void> reset() async {
    await _box.delete(_key);
  }

  /// 监听变化
  Stream<AppSettings> watch() {
    return _box.watch(key: _key).map((event) => load());
  }
}
