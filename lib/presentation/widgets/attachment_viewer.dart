/// AI 旅行账本 - 附件全屏预览 (ISSUE-026 step 2)
///
/// - PageView 左右滑动切换
/// - Hero 动画从缩略图过渡（如果提供了 heroTagPrefix）
/// - 长按关闭
/// - 双击缩放（InteractiveViewer 内置支持）
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/attachment.dart';
import '../../data/repositories/attachment_repository.dart';

class AttachmentViewer extends StatefulWidget {
  const AttachmentViewer({
    super.key,
    required this.attachments,
    this.initialIndex = 0,
  });

  final List<Attachment> attachments;
  final int initialIndex;

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1} / ${widget.attachments.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: GestureDetector(
        onLongPress: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _ctrl,
          itemCount: widget.attachments.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final a = widget.attachments[i];
            return InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: _buildImage(a),
              ),
            );
          },
        ),
      ),
    );
  }

  /// ISSUE-039: 支持本地沙盒附件 (file:// 路径)
  Widget _buildImage(Attachment a) {
    // 本地沙盒
    if (AttachmentRepository.isLocalUrl(a.url)) {
      final localPath = AttachmentRepository.localPathFromUrl(a.url);
      if (localPath != null && File(localPath).existsSync()) {
        return Image.file(
          File(localPath),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 64,
          ),
        );
      }
      return const Icon(
        Icons.broken_image,
        color: Colors.white54,
        size: 64,
      );
    }
    // 网络
    if (a.url.isEmpty) {
      return const Icon(
        Icons.broken_image,
        color: Colors.white54,
        size: 64,
      );
    }
    return CachedNetworkImage(
      imageUrl: a.url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.broken_image,
        color: Colors.white54,
        size: 64,
      ),
    );
  }
}
