import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Supabase 服务封装
///
/// 职责：
/// - 初始化 Supabase 客户端
/// - 提供 auth/realtime/storage 访问点
/// - 监听 auth 状态变化
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 当前用户 ID（未登录为 null）
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// 当前用户邮箱
  String? get currentUserEmail => _client?.auth.currentUser?.email;

  /// 是否已登录
  bool get isSignedIn => currentUserId != null;

  SupabaseClient? _client;
  SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw StateError(
        'SupabaseService not initialized. Call init() first.',
      );
    }
    return _client!;
  }

  GoTrueClient get auth => client.auth;
  SupabaseStorageClient get storage => client.storage;

  /// 初始化（必须在 main() 中调用）
  ///
  /// 如果 config 未配置，则跳过初始化，APP 仍可作为纯本地模式运行
  Future<void> init() async {
    if (_initialized) return;
    if (!SupabaseConfig.isConfigured) {
      // 静默跳过 - 纯本地模式
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _client = Supabase.instance.client;
    _initialized = true;
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
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}