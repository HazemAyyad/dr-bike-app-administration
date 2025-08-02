import 'package:doctorbike/features/admin/--/data/repositories/admin_implement.dart';
import 'package:get/get.dart';

import '../../../--/domain/usecases/special_tasks_usecase.dart';
import '../controllers/create_task_controller.dart';

class CreateTaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CreateTaskController(
        creatSpecialTasksUsecase: CreatSpecialTasksUsecase(
          adminRepository: Get.find<AdminImplement>(),
        ),
      ),
    );
  }
}
