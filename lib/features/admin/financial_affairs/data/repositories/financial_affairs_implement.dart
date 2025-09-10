import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_detials_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_log_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/expenses_models/expense_detail_model.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/financial_affairs_repository.dart';
import '../datasources/financial_affairs_datasource.dart';

class FinancialAffairsImplement implements FinancialAffairsRepository {
  final NetworkInfo networkInfo;
  final FinancialAffairsDatasource financialAffairsDatasource;

  FinancialAffairsImplement({
    required this.networkInfo,
    required this.financialAffairsDatasource,
  });

  // get all assets
  @override
  Future<dynamic> getAllFinancial({required String page}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await financialAffairsDatasource.getAllFinancial(page: page);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get assets logs
  @override
  Future<List<AssetLogModel>> getAssetsLogs() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await financialAffairsDatasource.getAssetsLogs();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // add new assets
  @override
  Future<Either<Failure, String>> addNewAssets({
    String? assetId,
    required String assetName,
    required double price,
    required String note,
    required double depreciationRate,
    required int numberOfMonths,
    required List<File?> selectedFile,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addNewAssets(
        assetId: assetId,
        assetName: assetName,
        price: price,
        note: note,
        depreciationRate: depreciationRate,
        numberOfMonths: numberOfMonths,
        selectedFile: selectedFile,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // depreciate assets
  @override
  Future<Either<Failure, String>> depreciateAssets() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.depreciateAssets();
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<AssetDetailsModel> assetsDetails({required String assetId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await financialAffairsDatasource.assetsDetails(assetId: assetId);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> addDestruction({
    required String productId,
    required String piecesNumber,
    required String destructionReason,
    required List<File?> media,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addDestruction(
        productId: productId,
        piecesNumber: piecesNumber,
        destructionReason: destructionReason,
        media: media,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> addExpense({
    required String name,
    required String price,
    required String notes,
    required String paymentMethod,
    required List<File?> invoiceImage,
    required List<File?> media,
    String? expenseId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addExpense(
        name: name,
        price: price,
        notes: notes,
        paymentMethod: paymentMethod,
        invoiceImage: invoiceImage,
        media: media,
        expenseId: expenseId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<ExpenseDetailModel> getExpensesData(
      {required String expenseId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await financialAffairsDatasource.getExpensesData(
          expenseId: expenseId);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
