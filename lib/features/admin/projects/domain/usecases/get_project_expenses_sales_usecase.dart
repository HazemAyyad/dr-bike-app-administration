import '../repositories/project_repository.dart';

class GetProjectExpensesSalesUsecase {
  final ProjectRepository projectRepository;

  GetProjectExpensesSalesUsecase({required this.projectRepository});

  Future<dynamic> call({
    required bool isSales,
    required String projectId,
    required String expenses,
    required String notes,
    String? boxId,
    String? expenseDate,
  }) {
    return projectRepository.getProjectExpensesAndSales(
      projectId: projectId,
      isSales: isSales,
      expenses: expenses,
      notes: notes,
      boxId: boxId,
      expenseDate: expenseDate,
    );
  }
}
