import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

/// Task reminder: when + channel (push / email), or none.
class TaskReminderSection extends GetView<CreateTaskController> {
  const TaskReminderSection({Key? key, this.compact = false}) : super(key: key);

  final bool compact;

  static const _whenOptions = [
    'none',
    'at_time',
    'before_10m',
    'before_1h',
    'before_1d',
  ];

  static const _whenLabels = {
    'none': 'reminderNone',
    'at_time': 'reminderAtTime',
    'before_10m': 'reminderBefore10m',
    'before_1h': 'reminderBefore1h',
    'before_1d': 'reminderBefore1d',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final hasReminder = controller.reminderWhen.value != 'none';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'reminderWhen'.tr,
              style: TextStyle(
                fontSize: compact ? 10.sp : 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.customGreyColor5,
              ),
            ),
            SizedBox(height: 4.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: _whenOptions.map((w) {
                final sel = controller.reminderWhen.value == w;
                return _chip(
                  label: _whenLabels[w]!.tr,
                  selected: sel,
                  onTap: () {
                    HapticHelper.selection();
                    controller.reminderWhen.value = w;
                    controller.updateRecurrenceSummary();
                  },
                );
              }).toList(),
            ),
            if (hasReminder) ...[
              SizedBox(height: 8.h),
              Text(
                'reminderChannel'.tr,
                style: TextStyle(
                  fontSize: compact ? 10.sp : 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.customGreyColor5,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Expanded(
                    child: _chip(
                      label: 'reminderPush'.tr,
                      selected: controller.reminderChannel.value == 'push',
                      onTap: () {
                    HapticHelper.selection();
                    controller.reminderChannel.value = 'push';
                        controller.updateRecurrenceSummary();
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _chip(
                      label: 'reminderEmail'.tr,
                      selected: controller.reminderChannel.value == 'email',
                      onTap: () {
                    HapticHelper.selection();
                    controller.reminderChannel.value = 'email';
                        controller.updateRecurrenceSummary();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8.w : 10.w,
          vertical: compact ? 6.h : 8.h,
        ),
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
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 10.sp : 11.sp,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.operationalNavy,
          ),
        ),
      ),
    );
  }
}
