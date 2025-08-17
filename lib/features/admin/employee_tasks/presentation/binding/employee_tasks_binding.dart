import 'package:get/get.dart';

import '../../data/repositories/employee_tasks_implement.dart';
import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import '../controllers/employee_task_service.dart';
import '../controllers/employee_tasks_controller.dart';

class EmployeeTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => EmployeeTasksController(
        employeeTasksUsecase: EmployeeTasksUsecase(
          employeeTasksRepository: Get.find<EmployeeTasksImplement>(),
        ),
        employeeTaskService: Get.find<EmployeeTaskService>(),
        cancelEmployeeTaskUsecase: CancelEmployeeTaskUsecase(
            employeeTasksRepository: Get.find<EmployeeTasksImplement>()),
      ),
    );
  }
}
