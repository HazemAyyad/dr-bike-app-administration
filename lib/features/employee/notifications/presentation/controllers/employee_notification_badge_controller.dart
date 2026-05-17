import 'package:get/get.dart';

import '../../../../../core/services/employee_notification_api_service.dart';
import '../../../../../core/services/initial_bindings.dart';

class EmployeeNotificationBadgeController extends GetxController {
  final unreadCount = 0.obs;

  @override
  Future<void> refresh() async {
    if (userType != 'employee') {
      unreadCount.value = 0;
      return;
    }
    try {
      unreadCount.value =
          await EmployeeNotificationApiService().fetchUnreadCount();
    } catch (_) {}
  }
}
