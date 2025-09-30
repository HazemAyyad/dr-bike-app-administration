import 'package:get/get.dart';

import '../../../../admin/debts/data/repositories/debts_implement.dart';
import '../../../../admin/debts/domain/usecases/get_debts_reports_usecase.dart';
import '../../data/repositories/employee_dashbord_implement.dart';
import '../../domain/usecases/change_task_completed_uasecase.dart';
import '../../domain/usecases/get_employee_data_usecase.dart';
import '../../domain/usecases/request_over_time_loan_usecase.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeDashbordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => EmployeeDashbordController(
        requestOverTimeLoanUsecase: RequestOverTimeLoanUsecase(
          employeeDashbordRepository: Get.find<EmployeeDashbordImplement>(),
        ),
        getEmployeeDataUsecase: GetEmployeeDataUsecase(
          employeeDashbordRepository: Get.find<EmployeeDashbordImplement>(),
        ),
        changeTaskCompletedUasecase: ChangeTaskCompletedUasecase(
          employeeDashbordRepository: Get.find<EmployeeDashbordImplement>(),
        ),
        getDebtsReports: GetDebtsReportsUsecase(
          debtsRepository: Get.find<DebtsImplement>(),
        ),
      ),
    );
  }
}
