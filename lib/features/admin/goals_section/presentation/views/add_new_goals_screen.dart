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
import '../controllers/target_section_controller.dart';
import '../widgets/goal_products_picker_sheet.dart';
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
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
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
                                      'detailed';
                                  controller.update();
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (context.mounted) {
                                      _showGoalFollowUpSheet(context);
                                    }
                                  });
                                },
                                isEnabled: true,
                              ),
                            ],
                          ),
                        ),
                        if (controller.targetTypeController.text.isNotEmpty)
                          const TaskFormSectionCard(
                            compact: _compact,
                            title: 'followUp',
                            child: _GoalFollowUpSummary(),
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

class _GoalFollowUpSummary extends GetView<TargetSectionController> {
  const _GoalFollowUpSummary();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TargetSectionController>(
      builder: (controller) {
        final items = _summaryItems(controller);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  side: const BorderSide(color: AppColors.operationalPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () => _showGoalFollowUpSheet(context),
                icon: Icon(
                  items.isEmpty ? Icons.tune_rounded : Icons.edit_note_rounded,
                ),
                label: Text(
                  items.isEmpty ? 'options'.tr : '${'edit'.tr} ${'options'.tr}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.operationalPurple,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            if (items.isEmpty) ...[
              SizedBox(height: 10.h),
              const _EmptySummaryHint(
                text: 'اختر التفاصيل المرتبطة بصيغة الهدف',
              ),
            ] else ...[
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: items
                    .map((item) => _SummaryChip(
                          title: item.title,
                          value: item.value,
                        ))
                    .toList(),
              ),
            ],
            if (controller.supportsTotalMode && !controller.isDetailedMode) ...[
              SizedBox(height: 10.h),
              const _EmptySummaryHint(
                text:
                    'تم اختيار الإجمالي، لذلك لا توجد منتجات أو خيارات تفصيلية',
              ),
            ],
            if (controller.isDetailedMode &&
                controller.formController.text.isEmpty) ...[
              SizedBox(height: 10.h),
              const _EmptySummaryHint(text: 'اختر نوع الخيارات التفصيلية'),
            ],
            if (controller.formController.text == 'products' &&
                controller.productsIds.isEmpty) ...[
              SizedBox(height: 10.h),
              const _EmptySummaryHint(text: 'لم يتم اختيار منتجات بعد'),
            ],
            GoalSelectedProductsTable(
              key: ValueKey(
                controller.productsIds
                    .map((product) => product.productId)
                    .join(','),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_SummaryItem> _summaryItems(TargetSectionController controller) {
    final items = <_SummaryItem>[];
    if (controller.calculationModeController.text.isNotEmpty) {
      items.add(_SummaryItem(
        'calculationMode',
        controller.calculationModeController.text.tr,
      ));
    }
    if (controller.formController.text.isNotEmpty) {
      items.add(_SummaryItem('options', controller.formController.text.tr));
    }
    final employee = controller.employeeList.firstWhereOrNull(
      (e) => e.id.toString() == controller.employeeIdController.text,
    );
    if (employee != null) {
      items.add(_SummaryItem('employeeName', employee.employeeName));
    }
    final box = controller.shownBoxes.firstWhereOrNull(
      (e) => e.boxId.toString() == controller.boxIdController.text,
    );
    if (box != null) {
      items.add(_SummaryItem('boxName', box.boxName));
    }
    final storeSection = controller.storeSections.firstWhereOrNull(
      (e) => e.id.toString() == controller.storeSectionIdController.text,
    );
    if (storeSection != null) {
      items.add(_SummaryItem('store_sections', storeSection.name));
    }
    final personName = controller.isSeller.value == false
        ? controller.allCustomersList
            .firstWhereOrNull(
              (e) =>
                  e.id.toString() ==
                  controller.customerAndSellerIdController.text,
            )
            ?.name
        : controller.allSellersList
            .firstWhereOrNull(
              (e) =>
                  e.id.toString() ==
                  controller.customerAndSellerIdController.text,
            )
            ?.name;
    if ((personName ?? '').isNotEmpty) {
      items.add(_SummaryItem(
        controller.isSeller.value == false ? 'customerName' : 'sellerName',
        personName!,
      ));
    }
    if (controller.productsIds.isNotEmpty) {
      final productNames = controller.productsIds
          .map((product) => product.productName)
          .where((name) => name.trim().isNotEmpty)
          .toList();
      final visibleNames = productNames.take(2).join('، ');
      final extraCount = productNames.length - 2;
      items.add(_SummaryItem(
        'selectedProducts',
        visibleNames.isEmpty
            ? '${controller.productsIds.length}'
            : extraCount > 0
                ? '$visibleNames +$extraCount'
                : visibleNames,
      ));
    }
    return items;
  }
}

void _showGoalFollowUpSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GoalFollowUpSheet(),
  );
}

class _SummaryItem {
  const _SummaryItem(this.title, this.value);

  final String title;
  final String value;
}

class _GoalFollowUpSheet extends GetView<TargetSectionController> {
  const _GoalFollowUpSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'followUp'.tr,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: ThemeService.isDark.value
                                ? Colors.white
                                : AppColors.operationalNavy,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: GetBuilder<TargetSectionController>(
                  builder: (_) => Column(
                    children: [
                      if (controller.supportsTotalMode) ...[
                        CustomDropdownField(
                          isRequired: true,
                          label: 'calculationMode',
                          hint: 'calculationMode',
                          value:
                              controller.calculationModeController.text.isEmpty
                                  ? null
                                  : controller.calculationModeController.text,
                          items: controller.calculationModes,
                          onChanged: (value) {
                            controller.calculationModeController.text = value!;
                            if (value == 'total') {
                              controller.formController.clear();
                              controller.mainCategoriesIdController.clear();
                              controller.subCategoriesIdController.clear();
                              controller.storeSectionIdController.clear();
                              controller.productIdController.clear();
                              controller.productsIds.clear();
                              controller.customerAndSellerIdController.clear();
                            }
                            controller.update();
                          },
                        ),
                        SizedBox(height: 10.h),
                      ],
                      const TargetTypeFormatWidget(),
                      if (controller.isDetailedMode) ...[
                        const OptionsWidget(),
                      ] else ...[
                        const _EmptySummaryHint(
                          text:
                              'الإجمالي يحسب كل البيانات بدون تحديد منتجات أو تصنيفات',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.operationalPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () {
                    controller.update();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'done'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158.w,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.operationalPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.customGreyColor5,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptySummaryHint extends StatelessWidget {
  const _EmptySummaryHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: AppColors.operationalNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w700,
            ),
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
