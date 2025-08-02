import 'package:get/get.dart';

import '../controllers/employee_tasks_controller.dart';


class EmployeeTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeeTasksController());
  }
}
