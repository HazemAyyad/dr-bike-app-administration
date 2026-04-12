import '../errors/failure.dart';

/// رسائل خطأ آمنة للعرض للمستخدم (خصوصاً على الويب حيث toString قد يعطي TypeError/JS).
String apiErrorMessageFromPayload(
  dynamic message, {
  String fallback = 'حدث خطأ غير معروف',
}) {
  if (message == null) return fallback;
  if (message is String) {
    final t = message.trim();
    if (t.isEmpty) return fallback;
    if (_isTechnicalNoise(t)) {
      return 'تعذر الاتصال بالسيرفر أو إكمال الطلب. تحقق من الشبكة، من إعدادات CORS على الباكند، ثم حدّث الصفحة.';
    }
    return t;
  }
  if (message is Map) {
    final parts = <String>[];
    message.forEach((key, value) {
      if (value is List) {
        for (final item in value) {
          parts.add(item.toString());
        }
      } else {
        parts.add(value.toString());
      }
    });
    final joined = parts.where((s) => s.trim().isNotEmpty).join('\n');
    if (joined.isEmpty) return fallback;
    if (_isTechnicalNoise(joined)) return fallback;
    return joined;
  }
  if (message is List) {
    final joined = message.map((e) => e.toString()).join('\n');
    if (joined.trim().isEmpty) return fallback;
    if (_isTechnicalNoise(joined)) return fallback;
    return joined;
  }
  try {
    final s = message.toString();
    if (s.trim().isEmpty || _isTechnicalNoise(s)) return fallback;
    return s;
  } catch (_) {
    return fallback;
  }
}

bool _isTechnicalNoise(String s) {
  final l = s.toLowerCase();
  return l.contains('typeerror') ||
      l.contains('javascriptobject') ||
      l.contains('firebaseexception') ||
      l.contains('core/no-app') ||
      l.startsWith('instance of ');
}

/// رسالة من [Failure] للعرض في واجهة تسجيل الدخول وغيرها.
String userFacingMessageFromFailure(Failure failure) {
  if (failure is NoConnectionFailure) {
    return failure.errMessage;
  }
  if (failure.data is Map) {
    final m = failure.data as Map;
    final fromApi = apiErrorMessageFromPayload(
      m['message'],
      fallback: '',
    );
    if (fromApi.isNotEmpty) return fromApi;
  }
  return apiErrorMessageFromPayload(
    failure.errMessage,
    fallback: 'تعذر تسجيل الدخول. تحقق من البيانات والاتصال.',
  );
}
