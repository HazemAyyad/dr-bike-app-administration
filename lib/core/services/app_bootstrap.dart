import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import '../../firebase_options.dart';
import 'notification_firebase_service.dart';

/// تهيئة Firebase + طلب إذن الإشعارات عند أول فتح للتطبيق (قبل Splash/Login).
class AppBootstrap {
  AppBootstrap._();

  static bool _mobileReady = false;

  static bool get isMobileReady => _mobileReady;

  static Future<void> initializeMobile() async {
    if (kIsWeb || _mobileReady) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('[FCM] Firebase initialized (app bootstrap)');
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
      debugPrint('[FCM] Firebase already initialized (duplicate-app ignored)');
    }

    try {
      await NotificationFirebaseService.instance
          .ensureInitialized()
          .timeout(const Duration(seconds: 12));
    } catch (e, st) {
      debugPrint('[FCM] ensureInitialized failed or timed out: $e\n$st');
    }
    _mobileReady = true;
    debugPrint('[FCM] Notifications ready at app launch');
  }
}
