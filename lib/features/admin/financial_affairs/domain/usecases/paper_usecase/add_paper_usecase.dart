import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddPictureUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddPictureUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String description,
    required List<File?> media,
  }) {
    return financialAffairsRepository.addPicture(
      name: name,
      description: description,
      media: media,
    );
  }
}
