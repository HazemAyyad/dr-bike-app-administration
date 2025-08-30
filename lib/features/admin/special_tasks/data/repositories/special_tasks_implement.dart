import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/special_tasks/data/models/special_task_details_model.dart';
import 'package:doctorbike/features/admin/special_tasks/data/models/special_task_model.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/special_tasks_repository.dart';
import '../datasources/special_tasks_datasource.dart';

class SpecialTasksImplement implements SpecialTasksRepository {
  final NetworkInfo networkInfo;
  final SpecialTasksDatasource specialTasksDatasource;

  SpecialTasksImplement(
      {required this.networkInfo, required this.specialTasksDatasource});

  // get special tasks
  @override
  Future<List<SpecialTaskModel>> specialTasks({required String page}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await specialTasksDatasource.getSpecialTasks(page: page);

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw [];
    }
  }

  @override
  Future<Either<Failure, String>> completedSpecialTasks(
      {required String specialTaskId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await specialTasksDatasource.completedSpecialTasks(
        specialTaskId: specialTaskId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<SpecialTaskDetailsModel> getSpecialTasksDetails(
      {required String specialTaskId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await specialTasksDatasource.getSpecialTasksDetails(
            specialTaskId: specialTaskId);

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw [];
    }
  }

  @override
  Future<Either<Failure, String>> cancelSpecialTask({
    required String specialTaskId,
    required bool repitition,
    required bool isTransfer,
    DateTime? endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await specialTasksDatasource.cancelSpecialTask(
        specialTaskId: specialTaskId,
        repitition: repitition,
        isTransfer: isTransfer,
        endDate: endDate,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  //  اكمال المهمة
  @override
  Future<Either<Failure, String>> subSpecialTaskCompleted(
      {required String subTaskId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await specialTasksDatasource.subSpecialTaskCompleted(
        subTaskId: subTaskId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
