/// AI 旅行账本 - 附件选择区组件 (ISSUE-026 step 2)
///
/// 提供：
/// - 已选附件的横向缩略图列表（删除 + 全屏预览）
/// - "+"按钮 → 弹出选择菜单（拍照 / 相册 / 取消）
/// - 选中后立即上传到 Supabase Storage（cloud mode）
///   本地模式时弹 SnackBar 提示「附件功能需要云同步」
///
/// 通过 [onChanged] 回调把变更后的 List<Attachment> 传给父组件
///
/// 依赖: image_picker (pubspec.yaml 已声明)
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/attachment.dart';
import '../providers/core_providers.dart';
import 'attachment_thumb.dart';
import 'attachment_viewer.dart';

class AttachmentPickerSection extends ConsumerStatefulWidget {
  const AttachmentPickerSection({
    super.key,
    required this.tripId,
    required this.expenseId,
    required this.attachments,
    required this.onChanged,
    this.maxCount = 9,
  });

  /// 用于 Supabase Storage 路径组织
  final String tripId;

  /// 用于 Supabase Storage 路径组织（新建时可用 placeholder ID）
  final String expenseId;

  /// 已选附件列表（受控）
  final List<Attachment> attachments;

  /// 列表变更回调
  final ValueChanged<List<Attachment>> onChanged;

  /// 最多附件数（默认 9）
  final int maxCount;

  @override
  ConsumerState<AttachmentPickerSection> createState() =>
      _AttachmentPickerSectionState();
}

class _AttachmentPickerSectionState
    extends ConsumerState<AttachmentPickerSection> {
  final ImagePicker _picker = ImagePicker();
  final Set<String> _uploadingLocalPaths = {};

  Future<void> _showAddSheet() async {
    if (widget.attachments.length >= widget.maxCount) {
      _snack('附件已达上限 ${widget.maxCount} 张');
      return;
    }

    // 本地模式提示
    final settingsAsync = ref.read(appSettingsProvider);
    final settings = settingsAsync.asData?.value;
    if (settings == null || !settings.isCloudMode) {
      _snack('附件功能需要云同步，请先在「云端设置」中启用');
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80, // 压缩到 80% 节省 Storage 空间
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (file == null) return;

    await _uploadOne(file);
  }

  Future<void> _uploadOne(XFile xfile) async {
    final localPath = xfile.path;
    final fileName = xfile.name;
    final size = await File(localPath).length();
    final mime = _guessMimeFromName(fileName);

    // 先加一个 pending 附件（显示上传中）
    final pending = Attachment.fromLocal(
      localPath: localPath,
      fileName: fileName,
      sizeBytes: size,
      mimeType: mime,
    );

    setState(() {
      _uploadingLocalPaths.add(localPath);
      widget.attachments.add(pending);
    });
    widget.onChanged(widget.attachments);

    try {
      final repo = ref.read(attachmentRepositoryProvider);
      final uploaded = await repo.upload(
        localPath: localPath,
        tripId: widget.tripId,
        expenseId: widget.expenseId,
      );

      // 替换 pending 为已上传
      final idx =
          widget.attachments.indexWhere((a) => a.localPath == localPath);
      if (idx >= 0) {
        setState(() {
          widget.attachments[idx] = uploaded;
          _uploadingLocalPaths.remove(localPath);
        });
        widget.onChanged(widget.attachments);
      }
    } catch (e) {
      // 失败 → 移除该 pending
      setState(() {
        widget.attachments.removeWhere((a) => a.localPath == localPath);
        _uploadingLocalPaths.remove(localPath);
      });
      widget.onChanged(widget.attachments);
      if (mounted) _snack('上传失败：$e');
    }
  }

  void _remove(Attachment a) {
    setState(() {
      widget.attachments.remove(a);
      if (a.localPath != null) _uploadingLocalPaths.remove(a.localPath);
    });
    widget.onChanged(widget.attachments);
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttachmentViewer(
          attachments: widget.attachments
              .where((a) => a.url.isNotEmpty)
              .toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  static String _guessMimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final isCloudMode = ref.watch(appSettingsProvider).asData?.value.isCloudMode ?? false;
    final canAdd = widget.attachments.length < widget.maxCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 8),
                Text(
                  '附件 (${widget.attachments.length}/${widget.maxCount})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (canAdd)
                  TextButton.icon(
                    onPressed: _showAddSheet,
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('添加'),
                  ),
              ],
            ),
            if (widget.attachments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isCloudMode
                      ? '点击「添加」可拍照或从相册选择（最多 ${widget.maxCount} 张）'
                      : '附件功能需要云同步，请先在「云端设置」中启用',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final a = widget.attachments[idx];
                    final isUploading = _uploadingLocalPaths.contains(a.localPath);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AttachmentThumb(
                        attachment: a,
                        uploading: isUploading,
                        onTap: a.url.isNotEmpty ? () => _openViewer(idx) : null,
                        onDelete: () => _remove(a),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}