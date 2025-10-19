import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/special_tasks_repository.dart';

class SubsSpecialTaskCompletedUsecase {
  final SpecialTasksRepository specialTasksRepository;

  SubsSpecialTaskCompletedUsecase({required this.specialTasksRepository});

  Future<Either<Failure, String>> call({
    required String subTaskId,
  }) {
    return specialTasksRepository.subSpecialTaskCompleted(
      subTaskId: subTaskId,
    );
  }
}
