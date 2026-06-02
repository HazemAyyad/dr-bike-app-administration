import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_tasks/presentation/widgets/task_operational_shared.dart';
import '../controllers/create_task_controller.dart';

/// Compact recurrence settings (RTL Arabic, type-specific duration units).
class TaskRecurrenceScreen extends GetView<CreateTaskController> {
  const TaskRecurrenceScreen({Key? key}) : super(key: key);

  static const weekdays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  static const _types = ['noRepeat', 'daily', 'weekly', 'monthly', 'yearly'];
  static const _ordinals = ['first', 'second', 'third', 'fourth', 'last'];
  static const _monthNames = [
    'monthJan',
    'monthFeb',
    'monthMar',
    'monthApr',
    'monthMay',
    'monthJun',
    'monthJul',
    'monthAug',
    'monthSep',
    'monthOct',
    'monthNov',
    'monthDec',
  ];

  @override
  Widget build(BuildContext context) {
    TaskNavDebug.log(
      'TaskRecurrenceScreen.build',
      AppRoutes.TASKRECURRENCE,
      screen: 'TaskRecurrenceScreen',
    );

    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: const CustomAppBar(title: 'recurrenceSettings'),
      body: Obx(() {
        if (controller.recurrenceSummary.value.isEmpty) {
          controller.updateRecurrenceSummary();
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 88.h),
          children: [
            const TaskSectionTitle('repeatPattern', compact: true),
            TaskOpCard(
              compact: true,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Row(
                    children: _types.take(3).map(_typeChip).toList(),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: _types.skip(3).map(_typeChip).toList(),
                  ),
                ],
              ),
            ),
            if (controller.selectedDays.value == 'weekly') ...[
              SizedBox(height: 6.h),
              const TaskSectionTitle('selectWeekdays', compact: true),
              TaskOpCard(
                compact: true,
                margin: EdgeInsets.zero,
                child: _WeekdayDragRow(
                  weekdays: weekdays,
                  selected: controller.selectedDaysList.toList(),
                  onToggle: controller.toggleDay,
                  onDragSelect: controller.addWeekdayWhileDragging,
                ),
              ),
            ],
            if (controller.selectedDays.value == 'monthly') ...[
              SizedBox(height: 6.h),
              const TaskSectionTitle('monthlyRepeatMode', compact: true),
              TaskOpCard(
                compact: true,
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _monthlyModeChip('day_of_month', 'monthlyOnDayOfMonth'),
                    if (controller.monthlyMode.value == 'day_of_month')
                      _dayOfMonthPicker(
                        value: controller.monthDay.value,
                        onChanged: (d) {
                          controller.monthDay.value = d;
                          controller.updateRecurrenceSummary();
                        },
                      ),
                    _monthlyModeChip('nth_weekday', 'monthlyOnNthWeekday'),
                    if (controller.monthlyMode.value == 'nth_weekday') ...[
                      _ordinalRow(),
                      _weekdayNameRow(forMonthly: true),
                    ],
                    _monthlyModeChip('custom_dates', 'monthlyCustomDates'),
                    if (controller.monthlyMode.value == 'custom_dates')
                      _monthDaysGrid(),
                  ],
                ),
              ),
            ],
            if (controller.selectedDays.value == 'yearly') ...[
              SizedBox(height: 6.h),
              const TaskSectionTitle('yearlyRepeatOn', compact: true),
              TaskOpCard(
                compact: true,
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _yearMonthDayPickers(),
                  ],
                ),
              ),
            ],
            if (controller.showRecurrenceDuration) ...[
              SizedBox(height: 6.h),
              const TaskSectionTitle('duration', compact: true),
              TaskOpCard(
                compact: true,
                margin: EdgeInsets.zero,
                child: _DurationSection(
                  controller: controller,
                  onPickEndDate: () => _pickRecurrenceEndDate(context),
                ),
              ),
            ],
            SizedBox(height: 6.h),
            const TaskSectionTitle('summary', compact: true),
            TaskOpCard(
              compact: true,
              margin: EdgeInsets.zero,
              child: Text(
                controller.recurrenceSummary.value.isEmpty
                    ? 'recurrenceNoRepeat'.tr
                    : controller.recurrenceSummary.value,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.45,
                  color: AppColors.operationalNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: TaskStickyCta(
        label: 'saveRecurrenceSettings',
        backgroundColor: AppColors.operationalPurple,
        onPressed: () {
          controller.updateRecurrenceSummary();
          Get.back(result: true);
        },
      ),
    );
  }

  Future<void> _pickRecurrenceEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.recurrenceEndDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: Get.locale,
    );
    if (picked != null) {
      controller.recurrenceEndDate.value = picked;
      controller.updateRecurrenceSummary();
    }
  }

  Widget _typeChip(String type) {
    final selected = controller.selectedDays.value == type;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: GestureDetector(
          onTap: () => controller.setRecurrenceType(type),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 9.h),
            decoration: BoxDecoration(
              color:
                  selected ? AppColors.operationalPurple : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: selected
                    ? AppColors.operationalPurple
                    : AppColors.operationalCardBorder,
              ),
            ),
            child: Text(
              type.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.operationalNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthlyModeChip(String mode, String labelKey) {
    final selected = controller.monthlyMode.value == mode;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: () {
          controller.monthlyMode.value = mode;
          controller.updateRecurrenceSummary();
        },
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18.sp,
              color: selected
                  ? AppColors.operationalPurple
                  : AppColors.customGreyColor5,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                labelKey.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.operationalNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayOfMonthPicker({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
      child: Row(
        children: [
          Text(
            'recurrenceDayOfMonth'.tr,
            style:
                TextStyle(fontSize: 11.sp, color: AppColors.customGreyColor5),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.remove_circle_outline, size: 22.sp),
            color: AppColors.operationalPurple,
            onPressed: () => onChanged((value - 1).clamp(1, 31)),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.add_circle_outline, size: 22.sp),
            color: AppColors.operationalPurple,
            onPressed: () => onChanged((value + 1).clamp(1, 31)),
          ),
        ],
      ),
    );
  }

  Widget _ordinalRow() {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        children: _ordinals.map((o) {
          final sel = controller.weekdayOrdinal.value == o;
          return _miniChip(
            label: o.tr,
            selected: sel,
            onTap: () {
              controller.weekdayOrdinal.value = o;
              controller.updateRecurrenceSummary();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _weekdayNameRow({required bool forMonthly}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        children: TaskRecurrenceScreen.weekdays.map((d) {
          final sel = forMonthly ? controller.monthlyWeekday.value == d : false;
          return _miniChip(
            label: _weekdayShort(d),
            selected: sel,
            onTap: () {
              controller.monthlyWeekday.value = d;
              controller.updateRecurrenceSummary();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _monthDaysGrid() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        children: List.generate(31, (i) {
          final day = i + 1;
          final sel = controller.customMonthDays.contains(day);
          return GestureDetector(
            onTap: () => controller.toggleMonthDay(day),
            child: Container(
              width: 32.w,
              height: 32.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.operationalPurple
                    : AppColors.operationalSurface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: sel
                      ? AppColors.operationalPurple
                      : AppColors.operationalCardBorder,
                ),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : AppColors.operationalNavy,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _yearMonthDayPickers() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          initialValue: controller.yearlyMonth.value,
          decoration: _dropdownDecoration('yearlyMonth'.tr),
          items: List.generate(12, (i) {
            final m = i + 1;
            return DropdownMenuItem(
              value: m,
              child: Text(_monthNames[i].tr, style: TextStyle(fontSize: 12.sp)),
            );
          }),
          onChanged: (v) {
            if (v != null) {
              controller.yearlyMonth.value = v;
              controller.updateRecurrenceSummary();
            }
          },
        ),
        SizedBox(height: 8.h),
        _dayOfMonthPicker(
          value: controller.yearlyDay.value,
          onChanged: (d) {
            controller.yearlyDay.value = d;
            controller.updateRecurrenceSummary();
          },
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 11.sp),
      filled: true,
      fillColor: AppColors.operationalSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _miniChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.operationalPurple
              : AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected
                ? AppColors.operationalPurple
                : AppColors.operationalCardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.operationalNavy,
          ),
        ),
      ),
    );
  }

  String _weekdayShort(String day) {
    const map = {
      'saturday': 'س',
      'sunday': 'ح',
      'monday': 'ن',
      'tuesday': 'ث',
      'wednesday': 'ر',
      'thursday': 'خ',
      'friday': 'ج',
    };
    return map[day] ?? day.substring(0, 1);
  }
}

class _WeekdayDragRow extends StatelessWidget {
  const _WeekdayDragRow({
    required this.weekdays,
    required this.selected,
    required this.onToggle,
    required this.onDragSelect,
  });

  final List<String> weekdays;
  final List<String> selected;
  final void Function(String) onToggle;
  final void Function(String) onDragSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (d) =>
              _selectAt(context, d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _selectAt(context, d.localPosition.dx, constraints.maxWidth),
          child: Row(
            children: weekdays.map((day) {
              final isOn = selected.contains(day);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticHelper.selection();
                    onToggle(day);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    height: 36.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOn
                          ? AppColors.operationalPurple
                          : AppColors.whiteColor,
                      border: Border.all(
                        color: isOn
                            ? AppColors.operationalPurple
                            : AppColors.operationalCardBorder,
                      ),
                    ),
                    child: Text(
                      _short(day),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isOn ? Colors.white : AppColors.operationalNavy,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _selectAt(BuildContext context, double dx, double width) {
    if (width <= 0) return;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final adjustedDx = isRtl ? width - dx : dx;
    final index = (adjustedDx / width * weekdays.length)
        .floor()
        .clamp(0, weekdays.length - 1);
    onDragSelect(weekdays[index]);
  }

  String _short(String day) {
    const map = {
      'saturday': 'س',
      'sunday': 'ح',
      'monday': 'ن',
      'tuesday': 'ث',
      'wednesday': 'ر',
      'thursday': 'خ',
      'friday': 'ج',
    };
    return map[day] ?? day.substring(0, 1);
  }
}

class _DurationSection extends StatelessWidget {
  const _DurationSection({
    required this.controller,
    required this.onPickEndDate,
  });

  final CreateTaskController controller;
  final VoidCallback onPickEndDate;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          _tile('forever', 'forever'),
          _tile('end_after_count', controller.durationCountLabelKey),
          if (controller.durationType.value == 'end_after_count')
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Obx(
                () => Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.remove_circle_outline, size: 24.sp),
                      color: AppColors.operationalPurple,
                      onPressed: () {
                        if (controller.endAfterCount.value > 1) {
                          controller.endAfterCount.value--;
                          controller.updateRecurrenceSummary();
                        }
                      },
                    ),
                    Text(
                      '${controller.endAfterCount.value}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.operationalNavy,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.add_circle_outline, size: 24.sp),
                      color: AppColors.operationalPurple,
                      onPressed: () {
                        controller.endAfterCount.value++;
                        controller.updateRecurrenceSummary();
                      },
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        controller.durationCountUnit,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.operationalPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _tile('end_date', 'endAtDate'),
          if (controller.durationType.value == 'end_date')
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                showData(controller.recurrenceEndDate.value),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.operationalNavy,
                ),
              ),
              trailing: Icon(
                Icons.calendar_today_outlined,
                size: 18.sp,
                color: AppColors.operationalPurple,
              ),
              onTap: onPickEndDate,
            ),
        ],
      ),
    );
  }

  Widget _tile(String value, String labelKey) {
    final selected = controller.durationType.value == value;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(
        labelKey.tr,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.operationalNavy,
        ),
      ),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: 20.sp,
        color:
            selected ? AppColors.operationalPurple : AppColors.customGreyColor5,
      ),
      onTap: () {
        controller.durationType.value = value;
        if (value == 'end_after_count') {
          controller.endAfterCount.value = 1;
        }
        controller.updateRecurrenceSummary();
      },
    );
  }
}
