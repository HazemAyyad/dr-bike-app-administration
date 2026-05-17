import 'package:get/get.dart';

import '../controllers/employee_notification_center_controller.dart';

class EmployeeNotificationCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeeNotificationCenterController());
  }
}
