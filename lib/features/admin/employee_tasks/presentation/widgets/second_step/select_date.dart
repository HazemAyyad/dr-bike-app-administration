import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/employee_tasks/presentation/widgets/second_step/data_and_time/data_and_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../controllers/create_task_controller.dart';
import 'required_label.dart';

Widget selectDate(
  BuildContext context,
  CreateTaskController controller,
  String label,
  RxBool isEndDate,
  String titale,
) {
  return Column(
    children: [
      BuildRequiredLabel(label: label),
      Obx(
        () => GestureDetector(
          onTap: () =>
              controller.toggleCalendar(label == 'startDate' ? true : false),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.customGreyColor2,
              ),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      titale,
                      style:
                          Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor
                                    : AppColors.customGreyColor6,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                              ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                  ],
                ),
                Obx(
                  () => AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.decelerate,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: child,
                        );
                      },
                      child: isEndDate.value
                          ? buildCalendar(context, controller)
                          : SizedBox(key: const ValueKey('empty')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
