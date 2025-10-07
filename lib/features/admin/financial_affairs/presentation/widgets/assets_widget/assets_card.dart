import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/assets_models/assets_data_model.dart';
import '../../controllers/assets_controller.dart';
import '../official_papers_widgets/cancel_file_dialog.dart';
import 'destruction_assets.dart';

class AssetsCard extends GetView<AssetsController> {
  const AssetsCard({Key? key, required this.asset}) : super(key: key);

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Get.dialog(
          Dialog(
            backgroundColor: ThemeService.isDark.value
                ? AppColors.darkColor
                : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8.r)),
                  ),
                  child: Column(
                    children: controller.list
                        .map<Widget>(
                          (option) => RadioListTile<String>(
                            title: Text(
                              option.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                            ),
                            value: option,
                            groupValue: null,
                            onChanged: (value) {
                              Get.back();
                              if (value == 'delete') {
                                Get.dialog(
                                  CancelFileDialog(
                                    fileName: asset.name,
                                    assetId: asset.assetId.toString(),
                                  ),
                                );
                              }
                              if (value == 'destruction') {
                                Get.dialog(
                                  DestructionAssets(asset: asset),
                                );
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onTap: () {
        controller.isEditing.value = true;
        controller.getAssetsDetials(assetId: asset.assetId.toString());
        Get.toNamed(AppRoutes.ADDNEWASSETSCREEN);
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
            Padding(
              padding: EdgeInsets.all(5.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: CachedNetworkImage(
                  imageUrl: asset.image,
                  fit: BoxFit.cover,
                  height: 45.h,
                  width: 50.w,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.graywhiteColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    showData(asset.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.graywhiteColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    borderRadius: Get.locale!.languageCode == 'ar'
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
                  height: 55.h,
                  width: 55.w,
                  child: Center(
                    child: Text(
                      NumberFormat('#,###')
                          .format(double.parse(asset.originalPrice)),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.blackColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SizedBox(width: 5.w),
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    borderRadius: Get.locale!.languageCode == 'ar'
                        ? BorderRadius.only(
                            bottomLeft: Radius.circular(4.r),
                            topLeft: Radius.circular(4.r),
                          )
                        : BorderRadius.only(
                            bottomRight: Radius.circular(4.r),
                            topRight: Radius.circular(4.r),
                          ),
                    color: AppColors.graywhiteColor,
                  ),
                  height: 55.h,
                  width: 55.w,
                  child: Center(
                    child: Text(
                      "${asset.depreciationRate}%",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.blackColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
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
