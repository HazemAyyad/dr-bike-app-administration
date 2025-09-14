import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddSafeUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddSafeUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String fileBoxId,
    required String treasuryId,
  }) {
    return financialAffairsRepository.addSafe(
      name: name,
      fileBoxId: fileBoxId,
      treasuryId: treasuryId,
    );
  }
}
