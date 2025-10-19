import '../../data/models/special_task_model.dart';
import '../repositories/special_tasks_repository.dart';

class SpecialTasksUsecase {
  final SpecialTasksRepository specialTasksRepository;

  SpecialTasksUsecase({required this.specialTasksRepository});

  Future<List<SpecialTaskModel>> call({required String page}) {
    return specialTasksRepository.specialTasks(page: page);
  }
}
