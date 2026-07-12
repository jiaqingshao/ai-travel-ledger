/// AI 旅行账本 - 费用附件元数据 (ISSUE-026)
///
/// 单个附件的元数据：URL、文件名、大小、MIME、上传时间、本地暂存路径。
///
/// **数据流**：
/// 1. 用户拍照/选图 → 本地路径 (`localPath`)
/// 2. 上传到 Supabase Storage → 公开 URL (`url`)
/// 3. 提交 expense 时, Expense.attachments 列表里存 `{Attachment}`
///
/// **Hive typeId**: 15 (接 TransferRecord=14 后面)
///
/// **JSON toMap/toJson**: 用于 Supabase 同步, `expenses.attachment_metadata` JSONB 字段
/// 实际生产用 string[] 存 URL, 这个模型用于本地 Hive box (key='expense_<expenseId>')

import 'package:hive/hive.dart';

part 'attachment.g.dart';

@HiveType(typeId: 15)
class Attachment {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final int sizeBytes;

  @HiveField(3)
  final String mimeType;

  /// 上传到云端完成时间 (UTC, 本地为 ISO8601 string)
  @HiveField(4)
  final String uploadedAt;

  /// 本地暂存路径 (上传成功后清空)
  /// 用于离线模式: 拍照/选图后路径放这里, 联网上传后置 null
  @HiveField(5)
  final String? localPath;

  const Attachment({
    required this.url,
    required this.fileName,
    required this.sizeBytes,
    required this.mimeType,
    required this.uploadedAt,
    this.localPath,
  });

  /// 从相机/相册 picker 拿到本地文件后构造 (此时 url 是空的, uploadedAt 用本地时间)
  factory Attachment.fromLocal({
    required String localPath,
    required String fileName,
    required int sizeBytes,
    required String mimeType,
  }) {
    return Attachment(
      url: '',
      fileName: fileName,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      uploadedAt: DateTime.now().toUtc().toIso8601String(),
      localPath: localPath,
    );
  }

  /// 上传成功后返回一个"已上传"副本 (清空 localPath, 设 url)
  Attachment markUploaded({required String publicUrl}) => Attachment(
        url: publicUrl,
        fileName: fileName,
        sizeBytes: sizeBytes,
        mimeType: mimeType,
        uploadedAt: DateTime.now().toUtc().toIso8601String(),
        localPath: null,
      );

  bool get isUploaded => url.isNotEmpty && localPath == null;
  bool get isPending => localPath != null && url.isEmpty;

  Map<String, dynamic> toJson() => {
        'url': url,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
        'uploadedAt': uploadedAt,
        'localPath': localPath,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        url: json['url'] as String? ?? '',
        fileName: json['fileName'] as String? ?? 'unknown',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        uploadedAt: json['uploadedAt'] as String? ?? '',
        localPath: json['localPath'] as String?,
      );
}
