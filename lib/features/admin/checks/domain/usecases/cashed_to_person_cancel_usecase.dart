import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class CashedToPersonCancelUsecase {
  final ChecksRepository checksRepository;

  CashedToPersonCancelUsecase({required this.checksRepository});

  Future<Either<Failure, String>> call({
    required bool isInComing,
    required bool toPerson,
    required String checkId,
    String? sellerId,
    String? customerId,
  }) {
    return checksRepository.cashedToPersonOrCancel(
      isInComing: isInComing,
      toPerson: toPerson,
      checkId: checkId,
      sellerId: sellerId,
      customerId: customerId,
    );
  }
}
