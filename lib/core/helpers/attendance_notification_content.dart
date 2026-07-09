import 'dart:math' as math;

import 'package:get/get.dart';

import '../../features/admin/employee_section/data/models/employee_attendance_history_model.dart';
import 'attendance_time_parser.dart';
import 'showtime.dart';

class AttendanceNotificationBuiltContent {
  const AttendanceNotificationBuiltContent({
    required this.title,
    required this.summary,
    required this.inboxLines,
    required this.mode,
    required this.accentArgb,
  });

  /// Collapsed headline (usually live clock or action title).
  final String title;

  /// Collapsed subtitle — badge + key info on one line.
  final String summary;

  /// Optional expanded detail rows.
  final List<String> inboxLines;
  final String mode;
  final int accentArgb;
}

/// Builds persistent-notification text from today's attendance snapshot.
class AttendanceNotificationContent {
  AttendanceNotificationContent._();

  static const accentCheckIn = 0xFF6C5CE7;
  static const accentWorking = 0xFF34C759;
  static const accentLate = 0xFFE53935;
  static const accentOvertime = 0xFFFF9800;
  static const accentNeutral = 0xFF1565C0;

  static String badge(String key) => key.tr;

  static int expectedMinutes(
    EmployeeAttendanceDay? day,
    String numberOfWorkHours,
  ) {
    if (day != null && day.expectedWorkMinutes > 0) {
      return day.expectedWorkMinutes;
    }
    return _parseDailyMinutes(numberOfWorkHours);
  }

  static Duration liveWorkedDuration(EmployeeAttendanceDay day) {
    var closedSeconds = 0;
    DateTime? openCheckIn;

    for (final seg in day.segments) {
      if (seg.open) {
        openCheckIn = seg.checkInAt ?? seg.checkInServerAt;
      } else if (seg.workedMinutes != null) {
        closedSeconds += seg.workedMinutes! * 60;
      }
    }

    if (openCheckIn != null) {
      closedSeconds += DateTime.now().difference(openCheckIn).inSeconds;
    }

    if (closedSeconds > 0) {
      return Duration(seconds: closedSeconds);
    }

    if (day.currentlyIn) {
      final checkIn = day.firstCheckIn ?? day.firstCheckInServer;
      if (checkIn != null) {
        return DateTime.now().difference(checkIn);
      }
    }

    return Duration(minutes: math.max(0, day.workedMinutes));
  }

  static int liveOvertimeMinutes(EmployeeAttendanceDay day, int expected) {
    final liveMinutes = liveWorkedDuration(day).inMinutes;
    return math.max(day.overtimeMinutes, math.max(0, liveMinutes - expected));
  }

  static String onTimeLabel(EmployeeAttendanceDay day) {
    if (day.onTime == null) return '—';
    return day.onTime! ? 'onTimeYes'.tr : 'onTimeNo'.tr;
  }

  static String lateLabel(EmployeeAttendanceDay day, String startWorkTime) {
    final firstCheckIn = day.firstCheckIn ?? day.firstCheckInServer;
    if (firstCheckIn == null || startWorkTime.trim().isEmpty) {
      return onTimeLabel(day);
    }

    final scheduled = AttendanceTimeParser.parseOnDate(
      startWorkTime,
      firstCheckIn,
    );
    if (scheduled == null || !firstCheckIn.isAfter(scheduled)) {
      return onTimeLabel(day);
    }

    final lateMinutes = firstCheckIn.difference(scheduled).inMinutes;
    if (lateMinutes <= 0) {
      return onTimeLabel(day);
    }

    return '${'onTimeNo'.tr} ${formatWorkedDurationMinutes(lateMinutes)}';
  }

  static AttendanceNotificationBuiltContent buildCheckInContent() {
    return AttendanceNotificationBuiltContent(
      title: 'attendancePersistentCheckInTitle'.tr,
      summary:
          '${badge('attendanceNotifBadgeOutside')} ${'attendancePersistentCheckInBody'.tr}',
      inboxLines: const [],
      mode: 'check_in',
      accentArgb: accentCheckIn,
    );
  }

  static AttendanceNotificationBuiltContent buildInsideContent({
    required EmployeeAttendanceDay day,
    required String startWorkTime,
    required String endWorkTime,
    required String numberOfWorkHours,
    required DateTime now,
  }) {
    final expected = expectedMinutes(day, numberOfWorkHours);
    final overtimeMin = liveOvertimeMinutes(day, expected);
    final lateInfo = lateLabel(day, startWorkTime);
    final isLate = day.onTime == false;
    final hasOvertime = overtimeMin > 0;

    final statusBadge = hasOvertime
        ? badge('attendanceNotifBadgeOvertime')
        : badge('attendanceNotifBadgeWorking');

    final accent = hasOvertime ? accentOvertime : accentWorking;

    final end = AttendanceTimeParser.parseToday(endWorkTime);
    var mode = hasOvertime ? 'overtime' : 'inside';

    if (end != null && now.isBefore(end)) {
      mode = 'countdown';
    }

    final summaryParts = <String>[statusBadge];
    if (isLate && !hasOvertime) {
      summaryParts.add(lateInfo);
    }
    if (end != null && !now.isBefore(end)) {
      summaryParts.add('attendancePersistentOvertimeBody'.tr);
      mode = 'overtime';
    }

    return AttendanceNotificationBuiltContent(
      title: 'attendancePersistentInsideTitle'.tr,
      summary: summaryParts.join(' · '),
      inboxLines: const [],
      mode: mode,
      accentArgb: accent,
    );
  }

  static AttendanceNotificationBuiltContent buildOutsideWithPartialDay(
    EmployeeAttendanceDay day,
    String numberOfWorkHours,
  ) {
    final workedFmt = formatWorkedDurationMinutes(day.workedMinutes);

    return AttendanceNotificationBuiltContent(
      title: 'attendancePersistentCheckInTitle'.tr,
      summary:
          '${badge('attendanceNotifBadgeOutside')} ${'attendanceNotifSummaryWorkedToday'.trParams({
            'duration': workedFmt
          })}',
      inboxLines: const [],
      mode: 'check_in_partial',
      accentArgb: accentCheckIn,
    );
  }

  static int _parseDailyMinutes(String? hours) {
    if (hours == null || hours.isEmpty || hours == '0') return 0;
    final n = double.tryParse(hours.replaceAll(',', '.'));
    if (n == null) return 0;
    return (n * 60).round();
  }
}
