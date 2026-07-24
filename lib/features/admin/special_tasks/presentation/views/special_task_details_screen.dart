import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_section/domain/entities/employee_entity.dart';
import '../../../employee_tasks/presentation/widgets/audio_player.dart';
import '../../../employee_tasks/presentation/widgets/task_media_thumbnail_row.dart';
import '../../../employee_tasks/presentation/widgets/task_operational_shared.dart';
import '../../../employee_tasks/presentation/widgets/task_status_badge.dart';
import '../../domain/entities/special_task_details_entities.dart';
import '../controllers/special_tasks_controller.dart';

class SpecialTaskDetailsScreen extends GetView<SpecialTasksController> {
  const SpecialTaskDetailsScreen({Key? key}) : super(key: key);

  static const _compact = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: AppBar(
        backgroundColor: AppColors.operationalSurface,
        elevation: 0,
        toolbarHeight: 48.h,
        title: Text(
          'privateTaskDetails'.tr,
          style: TextStyle(
            color: AppColors.operationalNavy,
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
          ),
        ),
        actions: [
          if (userType == 'admin')
            IconButton(
              tooltip: 'convertToEmployeeTask'.tr,
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.operationalPurple,
                size: 21.sp,
              ),
              onPressed: () => _showConvertToEmployeeSheet(context),
            ),
          if (userType == 'admin')
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                minimumSize: Size(0, 36.h),
              ),
              onPressed: () {
                Get.toNamed(
                  AppRoutes.CREATETASKSCREEN,
                  arguments: {
                    'title': 'editSpecialTask',
                    'isEdit': true,
                  },
                );
              },
              child: Text('edit'.tr, style: TextStyle(fontSize: 13.sp)),
            ),
        ],
      ),
      body: Obx(
        () {
          if (controller.isGetLoading.value) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.operationalPurple),
            );
          }
          final data = controller.specialTasksService.specialTaskDetails.value;
          if (data == null) return const ShowNoData();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SpecialOverviewCard(
                        data: data,
                        progress: _progress(data),
                        status: _taskStatus(data),
                      ),
                      _SpecialMaterialsCard(data: data),
                      if (data.subTasks.isNotEmpty) ...[
                        const TaskSectionTitle('taskProgress',
                            compact: _compact),
                        TaskOpCard(
                          compact: _compact,
                          child: _SpecialSubtaskChecklist(data: data),
                        ),
                      ],
                      _SpecialRecurrenceCard(data: data),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConvertToEmployeeSheet(BuildContext context) {
    final details = controller.specialTasksService.specialTaskDetails.value;
    if (details == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'convertToEmployeeTask'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'convertToEmployeeTaskHint'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.customGreyColor5,
                      ),
                ),
                SizedBox(height: 12.h),
                FutureBuilder<List<EmployeeEntity>>(
                  future: controller.employeesForConversion(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final employees = snapshot.data ?? [];
                    if (employees.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Text('noData'.tr, textAlign: TextAlign.center),
                      );
                    }
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 420.h),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: employees.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final employee = employees[index];
                          return Obx(
                            () => ListTile(
                              enabled: !controller.isConvertingTask.value,
                              leading: const Icon(Icons.person_outline),
                              title: Text(employee.employeeName),
                              trailing: controller.isConvertingTask.value
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.chevron_left),
                              onTap: () {
                                controller.convertSpecialTaskToEmployee(
                                  specialTaskId: details.taskId.toString(),
                                  employeeId: employee.id,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpecialOverviewCard extends StatelessWidget {
  const _SpecialOverviewCard({
    required this.data,
    required this.progress,
    required this.status,
  });

  final SpecialTaskDetailsEntities data;
  final int progress;
  final String status;

  @override
  Widget build(BuildContext context) {
    return TaskOpCard(
      compact: SpecialTaskDetailsScreen._compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.operationalPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '#${data.taskId}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalPurple,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              TaskStatusBadge(status: status, compact: true),
              const Spacer(),
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.operationalPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            data.taskName,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${'startDate'.tr}: ${showDateTime12(data.startTime)}',
            style:
                TextStyle(fontSize: 10.sp, color: AppColors.customGreyColor5),
          ),
          Text(
            '${'endDate'.tr}: ${showDateTime12(data.endTime)}',
            style:
                TextStyle(fontSize: 10.sp, color: AppColors.customGreyColor5),
          ),
          if (data.taskDescription.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              data.taskDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: AppColors.customGreyColor5,
              ),
            ),
          ],
          SizedBox(height: 8.h),
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
      ),
    );
  }
}

class _SpecialMaterialsCard extends StatelessWidget {
  const _SpecialMaterialsCard({required this.data});

  final SpecialTaskDetailsEntities data;

  @override
  Widget build(BuildContext context) {
    final hasImages = data.adminImg.isNotEmpty;
    final hasAudio = hasPlayableAudio(data.audio);
    final hasNotes = data.notes.isNotEmpty;

    if (!hasImages && !hasAudio && !hasNotes) {
      return const SizedBox.shrink();
    }

    return TaskOpCard(
      compact: SpecialTaskDetailsScreen._compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'adminAttachedMedia'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          if (hasImages) ...[
            SizedBox(height: 8.h),
            TaskMediaThumbnailRow(
              images: data.adminImg,
              thumbHeight: 72,
              thumbWidth: 72,
            ),
          ],
          if (hasAudio) ...[
            SizedBox(height: 8.h),
            AudioPlayerWidget(url: data.audio),
          ],
          if (hasNotes) ...[
            SizedBox(height: 8.h),
            Text(
              '${'taskNotes'.tr}: ${data.notes}',
              style: TextStyle(
                fontSize: 10.5.sp,
                color: AppColors.customGreyColor5,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecialSubtaskChecklist extends GetView<SpecialTasksController> {
  const _SpecialSubtaskChecklist({required this.data});

  final SpecialTaskDetailsEntities data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.subTasks.map((sub) {
        final done = sub.status == 'completed';
        final canceled = sub.status == 'canceled' || sub.status == 'rejected';
        final closed = done || canceled;
        return GestureDetector(
          onTap: closed ? null : () => _confirmComplete(context, sub),
          child: Container(
            margin: EdgeInsets.only(bottom: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: canceled
                  ? AppColors.redColor.withValues(alpha: 0.06)
                  : AppColors.operationalSurface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: done
                    ? AppColors.operationalPurple.withValues(alpha: 0.25)
                    : canceled
                        ? AppColors.redColor.withValues(alpha: 0.35)
                        : AppColors.operationalCardBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canceled
                      ? Icons.cancel
                      : done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                  size: 16.sp,
                  color: canceled
                      ? AppColors.redColor
                      : done
                          ? AppColors.operationalPurple
                          : AppColors.customGreyColor5,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.subTaskName,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          decoration:
                              closed ? TextDecoration.lineThrough : null,
                          color: canceled
                              ? AppColors.redColor
                              : done
                                  ? AppColors.customGreyColor5
                                  : AppColors.operationalNavy,
                        ),
                      ),
                      if (canceled) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'cancelTask'.tr,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redColor,
                          ),
                        ),
                      ],
                      if (sub.subTaskDescription.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          sub.subTaskDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                      if (sub.adminImg.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        TaskMediaThumbnailRow(
                          images: sub.adminImg,
                          thumbHeight: 44,
                          thumbWidth: 44,
                        ),
                      ],
                    ],
                  ),
                ),
                if (done) ...[
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: 'undoSubtaskCompletion'.tr,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmUndo(context, sub),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          width: 26.w,
                          height: 26.w,
                          decoration: BoxDecoration(
                            color: AppColors.customGreyColor5
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.customGreyColor5
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.undo_rounded,
                            size: 16.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (!closed) ...[
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: 'cancel'.tr,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmCancel(context, sub),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          width: 26.w,
                          height: 26.w,
                          decoration: BoxDecoration(
                            color: AppColors.redColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.redColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16.sp,
                            color: AppColors.redColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _confirmCancel(BuildContext context, SubTaskEntity sub) {
    Get.dialog(
      AlertDialog(
        title: Text('cancel'.tr),
        content: Text('areYouSure'.tr),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redColor,
            ),
            onPressed: () {
              controller.cancelSubSpecialTask(
                context: context,
                subTaskId: sub.subTaskId.toString(),
                specialTaskId: data.taskId.toString(),
              );
            },
            child: Text('yes'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmUndo(BuildContext context, SubTaskEntity sub) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFF3F4F6),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'undoSubtaskCompletion'.tr,
          style: TextStyle(
            color: AppColors.operationalNavy,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'undoSubtaskCompletionConfirm'.tr,
          style: TextStyle(
            color: AppColors.customGreyColor4,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.customGreyColor4),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.operationalPurple,
              elevation: 0,
              side: BorderSide(
                color: AppColors.operationalPurple.withValues(alpha: 0.28),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              controller.undoSubSpecialTaskCompletion(
                subTaskId: sub.subTaskId.toString(),
                specialTaskId: data.taskId.toString(),
              );
            },
            child: Text(
              'yes'.tr,
              style: const TextStyle(
                color: AppColors.operationalPurple,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmComplete(BuildContext context, SubTaskEntity sub) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFF3F4F6),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'areYouSure'.tr,
          style: TextStyle(
            color: AppColors.operationalNavy,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.customGreyColor4),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.operationalPurple,
              elevation: 0,
              side: BorderSide(
                color: AppColors.operationalPurple.withValues(alpha: 0.28),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              controller.makeSubsSpecialTaskCompleted(
                context,
                sub.subTaskId.toString(),
                data.taskId.toString(),
              );
            },
            child: Text(
              'yes'.tr,
              style: const TextStyle(
                color: AppColors.operationalPurple,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialRecurrenceCard extends StatelessWidget {
  const _SpecialRecurrenceCard({required this.data});

  final SpecialTaskDetailsEntities data;

  @override
  Widget build(BuildContext context) {
    return TaskOpCard(
      compact: SpecialTaskDetailsScreen._compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'taskRepeat',
            value: data.taskRecurrence.tr,
          ),
          if (data.taskRecurrence != 'noRepeat')
            _InfoRow(
              label: 'taskRepeatDate',
              value: data.taskRecurrenceTime.map((e) => e.tr).join(' ,'),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${label.tr}: ',
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: AppColors.customGreyColor5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int _progress(SpecialTaskDetailsEntities data) {
  if (data.subTasks.isEmpty) return 0;
  final done = data.subTasks
      .where((sub) =>
          sub.status == 'completed' ||
          sub.status == 'canceled' ||
          sub.status == 'rejected')
      .length;
  return ((done / data.subTasks.length) * 100).round().clamp(0, 100);
}

String _taskStatus(SpecialTaskDetailsEntities data) {
  if (data.subTasks.isNotEmpty && _progress(data) == 100) {
    return 'completed';
  }
  if (data.endTime.isBefore(DateTime.now())) return 'overdue';
  return 'ongoing';
}
