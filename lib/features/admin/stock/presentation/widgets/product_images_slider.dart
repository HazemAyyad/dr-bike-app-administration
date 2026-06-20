import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/show_net_image.dart';

List<String> _filterProductImageList(List<String> images) {
  final seen = <String>{};
  final out = <String>[];
  for (final r in images) {
    final t = r.toString().trim();
    if (t.isEmpty) continue;
    final tl = t.toLowerCase();
    if (tl == 'no image' ||
        tl == 'no img' ||
        tl == 'no images' ||
        tl == 'null') {
      continue;
    }
    if (!seen.add(t)) continue;
    out.add(t);
  }
  return out;
}

CacheManager _productImageCache() {
  return CacheManager(
    Config(
      'imagesCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );
}

class _ImageSourceBadge extends StatelessWidget {
  const _ImageSourceBadge({required this.source});

  final ProductImageSource source;

  @override
  Widget build(BuildContext context) {
    if (source == ProductImageSource.unknown) {
      return const SizedBox.shrink();
    }
    final legacy = source == ProductImageSource.legacyDotNetStore;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(7.r),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: legacy ? const Color(0xFFE65100) : const Color(0xFF00695C),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  legacy ? Icons.storefront_outlined : Icons.storage_outlined,
                  size: 13.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 4.w),
                Text(
                  legacy ? 'imageBadgeLegacyStore'.tr : 'imageBadgeLaravel'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductImagesSlider extends StatelessWidget {
  const ProductImagesSlider({
    Key? key,
    required this.images,
    required this.title,
    this.compact = false,
  }) : super(key: key);

  final List<String> images;
  final String title;
  final bool compact;

  Future<void> downloadImage(String imageUrl) async {
    try {
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        await Permission.photosAddOnly.request();
      }

      Get.snackbar(
        'تنبيه',
        'جاري تحميل الصورة...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = imageUrl.split('/').last;
      final tempPath = '${tempDir.path}/$fileName';

      await Dio().download(imageUrl, tempPath);
      await GallerySaver.saveImage(tempPath, albumName: 'Doctor Bike');

      Get.snackbar(
        'تم',
        'تم حفظ الصورة في المعرض',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل التحميل: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _closeViewer() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _openViewer(BuildContext context, List<String> slides, int initialPage) {
    final carouselController = CarouselSliderController();
    final currentIndex = initialPage.obs;
    final screenHeight = MediaQuery.sizeOf(context).height;

    Get.dialog(
      Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned(
              top: 58.h,
              right: 16.w,
              child: _ViewerIconButton(
                icon: Icons.close,
                onTap: _closeViewer,
              ),
            ),
            Positioned(
              top: 58.h,
              left: 16.w,
              child: _ViewerIconButton(
                icon: Icons.download,
                onTap: () => downloadImage(
                  ShowNetImage.getPhoto(slides[currentIndex.value]),
                ),
              ),
            ),
            Center(
              child: CarouselSlider.builder(
                carouselController: carouselController,
                itemCount: slides.length,
                itemBuilder: (context, index, realIdx) {
                  final raw = slides[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _NetworkProductImage(
                            imageUrl: ShowNetImage.getPhoto(raw),
                            fit: BoxFit.contain,
                            backgroundColor: Colors.black,
                          ),
                          _ImageSourceBadge(
                            source: ShowNetImage.classifySource(raw),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: screenHeight * 0.62,
                  enlargeCenterPage: slides.length > 1,
                  enableInfiniteScroll: slides.length > 1,
                  autoPlay: false,
                  viewportFraction: slides.length == 1 ? 0.92 : 0.86,
                  initialPage: initialPage,
                  onPageChanged: (i, reason) => currentIndex.value = i,
                ),
              ),
            ),
            Positioned(
              bottom: 42.h,
              left: 0,
              right: 0,
              child: Obx(
                () => Text(
                  '${currentIndex.value + 1} / ${slides.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.74),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _filterProductImageList(images);
    if (slides.isEmpty) {
      return const SizedBox.shrink();
    }

    final first = slides.first;
    final thumbs = compact ? <String>[] : slides.skip(1).take(4).toList();
    final extraCount = slides.length - 5;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 14.h),
      padding: EdgeInsets.all(compact ? 9.w : 12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: compact ? 17.sp : 20.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: compact ? 5.w : 8.w),
              Expanded(
                child: Text(
                  title.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11.sp : null,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AdminUiColors.subtleOverlay(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${slides.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => _openViewer(context, slides, 0),
            child: AspectRatio(
              aspectRatio: compact ? 1.25 : 1.85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _NetworkProductImage(
                      imageUrl: ShowNetImage.getPhoto(first),
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    _ImageSourceBadge(
                      source: ShowNetImage.classifySource(first),
                    ),
                    Positioned(
                      bottom: 10.h,
                      right: 10.w,
                      child: const _ImageActionPill(
                        icon: Icons.open_in_full,
                        label: 'عرض',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (thumbs.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                for (var i = 0; i < thumbs.length; i++) ...[
                  Expanded(
                    child: _ThumbnailTile(
                      raw: thumbs[i],
                      overlayText: i == thumbs.length - 1 && extraCount > 0
                          ? '+$extraCount'
                          : null,
                      onTap: () => _openViewer(context, slides, i + 1),
                    ),
                  ),
                  if (i != thumbs.length - 1) SizedBox(width: 8.w),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NetworkProductImage extends StatelessWidget {
  const _NetworkProductImage({
    required this.imageUrl,
    required this.fit,
    this.backgroundColor,
  });

  final String imageUrl;
  final BoxFit fit;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? AdminUiColors.subtleOverlay(context),
      child: CachedNetworkImage(
        cacheManager: _productImageCache(),
        imageUrl: imageUrl,
        fit: fit,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({
    required this.raw,
    required this.onTap,
    this.overlayText,
  });

  final String raw;
  final VoidCallback onTap;
  final String? overlayText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkProductImage(
                imageUrl: ShowNetImage.getPhoto(raw),
                fit: BoxFit.cover,
              ),
              if (overlayText != null)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Text(
                      overlayText!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46.w,
          height: 46.w,
          child: Icon(icon, color: Colors.white, size: 24.sp),
        ),
      ),
    );
  }
}

class _ImageActionPill extends StatelessWidget {
  const _ImageActionPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.sp, color: Colors.white),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
