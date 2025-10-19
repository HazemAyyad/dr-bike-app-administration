import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/special_tasks_repository.dart';

class CancelSpecialTaskUsecase {
  final SpecialTasksRepository specialTasksRepository;

  CancelSpecialTaskUsecase({required this.specialTasksRepository});

  Future<Either<Failure, String>> call({
    required String specialTaskId,
    required bool repitition,
    required bool isTransfer,
    DateTime? endDate,
  }) {
    return specialTasksRepository.cancelSpecialTask(
      specialTaskId: specialTaskId,
      repitition: repitition,
      isTransfer: isTransfer,
      endDate: endDate,
    );
  }
}
