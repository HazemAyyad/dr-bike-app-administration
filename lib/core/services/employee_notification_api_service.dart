import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';

class EmployeeNotificationApiService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<int> fetchUnreadCount() async {
    final Response res =
        await _api.get(EndPoints.employeeNotificationsUnreadCount);
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
    final Response res = await _api.get(
      EndPoints.employeeNotifications,
      queryParameters: q,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> markAsRead(int id) async {
    await _api.post(EndPoints.employeeNotificationMarkRead(id));
  }

  Future<void> markAllAsRead() async {
    await _api.post(EndPoints.employeeNotificationsMarkAllRead);
  }

  Future<void> deleteNotification(int id) async {
    await _api.delete(EndPoints.employeeNotificationDelete(id));
  }
}
