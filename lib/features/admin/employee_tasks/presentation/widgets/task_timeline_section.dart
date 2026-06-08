import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';

class TaskTimelineSection extends StatelessWidget {
  const TaskTimelineSection({
    Key? key,
    required this.events,
    this.compact = false,
  }) : super(key: key);

  final List<Map<String, dynamic>> events;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10.w : 16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(compact ? 12.r : 16.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'taskTimeline'.tr,
            style: theme.copyWith(
              fontSize: compact ? 12.sp : 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: compact ? 8.h : 16.h),
          ...events.map((e) => _TimelineTile(event: e, compact: compact)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, this.compact = false});

  final Map<String, dynamic> event;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = event['event_type']?.toString() ?? '';
    final createdAt = event['created_at']?.toString() ?? '';
    final notes = event['notes']?.toString();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8.h : 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 7.w : 10.w,
            height: compact ? 7.w : 10.w,
            margin: EdgeInsets.only(top: 3.h),
            decoration: const BoxDecoration(
              color: AppColors.operationalPurple,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 8.w : 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventLabel(type).tr,
                  style: TextStyle(
                    fontSize: compact ? 11.sp : 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.operationalNavy,
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    _formatCreatedAt(createdAt),
                    style: TextStyle(
                      fontSize: compact ? 9.5.sp : 11.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                if (notes != null && notes.isNotEmpty)
                  Text(
                    notes,
                    maxLines: compact ? 2 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: TextStyle(fontSize: compact ? 10.sp : 12.sp),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(String raw) {
    try {
      return showTimelineDateTime(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
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
      case 'task_reopened':
        return 'timelineReopened';
      case 'task_overdue':
        return 'timelineOverdue';
      case 'subtask_completed':
        return 'timelineSubtaskCompleted';
      default:
        return 'timelineCreated';
    }
  }
}
