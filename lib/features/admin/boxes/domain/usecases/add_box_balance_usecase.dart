import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/boxes_repository.dart';

class AddBoxBalanceUsecase {
  BoxesRepository boxesRepository;
  AddBoxBalanceUsecase({required this.boxesRepository});

  Future<Either<Failure, String>> call({
    required String boxId,
    required String total,
  }) {
    return boxesRepository.addBoxBalance(boxId: boxId, total: total);
  }
}
