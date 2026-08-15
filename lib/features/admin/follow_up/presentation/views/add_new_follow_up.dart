import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
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
                  _FollowUpStepper(
                    timeLineSteps: controller.timeLineSteps,
                    selectedStep: controller.selectedStep,
                    changeSelected: controller.changeSelected,
                  ),
                  SizedBox(height: 20.h),
                  CustomTextField(
                    label: 'details',
                    hintText: 'details',
                    controller: controller.itemIdController,
                    focusNode: controller.detailsFocusNode,
                    minLines: 6,
                    maxLines: 10,
                    validator: (p0) => null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        controller.openCustomerPickerFromKeyboard(),
                    onChanged: (_) => controller.scheduleAutoSave(),
                  ),
                  SizedBox(height: 16.h),
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
                              dropdownKey: controller.customerDropdownKey,
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                fit: FlexFit.loose,
                                constraints: BoxConstraints(maxHeight: 220.h),
                                searchDelay: const Duration(milliseconds: 120),
                                searchFieldProps: TextFieldProps(
                                  focusNode: controller.customerSearchFocusNode,
                                  autofocus: true,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'search'.tr,
                                    prefixIcon:
                                        const Icon(Icons.search_rounded),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
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
                                controller.scheduleAutoSave();
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
                        controller.scheduleAutoSave();
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
                    _AutoSaveStatus(controller: controller),
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

class _FollowUpStepper extends StatelessWidget {
  const _FollowUpStepper({
    required this.timeLineSteps,
    required this.selectedStep,
    required this.changeSelected,
  });

  final List<Map<int, String>> timeLineSteps;
  final RxInt selectedStep;
  final void Function(int index) changeSelected;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            for (var i = 0; i < timeLineSteps.length; i++) ...[
              Expanded(
                child: _FollowUpStepItem(
                  index: i + 1,
                  label: timeLineSteps[i].values.first.tr,
                  selectedStep: selectedStep.value,
                  onTap: () => changeSelected(i + 1),
                ),
              ),
              if (i < timeLineSteps.length - 1)
                Container(
                  width: 18.w,
                  height: 2.h,
                  color: selectedStep.value > i + 1
                      ? AppColors.primaryColor
                      : AppColors.customGreyColor5.withValues(alpha: 0.35),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FollowUpStepItem extends StatelessWidget {
  const _FollowUpStepItem({
    required this.index,
    required this.label,
    required this.selectedStep,
    required this.onTap,
  });

  final int index;
  final String label;
  final int selectedStep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = selectedStep == index;
    final isDone = selectedStep > index;
    final color = isActive || isDone
        ? AppColors.primaryColor
        : AppColors.customGreyColor5;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isActive || isDone
                  ? AppColors.primaryColor
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
            ),
            child: Center(
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                size: isDone ? 18.sp : 8.sp,
                color: isActive || isDone ? Colors.white : color,
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              color: color,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSaveStatus extends StatelessWidget {
  const _AutoSaveStatus({required this.controller});

  final FollowUpController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FollowUpController>(
      id: 'autoSaveStatus',
      builder: (_) {
        final hasError = controller.hasAutoSaveError.value;
        final isSaving = controller.isAutoSaving.value;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Row(
              key: ValueKey('$isSaving-$hasError'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18.sp,
                    color:
                        hasError ? AppColors.redColor : AppColors.customGreen1,
                  ),
                SizedBox(width: 6.w),
                Text(
                  isSaving
                      ? 'saving'.tr
                      : hasError
                          ? 'error'.tr
                          : 'saved'.tr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: hasError
                        ? AppColors.redColor
                        : ThemeService.isDark.value
                            ? AppColors.customGreyColor3
                            : AppColors.customGreyColor5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
