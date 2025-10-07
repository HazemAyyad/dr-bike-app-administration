import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/assets_models/assets_detials_model.dart';
import '../../data/models/assets_models/assets_log_model.dart';
import '../../data/models/expenses_models/expense_detail_model.dart';
import '../../data/models/official_papers_models/file_data_model.dart';

abstract class FinancialAffairsRepository {
  // assets
  Future<dynamic> getAllFinancial({required String page});

  Future<List<AssetLogModel>> getAssetsLogs();

  Future<Either<Failure, String>> depreciateAssets();

  Future<AssetDetailsModel> assetsDetails({required String assetId});

  Future<Either<Failure, String>> addNewAssets({
    String? assetId,
    required String assetName,
    required double price,
    required String note,
    required double depreciationRate,
    required int numberOfMonths,
    required List<File?> selectedFile,
  });

  // expenses
  Future<Either<Failure, String>> addDestruction({
    required String productId,
    required String piecesNumber,
    required String destructionReason,
    required List<File?> media,
  });

  Future<Either<Failure, String>> addExpense({
    required String name,
    required String price,
    required String notes,
    required String boxId,
    required List<File?> invoiceImage,
    required List<File?> media,
    String? expenseId,
  });

  Future<ExpenseDetailModel> getExpensesData({required String expenseId});

  // official papers
  Future<Either<Failure, String>> cancelPaper({
    required String? paperId,
    bool? isPicture,
  });

  Future<Either<Failure, String>> addPicture({
    required String name,
    required String description,
    required List<XFile?> media,
    required String pictureId,
  });

  Future<Either<Failure, String>> addPaper({
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
    required String paperId,
  });

  Future<Either<Failure, String>> addSafe({
    required String name,
    required String fileBoxId,
    required String treasuryId,
  });

  Future<Either<Failure, String>> deleteFiles({
    required String? fileId,
    required String? treasuryId,
    required String? fileBoxId,
    required String? assetId,
  });

  Future<List<FilePapersModel>> getFilePapers({required String fileId});

  Future<Uint8List> getAssetReport();

  Future<Either<Failure, String>> depreciateOneAssets({
    required String assetId,
  });
}
