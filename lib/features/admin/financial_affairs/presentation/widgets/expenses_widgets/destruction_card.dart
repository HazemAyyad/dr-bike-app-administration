import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/expenses_models/destruction_model.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/showtime.dart';
import '../../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../../controllers/official_papers_controller.dart';

class DestructionCard extends StatelessWidget {
  const DestructionCard({Key? key, required this.data}) : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.dialog(DestructionDetails(data: data));
        // controller.isEditing.value = true;
        // controller.getAssetsDetials(assetId: asset.id.toString());
        // Get.toNamed(AppRoutes.ADDNEWASSETSCREEN);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(5.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9.r),
                    child: CachedNetworkImage(
                      cacheManager: CacheManager(
                        Config(
                          'imagesCache',
                          stalePeriod: const Duration(days: 7),
                          maxNrOfCacheObjects: 100,
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        height: 55.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                      imageUrl: data.image.isEmpty
                          ? AssetsManager.noImageNet
                          : data.image.first,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  children: [
                    Text(
                      data.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.graywhiteColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      '${'piecesCount'.tr}:${data.piecesNumber}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.graywhiteColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            // const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: Get.locale!.languageCode != 'ar'
                        ? BorderRadius.only(
                            bottomRight: Radius.circular(4.r),
                            topRight: Radius.circular(4.r),
                          )
                        : BorderRadius.only(
                            bottomLeft: Radius.circular(4.r),
                            topLeft: Radius.circular(4.r),
                          ),
                    color: AppColors.graywhiteColor,
                  ),
                  height: 65.h,
                  width: 60.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'destructionValue'.tr,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: AppColors.blackColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Flexible(
                        child: Text(
                          NumberFormat('#,###').format(
                              double.parse(data.destructionValue.toString())),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: AppColors.blackColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DestructionDetails extends GetView<OfficialPapersController> {
  const DestructionDetails({Key? key, required this.data}) : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Text(
                    'details'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.secondaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'productName',
                      discription: data.productName,
                    ),
                  ),
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'destructionValue',
                      discription: data.destructionValue.toString(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'piecesCount',
                      discription: data.piecesNumber.toString(),
                    ),
                  ),
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'damageReason',
                      discription: data.destructionReason,
                    ),
                  ),
                ],
              ),
              if (data.image.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: '${'images'.tr} ${'or'.tr} ${'video'.tr}',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...data.image.map(
                            (e) => e.contains('.mp4')
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: GestureDetector(
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
                                                imageUrl: e);
                                          },
                                        );
                                      },
                                      child: Icon(
                                        Icons.video_library_rounded,
                                        size: 80.sp,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: GestureDetector(
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
                                              imageUrl: e,
                                            );
                                          },
                                        );
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl: e,
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
                                          width: 150.w,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                              filterQuality:
                                                  FilterQuality.medium,
                                            ),
                                          ),
                                        ),
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.primaryColor),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          Icons.error,
                                          size: 50,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              SupTextAndDiscr(
                titleColor: AppColors.primaryColor,
                title: 'date',
                discription: showData(data.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
