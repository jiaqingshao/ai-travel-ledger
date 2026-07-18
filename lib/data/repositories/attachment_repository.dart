/// AI 旅行账本 - 附件仓储 (ISSUE-026 + ISSUE-039)
///
/// 负责:
/// - **云端**: 上传本地文件到 Supabase Storage (`expense-attachments/<tripId>/<expenseId>/<uuid>.<ext>`)
/// - **本地 (ISSUE-039)**: 保存到 APP 沙盒 (`getApplicationDocumentsDirectory()/attachments/...`),
///   URL 用 `file://` 前缀标识, 卸载 APP 后数据丢失 (后续可接 Auto Backup)
/// - 删除附件 (云端: Storage remove / 本地: 删沙盒文件)
/// - 本地缓存: Hive box `attachments` (key = `<expenseId>_<uuid>`)
///
/// **依赖**: SupabaseService (cloud), Hive (local cache), path_provider
/// **运行时**: 上传/保存 [upload] 入口根据 `AppSettings.isCloudMode` 自动选择云/本路径
///
/// **MVP 范围 (ISSUE-039)**:
/// 1. ✅ 沙盒文件保存 (`saveLocal`)
/// 2. ✅ `file://` URL 标识
/// 3. ✅ 本地文件删除 (`deleteLocal`)
/// 4. ⏳ 离线队列 (后续 ISSUE-026 第 4 步)
/// 5. ⏳ Auto Backup (后续 V2.0)
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
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

  /// 本地沙盒附件 URL 前缀 (用于区分 file:// 和 http(s)://)
  static const String localUrlPrefix = 'file://';

  /// 上传/保存附件 (根据 [useCloud] 走不同路径)
  ///
  /// **云端模式** ([useCloud] = true):
  /// - 上传到 Supabase Storage
  /// - 返回 [Attachment] (url 是 https:// 公开 URL)
  ///
  /// **本地模式** ([useCloud] = false):
  /// - 复制到 APP 沙盒 (`getApplicationDocumentsDirectory()/attachments/<tripId>/<expenseId>/<uuid>.<ext>`)
  /// - 返回 [Attachment] (url 是 `file://` 前缀)
  /// - 不加密 (按用户要求: "不需要考虑加密")
  /// - 卸载 APP 后数据丢失 (后续可接 Auto Backup)
  ///
  /// [localPath] 本地文件路径 (image_picker 返回)
  /// [tripId] 当前旅程 ID (用于组织路径)
  /// [expenseId] 当前费用 ID (用于组织路径)
  /// [useCloud] 是否走云端 (默认从 settings 读, 但调用者应该传明确值避免 race)
  Future<Attachment> upload({
    required String localPath,
    required String tripId,
    required String expenseId,
    bool useCloud = true,
  }) async {
    if (useCloud) {
      return _uploadToCloud(
        localPath: localPath,
        tripId: tripId,
        expenseId: expenseId,
      );
    } else {
      return _saveToLocalSandbox(
        localPath: localPath,
        tripId: tripId,
        expenseId: expenseId,
      );
    }
  }

  /// 上传到 Supabase Storage (云端模式)
  Future<Attachment> _uploadToCloud({
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

  /// ISSUE-039: 保存到 APP 沙盒 (本地模式)
  ///
  /// 路径格式: `<appDocDir>/attachments/<tripId>/<expenseId>/<uuid>.<ext>`
  /// URL 格式: `file://<绝对路径>`
  Future<Attachment> _saveToLocalSandbox({
    required String localPath,
    required String tripId,
    required String expenseId,
  }) async {
    final srcFile = File(localPath);
    if (!await srcFile.exists()) {
      throw FileSystemException('文件不存在', localPath);
    }

    final ext = _extensionFromPath(localPath);
    final uuid = DateTime.now().microsecondsSinceEpoch.toString();
    final fileName = '$uuid.$ext';

    // 目标: <appDocDir>/attachments/<tripId>/<expenseId>/<uuid>.<ext>
    final appDocDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(
      '${appDocDir.path}/attachments/$tripId/$expenseId',
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final targetPath = '${targetDir.path}/$fileName';

    // 复制文件 (不移动, 避免 image_picker 临时目录被清理)
    await srcFile.copy(targetPath);

    final sizeBytes = await File(targetPath).length();

    return Attachment(
      url: '$localUrlPrefix$targetPath',
      fileName: _fileNameFromPath(localPath),
      sizeBytes: sizeBytes,
      mimeType: _mimeFromExt(ext),
      uploadedAt: DateTime.now().toUtc().toIso8601String(),
      localPath: null,
    );
  }

  /// 删除附件 (云端 / 本地自动识别)
  ///
  /// 传进来的 url 可能是 `https://...` 或 `file://...`, 根据前缀分流
  Future<void> delete({required String url}) async {
    if (url.isEmpty) return;
    if (url.startsWith(localUrlPrefix)) {
      await _deleteLocalFile(url);
    } else {
      await deleteRemote(remoteUrl: url);
    }
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

  /// ISSUE-039: 删除本地沙盒文件
  Future<void> _deleteLocalFile(String fileUrl) async {
    final filePath = fileUrl.substring(localUrlPrefix.length);
    final file = File(filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        // 沙盒文件可能被其他原因已删 (e.g. 用户手动清缓存), 不抛
      }
    }
  }

  /// 静态 helper: 判断 URL 是否是本地沙盒附件
  static bool isLocalUrl(String url) => url.startsWith(localUrlPrefix);

  /// 静态 helper: file:// URL → 本地文件路径
  static String? localPathFromUrl(String url) {
    if (!isLocalUrl(url)) return null;
    return url.substring(localUrlPrefix.length);
  }

  /// 本地缓存写入 (用于离线模式预览)
  Future<void> cacheLocal(Attachment attachment,
      {required String expenseId}) async {
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
