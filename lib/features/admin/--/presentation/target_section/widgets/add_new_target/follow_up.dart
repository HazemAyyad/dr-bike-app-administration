import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../../core/services/theme_service.dart';
import '../../../../../../../core/utils/app_colors.dart';

Column followUp(BuildContext context, controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'followUp'.tr,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor6
                  : AppColors.customGreyColor,
            ),
      ),
      SizedBox(height: 10.h),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Obx(
          () => Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Radio<int>(
                    fillColor: WidgetStateColor.resolveWith(
                      (states) => AppColors.primaryColor,
                    ),
                    value: 0,
                    groupValue: controller.selectedTypeIndex.value,
                    onChanged: (value) {
                      controller.selectedTypeIndex.value = value!;
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  Flexible(
                    child: CustomDropdownField(
                      isEnabled: controller.selectedTypeIndex.value == 0
                          ? true
                          : false,
                      isRequired: true,
                      label: 'product',
                      hint: 'productExample',
                      items: controller.productsList,
                      onChanged: (value) {
                        controller.product = value!;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Radio<int>(
                    fillColor: WidgetStateColor.resolveWith(
                      (states) => AppColors.primaryColor,
                    ),
                    value: 1,
                    groupValue: controller.selectedTypeIndex.value,
                    onChanged: (value) {
                      controller.selectedTypeIndex.value = value!;
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  Flexible(
                    child: CustomDropdownField(
                      isEnabled: controller.selectedTypeIndex.value == 1
                          ? true
                          : false,
                      isRequired: true,
                      label: 'person',
                      hint: 'personExample',
                      items: controller.personalsList,
                      onChanged: (value) {
                        controller.personal = value!;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Radio<int>(
                    fillColor: WidgetStateColor.resolveWith(
                      (states) => AppColors.primaryColor,
                    ),
                    value: 2,
                    groupValue: controller.selectedTypeIndex.value,
                    onChanged: (value) {
                      controller.selectedTypeIndex.value = value!;
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  Flexible(
                    child: CustomDropdownField(
                      isEnabled: controller.selectedTypeIndex.value == 2
                          ? true
                          : false,
                      isRequired: true,
                      label: 'employee',
                      hint: 'employeeNameExample',
                      items: controller.employeesList,
                      onChanged: (value) {
                        controller.employee = value!;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
