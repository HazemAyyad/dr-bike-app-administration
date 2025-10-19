import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class DeleteCheckUsecase {
  final ChecksRepository checksRepository;

  DeleteCheckUsecase({required this.checksRepository});

  Future<Either<Failure, String>> deleteCheck({
    required String checkId,
    required bool isInComing,
  }) async {
    return await checksRepository.deleteCheck(
      checkId: checkId,
      isInComing: isInComing,
    );
  }
}
