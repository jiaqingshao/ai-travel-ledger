import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_service.dart';
import '../providers/sync_providers.dart';

/// 登录/注册页
///
/// 当 Supabase 未配置时显示"云端同步未启用"提示
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true; // true=登录, false=注册
  bool _busy = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = '请输入邮箱和密码');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final notifier = ref.read(authStateProvider.notifier);
    final err = _isLogin
        ? await notifier.signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          )
        : await notifier.signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text.trim().isEmpty
                ? null
                : _nameCtrl.text.trim(),
          );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });

    if (err == null) {
      // 成功 → 关闭
      Navigator.of(context).pop(true);
      return;
    }

    // ISSUE-021: 增强错误提示 - 邮箱未验证提示
    if (!_isLogin && err.toLowerCase().contains('email not confirmed')) {
      setState(() {
                _error = '✉️ 注册成功！\n请到邮箱中点击验证链接，\n然后返回本页登录。\n原错误：' + err;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Supabase 未配置 - 显示友好提示
    // ISSUE-029 修复：去掉 CLI 命令，改用面向普通用户的文案
    if (!SupabaseService.instance.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('云端同步')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 72,
                    color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  '云端同步未配置',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '当前为本地模式，数据保存在设备本地。\n'
                  '如需开启云同步（多设备备份），请联系开发者：\n'
                  'litiboy@163.com',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '您可以继续本地使用本软件',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('知道了，返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 正常登录/注册表单
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '登录' : '注册')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.cloud_sync, size: 64,
                  color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _isLogin ? '登录 AI 旅行账本' : '创建账号',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '登录后可同步数据到云端,多设备共享',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '昵称(可选)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码(至少 6 位)',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLogin ? '登录' : '注册'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                        }),
                child: Text(_isLogin ? '没有账号?注册' : '已有账号?登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}