// AI 旅行账本 - AttachmentThumb 组件测试 (ISSUE-026 step 2)
//
// 覆盖:
// - 已上传 (url 非空): 渲染 AttachmentThumb
// - 上传中 (uploading=true): 显示上传中覆盖 (黑色 + 进度指示器)
// - 无 url 无 localPath: 显示 image_not_supported 图标
// - 长按触发 onDelete (弹确认对话框 + 点击删除触发回调)
//
// 注: 不测试图片实际加载 (CachedNetworkImage / Image.file 在测试环境难控制)

import 'package:ai_travel_ledger/data/models/attachment.dart';
import 'package:ai_travel_ledger/presentation/widgets/attachment_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AttachmentThumb', () {
    testWidgets('已上传: 渲染 AttachmentThumb 组件', (tester) async {
      const a = Attachment(
        url: 'https://example.supabase.co/x.jpg',
        fileName: 'x.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
        uploadedAt: '2026-07-12',
      );
      await tester.pumpWidget(_wrap(const AttachmentThumb(attachment: a)));
      await tester.pump();
      expect(find.byType(AttachmentThumb), findsOneWidget);
    });

    testWidgets('上传中: 黑色覆盖 + CircularProgressIndicator', (tester) async {
      final a = Attachment.fromLocal(
        localPath: 'C:\\fake\\path.jpg',
        fileName: 'path.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      await tester.pumpWidget(_wrap(
        AttachmentThumb(attachment: a, uploading: true),
      ));
      await tester.pump();
      expect(find.byType(AttachmentThumb), findsOneWidget);
      // 上传中覆盖层: 找 CircularProgressIndicator (color: white)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('无 url 无 localPath: 显示 image_not_supported 图标', (tester) async {
      const a = Attachment(
        url: '',
        fileName: '',
        sizeBytes: 0,
        mimeType: 'image/jpeg',
        uploadedAt: '',
      );
      await tester.pumpWidget(_wrap(const AttachmentThumb(attachment: a)));
      await tester.pump();
      expect(find.byType(AttachmentThumb), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('本地文件不存在: 显示 broken_image 图标 (Image.file errorBuilder)',
        (tester) async {
      final a = Attachment.fromLocal(
        localPath: 'C:\\nonexistent\\path\\fake.jpg',
        fileName: 'fake.jpg',
        sizeBytes: 0,
        mimeType: 'image/jpeg',
      );
      await tester.pumpWidget(_wrap(AttachmentThumb(attachment: a)));
      // Image.file 是异步的, 多 pump 几次等 errorBuilder 触发
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AttachmentThumb), findsOneWidget);
    });

    testWidgets('长按触发 onDelete (弹确认对话框 + 点击删除触发回调)',
        (tester) async {
      const a = Attachment(
        url: 'https://example.com/x.jpg',
        fileName: 'x.jpg',
        sizeBytes: 0,
        mimeType: 'image/jpeg',
        uploadedAt: '2026-07-12',
      );
      var deleted = false;
      await tester.pumpWidget(_wrap(
        AttachmentThumb(
          attachment: a,
          onDelete: () => deleted = true,
        ),
      ));
      // 长按触发
      await tester.longPress(find.byType(AttachmentThumb));
      // 弹对话框动画, 用 pump 不用 pumpAndSettle (CachedNetworkImage 持续 loading)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('删除附件'), findsOneWidget);
      // 点击删除
      await tester.tap(find.text('删除'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(deleted, isTrue);
    });
  });
}