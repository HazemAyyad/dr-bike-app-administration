import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class CashedToPersonOrCashedUsecase {
  final ChecksRepository checksRepository;

  CashedToPersonOrCashedUsecase({required this.checksRepository});

  Future<Either<Failure, String>> call({
    required bool isInComing,
    required String checkId,
    String? sellerId,
    String? customerId,
  }) {
    return checksRepository.cashedToPersonOrCashed(
      isInComing: isInComing,
      checkId: checkId,
      sellerId: sellerId,
      customerId: customerId,
    );
  }
}
