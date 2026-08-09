import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';

const _videoExtensions = {
  'mp4',
  'mov',
  'webm',
  '3gp',
  'm4v',
  'avi',
  'mkv',
};

bool isLedgerReceiptVideo(String path) {
  final clean = path.split('?').first.toLowerCase();
  final extension = clean.contains('.') ? clean.split('.').last : '';
  return _videoExtensions.contains(extension);
}

Future<void> openLedgerReceiptMedia(
  BuildContext context,
  String path, {
  bool isLocal = false,
}) async {
  if (isLedgerReceiptVideo(path)) {
    FullScreenZoomImage.open(
        context, isLocal ? path : ShowNetImage.getPhoto(path));
    return;
  }

  if (isLocal) {
    FullScreenZoomImage.open(context, path);
    return;
  }

  FullScreenZoomImage.open(context, ShowNetImage.getPhoto(path));
}

class LedgerReceiptMediaThumb extends StatelessWidget {
  const LedgerReceiptMediaThumb({
    Key? key,
    required this.path,
    required this.size,
    this.isLocal = false,
    this.onRemove,
  }) : super(key: key);

  final String path;
  final double size;
  final bool isLocal;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isVideo = isLedgerReceiptVideo(path);
    return Stack(
      children: [
        GestureDetector(
          onTap: () => openLedgerReceiptMedia(context, path, isLocal: isLocal),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _mediaBody(isVideo),
                Icon(
                  isVideo ? Icons.play_circle_fill : Icons.zoom_in,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: (size * 0.34).sp,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mediaBody(bool isVideo) {
    final dimension = size.w;
    if (isVideo) {
      return Container(
        width: dimension,
        height: dimension,
        color: const Color(0xFF202124),
        child: Icon(
          Icons.videocam_outlined,
          color: Colors.white70,
          size: (size * 0.28).sp,
        ),
      );
    }

    if (isLocal) {
      return Image.file(
        File(path),
        width: dimension,
        height: dimension,
        fit: BoxFit.cover,
      );
    }

    final url = ShowNetImage.getPhoto(path);
    return CachedNetworkImage(
      imageUrl: url,
      width: dimension,
      height: dimension,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: dimension,
        height: dimension,
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: dimension,
        height: dimension,
        color: Colors.grey.shade200,
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
