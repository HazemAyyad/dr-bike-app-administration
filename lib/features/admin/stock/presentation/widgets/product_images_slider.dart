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

import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

/// يزيل القيم الوهمية من الـ API ويزيل التكرار بنفس المسار.
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

CarouselOptions _carouselOptionsForCount(int n, {double height = 150}) {
  final h = height;
  if (n <= 0) {
    return CarouselOptions(height: h, viewportFraction: 1);
  }
  // صورة واحدة: شريحة مدمجة (~ربع المساحة السابقة) + بدون لف لا نهائي
  if (n == 1) {
    return CarouselOptions(
      height: h,
      viewportFraction: 0.58,
      enlargeCenterPage: false,
      enableInfiniteScroll: false,
      autoPlay: false,
      padEnds: true,
    );
  }
  if (n == 2) {
    return CarouselOptions(
      height: h,
      viewportFraction: 0.48,
      enlargeCenterPage: true,
      enableInfiniteScroll: true,
      autoPlay: false,
      padEnds: true,
    );
  }
  return CarouselOptions(
    height: h,
    viewportFraction: 0.34,
    enlargeCenterPage: true,
    enableInfiniteScroll: true,
    autoPlay: false,
    padEnds: true,
  );
}

/// شارة صغيرة تبيّن إن الصورة من الأرشيف (Images/Items) أو محلية (storage).
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
        padding: EdgeInsets.all(6.r),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8.r),
          color: legacy
              ? const Color(0xFFE65100).withValues(alpha: 0.95)
              : const Color(0xFF00695C).withValues(alpha: 0.95),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  legacy ? Icons.storefront_outlined : Icons.storage_outlined,
                  size: 14.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 4.w),
                Text(
                  legacy
                      ? 'imageBadgeLegacyStore'.tr
                      : 'imageBadgeLaravel'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
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
  final List<String> images;
  final String title;

  const ProductImagesSlider({
    Key? key,
    required this.images,
    required this.title,
  }) : super(key: key);

  Future<void> downloadImage(BuildContext context, String imageUrl) async {
    try {
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        await Permission.photosAddOnly.request();
      }

      Get.snackbar(
        "تنبيه",
        "جاري تحميل الصورة...",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = imageUrl.split('/').last;
      final tempPath = '${tempDir.path}/$fileName';

      await Dio().download(imageUrl, tempPath);

      if (imageUrl.endsWith('.mp4')) {
        await GallerySaver.saveVideo(tempPath, albumName: "Doctor Bike");
      } else {
        await GallerySaver.saveImage(tempPath, albumName: "Doctor Bike");
      }

      Get.snackbar(
        "تم",
        "تم حفظ الصورة في المعرض ✅",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل التحميل: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _filterProductImageList(images);
    if (slides.isEmpty) {
      return const SizedBox.shrink();
    }
    final n = slides.length;
    final carouselOptions = _carouselOptionsForCount(n, height: 86.h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6.h),
            height: 1.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor3,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        Text(
          title.tr,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor6
                    : AppColors.customGreyColor,
              ),
        ),
        SizedBox(height: 10.h),
        /// سلايدر — مع صورة واحدة: عرض كامل بدون تكرار (كان viewportFraction=0.3 + infinite يسبب 3 نسخ).
        CarouselSlider.builder(
          itemCount: n,
          options: carouselOptions,
          itemBuilder: (context, index, realIdx) {
            final raw = slides[index];
            final image = ShowNetImage.getPhoto(raw);
            final src = ShowNetImage.classifySource(raw);
            return GestureDetector(
              onTap: () {
                final CarouselSliderController controller =
                    CarouselSliderController();
                final RxInt currentIndex = index.obs;
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Dismiss',
                  barrierColor: Colors.black.withAlpha(128),
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, anim1, anim2) {
                    return Stack(
                      children: [
                        /// زر إغلاق
                        Positioned(
                          top: 80.h,
                          right: 20.w,
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 30.sp,
                            ),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        Positioned(
                          top: 80.h,
                          left: 20.w,
                          child: IconButton(
                            icon: Icon(
                              Icons.download,
                              color: Colors.green,
                              size: 30.sp,
                            ),
                            onPressed: () => downloadImage(
                              context,
                              ShowNetImage.getPhoto(
                                slides[currentIndex.value],
                              ),
                            ),
                          ),
                        ),
                        /// السلايدر داخل الـDialog
                        Center(
                          child: CarouselSlider.builder(
                            carouselController: controller,
                            itemCount: n,
                            itemBuilder: (context, index, realIdx) {
                              final rawDlg = slides[index];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    cacheManager: CacheManager(
                                      Config(
                                        'imagesCache',
                                        stalePeriod: const Duration(days: 7),
                                        maxNrOfCacheObjects: 100,
                                      ),
                                    ),
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.medium,
                                        ),
                                      ),
                                    ),
                                    imageUrl:
                                        ShowNetImage.getPhoto(rawDlg),
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    placeholder: (context, url) =>
                                        const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                  _ImageSourceBadge(
                                    source: ShowNetImage.classifySource(
                                      rawDlg,
                                    ),
                                  ),
                                ],
                              );
                            },
                            options: CarouselOptions(
                              height: MediaQuery.sizeOf(context).height * 0.55,
                              enlargeCenterPage: n > 1,
                              enableInfiniteScroll: n > 1,
                              autoPlay: false,
                              viewportFraction: n == 1 ? 1.0 : 0.85,
                              initialPage: index,
                              onPageChanged: (i, reason) {
                                currentIndex.value = i;
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      cacheManager: CacheManager(
                        Config(
                          'imagesCache',
                          stalePeriod: const Duration(days: 7),
                          maxNrOfCacheObjects: 100,
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.low,
                          ),
                        ),
                      ),
                      imageUrl: image,
                      fadeInDuration: const Duration(milliseconds: 200),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => const SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                    _ImageSourceBadge(source: src),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
