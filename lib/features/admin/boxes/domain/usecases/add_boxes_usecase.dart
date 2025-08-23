import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/boxes_repository.dart';

class AddBoxesUsecase {
  BoxesRepository boxesRepository;
  AddBoxesUsecase({required this.boxesRepository});

  Future<Either<Failure, String>> call({
    required String boxName,
    required String total,
  }) {
    return boxesRepository.addBox(boxName: boxName, total: total);
  }
}
