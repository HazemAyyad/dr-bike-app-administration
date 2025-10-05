import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class CancelPaperUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  CancelPaperUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call(
      {required String paperId, bool? isPicture}) {
    return financialAffairsRepository.cancelPaper(
        paperId: paperId, isPicture: isPicture);
  }
}
