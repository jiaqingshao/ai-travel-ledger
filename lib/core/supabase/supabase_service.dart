import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/app_settings.dart';
import 'supabase_config.dart';

/// Supabase 服务封装
///
/// 职责：
/// - 初始化 Supabase 客户端（运行时从 AppSettings 读取配置）
/// - 提供 auth/realtime/storage 访问点
/// - 监听 auth 状态变化
/// - **失败自动回退本地模式** (2026-07-11 新增)
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 当前激活的设置 (运行时)
  AppSettings? _activeSettings;
  AppSettings? get activeSettings => _activeSettings;

  /// 当前用户 ID（未登录为 null）
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// 当前用户邮箱
  String? get currentUserEmail => _client?.auth.currentSession?.user.email;

  /// 是否已登录
  bool get isSignedIn => currentUserId != null;

  SupabaseClient? _client;

  /// 客户端 getter - 返回 dynamic 以便测试时 mock
  dynamic get client {
    if (!_initialized || _client == null) {
      throw StateError(
        'SupabaseService not initialized. Call init() first.',
      );
    }
    return _client!;
  }

  GoTrueClient get auth {
    if (!_initialized) {
      throw StateError('Supabase 未初始化, 请先在云端设置页面连接');
    }
    return client.auth;
  }

  SupabaseStorageClient get storage {
    if (!_initialized) {
      throw StateError('Supabase 未初始化, 请先在云端设置页面连接');
    }
    return client.storage;
  }

  /// 初始化（必须在 main() 中调用）
  ///
  /// 2026-07-11 重构：从 AppSettings 读取配置, 失败时回退本地模式
  /// - settings 为 null: 纯本地模式
  /// - settings.isCloudMode = false: 纯本地模式 (用户主动切回本地)
  /// - 连接成功: 初始化为云模式
  /// - 连接失败: 回退本地模式 + 记录错误
  ///
  /// 返回: (success, errorMessage)
  Future<({bool success, String? error})> init({AppSettings? settings}) async {
    if (_initialized) return (success: true, error: null);
    _activeSettings = settings;

    // 模式判断
    if (settings == null || !settings.isCloudMode) {
      // 纯本地模式
      _initialized = false;
      _client = null;
      return (success: false, error: null);
    }

    // 尝试连接云端
    try {
      await Supabase.initialize(
        url: settings.supabaseUrl,
        anonKey: settings.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      return (success: true, error: null);
    } catch (e) {
      // 连接失败, 回退本地模式
      _initialized = false;
      _client = null;
      return (success: false, error: e.toString());
    }
  }

  /// 运行时切换模式 / 重新连接
  ///
  /// 2026-07-11 新增:
  /// - 关闭现有连接
  /// - 用新设置重连
  /// - 失败回退本地
  Future<({bool success, String? error})> switchMode(AppSettings newSettings) async {
    await _disconnect();
    _activeSettings = newSettings;
    return await init(settings: newSettings);
  }

  /// 断开云端连接, 回退本地模式
  Future<void> switchToLocal() async {
    await _disconnect();
    final local = (_activeSettings ?? const AppSettings()).copyWith(
      mode: 'local',
      clearError: true,
    );
    _activeSettings = local;
    _initialized = false;
    _client = null;
  }

  /// 内部: 断开 Supabase 连接
  Future<void> _disconnect() async {
    if (_initialized && _client != null) {
      try {
        await _client!.auth.signOut();
      } catch (_) {}
      _initialized = false;
      _client = null;
    }
  }

  /// 邮箱注册
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    return response;
  }

  /// 邮箱登录
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithPassword(email: email, password: password);
  }

  /// 登出
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// 监听 auth 状态变化
  Stream<AuthState> get authStateChanges {
    if (!_initialized) {
      throw StateError('Supabase 未初始化');
    }
    return client.auth.onAuthStateChange;
  }
}