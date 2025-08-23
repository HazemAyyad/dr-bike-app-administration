import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/boxes_repository.dart';

class EditBoxUsecase {
  BoxesRepository boxesRepository;
  EditBoxUsecase({required this.boxesRepository});

  Future<Either<Failure, String>> call({
    required String boxId,
    required String name,
    required String total,
    required String isShown,
  }) {
    return boxesRepository.editBox(
      boxId: boxId,
      name: name,
      total: total,
      isShown: isShown,
    );
  }
}
