import 'package:get/get.dart';

import '../../../../employee_section/data/repositorie_imp/employee_section_implement.dart';
import '../../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../../employee_section/presentation/controllers/employee_service.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DashboardController(
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeService: Get.find<EmployeeService>(),
      ),
    );
  }
}
