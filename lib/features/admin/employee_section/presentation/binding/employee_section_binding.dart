import 'package:doctorbike/features/admin/employee_section/domain/usecases/add_employee_usecase.dart';
import 'package:doctorbike/features/admin/employee_section/domain/usecases/get_all_employee.dart';
import 'package:get/get.dart';

import '../../data/repositorie_imp/employee_implement.dart';
import '../../domain/usecases/add_points_usecase.dart';
import '../../domain/usecases/employee_details_usecase.dart';
import '../../domain/usecases/financial_details_usecase.dart';
import '../../domain/usecases/financial_dues.usecase.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';
import '../../domain/usecases/qr_generation_usecase.dart';
import '../../domain/usecases/working_times_usecase.dart';
import '../controllers/add_employee_controller.dart';
import '../controllers/employee_section_controller.dart';
import '../controllers/employee_service.dart';

class EmployeeSectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => EmployeeSectionController(
        paySalaryEmployee: PaySalaryToEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeService: Get.find<EmployeeService>(),
        workingTimesUsecase: WorkingTimesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        financialDuesUsecase: FinancialDuesUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        financialDetailsUsecase: FinancialDetailsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeDetailsUsecase: EmployeeDetailsUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        qrGenerationUsecase: QrGenerationUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
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
        employeeService: Get.find<EmployeeService>(),
      ),
    );
  }
}
