import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:get/get.dart';

import '../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../data/repositories/employee_tasks_implement.dart';
import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import '../../domain/usecases/get_task_details_usecase.dart';
import '../../domain/usecases/upload_task_image_usecase.dart';
import '../controllers/employee_task_service.dart';
import '../controllers/employee_tasks_controller.dart';

class EmployeeTasksBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureEmployeeTasks();
    AppDependencyRegistry.ensureEmployeeSection();
    Get.lazyPut(
      () => GetAllEmployeeUsecase(employeeRepository: Get.find<EmployeeImplement>()),
    );

    Get.lazyPut(
      () => EmployeeTasksController(
        employeeTasksUsecase: EmployeeTasksUsecase(
          employeeTasksRepository: Get.find<EmployeeTasksImplement>(),
        ),
        employeeTaskService: Get.find<EmployeeTaskService>(),
        cancelEmployeeTaskUsecase: CancelEmployeeTaskUsecase(
          employeeTasksRepository: Get.find<EmployeeTasksImplement>(),
        ),
        getTaskDetailsUsecase: GetTaskDetailsUsecase(
          employeeTasksRepository: Get.find<EmployeeTasksImplement>(),
        ),
        uploadTaskImageUsecase: UploadTaskImageUsecase(
          employeeTasksRepository: Get.find<EmployeeTasksImplement>(),
        ),
      ),
    );
  }
}
