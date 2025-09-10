import 'package:get/get.dart';

import '../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../employee_section/domain/usecases/cancel_log_usecase.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../../domain/usecases/get_admin_logs_usecase.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AdminDashboardController(
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        getAdminLogsUsecase: GetAdminLogsUsecase(
          adminDashboardRepository: Get.find<AdminDashboardRepository>(),
        ),
        cancelLogUsecase: CancelLogUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
    );
  }
}
