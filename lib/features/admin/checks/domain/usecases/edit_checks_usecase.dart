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
    String? customerId,
    String? sellerId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    String? total,
    String? currency,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  }) {
    return checksRepository.editChecks(
      isInComing: isInComing,
      outgoingCheckId: outgoingCheckId,
      customerId: customerId,
      sellerId: sellerId,
      dueDate: dueDate,
      checkId: checkId,
      bankName: bankName,
      total: total,
      currency: currency,
      frontImage: frontImage,
      backImage: backImage,
      notes: notes,
    );
  }
}
