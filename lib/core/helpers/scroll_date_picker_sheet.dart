import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import 'haptic_helper.dart';

/// Date picker with vertical scroll wheels (year / month / day) — same UX as task time picker.
class ScrollDatePickerSheet extends StatefulWidget {
  const ScrollDatePickerSheet({
    Key? key,
    required this.initial,
    required this.onConfirm,
    this.firstYear = 2020,
    this.lastYear = 2100,
  }) : super(key: key);

  final DateTime initial;
  final ValueChanged<DateTime> onConfirm;
  final int firstYear;
  final int lastYear;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    int firstYear = 2020,
    int lastYear = 2100,
    String? title,
    DateTime? minimumDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        DateTime result = initial;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Row(
                  children: [
                    Text(
                      (title ?? 'due_date').tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.operationalNavy,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        if (minimumDate != null) {
                          final picked = DateTime(
                            result.year,
                            result.month,
                            result.day,
                          );
                          final min = DateTime(
                            minimumDate.year,
                            minimumDate.month,
                            minimumDate.day,
                          );
                          if (picked.isBefore(min)) {
                            result = min;
                          }
                        }
                        Navigator.pop(ctx, result);
                      },
                      child: Text(
                        'confirm'.tr,
                        style: const TextStyle(
                          color: AppColors.operationalPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ScrollDatePickerSheet(
                initial: initial,
                firstYear: firstYear,
                lastYear: lastYear,
                onConfirm: (d) => result = d,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  @override
  State<ScrollDatePickerSheet> createState() => _ScrollDatePickerSheetState();
}

class _ScrollDatePickerSheetState extends State<ScrollDatePickerSheet> {
  late int _year;
  late int _month;
  late int _day;

  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  int _lastYearIdx = -1;
  int _lastMonthIdx = -1;
  int _lastDayIdx = -1;

  int get _yearCount => widget.lastYear - widget.firstYear + 1;

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year.clamp(widget.firstYear, widget.lastYear);
    _month = widget.initial.month;
    _day = widget.initial.day.clamp(1, _daysInMonth(_year, _month));

    _yearCtrl =
        FixedExtentScrollController(initialItem: _year - widget.firstYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);

    _lastYearIdx = _year - widget.firstYear;
    _lastMonthIdx = _month - 1;
    _lastDayIdx = _day - 1;

    _yearCtrl.addListener(_onYearWheel);
    _monthCtrl.addListener(_onMonthWheel);
    _dayCtrl.addListener(_onDayWheel);
  }

  void _onYearWheel() {
    if (!_yearCtrl.hasClients) return;
    final idx = _yearCtrl.selectedItem;
    if (idx == _lastYearIdx) return;
    _lastYearIdx = idx;
    HapticHelper.selection();
    _year = widget.firstYear + idx;
    _clampDayAndSyncWheel();
    _emit();
  }

  void _onMonthWheel() {
    if (!_monthCtrl.hasClients) return;
    final idx = _monthCtrl.selectedItem;
    if (idx == _lastMonthIdx) return;
    _lastMonthIdx = idx;
    HapticHelper.selection();
    _month = idx + 1;
    _clampDayAndSyncWheel();
    _emit();
  }

  void _onDayWheel() {
    if (!_dayCtrl.hasClients) return;
    final idx = _dayCtrl.selectedItem;
    if (idx == _lastDayIdx) return;
    _lastDayIdx = idx;
    HapticHelper.selection();
    _day = idx + 1;
    _emit();
  }

  void _clampDayAndSyncWheel() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      _lastDayIdx = _day - 1;
      if (_dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(_day - 1);
      }
    }
    setState(() {});
  }

  void _emit() {
    widget.onConfirm(DateTime(_year, _month, _day));
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayCount = _daysInMonth(_year, _month);
    final locale = Get.locale?.toString() ?? 'ar';

    return SizedBox(
      height: 160.h,
      child: Row(
        children: [
          Expanded(
            child: _wheel(
              controller: _yearCtrl,
              label: 'year'.tr,
              items: List.generate(
                _yearCount,
                (i) => '${widget.firstYear + i}',
              ),
            ),
          ),
          Expanded(
            child: _wheel(
              controller: _monthCtrl,
              label: 'month'.tr,
              items: List.generate(
                12,
                (i) => DateFormat('MMM', locale).format(DateTime(2000, i + 1)),
              ),
            ),
          ),
          Expanded(
            child: _wheel(
              controller: _dayCtrl,
              label: 'day'.tr,
              items: List.generate(dayCount, (i) => '${i + 1}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    Key? key,
    required FixedExtentScrollController controller,
    required String label,
    required List<String> items,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            key: key,
            controller: controller,
            itemExtent: 36.h,
            diameterRatio: 1.4,
            perspective: 0.003,
            physics: const FixedExtentScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                return Center(
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.operationalNavy,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
