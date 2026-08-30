import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/admin/employee_section/data/models/employee_attendance_history_model.dart';
import 'notification_firebase_service.dart';

/// Keeps the former attendance notification API available while the feature is
/// disabled. Every entry point also clears any notification left by an older
/// app version.
class EmployeeAttendancePersistentNotificationService {
  EmployeeAttendancePersistentNotificationService._();

  static final EmployeeAttendancePersistentNotificationService instance =
      EmployeeAttendancePersistentNotificationService._();

  static const notificationId = 88001;
  static const payloadType = 'employee_attendance_persistent';

  Future<void> initializeForEmployee() =>
      stop(reason: 'attendance_status_notification_disabled');

  Future<void> syncFromSession() =>
      stop(reason: 'attendance_status_notification_disabled');

  Future<void> sync({
    required List<String> weeklyDaysOff,
    required String startWorkTime,
    required String endWorkTime,
    required String numberOfWorkHours,
    required bool isInside,
    EmployeeAttendanceDay? todayDay,
  }) =>
      stop(reason: 'attendance_status_notification_disabled');

  Future<void> stop({String reason = 'manual'}) async {
    if (kIsWeb) return;

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

  /// Ignore taps from a notification created by an older app version.
  static void handlePayload(Map<String, dynamic> data) {}
}
