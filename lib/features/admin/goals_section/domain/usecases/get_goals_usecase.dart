import '../../data/models/goals_model.dart';
import '../repositories/goals_repository.dart';

class GetGoalsUsecase {
  final GoalsRepository goalsRepository;

  GetGoalsUsecase({required this.goalsRepository});

  Future<List<GoalsModel>> call() async {
    return await goalsRepository.getAllGoals();
  }
}
