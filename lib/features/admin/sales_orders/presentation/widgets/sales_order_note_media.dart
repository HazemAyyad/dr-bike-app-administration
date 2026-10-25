import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/video_view.dart';
import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';

export '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart'
    show WhatsAppCapture;

Future<List<WhatsAppCapture>> pickSalesOrderNoteMedia(
    {required bool camera, required int remaining}) async {
  if (remaining <= 0) return [];
  if (camera) {
    final capture = await Get.to<WhatsAppCapture>(
        () => const WhatsAppCameraScreen(allowGallery: true),
        fullscreenDialog: true);
    return capture == null ? [] : [capture];
  }
  final picker = ImagePicker();
  final files = remaining == 1
      ? [await picker.pickMedia()].whereType<XFile>().toList()
      : await picker.pickMultipleMedia(limit: remaining);
  return files.take(remaining).map((file) {
    final video = file.mimeType?.startsWith('video/') == true ||
        RegExp(r'\.(mp4|mov|m4v|webm|3gp)$', caseSensitive: false)
            .hasMatch(file.path);
    return WhatsAppCapture(
        path: file.path, mediaKind: video ? 'video' : 'image');
  }).toList();
}

class SalesOrderNoteMediaTile extends StatelessWidget {
  const SalesOrderNoteMediaTile(
      {Key? key,
      required this.path,
      required this.isVideo,
      this.local = false,
      this.onRemove})
      : super(key: key);
  final String path;
  final bool isVideo;
  final bool local;
  final VoidCallback? onRemove;

  void _open(BuildContext context) {
    if (isVideo) {
      showDialog<void>(
          context: context, builder: (_) => VideoView(videoPath: path));
      return;
    }
    showDialog<void>(
        context: context,
        builder: (context) => Dialog(
              backgroundColor: const Color(0xFFF3F4F6),
              child: Stack(alignment: Alignment.center, children: [
                InteractiveViewer(child: _image(BoxFit.contain)),
                PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))),
              ]),
            ));
  }

  Widget _image(BoxFit fit) => local
      ? Image.file(File(path), fit: fit, errorBuilder: _imageError)
      : Image.network(path, fit: fit, errorBuilder: _imageError);
  Widget _imageError(BuildContext _, Object __, StackTrace? ___) =>
      const Center(child: Icon(Icons.broken_image_outlined));

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 92,
        height: 92,
        child: Stack(fit: StackFit.expand, children: [
          Material(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: () => _open(context),
                child: isVideo
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.play_circle_outline_rounded,
                                size: 34, color: Color(0xFF635CB1)),
                            Text('فيديو',
                                style: TextStyle(color: Color(0xFF111827))),
                          ])
                    : _image(BoxFit.cover)),
          ),
          if (onRemove != null)
            PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                    tooltip: 'إزالة المرفق',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: const Color(0xFF111827)),
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, size: 18))),
        ]),
      );
}
