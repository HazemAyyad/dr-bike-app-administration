import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

class TaskTimelineSection extends StatelessWidget {
  const TaskTimelineSection({Key? key, required this.events}) : super(key: key);

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'taskTimeline'.tr,
            style: theme.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 16.h),
          ...events.map((e) => _TimelineTile(event: e)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final type = event['event_type']?.toString() ?? '';
    final createdAt = event['created_at']?.toString() ?? '';
    final notes = event['notes']?.toString();

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            margin: EdgeInsets.only(top: 4.h),
            decoration: const BoxDecoration(
              color: AppColors.operationalPurple,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventLabel(type).tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.operationalNavy,
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    createdAt,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                if (notes != null && notes.isNotEmpty)
                  Text(
                    notes,
                    style: TextStyle(fontSize: 12.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _eventLabel(String type) {
    switch (type) {
      case 'task_started':
        return 'timelineStarted';
      case 'proof_uploaded':
        return 'timelineProofUploaded';
      case 'task_submitted':
        return 'timelineSubmitted';
      case 'task_approved':
        return 'timelineApproved';
      case 'task_rejected':
        return 'timelineRejected';
      case 'task_overdue':
        return 'timelineOverdue';
      case 'subtask_completed':
        return 'timelineSubtaskCompleted';
      default:
        return 'timelineCreated';
    }
  }
}
