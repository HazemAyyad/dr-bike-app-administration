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

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10.h),
            height: 1.h,
            width: 300.w,
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
        /// ✅ السلايدر الأساسي
        CarouselSlider.builder(
          itemCount: images.length,
          options: CarouselOptions(
            height: 150.h,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            autoPlay: false,
            viewportFraction: 0.3,
          ),
          itemBuilder: (context, index, realIdx) {
            final image = images[index];
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
                              images[currentIndex.value],
                            ),
                          ),
                        ),
                        /// السلايدر داخل الـDialog
                        Center(
                          child: CarouselSlider.builder(
                            carouselController: controller,
                            itemCount: images.length,
                            itemBuilder: (context, index, realIdx) {
                              return CachedNetworkImage(
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
                                imageUrl: images[index],
                                fadeInDuration:
                                    const Duration(milliseconds: 200),
                                fadeOutDuration:
                                    const Duration(milliseconds: 200),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              );
                            },
                            options: CarouselOptions(
                              enlargeCenterPage: true,
                              enableInfiniteScroll: true,
                              autoPlay: false,
                              viewportFraction: 0.8,
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
              child: CachedNetworkImage(
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
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            );
          },
        ),
      ],
    );
  }
}
