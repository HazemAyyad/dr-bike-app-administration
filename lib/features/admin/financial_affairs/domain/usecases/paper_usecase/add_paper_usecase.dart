import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddPictureUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddPictureUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String description,
    required List<XFile?> media,
    required String pictureId,
  }) {
    return financialAffairsRepository.addPicture(
      pictureId: pictureId,
      name: name,
      description: description,
      media: media,
    );
  }
}
