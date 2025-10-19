import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddDestructionUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddDestructionUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String productId,
    required String piecesNumber,
    required String destructionReason,
    required List<File?> media,
  }) {
    return financialAffairsRepository.addDestruction(
      productId: productId,
      piecesNumber: piecesNumber,
      destructionReason: destructionReason,
      media: media,
    );
  }
}
