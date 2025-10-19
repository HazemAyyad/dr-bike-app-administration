import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class EditChecksUsecase {
  final ChecksRepository checksRepository;

  EditChecksUsecase({required this.checksRepository});

  Future<Either<Failure, String>> call({
    required bool isInComing,
    required String outgoingCheckId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  }) {
    return checksRepository.editChecks(
      isInComing: isInComing,
      outgoingCheckId: outgoingCheckId,
      dueDate: dueDate,
      checkId: checkId,
      bankName: bankName,
      frontImage: frontImage,
      backImage: backImage,
      notes: notes,
    );
  }
}
