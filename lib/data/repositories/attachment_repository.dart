/// AI 旅行账本 - 附件仓储 (ISSUE-026)
///
/// 负责:
/// - 上传本地文件到 Supabase Storage (`expense-attachments/<tripId>/<expenseId>/<uuid>.<ext>`)
/// - 删除云端附件 (含删除 trip / expense 时的级联清理)
/// - 本地缓存: Hive box `attachments` (key = `<expenseId>_<uuid>`)
///
/// **依赖**: SupabaseService (cloud), Hive (local cache)
/// **运行时**: 仅在 cloud 模式 (`AppSettings.isCloudMode`) 下生效;
///             本地模式只走本地, 不上传
///
/// **MVP 范围 (本步只做第 1 步)**:
/// 1. ✅ 上传本地图片到 Supabase Storage
/// 2. ✅ 返回公开 URL + 元数据
/// 3. ⏳ 离线队列 (后续 ISSUE-026 第 4 步)
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/attachment.dart';

class AttachmentRepository {
  AttachmentRepository({
    required SupabaseService supabase,
    required Box<Attachment> box,
  })  : _supabase = supabase,
        _box = box;

  final SupabaseService _supabase;
  final Box<Attachment> _box;

  /// Supabase Storage bucket 名 (公开读, 私有写)
  static const String bucketName = 'expense-attachments';

  /// 上传本地图片到 Supabase Storage
  ///
  /// [localPath] 本地文件路径 (image_picker 返回)
  /// [tripId] 当前旅程 ID (用于组织 storage path)
  /// [expenseId] 当前费用 ID (用于组织 storage path)
  ///
  /// 返回 [Attachment] (已 markUploaded, url 是公开 URL)
  Future<Attachment> upload({
    required String localPath,
    required String tripId,
    required String expenseId,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', localPath);
    }

    final bytes = await file.readAsBytes();
    final ext = _extensionFromPath(localPath);
    final uuid = DateTime.now().microsecondsSinceEpoch.toString();
    final path = '$tripId/$expenseId/$uuid.$ext';

    // 上传到 Supabase Storage
    final storage = _supabase.storage.from(bucketName);
    await storage.uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: _mimeFromExt(ext)),
    );

    final publicUrl = storage.getPublicUrl(path);

    return Attachment(
      url: publicUrl,
      fileName: _fileNameFromPath(localPath),
      sizeBytes: bytes.length,
      mimeType: _mimeFromExt(ext),
      uploadedAt: DateTime.now().toUtc().toIso8601String(),
      localPath: null,
    );
  }

  /// 删除云端附件 (例如删除费用时调用)
  Future<void> deleteRemote({required String remoteUrl}) async {
    // 从 URL 提取 path (去掉 bucket name + /storage/v1/object/public/)
    final uri = Uri.parse(remoteUrl);
    final segments = uri.pathSegments;
    if (segments.length < 2) return;
    // 路径以 `expense-attachments/...` 开头, 找到其下标
    final bucketIdx = segments.indexOf(bucketName);
    if (bucketIdx < 0 || bucketIdx >= segments.length - 1) return;
    final path = segments.sublist(bucketIdx + 1).join('/');
    await _supabase.storage.from(bucketName).remove([path]);
  }

  /// 本地缓存写入 (用于离线模式预览)
  Future<void> cacheLocal(Attachment attachment, {required String expenseId}) async {
    if (!attachment.isUploaded) return;
    await _box.put('${expenseId}_${attachment.fileName}', attachment);
  }

  /// 读取本地缓存
  Attachment? readLocal({required String expenseId, required String fileName}) {
    return _box.get('${expenseId}_$fileName');
  }

  /// 清除本地缓存 (例如上传成功后, 或删除费用时)
  Future<void> clearLocal({required String expenseId}) async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith('${expenseId}_'))
        .toList();
    await _box.deleteAll(keys);
  }

  static String _extensionFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'jpg';
    final ext = path.substring(dot + 1).toLowerCase();
    return ext.isEmpty ? 'jpg' : ext;
  }

  static String _fileNameFromPath(String path) {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf('\\');
    final last = [slash, backslash].reduce((a, b) => a > b ? a : b);
    return last < 0 ? path : path.substring(last + 1);
  }

  static String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
