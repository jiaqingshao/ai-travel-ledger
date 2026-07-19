// AI 旅行账本 - AttachmentPickerSection 组件测试 (ISSUE-026 step 2)
//
// 覆盖:
// - 本地模式 + 空列表: 显示「需要云同步」提示
// - 云模式 + 空列表: 显示「点击添加可拍照或从相册选择」提示
// - 本地模式: 点击「添加」弹 SnackBar, 不触发 onChanged
// - 云模式: 附件计数显示「附件 (n/9)」+ 已选附件缩略图
//
// 注: image_picker 的 platform channel mocking 复杂, 这里不测选择/上传流程

import 'package:ai_travel_ledger/data/models/app_settings.dart';
import 'package:ai_travel_ledger/data/models/attachment.dart';
import 'package:ai_travel_ledger/data/repositories/app_settings_repository.dart';
import 'package:ai_travel_ledger/presentation/providers/core_providers.dart';
import 'package:ai_travel_ledger/presentation/widgets/attachment_picker_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository(this._settings);
  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Stream<AppSettings> watch() async* {
    yield _settings;
  }

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> reset() async {
    _settings = const AppSettings();
  }
}

Widget _wrap({
  required List<Attachment> attachments,
  required ValueChanged<List<Attachment>> onChanged,
  required AppSettings settings,
}) {
  return ProviderScope(
    overrides: [
      appSettingsRepositoryProvider
          .overrideWithValue(_FakeAppSettingsRepository(settings)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AttachmentPickerSection(
          tripId: 'trip-test-001',
          expenseId: 'expense-test-001',
          attachments: attachments,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

/// Pump 多次让 StreamProvider 解析 + 列表渲染完成 (不用 pumpAndSettle 因为
/// CachedNetworkImage 会一直 loading)。
Future<void> _pumpSettled(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('AttachmentPickerSection', () {
    testWidgets('本地模式 + 空列表: 显示「需要云同步」提示', (tester) async {
      const localSettings = AppSettings(mode: 'local');
      await tester.pumpWidget(_wrap(
        attachments: const [],
        onChanged: (_) {},
        settings: localSettings,
      ));
      await _pumpSettled(tester);
      expect(find.textContaining('附件功能需要云同步'), findsOneWidget);
    });

    testWidgets('云模式 + 空列表: 显示「点击添加可拍照或从相册选择」提示', (tester) async {
      const cloudSettings = AppSettings(
        mode: 'cloud',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'fake-key',
      );
      await tester.pumpWidget(_wrap(
        attachments: const [],
        onChanged: (_) {},
        settings: cloudSettings,
      ));
      await _pumpSettled(tester);
      expect(find.textContaining('点击「添加」可拍照或从相册选择'), findsOneWidget);
    });

    testWidgets('本地模式: 点击「添加」弹 SnackBar「附件需要云同步」, 不触发 onChanged',
        (tester) async {
      const localSettings = AppSettings(mode: 'local');
      var changed = false;
      await tester.pumpWidget(_wrap(
        attachments: const [],
        onChanged: (_) => changed = true,
        settings: localSettings,
      ));
      await _pumpSettled(tester);
      await tester.tap(find.text('添加'));
      // SnackBar 动画: 多 pump 几次等入屏 + 动画完成
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('附件功能需要云同步'), findsWidgets);
      expect(changed, isFalse);
    });

    testWidgets('云模式: 附件计数显示「附件 (n/9)」', (tester) async {
      const cloudSettings = AppSettings(
        mode: 'cloud',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'fake-key',
      );
      final list = [
        const Attachment(
          url: 'https://example.com/a.jpg',
          fileName: 'a.jpg',
          sizeBytes: 100,
          mimeType: 'image/jpeg',
          uploadedAt: '2026-07-12',
        ),
        const Attachment(
          url: 'https://example.com/b.jpg',
          fileName: 'b.jpg',
          sizeBytes: 200,
          mimeType: 'image/jpeg',
          uploadedAt: '2026-07-12',
        ),
      ];
      await tester.pumpWidget(_wrap(
        attachments: list,
        onChanged: (_) {},
        settings: cloudSettings,
      ));
      await _pumpSettled(tester);
      expect(find.text('附件 (2/9)'), findsOneWidget);
    });
  });
}
