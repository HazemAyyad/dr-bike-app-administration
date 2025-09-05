import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
        CarouselSlider(
          options: CarouselOptions(
            height: 150.h, // طول السلايدر
            enlargeCenterPage: true, // يخلي الصورة اللي في النص كبيرة
            enableInfiniteScroll: true,
            autoPlay: false, // لو عاوز الصور تتحرك تلقائي حطها true
            viewportFraction: 0.3, // حجم الصور اللي على الجنب
          ),
          items: images.map(
            (image) {
              return GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Dismiss',
                    barrierColor: Colors.black.withAlpha(128),
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (context, anim1, anim2) {
                      return Stack(
                        children: [
                          Positioned(
                            top: 200.h,
                            right: 30.w,
                            child: GestureDetector(
                              onTap: () {
                                Get.back();
                              },
                              child: const Icon(
                                Icons.close,
                                size: 30,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          Center(
                            child: CarouselSlider(
                              options: CarouselOptions(
                                // height: 300.h,
                                enlargeCenterPage: true,
                                enableInfiniteScroll: true,
                                autoPlay: false,
                                viewportFraction: 0.8,
                              ),
                              items: images.map(
                                (image) {
                                  return CachedNetworkImage(
                                    imageUrl: image,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
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
                              ).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}
