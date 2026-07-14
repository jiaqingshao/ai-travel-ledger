/// AI 旅行账本 - Build Milestone 元数据
///
/// 用于标记特别的里程碑版本（例如：首次云端版、本地里程碑等）。
///
/// ## 用法
///
/// **在代码中读取**：
/// ```dart
/// if (BuildMilestone.isMilestoneBuild) {
///   print('🏆 ${BuildMilestone.tag}');
///   print('   ${BuildMilestone.title}');
/// }
/// ```
///
/// **在 UI 中显示**（About 页面已自动支持）：
/// - 编译时注入 `BUILD_MILESTONE_TAG=🏆 Cloud Milestone`
/// - 编译时注入 `BUILD_MILESTONE_ID=cloud-v1.2`
/// - 编译时注入 `BUILD_MILESTONE_TITLE=首个云端同步版 ...`
/// - 编译时注入 `BUILD_MILESTONE_DATE=2026-07-14`
/// → About 页面顶部出现金棕色徽章 + 详情卡片
///
/// **如何构建里程碑版本**：
/// ```powershell
/// pwsh scripts\build-cloud-milestone.ps1
/// ```
///
/// ## 与 build variant 的区别
///
/// - `SupabaseConfig.buildVariant` = 'local' | 'cloud'（必有之一）
/// - `BuildMilestone.isMilestoneBuild` = bool（可叠加在本地或云端之上）
/// - 普通 build: `isMilestoneBuild = false` → 走标准路径
/// - 里程碑 build: `isMilestoneBuild = true` → 额外显示徽章 + 文档
library;

/// 编译时注入的 milestone tag（badge 显示文案，e.g. "🏆 Cloud Milestone"）
const String _milestoneTag = String.fromEnvironment(
  'BUILD_MILESTONE_TAG',
  defaultValue: '',
);

/// 编译时注入的 milestone 唯一 ID（用于 telemetry / 区分版本，e.g. "cloud-v1.2"）
const String _milestoneId = String.fromEnvironment(
  'BUILD_MILESTONE_ID',
  defaultValue: '',
);

/// 编译时注入的 milestone 标题（详情卡片主标题，e.g. "首个云端同步版本"）
const String _milestoneTitle = String.fromEnvironment(
  'BUILD_MILESTONE_TITLE',
  defaultValue: '',
);

/// 编译时注入的 milestone 简介（详情卡片正文，e.g. "原生集成 Supabase 云同步..."）
const String _milestoneSubtitle = String.fromEnvironment(
  'BUILD_MILESTONE_SUBTITLE',
  defaultValue: '',
);

/// 编译时注入的 milestone 发布日期（详情卡片右侧，e.g. "2026-07-14"）
const String _milestoneDate = String.fromEnvironment(
  'BUILD_MILESTONE_DATE',
  defaultValue: '',
);

/// Build Milestone 命名空间
class BuildMilestone {
  BuildMilestone._();

  /// tag（徽章文案）
  static const String tag = _milestoneTag;

  /// 唯一 ID（用于 telemetry / 搜索）
  static const String id = _milestoneId;

  /// 标题（详情卡片主标题）
  static const String title = _milestoneTitle;

  /// 简介（详情卡片正文）
  static const String subtitle = _milestoneSubtitle;

  /// 发布日期（详情卡片右下）
  static const String date = _milestoneDate;

  /// 是否为里程碑 build
  ///
  /// - true: 编译时注入了至少一个 milestone 字段（通常是 `_milestoneTag`）
  /// - false: 普通 build，走标准路径
  ///
  /// 注意：不能直接 `_milestoneTag.isNotEmpty`，因为 `isNotEmpty`
  /// 是运行时 getter（不是 const context）。改用 `length > 0` + const 比较。
  static const bool isMilestoneBuild = _milestoneTag.length > 0;
}
