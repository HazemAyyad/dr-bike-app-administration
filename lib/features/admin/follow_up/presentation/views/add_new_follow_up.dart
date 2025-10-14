import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../maintenance/presentation/widgets/custom_line_steps_widget.dart';
import '../../../maintenance/presentation/widgets/next_back_button.dart';
import '../controllers/follow_up_controller.dart';

class AddNewFollowUpScreen extends GetView<FollowUpController> {
  const AddNewFollowUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'createFollowUp',
        action: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: GetBuilder<FollowUpController>(
            builder: (conteoller) {
              return Column(
                children: [
                  SizedBox(height: 10.h),
                  CustomLineSteps(
                    timeLineSteps: controller.timeLineSteps,
                    selectedStep: controller.selectedStep,
                    changeSelected: controller.changeSelected,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: CustomCheckBox(
                                    title: 'seller'.tr,
                                    value: RxBool(
                                        !controller.isCustomer.value == true),
                                    onChanged: (val) {
                                      if (controller.isEdite.value) {
                                        return;
                                      }
                                      controller.customerAndSellerIdController
                                          .clear();
                                      controller.isCustomer.value = false;
                                      controller.update();
                                    },
                                  ),
                                ),
                                Flexible(
                                  child: CustomCheckBox(
                                    title: 'customer'.tr,
                                    value: RxBool(
                                        !controller.isCustomer.value == false),
                                    onChanged: (val) {
                                      if (controller.isEdite.value) {
                                        return;
                                      }
                                      controller.customerAndSellerIdController
                                          .text = '';
                                      controller.isCustomer.value = true;
                                      controller.update();
                                    },
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 10.h),
                            CustomDropdownFieldWithSearch(
                              tital: controller.isCustomer.value == false
                                  ? 'customerName'.tr
                                  : 'sellerName'.tr,
                              hint: 'employeeNameExample',
                              items: controller.isCustomer.value == false
                                  ? controller.allCustomersList
                                  : controller.allSellersList,
                              value: (controller.customerAndSellerIdController
                                      .text.isEmpty)
                                  ? null
                                  : (controller.isCustomer.value == false
                                      ? controller.allCustomersList
                                          .firstWhereOrNull(
                                          (e) =>
                                              e.id.toString() ==
                                              controller
                                                  .customerAndSellerIdController
                                                  .text,
                                        )
                                      : controller.allSellersList
                                          .firstWhereOrNull(
                                          (e) =>
                                              e.id.toString() ==
                                              controller
                                                  .customerAndSellerIdController
                                                  .text,
                                        )),
                              onChanged: (value) {
                                controller.customerAndSellerIdController.text =
                                    value.id.toString();
                              },
                              itemAsString: (f) => f.name,
                              compareFn: (a, b) => a.id == b.id,
                              isEnabled: !controller.isEdite.value,
                            ),
                          ],
                        ),
                      ),
                      if (controller.selectedStep.value == 1)
                        IconButton(
                          onPressed: () => Get.toNamed(
                            AppRoutes.ADDNEWCUSTOMERSCREEN,
                            arguments: {
                              'employeeType': '',
                              'employeeId': '',
                              'sellerId': '',
                            },
                          ),
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
                    label: 'details',
                    hintText: 'details',
                    controller: controller.itemIdController,
                    minLines: 6,
                    maxLines: 10,
                    validator: (p0) => null,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            text: controller.selectedStep.value == 1
                                ? 'step_one'.tr
                                : controller.selectedStep.value == 2
                                    ? 'step_two'.tr
                                    : 'step_three'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeService.isDark.value
                                      ? AppColors.whiteColor
                                      : AppColors.blackColor,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (controller.isEdite.value)
                    AppButton(
                      isSafeArea: false,
                      isLoading: controller.isLoading,
                      text: 'save',
                      onPressed: () {
                        controller.addFollowUp(
                          step: controller.selectedStep.value - 1,
                        );
                      },
                    ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Flexible(
                        child: NextBackButton(
                          isLoading: controller.isLoading,
                          endTitle: 'delivered',
                          totalSteps: controller.timeLineSteps.length.obs,
                          selectedStep: controller.selectedStep,
                          onPressedBack: () {
                            if (controller.formKey.currentState!.validate()) {
                              if (controller.selectedStep.value == 2) {
                                return;
                              }
                              return controller.prevStep();
                            }
                          },
                          onPressedNext: () {
                            if (controller.formKey.currentState!.validate()) {
                              return controller.nextStep();
                            }
                          },
                        ),
                      ),
                      if (controller.selectedStep.value == 3)
                        SizedBox(width: 10.w),
                      if (controller.selectedStep.value == 3)
                        AppButton(
                          isLoading: controller.isLoading,
                          text: 'sale_rejected',
                          color: AppColors.redColor,
                          onPressed: () {
                            controller.selectedStep.value = 4;
                            Get.back();
                            controller.addFollowUp(step: 4);
                          },
                          width: 120.w,
                          height: 45.h,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
