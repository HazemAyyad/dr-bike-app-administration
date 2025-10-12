import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/personal_details_controller.dart';

Column dropdownButton(PersonalDetailsController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'city'.tr,
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
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.customGreyColor3,
            width: 1.w,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Obx(
          () => DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primaryColor,
            ),
            value: controller.city.value,
            items: ['نابلس', 'رام الله', 'القدس', 'الخليل', 'غزة']
                .map(
                  (city) => DropdownMenuItem(
                    value: city,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        city,
                        style: Theme.of(Get.context!)
                            .textTheme
                            .bodyMedium!
                            .copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.customGreyColor2,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.city.value = value;
              }
            },
          ),
        ),
      ),
    ],
  );
}
