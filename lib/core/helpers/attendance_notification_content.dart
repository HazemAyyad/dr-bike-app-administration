import 'dart:math' as math;

import 'package:get/get.dart';

import '../../features/admin/employee_section/data/models/employee_attendance_history_model.dart';
import 'attendance_time_parser.dart';
import 'showtime.dart';

class AttendanceNotificationBuiltContent {
  const AttendanceNotificationBuiltContent({
    required this.title,
    required this.body,
    required this.mode,
  });

  final String title;
  final String body;
  final String mode;
}

/// Builds persistent-notification text from today's attendance snapshot.
class AttendanceNotificationContent {
  AttendanceNotificationContent._();

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

  static String statusTitle(EmployeeAttendanceDay day, int overtimeMinutes) {
    if (overtimeMinutes > 0) return 'shiftStatusOvertime'.tr;
    return 'shiftStatusWorking'.tr;
  }

  static AttendanceNotificationBuiltContent buildInsideContent({
    required EmployeeAttendanceDay day,
    required String endWorkTime,
    required String numberOfWorkHours,
    required DateTime now,
  }) {
    final live = liveWorkedDuration(day);
    final expected = expectedMinutes(day, numberOfWorkHours);
    final overtimeMin = liveOvertimeMinutes(day, expected);
    final liveClock = AttendanceTimeParser.formatDurationHms(live);
    final workedFmt = formatWorkedDurationMinutes(live.inMinutes);
    final requiredFmt = formatWorkedDurationMinutes(expected);
    final overtimeFmt = formatWorkedDurationMinutes(overtimeMin);
    final onTime = onTimeLabel(day);

    final lines = <String>[
      'attendancePersistentWorkedLine'.trParams({
        'time': liveClock,
        'duration': workedFmt,
      }),
      'attendancePersistentStatsLine'.trParams({
        'required': requiredFmt,
        'overtime': overtimeFmt,
      }),
      'attendancePersistentOnTimeLine'.trParams({'value': onTime}),
    ];

    final end = AttendanceTimeParser.parseToday(endWorkTime);
    var mode = overtimeMin > 0 ? 'overtime' : 'inside';
    if (end != null && now.isBefore(end)) {
      lines.add(
        'attendancePersistentLeaveCountdownLine'.trParams({
          'time': AttendanceTimeParser.formatDurationHms(end.difference(now)),
        }),
      );
      mode = 'countdown';
    } else if (end != null) {
      lines.add('attendancePersistentOvertimeBody'.tr);
    }

    return AttendanceNotificationBuiltContent(
      title: '${statusTitle(day, overtimeMin)} · $liveClock',
      body: lines.join('\n'),
      mode: mode,
    );
  }

  static AttendanceNotificationBuiltContent buildOutsideWithPartialDay(
    EmployeeAttendanceDay day,
    String numberOfWorkHours,
  ) {
    final expected = expectedMinutes(day, numberOfWorkHours);
    final workedFmt = formatWorkedDurationMinutes(day.workedMinutes);
    final requiredFmt = formatWorkedDurationMinutes(expected);
    final overtimeFmt =
        formatWorkedDurationMinutes(math.max(0, day.overtimeMinutes));

    return AttendanceNotificationBuiltContent(
      title: 'attendancePersistentCheckInTitle'.tr,
      body: [
        'attendancePersistentCheckInBody'.tr,
        'attendancePersistentStatsLine'.trParams({
          'required': requiredFmt,
          'overtime': overtimeFmt,
        }),
        'attendancePersistentWorkedTodayLine'.trParams({'duration': workedFmt}),
      ].join('\n'),
      mode: 'check_in_partial',
    );
  }

  static int _parseDailyMinutes(String? hours) {
    if (hours == null || hours.isEmpty || hours == '0') return 0;
    final n = double.tryParse(hours.replaceAll(',', '.'));
    if (n == null) return 0;
    return (n * 60).round();
  }
}
