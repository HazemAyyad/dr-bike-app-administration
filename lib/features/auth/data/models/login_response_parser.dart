import 'package:doctorbike/core/databases/api/end_points.dart';

/// يدعم شكل الاستجابة المباشر:
/// `{ status, token, user, employee_permissions }`
/// وأيضاً الشكل الملفوف مستقبلاً:
/// `{ status, data: { token, user, employee_permissions } }`
Map<String, dynamic> unwrapLoginEnvelope(Map<String, dynamic> raw) {
  final nested = raw[ApiKey.data];
  if (nested is Map) {
    final m = Map<String, dynamic>.from(nested);
    if (raw.containsKey(ApiKey.status)) {
      m[ApiKey.status] = raw[ApiKey.status];
    }
    if (raw.containsKey('message')) {
      m['message'] = raw['message'];
    }
    return m;
  }
  return Map<String, dynamic>.from(raw);
}

bool isLoginSuccessStatus(dynamic status) {
  if (status == 'success') return true;
  if (status == true) return true;
  if (status == 1 || status == '1') return true;
  return false;
}
