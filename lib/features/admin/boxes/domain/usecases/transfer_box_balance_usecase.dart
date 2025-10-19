import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/boxes_repository.dart';

class TransferBoxBalanceUsecase {
  BoxesRepository boxesRepository;
  TransferBoxBalanceUsecase({required this.boxesRepository});

  Future<Either<Failure, String>> call({
    required String fromBoxId,
    required String toBoxId,
    required String total,
  }) {
    return boxesRepository.transferBoxBalance(
      fromBoxId: fromBoxId,
      toBoxId: toBoxId,
      total: total,
    );
  }
}
