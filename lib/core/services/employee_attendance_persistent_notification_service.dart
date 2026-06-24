import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../helpers/attendance_time_parser.dart';
import '../helpers/task_recurrence_rules.dart';
import '../../routes/app_routes.dart';
import 'initial_bindings.dart';
import 'notification_firebase_service.dart';

/// Persistent attendance strip (Android foreground / iOS limited refresh).
class EmployeeAttendancePersistentNotificationService {
  EmployeeAttendancePersistentNotificationService._();

  static final EmployeeAttendancePersistentNotificationService instance =
      EmployeeAttendancePersistentNotificationService._();

  static const notificationId = 88001;
  static const channelId = 'dr_bike_employee_attendance_status';
  static const payloadType = 'employee_attendance_persistent';

  Timer? _tickTimer;
  bool _foregroundActive = false;
  bool _iosBannerShown = false;

  List<String> _weeklyDaysOff = const [];
  String _endWorkTime = '';
  bool _isInside = false;

  Future<void> initializeForEmployee() async {
    if (kIsWeb || userType != 'employee') return;
    await NotificationFirebaseService.instance.ensureInitialized();
    await NotificationFirebaseService.instance.setupFlutterNotifications();
    await _ensureChannel();
    await syncFromSession();
  }

  Future<void> stop({String reason = 'manual'}) async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _foregroundActive = false;
    _iosBannerShown = false;

    final plugin = NotificationFirebaseService.instance.localNotificationsPlugin;
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
    if (kIsWeb || userType != 'employee') {
      await stop(reason: 'not_employee');
      return;
    }
    await _renderOrStop();
  }

  Future<void> sync({
    required List<String> weeklyDaysOff,
    required String endWorkTime,
    required bool isInside,
  }) async {
    if (kIsWeb || userType != 'employee') return;

    _weeklyDaysOff = weeklyDaysOff;
    _endWorkTime = endWorkTime;
    _isInside = isInside;
    await _renderOrStop();
  }

  Future<void> _ensureChannel() async {
    if (!Platform.isAndroid) return;
    final android = NotificationFirebaseService.instance.localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'حضور الدوام',
        description: 'إشعار ثابت لتسجيل الدخول والعد التنازلي للانصراف',
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

  Future<void> _renderOrStop() async {
    final now = DateTime.now();

    if (_isWeeklyDayOff(now)) {
      await stop(reason: 'weekly_day_off');
      return;
    }

    if (!_isInside) {
      await _activate(
        title: 'attendancePersistentCheckInTitle'.tr,
        body: 'attendancePersistentCheckInBody'.tr,
        mode: 'check_in',
      );
      return;
    }

    final end = AttendanceTimeParser.parseToday(_endWorkTime);
    if (end == null) {
      await _activate(
        title: 'attendancePersistentInsideTitle'.tr,
        body: 'stillInside'.tr,
        mode: 'inside',
      );
      return;
    }

    if (!now.isBefore(end)) {
      await _activate(
        title: 'attendancePersistentOvertimeTitle'.tr,
        body: 'attendancePersistentOvertimeBody'.tr,
        mode: 'overtime',
      );
      return;
    }

    final remaining = end.difference(now);
    await _activate(
      title: 'attendancePersistentCountdownTitle'.tr,
      body: AttendanceTimeParser.formatDurationHms(remaining),
      mode: 'countdown',
    );
  }

  Future<void> _activate({
    required String title,
    required String body,
    required String mode,
  }) async {
    final payload = jsonEncode({
      'type': payloadType,
      'mode': mode,
      'route': AppRoutes.FULLSCREENQRSCANNER,
    });

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'attendancePersistentChannelName'.tr,
      channelDescription: 'attendancePersistentChannelDesc'.tr,
      icon: 'ic_notification',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.status,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: !_iosBannerShown,
      presentBadge: false,
      presentSound: false,
      threadIdentifier: channelId,
    );
    _iosBannerShown = true;

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final plugin = NotificationFirebaseService.instance.localNotificationsPlugin;

    if (Platform.isAndroid) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (!_foregroundActive) {
        await android?.startForegroundService(
          notificationId,
          title,
          body,
          notificationDetails: androidDetails,
          payload: payload,
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeDataSync,
          },
        );
        _foregroundActive = true;
      } else {
        await plugin.show(
          notificationId,
          title,
          body,
          details,
          payload: payload,
        );
      }
    } else if (Platform.isIOS) {
      await plugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    }

    _startTicker();
  }

  void _startTicker() {
    if (_tickTimer != null) return;
    final interval = Platform.isIOS
        ? const Duration(seconds: 30)
        : const Duration(seconds: 1);
    _tickTimer = Timer.periodic(interval, (_) {
      _renderOrStop();
    });
  }

  static void handlePayload(Map<String, dynamic> data) {
    if (data['type']?.toString() != payloadType) return;
    if (userType != 'employee') return;
    Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);
  }
}
