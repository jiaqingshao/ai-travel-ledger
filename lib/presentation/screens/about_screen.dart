import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/build_milestone.dart';
import '../../config/supabase_config.dart';

/// AI 旅行账本 - 关于页面
///
/// ISSUE-030: 显示应用信息、版本、作者联系方式、技术栈、开源仓库
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // 应用元数据（ISSUE-030）
  static const String _appName = 'AI 旅行账本';
  static const String _appNameEn = 'AI Travel Ledger';
  // 版本从编译时常量读取（统一来源：SupabaseConfig）
  // - 本地版默认 1.2.0+0
  // - 云端版可通过 --dart-define=APP_VERSION_NAME=vX.Y.Z 覆盖
  static const String _version = SupabaseConfig.appVersionName;
  static const String _authorEmail = 'litiboy@163.com';
  static const String _githubUrl = 'https://github.com/jiaqingshao/ai-travel-ledger';
  static const String _releaseDate = '2026-07-13';
  static const String _description = '自驾游/团队游场景的智能记账与分摊工具。让多人 AA 结算从 30 分钟缩短到 30 秒。';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============ Logo + 名称 ============
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.travel_explore,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _appNameEn,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v$_version',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ============ 🏆 里程碑徽章 (仅 milestone build 显示) ============
            if (BuildMilestone.isMilestoneBuild) ...[
              _MilestoneBadge(
                tag: BuildMilestone.tag,
                title: BuildMilestone.title,
                subtitle: BuildMilestone.subtitle,
                date: BuildMilestone.date,
                id: BuildMilestone.id,
              ),
              const SizedBox(height: 16),
            ],

            // ============ 简介 ============
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('简介', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ============ 作者联系 ============
            Card(
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.alternate_email,
                    label: '作者邮箱',
                    value: _authorEmail,
                    onTap: () => _copyToClipboard(context, _authorEmail),
                  ),
                  const Divider(height: 1),
                  _ContactTile(
                    icon: Icons.code,
                    label: '开源仓库',
                    value: _githubUrl,
                    onTap: () => _copyToClipboard(context, _githubUrl),
                  ),
                  const Divider(height: 1),
                  _ContactTile(
                    icon: Icons.calendar_today_outlined,
                    label: '发布日期',
                    value: _releaseDate,
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ============ 技术栈 ============
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.layers_outlined, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('技术栈', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _TechRow(label: 'Flutter', value: '3.24.5'),
                    _TechRow(label: 'Dart', value: '3.5.4'),
                    _TechRow(label: '状态管理', value: 'Riverpod 2.x'),
                    _TechRow(label: '本地存储', value: 'Hive + SQLite'),
                    _TechRow(label: '云同步', value: 'Supabase (可选)'),
                    _TechRow(label: '设计', value: 'Material 3 + 旅行蓝主题'),
                    _TechRow(label: '最低系统', value: 'Android 5.0+ / iOS 12+'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ============ 致谢 ============
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite_outline, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('致谢', style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '感谢以下开源项目：\n'
                      '• Flutter & Dart\n'
                      '• Riverpod 状态管理\n'
                      '• Hive 本地存储\n'
                      '• Supabase BaaS\n'
                      '• Material Design 3',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ============ 版权 ============
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 AI 旅行账本 · 个人项目',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '由 MiniMax-M3 与开发者协作完成',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onTap != null
          ? const Icon(Icons.copy_outlined, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
      dense: true,
    );
  }
}

class _TechRow extends StatelessWidget {
  const _TechRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🏆 里程碑徽章 + 详情卡片（仅 milestone build 显示）
///
/// 让里程碑版本在 About 页面顶部有一个金棕色醒目标记,
/// 方便测试/分发时一眼能辨识。
class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.id,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String date;
  final String id;

  @override
  Widget build(BuildContext context) {
    // 金棕色 palette (Apple-style Gold + Bronze)
    const goldBg = Color(0xFFFFF8E1);
    const goldFg = Color(0xFF8B6914);
    const goldBorder = Color(0xFFD4A642);
    const goldGradStart = Color(0xFFFFD54F);
    const goldGradEnd = Color(0xFFFFA726);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [goldBg, Color(0xFFFFEBC2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: goldBorder.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部: 奖杯 + tag + date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [goldGradStart, goldGradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: goldFg,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      id,
                      style: TextStyle(
                        fontSize: 11,
                        color: goldFg.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: goldBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E342E),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: goldFg.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // 底部分割线 + milestone ID 重复（防潮吧）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '这是里程碑版本 · 不定期推荐给用户时使用',
                style: TextStyle(
                  fontSize: 10,
                  color: goldFg.withOpacity(0.6),
                ),
              ),
              Text(
                id,
                style: TextStyle(
                  fontSize: 10,
                  color: goldFg.withOpacity(0.5),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
