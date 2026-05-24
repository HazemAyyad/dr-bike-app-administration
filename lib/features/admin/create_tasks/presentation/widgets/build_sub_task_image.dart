import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/helpers/task_media_paths.dart';

String _resolveSubTaskMediaUrl(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  if (isVideoMediaPath(raw)) {
    return resolveTaskMediaUri(raw);
  }
  return ShowNetImage.getPhoto(raw);
}

Widget buildSubTaskImage(BuildContext context, dynamic subTaskImage) {
  if (subTaskImage == null) return const SizedBox.shrink();

  final urls = <String>[];
  if (subTaskImage is List) {
    for (final item in subTaskImage) {
      final url = _resolveSubTaskMediaUrl(item);
      if (url.isNotEmpty) urls.add(url);
    }
  } else {
    final url = _resolveSubTaskMediaUrl(subTaskImage);
    if (url.isNotEmpty) urls.add(url);
  }

  if (urls.isEmpty) return const SizedBox.shrink();

  final firstUrl = urls.first;
  if (isVideoMediaPath(firstUrl)) {
    return GestureDetector(
      onTap: () => FullScreenZoomImage.open(context, firstUrl),
      child: Container(
        height: 40.h,
        width: 50.w,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(Icons.videocam, color: Colors.white70, size: 22.sp),
      ),
    );
  }

  if (firstUrl.startsWith('http://') || firstUrl.startsWith('https://')) {
    return GestureDetector(
      onTap: () => FullScreenZoomImage.open(context, firstUrl),
      child: CachedNetworkImage(
        cacheManager: CacheManager(
          Config(
            'imagesCache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        ),
        imageBuilder: (context, imageProvider) => Container(
          height: 40.h,
          width: 50.w,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        imageUrl: firstUrl,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => SizedBox(
          height: 40.h,
          width: 50.w,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => SizedBox(
          height: 40.h,
          width: 50.w,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  final file = File(firstUrl);
  if (!file.existsSync()) return const SizedBox.shrink();

  return Image.file(
    file,
    height: 50.h,
    width: 50.w,
    fit: BoxFit.cover,
  );
}
