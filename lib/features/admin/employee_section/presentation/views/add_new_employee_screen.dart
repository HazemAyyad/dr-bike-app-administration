import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/custom_time_picker.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_phone_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/add_employee_controller.dart';

class AddNewEmployeeScreen extends GetView<AddEmployeeController> {
  const AddNewEmployeeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title =
        Get.arguments['AddNewEmployeeScreen'] ?? 'addNewEmployee';
    return Scaffold(
      appBar: CustomAppBar(title: title, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      isRequired: true,
                      label: 'employeeName',
                      hintText: 'employeeNameExample',
                      // hintColor: ThemeService.isDark.value
                      //     ? AppColors.customGreyColor
                      //     : AppColors.customGreyColor6,
                      controller: controller.employeeNameController,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      isRequired: true,
                      label: 'email',
                      hintText: 'test@mail.com',
                      controller: controller.emailController,
                      validator: (p0) => Validators.validateEmail(
                        p0,
                        Get.locale!.languageCode,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              CustomPhoneField(
                label: 'phoneNumber',
                hintText: '58458XXXXX',
                controller: controller.phoneNumberController,
              ),
              SizedBox(height: 10.h),

              CustomPhoneField(
                label: 'alternatePhone',
                hintText: '58410XXXXX',
                controller: controller.subPhoneController,
              ),
              // Row(
              //   children: [
              //     Flexible(
              //       child:
              //     ),
              //     SizedBox(width: 10.w),
              //     Flexible(
              //       child:
              //     ),
              //   ],
              // ),
              SizedBox(height: controller.isEditEmployee ? 0 : 15.h),
              controller.isEditEmployee
                  ? SizedBox()
                  : Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            isRequired: true,
                            label: 'password',
                            hintText: '**********',
                            controller: controller.passwordController,
                            validator: (p0) => Validators.validatePassword(
                              p0,
                              Get.locale!.languageCode,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: CustomTextField(
                            isRequired: true,
                            label: 'confirmPassword',
                            hintText: '**********',
                            controller: controller.confirmPasswordController,
                            validator: (p0) => Validators.validatePassword(
                              p0,
                              Get.locale!.languageCode,
                            ),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: 15.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'hourlyRate',
                      hintText: 'employeeSalaryExample',
                      controller: controller.hourlyRateController,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      label: 'overTimeRate',
                      hintText: 'employeeSalaryExample',
                      controller: controller.overTimeRateController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                label: 'workHoursOfDayExample'.tr.split('(')[0],
                hintText: 'workHoursExample',
                controller: controller.workHoursOfDayController,
              ),
              SizedBox(height: 15.w),
              CustomTimePicker(
                isVisible: controller.isVisible,
                onTap: () =>
                    controller.isVisible.value = !controller.isVisible.value,
                selectedTime: controller.selectedTime,
                label: 'regularWorkingHours',
              ),
              SizedBox(height: 15.h),
              controller.isEditEmployee
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.documentsImageList.isEmpty
                            ? SizedBox.shrink()
                            : Text(
                                'documentsImages'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: (ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                        SizedBox(height: 5.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(
                            () => controller.deleteImage.value
                                ? SizedBox.shrink()
                                : Row(
                                    children: [
                                      ...controller.documentsImageList
                                          .asMap()
                                          .entries
                                          .map(
                                        (entry) {
                                          final index = entry.key;
                                          final file = entry.value;
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5.w),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.r),
                                                  child: CachedNetworkImage(
                                                    imageUrl: file.path,
                                                    height: 200.h,
                                                    width: 200.w,
                                                    fit: BoxFit.fill,
                                                    fadeInDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    fadeOutDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                ),
                                                // زرار فوق الصورة
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      controller
                                                          .deleteImage(true);
                                                      controller
                                                          .documentsImageList
                                                          .removeAt(index);
                                                      controller
                                                          .deleteImage(false);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                      ],
                    )
                  : SizedBox.shrink(),
              MediaUploadButton(
                title: 'documentsImages',
                onFilesChanged: (val) {
                  controller.documentsImageList.addAll(val);
                },
                allowedType: MediaType.image,
              ),
              SizedBox(height: 15.h),
              controller.isEditEmployee
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.employeeImageList.isEmpty
                            ? SizedBox.shrink()
                            : Text(
                                'employeeImage'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: (ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                        SizedBox(height: 5.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(
                            () => controller.deleteImage.value
                                ? SizedBox.shrink()
                                : Row(
                                    children: [
                                      ...controller.employeeImageList
                                          .asMap()
                                          .entries
                                          .map(
                                        (entry) {
                                          final index = entry.key;
                                          final file = entry.value;

                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5.w),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.r),
                                                  child: file.path
                                                          .startsWith('http')
                                                      ? CachedNetworkImage(
                                                          imageUrl: file.path,
                                                          height: 200.h,
                                                          width: 200.w,
                                                          fit: BoxFit.fill,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const Center(
                                                                  child:
                                                                      CircularProgressIndicator()),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        )
                                                      : Image.file(
                                                          file,
                                                          height: 200.h,
                                                          width: 200.w,
                                                          fit: BoxFit.fill,
                                                        ),
                                                ),
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () {
                                                      controller
                                                          .deleteImage(true);
                                                      controller
                                                          .employeeImageList
                                                          .removeAt(index);
                                                      controller
                                                          .deleteImage(false);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                      ],
                    )
                  : SizedBox.shrink(),
              MediaUploadButton(
                title: 'employeeImage',
                onFilesChanged: (val) {
                  controller.employeeImageList.addAll(val);
                },
                allowedType: MediaType.image,
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(
                    'permissions'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => controller.isAllPermissionsSelected.value
                        ? controller.setAllPermissionsFalse()
                        : controller.setAllPermissionsTrue(),
                    child: Obx(
                      () => Text(
                        controller.isAllPermissionsSelected.value
                            ? 'unselectAll'.tr
                            : 'selectAll'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.solid,
                            ),
                      ),
                    ),
                  )
                ],
              ),
              ...List.generate(
                controller.permissionsList.length,
                (index) => CustomCheckBox(
                  title: controller.permissionsList[index]['name'],
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.customGreyColor2,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                  value: controller.permissionsList[index]['permission'],
                  onChanged: (value) {
                    controller.permissionsList[index]['permission'].value =
                        value;
                  },
                ),
              ),
              SizedBox(height: 20.h),
              AppButton(
                isLoading: controller.isLoading,
                text:
                    title == 'editEmployee' ? 'saveChanges' : 'addNewEmployee',
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                height: 50.h,
                onPressed: () => controller.isLoading.value
                    ? null
                    : controller.addNewEmployee(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
