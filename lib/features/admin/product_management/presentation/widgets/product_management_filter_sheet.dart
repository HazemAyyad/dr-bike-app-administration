import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/scroll_date_picker_sheet.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/product_management_controller.dart';

class ProductManagementFilterSheet extends StatefulWidget {
  const ProductManagementFilterSheet({Key? key}) : super(key: key);

  @override
  State<ProductManagementFilterSheet> createState() =>
      _ProductManagementFilterSheetState();
}

class _ProductManagementFilterSheetState
    extends State<ProductManagementFilterSheet> {
  final ProductManagementController controller =
      Get.find<ProductManagementController>();

  late int status;
  late int stage;
  DateTime? dateFrom;
  DateTime? dateTo;

  Color get _fieldFill => ThemeService.isDark.value
      ? AppColors.customGreyColor
      : AppColors.whiteColor2;

  @override
  void initState() {
    super.initState();
    status = controller.statusFilter.value;
    stage = controller.stageFilter.value;
    dateFrom = controller.filterDateFrom.value;
    dateTo = controller.filterDateTo.value;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await ScrollDatePickerSheet.show(
      context,
      initial: (isFrom ? dateFrom : dateTo) ?? DateTime.now(),
      title: isFrom ? 'from'.tr : 'to'.tr,
      firstYear: 2015,
      lastYear: DateTime.now().year + 1,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        dateFrom = picked;
      } else {
        dateTo = picked;
      }
    });
  }

  String _formatDate(DateTime date) => DateFormat('yyyy/MM/dd').format(date);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Container(
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        24.h + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'filters'.tr,
              textAlign: TextAlign.center,
              style: textTheme.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.whiteColor
                    : AppColors.secondaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            _dropdown<int>(
              label: 'developmentStatus'.tr,
              value: status,
              items: [
                DropdownMenuItem(
                  value: ProductManagementController.statusAll,
                  child: Text('all'.tr),
                ),
                DropdownMenuItem(
                  value: ProductManagementController.statusInDevelopment,
                  child: Text('productInDevelopment'.tr),
                ),
                DropdownMenuItem(
                  value: ProductManagementController.statusFinal,
                  child: Text('developmentFinal'.tr),
                ),
              ],
              onChanged: (v) => setState(() => status = v ?? status),
            ),
            SizedBox(height: 12.h),
            _dropdown<int>(
              label: 'filterByStage'.tr,
              value: stage,
              items: [
                DropdownMenuItem(value: 0, child: Text('all'.tr)),
                for (final step in [
                  ...controller.timeLineSteps,
                  ...controller.timeLineSteps2,
                ])
                  DropdownMenuItem(
                    value: step.keys.first,
                    child: Text(step.values.first.tr),
                  ),
              ],
              onChanged: (v) => setState(() => stage = v ?? stage),
            ),
            SizedBox(height: 12.h),
            Text(
              'developmentDateFilter'.tr,
              style: textTheme.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.customGreyColor5,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _dateButton(
                    label: dateFrom == null
                        ? 'from'.tr
                        : '${'from'.tr}: ${_formatDate(dateFrom!)}',
                    onTap: () => _pickDate(isFrom: true),
                    onClear: dateFrom == null
                        ? null
                        : () => setState(() => dateFrom = null),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _dateButton(
                    label: dateTo == null
                        ? 'to'.tr
                        : '${'to'.tr}: ${_formatDate(dateTo!)}',
                    onTap: () => _pickDate(isFrom: false),
                    onClear:
                        dateTo == null ? null : () => setState(() => dateTo = null),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: _FilterActionButton(
                    label: 'clearFilters'.tr,
                    isPrimary: false,
                    onPressed: () {
                      controller.clearFilters();
                      Get.back();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _FilterActionButton(
                    label: 'apply'.tr,
                    isPrimary: true,
                    onPressed: () {
                      controller.applyFilterSettings(
                        status: status,
                        stage: stage,
                        dateFrom: dateFrom,
                        dateTo: dateTo,
                      );
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.customGreyColor5,
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: _fieldFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          ),
        ),
      ],
    );
  }

  Widget _dateButton({
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Material(
      color: _fieldFill,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16.sp,
                color: AppColors.secondaryColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: AppColors.customGreyColor5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8.r);
    final height = 48.h;

    if (isPrimary) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.secondaryColor,
            foregroundColor: AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: const BorderSide(
                color: AppColors.secondaryColor,
                width: 1.5,
              ),
            ),
            textStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : const Color(0xFFD8D8D8),
          foregroundColor: AppColors.redColor,
          side: const BorderSide(
            color: AppColors.redColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
