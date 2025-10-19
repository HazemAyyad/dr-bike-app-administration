import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/project_controller.dart';

class ShowImage extends GetView<ProjectController> {
  const ShowImage({Key? key, required this.list}) : super(key: key);

  final List<File> list;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        list.isEmpty
            ? const SizedBox.shrink()
            : Text(
                'projectOrProductsImages'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: (ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
        SizedBox(height: 5.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : list.isEmpty
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          ...list.asMap().entries.map(
                            (entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5.r),
                                      child: !file.path.contains('http')
                                          ? Image.file(
                                              File(file.path),
                                              height: 150.h,
                                              fit: BoxFit.fill,
                                            )
                                          : CachedNetworkImage(
                                              cacheManager: CacheManager(
                                                Config(
                                                  'imagesCache',
                                                  stalePeriod:
                                                      const Duration(days: 7),
                                                  maxNrOfCacheObjects: 100,
                                                ),
                                              ),
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Container(
                                                height: 150.h,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.fill,
                                                    filterQuality:
                                                        FilterQuality.medium,
                                                  ),
                                                ),
                                              ),
                                              imageUrl: file.path,
                                              fadeInDuration: const Duration(
                                                  milliseconds: 200),
                                              fadeOutDuration: const Duration(
                                                  milliseconds: 200),
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                    ),
                                    // زرار فوق الصورة
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          controller.isLoading(true);
                                          list.removeAt(index);
                                          controller.isLoading(false);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 50.w),
          height: 1.h,
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor6
              : AppColors.customGreyColor3,
        ),
      ],
    );
  }
}
