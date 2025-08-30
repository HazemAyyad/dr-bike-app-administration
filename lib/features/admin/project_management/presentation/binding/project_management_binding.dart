import 'package:get/get.dart';

import '../controllers/project_management_controller.dart';

class ProjectManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProjectManagementController());
  }
}
