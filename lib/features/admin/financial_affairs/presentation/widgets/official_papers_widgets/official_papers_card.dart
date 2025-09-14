import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/official_papers_models/papers_model.dart';
import '../../controllers/official_papers_controller.dart';

class OfficialPapersCard extends GetView<OfficialPapersController> {
  const OfficialPapersCard({Key? key, required this.data}) : super(key: key);

  final PaperModel data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.dialog(
          Dialog(
            backgroundColor: ThemeService.isDark.value
                ? AppColors.darckColor
                : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'delete_document'.tr,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.blackColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AppButton(
                          isSafeArea: false,
                          onPressed: () {
                            Get.back();
                          },
                          text: 'cancel'.tr,
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: AppButton(
                          isLoading: controller.isLoading,
                          isSafeArea: false,
                          onPressed: () {
                            controller.cancelPaper(
                                paperId: data.paperId.toString());
                          },
                          text: 'yes'.tr,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        // controller.isEditing.value = true;
        // controller.getAssetsDetials(
        //     assetId: asset.assetId.toString());
        // Get.toNamed(AppRoutes.ADDNEWASSETSCREEN);
      },
      child: Container(
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
                  imageUrl: data.img,
                  fit: BoxFit.cover,
                  height: 45.h,
                  width: 60.w,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                data.paperName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.graywhiteColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            SizedBox(width: 5.w),
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
                  width: 50.w,
                  child: Center(
                    child: Text(
                      data.treasuryName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.secondaryColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SizedBox(width: 5.w),
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: AppColors.graywhiteColor,
                  ),
                  height: 55.h,
                  width: 50.w,
                  child: Center(
                    child: Text(
                      data.fileBoxName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.secondaryColor,
                            fontSize: 11.sp,
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
                  width: 50.w,
                  child: Center(
                    child: Text(
                      data.fileName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.secondaryColor,
                            fontSize: 11.sp,
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
