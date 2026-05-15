import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../databases/api/end_points.dart';
import '../utils/app_colors.dart';
import 'admin_notification_api_service.dart';
import 'admin_notification_router.dart';
import 'initial_bindings.dart';
import 'user_data.dart';

/// Must match Laravel [FirebaseService::ADMIN_CHANNEL_ID] and AndroidManifest metadata.
const String kDrBikeAdminNotificationChannelId = 'dr_bike_admin_notifications';
const String kDrBikeAdminNotificationChannelName = 'Dr Bike Notifications';

class NotificationFirebaseService {
  NotificationFirebaseService._();
  static final NotificationFirebaseService instance =
      NotificationFirebaseService._();
  final firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String finalToken = '';

  bool _isFlutterLocalNotificationsPluginRegistered = false;
  bool _notificationsInitialized = false;

  /// Idempotent setup: permissions, channel, token, local notifications, handlers.
  Future<void> ensureInitialized() async {
    if (_notificationsInitialized) {
      return;
    }
    await intNotification();
    _notificationsInitialized = true;
  }

  Future<void> intNotification() async {
    await _requestNotificationPermissions();
    await setupFlutterNotifications();
    await _refreshFcmToken();

    firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      debugPrint('[FCM] Token refreshed: $newToken');
      finalToken = newToken;
      await GetStorage().write('fcmToken', newToken);
      await registerAdminDeviceTokenIfReady(source: 'token_refresh');
    });

    await _setupMessageHandler();
    debugPrint('[FCM] Notification service ready (channel=$kDrBikeAdminNotificationChannelId)');
  }

  Future<void> _requestNotificationPermissions() async {
    if (kIsWeb) {
      return;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      debugPrint('[FCM] Android POST_NOTIFICATIONS status: $status');
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        debugPrint('[FCM] Android POST_NOTIFICATIONS request: $result');
      }
      final fcmSettings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[FCM] Firebase requestPermission (Android): ${fcmSettings.authorizationStatus}',
      );
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
        '[FCM] iOS notification permission: ${settings.authorizationStatus}',
      );
      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
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

      final String? token = await firebaseMessaging.getToken();
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

    const channel = AndroidNotificationChannel(
      kDrBikeAdminNotificationChannelId,
      kDrBikeAdminNotificationChannelName,
      description: 'DoctorBike admin alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    debugPrint('[FCM] Android notification channel created: $kDrBikeAdminNotificationChannelId');

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
        AdminNotificationRouter.handlePayload(map);
      },
    );

    _isFlutterLocalNotificationsPluginRegistered = true;
  }

  /// Foreground only — background/killed use FCM notification payload from backend.
  Future<void> showForegroundNotification(RemoteMessage message) async {
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

    final androidDetails = AndroidNotificationDetails(
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

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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

  void _refreshAdminBadge() {
    if (userType != 'admin') {
      return;
    }
    if (Get.isRegistered<AdminNotificationBadgeController>()) {
      Get.find<AdminNotificationBadgeController>().refresh();
    }
  }

  Future<void> _setupMessageHandler() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM] foreground message title=${message.notification?.title}',
      );
      await showForegroundNotification(message);
      _refreshAdminBadge();
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
    AdminNotificationRouter.handlePayload(data);
  }
}
