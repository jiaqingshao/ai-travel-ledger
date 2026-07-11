import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AI 旅行账本 - 关于页面
///
/// ISSUE-030: 显示应用信息、版本、作者联系方式、技术栈、开源仓库
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // 应用元数据（ISSUE-030）
  static const String _appName = 'AI 旅行账本';
  static const String _appNameEn = 'AI Travel Ledger';
  static const String _version = '1.0.0+0';
  static const String _authorEmail = 'litiboy@163.com';
  static const String _githubUrl = 'https://github.com/jiaqingshao/ai-travel-ledger';
  static const String _releaseDate = '2026-07-11';
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