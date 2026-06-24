import 'dart:async';

import 'dart:convert';

import 'dart:io';



import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:get/get.dart';



import '../helpers/attendance_notification_content.dart';
import '../helpers/attendance_time_parser.dart';
import '../helpers/task_recurrence_rules.dart';

import '../../features/admin/employee_section/data/models/employee_attendance_history_model.dart';

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

  String _numberOfWorkHours = '';

  bool _isInside = false;

  EmployeeAttendanceDay? _todayDay;



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

    required String numberOfWorkHours,

    required bool isInside,

    EmployeeAttendanceDay? todayDay,

  }) async {

    if (kIsWeb || userType != 'employee') return;



    _weeklyDaysOff = weeklyDaysOff;

    _endWorkTime = endWorkTime;

    _numberOfWorkHours = numberOfWorkHours;

    _isInside = isInside;

    _todayDay = todayDay;

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

        description: 'إشعار ثابت لتسجيل الدخول وإحصائيات الدوام',

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

      final day = _todayDay;

      if (day != null && day.workedMinutes > 0) {

        final partial = AttendanceNotificationContent.buildOutsideWithPartialDay(

          day,

          _numberOfWorkHours,

        );

        await _activate(

          title: partial.title,

          body: partial.body,

          mode: partial.mode,

        );

        return;

      }



      await _activate(

        title: 'attendancePersistentCheckInTitle'.tr,

        body: 'attendancePersistentCheckInBody'.tr,

        mode: 'check_in',

      );

      return;

    }



    final day = _todayDay;

    if (day != null) {

      final content = AttendanceNotificationContent.buildInsideContent(

        day: day,

        endWorkTime: _endWorkTime,

        numberOfWorkHours: _numberOfWorkHours,

        now: now,

      );

      await _activate(

        title: content.title,

        body: content.body,

        mode: content.mode,

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

      styleInformation: BigTextStyleInformation(

        body,

        contentTitle: title,

        summaryText: 'attendancePersistentChannelName'.tr,

      ),

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


