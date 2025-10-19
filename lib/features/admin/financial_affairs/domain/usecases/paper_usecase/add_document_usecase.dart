import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddPaperUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddPaperUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
    required String paperId,
  }) {
    return financialAffairsRepository.addPaper(
      paperId: paperId,
      name: name,
      fileId: fileId,
      media: media,
      notes: notes,
    );
  }
}
