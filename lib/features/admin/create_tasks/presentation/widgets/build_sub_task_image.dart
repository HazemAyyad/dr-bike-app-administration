import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';

Widget buildSubTaskImage(BuildContext context, dynamic subTaskImage) {
  if (subTaskImage == null) return const SizedBox.shrink();

  // لو List
  if (subTaskImage is List && subTaskImage.isNotEmpty) {
    final firstImage = subTaskImage.first;

    if (firstImage.toString().contains('http')) {
      return GestureDetector(
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            barrierColor: Colors.black.withAlpha(128),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) {
              return FullScreenZoomImage(
                imageUrl: firstImage,
              );
            },
          );
        },
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
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          imageUrl: firstImage,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            height: 40.h,
            width: 50.w,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    } else {
      return Image.file(
        File(firstImage),
        height: 50.h,
        width: 50.w,
      );
    }
  }

  // لو String
  if (subTaskImage is String && subTaskImage.isNotEmpty) {
    if (subTaskImage.contains('http')) {
      return CachedNetworkImage(
        cacheManager: CacheManager(
          Config(
            'imagesCache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        ),
        imageBuilder: (context, imageProvider) => Container(
          height: 40.h,
          width: 40.w,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        imageUrl: subTaskImage,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      return Image.file(
        File(subTaskImage),
        height: 40.h,
        width: 40.w,
      );
    }
  }

  // لو مفيش صور
  return const SizedBox.shrink();
}
