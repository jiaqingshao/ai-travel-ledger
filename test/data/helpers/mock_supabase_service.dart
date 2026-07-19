// Mock SupabaseService 用于端到端测试
// 简化版：只用 dynamic 代理,避免实现完整的 Future 接口

import 'dart:async';
import 'package:ai_travel_ledger/core/supabase/supabase_service.dart';
import 'package:ai_travel_ledger/data/models/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseService implements SupabaseService {
  bool _initialized = true;
  bool simulateUninitialized = false;
  bool simulateNetworkError = false;
  AppSettings? _activeSettings;

  String? _userId = 'user-test-001';
  String? _email;

  // 记录所有 upsert 调用
  final List<Map<String, dynamic>> upsertedTrips = [];
  final List<Map<String, dynamic>> upsertedMembers = [];
  final List<Map<String, dynamic>> upsertedGroups = [];
  final List<Map<String, dynamic>> upsertedExpenses = [];
  final List<Map<String, dynamic>> upsertedTransfers = [];

  // 模拟云端已有数据（拉取时返回）
  List<Map<String, dynamic>> remoteTrips = [];

  @override
  bool get isInitialized => !simulateUninitialized && _initialized;

  @override
  bool get isSignedIn => _userId != null;

  @override
  String? get currentUserId => _userId;

  @override
  String? get currentUserEmail => _email;

  @override
  AppSettings? get activeSettings => _activeSettings;

  @override
  dynamic get client => _ProxyClient(this);

  @override
  GoTrueClient get auth => throw UnimplementedError('mock auth');

  @override
  SupabaseStorageClient get storage => throw UnimplementedError('mock storage');

  /// Mock init: 模拟成功初始化 (供无需网络真实测试的单元 / 集成测试用)
  ///
  /// 对应 SupabaseService.init({AppSettings? settings}) 的新签名 (2026-07-11 改造)
  /// 返回 record (`success`, `error`) 而不是 void, 这样调用方可以区分失败路径。
  @override
  Future<({bool success, String? error})> init({AppSettings? settings}) async {
    _activeSettings = settings;
    if (simulateNetworkError) {
      _initialized = false;
      return (success: false, error: 'mocked network error');
    }
    _initialized = true;
    return (success: true, error: null);
  }

  /// Mock switchMode: 等价于 init(newSettings)
  @override
  Future<({bool success, String? error})> switchMode(
      AppSettings newSettings) async {
    return await init(settings: newSettings);
  }

  /// Mock switchToLocal: 切回本地模式, 重置 _initialized 标记
  @override
  Future<void> switchToLocal() async {
    _activeSettings = null;
    _initialized = false;
  }

  @override
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    _email = email;
    _userId = 'user-${email.hashCode}';
    return AuthResponse(session: _mockSession(), user: _mockUser());
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _email = email;
    _userId = 'user-${email.hashCode}';
    return AuthResponse(session: _mockSession(), user: _mockUser());
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _userId = null;
  }

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  void signInMock(String email, String password) {
    _email = email;
    _userId = 'user-${email.hashCode}';
  }

  void signOutMock() {
    _email = null;
    _userId = null;
  }

  User _mockUser() => User(
        id: _userId ?? '',
        appMetadata: {},
        userMetadata: {'email': _email},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: _email,
        phone: null,
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  Session _mockSession() => Session(
        accessToken: 'mock-token',
        tokenType: 'bearer',
        user: _mockUser(),
      );
}

/// 代理 client - 任何方法调用都通过 dynamic 分派
class _ProxyClient {
  _ProxyClient(this.mock);
  final MockSupabaseService mock;

  dynamic from(String table) => _ProxyTable(mock, table);
}

/// 代理 table - 支持 upsert 和 select.or().await
class _ProxyTable {
  _ProxyTable(this.mock, this.table);
  final MockSupabaseService mock;
  final String table;

  Future<void> upsert(Map<String, dynamic> values,
      {bool onConflict = false}) async {
    if (mock.simulateNetworkError) throw Exception('Network error');
    switch (table) {
      case 'trips':
        mock.upsertedTrips.add(values);
        break;
      case 'trip_members':
        mock.upsertedMembers.add(values);
        break;
      case 'trip_groups':
        mock.upsertedGroups.add(values);
        break;
      case 'expenses':
        mock.upsertedExpenses.add(values);
        break;
      case 'transfer_records':
        mock.upsertedTransfers.add(values);
        break;
    }
  }

  /// 返回 _SelectChain - 支持 .or() 链式
  /// _SelectChain 本身是 awaitable（实现 then 方法）
  _SelectChain select([String? columns]) => _SelectChain(mock, table);
}

/// 支持 .or() 链式 + await
/// 本身是一个 Future<List<dynamic>>，同时支持 .or() 链式
class _SelectChain extends _SelectChainFuture {
  _SelectChain(this.mock, this.table) {
    // 异步触发完成
    Future.microtask(() {
      _completer.complete(_result());
    });
  }
  final MockSupabaseService mock;
  final String table;

  final Completer<List<dynamic>> _completer = Completer<List<dynamic>>();

  _SelectChain or(String filter) => this;

  @override
  Future<List<dynamic>> get future => _completer.future;

  Future<List<dynamic>> _result() async {
    if (mock.simulateNetworkError) throw Exception('Network error');
    return table == 'trips' ? mock.remoteTrips : <dynamic>[];
  }
}

/// 一个 Future 的中间基类 - 委托 future
abstract class _SelectChainFuture implements Future<List<dynamic>> {
  Future<List<dynamic>> get future;

  @override
  Future<R> then<R>(FutureOr<R> Function(List<dynamic>) onValue,
      {Function? onError}) {
    return future.then<R>(onValue, onError: onError);
  }

  @override
  Future<List<dynamic>> catchError(Function onError,
      {bool Function(Object)? test}) {
    return future.catchError(onError, test: test);
  }

  @override
  Future<List<dynamic>> whenComplete(FutureOr<void> Function() action) {
    return future.whenComplete(action);
  }

  @override
  Future<List<dynamic>> timeout(Duration timeLimit,
      {FutureOr<List<dynamic>> Function()? onTimeout}) {
    return future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<List<dynamic>> asStream() => future.asStream();

  @override
  Future<List<dynamic>> ignore() {
    future.ignore();
    return future;
  }
}
