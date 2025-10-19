// ignore_for_file: depend_on_referenced_packages

import 'package:intl/intl.dart';

String showData(dynamic date) {
  DateTime parsedDate = DateTime.parse(date.toString());

  // تنسيق التاريخ بالشكل المطلوب
  String formattedDate = DateFormat('yyyy-MM-dd', 'en').format(parsedDate);
  //  hh:mm a
  return formattedDate;
}

String showDataAndTime(DateTime date) {
  DateTime parsedDate = DateTime.parse(date.toString());

  // تنسيق التاريخ بالشكل المطلوب
  String formattedDate =
      DateFormat('yyyy-MM-dd' ' ' 'hh:mm a', 'en').format(parsedDate);
  //  hh:mm a
  return formattedDate;
}

String formatTimeTo12Hour(String time24) {
  // تحويل النص لوقت
  final dateTime = DateFormat("HH:mm:ss").parse(time24);
  // تحويله لصيغة 12 ساعة مع AM/PM
  return DateFormat("hh:mm a").format(dateTime);
}

String formatTimeTo12HourArabic(String time24) {
  final dateTime = DateFormat("HH:mm:ss").parse(time24);
  return DateFormat("hh:mm a", "ar").format(dateTime);
}
