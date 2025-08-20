import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/special_task_details_model.dart';
import '../../data/models/special_task_model.dart';

abstract class SpecialTasksRepository {
  Future<List<SpecialTaskModel>> specialTasks({required String page});

  Future<Either<Failure, String>> completedSpecialTasks(
      {required String specialTaskId});

  Future<SpecialTaskDetailsModel> getSpecialTasksDetails(
      {required String specialTaskId});

  Future<Either<Failure, String>> cancelSpecialTask({
    required String specialTaskId,
    required bool repitition,
    required bool isTransfer,
    DateTime? endDate,
  });
}
