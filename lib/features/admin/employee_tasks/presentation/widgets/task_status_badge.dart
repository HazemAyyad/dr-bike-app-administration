import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({
    Key? key,
    required this.status,
    this.compact = false,
  }) : super(key: key);

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(status);
    final label = _resolveLabel(status);

    return Container(
      padding: compact
          ? EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h)
          : EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6.r : 20.r),
        border: Border.all(
          color: color.withValues(alpha: compact ? 0.25 : 0.35),
        ),
      ),
      child: Text(
        label.tr,
        style: TextStyle(
          fontSize: compact ? 9.sp : 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _resolveColor(String raw) {
    switch (raw) {
      case 'in_progress':
      case 'ongoing':
        return AppColors.operationalPurple;
      case 'waiting_review':
        return AppColors.customOrange3;
      case 'completed':
        return AppColors.customGreen1;
      case 'overdue':
        return AppColors.redColor;
      case 'canceled':
        return AppColors.customGreyColor5;
      default:
        return AppColors.operationalNavy;
    }
  }

  String _resolveLabel(String raw) {
    switch (raw) {
      case 'in_progress':
      case 'ongoing':
        return 'taskStatusInProgress';
      case 'waiting_review':
        return 'taskStatusWaitingReview';
      case 'completed':
        return 'taskStatusCompleted';
      case 'overdue':
        return 'taskStatusOverdue';
      case 'canceled':
        return 'taskStatusCanceled';
      default:
        return 'taskStatusPending';
    }
  }
}
