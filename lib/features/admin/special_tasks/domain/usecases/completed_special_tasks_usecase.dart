import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/special_tasks_repository.dart';

class CompletedSpecialTasksUsecase {
  final SpecialTasksRepository specialTasksRepository;

  CompletedSpecialTasksUsecase({required this.specialTasksRepository});

  Future<Either<Failure, String>> call({required String specialTaskId}) {
    return specialTasksRepository.completedSpecialTasks(
      specialTaskId: specialTaskId,
    );
  }
}
