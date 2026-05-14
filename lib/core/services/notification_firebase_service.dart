import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
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

  Future<void> intNotification() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (Platform.isAndroid) {
      final String? token = await firebaseMessaging.getToken();
      if (token != null) {
        finalToken = token;
        await GetStorage().write('fcmToken', token);
      }
    } else if (Platform.isIOS) {
      final String? token = await firebaseMessaging.getAPNSToken();
      if (token != null) {
        finalToken = token;
        await GetStorage().write('fcmToken', token);
      }
    }

    firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      finalToken = newToken;
      await GetStorage().write('fcmToken', newToken);
      await _registerAdminDeviceTokenIfPossible(newToken);
    });

    await setupFlutterNotifications();

    await _setupMessageHandler();
  }

  Future<void> _registerAdminDeviceTokenIfPossible(String token) async {
    if (kIsWeb) {
      return;
    }
    if (userType != 'admin') {
      return;
    }
    final saved = await UserData.getUserToken();
    if (saved.isEmpty) {
      return;
    }
    try {
      await AdminNotificationApiService().registerDeviceToken(
        fcmToken: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
        deviceName: Platform.operatingSystem,
      );
    } catch (e, st) {
      debugPrint('FCM token refresh register failed: $e\n$st');
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

    final initializationSettingsDarwin = const DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
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

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title.isEmpty ? 'DoctorBike' : title,
      body,
      details,
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
