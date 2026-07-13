import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/utils/app_colors.dart';
import 'task_recurrence_screen.dart';
import '../controllers/create_task_controller.dart';
import '../widgets/audio_recorder.dart';
import '../widgets/employee_selector_field.dart';
import '../widgets/employee_task_priority_selector.dart';
import '../widgets/inline_subtask_builder.dart';
import '../widgets/proof_media_type_selector.dart';
import '../widgets/task_date_time_field.dart';
import '../widgets/task_form_section_card.dart';
import '../widgets/task_reminder_section.dart';

/// Compact operational composer for employee tasks.
class CreateEmployeeTaskScreen extends GetView<CreateTaskController> {
  const CreateEmployeeTaskScreen({Key? key}) : super(key: key);

  static const _compact = true;

  bool get _isEdit => Get.arguments?['isEdit'] == true;
  String get _title => Get.arguments?['title']?.toString() ?? '';
  bool get _isSpecialTask =>
      _title == 'addNewPravateTask' || _title == 'editSpecialTask';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(
        title: _isSpecialTask
            ? (_isEdit ? 'editSpecialTask' : 'addNewPravateTask')
            : (_isEdit ? 'editEmployeeTask' : 'createNewEmployeeTask'),
        action: false,
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Column(
                  children: [
                    TaskFormSectionCard(
                      compact: _compact,
                      title: 'taskInfo',
                      child: Column(
                        children: [
                          CustomTextField(
                            isRequired: true,
                            label: 'taskName',
                            hintText: 'taskNameExample',
                            controller: controller.taskNameController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 2,
                            maxLines: 6,
                          ),
                          if (!_isSpecialTask) ...[
                            SizedBox(height: 6.h),
                            CustomTextField(
                              label: 'taskDescription',
                              hintText: 'taskDescriptionExample',
                              controller: controller.taskDescriptionController,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              minLines: 2,
                              maxLines: 8,
                              validator: (_) => null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_isSpecialTask)
                      TaskFormSectionCard(
                        compact: _compact,
                        title: 'employeeName',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const EmployeeSelectorField(compact: true),
                            SizedBox(height: 8.h),
                            Text(
                              'priority'.tr,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.customGreyColor5,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            const EmployeeTaskPrioritySelector(compact: true),
                          ],
                        ),
                      ),
                    TaskFormSectionCard(
                      compact: _compact,
                      title: _isSpecialTask ? 'date' : 'taskPoints',
                      child: Column(
                        children: [
                          if (!_isSpecialTask) ...[
                            CustomTextField(
                              label: 'taskPoints',
                              hintText: 'taskPointsExample',
                              controller: controller.pointsController,
                              keyboardType: TextInputType.number,
                              validator: (_) => null,
                            ),
                            SizedBox(height: 8.h),
                          ],
                          const TaskDateTimeField(
                            compact: true,
                            label: 'startDate',
                            isStart: true,
                          ),
                          if (!_isSpecialTask) ...[
                            SizedBox(height: 8.h),
                            const TaskDateTimeField(
                              compact: true,
                              label: 'endDate',
                              isStart: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_isSpecialTask)
                      TaskFormSectionCard(
                        compact: _compact,
                        title: 'taskOptions',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomCheckBox(
                              title: 'pinTaskUntilDone',
                              value: controller.pinUntilDone,
                              onChanged: (v) =>
                                  controller.setPinUntilDone(v ?? false),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: 38.w,
                                end: 4.w,
                              ),
                              child: Text(
                                'pinTaskUntilDoneHint'.tr,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  height: 1.35,
                                  color: AppColors.customGreyColor5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TaskFormSectionCard(
                      compact: _compact,
                      title: 'taskRepeat',
                      trailing: Icon(
                        Icons.chevron_left,
                        color: AppColors.operationalPurple,
                        size: 20.sp,
                      ),
                      child: Obx(
                        () {
                          final isPinned = controller.pinUntilDone.value;
                          return InkWell(
                            onTap: isPinned
                                ? null
                                : () async {
                                    await showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16.r),
                                          ),
                                          child: SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.92,
                                            child: const TaskRecurrenceScreen(),
                                          ),
                                        ),
                                      ),
                                    );
                                    controller.updateRecurrenceSummary();
                                  },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 18.sp,
                                  color: AppColors.operationalPurple,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    controller.formRecurrenceSummary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: isPinned
                                          ? AppColors.customGreyColor5
                                          : AppColors.operationalNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const TaskFormSectionCard(
                      compact: _compact,
                      title: 'taskReminder',
                      child: TaskReminderSection(compact: true),
                    ),
                    TaskFormSectionCard(
                      compact: _compact,
                      title: 'subTasks',
                      child:
                          InlineSubtaskBuilder(isSpecialTask: _isSpecialTask),
                    ),
                    if (!_isSpecialTask)
                      TaskFormSectionCard(
                        compact: _compact,
                        title: 'attachments',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AudioRecorderButton(
                                    label: 'recordAudio',
                                    recordedPath: controller.recordedPath,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: MediaUploadButton(
                                    isShowPreview: !_isEdit,
                                    onFilesChanged: (files) {
                                      for (final file in files) {
                                        if (!controller.selectedFile
                                            .contains(file)) {
                                          controller.selectedFile.add(file);
                                        }
                                      }
                                      controller.update();
                                    },
                                    title: 'uploadImage',
                                  ),
                                ),
                              ],
                            ),
                            if (_isEdit &&
                                controller.selectedFile.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              SizedBox(
                                height: 64.h,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: controller.selectedFile
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final file = entry.value;
                                    return Padding(
                                      padding: EdgeInsets.only(left: 6.w),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            child: file.path.contains('http')
                                                ? CachedNetworkImage(
                                                    imageUrl: file.path,
                                                    height: 64.h,
                                                    width: 64.w,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.file(
                                                    file,
                                                    height: 64.h,
                                                    width: 64.w,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                controller.selectedFile
                                                    .removeAt(index);
                                                controller.update();
                                              },
                                              child: Icon(
                                                Icons.cancel,
                                                size: 18.sp,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            SizedBox(height: 4.h),
                            Obx(
                              () => ProofMediaTypeSelector(
                                value: controller.proofMediaType.value,
                                onChanged: controller.setMainProofMediaType,
                              ),
                            ),
                            CustomCheckBox(
                              title: 'requireAdminReview',
                              value: controller.requireAdminReview,
                              onChanged: (v) =>
                                  controller.requireAdminReview.value = v!,
                            ),
                            CustomCheckBox(
                              title: 'hideTask',
                              value: controller.hideTask,
                              onChanged: (v) => controller.hideTask.value = v!,
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 64.h),
                  ],
                ),
              ),
            ),
            _StickySaveBar(isEdit: _isEdit, isSpecialTask: _isSpecialTask),
          ],
        ),
      ),
    );
  }
}

class _StickySaveBar extends GetView<CreateTaskController> {
  const _StickySaveBar({
    required this.isEdit,
    required this.isSpecialTask,
  });

  final bool isEdit;
  final bool isSpecialTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: controller.isLoding.value
                  ? null
                  : () {
                      if (isSpecialTask) {
                        controller.createSpecialTask(
                          context,
                          specialTaskId: isEdit
                              ? controller.specialTasksService
                                  .specialTaskDetails.value!.taskId
                              : 0,
                        );
                      } else if (isEdit) {
                        controller.createTask(
                          context,
                          employeeTaskId: controller
                              .employeeTaskService.taskDetails.value!.taskId,
                        );
                      } else {
                        controller.createTask(context);
                      }
                    },
              child: controller.isLoding.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEdit ? 'editTask'.tr : 'createTask'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
