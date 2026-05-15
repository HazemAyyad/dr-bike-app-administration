import 'package:get/get.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../data/datasources/employee_tasks_datasource.dart';
import '../../data/repositories/employee_tasks_implement.dart';
import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import '../../domain/usecases/get_task_details_usecase.dart';
import '../../domain/usecases/upload_task_image_usecase.dart';
import '../controllers/employee_task_service.dart';
import '../controllers/employee_tasks_controller.dart';

class EmployeeTasksBinding extends Bindings {
  void _ensureDependencies() {
    if (!Get.isRegistered<EmployeeTasksDatasource>()) {
      Get.lazyPut<EmployeeTasksDatasource>(
        () => EmployeeTasksDatasource(api: Get.find<DioConsumer>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<EmployeeTasksImplement>()) {
      Get.lazyPut<EmployeeTasksImplement>(
        () => EmployeeTasksImplement(
          networkInfo: Get.find<NetworkInfo>(),
          employeeTasksDataSource: Get.find<EmployeeTasksDatasource>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<EmployeeTaskService>()) {
      Get.lazyPut<EmployeeTaskService>(
        () => EmployeeTaskService(),
        fenix: true,
      );
    }
  }

  @override
  void dependencies() {
    _ensureDependencies();

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
