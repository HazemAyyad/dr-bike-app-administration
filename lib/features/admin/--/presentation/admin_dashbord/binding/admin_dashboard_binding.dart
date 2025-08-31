import 'package:get/get.dart';

import '../../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../../employee_section/domain/usecases/get_all_employee.dart';
import '../controllers/admin_dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DashboardController(
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        // employeeService: Get.find<EmployeeService>(),
      ),
    );
  }
}
