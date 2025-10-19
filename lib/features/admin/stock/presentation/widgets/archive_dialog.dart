import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../controllers/stock_controller.dart';

class ArchiveDialog extends GetView<StockController> {
  const ArchiveDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          Text(
            'archiveClearance'.tr,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                ),
          ),
          Container(
            margin: EdgeInsets.symmetric(
              vertical: 10.h,
              horizontal: 25.w,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 5.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'productName'.tr,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: AppColors.whiteColor,
                      ),
                ),
                Text(
                  'quantity'.tr,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: AppColors.whiteColor,
                      ),
                ),
              ],
            ),
          ),
          Obx(
            () {
              if (controller.isProductLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (controller.archived.isEmpty) {
                return const ShowNoData();
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    ...controller.archived.map(
                      (product) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 25.w,
                            vertical: 5.h,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor6,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 5.w),
                              product.image.isEmpty ||
                                      product.image == 'no image'
                                  ? Image.asset(
                                      AssetsManager.stockImage,
                                      height: 25.h,
                                      width: 35.w,
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          barrierLabel: 'Dismiss',
                                          barrierColor:
                                              Colors.black.withAlpha(128),
                                          transitionDuration:
                                              const Duration(milliseconds: 300),
                                          pageBuilder: (context, anim1, anim2) {
                                            return FullScreenZoomImage(
                                              imageUrl: product.image,
                                            );
                                          },
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        child: CachedNetworkImage(
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
                                            height: 25.h,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                                filterQuality:
                                                    FilterQuality.medium,
                                              ),
                                            ),
                                          ),
                                          imageUrl: product.image,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                            AssetsManager.stockImage,
                                            height: 25.h,
                                          ),
                                        ),
                                      ),
                                    ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: SizedBox(
                                  width: 140.w,
                                  child: Text(
                                    product.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.sp,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20.w),
                              Text(
                                product.stock.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.sp,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 15.h),
        ],
      ),
    );
  }
}
