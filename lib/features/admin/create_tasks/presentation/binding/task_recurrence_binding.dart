import 'package:get/get.dart';

import '../controllers/create_task_controller.dart';
import 'create_task_binding.dart';

/// Reuses [CreateTaskController] from the create/edit screen — never replaces it.
class TaskRecurrenceBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CreateTaskController>()) {
      CreateTaskBinding().dependencies();
    }
  }
}
