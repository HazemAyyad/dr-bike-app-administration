import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';
import '../widgets/add_sub_task.dart';
import '../widgets/select_date.dart';
import '../../../../../core/helpers/multi_select_dropdown.dart';
import '../widgets/audio_recorder.dart';

class CreateTaskScreen extends GetView<CreateTaskController> {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = Get.arguments['title'];

    return Scaffold(
      appBar: CustomAppBar(title: title, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h),
              Row(
                children: [
                  // اسم المهمة
                  Flexible(
                    child: CustomTextField(
                      isRequired: true,
                      label: 'taskName',
                      hintText: 'taskNameExample',
                      controller: controller.taskNameController,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Flexible(
                    child: CustomTextField(
                      label: 'taskDescription',
                      hintText: 'taskDescriptionExample',
                      controller: controller.taskDescriptionController,
                      validator: (p0) => null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              // ملاحظات عن المهمة
              title == 'createNewEmployeeTask' || title == 'editEmployeeTask'
                  ? Row(
                      children: [
                        Flexible(
                          child: CustomTextField(
                            label: 'taskNotes',
                            hintText: 'taskDescriptionExample',
                            controller: controller.taskNotesController,
                            validator: (p0) => null,
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Flexible(
                          child: GetBuilder<CreateTaskController>(
                            builder: (_) {
                              return CustomDropdownField(
                                label: 'employeeName',
                                hint: 'employeeNameExample',
                                dropdownField: controller
                                    .employeeService.employeeList
                                    .map((e) {
                                  return DropdownMenuItem<String>(
                                    value: e.id.toString(),
                                    child: Text(e.employeeName),
                                  );
                                }).toList(),
                                value: controller.employeeService.employeeList
                                        .any((e) =>
                                            e.id.toString() ==
                                            controller.employeeIdConroller.text)
                                    ? controller.employeeIdConroller.text
                                    : null,
                                onChanged: (value) {
                                  controller.employeeIdConroller.text = value!;
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : CustomTextField(
                      label: 'taskNotes',
                      hintText: 'taskDescriptionExample',
                      controller: controller.taskNotesController,
                      validator: (p0) => null,
                      maxLines: 5,
                      minLines: 5,
                    ),
              SizedBox(height: 15.h),
              // إضافة مهمة فرعية
              AddSubTask(title: title),
              SizedBox(height: 10.h),
              title == 'editEmployeeTask' || title == 'createNewEmployeeTask'
                  ? CustomTextField(
                      label: 'taskPoints',
                      hintText: 'taskPointsExample',
                      controller: controller.pointsController,
                      keyboardType: TextInputType.number,
                      validator: (p0) => null,
                    )
                  : const SizedBox.shrink(),
              SizedBox(height: 15.h),
              // تاريخ البدء
              SelectDate(
                label: 'startDate',
                onTap: () => controller.toggleCalendar(true),
                isSelected: controller.isSelected,
                date: controller.startDate,
                time: controller.startTime,
                isEndDate: controller.isStartDateCalendarVisible,
              ),
              SizedBox(height: 15.h),
              // تاريخ الانتهاء
              SelectDate(
                label: 'endDate',
                onTap: () => controller.toggleCalendar(false),
                isSelected: controller.isSelected,
                date: controller.endDate,
                time: controller.endTime,
                isEndDate: controller.isEndDateCalendarVisible,
              ),
              SizedBox(height: 10.h),
              // إشعار بدأ المهمة
              title == 'editEmployeeTask' || title == 'createNewEmployeeTask'
                  ? CustomCheckBox(
                      title: 'hideTask',
                      value: controller.hideTask,
                      onChanged: (value) => controller.hideTask.value = value!,
                    )
                  : const SizedBox.shrink(),
              // التكرار
              CustomDropdownField(
                label: 'taskRepeat'.tr,
                value: controller.selectedDays.value.isEmpty
                    ? null
                    : controller.selectedDays.value,
                hint: controller.isEdit && controller.title == 'editSpecialTask'
                    ? controller.specialTasksService.specialTaskDetails.value!
                        .taskRecurrence
                    : controller.isEdit && controller.title != 'editSpecialTask'
                        ? controller.employeeTaskService.taskDetails.value!
                            .taskRecurrence
                        : 'taskRepeatExample'.tr,
                items: controller.weekDays,
                onChanged: (value) {
                  controller.selectedDays.value = value!;
                },
                validator: (p0) => null,
              ),
              SizedBox(height: 10.h),
              MultiSelectDropdown(
                toggleRecurrence: controller.toggleRecurrence,
                selectedDaysList: controller.selectedDaysList,
                isRecurrenceVisible: controller.isRecurrenceVisible,
                label: 'taskRepeatDate',
              ),
              // if (!controller.isEdit)
              SizedBox(height: 10.h),
              // if (!controller.isEdit)
              AudioRecorderButton(
                label: 'recordAudio',
                recordedPath: controller.recordedPath,
              ),
              if (!controller.isEdit) SizedBox(height: 20.h),
              // صورة المهمة
              controller.isEdit
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.selectedFile.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                'documentsImages'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: (ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                        SizedBox(height: 5.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: GetBuilder<CreateTaskController>(
                            builder: (controller) => Row(
                              children: [
                                ...controller.selectedFile.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final file = entry.value;
                                    return Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.w),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(5.r),
                                            child: file.path.contains('http')
                                                ? CachedNetworkImage(
                                                    imageUrl: file.path,
                                                    height: 200.h,
                                                    width: 200.w,
                                                    fit: BoxFit.fill,
                                                    fadeInDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    fadeOutDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  )
                                                : Image.file(
                                                    file,
                                                    height: 200.h,
                                                    width: 200.w,
                                                    fit: BoxFit.fill,
                                                  ),
                                          ),
                                          // زرار فوق الصورة
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                controller.selectedFile
                                                    .removeAt(index);
                                                controller.update();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                      ],
                    )
                  : const SizedBox.shrink(),
              Column(
                children: [
                  // controller.isEdit && controller.title == 'editSpecialTask'
                  //     ? controller.selectedFile.isNotEmpty
                  //         ? controller.selectedFile.first.path.contains('http')
                  //             ? CachedNetworkImage(
                  //                 imageUrl: controller.selectedFile.first.path,
                  //                 height: 350.h,
                  //                 width: double.infinity,
                  //                 fit: BoxFit.cover,
                  //               )
                  //             : MediaUploadButton(
                  //                 allowedType: MediaType.image,
                  //                 onFilesChanged: (files) {
                  //                   controller.selectedFile.addAll(files);
                  //                 },
                  //                 title: 'uploadImage',
                  //               )
                  //         : MediaUploadButton(
                  //             allowedType: MediaType.image,
                  //             onFilesChanged: (files) {
                  //               controller.selectedFile.addAll(files);
                  //             },
                  //             title: 'uploadImage',
                  //           )
                  //     :
                  // if (!controller.isEdit)
                  MediaUploadButton(
                    isShowPreview: controller.isEdit ? false : true,
                    onFilesChanged: (files) {
                      for (var file in files) {
                        if (!controller.selectedFile.contains(file)) {
                          controller.selectedFile.add(file);
                        }
                      }
                      controller.update();
                    },
                    title: 'uploadImage',
                  ),
                  SizedBox(height: 10.h),
                  title == 'editEmployeeTask' ||
                          title == 'createNewEmployeeTask'
                      ? CustomCheckBox(
                          title: 'requireImage',
                          value: controller.requireImage,
                          onChanged: (value) {
                            controller.requireImage.value = value!;
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              SizedBox(height: 10.h),
              AppButton(
                isLoading: controller.isLoding,
                text: controller.isEdit
                    ? 'editTask'
                    : title == 'editEmployeeTask'
                        ? 'editEmployeeTask'
                        : 'createTask',
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                onPressed: () {
                  if (controller.isEdit) {
                    title == 'editSpecialTask'
                        ? controller.createSpecialTask(
                            context,
                            specialTaskId: controller.specialTasksService
                                .specialTaskDetails.value!.taskId,
                          )
                        : controller.createTask(
                            context,
                            employeeTaskId: controller
                                .employeeTaskService.taskDetails.value!.taskId,
                          );
                  } else {
                    title == 'createNewEmployeeTask'
                        ? controller.createTask(context)
                        : controller.createSpecialTask(context);
                  }
                },
                height: 40.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
