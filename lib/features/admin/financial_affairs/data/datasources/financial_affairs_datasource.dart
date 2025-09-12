import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/assets_models/assets_detials_model.dart';
import '../models/assets_models/assets_log_model.dart';
import '../models/expenses_models/expense_detail_model.dart';

class FinancialAffairsDatasource {
  final ApiConsumer api;

  FinancialAffairsDatasource({required this.api});

  // get all financial
  Future<dynamic> getAllFinancial({required String page}) async {
    try {
      final response = await api.get(
        page == '1'
            ? EndPoints.getAllAssets
            : page == '2'
                ? EndPoints.getAllExpenses
                : page == '3'
                    ? EndPoints.getAllDestructions
                    : page == '4'
                        ? EndPoints.getAllPapers
                        : page == '5'
                            ? EndPoints.getAllPictures
                            : page == '6'
                                ? EndPoints.getAllFiles
                                : EndPoints.getAllAssets,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get assets logs
  Future<List<AssetLogModel>> getAssetsLogs() async {
    try {
      final response = await api.get(EndPoints.getAssetsLogs);
      final data = response.data['asset_logs'] as List;
      return data
          .where((e) => e['type'] == 'depreciate')
          .toList()
          .map((e) => AssetLogModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // add new assets
  Future<Map<String, dynamic>> addNewAssets({
    String? assetId,
    required String assetName,
    required double price,
    required String note,
    required double depreciationRate,
    required int numberOfMonths,
    required List<File?> selectedFile,
  }) async {
    try {
      final response = await api.post(
        assetId != null ? EndPoints.editAsset : EndPoints.addNewAsset,
        data: {
          if (assetId != null) 'asset_id': assetId,
          'name': assetName,
          'price': price,
          'notes': note,
          'depreciation_rate': depreciationRate,
          'months_number': numberOfMonths,
          if (selectedFile.isNotEmpty)
            'media[]': selectedFile.map(
              (file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                return await Future.wait(
                  [
                    MultipartFile.fromFile(
                      file.path,
                      filename: file.path.split('/').last,
                    ),
                  ],
                );
              },
            ),
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // depreciate assets
  Future<Map<String, dynamic>> depreciateAssets() async {
    try {
      final response = await api.get(EndPoints.depreciateAssets);
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // assets detials
  Future<AssetDetailsModel> assetsDetails({required String assetId}) async {
    try {
      final response =
          await api.post(EndPoints.assetsDetails, data: {'asset_id': assetId});
      return AssetDetailsModel.fromJson(response.data['asset']);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // add destruction
  Future<Map<String, dynamic>> addDestruction({
    required String productId,
    required String piecesNumber,
    required String destructionReason,
    required List<File?> media,
  }) async {
    try {
      final response = await api.post(
        EndPoints.addDestruction,
        data: {
          'product_id': productId,
          'pieces_number': piecesNumber,
          'destruction_reason': destructionReason,
          if (media.isNotEmpty)
            'media[]': await Future.wait(
              media.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                return await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                );
              }),
            ),
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // add expense
  Future<Map<String, dynamic>> addExpense({
    required String name,
    required String price,
    required String notes,
    required String paymentMethod,
    required List<File?> invoiceImage,
    required List<File?> media,
    String? expenseId,
  }) async {
    try {
      final response = await api.post(
        expenseId != null ? EndPoints.editExpense : EndPoints.addExpense,
        data: {
          if (expenseId != null) 'expense_id': expenseId,
          'name': name,
          'price': price,
          'notes': notes,
          'payment_method': paymentMethod,
          if (invoiceImage.isNotEmpty)
            'invoice_img[]': await Future.wait(
              invoiceImage.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                return await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                );
              }),
            ),
          if (media.isNotEmpty)
            'media[]': await Future.wait(
              media.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                return await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                );
              }),
            ),
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get expenses data
  Future<ExpenseDetailModel> getExpensesData(
      {required String expenseId}) async {
    try {
      final response = await api
          .post(EndPoints.showExpense, data: {'expense_id': expenseId});
      return ExpenseDetailModel.fromJson(response.data['expense']);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // cancel paper
  Future<Map<String, dynamic>> cancelPaper({required String? paperId}) async {
    try {
      final response = await api.post(
        EndPoints.cancelPaper,
        data: {'paper_id': paperId},
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // add picture
  Future<Map<String, dynamic>> addPicture({
    required String name,
    required String description,
    required List<File?> media,
  }) async {
    try {
      final response = await api.post(
        EndPoints.addPicture,
        data: {
          'name': name,
          'description': description,
          if (media.isNotEmpty)
            'file': await Future.wait(
              media.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                return await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                );
              }),
            ),
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // add document
  Future<Map<String, dynamic>> addPaper({
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
  }) async {
    try {
      final response = await api.post(
        EndPoints.addPaper,
        data: {
          'name': name,
          'file_id': fileId,
          if (media.isNotEmpty)
            'img[]': await Future.wait(
              media.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                return await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                );
              }),
            ),
          'notes': notes,
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }
}
