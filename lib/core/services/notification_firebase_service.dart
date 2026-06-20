import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../firebase_options.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import '../utils/app_colors.dart';
import '../../features/employee/notifications/presentation/controllers/employee_notification_badge_controller.dart';
import 'admin_notification_api_service.dart';
import 'admin_notification_router.dart';
import 'employee_notification_router.dart';
import 'initial_bindings.dart';
import 'user_data.dart';

/// Must match Laravel [FirebaseService::ADMIN_CHANNEL_ID] and AndroidManifest.
/// google-services.json project_id should match [DefaultFirebaseOptions] projectId.
const String kDrBikeAdminNotificationChannelId = 'dr_bike_admin_notifications';
const String kDrBikeAdminNotificationChannelName = 'Dr Bike Notifications';

/// Must match Laravel [FirebaseService::EMPLOYEE_TASK_CHANNEL_ID] and res/raw/task_sos_alert.
const String kDrBikeTaskNotificationChannelId = 'dr_bike_task_notifications';
const String kDrBikeTaskNotificationChannelName = 'Dr Bike Task Alerts';

/// Must match Laravel [FirebaseService::ADMIN_LOGIN_CHANNEL_ID].
const String kDrBikeAdminLoginChannelId = 'dr_bike_admin_login_alerts';
const String kDrBikeAdminLoginChannelName = 'تسجيل دخول الموظفين';

/// Must match Laravel [FirebaseService::ADMIN_ATTENDANCE_CHANNEL_ID] (logout).
const String kDrBikeAdminAttendanceChannelId = 'dr_bike_admin_attendance_alerts';
const String kDrBikeAdminAttendanceChannelName = 'تنبيهات خروج الموظفين';

/// Must match Laravel [FirebaseService::TASK_SUCCESS_CHANNEL_ID] and res/raw/task_success.
const String kDrBikeTaskSuccessChannelId = 'dr_bike_task_success_notifications';
const String kDrBikeTaskSuccessChannelName = 'إنجاز المهام';

/// Must match Laravel [FirebaseService::SHIPLY_MOTORCYCLE_CHANNEL_ID].
const String kDrBikeShiplyMotorcycleChannelId = 'dr_bike_shiply_motorcycle';
const String kDrBikeShiplyMotorcycleChannelName = 'تحديثات شبلي';

/// Must match Laravel [FirebaseService::SHIPLY_STUCK_CHANNEL_ID].
const String kDrBikeShiplyStuckChannelId = 'dr_bike_shiply_stuck_alert';
const String kDrBikeShiplyStuckChannelName = 'شبلي — عالقة';

/// Must match Laravel [FirebaseService::SHIPLY_RETURNED_CHANNEL_ID].
const String kDrBikeShiplyReturnedChannelId = 'dr_bike_shiply_returned_ambulance';
const String kDrBikeShiplyReturnedChannelName = 'شبلي — راجع';

/// Must match Laravel [FirebaseService::SHIPLY_DELIVERED_CHANNEL_ID].
const String kDrBikeShiplyDeliveredChannelId = 'dr_bike_shiply_delivered_finale';
const String kDrBikeShiplyDeliveredChannelName = 'توصيل شبلي';

/// Must match Laravel [FirebaseService::SALES_ORDER_STATUS_CHANNEL_ID].
const String kDrBikeSalesOrderStatusChannelId = 'dr_bike_sales_order_status';
const String kDrBikeSalesOrderStatusChannelName = 'تحديثات الطلبيات';

const int kShiplyParcelStatusPending = 5;
const int kShiplyParcelStatusReturned = 7;

const String kTaskSosSoundResource = 'task_sos_alert';
const String kTaskSosSoundIos = 'task_sos_alert.mp3';
const String kTaskSuccessSoundResource = 'task_success';
const String kTaskSuccessSoundIos = 'task_success.wav';
const String kShiplyMotorcycleSoundResource = 'shiply_motorcycle';
const String kShiplyMotorcycleSoundIos = 'shiply_motorcycle.wav';
const String kShiplyStuckSoundResource = 'shiply_stuck';
const String kShiplyStuckSoundIos = 'shiply_stuck.wav';
const String kShiplyReturnedSoundResource = 'shiply_returned';
const String kShiplyReturnedSoundIos = 'shiply_returned.wav';
const String kShiplyDeliveredSoundResource = 'shiply_delivered';
const String kShiplyDeliveredSoundIos = 'shiply_delivered.wav';
const String kSalesOrderChurchBellSoundResource = 'sales_order_church_bell';
const String kSalesOrderChurchBellSoundIos = 'sales_order_church_bell.wav';
const String kAdminLoginMotivateSoundResource = 'admin_login_motivate';
const String kAdminLoginMotivateSoundIos = 'admin_login_motivate.wav';

/// SOS-style alert for employee task push notifications.
final Int64List kTaskSosVibrationPattern =
    Int64List.fromList([0, 400, 200, 400, 200, 600]);

/// Gentle vibration for task completion.
final Int64List kTaskSuccessVibrationPattern =
    Int64List.fromList([0, 100, 60, 140]);

/// Motorcycle-style vibration for Shiply tracking updates.
final Int64List kShiplyMotorcycleVibrationPattern =
    Int64List.fromList([0, 120, 80, 160, 80, 140]);

/// Crash-style vibration for stuck/pending Shiply parcels.
final Int64List kShiplyStuckVibrationPattern =
    Int64List.fromList([0, 500, 200, 600, 200, 500]);

/// Ambulance-style vibration for returned Shiply parcels.
final Int64List kShiplyReturnedVibrationPattern =
    Int64List.fromList([0, 280, 140, 280, 140, 280, 140, 320]);

/// Celebration vibration for Shiply delivered (coins + whistle).
final Int64List kShiplyDeliveredVibrationPattern =
    Int64List.fromList([0, 70, 50, 90, 50, 110, 80, 200, 100, 260]);

/// Energetic vibration for admin login (motivational).
final Int64List kAdminLoginMotivateVibrationPattern =
    Int64List.fromList([0, 180, 90, 180, 90, 280]);

/// Church-bell style vibration for sales order status changes.
final Int64List kSalesOrderStatusVibrationPattern =
    Int64List.fromList([0, 220, 120, 280, 120, 320]);

/// Urgent employee task FCM types (SOS tone).
const Set<String> kEmployeeTaskUrgentNotificationTypes = {
  'employee_task_assigned',
  'employee_task_rejected',
  'employee_task_scheduled_reminder',
  'employee_daily_tasks',
  'employee_hourly_reminder',
  'employee_operational_reminder',
};

/// Task completion / success FCM types.
const Set<String> kTaskSuccessNotificationTypes = {
  'employee_task_approved',
  'employee_task_co_subtask_done',
  'employee_task_co_main_done',
  'employee_task_co_main_completed',
  'employee_daily_tasks_complete',
  'employee_task_completed',
  'employee_task_submitted',
  'employee_subtask_completed',
};

/// Admin login FCM types (motivational loud tone).
const Set<String> kAdminLoginNotificationTypes = {
  'employee_login',
};

/// Admin logout FCM types (alarm sound).
const Set<String> kAdminLogoutNotificationTypes = {
  'employee_logout',
  'employee_logout_pending_tasks',
};

/// Shiply handover / tracking FCM types (sound depends on parcel_status_id).
const Set<String> kShiplyTrackingNotificationTypes = {
  'sales_order_shiply_handover',
  'sales_order_shiply_status',
};

/// Shiply delivered FCM type (coins + end whistle).
const Set<String> kShiplyDeliveredNotificationTypes = {
  'sales_order_shiply_delivered',
};

/// Sales order manual status change FCM type (church bell).
const Set<String> kSalesOrderStatusNotificationTypes = {
  'sales_order_status',
};

/// All Shiply admin notification types.
const Set<String> kShiplyNotificationTypes = {
  ...kShiplyTrackingNotificationTypes,
  ...kShiplyDeliveredNotificationTypes,
};

bool isEmployeeTaskUrgentNotificationType(String? type) =>
    type != null && kEmployeeTaskUrgentNotificationTypes.contains(type);

bool isTaskSuccessNotificationType(String? type) =>
    type != null && kTaskSuccessNotificationTypes.contains(type);

bool isAdminLoginNotificationType(String? type) =>
    type != null && kAdminLoginNotificationTypes.contains(type);

bool isAdminLogoutNotificationType(String? type) =>
    type != null && kAdminLogoutNotificationTypes.contains(type);

bool isShiplyNotificationType(String? type) =>
    type != null && kShiplyNotificationTypes.contains(type);

bool isShiplyTrackingNotificationType(String? type) =>
    type != null && kShiplyTrackingNotificationTypes.contains(type);

bool isShiplyDeliveredNotificationType(String? type) =>
    type != null && kShiplyDeliveredNotificationTypes.contains(type);

bool isSalesOrderStatusNotificationType(String? type) =>
    type != null && kSalesOrderStatusNotificationTypes.contains(type);

_TrayAlertStyle? resolveShiplyTrayStyle(String type, Map<String, dynamic> data) {
  if (isShiplyDeliveredNotificationType(type)) {
    return _TrayAlertStyle.shiplyDelivered;
  }
  if (!isShiplyTrackingNotificationType(type)) {
    return null;
  }

  final statusId =
      int.tryParse(data['parcel_status_id']?.toString() ?? '') ?? 0;
  if (statusId == kShiplyParcelStatusReturned) {
    return _TrayAlertStyle.shiplyReturned;
  }
  if (statusId == kShiplyParcelStatusPending) {
    return _TrayAlertStyle.shiplyStuck;
  }

  return _TrayAlertStyle.shiplyMotorcycle;
}

enum _TrayAlertStyle {
  normal,
  employeeTaskUrgent,
  taskSuccess,
  adminLogin,
  adminLogout,
  shiplyMotorcycle,
  shiplyStuck,
  shiplyReturned,
  shiplyDelivered,
  salesOrderStatus,
}

/// google-services.json (android/app) — compare with [DefaultFirebaseOptions.android.projectId].
const String kGoogleServicesProjectIdHint = 'drbike-7fa3a';

class NotificationFirebaseService {
  NotificationFirebaseService._();
  static final NotificationFirebaseService instance =
      NotificationFirebaseService._();
  final firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String finalToken = '';

  bool _isFlutterLocalNotificationsPluginRegistered = false;
  bool _notificationsInitialized = false;
  bool _notificationsDenied = false;

  bool get notificationsDenied => _notificationsDenied;

  bool get isInitialized => _notificationsInitialized;

  Future<void> ensureInitialized() async {
    if (_notificationsInitialized) {
      return;
    }
    await intNotification();
    _notificationsInitialized = true;
  }

  Future<void> intNotification() async {
    _logFirebaseProjectDiagnostics();
    await _requestNotificationPermissions();
    await setupFlutterNotifications();
    await _logAndroidChannelDiagnostics();
    await _refreshFcmToken();

    firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      debugPrint('[FCM] Token refreshed: $newToken');
      finalToken = newToken;
      await GetStorage().write('fcmToken', newToken);
      await syncFcmTokenToServer(source: 'token_refresh');
    });

    await _setupMessageHandler();
    debugPrint(
      '[FCM] Notification service ready (channel=$kDrBikeAdminNotificationChannelId)',
    );
  }

  void _logFirebaseProjectDiagnostics() {
    if (kIsWeb) {
      return;
    }
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      debugPrint(
        '[FCM] Flutter DefaultFirebaseOptions.projectId=${options.projectId}',
      );
      debugPrint(
        '[FCM] Flutter messagingSenderId=${options.messagingSenderId}',
      );
      debugPrint(
        '[FCM] android/app/google-services.json project_id (expected): $kGoogleServicesProjectIdHint',
      );
      if (options.projectId != kGoogleServicesProjectIdHint) {
        debugPrint(
          '[FCM] *** PROJECT MISMATCH WARNING *** '
          'DefaultFirebaseOptions.projectId (${options.projectId}) != '
          'google-services.json ($kGoogleServicesProjectIdHint). '
          'FCM tokens will not receive pushes from Laravel if service account uses a different project.',
        );
      }
      debugPrint(
        '[FCM] Laravel FIREBASE_CREDENTIALS project_id must match Flutter projectId above.',
      );
    } catch (e) {
      debugPrint('[FCM] Firebase project diagnostics error: $e');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (kIsWeb) {
      return;
    }

    if (Platform.isAndroid) {
      final permissionStatus = await Permission.notification.status;
      debugPrint('[FCM] Permission.notification.status=$permissionStatus');

      if (!permissionStatus.isGranted) {
        final requestResult = await Permission.notification.request();
        debugPrint('[FCM] Permission.notification.request()=$requestResult');
      }

      final afterStatus = await Permission.notification.status;
      debugPrint('[FCM] Permission.notification.status (after)=$afterStatus');

      final fcmSettings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[FCM] FirebaseMessaging.requestPermission authorizationStatus=${fcmSettings.authorizationStatus}',
      );

      final notificationSettings =
          await firebaseMessaging.getNotificationSettings();
      debugPrint(
        '[FCM] FirebaseMessaging.getNotificationSettings() '
        'authorizationStatus=${notificationSettings.authorizationStatus} '
        'alert=${notificationSettings.alert} '
        'badge=${notificationSettings.badge} '
        'sound=${notificationSettings.sound}',
      );

      _notificationsDenied = afterStatus.isDenied || afterStatus.isPermanentlyDenied;
      if (_notificationsDenied) {
        debugPrint(
          '[FCM] Notifications are denied. Enable them from app settings.',
        );
        if (afterStatus.isPermanentlyDenied) {
          debugPrint('[FCM] Permission permanently denied — call openAppSettings()');
        }
      }
    }

    if (Platform.isIOS) {
      final settings = await firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint(
        '[FCM] iOS requestPermission: ${settings.authorizationStatus}',
      );
      final notificationSettings =
          await firebaseMessaging.getNotificationSettings();
      debugPrint(
        '[FCM] iOS getNotificationSettings: ${notificationSettings.authorizationStatus}',
      );
      _notificationsDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;
      if (_notificationsDenied) {
        debugPrint(
          '[FCM] Notifications are denied. Enable them from app settings.',
        );
      }
      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Opens system app settings (Android 13+ notification toggle).
  Future<void> openNotificationSettings() async {
    debugPrint('[FCM] Opening app settings for notification permission');
    await openAppSettings();
  }

  Future<void> _logAndroidChannelDiagnostics() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      final channels = await androidPlugin?.getNotificationChannels();
      if (channels == null || channels.isEmpty) {
        debugPrint('[FCM] No Android notification channels reported yet');
        return;
      }
      for (final ch in channels) {
        debugPrint(
          '[FCM] Android channel id=${ch.id} name=${ch.name} '
          'importance=${ch.importance} playSound=${ch.playSound}',
        );
        if (ch.id == kDrBikeAdminNotificationChannelId) {
          debugPrint(
            '[FCM] Target channel OK: importance=${ch.importance} (max=${Importance.max})',
          );
        }
      }
    } catch (e) {
      debugPrint('[FCM] Channel diagnostics error: $e');
    }
  }

  Future<void> _refreshFcmToken() async {
    if (kIsWeb) {
      debugPrint('[FCM] Web platform — skipping device token');
      return;
    }
    try {
      if (Platform.isIOS) {
        var apns = await firebaseMessaging.getAPNSToken();
        if (apns == null) {
          for (var i = 0; i < 5 && apns == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            apns = await firebaseMessaging.getAPNSToken();
          }
        }
        debugPrint(
          '[FCM] APNS token: ${apns == null || apns.isEmpty ? "pending" : "ok"}',
        );
      }

      if (Platform.isAndroid && !_notificationsDenied) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      final String? token = await firebaseMessaging
          .getToken()
          .timeout(const Duration(seconds: 8));
      finalToken = token ?? '';
      debugPrint(
        '[FCM] FCM token: ${finalToken.isEmpty ? "null/empty" : finalToken}',
      );
      if (finalToken.isNotEmpty) {
        await GetStorage().write('fcmToken', finalToken);
      }
    } catch (e, st) {
      debugPrint('[FCM] Failed to get token: $e\n$st');
    }
  }

  /// انتظار توكن FCM قبل أول تسجيل دخول (بعد منح الإذن قد يتأخر ثوانٍ).
  Future<String> resolveTokenForLogin({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (kIsWeb) {
      return 'no_token';
    }

    await ensureInitialized();

    final cached = GetStorage().read<String>('fcmToken');
    if (cached != null && cached.isNotEmpty) {
      finalToken = cached;
      return cached;
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await _refreshFcmToken();
      if (finalToken.isNotEmpty) {
        return finalToken;
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    debugPrint('[FCM] resolveTokenForLogin: timeout — using no_token');
    return 'no_token';
  }

  /// مزامنة التوكن مع السيرفر (موظف أو أدمن) بعد توفره.
  Future<void> syncFcmTokenToServer({required String source}) async {
    if (kIsWeb) {
      return;
    }

    await ensureInitialized();

    final authToken = await UserData.getUserToken();
    if (authToken.isEmpty) {
      debugPrint('[FCM] Skip sync ($source): no auth token');
      return;
    }

    if (finalToken.isEmpty) {
      await _refreshFcmToken();
    }
    var token = finalToken;
    if (token.isEmpty) {
      token = await resolveTokenForLogin(timeout: const Duration(seconds: 8));
    }
    if (token.isEmpty || token == 'no_token') {
      debugPrint('[FCM] Skip sync ($source): FCM still empty');
      return;
    }

    final url = '${EndPoints.baserUrl}${EndPoints.updateFcmToken}';
    debugPrint('[FCM] POST $url (source=$source)');

    try {
      if (!Get.isRegistered<DioConsumer>()) {
        debugPrint('[FCM] Skip sync ($source): DioConsumer not ready');
        return;
      }
      final api = Get.find<DioConsumer>();
      final response = await api.post(
        EndPoints.updateFcmToken,
        data: {
          'fcm_token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'device_name': Platform.operatingSystem,
        },
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        debugPrint('[FCM] syncFcmTokenToServer OK ($source)');
      }
    } on DioException catch (e) {
      debugPrint(
        '[FCM] syncFcmTokenToServer DioException status=${e.response?.statusCode}',
      );
    } catch (e, st) {
      debugPrint('[FCM] syncFcmTokenToServer failed: $e\n$st');
    }

    if (userType == 'admin') {
      await registerAdminDeviceTokenIfReady(source: source);
    }
  }

  Future<void> registerAdminDeviceTokenIfReady({required String source}) async {
    if (kIsWeb) {
      debugPrint('[FCM] Skip admin device-token ($source): web');
      return;
    }

    await ensureInitialized();

    if (userType != 'admin') {
      debugPrint('[FCM] Skip admin device-token ($source): userType=$userType');
      return;
    }

    final authToken = await UserData.getUserToken();
    if (authToken.isEmpty) {
      debugPrint(
        '[FCM] Skip admin device-token ($source): auth token missing',
      );
      return;
    }

    if (finalToken.isEmpty) {
      await _refreshFcmToken();
    }
    if (finalToken.isEmpty) {
      debugPrint('[FCM] Skip admin device-token ($source): FCM token empty');
      return;
    }

    final url = '${EndPoints.baserUrl}${EndPoints.adminDeviceToken}';
    debugPrint('[FCM] POST $url (source=$source)');

    try {
      final response = await AdminNotificationApiService().registerDeviceToken(
        fcmToken: finalToken,
        platform: Platform.isAndroid ? 'android' : 'ios',
        deviceName: Platform.operatingSystem,
      );
      debugPrint('[FCM] admin/device-token success (source=$source)');
      if (response != null) {
        debugPrint('[FCM] response: $response');
      }
    } on DioException catch (e) {
      debugPrint(
        '[FCM] admin/device-token DioException status=${e.response?.statusCode}',
      );
      debugPrint('[FCM] response body: ${e.response?.data}');
    } catch (e, st) {
      debugPrint('[FCM] admin/device-token failed: $e\n$st');
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsPluginRegistered) {
      return;
    }

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    const adminChannel = AndroidNotificationChannel(
      kDrBikeAdminNotificationChannelId,
      kDrBikeAdminNotificationChannelName,
      description: 'DoctorBike admin alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(adminChannel);

    final taskChannel = AndroidNotificationChannel(
      kDrBikeTaskNotificationChannelId,
      kDrBikeTaskNotificationChannelName,
      description: 'Urgent employee task alerts (SOS tone)',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(kTaskSosSoundResource),
      enableVibration: true,
      vibrationPattern: kTaskSosVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(taskChannel);

    final attendanceChannel = AndroidNotificationChannel(
      kDrBikeAdminAttendanceChannelId,
      kDrBikeAdminAttendanceChannelName,
      description: 'تنبيهات خروج الموظفين (صوت إنذار)',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(kTaskSosSoundResource),
      enableVibration: true,
      vibrationPattern: kTaskSosVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(attendanceChannel);

    final adminLoginChannel = AndroidNotificationChannel(
      kDrBikeAdminLoginChannelId,
      kDrBikeAdminLoginChannelName,
      description: 'صوت تحفيزي عالي عند تسجيل دخول الموظف',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        kAdminLoginMotivateSoundResource,
      ),
      enableVibration: true,
      vibrationPattern: kAdminLoginMotivateVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(adminLoginChannel);

    final taskSuccessChannel = AndroidNotificationChannel(
      kDrBikeTaskSuccessChannelId,
      kDrBikeTaskSuccessChannelName,
      description: 'صوت نجاح عند إتمام المهام',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(kTaskSuccessSoundResource),
      enableVibration: true,
      vibrationPattern: kTaskSuccessVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(taskSuccessChannel);

    final shiplyMotorcycleChannel = AndroidNotificationChannel(
      kDrBikeShiplyMotorcycleChannelId,
      kDrBikeShiplyMotorcycleChannelName,
      description: 'صوت درّاجة نارية (بنزين) لتحديثات شبلي',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        kShiplyMotorcycleSoundResource,
      ),
      enableVibration: true,
      vibrationPattern: kShiplyMotorcycleVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(shiplyMotorcycleChannel);

    final shiplyStuckChannel = AndroidNotificationChannel(
      kDrBikeShiplyStuckChannelId,
      kDrBikeShiplyStuckChannelName,
      description: 'صوت حادث عند تعثر الطرد مع شبلي',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(kShiplyStuckSoundResource),
      enableVibration: true,
      vibrationPattern: kShiplyStuckVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(shiplyStuckChannel);

    final shiplyReturnedChannel = AndroidNotificationChannel(
      kDrBikeShiplyReturnedChannelId,
      kDrBikeShiplyReturnedChannelName,
      description: 'صوت إسعاف عند رجوع الطرد من شبلي',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        kShiplyReturnedSoundResource,
      ),
      enableVibration: true,
      vibrationPattern: kShiplyReturnedVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(shiplyReturnedChannel);

    final shiplyDeliveredChannel = AndroidNotificationChannel(
      kDrBikeShiplyDeliveredChannelId,
      kDrBikeShiplyDeliveredChannelName,
      description: 'عملات معدنية + صفارة نهاية عند توصيل شبلي',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(kShiplyDeliveredSoundResource),
      enableVibration: true,
      vibrationPattern: kShiplyDeliveredVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(shiplyDeliveredChannel);

    final salesOrderStatusChannel = AndroidNotificationChannel(
      kDrBikeSalesOrderStatusChannelId,
      kDrBikeSalesOrderStatusChannelName,
      description: 'جرس كنيسة عند تغيير مرحلة الطلبية',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        kSalesOrderChurchBellSoundResource,
      ),
      enableVibration: true,
      vibrationPattern: kSalesOrderStatusVibrationPattern,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(salesOrderStatusChannel);

    debugPrint(
      '[FCM] Android channels: admin=$kDrBikeAdminNotificationChannelId '
      'task=$kDrBikeTaskNotificationChannelId login=$kDrBikeAdminLoginChannelId '
      'logout=$kDrBikeAdminAttendanceChannelId success=$kDrBikeTaskSuccessChannelId '
      'shiplyMotor=$kDrBikeShiplyMotorcycleChannelId shiplyStuck=$kDrBikeShiplyStuckChannelId '
      'shiplyReturned=$kDrBikeShiplyReturnedChannelId '
      'delivered=$kDrBikeShiplyDeliveredChannelId '
      'salesOrderStatus=$kDrBikeSalesOrderStatusChannelId',
    );

    const initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const initializationSettingsDarwin = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final map = AdminNotificationRouter.parsePayload(response.payload);
        _routeNotificationPayload(map);
      },
    );

    _isFlutterLocalNotificationsPluginRegistered = true;
  }

  /// Debug: local notification without Firebase (channel/permission/icon test).
  Future<void> showLocalTestNotification() async {
    if (_notificationsDenied) {
      debugPrint(
        '[FCM] Local test skipped — notifications denied. Enable from app settings.',
      );
      Get.snackbar(
        'Notifications',
        'Notifications are denied. Enable them from app settings.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: openNotificationSettings,
          child: const Text('Settings'),
        ),
      );
      return;
    }

    await setupFlutterNotifications();

    const androidDetails = AndroidNotificationDetails(
      kDrBikeAdminNotificationChannelId,
      kDrBikeAdminNotificationChannelName,
      channelDescription: 'DoctorBike admin alerts',
      icon: 'ic_notification',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      color: AppColors.primaryColor,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _flutterLocalNotificationsPlugin.show(
      999001,
      'DoctorBike Local Test',
      'Local notification channel test',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode({'type': 'admin_manual', 'source': 'local_test'}),
    );
    debugPrint('[FCM] showLocalTestNotification() displayed');
    await _logAndroidChannelDiagnostics();
  }

  Future<void> showForegroundNotification(RemoteMessage message) async {
    final type = message.data['type']?.toString() ?? '';
    final shiplyStyle = resolveShiplyTrayStyle(type, message.data);
    final _TrayAlertStyle style;
    if (isAdminLoginNotificationType(type)) {
      style = _TrayAlertStyle.adminLogin;
    } else if (isAdminLogoutNotificationType(type)) {
      style = _TrayAlertStyle.adminLogout;
    } else if (shiplyStyle != null) {
      style = shiplyStyle;
    } else if (isSalesOrderStatusNotificationType(type)) {
      style = _TrayAlertStyle.salesOrderStatus;
    } else if (isTaskSuccessNotificationType(type)) {
      style = _TrayAlertStyle.taskSuccess;
    } else if (isEmployeeTaskUrgentNotificationType(type)) {
      style = _TrayAlertStyle.employeeTaskUrgent;
    } else {
      style = _TrayAlertStyle.normal;
    }

    await _showTrayNotification(message, style: style);
    _refreshNotificationBadge();
  }

  Future<void> _showTrayNotification(
    RemoteMessage message, {
    required _TrayAlertStyle style,
  }) async {
    await setupFlutterNotifications();

    final RemoteNotification? notification = message.notification;
    final String title = notification?.title ??
        message.data['title']?.toString() ??
        'DoctorBike';
    final String body =
        notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final AndroidNotificationDetails androidDetails;
    if (style == _TrayAlertStyle.employeeTaskUrgent) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeTaskNotificationChannelId,
        kDrBikeTaskNotificationChannelName,
        channelDescription: 'Urgent employee task alerts',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kTaskSosSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kTaskSosVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.taskSuccess) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeTaskSuccessChannelId,
        kDrBikeTaskSuccessChannelName,
        channelDescription: 'صوت نجاح عند إتمام المهام',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kTaskSuccessSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kTaskSuccessVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.adminLogin) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeAdminLoginChannelId,
        kDrBikeAdminLoginChannelName,
        channelDescription: 'صوت تحفيزي عند تسجيل دخول الموظف',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kAdminLoginMotivateSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kAdminLoginMotivateVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.adminLogout) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeAdminAttendanceChannelId,
        kDrBikeAdminAttendanceChannelName,
        channelDescription: 'تنبيهات خروج الموظفين',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kTaskSosSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kTaskSosVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.shiplyMotorcycle) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeShiplyMotorcycleChannelId,
        kDrBikeShiplyMotorcycleChannelName,
        channelDescription: 'صوت درّاجة نارية (بنزين) لتحديثات شبلي',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kShiplyMotorcycleSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kShiplyMotorcycleVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.shiplyStuck) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeShiplyStuckChannelId,
        kDrBikeShiplyStuckChannelName,
        channelDescription: 'صوت حادث عند تعثر الطرد مع شبلي',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kShiplyStuckSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kShiplyStuckVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.shiplyReturned) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeShiplyReturnedChannelId,
        kDrBikeShiplyReturnedChannelName,
        channelDescription: 'صوت إسعاف عند رجوع الطرد من شبلي',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kShiplyReturnedSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kShiplyReturnedVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.shiplyDelivered) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeShiplyDeliveredChannelId,
        kDrBikeShiplyDeliveredChannelName,
        channelDescription: 'عملات معدنية + صفارة نهاية عند توصيل شبلي',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kShiplyDeliveredSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kShiplyDeliveredVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else if (style == _TrayAlertStyle.salesOrderStatus) {
      androidDetails = AndroidNotificationDetails(
        kDrBikeSalesOrderStatusChannelId,
        kDrBikeSalesOrderStatusChannelName,
        channelDescription: 'جرس كنيسة عند تغيير مرحلة الطلبية',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          kSalesOrderChurchBellSoundResource,
        ),
        enableVibration: true,
        vibrationPattern: kSalesOrderStatusVibrationPattern,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        kDrBikeAdminNotificationChannelId,
        kDrBikeAdminNotificationChannelName,
        channelDescription: 'DoctorBike admin alerts',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        color: AppColors.primaryColor,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );
    }

    final String? iosSound;
    if (style == _TrayAlertStyle.taskSuccess) {
      iosSound = kTaskSuccessSoundIos;
    } else if (style == _TrayAlertStyle.shiplyDelivered) {
      iosSound = kShiplyDeliveredSoundIos;
    } else if (style == _TrayAlertStyle.shiplyMotorcycle) {
      iosSound = kShiplyMotorcycleSoundIos;
    } else if (style == _TrayAlertStyle.shiplyStuck) {
      iosSound = kShiplyStuckSoundIos;
    } else if (style == _TrayAlertStyle.shiplyReturned) {
      iosSound = kShiplyReturnedSoundIos;
    } else if (style == _TrayAlertStyle.salesOrderStatus) {
      iosSound = kSalesOrderChurchBellSoundIos;
    } else if (style == _TrayAlertStyle.adminLogin) {
      iosSound = kAdminLoginMotivateSoundIos;
    } else if (style == _TrayAlertStyle.employeeTaskUrgent ||
        style == _TrayAlertStyle.adminLogout) {
      iosSound = kTaskSosSoundIos;
    } else {
      iosSound = null;
    }

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: iosSound,
    );

    final payload = jsonEncode(_payloadFromMessage(message));

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode.abs() % 0x7FFFFFFF,
      title.isEmpty ? 'DoctorBike' : title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  static Map<String, dynamic> _payloadFromMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      return Map<String, dynamic>.from(message.data);
    }
    return {
      if (message.notification?.title != null)
        'title': message.notification!.title!,
      if (message.notification?.body != null)
        'body': message.notification!.body!,
    };
  }

  void _refreshNotificationBadge() {
    if (userType == 'admin' &&
        Get.isRegistered<AdminNotificationBadgeController>()) {
      Get.find<AdminNotificationBadgeController>().refresh();
    }
    if (userType == 'employee' &&
        Get.isRegistered<EmployeeNotificationBadgeController>()) {
      Get.find<EmployeeNotificationBadgeController>().refresh();
    }
  }

  void _routeNotificationPayload(Map<String, dynamic> data) {
    if (userType == 'employee') {
      EmployeeNotificationRouter.handlePayload(data);
    } else {
      AdminNotificationRouter.handlePayload(data);
    }
  }

  void _handleEmployeeSalesDailyForeground(Map<String, dynamic> data) {
    if (userType != 'employee') return;

    final type = data['type']?.toString() ?? '';
    switch (type) {
      case EmployeeNotificationRouter.typeReopenApproved:
        EmployeeNotificationRouter.openSalesAndRefreshDailySession(
          successMessage: 'salesDailyReopenApproved'.tr,
        );
        break;
      case EmployeeNotificationRouter.typeReopenRejected:
        EmployeeNotificationRouter.openSalesAndRefreshDailySession(
          infoMessage: 'salesDailyReopenRejected'.tr,
        );
        break;
      case EmployeeNotificationRouter.typeClosingApproved:
        EmployeeNotificationRouter.openSalesAndRefreshDailySession(
          infoMessage: 'salesDailyDayClosed'.tr,
        );
        break;
      case EmployeeNotificationRouter.typeClosingRejected:
        EmployeeNotificationRouter.openSalesAndRefreshDailySession(
          infoMessage: 'salesDailyClosingRejected'.tr,
        );
        break;
    }
  }

  Future<void> _setupMessageHandler() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM] foreground message title=${message.notification?.title} '
        'data=${message.data}',
      );
      await showForegroundNotification(message);
      _refreshNotificationBadge();
      _handleEmployeeSalesDailyForeground(_payloadFromMessage(message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final RemoteMessage? initialMessage =
        await firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        _handleOpenedMessage(initialMessage);
      });
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint('[FCM] notification opened app');
    final data = _payloadFromMessage(message);
    _routeNotificationPayload(data);
    _refreshNotificationBadge();
  }
}
