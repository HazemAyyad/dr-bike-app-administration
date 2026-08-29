import 'package:get/get.dart';

import '../controllers/admin_notification_settings_controller.dart';

class AdminNotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AdminNotificationSettingsController());
  }
}
