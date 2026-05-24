import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/task_media_paths.dart';
import '../../../../../core/utils/app_colors.dart';

/// Horizontal row of task images/videos; tap to open full screen.
class TaskMediaThumbnailRow extends StatelessWidget {
  const TaskMediaThumbnailRow({
    Key? key,
    required this.images,
    this.videos = const [],
    this.localFiles = const [],
    this.thumbHeight = 72,
    this.thumbWidth = 72,
    this.emptyMessage,
  }) : super(key: key);

  final List<String> images;
  final List<String> videos;
  final List<File> localFiles;
  final double thumbHeight;
  final double thumbWidth;
  final String? emptyMessage;

  int get _itemCount =>
      images.length + videos.length + localFiles.length;

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) {
      if (emptyMessage == null || emptyMessage!.isEmpty) {
        return const SizedBox.shrink();
      }
      return Text(
        emptyMessage!,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          color: AppColors.customGreyColor5,
        ),
      );
    }

    return SizedBox(
      height: thumbHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _itemCount,
        separatorBuilder: (_, __) => SizedBox(width: 6.w),
        itemBuilder: (context, index) {
          if (index < images.length) {
            return _MediaThumb(
              onTap: () => FullScreenZoomImage.open(context, images[index]),
              child: CachedNetworkImage(
                imageUrl: images[index],
                width: thumbWidth.w,
                height: thumbHeight.h,
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(
                  width: thumbWidth.w,
                  height: thumbHeight.h,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: thumbWidth.w,
                  height: thumbHeight.h,
                  color: AppColors.operationalSurface,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.customGreyColor5,
                    size: 22.sp,
                  ),
                ),
              ),
            );
          }
          final videoIndex = index - images.length;
          if (videoIndex < videos.length) {
            final url = videos[videoIndex];
            return _MediaThumb(
              onTap: () => FullScreenZoomImage.open(context, url),
              isVideo: true,
              child: _VideoThumbPlaceholder(width: thumbWidth, height: thumbHeight),
            );
          }
          final fileIndex = videoIndex - videos.length;
          final file = localFiles[fileIndex];
          final isVid = localFileIsVideo(file.path);
          return _MediaThumb(
            onTap: () => FullScreenZoomImage.open(context, file.path),
            isVideo: isVid,
            child: isVid
                ? _VideoThumbPlaceholder(width: thumbWidth, height: thumbHeight)
                : Image.file(file, width: thumbWidth.w, height: thumbHeight.h, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.onTap,
    required this.child,
    this.isVideo = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: child,
            ),
            if (isVideo)
              Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
            Positioned(
              right: 4.w,
              bottom: 4.h,
              child: Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 16.sp,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbPlaceholder extends StatelessWidget {
  const _VideoThumbPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: height.h,
      color: AppColors.operationalNavy.withValues(alpha: 0.85),
      child: Icon(Icons.videocam, color: Colors.white70, size: 28.sp),
    );
  }
}
