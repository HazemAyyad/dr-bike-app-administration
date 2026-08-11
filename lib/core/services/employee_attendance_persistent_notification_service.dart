import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../helpers/attendance_notification_content.dart';
import '../helpers/attendance_time_parser.dart';
import '../helpers/task_recurrence_rules.dart';
import '../../features/admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../../routes/app_routes.dart';
import 'initial_bindings.dart';
import 'impersonation_state.dart';
import 'notification_firebase_service.dart';

/// Attendance reminder notification.
class EmployeeAttendancePersistentNotificationService {
  EmployeeAttendancePersistentNotificationService._();

  static final EmployeeAttendancePersistentNotificationService instance =
      EmployeeAttendancePersistentNotificationService._();

  static const notificationId = 88001;
  static const channelId = 'dr_bike_employee_attendance_status';
  static const payloadType = 'employee_attendance_persistent';

  bool _iosBannerShown = false;

  List<String> _weeklyDaysOff = const [];
  String _startWorkTime = '';
  String _endWorkTime = '';
  String _numberOfWorkHours = '';
  bool _isInside = false;
  EmployeeAttendanceDay? _todayDay;

  Future<void> initializeForEmployee() async {
    if (kIsWeb ||
        userType != 'employee' ||
        ImpersonationState.isAdminImpersonatingEmployee) {
      await stop(reason: 'not_real_employee_session');
      return;
    }
    await NotificationFirebaseService.instance.ensureInitialized();
    await NotificationFirebaseService.instance.setupFlutterNotifications();
    await _ensureChannel();
    await syncFromSession();
  }

  Future<void> stop({String reason = 'manual'}) async {
    _iosBannerShown = false;

    final plugin =
        NotificationFirebaseService.instance.localNotificationsPlugin;
    if (Platform.isAndroid) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.stopForegroundService();
      } catch (_) {}
    }
    try {
      await plugin.cancel(notificationId);
    } catch (_) {}
    debugPrint('[AttendanceNotif] stopped ($reason)');
  }

  Future<void> syncFromSession() async {
    if (kIsWeb ||
        userType != 'employee' ||
        ImpersonationState.isAdminImpersonatingEmployee) {
      await stop(reason: 'not_employee');
      return;
    }
    await _renderOrStop();
  }

  Future<void> sync({
    required List<String> weeklyDaysOff,
    required String startWorkTime,
    required String endWorkTime,
    required String numberOfWorkHours,
    required bool isInside,
    EmployeeAttendanceDay? todayDay,
  }) async {
    if (kIsWeb ||
        userType != 'employee' ||
        ImpersonationState.isAdminImpersonatingEmployee) {
      await stop(reason: 'not_real_employee_session');
      return;
    }

    _weeklyDaysOff = weeklyDaysOff;
    _startWorkTime = startWorkTime;
    _endWorkTime = endWorkTime;
    _numberOfWorkHours = numberOfWorkHours;
    _isInside = isInside;
    _todayDay = todayDay;
    await _renderOrStop();
  }

  Future<void> _ensureChannel() async {
    if (!Platform.isAndroid) return;
    final android = NotificationFirebaseService
        .instance.localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'حضور الدوام',
        description: 'تذكير تسجيل الدخول وإحصائيات الدوام',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );
  }

  bool _isWeeklyDayOff(DateTime day) {
    return !TaskRecurrenceRules.isEmployeeWorkingDay(day, _weeklyDaysOff);
  }

  AttendanceNotificationBuiltContent _buildContent(DateTime now) {
    if (!_isInside) {
      final day = _todayDay;
      if (day != null && day.workedMinutes > 0) {
        return AttendanceNotificationContent.buildOutsideWithPartialDay(
          day,
          _numberOfWorkHours,
        );
      }
      return AttendanceNotificationContent.buildCheckInContent();
    }

    final day = _todayDay;
    if (day != null) {
      return AttendanceNotificationContent.buildInsideContent(
        day: day,
        startWorkTime: _startWorkTime,
        endWorkTime: _endWorkTime,
        numberOfWorkHours: _numberOfWorkHours,
        now: now,
      );
    }

    final end = AttendanceTimeParser.parseToday(_endWorkTime);
    if (end == null) {
      return AttendanceNotificationBuiltContent(
        title: 'attendancePersistentInsideTitle'.tr,
        summary:
            '${AttendanceNotificationContent.badge('attendanceNotifBadgeWorking')} ${'stillInside'.tr}',
        inboxLines: const [],
        mode: 'inside',
        accentArgb: AttendanceNotificationContent.accentWorking,
      );
    }

    if (!now.isBefore(end)) {
      return AttendanceNotificationBuiltContent(
        title: 'attendancePersistentOvertimeTitle'.tr,
        summary:
            '${AttendanceNotificationContent.badge('attendanceNotifBadgeOvertime')} ${'attendancePersistentOvertimeBody'.tr}',
        inboxLines: const [],
        mode: 'overtime',
        accentArgb: AttendanceNotificationContent.accentOvertime,
      );
    }

    final remaining =
        AttendanceTimeParser.formatDurationHms(end.difference(now));
    return AttendanceNotificationBuiltContent(
      title: remaining,
      summary:
          '${AttendanceNotificationContent.badge('attendanceNotifBadgeWorking')} ${'attendancePersistentCountdownTitle'.tr}',
      inboxLines: const [],
      mode: 'countdown',
      accentArgb: AttendanceNotificationContent.accentWorking,
    );
  }

  Future<void> _renderOrStop() async {
    final now = DateTime.now();

    if (_isWeeklyDayOff(now)) {
      await stop(reason: 'weekly_day_off');
      return;
    }

    await _activate(_buildContent(now));
  }

  StyleInformation? _buildStyle(AttendanceNotificationBuiltContent content) {
    return BigTextStyleInformation(
      content.summary,
      contentTitle: content.title,
      summaryText: 'attendancePersistentChannelName'.tr,
      htmlFormatBigText: false,
      htmlFormatContentTitle: false,
      htmlFormatSummaryText: false,
    );
  }

  Future<void> _activate(AttendanceNotificationBuiltContent content) async {
    final payload = jsonEncode({
      'type': payloadType,
      'mode': content.mode,
      'route': AppRoutes.FULLSCREENQRSCANNER,
    });

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'attendancePersistentChannelName'.tr,
      channelDescription: 'attendancePersistentChannelDesc'.tr,
      icon: 'ic_notification',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: false,
      autoCancel: true,
      timeoutAfter: 15000,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.status,
      color: Color(content.accentArgb),
      colorized: false,
      styleInformation: _buildStyle(content),
    );

    final iosBody = content.inboxLines.isEmpty
        ? content.summary
        : [content.summary, ...content.inboxLines].join('\n');

    final iosDetails = DarwinNotificationDetails(
      presentAlert: !_iosBannerShown,
      presentBadge: false,
      presentSound: false,
      threadIdentifier: channelId,
      subtitle: content.summary,
    );
    _iosBannerShown = true;

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final plugin =
        NotificationFirebaseService.instance.localNotificationsPlugin;
    final title = content.title;
    final body = content.summary;

    if (Platform.isAndroid) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.stopForegroundService();
      } catch (_) {}
      await plugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } else if (Platform.isIOS) {
      await plugin.show(
        notificationId,
        title,
        iosBody,
        details,
        payload: payload,
      );
    }
  }

  static void handlePayload(Map<String, dynamic> data) {
    if (data['type']?.toString() != payloadType) return;
    if (userType != 'employee' ||
        ImpersonationState.isAdminImpersonatingEmployee) {
      return;
    }
    Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);
  }
}
