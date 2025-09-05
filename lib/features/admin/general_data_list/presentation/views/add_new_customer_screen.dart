import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_phone_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/general_data_list_controller.dart';

class AddNewCustomerScreen extends GetView<GeneralDataListController> {
  const AddNewCustomerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sellerId = Get.arguments['sellerId'];
    final employeeId = Get.arguments['employeeId'];
    final employeeType = Get.arguments['employeeType'];

    return Scaffold(
      appBar: CustomAppBar(
        title: controller.isEdit.value ? 'editCustomer' : 'addNewCustomer',
        action: false,
      ),
      body: Form(
        key: controller.formKey,
        child: GetBuilder<GeneralDataListController>(
          builder: (controller) {
            if (controller.isEditLoading.value) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Flexible(
                      child: CustomTextField(
                        isRequired: true,
                        label: 'customerName',
                        hintText: 'customerNameExample',
                        controller: controller.customerNameController,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: CustomDropdownField(
                        isRequired: true,
                        label: 'customerTypeTitle',
                        hint: 'customerNameExample',
                        value: controller.selectedCustomerType.text.isEmpty
                            ? null
                            : controller.selectedCustomerType.text,
                        items: controller.customerTypeList,
                        onChanged: (value) {
                          controller.selectedCustomerType.text = value!;
                        },
                        border: Border.all(color: AppColors.customGreyColor3),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                CustomPhoneField(
                  label: 'customerPhoneNumber',
                  hintText: 'phoneNumberExample',
                  controller: controller.phoneNumberController,
                ),
                SizedBox(height: 10.h),
                CustomPhoneField(
                  label: 'alternatePhone',
                  hintText: 'phoneNumberExample',
                  controller: controller.subPhoneNumberController,
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Flexible(
                      child: CustomTextField(
                        label: 'facebookName',
                        hintText: 'facebookNameExample',
                        controller: controller.facebookNameController,
                        validator: (p0) => null,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: CustomTextField(
                        label: 'facebookLink',
                        hintText: 'facebookLinkExample',
                        controller: controller.facebookLinkController,
                        validator: (p0) => null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Flexible(
                      child: CustomTextField(
                        label: 'instagramName',
                        hintText: 'instagramNameExample',
                        controller: controller.instagramNameController,
                        validator: (p0) => null,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: CustomTextField(
                        label: 'instagramLink',
                        hintText: 'instagramLinkExample',
                        controller: controller.instagramLinkController,
                        validator: (p0) => null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                CustomDropdownField(
                  label: 'closeContacts',
                  hint: 'customerNameExample',
                  items: controller.closePeopleList,
                  onChanged: (value) {
                    controller.closePeople.text = value!;
                  },
                  border: Border.all(color: AppColors.customGreyColor3),
                  validator: (p0) => null,
                ),
                SizedBox(height: 20.h),
                controller.isEdit.value
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          controller.personalIdImage.isEmpty
                              ? SizedBox.shrink()
                              : Text(
                                  'personalIdImage'.tr,
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
                            child: controller.personalIdImage.isEmpty
                                ? SizedBox.shrink()
                                : Row(
                                    children: [
                                      ...controller.personalIdImage
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
                                                      controller.personalIdImage
                                                          .removeAt(index);
                                                      controller.update();
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
                          SizedBox(height: 15.h),
                        ],
                      )
                    : SizedBox.shrink(),

                SizedBox(height: 0.h),
                controller.isEdit.value
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          controller.personalIdImage.isEmpty
                              ? SizedBox.shrink()
                              : Text(
                                  'carLicenseImage'.tr,
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
                            child: controller.licenseImage.isEmpty
                                ? SizedBox.shrink()
                                : Row(
                                    children: [
                                      ...controller.licenseImage
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
                                                      controller.licenseImage
                                                          .removeAt(index);
                                                      controller.update();
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
                          SizedBox(height: 15.h),
                        ],
                      )
                    : SizedBox.shrink(),

                Row(
                  children: [
                    Flexible(
                      child: MediaUploadButton(
                        allowedType: MediaType.image,
                        title: 'personalIdImage',
                        onFilesChanged: (files) {
                          controller.personalIdImage = files;
                        },
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Flexible(
                      child: MediaUploadButton(
                        allowedType: MediaType.image,
                        title: 'carLicenseImage',
                        onFilesChanged: (files) {
                          controller.licenseImage = files;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Flexible(
                      child: CustomTextField(
                        label: 'residenceLocation',
                        hintText: 'residenceLocationExample',
                        controller: controller.residenceLocationController,
                        validator: (p0) => null,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: CustomTextField(
                        label: 'work',
                        hintText: 'workExample',
                        controller: controller.workController,
                        validator: (p0) => null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // Row(
                //   children: [
                //     Flexible(
                //       child: CustomTextField(
                //         label: 'workLocation',
                //         hintText: 'residenceLocationExample',
                //         controller: controller.workLocationController,
                //         validator: (p0) => null,
                //       ),
                //     ),
                //     SizedBox(width: 10.w),
                //     Flexible(
                //       child: CustomPhoneField(
                //         label: 'closestPersonNumber',
                //         hintText: 'phoneNumberExample',
                //         controller: controller.closestPersonNumberController,
                //       ),
                //     ),
                //   ],
                // ),
                CustomTextField(
                  label: 'workLocation',
                  hintText: 'residenceLocationExample',
                  controller: controller.workLocationController,
                  validator: (p0) => null,
                ),
                SizedBox(height: 10.h),
                CustomPhoneField(
                  label: 'closestPersonNumber',
                  hintText: 'phoneNumberExample',
                  controller: controller.closestPersonNumberController,
                ),
                SizedBox(height: 10.h),
                CustomTextField(
                  label: 'closestPersonWork',
                  hintText: 'workTitleExample',
                  controller: controller.closestPersonWorkController,
                  validator: (p0) => null,
                ),
                SizedBox(height: 20.h),
                AppButton(
                  isLoading: controller.isLoading,
                  text:
                      controller.isEdit.value ? 'editCustomer' : 'addCustomer',
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                  onPressed: () {
                    if (controller.isEdit.value) {
                      controller.addPerson(
                        context: context,
                        customerId: controller.currentTab.value == 1
                            ? employeeId
                            : employeeType == 'customer'
                                ? employeeId
                                : '',
                        sellerId: controller.currentTab.value == 0
                            ? sellerId
                            : employeeType == 'seller'
                                ? sellerId
                                : '',
                      );
                    } else {
                      controller.addPerson(context: context);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
