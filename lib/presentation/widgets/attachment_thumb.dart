/// AI 旅行账本 - 附件缩略图组件 (ISSUE-026 step 2)
///
/// 渲染单个附件的缩略图（96x96）：
/// - 已上传（url 非空）→ CachedNetworkImage 加载
/// - 上传中（pending）→ 显示本地 FileImage + LinearProgressIndicator
/// - 长按显示删除确认
///
/// 依赖: cached_network_image (pubspec.yaml 已声明)
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/attachment.dart';
import '../../data/repositories/attachment_repository.dart';

class AttachmentThumb extends StatelessWidget {
  const AttachmentThumb({
    super.key,
    required this.attachment,
    this.size = 96,
    this.onTap,
    this.onDelete,
    this.uploading = false,
  });

  final Attachment attachment;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  /// 是否上传中（pending 状态时显示进度条覆盖）
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    Widget image;
    if (AttachmentRepository.isLocalUrl(attachment.url)) {
      // ISSUE-039: 本地沙盒文件 → Image.file
      final localPath = AttachmentRepository.localPathFromUrl(attachment.url);
      if (localPath != null && File(localPath).existsSync()) {
        image = Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 28),
          ),
        );
      } else {
        // 沙盒文件被外部删除 (清理缓存等)
        image = Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, size: 28),
        );
      }
    } else if (attachment.url.isNotEmpty) {
      // 已上传 → 网络图
      image = CachedNetworkImage(
        imageUrl: attachment.url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.errorContainer,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 28,
          ),
        ),
      );
    } else if (attachment.localPath != null &&
        File(attachment.localPath!).existsSync()) {
      // 未上传 → 本地图
      image = Image.file(
        File(attachment.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.errorContainer,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 28),
        ),
      );
    } else {
      image = Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 28),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: GestureDetector(
                onTap: onTap,
                onLongPress:
                    onDelete == null ? null : () => _confirmDelete(context),
                child: image,
              ),
            ),
          ),
          if (uploading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (attachment.fileName.isNotEmpty && !uploading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black54,
                  child: Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除附件'),
        content: const Text('确定要删除这张附件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && onDelete != null) onDelete!();
  }
}
