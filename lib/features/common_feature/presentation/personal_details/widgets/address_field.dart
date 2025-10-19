import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/personal_details_controller.dart';

Column addressField(PersonalDetailsController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'address'.tr,
        style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: ThemeService.isDark.value
                  ? Colors.white
                  : AppColors.secondaryColor,
            ),
      ),
      SizedBox(height: 10.h),
      Container(
        height: 100.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.customGreyColor3,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: TextField(
          maxLines: 4,
          controller: controller.addressController,
          decoration: InputDecoration(
            hintText: 'enterFullAddress'.tr,
            hintStyle: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.customGreyColor2,
                ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    ],
  );
}
