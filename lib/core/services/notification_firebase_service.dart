import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';

import '../utils/app_colors.dart';

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
      String? token = await firebaseMessaging.getToken();
      if (token != null) {
        // print("FCM Token: $token");
        finalToken = token;
        await GetStorage().write('fcmToken', token);
      }
    } else if (Platform.isIOS) {
      String? token = await firebaseMessaging.getAPNSToken();
      if (token != null) {
        // print("APNS Token: $token");
        finalToken = token;
        await GetStorage().write('fcmToken', token);
      }
    }
    await setupFlutterNotifications();

    await _setupMessageHandler();
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsPluginRegistered) {
      return;
    }

    const channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
      enableVibration: true,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); //ic_launcher

    // ios Setup
    final initializationSettingsDarwin = const DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        // يتم استدعاء هذه الدالة عند الضغط على الإشعار
        final payload = response.payload; // String
        if (payload != null) {
          // print("تم الضغط على الإشعار، البيانات:");

          // Get.to(() => NotificationScreen());
          // إذا أردت تحويلها من String إلى خريطة (Map) لقراءتها:
          // import 'dart:convert';
          // final dataMap = jsonDecode(payload) as Map<String, dynamic>;
          // print("Data as Map: $dataMap");
        }
      },
    );

    _isFlutterLocalNotificationsPluginRegistered = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    // تأكد من تهيئة الإشعارات
    await setupFlutterNotifications();

    // محتوى الإشعار
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = notification?.android;

    if (notification != null && android != null) {
      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel', // channelId
        'High Importance Notifications', // channelName
        channelDescription: 'Used for important notifications',
        importance: Importance.high,
        priority: Priority.high,

        // الأيقونة الصغيرة (small icon)
        icon: '@mipmap/ic_launcher',

        // أيقونة كبيرة (large icon)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),

        color: AppColors.primaryColor,

        // أسلوب عرض النص: BigTextStyle
        styleInformation: BigTextStyleInformation(
          notification.body ?? '',
          htmlFormatBigText: true,
          contentTitle: notification.title ?? '',
          htmlFormatContentTitle: true,
          // summaryText: 'تجربة إشعار متقدم',
          htmlFormatSummaryText: true,
          htmlFormatContent: true,
          htmlFormatTitle: true,
        ),
      );

      // إعدادات iOS (Darwin)
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // إصدار الإشعار
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _setupMessageHandler() async {
    FirebaseMessaging.onMessage.listen((messages) async {
      // final notificationsController = Get.put(NotificationsController());
      // await notificationsController.getNotifications();
      showNotification(messages);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'test') {
      showNotification(message);
    }
  }
}
