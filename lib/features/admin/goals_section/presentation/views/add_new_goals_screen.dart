import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_calendar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../create_tasks/presentation/widgets/task_form_section_card.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../../../projects/presentation/widgets/product_details_widgets/sup_text_and_dis.dart';
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
                              CustomCalendar(
                                label: 'fromDate',
                                selectedDay: controller.selectedStartTime,
                                onTap: () {
                                  controller.startTimeController.value =
                                      !controller.startTimeController.value;
                                },
                                isVisible: controller.startTimeController,
                              ),
                              SizedBox(height: 8.h),
                              CustomCalendar(
                                label: 'date',
                                selectedDay: controller.selectedTime,
                                onTap: () {
                                  controller.targetTimeController.value =
                                      !controller.targetTimeController.value;
                                },
                                isVisible: controller.targetTimeController,
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

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 28.w),
          height: 1.h,
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor6
              : AppColors.customGreyColor3,
        ),
        ...List.generate(
          controller.productsIds.length,
          (index) {
            final ProjectProductModel product = controller.productsIds[index];
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SupTextAndDis(
                    showLine: false,
                    title: '${'productName'.tr} ${index + 1}',
                    discription: product.productName,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.productsIds.removeAt(index);
                    controller.update();
                  },
                  icon: Icon(
                    Icons.highlight_remove_rounded,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                    size: 25.sp,
                  ),
                ),
              ],
            );
          },
        ),
      ],
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
