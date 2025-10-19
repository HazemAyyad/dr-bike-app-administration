import 'package:doctorbike/features/admin/follow_up/presentation/controllers/follow_up_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class CancelDialog extends GetWidget<FollowUpController> {
  const CancelDialog({Key? key, required this.followupId}) : super(key: key);

  final String followupId;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11.r),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              'cancel_followup_confirmation'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redColor,
                  ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    isLoading: controller.isLoading,
                    borderRadius: BorderRadius.circular(30.r),
                    text: 'yes'.tr,
                    onPressed: () => controller.getFollowUpDetails(
                      followupId: followupId,
                      isCancel: true,
                    ),
                    isSafeArea: false,
                    color: AppColors.redColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    borderRadius: BorderRadius.circular(30.r),
                    borderColor: Colors.red,
                    text: 'cancel'.tr,
                    onPressed: () => Get.back(),
                    isSafeArea: false,
                    textColor: Colors.red,
                    color: Colors.transparent,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
