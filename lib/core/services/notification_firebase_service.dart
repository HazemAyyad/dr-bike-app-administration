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
const String kTaskSosSoundResource = 'task_sos_alert';
const String kTaskSosSoundIos = 'task_sos_alert.mp3';

/// SOS-style alert for employee task push notifications.
final Int64List kTaskSosVibrationPattern =
    Int64List.fromList([0, 400, 200, 400, 200, 600]);

/// Employee task-related FCM types (custom urgent sound).
const Set<String> kEmployeeTaskNotificationTypes = {
  'employee_task_assigned',
  'employee_task_approved',
  'employee_task_rejected',
  'employee_task_co_subtask_done',
  'employee_task_co_main_done',
  'employee_task_co_main_completed',
  'employee_task_scheduled_reminder',
  'employee_daily_tasks',
  'employee_hourly_reminder',
  'employee_daily_tasks_complete',
};

bool isEmployeeTaskNotificationType(String? type) =>
    type != null && kEmployeeTaskNotificationTypes.contains(type);

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

    debugPrint(
      '[FCM] Android channels: admin=$kDrBikeAdminNotificationChannelId '
      'task=$kDrBikeTaskNotificationChannelId (sound=$kTaskSosSoundResource)',
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
    final isTaskAlert = isEmployeeTaskNotificationType(type);

    if (isTaskAlert) {
      await _showTrayNotification(message, urgentTask: true);
      _refreshNotificationBadge();
      return;
    }

    await _showTrayNotification(message, urgentTask: false);
  }

  Future<void> _showTrayNotification(
    RemoteMessage message, {
    required bool urgentTask,
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

    final androidDetails = urgentTask
        ? AndroidNotificationDetails(
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
          )
        : AndroidNotificationDetails(
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

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: urgentTask ? kTaskSosSoundIos : null,
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

  Future<void> _setupMessageHandler() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM] foreground message title=${message.notification?.title} '
        'data=${message.data}',
      );
      await showForegroundNotification(message);
      _refreshNotificationBadge();
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
