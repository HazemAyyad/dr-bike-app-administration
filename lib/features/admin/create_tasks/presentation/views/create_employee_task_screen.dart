import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/create_task_controller.dart';
import '../widgets/audio_recorder.dart';
import '../widgets/employee_selector_field.dart';
import '../widgets/employee_task_priority_selector.dart';
import '../widgets/inline_subtask_builder.dart';
import '../widgets/select_date.dart';
import '../widgets/task_form_section_card.dart';

/// Modern operational composer for employee tasks (replaces legacy long form).
class CreateEmployeeTaskScreen extends GetView<CreateTaskController> {
  const CreateEmployeeTaskScreen({Key? key}) : super(key: key);

  bool get _isEdit => Get.arguments?['isEdit'] == true;

  String get _titleArg => Get.arguments?['title']?.toString() ?? 'createNewEmployeeTask';

  @override
  Widget build(BuildContext context) {
    TaskNavDebug.log(
      'CreateEmployeeTaskScreen.build',
      AppRoutes.CREATETASKSCREEN,
      screen: 'CreateEmployeeTaskScreen',
      extra: {'isEdit': _isEdit, 'title': _titleArg},
    );

    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(
        title: _isEdit ? 'editEmployeeTask' : 'createNewEmployeeTask',
        action: false,
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  children: [
                    TaskFormSectionCard(
                      title: 'taskInfo',
                      child: Column(
                        children: [
                          CustomTextField(
                            isRequired: true,
                            label: 'taskName',
                            hintText: 'taskNameExample',
                            controller: controller.taskNameController,
                          ),
                          SizedBox(height: 12.h),
                          CustomTextField(
                            label: 'taskDescription',
                            hintText: 'taskDescriptionExample',
                            controller: controller.taskDescriptionController,
                            validator: (_) => null,
                          ),
                          SizedBox(height: 12.h),
                          CustomTextField(
                            label: 'taskNotes',
                            hintText: 'taskDescriptionExample',
                            controller: controller.taskNotesController,
                            validator: (_) => null,
                          ),
                        ],
                      ),
                    ),
                    TaskFormSectionCard(
                      title: 'employeeName',
                      child: const EmployeeSelectorField(),
                    ),
                    TaskFormSectionCard(
                      title: 'priority',
                      child: const EmployeeTaskPrioritySelector(),
                    ),
                    TaskFormSectionCard(
                      title: 'taskPoints',
                      child: CustomTextField(
                        label: 'taskPoints',
                        hintText: 'taskPointsExample',
                        controller: controller.pointsController,
                        keyboardType: TextInputType.number,
                        validator: (_) => null,
                      ),
                    ),
                    TaskFormSectionCard(
                      title: 'scheduling',
                      child: Column(
                        children: [
                          SelectDate(
                            label: 'startDate',
                            onTap: () => controller.toggleCalendar(true),
                            isSelected: controller.isSelected,
                            date: controller.startDate,
                            time: controller.startTime,
                            isEndDate: controller.isStartDateCalendarVisible,
                          ),
                          SizedBox(height: 12.h),
                          SelectDate(
                            label: 'endDate',
                            onTap: () => controller.toggleCalendar(false),
                            isSelected: controller.isSelected,
                            date: controller.endDate,
                            time: controller.endTime,
                            isEndDate: controller.isEndDateCalendarVisible,
                          ),
                        ],
                      ),
                    ),
                    TaskFormSectionCard(
                      title: 'taskRepeat',
                      trailing: Icon(Icons.chevron_right, color: AppColors.operationalPurple),
                      child: Obx(
                        () => InkWell(
                          onTap: () {
                            TaskNavDebug.log(
                              'CreateEmployeeTaskScreen.recurrenceTile',
                              AppRoutes.TASKRECURRENCE,
                              screen: 'TaskRecurrenceScreen',
                            );
                            Get.toNamed(AppRoutes.TASKRECURRENCE)?.then((_) {
                              controller.updateRecurrenceSummary();
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    controller.recurrenceSummary.value.isEmpty
                                        ? (controller.selectedDays.value.isEmpty
                                            ? 'taskRepeatExample'.tr
                                            : controller.selectedDays.value.tr)
                                        : controller.recurrenceSummary.value,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.operationalNavy,
                                    ),
                                  ),
                                ),
                                Icon(Icons.tune, color: AppColors.operationalPurple, size: 22.sp),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    TaskFormSectionCard(
                      title: 'subTasks',
                      child: const InlineSubtaskBuilder(),
                    ),
                    TaskFormSectionCard(
                      title: 'attachments',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AudioRecorderButton(
                            label: 'recordAudio',
                            recordedPath: controller.recordedPath,
                          ),
                          SizedBox(height: 12.h),
                          MediaUploadButton(
                            isShowPreview: !_isEdit,
                            onFilesChanged: (files) {
                              for (final file in files) {
                                if (!controller.selectedFile.contains(file)) {
                                  controller.selectedFile.add(file);
                                }
                              }
                              controller.update();
                            },
                            title: 'uploadImage',
                          ),
                          if (_isEdit && controller.selectedFile.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: controller.selectedFile.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.w),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: file.path.contains('http')
                                              ? CachedNetworkImage(
                                                  imageUrl: file.path,
                                                  height: 100.h,
                                                  width: 100.w,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  file,
                                                  height: 100.h,
                                                  width: 100.w,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () {
                                              controller.selectedFile.removeAt(index);
                                              controller.update();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          SizedBox(height: 8.h),
                          CustomCheckBox(
                            title: 'requireImage',
                            value: controller.requireImage,
                            onChanged: (v) => controller.requireImage.value = v!,
                          ),
                          CustomCheckBox(
                            title: 'hideTask',
                            value: controller.hideTask,
                            onChanged: (v) => controller.hideTask.value = v!,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
            _StickySaveBar(isEdit: _isEdit),
          ],
        ),
      ),
    );
  }
}

class _StickySaveBar extends GetView<CreateTaskController> {
  const _StickySaveBar({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: controller.isLoding.value
                  ? null
                  : () {
                      if (isEdit) {
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
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEdit ? 'editTask'.tr : 'createTask'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
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
