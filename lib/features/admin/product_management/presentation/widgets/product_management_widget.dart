import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/product_management_controller.dart';

class ProductManagementWidget extends GetView<ProductManagementController> {
  const ProductManagementWidget({
    Key? key,
    required this.productName,
    required this.productImage,
    required this.currentStep,
    this.isEdit = false,
  }) : super(key: key);

  final String currentStep;
  final String productName;
  final String productImage;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Row(
        children: [
          // الصورة
          Flexible(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      barrierColor: Colors.black.withAlpha(128),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return FullScreenZoomImage(
                          imageUrl: productImage,
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
                      height: 45.h,
                      width: 60.w,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                    imageUrl: productImage,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // الاسم
                Flexible(
                  child: Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // المرحلة
          Text(
            isEdit ? controller.description : '${'step'.tr} $currentStep',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(width: 30.w),
        ],
      ),
    );
  }
}
