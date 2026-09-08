import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../maintenance/presentation/widgets/next_back_button.dart';
import '../../../widgets/unified_partner_selector.dart';
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
                  if (controller.isEdite.value ||
                      controller.canUseAdminOnly) ...[
                    Row(
                      children: [
                        if (controller.isEdite.value)
                          Expanded(
                            child: _AutoSaveStatus(controller: controller),
                          )
                        else
                          const Spacer(),
                        if (controller.canUseAdminOnly)
                          _AdminOnlyIconButton(controller: controller),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
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
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => controller.scheduleAutoSave(),
                  ),
                  SizedBox(height: 16.h),
                  _FollowUpPartnerSearch(
                    key: controller.customerPickerKey,
                    controller: controller,
                  ),
                  if (controller.isEdite.value) ...[
                    SizedBox(height: 8.h),
                    _FollowUpAuditSection(controller: controller),
                  ],
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

class _FollowUpPartnerSearch extends StatelessWidget {
  const _FollowUpPartnerSearch({Key? key, required this.controller})
      : super(key: key);

  final FollowUpController controller;

  SellerModel? _selectedPartner() {
    final list = controller.isCustomer.value
        ? controller.allCustomersList
        : controller.allSellersList;
    return list.firstWhereOrNull(
      (item) =>
          item.id.toString() == controller.customerAndSellerIdController.text,
    );
  }

  Future<void> _addPartner(bool isSeller) async {
    await Get.toNamed(
      AppRoutes.ADDNEWCUSTOMERSCREEN,
      arguments: {
        'sellerId': '',
        'employeeId': '',
        'popOnceOnSuccess': true,
        'employeeType': isSeller ? 'seller' : 'customer',
      },
    );
    controller.getAllCustomersAndSellers();
  }

  void _selectPartner(SellerModel item, bool isSeller) {
    controller.isCustomer.value = !isSeller;
    controller.customerAndSellerIdController.text = item.id.toString();
    controller.scheduleAutoSave();
    controller.update();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => UnifiedPartnerSelector<SellerModel>(
        customers: controller.allCustomersList,
        sellers: controller.allSellersList,
        selected: _selectedPartner(),
        selectedIsSeller: !controller.isCustomer.value,
        idOf: (item) => item.id,
        nameOf: (item) => item.name,
        phoneOf: (item) => item.phone,
        requiredSelection: true,
        onSelected: _selectPartner,
        onCleared: () {
          controller.customerAndSellerIdController.clear();
          controller.scheduleAutoSave();
        },
        onAddRequested: controller.selectedStep.value == 1 ? _addPartner : null,
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
          ],
        );
      },
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
          alignment: Alignment.centerLeft,
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

class _AdminOnlyIconButton extends StatelessWidget {
  const _AdminOnlyIconButton({required this.controller});

  final FollowUpController controller;

  @override
  Widget build(BuildContext context) {
    final isOn = controller.adminOnly.value;
    final color = isOn ? AppColors.primaryColor : AppColors.customGreyColor5;
    return Tooltip(
      message: 'adminOnlyFollowUp'.tr,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () {
          controller.adminOnly.value = !controller.adminOnly.value;
          controller.scheduleAutoSave();
          controller.update();
        },
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isOn ? 0.16 : 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: isOn ? 0.55 : 0.25),
            ),
          ),
          child: Icon(
            isOn
                ? Icons.admin_panel_settings_rounded
                : Icons.admin_panel_settings_outlined,
            color: color,
            size: 19.sp,
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
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color:
              isDark ? AppColors.customGreyColor2 : AppColors.customGreyColor7,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 10.w),
          childrenPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
          iconColor: AppColors.primaryColor,
          collapsedIconColor:
              isDark ? AppColors.customGreyColor3 : AppColors.customGreyColor5,
          leading: Icon(
            Icons.history_rounded,
            size: 18.sp,
            color: AppColors.primaryColor,
          ),
          title: Text(
            'followUpActivityLog'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.whiteColor : AppColors.secondaryColor,
            ),
          ),
          subtitle: controller.createdByName.value.isNotEmpty
              ? Text(
                  '${'createdBy'.tr}: ${controller.createdByName.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.customGreyColor3
                        : AppColors.customGreyColor5,
                  ),
                )
              : null,
          children: [
            if (controller.activityLogs.isEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    'noData'.tr,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark
                          ? AppColors.customGreyColor3
                          : AppColors.customGreyColor5,
                    ),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 520.w,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.05),
                      1: FlexColumnWidth(1.0),
                      2: FlexColumnWidth(2.2),
                    },
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: isDark
                            ? AppColors.customGreyColor2
                            : AppColors.customGreyColor7,
                      ),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        children: [
                          _AuditTableCell('date'.tr, header: true),
                          _AuditTableCell('employee'.tr, header: true),
                          _AuditTableCell('details'.tr, header: true),
                        ],
                      ),
                      ...controller.activityLogs.map((log) {
                        final description =
                            log['description']?.toString() ?? '';
                        final actorName = log['actor_name']?.toString() ?? '';
                        final createdAt = log['created_at']?.toString() ?? '';
                        return TableRow(
                          children: [
                            _AuditTableCell(createdAt),
                            _AuditTableCell(actorName),
                            _AuditTableCell(description, maxLines: 3),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuditTableCell extends StatelessWidget {
  const _AuditTableCell(
    this.text, {
    this.header = false,
    this.maxLines = 2,
  });

  final String text;
  final bool header;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final color = header
        ? AppColors.primaryColor
        : isDark
            ? AppColors.customGreyColor3
            : AppColors.customGreyColor5;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
      child: Text(
        text.isEmpty ? '-' : text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: header ? 10.5.sp : 10.sp,
          height: 1.25,
          fontWeight: header ? FontWeight.w900 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
