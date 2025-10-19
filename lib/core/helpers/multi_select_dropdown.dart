import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class MultiSelectDropdown extends StatelessWidget {
  const MultiSelectDropdown({
    Key? key,
    required this.selectedDaysList,
    required this.isRecurrenceVisible,
    required this.toggleRecurrence,
    required this.label,
    this.isRequired = false,
  }) : super(key: key);

  final RxList<String> selectedDaysList;
  final RxBool isRecurrenceVisible;
  final VoidCallback toggleRecurrence;
  final String label;
  final bool? isRequired;

  @override
  Widget build(BuildContext context) {
    // قائمة أيام الأسبوع
    final List<String> days = [
      "saturday",
      "sunday",
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ];
    final textTheme = Theme.of(context).textTheme.bodyMedium!;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label.tr,
              style: textTheme.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor6
                    : AppColors.customGreyColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            isRequired!
                ? Text(
                    '*',
                    style: textTheme.copyWith(
                      color: Colors.red,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        SizedBox(height: 10.h),
        Obx(
          () => GestureDetector(
            onTap: toggleRecurrence,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          selectedDaysList.isEmpty
                              ? 'taskRepeatDateExample'.tr
                              : selectedDaysList
                                  .map((day) => day.tr)
                                  .join(' ، '),
                          style: textTheme.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor2
                                : AppColors.customGreyColor5,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                    ],
                  ),
                  AnimatedSize(
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
                      child: isRecurrenceVisible.value
                          ? Column(
                              children: [
                                ...days.map(
                                  (day) {
                                    return Obx(
                                      () {
                                        final isSelected =
                                            selectedDaysList.contains(day);
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity:
                                              const VisualDensity(vertical: -2),
                                          horizontalTitleGap: 5.w,
                                          titleAlignment: ListTileTitleAlignment
                                              .titleHeight,
                                          leading: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  color: AppColors.primaryColor,
                                                  size: 20.sp,
                                                )
                                              : SizedBox(width: 24.w),
                                          title: Text(
                                            day.tr,
                                            style: textTheme.copyWith(
                                              color: ThemeService.isDark.value
                                                  ? AppColors.whiteColor
                                                  : AppColors.customGreyColor4,
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          onTap: () {
                                            if (isSelected) {
                                              selectedDaysList.remove(day);
                                            } else {
                                              selectedDaysList.add(day);
                                            }
                                          },
                                        );
                                      },
                                    );
                                  },
                                )
                              ],
                            )
                          : const SizedBox(key: ValueKey('empty')),
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
