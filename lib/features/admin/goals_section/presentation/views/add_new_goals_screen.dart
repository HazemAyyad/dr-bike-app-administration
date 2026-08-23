import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../create_tasks/presentation/widgets/task_form_section_card.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../controllers/target_section_controller.dart';
import '../widgets/options_widget.dart';
import '../widgets/target_type_format_widget.dart';

class AddNewGoalScreen extends GetView<TargetSectionController> {
  const AddNewGoalScreen({Key? key}) : super(key: key);

  static const _compact = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(
        title: controller.isEdit.value ? 'editTarget' : 'addTarget',
        action: false,
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: GetBuilder<TargetSectionController>(
                  builder: (controller) {
                    return Column(
                      children: [
                        TaskFormSectionCard(
                          compact: _compact,
                          title: 'targetDetails',
                          child: Column(
                            children: [
                              CustomTextField(
                                isRequired: true,
                                label: 'targetName',
                                hintText: 'targetNameExample',
                                controller: controller.targetNameController,
                              ),
                              SizedBox(height: 8.h),
                              CustomTextField(
                                label: 'notes',
                                hintText: 'notesExample',
                                controller: controller.notesController,
                                minLines: 2,
                                maxLines: 5,
                                validator: (_) => null,
                              ),
                            ],
                          ),
                        ),
                        TaskFormSectionCard(
                          compact: _compact,
                          title: 'targetType',
                          child: Column(
                            children: [
                              CustomDropdownField(
                                isRequired: true,
                                label: 'targetType',
                                hint: 'targetTypeExample',
                                items: controller.targetTypes,
                                value: controller
                                        .targetScopeController.text.isEmpty
                                    ? null
                                    : controller.targetScopeController.text,
                                onChanged: (value) {
                                  controller.targetScopeController.text =
                                      value!;
                                },
                              ),
                              SizedBox(height: 8.h),
                              CustomDropdownField(
                                isRequired: true,
                                label: 'targetTypeFormat',
                                hint: 'targetTypeFormat',
                                value:
                                    controller.targetTypeController.text.isEmpty
                                        ? null
                                        : controller.targetTypeController.text,
                                items: controller.targetTypeList,
                                onChanged: (value) {
                                  controller.formController.clear();
                                  controller.mainCategoriesIdController.clear();
                                  controller.subCategoriesIdController.clear();
                                  controller.storeSectionIdController.clear();
                                  controller.productIdController.clear();
                                  controller.customerAndSellerIdController
                                      .clear();
                                  controller.employeeIdController.clear();
                                  controller.boxIdController.clear();

                                  controller.targetTypeController.text = value!;
                                  controller.calculationModeController.text =
                                      controller.supportsTotalMode
                                          ? 'total'
                                          : 'detailed';
                                  controller.update();
                                },
                                isEnabled: !controller.isEdit.value,
                              ),
                              if (controller.supportsTotalMode) ...[
                                SizedBox(height: 8.h),
                                CustomDropdownField(
                                  isRequired: true,
                                  label: 'calculationMode',
                                  hint: 'calculationMode',
                                  value: controller.calculationModeController
                                          .text.isEmpty
                                      ? null
                                      : controller
                                          .calculationModeController.text,
                                  items: controller.calculationModes,
                                  onChanged: (value) {
                                    controller.calculationModeController.text =
                                        value!;
                                    if (value == 'total') {
                                      controller.formController.clear();
                                      controller.mainCategoriesIdController
                                          .clear();
                                      controller.subCategoriesIdController
                                          .clear();
                                      controller.storeSectionIdController
                                          .clear();
                                      controller.productIdController.clear();
                                      controller.productsIds.clear();
                                      controller.customerAndSellerIdController
                                          .clear();
                                    }
                                    controller.update();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (controller.targetTypeController.text.isNotEmpty)
                          TaskFormSectionCard(
                            compact: _compact,
                            title: 'followUp',
                            child: Column(
                              children: [
                                const TargetTypeFormatWidget(),
                                if (controller.isDetailedMode)
                                  const OptionsWidget(),
                                const _SelectedGoalProducts(),
                              ],
                            ),
                          ),
                        TaskFormSectionCard(
                          compact: _compact,
                          title: 'targetValue',
                          child: CustomTextField(
                            label: 'targetValue',
                            hintText: 'targetValueExample',
                            controller: controller.targetValueController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        TaskFormSectionCard(
                          compact: _compact,
                          title: 'date',
                          child: Column(
                            children: [
                              _GoalDateField(
                                label: 'fromDate',
                                date: controller.selectedStartTime.value,
                                onTap: () => controller.pickStartDate(context),
                              ),
                              SizedBox(height: 8.h),
                              _GoalDateField(
                                label: 'date',
                                date: controller.selectedTime.value,
                                onTap: () => controller.pickDueDate(context),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 64.h),
                      ],
                    );
                  },
                ),
              ),
            ),
            const _GoalSaveBar(),
          ],
        ),
      ),
    );
  }
}

class _SelectedGoalProducts extends GetView<TargetSectionController> {
  const _SelectedGoalProducts();

  @override
  Widget build(BuildContext context) {
    if (controller.productsIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor6
              : AppColors.customGreyColor3,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.operationalPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9.r)),
            ),
            child: Row(
              children: [
                SizedBox(width: 34.w, child: Text('#'.tr)),
                Expanded(
                  child: Text(
                    'productName'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                SizedBox(width: 40.w),
              ],
            ),
          ),
          ...List.generate(
            controller.productsIds.length,
            (index) {
              final ProjectProductModel product = controller.productsIds[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34.w,
                      child: Text('${index + 1}'),
                    ),
                    Expanded(
                      child: Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        controller.productsIds.removeAt(index);
                        controller.update();
                      },
                      icon: Icon(
                        Icons.highlight_remove_rounded,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                        size: 23.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoalDateField extends StatelessWidget {
  const _GoalDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.operationalNavy.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 34.h,
              width: 34.h,
              decoration: BoxDecoration(
                color: AppColors.operationalPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: AppColors.operationalPurple,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.tr,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.customGreyColor5,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    showData(date.toIso8601String()),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.operationalNavy,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.customGreyColor5,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSaveBar extends GetView<TargetSectionController> {
  const _GoalSaveBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: controller.isAddLoading.value ? 58.h : 44.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: controller.isAddLoading.value
                  ? null
                  : () {
                      if (controller.formKey.currentState!.validate()) {
                        controller.addGoal(context);
                      }
                    },
              child: controller.isAddLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      (controller.isEdit.value ? 'editTarget' : 'addTarget').tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
