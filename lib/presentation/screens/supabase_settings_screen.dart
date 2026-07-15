import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_service.dart';
import '../../data/models/app_settings.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../providers/core_providers.dart';

/// 云端设置页面 (2026-07-11 新增)
///
/// 用户在 APP 内输入 Supabase URL 和 anon key,
/// 运行时切换云端/本地模式, 失败自动回退本地
class SupabaseSettingsScreen extends ConsumerStatefulWidget {
  const SupabaseSettingsScreen({super.key});

  @override
  ConsumerState<SupabaseSettingsScreen> createState() => _SupabaseSettingsScreenState();
}

class _SupabaseSettingsScreenState extends ConsumerState<SupabaseSettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _obscureKey = true;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    // 启动时填入已有设置
    final s = ref.read(appSettingsRepositoryProvider).load();
    _urlCtrl.text = s.supabaseUrl;
    _keyCtrl.text = s.supabaseAnonKey;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();

    // 基础校验
    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _busy = false;
        _error = 'URL 和 anon key 都不能为空';
      });
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _busy = false;
        _error = 'URL 必须以 http:// 或 https:// 开头';
      });
      return;
    }
    if (key.length < 50) {
      setState(() {
        _busy = false;
        _error = 'anon key 太短, 请检查是否复制完整 (通常 100+ 字符)';
      });
      return;
    }

    final repo = ref.read(appSettingsRepositoryProvider);
    final newSettings = AppSettings(
      mode: 'cloud',
      supabaseUrl: url,
      supabaseAnonKey: key,
      autoSyncEnabled: true,
    );

    // 先保存设置
    await repo.save(newSettings);

    // 运行时切换
    final result = await SupabaseService.instance.switchMode(newSettings);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _busy = false;
        _success = '✅ 已连接到云端: $url';
      });
    } else {
      // 失败: 回退到本地, 但保留用户输入的配置 (下次再试)
      await repo.save(newSettings.copyWith(
        mode: 'local',
        lastConnectionError: result.error,
      ));
      setState(() {
        _busy = false;
        _error = '❌ 连接失败, 已回退本地模式\n\n${result.error ?? "未知错误"}\n\n请检查:\n• URL 是否正确\n• anon key 是否完整\n• 网络是否可达';
      });
    }
  }

  Future<void> _switchToLocal() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    await SupabaseService.instance.switchToLocal();

    final repo = ref.read(appSettingsRepositoryProvider);
    final current = repo.load();
    await repo.save(current.copyWith(
      mode: 'local',
      clearError: true,
    ));

    if (!mounted) return;
    setState(() {
      _busy = false;
      _success = '✅ 已切换到本地模式 (云端配置已保留)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('云端设置'),
        actions: [
          IconButton(
            tooltip: '粘贴示例',
            icon: const Icon(Icons.paste_outlined),
            onPressed: _pasteExample,
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(settings: settings),
              const SizedBox(height: 16),
              _ConfigForm(
                urlCtrl: _urlCtrl,
                keyCtrl: _keyCtrl,
                obscureKey: _obscureKey,
                onToggleObscure: () =>
                    setState(() => _obscureKey = !_obscureKey),
              ),
              const SizedBox(height: 16),
              if (_error != null) _MessageCard(text: _error!, color: theme.colorScheme.error),
              if (_success != null) _MessageCard(text: _success!, color: theme.colorScheme.tertiary),
              const SizedBox(height: 16),
              _ActionButtons(
                busy: _busy,
                isCloudMode: settings.isCloudMode,
                hasConfig: settings.hasSupabaseConfig,
                onConnect: _connect,
                onSwitchToLocal: _switchToLocal,
              ),
              const SizedBox(height: 24),
              _HelpCard(),
            ],
          ),
        ),
      ),
    );
  }

  void _pasteExample() {
    setState(() {
      _urlCtrl.text = 'https://YOUR-PROJECT.supabase.co';
      _keyCtrl.text = '<粘贴你的 anon key>';
    });
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCloud = settings.isCloudMode;
    final hasConfig = settings.hasSupabaseConfig;

    Color bg;
    IconData icon;
    String title;
    String subtitle;

    if (isCloud) {
      bg = theme.colorScheme.tertiaryContainer;
      icon = Icons.cloud_done;
      title = '云端模式 · 已连接';
      subtitle = settings.supabaseUrl;
    } else if (hasConfig) {
      bg = theme.colorScheme.errorContainer;
      icon = Icons.cloud_off;
      title = '云端配置存在 · 未连接';
      subtitle = '上次错误: ${settings.lastConnectionError ?? "未知"}';
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      icon = Icons.cloud_queue;
      title = '本地模式';
      subtitle = '数据存储在设备本地, 卸载 APP = 数据清空';
    }

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigForm extends StatelessWidget {
  const _ConfigForm({
    required this.urlCtrl,
    required this.keyCtrl,
    required this.obscureKey,
    required this.onToggleObscure,
  });

  final TextEditingController urlCtrl;
  final TextEditingController keyCtrl;
  final bool obscureKey;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Supabase 配置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('从 Supabase Dashboard > Settings > API 获取',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Project URL',
                hintText: 'https://xxx.supabase.co',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              obscureText: obscureKey,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'anon public key',
                hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: onToggleObscure,
                  tooltip: obscureKey ? '显示' : '隐藏',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.busy,
    required this.isCloudMode,
    required this.hasConfig,
    required this.onConnect,
    required this.onSwitchToLocal,
  });

  final bool busy;
  final bool isCloudMode;
  final bool hasConfig;
  final VoidCallback onConnect;
  final VoidCallback onSwitchToLocal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: busy ? null : onConnect,
          icon: busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(busy ? '连接中...' : (isCloudMode ? '重新连接' : '连接云端')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        if (isCloudMode || hasConfig)
          OutlinedButton.icon(
            onPressed: busy ? null : onSwitchToLocal,
            icon: const Icon(Icons.cloud_off_outlined),
            label: const Text('切换到本地模式'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: color, fontSize: 13)),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {},
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.help_outline, size: 18),
                SizedBox(width: 6),
                Text('使用说明', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('1. 注册 Supabase: https://supabase.com\n'
                '2. 创建项目, 执行 supabase/migrations/*.sql 迁移\n'
                '3. Settings > API 复制 Project URL 和 anon key\n'
                '4. 粘贴到上方, 点"连接云端"\n'
                '5. 连接失败会自动回退本地模式, 不影响使用',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('联系开发者获取帮助: https://github.com/jiaqingshao/ai-travel-ledger/issues',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}