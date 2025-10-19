import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'full_screen_image_viewer.dart';
import 'video_view.dart';

class ShowImageOrVideo extends StatelessWidget {
  const ShowImageOrVideo({Key? key, required this.path}) : super(key: key);

  final String path;

  bool get _isVideo => path.toLowerCase().contains('.mp4');
  bool get _isNetwork => path.toLowerCase().startsWith('http');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.r),
      child: GestureDetector(
        onTap: () {
          if (_isVideo) {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black.withAlpha(128),
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) {
                return VideoView(videoPath: path);
              },
            );
          } else {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black.withAlpha(128),
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) {
                return FullScreenZoomImage(imageUrl: path);
              },
            );
          }
        },
        child: _isVideo
            ? Icon(
                Icons.play_circle_outline_rounded,
                size: 150.sp,
                color: AppColors.primaryColor,
              )
            : _isNetwork
                ? CachedNetworkImage(
                    cacheManager: CacheManager(
                      Config(
                        'imagesCache',
                        stalePeriod: const Duration(days: 7),
                        maxNrOfCacheObjects: 100,
                      ),
                    ),
                    imageBuilder: (context, imageProvider) => Container(
                      height: 200.h,
                      width: 200.w,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                    imageUrl: path,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => SizedBox(
                      height: 200.h,
                      width: 200.w,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  )
                : Image.file(
                    File(path),
                    height: 200.h,
                    width: 200.w,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
      ),
    );
  }
}
