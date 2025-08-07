import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_calendar.dart';
import '../../../../../core/helpers/custom_time_picker.dart';
import '../../../../../core/services/theme_service.dart';

class SelectDate extends StatelessWidget {
  const SelectDate({
    Key? key,
    required this.label,
    required this.onTap,
    this.isEndDate,
    required this.isSelected,
    required this.date,
    required this.time,
  }) : super(key: key);

  final String label;
  final Function() onTap;
  final RxBool? isEndDate;
  final RxInt isSelected;
  final Rx<DateTime> date;
  final Rx<TimeOfDay> time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label.tr,
              style: theme.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor6
                    : AppColors.customGreyColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            // Text(
            //   '*',
            //   style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            //         color: Colors.red,
            //         fontSize: 15.sp,
            //         fontWeight: FontWeight.w700,
            //       ),
            // )
          ],
        ),
        SizedBox(height: 10.h),
        Obx(
          () => GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.customGreyColor2),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${showData(date.value)} / ${(time.value.hour % 12 == 0 ? 12 : time.value.hour % 12).toString().padLeft(2, '0')}:${time.value.minute.toString().padLeft(2, '0')} ${time.value.hour < 12 ? 'morning'.tr : 'evening'.tr}',
                        style: theme.copyWith(
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
                        child: isEndDate!.value
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 10.h),
                                  // رأس التقويم
                                  Container(
                                    height: 35.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  isSelected.value == 1
                                                      ? const Color.fromARGB(
                                                          255, 136, 129, 233)
                                                      : AppColors.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                              ),
                                            ),
                                            child: Text(
                                              'day'.tr,
                                              style: theme.copyWith(
                                                color: AppColors.whiteColor,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            onPressed: () {
                                              isSelected.value = 0;
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  isSelected.value == 0
                                                      ? const Color.fromARGB(
                                                          255, 136, 129, 233)
                                                      : AppColors.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                              ),
                                            ),
                                            child: Text(
                                              'time'.tr,
                                              style: theme.copyWith(
                                                color: AppColors.whiteColor,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            onPressed: () {
                                              isSelected.value = 1;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  isSelected.value == 0
                                      ? Calendar(
                                          onDaySelected: (DateTime value) {
                                            date.value = value;
                                          },
                                          selectedDay: date.value,
                                        )
                                      : TimePicker(
                                          initialTime: TimeOfDay.now(),
                                          onTimeChanged: (TimeOfDay value) {
                                            time.value = value;
                                          },
                                        ),
                                ],
                              )
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
}
