import '../../../data/models/expenses_models/expense_detail_model.dart';
import '../../repositories/financial_affairs_repository.dart';

class GetExpensesDataUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  GetExpensesDataUsecase({required this.financialAffairsRepository});

  Future<ExpenseDetailModel> call({required String expenseId}) {
    return financialAffairsRepository.getExpensesData(expenseId: expenseId);
  }
}
