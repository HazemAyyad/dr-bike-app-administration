import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../data/models/official_papers_models/pictures_model.dart';
import '../../controllers/official_papers_controller.dart';
import 'picture_details.dart';

class PictureCard extends GetView<OfficialPapersController> {
  const PictureCard({Key? key, required this.data}) : super(key: key);

  final PictureModel data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.dialog(PictureDetails(picture: data));
      },
      onLongPress: () {
        Get.dialog(
          Dialog(
            backgroundColor: ThemeService.isDark.value
                ? AppColors.darkColor
                : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'delete_picture'.tr,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.blackColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  SizedBox(height: 10.h),
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
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AppButton(
                          isLoading: controller.isLoading,
                          isSafeArea: false,
                          onPressed: () {
                            controller.cancelPaper(
                              isPicture: true,
                              paperId: data.id.toString(),
                            );
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: CachedNetworkImage(
                  imageUrl: data.file,
                  fit: BoxFit.cover,
                  height: 80,
                  width: 100,
                  errorWidget: (context, url, error) =>
                      Image.network(AssetsManager.noImageNet),
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            Flexible(
              child: Text(
                data.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
            Flexible(
              child: Text(
                showData(data.createdAt),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.graywhiteColor,
                    ),
              ),
            ),
            Flexible(
              child: Text(
                data.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.graywhiteColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
