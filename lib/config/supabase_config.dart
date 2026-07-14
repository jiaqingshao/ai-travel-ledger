/// AI 旅行账本 - Supabase 预配置 (云端版编译时硬编码)
///
/// ## 用途
/// - **本地版** (`flutter build apk --release`)：使用 [SupabaseService] 的 runtime 配置模式
///   - 用户在 app 里手动填 URL + Key（保存在 Hive `appSettings` box）
///   - 适合个人/隐私优先/无云场景
///
/// - **云端版** (`flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=***)
///   - 编译时通过 --dart-define 注入预配置值
///   - 用户安装即用，无须配置
///   - 适合团队/多设备同步场景
///
/// ## 使用
/// ```dart
/// // 在 main() 启动时:
/// final settings = userSettings.mergeWith(SupabaseConfig.cloudDefaults);
/// await SupabaseService.instance.init(settings: settings);
/// ```
///
/// ## 为什么不在 SupabaseConfig 里写死 URL/Key
/// - **避免 anon key 泄漏到 git 公开仓库**
/// - 编译时通过 --dart-define 注入 + 公开 API 读取 = "secure build-time configuration"
/// - 用户给的 anon key 走环境变量 / CI secret，不入仓
library;

import '../data/models/app_settings.dart';

/// Supabase 编译时配置（云端版注入 / 本地版留空）
class SupabaseConfig {
  SupabaseConfig._();

  /// 编译时注入的 Supabase URL
  ///
  /// 来源 (优先级):
  /// 1. `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co`
  /// 2. `String.fromEnvironment('SUPABASE_URL')` 编译期常量
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// 编译时注入的 Supabase anon key (公开 key，可入仓但建议走 secret)
  ///
  /// 来源: `--dart-define=SUPABASE_ANON_KEY=***`
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// 当前 build 是否启用了预配置云模式
  ///
  /// - true: 编译时注入了 SUPABASE_URL + SUPABASE_ANON_KEY → 默认开启云模式
  /// - false: 本地版，用户需手动配置或在 app 内启用
  static bool get isCloudBuild =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// 应用 launcher 名称后缀（区分本地/云端版）
  ///
  /// - 本地版: "AI 旅行账本"
  /// - 云端版: "AI 旅行账本 · 云"
  static String get appLabel {
    if (isCloudBuild) return 'AI 旅行账本 · 云';
    return 'AI 旅行账本';
  }

  /// 应用 versionName（用于 about 页面显示）
  ///
  /// 优先级:
  /// 1. 编译时 --dart-define=APP_VERSION_NAME=v1.2.0+0
  /// 2. 默认 v1.2.0+0
  static const String appVersionName = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '1.2.0+0',
  );

  /// Build variant tag（区分本地版 / 云端版 用于 telemetry 和调试）
  ///
  /// - 本地版: 'local'
  /// - 云端版: 'cloud'
  static String get buildVariant => isCloudBuild ? 'cloud' : 'local';

  /// 云端版默认 AppSettings（包含编译时注入的 URL + anon key）
  ///
  /// 仅在 [isCloudBuild] 为 true 时有效。使用方式:
  /// ```dart
  /// final merged = userSettings.mergeWith(SupabaseConfig.cloudDefaults);
  /// ```
  static AppSettings get cloudDefaults => const AppSettings(
        mode: 'cloud',
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
      );
}
