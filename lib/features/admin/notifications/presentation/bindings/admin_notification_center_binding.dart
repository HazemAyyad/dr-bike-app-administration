import 'package:get/get.dart';

import '../controllers/admin_notification_center_controller.dart';

class AdminNotificationCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AdminNotificationCenterController());
  }
}
