// بناء التقويم
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../../core/utils/app_colors.dart';
import '../../../controllers/create_task_controller.dart';
import '../../../../../../../core/helpers/custom_calendar.dart';
import '../../../../../../../core/helpers/custom_time_picker.dart';

Widget buildCalendar(BuildContext context, CreateTaskController controller) {
  return Container(
    padding: EdgeInsets.all(10.w),
    // height: 500.h,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // رأس التقويم
        Container(
          height: 35.h,
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: controller.isSelected.value == 0
                        ? const Color.fromARGB(255, 136, 129, 233)
                        : AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text(
                    'day'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.whiteColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  onPressed: () {
                    controller.isSelected.value = 0;
                  },
                ),
              ),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: controller.isSelected.value == 1
                        ? const Color.fromARGB(255, 136, 129, 233)
                        : AppColors.primaryColor,
                    // foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text(
                    'time'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.whiteColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  onPressed: () {
                    // controller.changeMonth(-1);
                    controller.isSelected.value = 1;
                  },
                ),
              ),
            ],
          ),
        ),

        controller.isSelected.value == 0
            ? Calendar(
                onDaySelected: (DateTime value) {
                  controller.startDate.value = value;
                },
                selectedDay: controller.startDate.value,
              )
            : TimePicker(
                initialTime: TimeOfDay.now(),
                onTimeChanged: (TimeOfDay value) {
                  controller.startTime.value = value;
                },
              ),
      ],
    ),
  );
}
