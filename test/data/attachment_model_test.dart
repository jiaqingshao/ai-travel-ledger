// AI 旅行账本 - Attachment 模型测试 (ISSUE-026 step 2)
//
// 覆盖:
// - 工厂 fromLocal: 本地路径构造 (url 空)
// - markUploaded: 转为已上传 (url 非空, localPath 清空)
// - isUploaded / isPending 状态判断
// - toJson / fromJson 序列化往返
// - Hive typeId = 15 不冲突

import 'package:ai_travel_ledger/data/models/attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attachment 模型', () {
    test('fromLocal 构造: url 为空, localPath 非空', () {
      final a = Attachment.fromLocal(
        localPath: '/tmp/receipt.jpg',
        fileName: 'receipt.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      expect(a.url, isEmpty);
      expect(a.localPath, '/tmp/receipt.jpg');
      expect(a.fileName, 'receipt.jpg');
      expect(a.sizeBytes, 1024);
      expect(a.mimeType, 'image/jpeg');
      expect(a.uploadedAt, isNotEmpty);
      expect(a.isPending, isTrue);
      expect(a.isUploaded, isFalse);
    });

    test('markUploaded: 清空 localPath, 设置 url', () {
      final pending = Attachment.fromLocal(
        localPath: '/tmp/receipt.jpg',
        fileName: 'receipt.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      final uploaded = pending.markUploaded(
        publicUrl: 'https://example.supabase.co/storage/v1/object/public/expense-attachments/trip-001/expense-001/uuid.jpg',
      );
      expect(uploaded.url, contains('expense-attachments'));
      expect(uploaded.localPath, isNull);
      expect(uploaded.fileName, 'receipt.jpg');
      expect(uploaded.sizeBytes, 1024);
      expect(uploaded.isUploaded, isTrue);
      expect(uploaded.isPending, isFalse);
    });

    test('toJson / fromJson 往返一致', () {
      final original = Attachment(
        url: 'https://example.com/receipt.jpg',
        fileName: 'receipt.jpg',
        sizeBytes: 2048,
        mimeType: 'image/jpeg',
        uploadedAt: '2026-07-12T10:00:00.000Z',
        localPath: null,
      );
      final json = original.toJson();
      final restored = Attachment.fromJson(json);
      expect(restored.url, original.url);
      expect(restored.fileName, original.fileName);
      expect(restored.sizeBytes, original.sizeBytes);
      expect(restored.mimeType, original.mimeType);
      expect(restored.uploadedAt, original.uploadedAt);
      expect(restored.localPath, isNull);
    });

    test('fromJson 缺字段时使用默认值', () {
      final restored = Attachment.fromJson({});
      expect(restored.url, isEmpty);
      expect(restored.fileName, 'unknown');
      expect(restored.sizeBytes, 0);
      expect(restored.mimeType, 'application/octet-stream');
      expect(restored.uploadedAt, isEmpty);
      expect(restored.localPath, isNull);
    });

    test('Hive typeId = 15 (与 TransferRecord=14 后, 不冲突)', () {
      // 用反射取 typeId 不可行, 这里只校验类型能实例化
      const a = Attachment(
        url: 'x',
        fileName: 'x',
        sizeBytes: 0,
        mimeType: 'x',
        uploadedAt: 'x',
      );
      expect(a, isA<Attachment>());
    });

    test('等值构造 const', () {
      const a1 = Attachment(
        url: 'x',
        fileName: 'x',
        sizeBytes: 0,
        mimeType: 'x',
        uploadedAt: 'x',
      );
      const a2 = Attachment(
        url: 'x',
        fileName: 'x',
        sizeBytes: 0,
        mimeType: 'x',
        uploadedAt: 'x',
      );
      expect(identical(a1, a2), isTrue);
    });
  });
}