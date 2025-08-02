import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';
import '../widgets/add_sub_task.dart';
import '../widgets/second_step/second_step.dart';
import '../widgets/third_step/third_step.dart';

class CreateTaskScreen extends GetView<CreateTaskController> {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = Get.arguments['title'];

    return Scaffold(
      appBar: customAppBar(
        context,
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
              // اسم المهمة
              Row(
                children: [
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
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              // ملاحظات عن المهمة
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'taskNotes',
                      hintText: 'taskDescriptionExample',
                      controller: controller.taskNotesController,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Flexible(
                    child: title == 'createNewEmployeeTask'
                        ? CustomDropdownField(
                            label: 'employeeName',
                            hint: 'chooseEmployee',
                            items: controller.availableEmployees,
                            onChanged: (value) {
                              controller.selectedEmployees = value!;
                            },
                          )
                        : SizedBox(),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              // إضافة مهمة فرعية
              AddSubTask(controller: controller),
              buildSecondStep(context, controller),
              buildThirdStep(context, controller, title),
            ],
          ),
        ),
      ),
    );
  }
}
