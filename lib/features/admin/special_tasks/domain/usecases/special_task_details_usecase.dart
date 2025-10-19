import '../../data/models/special_task_details_model.dart';
import '../repositories/special_tasks_repository.dart';

class SpecialTaskDetailsUsecase {
  final SpecialTasksRepository specialTasksRepository;

  SpecialTaskDetailsUsecase({required this.specialTasksRepository});

  Future<SpecialTaskDetailsModel> call({required String specialTaskId}) {
    return specialTasksRepository.getSpecialTasksDetails(
      specialTaskId: specialTaskId,
    );
  }
}
