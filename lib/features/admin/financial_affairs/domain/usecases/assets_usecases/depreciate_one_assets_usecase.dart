import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class DepreciateOneAssetsUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  DepreciateOneAssetsUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({required String assetId}) {
    return financialAffairsRepository.depreciateOneAssets(assetId: assetId);
  }
}
