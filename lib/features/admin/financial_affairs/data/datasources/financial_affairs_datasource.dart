import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/media/media_upload_preparer.dart';
import '../../../../../core/media/prepared_upload.dart';
import '../models/assets_models/assets_detials_model.dart';
import '../models/assets_models/asset_depreciation_preview_model.dart';
import '../models/assets_models/assets_log_model.dart';
import '../models/expenses_models/expense_detail_model.dart';
import '../models/official_papers_models/file_data_model.dart';

class FinancialAffairsDatasource {
  final ApiConsumer api;

  FinancialAffairsDatasource({required this.api});

  // get all financial
  Future<dynamic> getAllFinancial({
    required String page,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final endpoint = page == '1'
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
                                  : page == '8'
                                      ? EndPoints.destructionCostLayers
                                      : EndPoints.getAllAssets;
      final response = await api.get(endpoint, queryParameters: filters);
      final raw = response.data;
      debugParseLog(
        'FinancialAffairsDatasource.getAllFinancial',
        'page=$page endpoint=$endpoint rawType=${raw.runtimeType}',
      );
      return raw;
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
  Future<List<AssetLogModel>> getAssetsLogs({
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response =
          await api.get(EndPoints.getAssetsLogs, queryParameters: filters);
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
    String? boxId,
    required String assetName,
    required double price,
    required String note,
    required int numberOfMonths,
    String? acquiredAt,
    required List<File?> selectedFile,
    void Function(double progress)? onUploadProgress,
  }) async {
    final preparedUploads = <PreparedUpload>[];
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
            final prepared = await _prepareFinancialMedia(
              file,
              imageProfile: ImageUploadProfile.general,
              maxVideoBytes: 30 * 1024 * 1024,
            );
            preparedUploads.add(prepared);
            formData['media[$i]'] = await prepared.toMultipartFile();
          }
        }
      }

      final response = await api.post(
        assetId != null ? EndPoints.editAsset : EndPoints.addNewAsset,
        data: {
          if (assetId != null) 'asset_id': assetId,
          if (assetId == null && boxId != null) 'box_id': boxId,
          'name': assetName,
          'price': price,
          'notes': note,
          'months_number': numberOfMonths,
          if (acquiredAt != null && acquiredAt.trim().isNotEmpty)
            'acquired_at': acquiredAt,
          ...formData,
        },
        isFormData: true,
        onSendProgress: (sent, total) {
          if (total > 0) onUploadProgress?.call(sent / total);
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
    } finally {
      await _cleanupPrepared(preparedUploads);
    }
  }

  // depreciate assets
  Future<Map<String, dynamic>> depreciateAssets() async {
    try {
      final response = await api.post(EndPoints.depreciateAssets);
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

  Future<AssetDepreciationPreview> getDepreciationPreview() async {
    try {
      final response = await api.get(EndPoints.depreciationPreview);
      return AssetDepreciationPreview.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data?['data'] ?? {},
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
    String? costLayerId,
    List<Map<String, dynamic>>? items,
  }) async {
    final preparedUploads = <PreparedUpload>[];
    try {
      final uploadMedia = <dynamic>[];
      for (final file in media) {
        if (file == null) continue;
        if (file.path.contains('http')) {
          uploadMedia.add(file.path);
          continue;
        }
        final prepared = await _prepareFinancialMedia(
          file,
          imageProfile: ImageUploadProfile.general,
          maxVideoBytes: 30 * 1024 * 1024,
        );
        preparedUploads.add(prepared);
        uploadMedia.add(await prepared.toMultipartFile());
      }
      final response = await api.post(
        items == null
            ? EndPoints.addDestruction
            : EndPoints.addDestructionsBatch,
        data: {
          if (items == null) 'product_id': productId,
          if (items == null) 'pieces_number': piecesNumber,
          if (items != null) 'items': jsonEncode(items),
          'destruction_reason': destructionReason,
          if (costLayerId != null) 'cost_layer_id': costLayerId,
          if (uploadMedia.isNotEmpty) 'media[]': uploadMedia,
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
    } finally {
      await _cleanupPrepared(preparedUploads);
    }
  }

  Future<Map<String, dynamic>> editDestruction({
    required String destructionId,
    required String destructionReason,
    required List<File?> media,
  }) async {
    final preparedUploads = <PreparedUpload>[];
    try {
      final Map<String, dynamic> payload = {
        'destruction_id': destructionId,
        'destruction_reason': destructionReason,
      };
      for (var i = 0; i < media.length; i++) {
        final file = media[i];
        if (file == null || file.path.startsWith('http')) continue;
        final prepared = await _prepareFinancialMedia(
          file,
          imageProfile: ImageUploadProfile.general,
          maxVideoBytes: 30 * 1024 * 1024,
        );
        preparedUploads.add(prepared);
        payload['media[$i]'] = await prepared.toMultipartFile();
      }
      final response = await api.post(EndPoints.editDestruction,
          data: payload, isFormData: true);
      return Map<String, dynamic>.from(response.data);
    } finally {
      await _cleanupPrepared(preparedUploads);
    }
  }

  // add expense
  Future<Map<String, dynamic>> addExpense({
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
    final preparedUploads = <PreparedUpload>[];
    try {
      final invoiceUploads = <dynamic>[];
      for (final file in invoiceImage) {
        if (file == null) continue;
        if (file.path.contains('http')) {
          invoiceUploads.add(file.path);
          continue;
        }
        final prepared = await MediaUploadPreparer.prepareImageForUpload(
          XFile(file.path),
          profile: ImageUploadProfile.receipt,
        );
        preparedUploads.add(prepared);
        invoiceUploads.add(await prepared.toMultipartFile());
      }
      final mediaUploads = <dynamic>[];
      for (final file in media) {
        if (file == null) continue;
        if (file.path.contains('http')) {
          mediaUploads.add(file.path);
          continue;
        }
        final prepared = await _prepareFinancialMedia(
          file,
          imageProfile: ImageUploadProfile.general,
          maxVideoBytes: 30 * 1024 * 1024,
        );
        preparedUploads.add(prepared);
        mediaUploads.add(await prepared.toMultipartFile());
      }
      final response = await api.post(
        expenseId != null ? EndPoints.editExpense : EndPoints.addExpense,
        data: {
          if (expenseId != null) 'expense_id': expenseId,
          'name': name,
          if (expenseId == null) 'price': price,
          'notes': notes,
          if (expenseId == null) 'box_id': boxId,
          if (expenseId == null) 'expense_type': expenseType,
          if (expenseId == null) 'expense_date': expenseDate,
          if (invoiceUploads.isNotEmpty) 'invoice_img[]': invoiceUploads,
          if (mediaUploads.isNotEmpty) 'media[]': mediaUploads,
        },
        isFormData: true,
        onSendProgress: (sent, total) {
          if (total > 0) onUploadProgress?.call(sent / total);
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
    } finally {
      await _cleanupPrepared(preparedUploads);
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

  Future<Uint8List> getExpenseReport({
    required String format,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await api.get(
        EndPoints.expenseReportExport(format),
        queryParameters: filters,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(List<int>.from(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'تعذر تحميل التقرير',
          status: e.response?.statusCode ?? 500,
          data: data is Map ? Map<String, dynamic>.from(data) : {},
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
    void Function(double progress)? onUploadProgress,
  }) async {
    final preparedUploads = <PreparedUpload>[];
    try {
      final selected = media.isEmpty ? null : media.first;
      dynamic preparedFile;
      if (selected != null) {
        if (selected.path.contains('http')) {
          preparedFile = selected.path;
        } else {
          final extension = selected.path.split('.').last.toLowerCase();
          final prepared = {'mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv', 'wmv'}
                  .contains(extension)
              ? await MediaUploadPreparer.prepareVideoForUpload(
                  XFile(selected.path),
                  maxBytes: 30 * 1024 * 1024,
                )
              : await MediaUploadPreparer.prepareImageForUpload(
                  XFile(selected.path),
                  profile: ImageUploadProfile.general,
                );
          preparedUploads.add(prepared);
          preparedFile = await prepared.toMultipartFile();
        }
      }
      final response = await api.post(
        pictureId.isNotEmpty ? EndPoints.editPicture : EndPoints.addPicture,
        data: {
          if (pictureId.isNotEmpty) 'picture_id': pictureId,
          'name': name,
          'description': description,
          if (preparedFile != null) 'file': preparedFile,
        },
        isFormData: true,
        onSendProgress: (sent, total) {
          if (total > 0) onUploadProgress?.call(sent / total);
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
    } finally {
      await _cleanupPrepared(preparedUploads);
    }
  }

  // add Paper
  Future<Map<String, dynamic>> addPaper({
    required String paperId,
    required String name,
    required String fileId,
    required List<File?> media,
    required String notes,
    void Function(double progress)? onUploadProgress,
  }) async {
    final preparedUploads = <PreparedUpload>[];
    try {
      // تجهيز قائمة الملفات اللي هترفعها
      final List filesToUpload = [];
      final retainedImages = <String>[];
      for (var file in media) {
        if (file == null) continue;

        // Existing remote images are sent separately so removing one from the
        // edit preview also removes its reference from the paper record.
        if (file.path.contains('http')) {
          retainedImages.add(file.path);
        } else {
          final prepared = await MediaUploadPreparer.prepareImageForUpload(
            XFile(file.path),
            profile: ImageUploadProfile.receipt,
          );
          preparedUploads.add(prepared);
          filesToUpload.add(await prepared.toMultipartFile());
        }
      }

      final response = await api.post(
        paperId.isNotEmpty ? EndPoints.editPaper : EndPoints.addPaper,
        data: {
          if (paperId.isNotEmpty) 'paper_id': paperId,
          'name': name,
          'file_id': fileId,
          if (paperId.isNotEmpty) 'retained_img': jsonEncode(retainedImages),
          if (filesToUpload.isNotEmpty) 'img[]': filesToUpload,
          'notes': notes,
        },
        isFormData: true,
        onSendProgress: (sent, total) {
          if (total > 0) onUploadProgress?.call(sent / total);
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
    } finally {
      await _cleanupPrepared(preparedUploads);
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
      final rows = extractMapListFromResponse(response.data, 'file_papers');
      final list = rows.map((e) => FilePapersModel.fromJson(e)).toList();
      return dartList(list);
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
  Future<Uint8List> getAssetReport({Map<String, dynamic>? filters}) async {
    try {
      final response = await api.get(
        EndPoints.getAssetsLogsReport,
        queryParameters: filters,
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

Future<PreparedUpload> _prepareFinancialMedia(
  File file, {
  required ImageUploadProfile imageProfile,
  required int maxVideoBytes,
}) {
  final extension = file.path.split('.').last.toLowerCase();
  if ({'mp4', 'mov', 'm4v', '3gp', 'webm', 'avi', 'mkv', 'wmv'}
      .contains(extension)) {
    return MediaUploadPreparer.prepareVideoForUpload(
      XFile(file.path),
      maxBytes: maxVideoBytes,
    );
  }
  return MediaUploadPreparer.prepareImageForUpload(
    XFile(file.path),
    profile: imageProfile,
  );
}

Future<void> _cleanupPrepared(Iterable<PreparedUpload> uploads) async {
  for (final upload in uploads) {
    await upload.deleteTemporaryCopy();
  }
}
