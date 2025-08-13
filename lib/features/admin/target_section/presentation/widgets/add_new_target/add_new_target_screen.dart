import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/target_section_controller.dart';
import 'follow_up.dart';

class AddNewTargetScreen extends GetView<TargetSectionController> {
  const AddNewTargetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar( title: 'addNewTarget', action: false),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 20.h),
          CustomTextField(
            isRequired: true,
            label: 'targetName',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'targetNameExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.targetNameController,
          ),
          SizedBox(height: 20.h),
          CustomDropdownField(
            isRequired: true,
            label: 'targetType',
            hint: 'targetTypeExample',
            items: controller.targetTypes,
            onChanged: (value) {
              controller.targetType = value!;
            },
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            isRequired: true,
            label: 'mainValue',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'targetValueExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.mainValueController,
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            isRequired: true,
            label: 'targetValue',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'mainValueExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.targetValueController,
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            label: 'notes',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'notesExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.notesController,
          ),
          SizedBox(height: 20.h),
          // follow up
          followUp(context, controller),
          SizedBox(height: 30.h),
          AppButton(
            text: 'addTarget',
            onPressed: controller.createTarget,
            height: 40.h,
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
