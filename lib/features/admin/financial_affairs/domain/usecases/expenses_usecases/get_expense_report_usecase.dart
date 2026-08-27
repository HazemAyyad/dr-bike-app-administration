import 'dart:typed_data';

import '../../repositories/financial_affairs_repository.dart';

class GetExpenseReportUsecase {
  const GetExpenseReportUsecase({required this.financialAffairsRepository});

  final FinancialAffairsRepository financialAffairsRepository;

  Future<Uint8List> call({
    required String format,
    Map<String, dynamic>? filters,
  }) {
    return financialAffairsRepository.getExpenseReport(
      format: format,
      filters: filters,
    );
  }
}
