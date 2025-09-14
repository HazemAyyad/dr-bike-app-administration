import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class DeleteFileUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  DeleteFileUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({required String fileId}) {
    return financialAffairsRepository.deleteFile(fileId: fileId);
  }
}
