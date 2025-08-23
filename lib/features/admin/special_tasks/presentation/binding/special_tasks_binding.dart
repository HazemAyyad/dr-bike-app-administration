import 'package:doctorbike/features/admin/special_tasks/data/repositories/special_tasks_implement.dart';
import 'package:get/get.dart';

import '../../domain/usecases/subs_pecial_task_completed_usecase.dart';
import '../../domain/usecases/cancel_special_task_usecase.dart';
import '../../domain/usecases/completed_special_tasks_usecase.dart';
import '../../domain/usecases/special_task_details_usecase.dart';
import '../../domain/usecases/special_tasks_usecase.dart';
import '../controllers/special_tasks_controller.dart';
import '../controllers/special_tasks_service.dart';

class SpecialTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SpecialTasksController(
        specialTasksUsecase: SpecialTasksUsecase(
          specialTasksRepository: Get.find<SpecialTasksImplement>(),
        ),
        specialTasksService: Get.find<SpecialTasksService>(),
        completedSpecialTasksUsecase: CompletedSpecialTasksUsecase(
          specialTasksRepository: Get.find<SpecialTasksImplement>(),
        ),
        specialTaskDetailsUsecase: SpecialTaskDetailsUsecase(
          specialTasksRepository: Get.find<SpecialTasksImplement>(),
        ),
        cancelSpecialTaskUsecase: CancelSpecialTaskUsecase(
          specialTasksRepository: Get.find<SpecialTasksImplement>(),
        ),
        subsSpecialTaskCompletedUsecase: SubsSpecialTaskCompletedUsecase(
          specialTasksRepository: Get.find<SpecialTasksImplement>(),
        ),
      ),
    );
  }
}
