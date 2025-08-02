import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/debts_controller.dart';
import 'app_bar.dart';

void createDebts(
  BuildContext context,
  String title,
  String supTitle,
  Color color,
  DebtsController controller,
) {
  Get.bottomSheet(
    SafeArea(
      child: Scaffold(
        extendBody: true,
        appBar: appBar(title, false, context, Get.find<DebtsController>(),
            supTitle, color),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                CustomDropdownField(
                  label: 'customerName',
                  hint: 'employeeNameExample',
                  items: ['Employee 1', 'Employee 2', 'Employee 3'],
                  onChanged: (value) {
                    // Handle the change
                    controller.customerName = value!;
                    print('Selected employee: ${controller.customerName} ');
                  },
                  isRequired: true,
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    controller.pickDate(context);
                  },
                  child: CustomTextField(
                    isRequired: true,
                    enabled: false,
                    label: 'due_date',
                    labelColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor,
                    hintText: controller.dueDateController.text.isEmpty
                        ? 'endDateExample'
                        : showData(controller.dueDateController.text),
                    hintColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor6,
                    controller: controller.dueDateController,
                    suffixIcon: Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                CustomTextField(
                  isRequired: true,
                  label: 'total_debt',
                  labelColor: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor,
                  hintText: 'employeeSalaryExample',
                  hintColor: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.customGreyColor6,
                  controller: controller.totalDebtController,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text(
                      'receipt'.tr,
                      style:
                          Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor6
                                    : AppColors.customGreyColor,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400,
                              ),
                    ),
                    Text(
                      '*',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.red,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  ],
                ),
                SizedBox(height: 10.h),
                FormField<void>(
                  validator: (file) {
                    if (controller.selectedFile.isEmpty) {
                      return 'برجاء اختيار صورة الهوية';
                    }
                    return null;
                  },
                  builder: (formFieldState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaUploadButton(
                          title: 'uploadPersonalIdImage',
                          width: double.infinity,
                          allowedType: MediaType.image,
                          onFilesChanged: (files) {
                            controller.selectedFile = [files.first];
                          },
                        ),
                        // UploadButton(
                        //   selectedFile: controller.selectedFile,
                        //   title: 'uploadPersonalIdImage',
                        //   width: double.infinity,
                        //   textColor: ThemeService.isDark.value
                        //       ? Colors.white
                        //       : AppColors.primaryColor,
                        // ),
                        if (formFieldState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              formFieldState.errorText ?? "",
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20.h),
                CustomTextField(
                  label: 'other_details',
                  labelColor: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor,
                  hintText: 'other_details',
                  hintColor: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.customGreyColor6,
                  controller: controller.moreDetailsController,
                  validator: (p0) {
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                AppButton(
                  text: 'createNewDebt',
                  onPressed: () {
                    controller.createDebts();
                  },
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    ),
    ignoreSafeArea: false,
    isScrollControlled: true,
    backgroundColor:
        ThemeService.isDark.value ? AppColors.darckColor : Colors.white,
  );
}
