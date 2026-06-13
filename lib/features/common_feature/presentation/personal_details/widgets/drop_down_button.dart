import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/personal_details_controller.dart';

Column dropdownButton(PersonalDetailsController controller) {
  const defaultCities = ['نابلس', 'رام الله', 'القدس', 'الخليل', 'غزة'];
  final cities = List<String>.from(defaultCities);
  final currentCity = controller.city.value.trim();
  if (currentCity.isNotEmpty && !cities.contains(currentCity)) {
    cities.insert(0, currentCity);
  }

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
          () {
            final liveCity = controller.city.value.trim();
            final liveSelected = liveCity.isNotEmpty && cities.contains(liveCity)
                ? liveCity
                : null;

            return DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: controller.isAdmin ? 'optional'.tr : null,
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primaryColor,
            ),
            value: liveSelected,
            items: [
              if (controller.isAdmin)
                DropdownMenuItem<String?>(
                  value: null,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'optional'.tr,
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
              ...cities.map(
                  (city) => DropdownMenuItem<String?>(
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
            ],
            onChanged: (value) {
              controller.city.value = value ?? '';
            },
          );
          },
        ),
      ),
    ],
  );
}
