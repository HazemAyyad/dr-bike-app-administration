import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../../data/models/goals_model.dart';

abstract class GoalsRepository {
  Future<List<GoalsModel>> getAllGoals();

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
  });

  Future<dynamic> getGoalDetails({
    required String goalId,
    bool? isCancel,
    bool? isTransfer,
    bool? isDelete,
  });
}
