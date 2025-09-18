import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../controllers/checks_controller.dart';

class NewCheckScreen extends GetView<ChecksController> {
  const NewCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNewCheck = Get.arguments['isNewCheck'] ?? true;
    final RxnString selectedValue = RxnString();

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
                                    selectedValue.value = null;
                                    controller.selectedCustomersSellers.value =
                                        false;
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
                                    selectedValue.value = null;
                                    controller.selectedCustomersSellers.value =
                                        true;
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                        Obx(
                          () => CustomDropdownField(
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
                            value: selectedValue.value,
                            onChanged: (val) {
                              selectedValue.value = val!;
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
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'currencyy'.tr;
                //   }
                //   return null;
                // },
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
              SizedBox(height: 30.h),
              FormField<void>(
                validator: (file) {
                  if (controller.checkFrontImage.value == null) {
                    return 'checkFrontImage'.tr;
                  }
                  return null;
                },
                builder: (formFieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UploadImageButton(
                        selectedFile: controller.checkFrontImage,
                        title: 'checkFrontImage',
                      ),
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
              // MediaUploadButton(
              //   title: 'checkFrontImage',
              //   allowedType: MediaType.image,
              //   onFilesChanged: (files) {
              //     controller.checkFrontImage = [files.first];
              //   },
              // ),
              SizedBox(height: 30.h),
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
                  controller.addChecks(
                    isInComing: !isNewCheck,
                    context: context,
                    customerId: !isNewCheck &&
                            !controller.selectedCustomersSellers.value
                        ? selectedValue.value
                        : null,
                    sellerId:
                        !isNewCheck && controller.selectedCustomersSellers.value
                            ? selectedValue.value
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
