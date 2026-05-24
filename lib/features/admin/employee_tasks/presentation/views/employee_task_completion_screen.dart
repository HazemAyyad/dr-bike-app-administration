import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/camera_capture_helper.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/task_details_model.dart';
import '../../domain/entities/task_details_entiny.dart';
import '../controllers/employee_tasks_controller.dart';
import '../widgets/task_admin_materials_section.dart';
import '../widgets/task_media_thumbnail_row.dart';
import '../widgets/task_operational_shared.dart';
import '../widgets/task_status_badge.dart';
import '../widgets/task_assignees_section.dart';
import 'employee_task_details_operational_screen.dart' show OperationalChecklist;

/// Employee flow: complete subtasks, upload proof, submit for review.
class EmployeeTaskCompletionScreen extends GetView<EmployeeTasksController> {
  const EmployeeTaskCompletionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TaskNavDebug.log(
      'EmployeeTaskCompletionScreen.build',
      AppRoutes.TASKDETAILS,
      screen: 'EmployeeTaskCompletionScreen',
    );

    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: AppBar(
        backgroundColor: AppColors.operationalSurface,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 48.h,
        title: Text(
          'completeTaskTitle'.tr,
          style: TextStyle(
            color: AppColors.operationalNavy,
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.operationalNavy),
      ),
      body: Obx(() {
        final data = controller.employeeTaskService.taskDetails.value;
        if (controller.isTaskDetailsLoading.value && data == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.operationalPurple),
          );
        }
        if (data == null) {
          return Center(child: Text('noData'.tr));
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(
                      data: data,
                      progress: controller.subtaskProgress(data),
                    ),
                    if (data.assignees.isNotEmpty)
                      TaskAssigneesSection(
                        assignees: data.assignees,
                        compact: true,
                      ),
                    if (data.rejectionNotes != null &&
                        data.rejectionNotes!.trim().isNotEmpty)
                      TaskOpCard(
                        compact: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.redColor,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                '${'rejectionNotes'.tr}: ${data.rejectionNotes}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.redColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TaskAdminMaterialsSection(data: data, compact: true),
                    TaskSectionTitle('operationalChecklist', compact: true),
                    TaskOpCard(
                      compact: true,
                      child: OperationalChecklist(
                        data: data,
                        compact: true,
                        interactive: !_isLocked(data),
                        onSubtaskTap: (sub) => _onSubtaskTap(context, sub),
                      ),
                    ),
                    TaskSectionTitle('proofUploadSection', compact: true),
                    _ProofSection(data: data),
                    SizedBox(height: 64.h),
                  ],
                ),
              ),
            ),
            if (!_isLocked(data))
              TaskStickyCta(
                label: data.requiresAdminReview
                    ? 'submitForReview'
                    : 'completeTaskNow',
                icon: Icons.send_rounded,
                isLoading: controller.isLoading.value,
                onPressed: () => _submit(context, data),
              ),
          ],
        );
      }),
    );
  }

  bool _isLocked(TaskDetailsModel data) {
    return data.status == 'completed' ||
        data.status == 'waiting_review' ||
        data.status == 'canceled';
  }

  Future<void> _onSubtaskTap(BuildContext context, SubTaskEntity sub) async {
    if (sub.status == 'completed') return;

    final details = controller.employeeTaskService.taskDetails.value;
    if (details == null) return;

    final args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    final mainTaskId = details.taskId.toString();
    final occurrenceId = args['occurrence_id']?.toString() ??
        controller.lastLoadedOccurrenceId;

    final ok = await controller.completeSubtaskWithCameraProof(
      context: context,
      sub: sub,
      mainTaskId: mainTaskId,
      occurrenceId: occurrenceId,
    );
    if (!ok || !context.mounted) return;

    final meta = controller.lastProofUploadMeta;
    final autoSubmitted = meta != null &&
        EmployeeTasksController.metaTruthy(meta['auto_submitted']);

    if (autoSubmitted) {
      await controller.getTaskDetails(
        taskId: mainTaskId,
        occurrenceId: occurrenceId,
        showFullScreenLoader: false,
      );
      if (!context.mounted) return;
      Get.snackbar(
        'success'.tr,
        'taskSubmittedForReview'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      Get.back(result: true);
      return;
    }

    final refreshed = controller.employeeTaskService.taskDetails.value;
    final allDone = refreshed?.subTasks.every((s) => s.status == 'completed') ??
        false;
    if (!allDone || !context.mounted) return;

    final needsMainProof = (refreshed ?? details).isForcedToUploadImg &&
        !controller.taskHasEmployeeImage(refreshed ?? details);

    if (needsMainProof) {
      Get.snackbar(
        'note'.tr,
        'allSubtasksDoneUploadMainProof'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final submitted = await controller.tryAutoSubmitTaskAfterSubtasks(
      mainTaskId: mainTaskId,
      occurrenceId: occurrenceId,
    );
    if (!context.mounted) return;
    if (submitted) {
      Get.snackbar(
        'success'.tr,
        'taskSubmittedForReview'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      Get.back(result: true);
    }
  }

  Future<void> _submit(BuildContext context, TaskDetailsModel data) async {
    final incomplete = data.subTasks.any((s) => s.status != 'completed');
    if (incomplete) {
      Get.snackbar('error'.tr, 'completeAllSubtasksFirst'.tr);
      return;
    }

    final occurrenceId = (Get.arguments is Map<String, dynamic>
            ? (Get.arguments as Map<String, dynamic>)['occurrence_id']
            : null)
        ?.toString() ??
        controller.lastLoadedOccurrenceId;
    final isOccurrence =
        occurrenceId != null && occurrenceId.isNotEmpty;

    if (data.isForcedToUploadImg &&
        !controller.taskHasEmployeeImage(data) &&
        controller.selectedFile.isEmpty) {
      Get.snackbar('error'.tr, 'employeeImageRequired'.tr);
      return;
    }

    if (controller.selectedFile.isNotEmpty) {
      final uploadId = isOccurrence ? occurrenceId! : data.taskId.toString();
      final ok = await controller.uploadTaskImage(
        taskId: uploadId,
        isOccurrenceMain: isOccurrence,
        reloadOccurrenceId: occurrenceId,
      );
      if (!ok) return;
    }

    if (!context.mounted) return;

    final ok = await controller.submitTaskForReview(
      data.taskId.toString(),
      occurrenceId: occurrenceId,
    );
    if (!context.mounted) return;
    if (ok) {
      Get.back(result: true);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.progress});

  final TaskDetailsModel data;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final done = data.subTasks.where((s) => s.status == 'completed').length;
    final total = data.subTasks.length;

    return TaskOpCard(
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${data.taskId}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.customGreyColor5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6.w),
              TaskStatusBadge(status: data.status, compact: true),
              const Spacer(),
              if (total > 0)
                Text(
                  'subtasksProgressCount'.trParams({
                    'done': '$done',
                    'total': '$total',
                  }),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.customGreyColor5,
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
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${data.employeeName}\n${'endDate'.tr}: ${showDateTime12(data.endTime)}',
            style: TextStyle(fontSize: 10.5.sp, color: AppColors.customGreyColor5),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.operationalPurple,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 4.h,
                    color: AppColors.operationalPurple,
                    backgroundColor: AppColors.operationalSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProofSection extends GetView<EmployeeTasksController> {
  const _ProofSection({required this.data});

  final TaskDetailsModel data;

  Future<void> _pickCameraProof(BuildContext context) async {
    final file = await CameraCaptureHelper.captureProof(context);
    if (file == null) return;
    if (!controller.selectedFile.contains(file)) {
      controller.selectedFile.add(file);
    }

    final args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    final occurrenceId = args['occurrence_id']?.toString() ??
        controller.lastLoadedOccurrenceId;
    final isOccurrence =
        occurrenceId != null && occurrenceId.isNotEmpty;

    await controller.uploadTaskImage(
      taskId: isOccurrence ? occurrenceId! : data.taskId.toString(),
      isOccurrenceMain: isOccurrence,
      files: [file],
      reloadOccurrenceId: occurrenceId,
      silentRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TaskOpCard(
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.isForcedToUploadImg)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                'proofRequiredHint'.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.operationalPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Obx(() {
            final live = controller.employeeTaskService.taskDetails.value;
            final d = live ?? data;
            return TaskMediaThumbnailRow(
              images: d.employeeImg ?? [],
              videos: d.employeeVideos ?? [],
              localFiles: controller.selectedFile.toList(),
            );
          }),
          Obx(() {
            if (!controller.isTaskDetailsLoading.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'syncingProof'.tr,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 8.h),
          _AddProofTile(onTap: () => _pickCameraProof(context)),
        ],
      ),
    );
  }
}

class _AddProofTile extends StatelessWidget {
  const _AddProofTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48.h,
        margin: EdgeInsets.only(left: 6.w),
        decoration: BoxDecoration(
          color: AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.operationalCardBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: AppColors.operationalPurple),
            SizedBox(height: 2.h),
            Text(
              'uploadTaskProof'.tr,
              style: TextStyle(fontSize: 10.sp, color: AppColors.operationalPurple),
            ),
          ],
        ),
      ),
    );
  }
}

