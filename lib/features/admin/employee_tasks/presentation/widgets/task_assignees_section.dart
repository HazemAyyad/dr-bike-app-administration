import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../domain/entities/task_assignee_info.dart';
import 'task_operational_shared.dart';

/// Shows employees assigned to a shared task (avatars + names).
class TaskAssigneesSection extends StatelessWidget {
  const TaskAssigneesSection({
    Key? key,
    required this.assignees,
    this.compact = false,
  }) : super(key: key);

  final List<TaskAssigneeInfo> assignees;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (assignees.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskSectionTitle('taskAssignedTo', compact: compact),
        TaskOpCard(
          compact: compact,
          child: SizedBox(
            height: compact ? 88.h : 100.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: assignees.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 10.w : 12.w),
              itemBuilder: (context, index) {
                final a = assignees[index];
                return _AssigneeChip(assignee: a, compact: compact);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.assignee, required this.compact});

  final TaskAssigneeInfo assignee;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 22.r : 26.r;
    final tileWidth = compact ? 64.w : 76.w;

    return SizedBox(
      width: tileWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor:
                AppColors.operationalPurple.withValues(alpha: 0.12),
            backgroundImage: assignee.photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(assignee.photoUrl)
                : null,
            child: assignee.photoUrl.isEmpty
                ? Icon(
                    Icons.person,
                    color: AppColors.operationalPurple,
                    size: compact ? 20.sp : 24.sp,
                  )
                : null,
          ),
          SizedBox(height: 4.h),
          Text(
            assignee.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 9.sp : 10.sp,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: AppColors.operationalNavy,
            ),
          ),
        ],
      ),
    );
  }
}
