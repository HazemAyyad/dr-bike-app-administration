import 'dart:async';

/// حالة تهيئة Firebase / Supabase من [InitialBindings] — ينتظرها الـ Splash قبل التوجيه.
class AppStartup {
  AppStartup._();

  static bool remoteConfigReady = false;
  static Completer<void>? _remoteCompleter;

  static Future<void> waitRemoteConfig({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (remoteConfigReady) {
      return;
    }
    _remoteCompleter ??= Completer<void>();
    try {
      await _remoteCompleter!.future.timeout(timeout);
    } on TimeoutException {
      // نكمل بالقيم الافتراضية حتى لا تبقى الشاشة عالقة
    }
  }

  static void markRemoteConfigReady() {
    if (remoteConfigReady) {
      return;
    }
    remoteConfigReady = true;
    if (_remoteCompleter != null && !_remoteCompleter!.isCompleted) {
      _remoteCompleter!.complete();
    }
  }
}
