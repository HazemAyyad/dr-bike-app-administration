import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_detials_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/asset_depreciation_preview_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/assets_models/assets_log_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/expenses_models/expense_detail_model.dart';
import 'package:doctorbike/features/admin/financial_affairs/data/models/official_papers_models/file_data_model.dart';
import 'package:image_picker/image_picker.dart';

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
  Future<dynamic> getAllFinancial({
    required String page,
    Map<String, dynamic>? filters,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await financialAffairsDatasource.getAllFinancial(
        page: page,
        filters: filters,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // get assets logs
  @override
  Future<List<AssetLogModel>> getAssetsLogs({
    Map<String, dynamic>? filters,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await financialAffairsDatasource.getAssetsLogs(filters: filters);
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
    void Function(double progress)? onUploadProgress,
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
        onUploadProgress: onUploadProgress,
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
  Future<AssetDepreciationPreview> getDepreciationPreview() async {
    if (!await networkInfo.isConnected) throw NoConnectionFailure();
    try {
      return await financialAffairsDatasource.getDepreciationPreview();
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
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
    String? costLayerId,
    List<Map<String, dynamic>>? items,
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
        costLayerId: costLayerId,
        items: items,
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
  Future<Either<Failure, String>> editDestruction({
    required String destructionId,
    required String destructionReason,
    required List<File?> media,
  }) async {
    if (!await networkInfo.isConnected) return Left(NoConnectionFailure());
    try {
      final result = await financialAffairsDatasource.editDestruction(
        destructionId: destructionId,
        destructionReason: destructionReason,
        media: media,
      );
      return result['status'] == 'success'
          ? Right('${result['message']}')
          : Left(ServerFailure('${result['message']}', result));
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
    required String boxId,
    required String expenseType,
    required String expenseDate,
    required List<File?> invoiceImage,
    required List<File?> media,
    void Function(double progress)? onUploadProgress,
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
        boxId: boxId,
        expenseType: expenseType,
        expenseDate: expenseDate,
        invoiceImage: invoiceImage,
        media: media,
        onUploadProgress: onUploadProgress,
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

  @override
  Future<Uint8List> getExpenseReport({
    required String format,
    Map<String, dynamic>? filters,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await financialAffairsDatasource.getExpenseReport(
        format: format,
        filters: filters,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // cancel paper
  @override
  Future<Either<Failure, String>> cancelPaper({
    required String? paperId,
    bool? isPicture,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.cancelPaper(
        paperId: paperId!,
        isPicture: isPicture,
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

  // add picture
  @override
  Future<Either<Failure, String>> addPicture({
    required String pictureId,
    required String name,
    required String description,
    required List<XFile?> media,
    void Function(double progress)? onUploadProgress,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addPicture(
        pictureId: pictureId,
        name: name,
        description: description,
        media: media,
        onUploadProgress: onUploadProgress,
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
    required String paperId,
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
    void Function(double progress)? onUploadProgress,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.addPaper(
        paperId: paperId,
        name: name,
        fileId: fileId,
        media: media,
        notes: notes,
        onUploadProgress: onUploadProgress,
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
  Future<Either<Failure, String>> deleteFiles({
    required String? fileId,
    required String? treasuryId,
    required String? fileBoxId,
    required String? assetId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.deleteFiles(
        fileId: fileId,
        treasuryId: treasuryId,
        fileBoxId: fileBoxId,
        assetId: assetId,
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

  @override
  Future<Uint8List> getAssetReport({Map<String, dynamic>? filters}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await financialAffairsDatasource.getAssetReport(filters: filters);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> depreciateOneAssets({
    required String assetId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await financialAffairsDatasource.depreciateOneAssets(
        assetId: assetId,
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
}
