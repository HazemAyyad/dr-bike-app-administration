import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/debts_controller.dart';
import 'app_bar.dart';

class CreateDebts extends GetView<DebtsController> {
  const CreateDebts({
    Key? key,
    required this.title,
    required this.supTitle,
    required this.color,
  }) : super(key: key);

  final String title;
  final String supTitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: CustomCheckBox(
                          title: 'seller'.tr,
                          value: RxBool(
                              !controller.selectedCustomersSellers.value ==
                                  true),
                          onChanged: (val) {
                            controller.customerOrSellerIdController.text = '';
                            controller.customerOrSellerIdController.clear();
                            controller.selectedCustomersSellers.value = false;
                          },
                        ),
                      ),
                      Flexible(
                        child: CustomCheckBox(
                          title: 'customer'.tr,
                          value: RxBool(
                              !controller.selectedCustomersSellers.value ==
                                  false),
                          onChanged: (val) {
                            controller.customerOrSellerIdController.text = '';
                            controller.customerOrSellerIdController.clear();
                            controller.selectedCustomersSellers.value = true;
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Obx(
                  () => CustomDropdownFieldWithSearch(
                    tital: controller.selectedCustomersSellers.value == false
                        ? 'customerName'.tr
                        : 'sellerName'.tr,
                    hint: 'employeeNameExample',
                    items: controller.selectedCustomersSellers.value == false
                        ? controller.allCustomersList
                        : controller.allSellersList,
                    // value: selectedValue.value,
                    onChanged: (val) {
                      controller.customerOrSellerIdController.text =
                          val!.id.toString();
                    },
                    itemAsString: (f) => f.name,
                    compareFn: (a, b) => a.id == b.id,
                  ),
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
                    hintText: controller.dueDateController.text.isEmpty
                        ? 'endDateExample'
                        : showData(controller.dueDateController.text),
                    controller: controller.dueDateController,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                CustomTextField(
                  isRequired: true,
                  label: 'total_debt',
                  hintText: 'employeeSalaryExample',
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
                // FormField<void>(
                //   validator: (file) {
                //     if (controller.selectedFile.isEmpty) {
                //       return 'receipt'.tr;
                //     }
                //     return null;
                //   },
                //   builder: (formFieldState) {
                //     return Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         MediaUploadButton(
                //           title: 'uploadPersonalIdImage',
                //           width: double.infinity,
                //           allowedType: MediaType.image,
                //           onFilesChanged: (files) {
                //             controller.selectedFile = files;
                //           },
                //         ),
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
                MediaUploadButton(
                  title: 'uploadPersonalIdImage',
                  width: double.infinity,
                  allowedType: MediaType.image,
                  onFilesChanged: (files) {
                    controller.selectedFile = files;
                  },
                ),
                SizedBox(height: 20.h),
                CustomTextField(
                  label: 'other_details',
                  hintText: 'other_details',
                  controller: controller.moreDetailsController,
                  validator: (p0) {
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                AppButton(
                  isLoading: controller.isLoading,
                  text: 'createNewDebt',
                  onPressed: () {
                    print(controller.customerOrSellerIdController.text);
                    if (controller.formKey.currentState?.validate() ?? false) {
                      controller.addDebts(
                        context: context,
                        isCustomer: !controller.selectedCustomersSellers.value,
                        type: supTitle == 'gave' ? 'owed to us' : 'we owe',
                      );
                    }
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
    );
  }
}
