import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

import '../../../../../core/helpers/custom_calendar.dart';
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
    this.compact = false,
  }) : super(key: key);

  final String label;
  final Function() onTap;
  final RxBool? isEndDate;
  final RxInt isSelected;
  final Rx<DateTime> date;
  final Rx<TimeOfDay> time;
  final bool compact;

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
                fontSize: compact ? 11.sp : 15.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4.h : 10.h),
        Obx(
          () => GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8.w : 16.w,
                vertical: compact ? 8.h : 12.h,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.customGreyColor2),
                borderRadius: BorderRadius.circular(compact ? 8.r : 11.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${showData(date.value)} / ${(time.value.hour % 12 == 0 ? 12 : time.value.hour % 12).toString().padLeft(2, '0')}:${time.value.minute.toString().padLeft(2, '0')} ${time.value.hour < 12 ? 'morning'.tr : 'evening'.tr}',
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.customGreyColor6,
                            fontSize: compact ? 11.sp : 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryColor,
                        size: compact ? 16.sp : 20.sp,
                      ),
                    ],
                  ),
                  Obx(
                    () => isEndDate!.value
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 10.h),
                              // رأس التقويم
                              Container(
                                height: 35.h,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryColor,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: isSelected.value == 1
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
                                          backgroundColor: isSelected.value == 0
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
                                      onDaySelected: (dateTime) {
                                        date.value = dateTime;
                                      },
                                    )
                                  : OmniDateTimePicker(
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      is24HourMode: false,
                                      isShowSeconds: false,
                                      minutesInterval: 1,
                                      amText: 'morning'.tr,
                                      pmText: 'evening'.tr,
                                      type: OmniDateTimePickerType.time,
                                      onDateTimeChanged: (selectedTime) {
                                        time.value = TimeOfDay.fromDateTime(
                                            selectedTime);
                                      },
                                    ),
                            ],
                          )
                        : const SizedBox(key: ValueKey('empty')),
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
