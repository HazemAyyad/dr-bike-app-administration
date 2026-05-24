import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/utils/app_colors.dart';

/// Vertical wheel columns for hour / minute / AM-PM with haptic on change.
class HorizontalTimePickerSheet extends StatefulWidget {
  const HorizontalTimePickerSheet({
    Key? key,
    required this.initial,
    required this.onConfirm,
  }) : super(key: key);

  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onConfirm;

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initial,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        TimeOfDay result = initial;
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
                      'time'.tr,
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
                      onPressed: () => Navigator.pop(ctx, result),
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
              HorizontalTimePickerSheet(
                initial: initial,
                onConfirm: (t) => result = t,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  @override
  State<HorizontalTimePickerSheet> createState() =>
      _HorizontalTimePickerSheetState();
}

class _HorizontalTimePickerSheetState extends State<HorizontalTimePickerSheet> {
  late int _hour12;
  late int _minute;
  late bool _isAm;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _ampmCtrl;

  int _lastHourIdx = -1;
  int _lastMinuteIdx = -1;
  int _lastAmpmIdx = -1;

  @override
  void initState() {
    super.initState();
    final h = widget.initial.hour;
    _isAm = h < 12;
    final hh = h % 12;
    _hour12 = hh == 0 ? 12 : hh;
    _minute = widget.initial.minute;

    _hourCtrl = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _ampmCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);

    _lastHourIdx = _hour12 - 1;
    _lastMinuteIdx = _minute;
    _lastAmpmIdx = _isAm ? 0 : 1;

    _hourCtrl.addListener(() => _onHourWheel());
    _minuteCtrl.addListener(() => _onMinuteWheel());
    _ampmCtrl.addListener(() => _onAmpmWheel());
  }

  void _onHourWheel() {
    if (!_hourCtrl.hasClients) return;
    final idx = _hourCtrl.selectedItem;
    if (idx == _lastHourIdx) return;
    _lastHourIdx = idx;
    HapticHelper.selection();
    _hour12 = idx + 1;
    _emit();
  }

  void _onMinuteWheel() {
    if (!_minuteCtrl.hasClients) return;
    final idx = _minuteCtrl.selectedItem;
    if (idx == _lastMinuteIdx) return;
    _lastMinuteIdx = idx;
    HapticHelper.selection();
    _minute = idx;
    _emit();
  }

  void _onAmpmWheel() {
    if (!_ampmCtrl.hasClients) return;
    final idx = _ampmCtrl.selectedItem;
    if (idx == _lastAmpmIdx) return;
    _lastAmpmIdx = idx;
    HapticHelper.selection();
    _isAm = idx == 0;
    _emit();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _ampmCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _buildTime() {
    var h = _hour12 % 12;
    if (!_isAm) h += 12;
    if (_isAm && _hour12 == 12) h = 0;
    if (!_isAm && _hour12 == 12) h = 12;
    return TimeOfDay(hour: h, minute: _minute);
  }

  void _emit() => widget.onConfirm(_buildTime());

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.h,
      child: Row(
        children: [
          Expanded(
            child: _wheel(
              controller: _hourCtrl,
              items: List.generate(12, (i) => '${i + 1}'),
            ),
          ),
          Text(
            ':',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _wheel(
              controller: _minuteCtrl,
              items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
            ),
          ),
          Expanded(
            child: _wheel(
              controller: _ampmCtrl,
              items: ['morning'.tr, 'evening'.tr],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<String> items,
  }) {
    return ListWheelScrollView.useDelegate(
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
    );
  }
}
