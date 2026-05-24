import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../admin/employee_tasks/presentation/widgets/task_status_badge.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';

/// Employee task row — same operational look as admin [OperationalTaskCard].
class EmployeeOperationalTaskCard extends GetView<EmployeeDashbordController> {
  const EmployeeOperationalTaskCard({
    Key? key,
    required this.task,
    this.showCheckbox = true,
  }) : super(key: key);

  final Task task;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final isCompleted = task.status == 'completed';
    final blockedByOther = !task.canExecute;
    final progress = task.displayProgress;
    final showProgress = progress > 0 && !isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showCheckbox && !task.hasSubTasks) ...[
                Obx(() {
                  final busy = controller.completingTaskId.value == task.id;
                  if (busy) {
                    return Padding(
                      padding: EdgeInsets.all(6.w),
                      child: SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: AppColors.operationalPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    side: BorderSide(
                      color: AppColors.operationalPurple.withValues(alpha: 0.6),
                    ),
                    value: isCompleted,
                    onChanged: isCompleted || blockedByOther
                        ? null
                        : (v) {
                            if (v == true) {
                              _onMarkComplete(context);
                            }
                          },
                  ),
                );
                }),
                SizedBox(width: 4.w),
              ],
              if (showCheckbox && task.hasSubTasks) ...[
                Icon(
                  Icons.account_tree_outlined,
                  size: 20.sp,
                  color: AppColors.operationalPurple.withValues(alpha: 0.7),
                ),
                SizedBox(width: 4.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            maxLines: 2,
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
                        if (!isCompleted) _TimeLeftChip(endTime: task.endTime),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        TaskStatusBadge(status: task.status, compact: true),
                        if (task.isForcedToUploadImg) ...[
                          SizedBox(width: 6.w),
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
                          )
                        else
                          Text(
                            '${'dueDate'.tr}: ${showDateTime12(task.endTime)}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.customGreyColor5,
                            ),
                          ),
                      ],
                    ),
                    if (blockedByOther &&
                        task.completedByName != null &&
                        task.completedByName!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.customOrange3.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'taskCompletedBy'.tr.replaceAll(
                            '@name',
                            task.completedByName!,
                          ),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.customOrange3,
                          ),
                        ),
                      ),
                    ],
                    if (showProgress) ...[
                      SizedBox(height: 4.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 4.h,
                          color: AppColors.operationalPurple,
                          backgroundColor: AppColors.operationalSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails() {
    controller.openTaskDetails(task);
  }

  Future<void> _onMarkComplete(BuildContext context) async {
    if (!task.canExecute) {
      if (task.completedByName != null && task.completedByName!.isNotEmpty) {
        Get.snackbar(
          'note'.tr,
          'taskCompletedBy'.tr.replaceAll('@name', task.completedByName!),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }
    if (task.hasSubTasks) {
      Get.snackbar(
        'note'.tr,
        'completeSubtasksInDetails'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      _openDetails();
      return;
    }
    if (task.isForcedToUploadImg) {
      await controller.completeTaskWithCameraProof(context, task);
      return;
    }
    Get.dialog(
      Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'areYouSure'.tr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.operationalNavy,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      isLoading: controller.isTaskLoading,
                      text: 'yes'.tr,
                      onPressed: () {
                        Get.back();
                        controller.changeTaskToCompleted(
                          context: context,
                          isSubTask: false,
                          taskId: task.id,
                          task: task,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      color: AppColors.redColor,
                      text: 'cancel'.tr,
                      onPressed: Get.back,
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
}

class _TimeLeftChip extends StatelessWidget {
  const _TimeLeftChip({required this.endTime});

  final DateTime endTime;

  @override
  Widget build(BuildContext context) {
    final diff = endTime.difference(DateTime.now());
    final color = diff.inHours <= 0
        ? AppColors.redColor
        : diff.inHours <= 24
            ? AppColors.customOrange3
            : AppColors.customGreen1;
    String label;
    if (diff.inSeconds <= 0) {
      label = 'overdue'.tr;
    } else if (diff.inHours >= 1) {
      label = '${diff.inHours} ${'hours'.tr}';
    } else {
      label = '${diff.inMinutes.clamp(1, 59)} ${'minute'.tr}';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
