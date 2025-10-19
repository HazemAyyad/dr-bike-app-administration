import 'package:get/get.dart';

import '../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../../../employee_tasks/presentation/controllers/employee_task_service.dart';
import '../../../special_tasks/presentation/controllers/special_tasks_service.dart';
import '../../data/repositories/employee_tasks_implement.dart';
import '../../domain/usecases/creat_special_tasks_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../controllers/create_task_controller.dart';

class CreateTaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CreateTaskController(
        createTaskUsecase: CreateTaskUsecase(
          employeeTasksRepository: Get.find<CreateEmployeeTasksImplement>(),
        ),
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        employeeService: Get.find<EmployeeService>(),
        creatSpecialTasksUsecase: CreatSpecialTasksUsecase(
          createEmployeeTasksRepository:
              Get.find<CreateEmployeeTasksImplement>(),
        ),
        specialTasksService: Get.find<SpecialTasksService>(),
        employeeTaskService: Get.find<EmployeeTaskService>(),
      ),
    );
  }
}
