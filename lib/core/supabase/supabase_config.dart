/// AI 旅行账本 - Supabase 配置
///
/// 使用方式：
/// 1. 在 https://supabase.com 创建项目
/// 2. 复制 Project URL 和 anon key
/// 3. 填到下方常量（或用 --dart-define 注入）
/// 4. 在 SQL Editor 执行 supabase/migrations/*.sql
///
/// 国内访问：建议自托管或用 CloudBase 替代
class SupabaseConfig {
  /// Supabase Project URL
  /// 例：https://xxxxxxxxxxxxx.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase anon public key
  /// 例：eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  /// 是否已配置（值不是默认占位符且非空且 URL 合法）
  ///
  /// 防护场景:
  /// - 构建时传入空字符串 (--dart-define=SUPABASE_URL=)
  /// - URL 不以 http 开头（误填）
  /// - 占位符未替换
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url != 'https://your-project.supabase.co' &&
      anonKey != 'your-anon-key-here' &&
      (url.startsWith('http://') || url.startsWith('https://'));

  /// Storage bucket 名（票据照片）
  static const String receiptBucket = 'receipts';

  /// 同步间隔（秒）- 后台定时同步
  static const int syncIntervalSeconds = 30;

  /// API 超时（秒）
  static const int apiTimeoutSeconds = 15;
}