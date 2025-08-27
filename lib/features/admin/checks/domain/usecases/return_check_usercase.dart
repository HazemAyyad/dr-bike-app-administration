import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class ReturnCheckUsercase {
  final ChecksRepository checksRepository;

  ReturnCheckUsercase({required this.checksRepository});

  Future<Either<Failure, String>> call({
    required String checkId,
    required bool isInComing,
    required bool isCancel,
  }) {
    return checksRepository.returnCheck(
      checkId: checkId,
      isInComing: isInComing,
      isCancel: isCancel,
    );
  }
}
