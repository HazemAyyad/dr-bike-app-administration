import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../controllers/checks_controller.dart';

class NewCheckScreen extends GetView<ChecksController> {
  const NewCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNewCheck = !controller.isInComing;

    return Scaffold(
      appBar: CustomAppBar(
          title: isNewCheck ? 'newCheck'.tr : 'newReceipt'.tr, action: false),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              CustomTextField(
                label: 'checkValue',
                hintText: 'totalExample',
                controller: controller.checkValueController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                isRequired: true,
                enabled: !controller.isEdit.value,
              ),
              SizedBox(height: isNewCheck ? 0 : 16.h),
              isNewCheck
                  ? const SizedBox()
                  : Column(
                      children: [
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'seller'.tr,
                                  value: RxBool(!controller
                                          .selectedCustomersSellers.value ==
                                      true),
                                  onChanged: (val) {
                                    if (controller.isEdit.value) {
                                      null;
                                    } else {
                                      controller.selectedValue.value = null;
                                      controller.selectedCustomersSellers
                                          .value = false;
                                    }
                                  },
                                ),
                              ),
                              Flexible(
                                child: CustomCheckBox(
                                  title: 'customer'.tr,
                                  value: RxBool(!controller
                                          .selectedCustomersSellers.value ==
                                      false),
                                  onChanged: (val) {
                                    if (controller.isEdit.value) {
                                      null;
                                    } else {
                                      controller.selectedValue.value = null;
                                      controller.selectedCustomersSellers
                                          .value = true;
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                        Obx(
                          () => CustomDropdownField(
                            validator: (p0) => null,
                            isEnabled: !controller.isEdit.value,
                            label: 'beneficiaryName',
                            hint: 'customerNameExample',
                            dropdownField:
                                controller.selectedCustomersSellers.value ==
                                        false
                                    ? controller.allCustomersList
                                        .map(
                                          (e) => DropdownMenuItem<String>(
                                            value: e.id.toString(),
                                            child: Text(e.name),
                                          ),
                                        )
                                        .toList()
                                    : controller.allSellersList
                                        .map(
                                          (e) => DropdownMenuItem<String>(
                                            value: e.id.toString(),
                                            child: Text(e.name),
                                          ),
                                        )
                                        .toList(),
                            value: controller.selectedCustomersSellers.value ==
                                    false
                                ? controller.allCustomersList
                                    .firstWhereOrNull(
                                      (element) =>
                                          element.id.toString() ==
                                          controller.selectedValue.value,
                                    )
                                    ?.id
                                    .toString()
                                : controller.allSellersList
                                    .firstWhereOrNull(
                                      (element) =>
                                          element.id.toString() ==
                                          controller.selectedValue.value,
                                    )
                                    ?.id
                                    .toString(),
                            onChanged: (val) {
                              controller.selectedValue.value = val!;
                            },
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: 16.h),
              CustomCalendar(
                isVisible: controller.isCalendarVisible,
                onTap: () => controller.toggleCalendar(),
                selectedDay: controller.selectedDay,
                label: 'due_date',
                isRequired: true,
              ),
              SizedBox(height: 16.h),
              CustomDropdownField(
                isRequired: true,
                label: 'currencyy',
                hint: 'currencyExample',
                items: controller.currency,
                onChanged: (value) {
                  controller.currencyController.text = value!;
                },
                value: controller.currencyController.text.isEmpty
                    ? null
                    : controller.currencyController.text,
                isEnabled: !controller.isEdit.value,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'checkNumber',
                hintText: 'checkNumberExample',
                controller: controller.checkNumberController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                isRequired: true,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'bankName',
                hintText: 'bankNameExample',
                controller: controller.bankNameController,
                textInputAction: TextInputAction.next,
                isRequired: true,
              ),
              if (controller.editCheckBackImage.value == null)
                SizedBox(height: 30.h),
              if (controller.editCheckFrontImage.value != null &&
                  controller.isEdit.value)
                Column(
                  children: [
                    const SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'checkFrontImage',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: 'Dismiss',
                              barrierColor: Colors.black.withAlpha(128),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              pageBuilder: (context, anim1, anim2) {
                                return FullScreenZoomImage(
                                  imageUrl: controller
                                      .editCheckFrontImage.value!.path,
                                );
                              },
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl:
                                controller.editCheckFrontImage.value!.path,
                            fit: BoxFit.cover,
                            height: 300.h,
                            width: 300.w,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryColor),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.error,
                              size: 50,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),

              UploadImageButton(
                selectedFile: controller.checkFrontImage,
                title: 'checkFrontImage',
              ),
              // FormField<void>(
              //   validator: (file) {
              //     if (controller.checkFrontImage.value == null) {
              //       return 'checkFrontImage'.tr;
              //     }
              //     return null;
              //   },
              //   builder: (formFieldState) {
              //     return Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         if (formFieldState.hasError)
              //           Padding(
              //             padding: const EdgeInsets.only(top: 5),
              //             child: Text(
              //               formFieldState.errorText ?? "",
              //               style: const TextStyle(
              //                   color: Colors.red, fontSize: 12),
              //             ),
              //           ),
              //       ],
              //     );
              //   },
              // ),
              // MediaUploadButton(
              //   title: 'checkFrontImage',
              //   allowedType: MediaType.image,
              //   onFilesChanged: (files) {
              //     controller.checkFrontImage = [files.first];
              //   },
              // ),

              if (controller.editCheckBackImage.value == null)
                SizedBox(height: 30.h),
              if (controller.editCheckBackImage.value != null &&
                  controller.isEdit.value &&
                  controller.isInComing)
                Column(
                  children: [
                    const SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'checkBackImage',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: 'Dismiss',
                              barrierColor: Colors.black.withAlpha(128),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              pageBuilder: (context, anim1, anim2) {
                                return FullScreenZoomImage(
                                  imageUrl:
                                      controller.editCheckBackImage.value!.path,
                                );
                              },
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl: controller.editCheckBackImage.value!.path,
                            fit: BoxFit.cover,
                            height: 300.h,
                            width: 300.w,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryColor),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.error,
                              size: 50,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              isNewCheck
                  ? const SizedBox()
                  : UploadImageButton(
                      selectedFile: controller.checkBackImage,
                      title: 'checkBackImage',
                    ),
              // MediaUploadButton(
              //   title: 'checkBackImage',
              //   allowedType: MediaType.image,
              //   onFilesChanged: (files) {
              //     controller.checkBackImage = [files.first];
              //   },
              // ),
              SizedBox(height: isNewCheck ? 0 : 50.h),
              AppButton(
                isLoading: controller.isLoading,
                text: isNewCheck ? 'createCheck'.tr : 'cashTheChecks'.tr,
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.w700,
                    ),
                onPressed: () {
                  controller.isEdit.value
                      ? controller.editChecks(
                          context: context,
                          isInComing: !isNewCheck,
                          checkId: controller.checkId!,
                        )
                      : controller.addChecks(
                          isInComing: !isNewCheck,
                          context: context,
                          customerId: !isNewCheck &&
                                  !controller.selectedCustomersSellers.value
                              ? controller.selectedValue.value
                              : null,
                          sellerId: !isNewCheck &&
                                  controller.selectedCustomersSellers.value
                              ? controller.selectedValue.value
                              : null,
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
