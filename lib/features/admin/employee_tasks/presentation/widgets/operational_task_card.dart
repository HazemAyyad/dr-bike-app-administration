import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/task_source_debug_badge.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_task_model.dart';
import 'task_status_badge.dart';

/// Compact operational task card — fits more tasks per screen.
class OperationalTaskCard extends StatelessWidget {
  const OperationalTaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.trailing,
    this.searchQuery = '',
  }) : super(key: key);

  final EmployeeTaskModel task;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final imageUrl = task.employeePhoto ?? task.adminImg;
    final progress = task.progress.clamp(0, 100);
    final showProgress = progress > 0 && task.status != 'completed';
    final matchedSubtasks = task.matchingSubtaskNames(searchQuery);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(url: imageUrl),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.taskName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: isDark
                                      ? AppColors.whiteColor
                                      : AppColors.operationalNavy,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            _TimeLeftLabel(endTime: task.endTime),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          task.isShared
                              ? '${'sharedTask'.tr}: ${task.displayAssigneeLabel} · ${'dueDate'.tr}: ${showDateTime12(task.endTime)}'
                              : '${task.displayAssigneeLabel} · ${'dueDate'.tr}: ${showDateTime12(task.endTime)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            height: 1.2,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        TaskSourceDebugBadge(
                          label: TaskSourceDebug.label(
                            source: task.source,
                            taskId: task.taskId,
                            occurrenceId: task.occurrenceId,
                            templateId: task.templateId,
                            parentId: task.parentId,
                          ),
                        ),
                        if (matchedSubtasks.isNotEmpty) ...[
                          SizedBox(height: 3.h),
                          _SubtaskMatchLabel(names: matchedSubtasks),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: 4.w),
                    trailing!,
                  ],
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  TaskStatusBadge(status: task.status, compact: true),
                  if (task.isShared) ...[
                    SizedBox(width: 4.w),
                    _MiniChip(
                      label: 'sharedTask'.tr,
                      color: AppColors.customGreen1,
                      icon: Icons.people_outline,
                    ),
                  ],
                  if (task.isRepeatedCopy) ...[
                    SizedBox(width: 4.w),
                    _MiniChip(
                      label: 'taskRepeatedCopy'.tr,
                      color: AppColors.customOrange3,
                      icon: Icons.copy_all_outlined,
                    ),
                  ],
                  SizedBox(width: 4.w),
                  _MiniChip(
                    label: task.priority.tr,
                    color: _priorityColor(task.priority),
                  ),
                  if (task.points > 0) ...[
                    SizedBox(width: 4.w),
                    _MiniChip(
                      label: '${task.points}',
                      color: AppColors.operationalPurple,
                      icon: Icons.bolt,
                    ),
                  ],
                  if (task.proofRequired) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 14.sp,
                      color: AppColors.operationalPurple,
                    ),
                  ],
                  const Spacer(),
                  if (showProgress)
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.operationalPurple,
                      ),
                    ),
                ],
              ),
              if (showProgress) ...[
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 3.h,
                    backgroundColor: AppColors.operationalSurface,
                    color: AppColors.operationalPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.redColor;
      case 'low':
        return AppColors.customGreyColor5;
      default:
        return AppColors.operationalPurple;
    }
  }
}

class _SubtaskMatchLabel extends StatelessWidget {
  const _SubtaskMatchLabel({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(3).join(' · ');
    final extra = names.length > 3 ? ' +${names.length - 3}' : '';
    return Row(
      children: [
        Icon(
          Icons.subdirectory_arrow_right,
          size: 12.sp,
          color: AppColors.operationalPurple,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            '${'subTasks'.tr}: $shown$extra',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.operationalPurple,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeLeftLabel extends StatelessWidget {
  const _TimeLeftLabel({required this.endTime});

  final DateTime endTime;

  @override
  Widget build(BuildContext context) {
    final label = _formatTimeLeft(endTime);
    final color = _colorFor(endTime);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _formatTimeLeft(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 'overdue'.tr;
    if (diff.inDays >= 1) return '${diff.inDays} ${'days'.tr}';
    if (diff.inHours >= 1) return '${diff.inHours} ${'hours'.tr}';
    final mins = diff.inMinutes.clamp(1, 59);
    return '$mins ${'minute'.tr}';
  }

  static Color _colorFor(DateTime end) {
    final hours = end.difference(DateTime.now()).inHours;
    if (hours <= 0) return AppColors.redColor;
    if (hours <= 24) return AppColors.customOrange3;
    return AppColors.customGreen1;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: AppColors.operationalSurface,
      backgroundImage: url != null && url!.isNotEmpty
          ? CachedNetworkImageProvider(url!)
          : null,
      child: url == null || url!.isEmpty
          ? Icon(Icons.person, color: AppColors.operationalPurple, size: 16.sp)
          : null,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 2.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
