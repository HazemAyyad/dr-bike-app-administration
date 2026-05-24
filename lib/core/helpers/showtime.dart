// ignore_for_file: depend_on_referenced_packages

import 'package:get/get.dart';
import 'package:intl/intl.dart';

DateTime _parseDate(dynamic date) {
  if (date is DateTime) return date.toLocal();
  return DateTime.parse(date.toString()).toLocal();
}

String _localeTag() {
  final code = Get.locale?.languageCode ?? 'ar';
  return code == 'ar' ? 'ar' : 'en';
}

/// Date only (d/M/yyyy).
String showData(dynamic date) {
  return DateFormat('d/M/yyyy', _localeTag()).format(_parseDate(date));
}

/// Date + time — 12-hour with AM/PM (ص/م in Arabic).
String showDateTime12(dynamic date) {
  return DateFormat('d/M/yyyy hh:mm a', _localeTag()).format(_parseDate(date));
}

/// Alias for timeline / activity log timestamps.
String showTimelineDateTime(dynamic date) => showDateTime12(date);

String showDataAndTime(DateTime date) {
  return showDateTime12(date);
}

String formatTimeTo12Hour(String time24) {
  final dateTime = DateFormat('HH:mm:ss').parse(time24);
  return DateFormat('hh:mm a', _localeTag()).format(dateTime);
}

String formatTimeTo12HourArabic(String time24) {
  return formatTimeTo12Hour(time24);
}
