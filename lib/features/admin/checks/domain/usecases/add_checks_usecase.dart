import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/checks_repository.dart';

class AddChecksUsecase {
  final ChecksRepository checksRepository;

  AddChecksUsecase({required this.checksRepository});

  Future<Either<Failure, String>> call({
    required bool isInComing,
    String? customerId,
    String? sellerId,
    required String total,
    required DateTime dueDate,
    required String currency,
    required String checkId,
    required String bankName,
    required XFile img,
    XFile? frontImage,
    XFile? backImage,
  }) {
    return checksRepository.addChecks(
      isInComing: isInComing,
      customerId: customerId,
      sellerId: sellerId,
      total: total,
      dueDate: dueDate,
      currency: currency,
      checkId: checkId,
      bankName: bankName,
      img: img,
      frontImage: frontImage,
      backImage: backImage,
    );
  }
}
