import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class DepreciateAssetsUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  DepreciateAssetsUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call() {
    return financialAffairsRepository.depreciateAssets();
  }
}
