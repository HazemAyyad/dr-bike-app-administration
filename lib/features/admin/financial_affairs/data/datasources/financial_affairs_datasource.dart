import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../models/official_papers_models/file_data_model.dart';
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
                                : page == '7'
                                    ? EndPoints.getAllTreasuries
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
      return data.map((e) => AssetLogModel.fromJson(e)).toList();
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
      final Map<String, dynamic> formData = {};

      if (selectedFile.isNotEmpty) {
        for (int i = 0; i < selectedFile.length; i++) {
          final file = selectedFile[i];
          if (file == null) continue;

          if (file.path.contains('http')) {
            // لو الملف لينك (مش مرفوع جديد)
            formData['media[$i]'] = file.path;
          } else {
            final compressedImg = await compressImage(XFile(file.path));
            // لو الملف محلي
            formData['media[$i]'] = await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }
        }
      }

      final response = await api.post(
        assetId != null ? EndPoints.editAsset : EndPoints.addNewAsset,
        data: {
          if (assetId != null) 'asset_id': assetId,
          'name': assetName,
          'price': price,
          'notes': note,
          'depreciation_rate': depreciationRate,
          'months_number': numberOfMonths,
          ...formData,
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
                final compressedImg = await compressImage(XFile(file.path));
                return await MultipartFile.fromFile(
                  compressedImg.path,
                  filename: compressedImg.path.split('/').last,
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
    required String boxId,
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
          if (expenseId == null) 'price': price,
          'notes': notes,
          if (expenseId == null) 'box_id': boxId,
          if (invoiceImage.isNotEmpty)
            'invoice_img[]': await Future.wait(
              invoiceImage.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                final compressedImg = await compressImage(XFile(file.path));
                return await MultipartFile.fromFile(
                  compressedImg.path,
                  filename: compressedImg.path.split('/').last,
                );
              }),
            ),
          if (media.isNotEmpty)
            'media[]': await Future.wait(
              media.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                final compressedImg = await compressImage(XFile(file.path));
                return await MultipartFile.fromFile(
                  compressedImg.path,
                  filename: compressedImg.path.split('/').last,
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
  Future<Map<String, dynamic>> cancelPaper({
    required String paperId,
    bool? isPicture,
  }) async {
    try {
      final response = await api.post(
        isPicture == true ? EndPoints.deletePicture : EndPoints.cancelPaper,
        data: {
          if (isPicture == false) 'paper_id': paperId,
          if (isPicture == true) 'picture_id': paperId
        },
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
    required List<XFile?> media,
    required String pictureId,
  }) async {
    try {
      final response = await api.post(
        pictureId.isNotEmpty ? EndPoints.editPicture : EndPoints.addPicture,
        data: {
          if (pictureId.isNotEmpty) 'picture_id': pictureId,
          'name': name,
          'description': description,
          if (media.isNotEmpty)
            'file': await Future.wait(
              media.map((file) async {
                if (file!.path.contains('http')) {
                  return file.path;
                }
                final compressedImg = await compressImage(XFile(file.path));
                return await MultipartFile.fromFile(
                  compressedImg.path,
                  filename: compressedImg.path.split('/').last,
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

  // add Paper
  Future<Map<String, dynamic>> addPaper({
    required String paperId,
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
  }) async {
    try {
      // تجهيز قائمة الملفات اللي هترفعها
      final List filesToUpload = [];
      for (var file in media) {
        if (file == null) continue;

        // لو الـ path يحتوي "http"، يمكن ترسله كرابط مباشرة
        if (file.path.contains('http')) {
          filesToUpload.add(file.path);
        } else {
          // نضغط الصورة أولاً باستخدام الـ compressImage (نفس الفانكشن اللي اعددناه)
          final compressed =
              await compressImageFile(inputFile: XFile(file.path));
          final mf = await MultipartFile.fromFile(
            compressed.path,
            filename: compressed.path.split('/').last,
          );
          filesToUpload.add(mf);
        }
      }

      final response = await api.post(
        paperId.isNotEmpty ? EndPoints.editPaper : EndPoints.addPaper,
        data: {
          if (paperId.isNotEmpty) 'paper_id': paperId,
          'name': name,
          'file_id': fileId,
          if (filesToUpload.isNotEmpty) 'img[]': filesToUpload,
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

  // add safe
  Future<Map<String, dynamic>> addSafe({
    required String name,
    required String fileBoxId,
    required String treasuryId,
  }) async {
    try {
      final response = await api.post(
        fileBoxId.isNotEmpty
            ? EndPoints.storeFile
            : treasuryId.isNotEmpty
                ? EndPoints.storeFileBox
                : EndPoints.storeTreasury,
        data: {
          'name': name,
          if (treasuryId.isNotEmpty) 'treasury_id': treasuryId,
          if (fileBoxId.isNotEmpty) 'file_box_id': fileBoxId,
        },
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

  // delete file
  Future<Map<String, dynamic>> deleteFiles({
    required String? fileId,
    required String? treasuryId,
    required String? fileBoxId,
    required String? assetId,
  }) async {
    try {
      final response = await api.post(
          fileId != null
              ? EndPoints.deleteFile
              : treasuryId != null
                  ? EndPoints.deleteTreasury
                  : fileBoxId != null
                      ? EndPoints.deleteFileBox
                      : EndPoints.deleteAsset,
          data: {
            if (fileId != null) 'file_id': fileId,
            if (treasuryId != null) 'treasury_id': treasuryId,
            if (fileBoxId != null) 'file_box_id': fileBoxId,
            if (assetId != null) 'asset_id': assetId,
          });
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

  // get file papers
  Future<List<FilePapersModel>> getFilePapers({required String fileId}) async {
    try {
      final response = await api.post(
        EndPoints.getFilePapers,
        data: {'file_id': fileId},
      );
      final data = response.data['file_papers'] as List;
      return data
          .map((e) => FilePapersModel.fromJson(e as Map<String, dynamic>))
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

  // get assets logs
  Future<Uint8List> getAssetReport() async {
    try {
      final response = await api.get(
        EndPoints.getAssetsLogsReport,
        options: Options(responseType: ResponseType.bytes),
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
  Future<Map<String, dynamic>> depreciateOneAssets(
      {required String assetId}) async {
    try {
      final response = await api
          .post(EndPoints.depreciateOneAsset, data: {'asset_id': assetId});
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

Future<XFile> compressImageFile({required XFile inputFile}) async {
  final file = File(inputFile.path);
  final tempDir = await getTemporaryDirectory();
  final targetPath = p.join(
    tempDir.path,
    "${DateTime.now().millisecondsSinceEpoch}_${p.basename(inputFile.path)}",
  );

  // نستخدم compressAndGetFile للحصول على ملف مضغوط
  final compressedFile = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 90,
    format: CompressFormat.jpeg,
    keepExif: false,
  );

  if (compressedFile == null) {
    // في حال فشل الضغط، رجّع الصورة الأصلية
    return inputFile;
  }

  return XFile(compressedFile.path);
}
