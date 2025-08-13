import 'package:doctorbike/features/admin/employee_section/domain/usecases/add_employee_usecase.dart';
import 'package:get/get.dart';

import '../../data/repositorie_imp/employee_section_implement.dart';
import '../../domain/usecases/add_points_usecase.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';
import '../controllers/add_employee_controller.dart';
import '../controllers/employee_section_controller.dart';

class EmployeeSectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => EmployeeSectionController(
        paySalaryEmployee: PaySalaryToEmployeeUsecase(
            employeeRepository: Get.find<EmployeeImplement>()),
      ),
    );
    Get.lazyPut(
      () => AddEmployeeController(
        employeeUsecase: AddEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        addPointsUsecase: AddPointsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
      ),
    );
  }
}
