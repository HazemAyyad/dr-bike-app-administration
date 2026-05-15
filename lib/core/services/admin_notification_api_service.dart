import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart' hide Response;

import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';

/// Admin notification center + device token (requires admin Bearer token).
class AdminNotificationApiService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<int> fetchUnreadCount() async {
    final Response res =
        await _api.get(EndPoints.adminNotificationsUnreadCount);
    final dynamic d = res.data;
    if (d is Map && d['unread_count'] != null) {
      return int.tryParse(d['unread_count'].toString()) ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>> fetchNotifications({
    int page = 1,
    int perPage = 20,
    String? type,
    bool? unreadOnly,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, dynamic> q = {
      'page': page,
      'per_page': perPage,
    };
    if (type != null && type.isNotEmpty && type != 'all') {
      q['type'] = type;
    }
    if (unreadOnly == true) {
      q['unread_only'] = '1';
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      q['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      q['date_to'] = dateTo;
    }
    final Response res = await _api.get(
      EndPoints.adminNotifications,
      queryParameters: q,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> markAsRead(int id) async {
    await _api.post(EndPoints.adminNotificationMarkRead(id));
  }

  Future<void> markAllAsRead() async {
    await _api.post(EndPoints.adminNotificationsMarkAllRead);
  }

  Future<void> deleteNotification(int id) async {
    await _api.delete(EndPoints.adminNotificationDelete(id));
  }

  /// Returns response body map on success for logging.
  Future<Map<String, dynamic>?> registerDeviceToken({
    required String fcmToken,
    required String platform,
    String? deviceName,
  }) async {
    final Response res = await _api.post(
      EndPoints.adminDeviceToken,
      data: {
        'fcm_token': fcmToken,
        'platform': platform,
        if (deviceName != null && deviceName.isNotEmpty)
          'device_name': deviceName,
      },
    );
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    debugPrint('[FCM] admin/device-token status=${res.statusCode}');
    return null;
  }

  Future<void> deleteDeviceToken(String fcmToken) async {
    await _api.delete(
      EndPoints.adminDeviceToken,
      data: {'fcm_token': fcmToken},
    );
  }
}
