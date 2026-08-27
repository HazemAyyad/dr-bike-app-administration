import '../repositories/financial_affairs_repository.dart';

class GetAllFinancialUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  GetAllFinancialUsecase({required this.financialAffairsRepository});

  Future<dynamic> call({required String page, Map<String, dynamic>? filters}) {
    return financialAffairsRepository.getAllFinancial(
      page: page,
      filters: filters,
    );
  }
}
