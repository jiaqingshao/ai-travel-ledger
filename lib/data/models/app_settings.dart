/// AI 旅行账本 - 应用设置模型
///
/// 存储在 Hive box 'app_settings' (单例)
/// 包含:
/// - 模式 (local / cloud)
/// - Supabase 配置 (URL + anon key)
/// - 自动同步开关
class AppSettings {
  /// 运行模式: 'local' (纯本地) 或 'cloud' (本地 + 云同步)
  final String mode;

  /// Supabase Project URL
  final String supabaseUrl;

  /// Supabase anon public key
  final String supabaseAnonKey;

  /// 是否启用自动同步
  final bool autoSyncEnabled;

  /// 最后一次连接错误 (用于 UI 提示)
  final String? lastConnectionError;

  /// 最后一次连接成功时间 (ISO 8601)
  final String? lastConnectedAt;

  const AppSettings({
    this.mode = 'local',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.autoSyncEnabled = true,
    this.lastConnectionError,
    this.lastConnectedAt,
  });

  /// 是否已配置 Supabase
  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// 是否正在云模式运行
  bool get isCloudMode => mode == 'cloud' && hasSupabaseConfig;

  /// 复制并修改部分字段
  AppSettings copyWith({
    String? mode,
    String? supabaseUrl,
    String? supabaseAnonKey,
    bool? autoSyncEnabled,
    String? lastConnectionError,
    bool clearError = false,
    String? lastConnectedAt,
  }) {
    return AppSettings(
      mode: mode ?? this.mode,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      lastConnectionError:
          clearError ? null : (lastConnectionError ?? this.lastConnectionError),
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  /// 与另一个 settings 合并（other 字段优先），用于：
  /// - 本地版启动: 把用户在前端填的 URL/Key 合并进默认设置
  /// - 云端版启动: 把编译时注入的 URL/Key 合并进用户偏好（默认 cloud 模式）
  AppSettings mergeWith(AppSettings other) {
    return AppSettings(
      mode: other.mode.isNotEmpty ? other.mode : mode,
      supabaseUrl:
          other.supabaseUrl.isNotEmpty ? other.supabaseUrl : supabaseUrl,
      supabaseAnonKey: other.supabaseAnonKey.isNotEmpty
          ? other.supabaseAnonKey
          : supabaseAnonKey,
      autoSyncEnabled: other.autoSyncEnabled,
      lastConnectionError: other.lastConnectionError,
      lastConnectedAt: other.lastConnectedAt ?? lastConnectedAt,
    );
  }

  /// 转为 JSON 用于持久化
  Map<String, dynamic> toJson() => {
        'mode': mode,
        'supabaseUrl': supabaseUrl,
        'supabaseAnonKey': supabaseAnonKey,
        'autoSyncEnabled': autoSyncEnabled,
        'lastConnectionError': lastConnectionError,
        'lastConnectedAt': lastConnectedAt,
      };

  /// 从 JSON 恢复
  factory AppSettings.fromJson(Map<dynamic, dynamic> json) {
    return AppSettings(
      mode: (json['mode'] as String?) ?? 'local',
      supabaseUrl: (json['supabaseUrl'] as String?) ?? '',
      supabaseAnonKey: (json['supabaseAnonKey'] as String?) ?? '',
      autoSyncEnabled: (json['autoSyncEnabled'] as bool?) ?? true,
      lastConnectionError: json['lastConnectionError'] as String?,
      lastConnectedAt: json['lastConnectedAt'] as String?,
    );
  }
}
