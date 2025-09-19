import '../repositories/goals_repository.dart';

class GetGoalDetailsUsecase {
  final GoalsRepository goalsRepository;

  GetGoalDetailsUsecase({required this.goalsRepository});

  Future<dynamic> call({
    required String goalId,
    bool? isCancel,
    bool? isTransfer,
  }) async {
    return await goalsRepository.getGoalDetails(
      goalId: goalId,
      isCancel: isCancel,
      isTransfer: isTransfer,
    );
  }
}
