import 'package:get/get.dart';

import '../controllers/employee_section_controller.dart';

class EmployeeSectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeeSectionController());
  }
}
