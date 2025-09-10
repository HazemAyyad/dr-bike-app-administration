import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/assets_models/assets_detials_model.dart';
import '../../data/models/assets_models/assets_log_model.dart';
import '../../data/models/expenses_models/expense_detail_model.dart';

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
    required String paymentMethod,
    required List<File?> invoiceImage,
    required List<File?> media,
    String? expenseId,
  });

  Future<ExpenseDetailModel> getExpensesData({required String expenseId});
}
