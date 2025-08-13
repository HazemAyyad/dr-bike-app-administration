import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/loding_indicator.dart';
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
    final String title = Get.arguments;

    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        action: false,
      ),
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
                      hintStyle:
                          Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor
                                    : AppColors.customGreyColor6,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
                      controller: controller.taskDescriptionController,
                      validator: (p0) => null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              // ملاحظات عن المهمة
              title == 'createNewEmployeeTask'
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
                          child: CustomDropdownField(
                            label: 'employeeName',
                            hint: 'chooseEmployee',
                            items: controller.availableEmployees,
                            onChanged: (value) {
                              controller.selectedEmployees = value!;
                            },
                            validator: (p0) => null,
                          ),
                        ),
                      ],
                    )
                  : CustomTextField(
                      label: 'taskNotes',
                      hintText: 'taskDescriptionExample',
                      controller: controller.taskNotesController,
                      validator: (p0) => null,
                    ),
              SizedBox(height: 15.h),
              // إضافة مهمة فرعية
              AddSubTask(controller: controller),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'taskPoints',
                hintText: 'taskPointsExample',
                controller: controller.pointsController,
                validator: (p0) => null,
              ),
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
              CustomCheckBox(
                title: 'hideTask',
                value: controller.hideTask,
                onChanged: (value) => controller.hideTask.value = value!,
              ),
              // التكرار
              CustomDropdownField(
                label: 'taskRepeat'.tr,
                hint: 'taskRepeatExample'.tr,
                items: controller.weekDays,
                onChanged: (value) => controller.selectedDays.value = value!,
                validator: (p0) => null,
              ),
              SizedBox(height: 10.h),
              MultiSelectDropdown(
                toggleRecurrence: controller.toggleRecurrence,
                selectedDaysList: controller.selectedDaysList,
                isRecurrenceVisible: controller.isRecurrenceVisible,
                label: 'taskRepeatDate',
              ),
              SizedBox(height: 20.h),
              AudioRecorderButton(
                label: 'recordAudio',
                recordedPath: controller.recordedPath,
              ),
              SizedBox(height: 20.h),
              // صورة المهمة
              Column(
                children: [
                  UploadImageButton(
                    selectedFile: controller.selectedFile,
                    title: 'uploadImage',
                  ),
                  SizedBox(height: 10.h),
                  CustomCheckBox(
                    title: 'requireImage',
                    value: controller.requireImage,
                    onChanged: (value) {
                      controller.requireImage.value = value!;
                    },
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Obx(
                () => controller.isLoding.value
                    ? lodingIndicator()
                    : AppButton(
                        text: 'createTask'.tr,
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                        onPressed: () {
                          controller.createTask(context);
                        },
                        height: 40.h,
                      ),
              ),
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}
