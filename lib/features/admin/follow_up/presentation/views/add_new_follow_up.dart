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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          24.w,
          0,
          24.w,
          MediaQuery.viewInsetsOf(context).bottom + 16.h,
        ),
        child: Form(
          key: controller.formKey,
          child: GetBuilder<FollowUpController>(
            builder: (conteoller) {
              return Column(
                children: [
                  SizedBox(height: 10.h),
                  _FollowUpStageIndicator(controller: controller),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    label: 'details',
                    hintText: 'details',
                    controller: controller.itemIdController,
                    focusNode: controller.detailsFocusNode,
                    minLines: 2,
                    maxLines: 7,
                    validator: (p0) => null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        controller.openCustomerPickerFromKeyboard(),
                    onChanged: (_) => controller.scheduleAutoSave(),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    key: controller.customerPickerKey,
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
                                constraints: BoxConstraints(maxHeight: 170.h),
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
                    SizedBox(height: 8.h),
                    _FollowUpAuditSection(controller: controller),
                  ],
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

class _FollowUpStageIndicator extends StatelessWidget {
  const _FollowUpStageIndicator({required this.controller});

  final FollowUpController controller;

  String _labelForStep(int step) {
    if (step == 1) return 'initialFollowUp'.tr;
    if (step == 2) return 'notify_customer'.tr;
    if (step == 3) return 'completion_and_agreement'.tr;
    return 'archive'.tr;
  }

  Color _colorForStep(int step) {
    if (step == 1) return AppColors.primaryColor;
    if (step == 2) return Colors.blueAccent;
    if (step == 3) return AppColors.customGreen1;
    return AppColors.redColor;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final step = controller.selectedStep.value;
        final color = _colorForStep(step);
        return Row(
          children: [
            Container(
              width: 6.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _labelForStep(step),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
              ),
            ),
            if (controller.isEdite.value) ...[
              _StageTextButton(
                label: 'initialFollowUp'.tr,
                selected: step == 1,
                color: _colorForStep(1),
                onTap: () => controller.changeSelected(1),
              ),
              _StageTextButton(
                label: 'notify_customer'.tr,
                selected: step == 2,
                color: _colorForStep(2),
                onTap: () => controller.changeSelected(2),
              ),
              _StageTextButton(
                label: 'completion_and_agreement'.tr,
                selected: step == 3,
                color: _colorForStep(3),
                onTap: () => controller.changeSelected(3),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StageTextButton extends StatelessWidget {
  const _StageTextButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: EdgeInsetsDirectional.only(start: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? color : Colors.transparent,
          ),
        ),
        constraints: BoxConstraints(maxWidth: 64.w),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected
                ? color
                : ThemeService.isDark.value
                    ? AppColors.customGreyColor3
                    : AppColors.customGreyColor5,
          ),
        ),
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
