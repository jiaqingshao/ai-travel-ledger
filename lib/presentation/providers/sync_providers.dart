import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../../data/sync/sync_engine.dart';
import 'core_providers.dart';

/// 同步引擎 Provider
///
/// 通过 overrideWithValue 在 main.dart 注入
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final boxes = ref.watch(hiveBoxesProvider);
  return SyncEngine(boxes: boxes);
});

/// 当前用户状态（Riverpod 友好版）
class AuthState {
  AuthState({this.isSignedIn = false, this.email, this.userId});
  final bool isSignedIn;
  final String? email;
  final String? userId;

  AuthState copyWith({bool? isSignedIn, String? email, String? userId}) =>
      AuthState(
        isSignedIn: isSignedIn ?? this.isSignedIn,
        email: email ?? this.email,
        userId: userId ?? this.userId,
      );

  static final signedOut = AuthState();
}

/// 当前认证状态 Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.signedOut) {
    _init();
  }

  void _init() {
    if (!SupabaseService.instance.isInitialized) {
      return;
    }
    final user = SupabaseService.instance.auth.currentUser;
    if (user != null) {
      state = AuthState(
        isSignedIn: true,
        email: user.email,
        userId: user.id,
      );
    }
    // 订阅 auth 变化
    SupabaseService.instance.authStateChanges.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn) {
        final user = authState.session?.user;
        state = AuthState(
          isSignedIn: true,
          email: user?.email,
          userId: user?.id,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthState.signedOut;
      }
    });
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      final response = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return null; // 成功
      }
      return '登录失败';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (response.user != null) {
        return null;
      }
      return '注册失败';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    state = AuthState.signedOut;
  }
}