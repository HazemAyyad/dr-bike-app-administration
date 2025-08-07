import 'package:get/get.dart';

import '../controllers/special_tasks_controller.dart';

class SpecialTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SpecialTasksController());
  }
}
