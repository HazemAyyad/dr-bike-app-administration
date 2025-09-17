import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/project_service.dart';

class EndProjectDialog extends GetView<ProjectController> {
  const EndProjectDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 10.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'endProjectText'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    borderColor: Colors.red,
                    color: Colors.transparent,
                    textColor: Colors.red,
                    text: 'cancel',
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    isLoading: controller.isLoading,
                    isSafeArea: false,
                    color: Colors.red,
                    text: 'yes',
                    onPressed: () {
                      controller.itemIdController.clear();
                      controller
                          .addProductToProjectOrComplete(
                        context: context,
                        projectId: ProjectService().projectDetails.value!.id,
                      )
                          .then((value) {
                        Get.back();
                      });
                    },
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
