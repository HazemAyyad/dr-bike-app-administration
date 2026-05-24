import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

/// Date and time as two separate tappable fields (no inline wheel — avoids vibration).
class TaskDateTimeField extends StatelessWidget {
  const TaskDateTimeField({
    Key? key,
    required this.label,
    required this.isStart,
    this.compact = false,
  }) : super(key: key);

  final String label;
  final bool isStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateTaskController>();
    final dateRx = isStart ? controller.startDate : controller.endDate;
    final timeRx = isStart ? controller.startTime : controller.endTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.tr,
          style: TextStyle(
            fontSize: compact ? 11.sp : 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.operationalNavy,
          ),
        ),
        SizedBox(height: compact ? 4.h : 6.h),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  value: showData(dateRx.value),
                  compact: compact,
                  onTap: () => isStart
                      ? controller.pickStartDate(context)
                      : controller.pickEndDate(context),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_rounded,
                  value: _formatTime(timeRx.value),
                  compact: compact,
                  onTap: () => isStart
                      ? controller.pickStartTime(context)
                      : controller.pickEndTime(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.value,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(compact ? 8.r : 10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8.r : 10.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8.w : 10.w,
            vertical: compact ? 8.h : 10.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 8.r : 10.r),
            border: Border.all(color: AppColors.operationalCardBorder),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 16.sp : 18.sp,
                color: AppColors.operationalPurple,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11.sp : 13.sp,
                    color: AppColors.operationalNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
