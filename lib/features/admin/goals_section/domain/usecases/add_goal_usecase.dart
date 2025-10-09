import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../repositories/goals_repository.dart';

class AddGoalUsecase {
  final GoalsRepository goalsRepository;

  AddGoalUsecase({required this.goalsRepository});

  Future<Either<Failure, String>> call({
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
    return await goalsRepository.addGoal(
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
      productsIds: productsIds,
      mainCategoriesId: mainCategoriesId,
      subCategoriesId: subCategoriesId,
      dueDate: dueDate,
    );
  }
}
