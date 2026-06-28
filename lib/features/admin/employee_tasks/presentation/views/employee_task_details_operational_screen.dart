import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/initial_bindings.dart';
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
import '../widgets/task_timeline_section.dart';
import '../widgets/subtask_voice_note_icon.dart';
import '../widgets/subtask_voice_note_tile.dart';
import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/proof_media_type.dart';

/// Admin/manager task details — compact layout.
class EmployeeTaskDetailsOperationalScreen
    extends GetView<EmployeeTasksController> {
  const EmployeeTaskDetailsOperationalScreen({Key? key}) : super(key: key);

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
          'employeeTaskDetails'.tr,
          style: TextStyle(
            color: AppColors.operationalNavy,
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
          ),
        ),
        actions: [
          // النسخ محصور على الأدمن أو من يملك صلاحية "نسخ مهمة موظف".
          if (canCloneEmployeeTasks)
            IconButton(
              tooltip: 'cloneTask'.tr,
              icon: Icon(
                Icons.copy_all_outlined,
                color: AppColors.operationalPurple,
                size: 20.sp,
              ),
              onPressed: () {
                Get.toNamed(
                  AppRoutes.CREATETASKSCREEN,
                  arguments: {
                    'title': 'createNewEmployeeTask',
                    'isEdit': false,
                    'cloneFromTask': true,
                  },
                );
              },
            ),
          // التعديل محصور على الأدمن أو من يملك صلاحية "تعديل مهمة موظف".
          if (canEditEmployeeTasks)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                minimumSize: Size(0, 36.h),
              ),
              onPressed: () {
                Get.toNamed(
                  AppRoutes.CREATETASKSCREEN,
                  arguments: {'title': 'editEmployeeTask', 'isEdit': true},
                );
              },
              child: Text('edit'.tr, style: TextStyle(fontSize: 13.sp)),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isTaskDetailsLoading.value) {
          return const Center(
            child:
                CircularProgressIndicator(color: AppColors.operationalPurple),
          );
        }
        final data = controller.employeeTaskService.taskDetails.value;
        if (data == null) return Center(child: Text('noData'.tr));

        final progress = controller.subtaskProgress(data);
        final showReview =
            data.status == 'waiting_review' && userType == 'admin';

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverviewCard(data: data, progress: progress),
                    if (data.assignees.isNotEmpty)
                      TaskAssigneesSection(
                        assignees: data.assignees,
                        compact: _compact,
                      ),
                    TaskAdminMaterialsSection(data: data, compact: _compact),
                    if (data.subTasks.isNotEmpty) ...[
                      TaskSectionTitle('taskProgress', compact: _compact),
                      TaskOpCard(
                        compact: _compact,
                        child: OperationalChecklist(
                          data: data,
                          compact: _compact,
                        ),
                      ),
                    ],
                    if (_showsEmployeeProofSection(data)) ...[
                      TaskSectionTitle('employeeProofSection', compact: _compact),
                      _ProofGallery(data: data),
                    ],
                    if (data.timeline.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      TaskTimelineSection(
                        events: data.timeline,
                        compact: _compact,
                      ),
                    ],
                    if (data.rejectionNotes != null &&
                        data.rejectionNotes!.isNotEmpty)
                      TaskOpCard(
                        compact: _compact,
                        child: Text(
                          '${'rejectionNotes'.tr}: ${data.rejectionNotes}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.redColor,
                          ),
                        ),
                      ),
                    SizedBox(height: showReview ? 72.h : 12.h),
                  ],
                ),
              ),
            ),
            if (showReview)
              _ReviewBar(
                taskId: data.taskId.toString(),
                occurrenceId: controller.lastLoadedOccurrenceId,
              ),
          ],
        );
      }),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data, required this.progress});

  final TaskDetailsModel data;
  final int progress;

  @override
  Widget build(BuildContext context) {
    return TaskOpCard(
      compact: EmployeeTaskDetailsOperationalScreen._compact,
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
              TaskStatusBadge(
                status: data.status,
                compact: true,
              ),
              const Spacer(),
              Icon(Icons.bolt, size: 14.sp, color: AppColors.operationalPurple),
              SizedBox(width: 2.w),
              Text(
                '${data.points} ${'pointsUnit'.tr}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.operationalNavy,
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
          if (data.assignees.isEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              data.employeeName,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: AppColors.customGreyColor5,
              ),
            ),
          ],
          if (data.completedByName != null &&
              data.completedByName!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 12.sp,
                  color: AppColors.operationalPurple,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'mainTaskFinishedBy'
                        .tr
                        .replaceAll('@name', data.completedByName!),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.operationalPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 2.h),
          Text(
            '${'startDate'.tr}: ${showDateTime12(data.startTime)}',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.customGreyColor5,
            ),
          ),
          Text(
            '${'endDate'.tr}: ${showDateTime12(data.endTime)}',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.customGreyColor5,
            ),
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

class _ProofGallery extends StatelessWidget {
  const _ProofGallery({required this.data});

  final TaskDetailsModel data;

  @override
  Widget build(BuildContext context) {
    final media = TaskMediaThumbnailRow(
      images: data.employeeImg ?? [],
      videos: data.employeeVideos ?? [],
      emptyMessage: 'noProofImages'.tr,
    );
    return TaskOpCard(
      compact: EmployeeTaskDetailsOperationalScreen._compact,
      child: media,
    );
  }
}

class _ReviewBar extends GetView<EmployeeTasksController> {
  const _ReviewBar({required this.taskId, this.occurrenceId});

  final String taskId;
  final String? occurrenceId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      color: AppColors.whiteColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    controller.isLoading.value ? null : () => _reject(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 40.h),
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'rejectTask'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final ok = await controller.approveTaskWorkflow(
                          taskId,
                          occurrenceId: occurrenceId,
                        );
                        if (ok) Get.back(result: true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: Size(0, 44.h),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.check_circle_outline, size: 18.sp),
                label: Text(
                  'approveTask'.tr,
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final notesController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('rejectTask'.tr),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            hintText: 'rejectionReasonRequired'.tr,
            labelText: 'rejectionNotes'.tr,
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              if (notesController.text.trim().isEmpty) {
                Get.snackbar('error'.tr, 'rejectionReasonRequired'.tr);
                return;
              }
              Get.back(result: true);
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true && notesController.text.trim().isNotEmpty) {
      final ok = await controller.rejectTaskWorkflow(
        taskId,
        notesController.text.trim(),
        occurrenceId: occurrenceId,
      );
      if (ok) Get.back(result: true);
    }
  }
}

/// Shared checklist for details and completion screens.
class OperationalChecklist extends StatelessWidget {
  const OperationalChecklist({
    Key? key,
    required this.data,
    this.interactive = false,
    this.compact = false,
    this.onSubtaskTap,
    this.onSubtaskReject,
  }) : super(key: key);

  final TaskDetailsModel data;
  final bool interactive;
  final bool compact;
  final void Function(SubTaskEntity sub)? onSubtaskTap;
  final void Function(SubTaskEntity sub)? onSubtaskReject;

  @override
  Widget build(BuildContext context) {
    if (data.subTasks.isEmpty) {
      return Text(
        'noSubtasks'.tr,
        style: TextStyle(fontSize: compact ? 11.sp : 13.sp),
      );
    }
    return Column(
      children: data.subTasks.map((sub) {
        final done = sub.status == 'completed';
        final rejected = sub.status == 'rejected';
        final needsProof = sub.isForcedToUploadImg;
        final canReject = interactive && !done && !rejected;
        final hasAdminMedia = (sub.adminImg?.isNotEmpty ?? false) ||
            (sub.adminVideos?.isNotEmpty ?? false) ||
            hasPlayableAudio(sub.adminAudio);
        final hasEmployeeProof = (sub.employeeImg?.isNotEmpty ?? false) ||
            (sub.employeeVideos?.isNotEmpty ?? false);
        return GestureDetector(
          onTap: interactive && !done && !rejected
              ? () => onSubtaskTap?.call(sub)
              : null,
          child: Container(
            margin: EdgeInsets.only(bottom: compact ? 4.h : 8.h),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8.w : 12.w,
              vertical: compact ? 6.h : 10.h,
            ),
            decoration: BoxDecoration(
              color: rejected
                  ? AppColors.redColor.withValues(alpha: 0.06)
                  : AppColors.operationalSurface,
              borderRadius: BorderRadius.circular(compact ? 8.r : 14.r),
              border: rejected
                  ? Border.all(
                      color: AppColors.redColor.withValues(alpha: 0.35),
                    )
                  : needsProof && !done
                      ? Border.all(
                          color: AppColors.operationalPurple
                              .withValues(alpha: 0.35),
                        )
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  rejected
                      ? Icons.cancel
                      : done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                  size: compact ? 16.sp : 22.sp,
                  color: rejected
                      ? AppColors.redColor
                      : done
                          ? AppColors.operationalPurple
                          : AppColors.customGreyColor5,
                ),
                SizedBox(width: compact ? 8.w : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: compact ? 11.5.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          decoration: done || rejected
                              ? TextDecoration.lineThrough
                              : null,
                          color: rejected
                              ? AppColors.redColor
                              : done
                                  ? AppColors.customGreyColor5
                                  : AppColors.operationalNavy,
                        ),
                      ),
                      if (rejected) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'subtaskDeclinedLabel'.tr,
                          style: TextStyle(
                            fontSize: compact ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redColor,
                          ),
                        ),
                        if (sub.rejectionReason != null &&
                            sub.rejectionReason!.trim().isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            '${'reasonLabel'.tr}: ${sub.rejectionReason}',
                            style: TextStyle(
                              fontSize: compact ? 9.sp : 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.redColor,
                            ),
                          ),
                        ],
                      ],
                      if (done &&
                          sub.completedByName != null &&
                          sub.completedByName!.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'subtaskFinishedBy'
                              .tr
                              .replaceAll('@name', sub.completedByName!),
                          style: TextStyle(
                            fontSize: compact ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.operationalPurple,
                          ),
                        ),
                      ],
                      if (needsProof && !done && !rejected && !hasEmployeeProof) ...[
                        SizedBox(height: 2.h),
                        Text(
                          ProofMediaType.subtaskRequiredHintKey(sub.proofMediaType)
                              .tr,
                          style: TextStyle(
                            fontSize: compact ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.operationalPurple,
                          ),
                        ),
                      ],
                      if (hasAdminMedia) ...[
                        SizedBox(height: 6.h),
                        Text(
                          'subtaskAdminMaterialsForEmployee'.tr,
                          style: TextStyle(
                            fontSize: compact ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        if (compact)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TaskMediaThumbnailRow(
                                  images: sub.adminImg ?? [],
                                  videos: sub.adminVideos ?? [],
                                  thumbHeight: 40,
                                  thumbWidth: 40,
                                ),
                              ),
                              if (hasPlayableAudio(sub.adminAudio)) ...[
                                SizedBox(width: 8.w),
                                SubtaskVoiceNoteIcon(
                                  url: sub.adminAudio!,
                                  size: 40,
                                ),
                              ],
                            ],
                          )
                        else ...[
                          TaskMediaThumbnailRow(
                            images: sub.adminImg ?? [],
                            videos: sub.adminVideos ?? [],
                            thumbHeight: 56,
                            thumbWidth: 56,
                          ),
                          if (hasPlayableAudio(sub.adminAudio)) ...[
                            SizedBox(height: 6.h),
                            SubtaskVoiceNoteTile(url: sub.adminAudio!),
                          ],
                        ],
                      ],
                      if (hasEmployeeProof) ...[
                        SizedBox(height: 6.h),
                        Text(
                          'subtaskEmployeeProofTitle'.tr,
                          style: TextStyle(
                            fontSize: compact ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.operationalPurple,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        TaskMediaThumbnailRow(
                          images: sub.employeeImg ?? [],
                          videos: sub.employeeVideos ?? [],
                          thumbHeight: compact ? 48 : 56,
                          thumbWidth: compact ? 48 : 56,
                        ),
                      ],
                    ],
                  ),
                ),
                if (needsProof && !rejected) ...[
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: done && hasEmployeeProof
                        ? 'subtaskProofUploaded'.tr
                        : ProofMediaType.subtaskRequiredHintKey(sub.proofMediaType)
                            .tr,
                    child: Icon(
                      done && hasEmployeeProof
                          ? Icons.verified_outlined
                          : Icons.camera_alt_outlined,
                      size: compact ? 16.sp : 20.sp,
                      color: done && hasEmployeeProof
                          ? AppColors.customGreen1
                          : AppColors.operationalPurple,
                    ),
                  ),
                ],
                if (canReject && onSubtaskReject != null) ...[
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: 'declineSubtask'.tr,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSubtaskReject?.call(sub),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          width: compact ? 26.w : 32.w,
                          height: compact ? 26.w : 32.w,
                          decoration: BoxDecoration(
                            color: AppColors.redColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.redColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: compact ? 16.sp : 20.sp,
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
}

bool _showsEmployeeProofSection(TaskDetailsModel data) {
  if (data.isForcedToUploadImg) return true;
  return (data.employeeImg?.isNotEmpty ?? false) ||
      (data.employeeVideos?.isNotEmpty ?? false);
}
