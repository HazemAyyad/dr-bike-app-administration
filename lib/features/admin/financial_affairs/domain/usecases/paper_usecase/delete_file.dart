import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class DeleteFilesUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  DeleteFilesUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String? fileId,
    required String? treasuryId,
    required String? fileBoxId,
  }) {
    return financialAffairsRepository.deleteFiles(
      fileId: fileId,
      treasuryId: treasuryId,
      fileBoxId: fileBoxId,
    );
  }
}
