import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class ChashToBoxUsecase {
  final ChecksRepository checksRepository;

  ChashToBoxUsecase({required this.checksRepository});

  Future<Either<Failure, String>> chashToBox(
      {required String boxId, required String checkId}) async {
    return await checksRepository.chashToBox(boxId: boxId, checkId: checkId);
  }
}
