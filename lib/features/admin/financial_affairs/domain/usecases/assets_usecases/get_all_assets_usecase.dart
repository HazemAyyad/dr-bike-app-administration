import '../../repositories/financial_affairs_repository.dart';

class GetAllFinancialUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  GetAllFinancialUsecase({required this.financialAffairsRepository});

  Future<dynamic> call({required String page}) {
    return financialAffairsRepository.getAllFinancial(page: page);
  }
}
