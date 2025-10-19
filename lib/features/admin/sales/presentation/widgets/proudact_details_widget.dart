import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class ProudactDetailsWidget extends StatelessWidget {
  const ProudactDetailsWidget({
    Key? key,
    required this.product,
    required this.cost,
    required this.quantity,
    required this.image,
  }) : super(key: key);

  final String image;
  final String product;
  final String cost;
  final String quantity;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      height: 40.h,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.customGreyColor6,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      barrierColor: Colors.black.withAlpha(128),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return FullScreenZoomImage(imageUrl: image);
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
                      height: 50.h,
                      width: 50.w,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                    imageUrl: image,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => SizedBox(
                      height: 50.h,
                      width: 50.w,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              SizedBox(width: 5.w),
              SizedBox(
                width: 80.w,
                child: Text(
                  product,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                      ),
                ),
              ),
            ],
          ),
          Text(
            quantity,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                ),
          ),
          Text(
            cost,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                ),
          ),
          Padding(
            padding: EdgeInsets.only(
              right: Get.locale!.languageCode == 'ar' ? 0 : 35.w,
              left: Get.locale!.languageCode == 'ar' ? 35.w : 0.w,
            ),
            child: Text(
              (int.parse(cost) * int.parse(quantity)).toString(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
