import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/task_details_model.dart';
import '../../data/datasources/employee_tasks_datasource.dart';
import '../../../employee_section/data/models/employee_points_log_model.dart';
import '../../../employee_section/data/models/employee_reward_rule_model.dart';
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
          if (canManageEmployeeTasks)
            IconButton(
              tooltip: 'convertToSpecialTask'.tr,
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.operationalPurple,
                size: 21.sp,
              ),
              onPressed: () => _confirmConvertToSpecial(context),
            ),
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
            data.status == 'waiting_review' && controller.canReviewTasks;

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
                      const TaskSectionTitle('taskProgress', compact: _compact),
                      TaskOpCard(
                        compact: _compact,
                        child: OperationalChecklist(
                          data: data,
                          compact: _compact,
                          onSubtaskLongPress: showReview
                              ? (sub) =>
                                  _showSubtaskPointsActions(context, data, sub)
                              : null,
                          onSubtaskReject: showReview
                              ? (sub) =>
                                  _showSubtaskRejectDialog(context, data, sub)
                              : null,
                        ),
                      ),
                    ],
                    if (_showsEmployeeProofSection(data)) ...[
                      const TaskSectionTitle('employeeProofSection',
                          compact: _compact),
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
                taskName: data.taskName,
                employeeId: data.employeeId,
                occurrenceId: controller.lastLoadedOccurrenceId,
              ),
          ],
        );
      }),
    );
  }

  void _confirmConvertToSpecial(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('convertToSpecialTask'.tr),
        content: Text('convertToSpecialTaskConfirm'.tr),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.operationalPurple,
            ),
            onPressed: () {
              Get.back();
              controller.convertCurrentTaskToSpecial(context);
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubtaskPointsActions(
    BuildContext context,
    TaskDetailsModel task,
    SubTaskEntity subtask,
  ) async {
    final datasource = Get.find<EmployeeTasksDatasource>();
    var categories = <EmployeePointCategoryModel>[];
    var rewardRules = <EmployeeRewardRuleModel>[];

    try {
      categories = await datasource.getPointCategoriesForReview();
      rewardRules = await datasource.getRewardRulesForReview();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }

    final addCategories = categories.where((e) => e.isAdd).toList();
    final deductCategories = categories.where((e) => e.isDeduct).toList();

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      subtask.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      task.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _PointActionSection(
                    title: 'أسباب الإضافة',
                    icon: Icons.add_circle_outline,
                    color: const Color(0xFF16A34A),
                    emptyText: 'لا يوجد أسباب إضافة ثابتة',
                    children: [
                      for (final category in addCategories)
                        _PointActionTile(
                          icon: Icons.add_circle_outline,
                          color: const Color(0xFF16A34A),
                          title: _categoryName(category),
                          subtitle:
                              '+${category.defaultPoints} ${'pointsUnit'.tr}',
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showPointsDialog(
                              context,
                              task,
                              subtask,
                              true,
                              category: category,
                            );
                          },
                        ),
                      _PointActionTile(
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFF16A34A),
                        title: 'إضافة حرّة',
                        subtitle: 'اكتب عدد النقاط والسبب يدويًا',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showPointsDialog(context, task, subtask, true);
                        },
                      ),
                    ],
                  ),
                  _PointActionSection(
                    title: 'أسباب الخصم',
                    icon: Icons.remove_circle_outline,
                    color: const Color(0xFFDC2626),
                    emptyText: 'لا يوجد أسباب خصم ثابتة',
                    children: [
                      for (final category in deductCategories)
                        _PointActionTile(
                          icon: Icons.remove_circle_outline,
                          color: const Color(0xFFDC2626),
                          title: _categoryName(category),
                          subtitle:
                              '-${category.defaultPoints} ${'pointsUnit'.tr}',
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showPointsDialog(
                              context,
                              task,
                              subtask,
                              false,
                              category: category,
                            );
                          },
                        ),
                      _PointActionTile(
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFFDC2626),
                        title: 'خصم حر',
                        subtitle: 'اكتب عدد النقاط والسبب يدويًا',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showPointsDialog(context, task, subtask, false);
                        },
                      ),
                    ],
                  ),
                  _PointActionSection(
                    title: 'المكافآت',
                    icon: Icons.card_giftcard_rounded,
                    color: AppColors.operationalPurple,
                    emptyText: 'لا يوجد قواعد مكافآت ثابتة',
                    children: [
                      for (final rule in rewardRules)
                        _PointActionTile(
                          icon: Icons.card_giftcard_rounded,
                          color: AppColors.operationalPurple,
                          title: _rewardName(rule),
                          subtitle: _rewardSubtitle(rule),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showPointsDialog(
                              context,
                              task,
                              subtask,
                              true,
                              rewardRule: rule,
                              categoryCode: 'subtask_review_reward',
                            );
                          },
                        ),
                      _PointActionTile(
                        icon: Icons.edit_note_rounded,
                        color: AppColors.operationalPurple,
                        title: 'مكافأة حرّة',
                        subtitle: 'اكتب نقاط المكافأة يدويًا',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showPointsDialog(
                            context,
                            task,
                            subtask,
                            true,
                            categoryCode: 'subtask_review_reward',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPointsDialog(
    BuildContext context,
    TaskDetailsModel task,
    SubTaskEntity subtask,
    bool isAdd, {
    EmployeePointCategoryModel? category,
    EmployeeRewardRuleModel? rewardRule,
    String categoryCode = 'subtask_review',
  }) async {
    final initialPoints = category?.defaultPoints ??
        (rewardRule == null
            ? 1
            : (rewardRule.minPoints < 1 ? 1 : rewardRule.minPoints));
    final pointsCtrl = TextEditingController(text: initialPoints.toString());
    final notesCtrl = TextEditingController();
    final isReward =
        rewardRule != null || categoryCode == 'subtask_review_reward';
    final title = isReward
        ? 'إعطاء مكافأة'
        : category != null
            ? _categoryName(category)
            : isAdd
                ? 'إضافة نقاط'
                : 'خصم نقاط';
    final fixedReason = rewardRule != null
        ? 'مكافأة من مراجعة مهمة فرعية: ${subtask.name} - ${_rewardName(rewardRule)}'
        : category != null
            ? '${isAdd ? 'إضافة' : 'خصم'} نقاط من مراجعة مهمة فرعية: ${subtask.name} - ${_categoryName(category)}'
            : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fixedReason != null) ...[
              Text(
                fixedReason,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.customGreyColor5,
                ),
              ),
              SizedBox(height: 10.h),
            ],
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'pointsValue'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: notesCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: fixedReason == null
                    ? 'سبب / ملاحظات'
                    : 'pointsNotesOptional'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReward
                  ? AppColors.operationalPurple
                  : isAdd
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    final points = int.tryParse(pointsCtrl.text.trim()) ?? 0;
    final notes = notesCtrl.text.trim();
    pointsCtrl.dispose();
    notesCtrl.dispose();
    if (confirmed != true) return;

    await _mutateSubtaskReviewPoints(
      task: task,
      subtask: subtask,
      isAdd: isAdd,
      points: points,
      notes: notes,
      categoryId: category?.id,
      category: category?.code ?? categoryCode,
      reasonOverride: fixedReason ??
          '${isReward ? 'مكافأة' : isAdd ? 'إضافة' : 'خصم'} من مراجعة مهمة فرعية: ${subtask.name}',
    );
  }

  Future<void> _mutateSubtaskReviewPoints({
    required TaskDetailsModel task,
    required SubTaskEntity subtask,
    required bool isAdd,
    required int points,
    String? notes,
    int? categoryId,
    String category = 'subtask_review',
    String? reasonOverride,
  }) async {
    final employeeId = int.tryParse(task.employeeId);
    if (employeeId == null || employeeId <= 0) {
      Get.snackbar('error'.tr, 'employee_not_found'.tr);
      return;
    }
    if (points < 1) {
      Get.snackbar('error'.tr, 'pointsValueMin'.tr);
      return;
    }

    final action = isAdd ? 'إضافة' : 'خصم';
    final reason =
        reasonOverride ?? '$action نقاط من مراجعة مهمة فرعية: ${subtask.name}';
    controller.isLoading(true);
    try {
      final res =
          await Get.find<EmployeeTasksDatasource>().mutateEmployeePoints(
        employeeId: employeeId,
        isAdd: isAdd,
        points: points,
        reason: reason,
        categoryId: categoryId,
        category: category,
        notes: notes,
      );
      if (res['status'] == 'success') {
        await controller.getTaskDetails(
          taskId: task.taskId.toString(),
          occurrenceId: controller.lastLoadedOccurrenceId,
          showFullScreenLoader: false,
        );
        controller.update(['taskDetails', 'subtasks']);
        Get.snackbar(
          'success'.tr,
          'pointsUpdatedMessage'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      Get.snackbar('error'.tr, '${res['message'] ?? ''}');
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      controller.isLoading(false);
    }
  }

  Future<void> _showSubtaskRejectDialog(
    BuildContext context,
    TaskDetailsModel task,
    SubTaskEntity subtask,
  ) async {
    if (subtask.status == 'rejected') return;

    final reasonController = TextEditingController();
    final deductionController = TextEditingController();
    const dialogBg = Color(0xFFF0F0F0);
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'declineSubtaskTitle'.tr,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.operationalNavy,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'declineSubtaskHint'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.customGreyColor5,
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: reasonController,
                maxLines: 4,
                autofocus: true,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.operationalNavy,
                ),
                decoration: InputDecoration(
                  hintText: 'declineReasonRequired'.tr,
                  hintStyle: TextStyle(
                    color: AppColors.customGreyColor5,
                    fontSize: 12.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.whiteColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(
                      color: AppColors.operationalCardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.redColor),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: deductionController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.operationalNavy,
                ),
                decoration: InputDecoration(
                  hintText: 'اتركه فارغ إذا ما بدك تخصم',
                  labelText: 'خصم نقاط اختياري',
                  hintStyle: TextStyle(
                    color: AppColors.customGreyColor5,
                    fontSize: 12.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.whiteColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(
                      color: AppColors.operationalCardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: AppColors.redColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.customGreyColor5),
            ),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar('error'.tr, 'declineReasonRequired'.tr);
                return;
              }
              Get.back(result: true);
            },
            child: Text(
              'confirm'.tr,
              style: const TextStyle(
                color: AppColors.redColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    final deductionPoints = int.tryParse(deductionController.text.trim()) ?? 0;
    if (confirmed != true || reason.isEmpty) return;

    final ok = await controller.rejectSubtask(
      subTaskId: subtask.id,
      reason: reason,
      mainTaskId: task.taskId.toString(),
      occurrenceId: controller.lastLoadedOccurrenceId,
      asReviewer: true,
    );
    if (ok) {
      if (deductionPoints > 0) {
        await _mutateSubtaskReviewPoints(
          task: task,
          subtask: subtask,
          isAdd: false,
          points: deductionPoints,
          category: 'task_rejection',
          reasonOverride:
              'خصم نقاط بسبب رفض مهمة فرعية: ${subtask.name} - $reason',
        );
      } else {
        Get.snackbar(
          'success'.tr,
          'subtaskDeclined'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  String _categoryName(EmployeePointCategoryModel category) {
    return category.nameAr.trim().isNotEmpty
        ? category.nameAr.trim()
        : (category.nameEn ?? category.code).trim();
  }

  String _rewardName(EmployeeRewardRuleModel rule) {
    final label = rule.statusLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return 'مكافأة ${rule.rewardAmount}';
  }

  String _rewardSubtitle(EmployeeRewardRuleModel rule) {
    final max = rule.maxPoints == null ? '∞' : rule.maxPoints.toString();
    return '${rule.minPoints} - $max ${'pointsUnit'.tr} / ${rule.rewardAmount}';
  }
}

class _PointActionSection extends StatelessWidget {
  const _PointActionSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visibleChildren = children.isEmpty
        ? <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                emptyText,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.customGreyColor5,
                ),
              ),
            ),
          ]
        : children;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...visibleChildren,
        ],
      ),
    );
  }
}

class _PointActionTile extends StatelessWidget {
  const _PointActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20.sp),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10.5.sp),
      ),
      onTap: onTap,
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
  const _ReviewBar({
    required this.taskId,
    required this.taskName,
    required this.employeeId,
    this.occurrenceId,
  });

  final String taskId;
  final String taskName;
  final String employeeId;
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
    final deductionController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('rejectTask'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'rejectionReasonRequired'.tr,
                  labelText: 'rejectionNotes'.tr,
                ),
                maxLines: 4,
                autofocus: true,
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: deductionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'اتركه فارغ إذا ما بدك تخصم',
                  labelText: 'خصم نقاط اختياري',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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

    final notes = notesController.text.trim();
    final deductionPoints = int.tryParse(deductionController.text.trim()) ?? 0;
    if (confirmed == true && notes.isNotEmpty) {
      final ok = await controller.rejectTaskWorkflow(
        taskId,
        notes,
        occurrenceId: occurrenceId,
      );
      if (!ok) return;

      if (deductionPoints > 0) {
        await _deductTaskRejectionPoints(deductionPoints, notes);
      }
      Get.back(result: true);
    }
  }

  Future<void> _deductTaskRejectionPoints(int points, String notes) async {
    final parsedEmployeeId = int.tryParse(employeeId);
    if (parsedEmployeeId == null || parsedEmployeeId <= 0 || points < 1) {
      return;
    }

    controller.isLoading(true);
    try {
      final res =
          await Get.find<EmployeeTasksDatasource>().mutateEmployeePoints(
        employeeId: parsedEmployeeId,
        isAdd: false,
        points: points,
        category: 'task_rejection',
        reason: 'خصم نقاط بسبب رفض مهمة رئيسية: $taskName',
        notes: notes,
      );
      if (res['status'] != 'success') {
        Get.snackbar('error'.tr, '${res['message'] ?? ''}');
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      controller.isLoading(false);
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
    this.onSubtaskUndo,
    this.onSubtaskReplaceProof,
    this.onSubtaskLongPress,
  }) : super(key: key);

  final TaskDetailsModel data;
  final bool interactive;
  final bool compact;
  final void Function(SubTaskEntity sub)? onSubtaskTap;
  final void Function(SubTaskEntity sub)? onSubtaskReject;
  final void Function(SubTaskEntity sub)? onSubtaskUndo;
  final void Function(SubTaskEntity sub)? onSubtaskReplaceProof;
  final void Function(SubTaskEntity sub)? onSubtaskLongPress;

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
        final hasRejectionReason = sub.rejectionReason != null &&
            sub.rejectionReason!.trim().isNotEmpty;
        final canReject =
            !rejected && onSubtaskReject != null && (!done || !interactive);
        final canUndo = interactive && done && onSubtaskUndo != null;
        final canReplaceProof =
            interactive && done && needsProof && onSubtaskReplaceProof != null;
        final hasAdminMedia = (sub.adminImg?.isNotEmpty ?? false) ||
            (sub.adminVideos?.isNotEmpty ?? false) ||
            hasPlayableAudio(sub.adminAudio);
        final hasEmployeeProof = (sub.employeeImg?.isNotEmpty ?? false) ||
            (sub.employeeVideos?.isNotEmpty ?? false);
        return GestureDetector(
          onTap: interactive && !done && !rejected
              ? () => onSubtaskTap?.call(sub)
              : null,
          onLongPress: onSubtaskLongPress == null
              ? null
              : () => onSubtaskLongPress?.call(sub),
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
                        if (hasRejectionReason) ...[
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
                      if (!rejected && hasRejectionReason) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'تم إرجاعها للتنفيذ',
                          style: TextStyle(
                            fontSize: compact ? 9.sp : 10.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redColor,
                          ),
                        ),
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
                      if (needsProof &&
                          !done &&
                          !rejected &&
                          !hasEmployeeProof) ...[
                        SizedBox(height: 2.h),
                        Text(
                          ProofMediaType.subtaskRequiredHintKey(
                                  sub.proofMediaType)
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
                  if (canReplaceProof)
                    Tooltip(
                      message: 'replaceSubtaskProof'.tr,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onSubtaskReplaceProof?.call(sub),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            width: compact ? 26.w : 32.w,
                            height: compact ? 26.w : 32.w,
                            decoration: BoxDecoration(
                              color: AppColors.operationalPurple
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.operationalPurple
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Icon(
                              Icons.swap_horizontal_circle_outlined,
                              size: compact ? 16.sp : 20.sp,
                              color: AppColors.operationalPurple,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: done && hasEmployeeProof
                          ? 'subtaskProofUploaded'.tr
                          : ProofMediaType.subtaskRequiredHintKey(
                                  sub.proofMediaType)
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
                if (canUndo) ...[
                  SizedBox(width: 6.w),
                  Tooltip(
                    message: 'undoSubtaskCompletion'.tr,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSubtaskUndo?.call(sub),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          width: compact ? 26.w : 32.w,
                          height: compact ? 26.w : 32.w,
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
                            size: compact ? 16.sp : 20.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ),
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
