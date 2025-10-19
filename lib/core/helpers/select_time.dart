import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';

Future<void> selectTime(
    BuildContext context, TextEditingController controller) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: true), // تأكيد صيغة 12 ساعة
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (picked != null) {
    // تحويل TimeOfDay إلى DateTime
    final DateTime now = DateTime.now();
    final DateTime dateTime =
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute);

    // استخدام intl لضبط الوقت على الإنجليزية وصيغة 12 ساعة
    final String formattedTime = DateFormat("h:mm a", "en").format(dateTime);

    controller.text = formattedTime; // تحديث النص داخل الـ TextField
  }
}

Future<void> selectDate(
    BuildContext context, TextEditingController controller) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: ThemeService.isDark.value
                ? AppColors.customGreyColor5
                : AppColors.secondaryColor, // لون التحديد
            onPrimary: Colors.white, // لون النص عند التحديد
            onSurface: ThemeService.isDark.value
                ? AppColors.primaryColor
                : AppColors.secondaryColor, // لون النص العادي
            surface: ThemeService.isDark.value
                ? AppColors.darkColor
                : AppColors.whiteColor,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryColor,
                  ),
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (picked != null) {
    // تنسيق التاريخ باستخدام intl
    final String formattedDate = DateFormat("yyyy-MM-dd", "en").format(picked);

    controller.text = formattedDate; // تحديث النص داخل الـ TextField
  }
}
