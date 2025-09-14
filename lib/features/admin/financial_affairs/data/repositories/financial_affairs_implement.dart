import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_detials_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_log_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/expenses_models/expense_detail_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/presentation/views/official_papers_screens/file_data_model.dart';

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

  // add picture
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

  // add destruction
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

  // add expense
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

  // get expenses data
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

  // cancel paper
  @override
  Future<Either<Failure, String>> cancelPaper(
      {required String? paperId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await financialAffairsDatasource.cancelPaper(paperId: paperId);
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

  // add picture
  @override
  Future<Either<Failure, String>> addPicture({
    required String name,
    required String description,
    required List<File?> media,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addPicture(
        name: name,
        description: description,
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
  Future<Either<Failure, String>> addPaper({
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addPaper(
        name: name,
        fileId: fileId,
        media: media,
        notes: notes,
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

  // add safe
  @override
  Future<Either<Failure, String>> addSafe({
    required String name,
    required String fileBoxId,
    required String treasuryId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addSafe(
        name: name,
        fileBoxId: fileBoxId,
        treasuryId: treasuryId,
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

  // delete file
  @override
  Future<Either<Failure, String>> deleteFile({required String fileId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await financialAffairsDatasource.deleteFile(fileId: fileId);
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
  Future<List<FilePapersModel>> getFilePapers({required String fileId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await financialAffairsDatasource.getFilePapers(fileId: fileId);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
