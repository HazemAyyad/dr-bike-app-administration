import 'package:dartz/dartz.dart';

import '../../../../../../core/connection/network_info.dart';
import '../../../../../../core/errors/failure.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../../domain/repositories/goals_repository.dart';
import '../datasources/goals_datasource.dart';
import '../models/goals_model.dart';

class GoalsImplement implements GoalsRepository {
  final NetworkInfo networkInfo;
  final GoalsDatasource goalsDatasource;

  GoalsImplement({required this.networkInfo, required this.goalsDatasource});

  @override
  Future<List<GoalsModel>> getAllGoals() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await goalsDatasource.getAllGoals();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> addGoal({
    String? goalId,
    required String name,
    required String type,
    required String form,
    required String targetedValue,
    required String currentValue,
    required String notes,
    required String scope,
    required String customerId,
    required String employeeId,
    required String sellerId,
    required String boxId,
    required List<ProjectProductModel> productsIds,
    required String mainCategoriesId,
    required String subCategoriesId,
    required DateTime dueDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await goalsDatasource.addGoal(
        goalId: goalId,
        name: name,
        type: type,
        form: form,
        targetedValue: targetedValue,
        currentValue: currentValue,
        notes: notes,
        scope: scope,
        customerId: customerId,
        employeeId: employeeId,
        sellerId: sellerId,
        boxId: boxId,
        mainCategoriesId: mainCategoriesId,
        subCategoriesId: subCategoriesId,
        dueDate: dueDate,
        productsIds: productsIds,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<dynamic> getGoalDetails({
    required String goalId,
    bool? isCancel,
    bool? isTransfer,
    bool? isDelete,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await goalsDatasource.getGoalDetails(
        goalId: goalId,
        isCancel: isCancel,
        isTransfer: isTransfer,
        isDelete: isDelete,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
