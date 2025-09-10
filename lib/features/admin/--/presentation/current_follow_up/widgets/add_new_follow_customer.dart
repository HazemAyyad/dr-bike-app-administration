import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/state_manager.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../controllers/current_follow_up_controller.dart';

class AddNewFollowCustomerScreen extends GetView<CurrentFollowUpController> {
  const AddNewFollowCustomerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'addNewCustomer', action: false),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 10.h),
          CustomTextField(
            isRequired: true,
            label: 'customerName',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'employeeNameExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.customerNameController,
          ),
          SizedBox(height: 20.h),
          CustomDropdownField(
            isRequired: true,
            label: 'customerTypeTitle',
            hint: 'customerTypeExample',
            items: controller.customerTypeList,
            onChanged: (value) {
              controller.selectedCustomerType = value!;
            },
            border: Border.all(color: AppColors.customGreyColor3),
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            isRequired: true,
            label: 'phoneNumberTitle',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'phoneNumberExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.customerphoneNumberController,
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            isRequired: true,
            label: 'notes',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'notesExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.customerNotesController,
          ),
          SizedBox(height: 20.h),
          AppButton(
            text: 'addCustomer',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
            onPressed: controller.addNewCustomer,
            height: 40.h,
          ),
        ],
      ),
    );
  }
}
