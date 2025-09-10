import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../controllers/current_follow_up_controller.dart';

class AddCustomerFollowUpScreen extends GetView<CurrentFollowUpController> {
  const AddCustomerFollowUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'createFollowUp',
        action: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: CustomDropdownField(
                  isRequired: true,
                  label: 'customerName',
                  hint: 'employeeNameExample',
                  items: controller.customerNameList,
                  onChanged: (value) {
                    controller.selectedCustomerName = value!;
                  },
                  border: Border.all(color: AppColors.customGreyColor3),
                ),
              ),
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.ADDNEWCUSTOMERSCREEN),
                icon: Icon(
                  Icons.add_circle_sharp,
                  color: AppColors.primaryColor,
                  size: 35.sp,
                ),
              )
            ],
          ),
          SizedBox(height: 20.h),
          CustomTextField(
            isRequired: true,
            label: 'productDetailsTitle',
            labelColor: ThemeService.isDark.value
                ? AppColors.customGreyColor6
                : AppColors.customGreyColor,
            hintText: 'productDetailsExample',
            hintColor: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.customGreyColor6,
            controller: controller.customerphoneNumberController,
          ),
          SizedBox(height: 20.h),
          AppButton(
            text: 'addFollowUp',
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
            onPressed: controller.addNewFollowUp,
            height: 40.h,
          ),
        ],
      ),
    );
  }
}
