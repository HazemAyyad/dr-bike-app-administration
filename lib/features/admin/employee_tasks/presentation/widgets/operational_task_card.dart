import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_task_model.dart';
import 'task_status_badge.dart';

/// Modern operational task card for list screens.
class OperationalTaskCard extends StatelessWidget {
  const OperationalTaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  final EmployeeTaskModel task;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    final isDark = ThemeService.isDark.value;
    final hoursLeft = task.endTime.difference(DateTime.now()).inHours;
    final imageUrl = task.employeePhoto ?? task.adminImg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(url: imageUrl),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.taskName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.whiteColor
                                : AppColors.operationalNavy,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          task.employeeName,
                          style: theme.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  TaskStatusBadge(status: task.status),
                  SizedBox(width: 8.w),
                  _Chip(
                    label: task.priority.tr,
                    color: _priorityColor(task.priority),
                  ),
                  if (task.points > 0) ...[
                    SizedBox(width: 8.w),
                    _Chip(
                      label: '${task.points} XP',
                      color: AppColors.operationalPurple,
                      icon: Icons.stars_rounded,
                    ),
                  ],
                  if (task.proofRequired) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 18.sp,
                      color: AppColors.operationalPurple,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: (task.progress.clamp(0, 100)) / 100,
                  minHeight: 6.h,
                  backgroundColor: AppColors.operationalSurface,
                  color: AppColors.operationalPurple,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'dueDate'.tr}: ${showData(task.endTime)}',
                    style: theme.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                  Text(
                    hoursLeft > 0 ? '$hoursLeft ${'hours'.tr}' : 'overdue'.tr,
                    style: theme.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: hoursLeft > 2
                          ? AppColors.customGreen1
                          : hoursLeft > 0
                              ? AppColors.customOrange3
                              : AppColors.redColor,
                    ),
                  ),
                ],
              ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24.r,
      backgroundColor: AppColors.operationalSurface,
      backgroundImage:
          url != null && url!.isNotEmpty ? CachedNetworkImageProvider(url!) : null,
      child: url == null || url!.isEmpty
          ? Icon(Icons.person, color: AppColors.operationalPurple, size: 24.sp)
          : null,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
