import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../controllers/create_task_controller.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../third_step/multi_select_dropdown.dart';
import 'select_date.dart';

Widget buildSecondStep(BuildContext context, CreateTaskController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 10.h),
      CustomTextField(
        label: 'taskPoints',
        hintText: 'taskPointsExample',
        controller: controller.pointsController,
      ),
      SizedBox(height: 10.h),
      // تاريخ البدء
      selectDate(
        context,
        controller,
        'startDate',
        controller.isStartDateCalendarVisible,
        controller.startDate.value.toString().split(' ')[0],
      ),
      SizedBox(height: 10.h),

      // تاريخ الانتهاء
      selectDate(
        context,
        controller,
        'endDate',
        controller.isEndDateCalendarVisible,
        controller.endDate.value.toString().split(' ')[0],
      ),
      SizedBox(height: 10.h),
      // إشعار بدأ المهمة
      CustomChechbox(
        titale: 'hideTask',
        value: controller.hideTask,
        onChanged: (value) => controller.hideTask.value = value!,
      ),
      // التكرار
      CustomDropdownField(
        label: 'taskRepeat'.tr,
        hint: 'taskRepeatExample'.tr,
        items: controller.weekDays,
        onChanged: (value) => controller.selectedDays.value = value!,
      ),
      SizedBox(height: 10.h),
      MultiSelectDropdown(
        toggleRecurrence: controller.toggleRecurrence,
        selectedDaysList: controller.selectedDaysList,
        isRecurrenceVisible: controller.isRecurrenceVisible,
        label: 'taskRepeatDate',
      ),
    ],
  );
}
