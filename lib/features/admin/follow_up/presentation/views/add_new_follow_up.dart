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
                                    value: RxBool(!controller.isCustomer.value),
                                    onChanged: (val) {
                                      if (controller.isEdite.value) {
                                        return;
                                      }
                                      controller.getAllCustomersAndSellers();
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
                                    value: RxBool(controller.isCustomer.value),
                                    onChanged: (val) {
                                      if (controller.isEdite.value) {
                                        return;
                                      }
                                      controller.getAllCustomersAndSellers();
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
                              tital: controller.isCustomer.value
                                  ? 'customerName'.tr
                                  : 'sellerName'.tr,
                              hint: 'employeeNameExample',
                              items: controller.isCustomer.value
                                  ? controller.allCustomersList
                                  : controller.allSellersList,
                              value: (controller.customerAndSellerIdController
                                      .text.isEmpty)
                                  ? null
                                  : (controller.isCustomer.value
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
                          )?.then(
                            (value) => controller.getAllCustomersAndSellers(),
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
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                  if (controller.canUseAdminOnly) ...[
                    SizedBox(height: 10.h),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryColor,
                      title: Text(
                        'adminOnlyFollowUp'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: ThemeService.isDark.value
                                  ? AppColors.whiteColor
                                  : AppColors.secondaryColor,
                            ),
                      ),
                      subtitle: Text(
                        'adminOnlyFollowUpHint'.tr,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontSize: 11.sp,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor3
                                  : AppColors.customGreyColor5,
                            ),
                      ),
                      value: controller.adminOnly.value,
                      onChanged: (value) {
                        controller.adminOnly.value = value;
                        controller.update();
                      },
                    ),
                  ],
                  if (controller.isEdite.value) ...[
                    SizedBox(height: 10.h),
                    _FollowUpAuditSection(controller: controller),
                  ],
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
                          endTitle:
                              controller.isEdite.value ? 'delivered' : 'save',
                          totalSteps: controller.isEdite.value
                              ? controller.timeLineSteps.length.obs
                              : 1.obs,
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
                      if (controller.isEdite.value &&
                          controller.selectedStep.value == 3)
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

class _FollowUpAuditSection extends StatelessWidget {
  const _FollowUpAuditSection({required this.controller});

  final FollowUpController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color:
              isDark ? AppColors.customGreyColor2 : AppColors.customGreyColor7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.createdByName.value.isNotEmpty)
            Text(
              '${'createdBy'.tr}: ${controller.createdByName.value}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.whiteColor : AppColors.secondaryColor,
              ),
            ),
          if (controller.activityLogs.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'followUpActivityLog'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.whiteColor : AppColors.secondaryColor,
              ),
            ),
            SizedBox(height: 6.h),
            ...controller.activityLogs.map((log) {
              final description = log['description']?.toString() ?? '';
              final actorName = log['actor_name']?.toString() ?? '';
              final createdAt = log['created_at']?.toString() ?? '';
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 15.sp,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        [
                          if (description.isNotEmpty) description,
                          if (actorName.isNotEmpty) actorName,
                          if (createdAt.isNotEmpty) createdAt,
                        ].join(' - '),
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          height: 1.25,
                          color: isDark
                              ? AppColors.customGreyColor3
                              : AppColors.customGreyColor5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
