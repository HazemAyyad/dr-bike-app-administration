import 'package:get/get.dart';

import '../../../../../core/services/admin_notification_api_service.dart';
import '../../../../../core/services/initial_bindings.dart';

class AdminNotificationBadgeController extends GetxController {
  final unreadCount = 0.obs;

  Future<void> refresh() async {
    if (userType != 'admin') {
      unreadCount.value = 0;
      return;
    }
    try {
      unreadCount.value =
          await AdminNotificationApiService().fetchUnreadCount();
    } catch (_) {
      // keep previous count
    }
  }
}
