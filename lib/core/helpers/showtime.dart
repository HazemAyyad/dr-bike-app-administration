// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
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

/// Date + time — day-month-year, then time 12-hour (ص/م in Arabic).
/// Example: `2-6-2026 - 03:45 م`
String showDateTime12(dynamic date) {
  return DateFormat('d-M-yyyy - hh:mm a', _localeTag()).format(_parseDate(date));
}

/// Alias for timeline / activity log timestamps.
String showTimelineDateTime(dynamic date) => showDateTime12(date);

String showDataAndTime(DateTime date) {
  return showDateTime12(date);
}

String formatTimeTo12Hour(String time24) {
  final raw = time24.trim();
  if (raw.isEmpty || raw == '0') {
    return '—';
  }

  DateTime? parsed;
  for (final pattern in ['HH:mm:ss', 'HH:mm', 'H:mm:ss', 'H:mm']) {
    try {
      parsed = DateFormat(pattern).parse(raw);
      break;
    } catch (_) {}
  }

  if (parsed == null) {
    return raw;
  }

  return DateFormat('hh:mm a', _localeTag()).format(parsed);
}

/// Parses 24h time strings like `08:00` or `08:00:00`. Returns [fallback] if invalid.
TimeOfDay parseTimeOfDay(
  String time24, {
  TimeOfDay fallback = const TimeOfDay(hour: 9, minute: 0),
}) {
  final raw = time24.trim();
  if (raw.isEmpty || raw == '0') {
    return fallback;
  }

  final parts = raw.split(':');
  if (parts.length < 2) {
    return fallback;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return fallback;
  }

  return TimeOfDay(hour: hour, minute: minute);
}

String formatTimeTo12HourArabic(String time24) {
  return formatTimeTo12Hour(time24);
}

/// Time only — 12-hour with AM/PM (ص/م in Arabic).
String formatTimeOnly12(dynamic date) {
  return DateFormat('hh:mm a', _localeTag()).format(_parseDate(date));
}

String formatDayHeader(dynamic date) {
  final dt = _parseDate(date);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) {
    return 'today'.tr;
  }
  return DateFormat('d-M-yyyy', _localeTag()).format(dt);
}

/// API timestamp or date-only string → `d-M-yyyy - hh:mm a` (ص/م in Arabic).
String formatApiDateTime12(dynamic value) {
  if (value == null) return '—';
  final raw = value.toString().trim();
  if (raw.isEmpty) return '—';
  try {
    return showDateTime12(raw);
  } catch (_) {
    try {
      return DateFormat('d-M-yyyy', _localeTag()).format(_parseDate(raw));
    } catch (_) {
      return raw;
    }
  }
}
