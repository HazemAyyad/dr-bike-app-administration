import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import 'showtime.dart';

class CustomCalendar extends StatelessWidget {
  const CustomCalendar({
    Key? key,
    required this.isVisible,
    required this.onTap,
    required this.selectedDay,
    this.label,
    this.isrequired = false,
  }) : super(key: key);

  final Function() onTap;
  final Rx<DateTime> selectedDay;
  final RxBool isVisible;
  final String? label;
  final bool? isrequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        label != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    label!.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  isrequired!
                      ? Text(
                          '*',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.red,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                        )
                      : const SizedBox.shrink(),
                ],
              )
            : const SizedBox.shrink(),
        SizedBox(height: 10.h),
        Obx(
          () => GestureDetector(
            onTap: onTap,
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
                        showData(selectedDay.value),
                        style: Theme.of(Get.context!)
                            .textTheme
                            .bodyMedium!
                            .copyWith(
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
                      child: isVisible.value
                          ? Padding(
                              padding: EdgeInsets.only(top: 20.h),
                              child: Calendar(
                                selectedDay: selectedDay.value,
                                onDaySelected: (value) {
                                  selectedDay.value = value;
                                },
                              ),
                            )
                          : const SizedBox(),
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

class Calendar extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const Calendar({
    Key? key,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  CalendarState createState() => CalendarState();
}

class CalendarState extends State<Calendar> {
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();
    displayedMonth =
        DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  List<DateTime?> getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final startWeekday = first.weekday % 7;
    final days = <DateTime?>[];

    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(month.year, month.month, d));
    }
    final rem = days.length % 7;
    if (rem != 0) {
      for (int i = 0; i < 7 - rem; i++) {
        days.add(null);
      }
    }
    return days;
  }

  void changeMonth(int offset) {
    setState(() {
      displayedMonth =
          DateTime(displayedMonth.year, displayedMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale =
        Get.locale == const Locale('ar') ? const Locale('ar') : const Locale('en');
    final daysList = getDaysInMonth(displayedMonth);
    final now = DateTime.now();

    return Column(
      children: [
        Container(
          color: AppColors.primaryColor,
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    size: 16.sp, color: Colors.white),
                onPressed: () => changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy', locale.languageCode)
                    .format(displayedMonth),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios,
                    size: 16.sp, color: Colors.white),
                onPressed: () => changeMonth(1),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        Row(
          children: ['sun', 'mon', 'tues', 'wednes', 'thurs', 'fri', 'satur']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d.tr,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 8.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: daysList.length,
          itemBuilder: (_, idx) {
            final day = daysList[idx];
            final isToday = day != null &&
                day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;
            final isSelected = day != null &&
                day.year == widget.selectedDay.year &&
                day.month == widget.selectedDay.month &&
                day.day == widget.selectedDay.day;

            return GestureDetector(
              onTap: day != null ? () => widget.onDaySelected(day) : null,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : isToday
                          ? AppColors.primaryColor.withAlpha(50)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    day?.day.toString() ?? '',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.primaryColor
                              : AppColors.customGreyColor5,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
