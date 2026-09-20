import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddNewAssetsUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddNewAssetsUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    String? assetId,
    String? boxId,
    required String assetName,
    required double price,
    required String note,
    required double depreciationRate,
    required int numberOfMonths,
    required List<File?> selectedFile,
    void Function(double progress)? onUploadProgress,
  }) {
    return financialAffairsRepository.addNewAssets(
      assetId: assetId,
      boxId: boxId,
      assetName: assetName,
      price: price,
      note: note,
      depreciationRate: depreciationRate,
      numberOfMonths: numberOfMonths,
      selectedFile: selectedFile,
      onUploadProgress: onUploadProgress,
    );
  }
}
