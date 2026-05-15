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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationFirebaseService.instance.setupFlutterNotifications();
  await NotificationFirebaseService.instance.showNotification(message);
}

class NotificationFirebaseService {
  NotificationFirebaseService._();
  static final NotificationFirebaseService instance =
      NotificationFirebaseService._();
  final firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String finalToken = '';

  bool _isFlutterLocalNotificationsPluginRegistered = false;
  bool _notificationsInitialized = false;

  /// Idempotent setup: permissions, token, local notifications, handlers.
  Future<void> ensureInitialized() async {
    if (_notificationsInitialized) {
      return;
    }
    await intNotification();
    _notificationsInitialized = true;
  }

  Future<void> intNotification() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestNotificationPermissions();

    await _refreshFcmToken();

    firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      debugPrint('[FCM] Token refreshed: $newToken');
      finalToken = newToken;
      await GetStorage().write('fcmToken', newToken);
      await registerAdminDeviceTokenIfReady(source: 'token_refresh');
    });

    await setupFlutterNotifications();

    await _setupMessageHandler();
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
        // FCM on iOS needs APNS registration before getToken() succeeds.
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

  /// Register admin device token when Firebase + auth + admin role are ready.
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
    debugPrint('[FCM] fcm_token=$finalToken');

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
      debugPrint('[FCM] message: ${e.message}');
    } catch (e, st) {
      debugPrint('[FCM] admin/device-token failed: $e\n$st');
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsPluginRegistered) {
      return;
    }

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsDarwin = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final map = AdminNotificationRouter.parsePayload(response.payload);
        if (map.isNotEmpty) {
          AdminNotificationRouter.handlePayload(map);
        }
      },
    );

    _isFlutterLocalNotificationsPluginRegistered = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    await setupFlutterNotifications();

    final RemoteNotification? notification = message.notification;

    final String title = notification?.title ??
        message.data['title']?.toString() ??
        'DoctorBike';
    final String body =
        notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty && message.data.isEmpty) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: AppColors.primaryColor,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
        htmlFormatContent: true,
        htmlFormatTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final String payload = jsonEncode(message.data);

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title.isEmpty ? 'DoctorBike' : title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
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
    FirebaseMessaging.onMessage.listen((RemoteMessage messages) async {
      await showNotification(messages);
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
    if (message.data.isEmpty) {
      return;
    }
    AdminNotificationRouter.handlePayload(
      Map<String, dynamic>.from(message.data),
    );
  }
}
