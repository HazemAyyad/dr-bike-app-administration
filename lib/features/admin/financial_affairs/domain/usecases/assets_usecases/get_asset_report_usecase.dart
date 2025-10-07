import 'dart:typed_data';

import '../../repositories/financial_affairs_repository.dart';

class GetAssetReportUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  GetAssetReportUsecase({required this.financialAffairsRepository});

  Future<Uint8List> call() {
    return financialAffairsRepository.getAssetReport();
  }
}
