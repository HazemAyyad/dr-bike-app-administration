import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart' hide MultipartFile;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/check_model.dart';
import '../models/general_checks_data_model.dart';

class ChecksDatasource {
  final ApiConsumer api;

  ChecksDatasource({required this.api});

  // addChecks
  Future<Map<String, dynamic>> addChecks({
    required bool isInComing,
    String? customerId,
    String? sellerId,
    required String total,
    required DateTime dueDate,
    required String currency,
    required String checkId,
    required String bankName,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  }) async {
    try {
      XFile? compressedFrontImage;
      XFile? compressedBackImage;

      if (frontImage != null) {
        compressedFrontImage = await compressImage(frontImage);
      }

      if (backImage != null) {
        compressedBackImage = await compressImage(backImage);
      }

      final response = await api.post(
        isInComing ? EndPoints.addIncomingCheck : EndPoints.addOutgoingCheck,
        data: {
          if (customerId != null) 'from_customer': customerId,
          if (sellerId != null) 'from_seller': sellerId,
          'total': total,
          'due_date': dueDate,
          'currency': currency,
          'check_id': checkId,
          'bank_name': bankName,
          // if (isInComing)
          if (compressedFrontImage != null)
            'img': await MultipartFile.fromFile(
              compressedFrontImage.path,
              filename: compressedFrontImage.path.split('/').last,
            ),
          if (compressedFrontImage != null)
            'front_image': await MultipartFile.fromFile(
              compressedFrontImage.path,
              filename: compressedFrontImage.path.split('/').last,
            ),
          if (compressedBackImage != null)
            'back_image': await MultipartFile.fromFile(
              compressedBackImage.path,
              filename: compressedBackImage.path.split('/').last,
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

  // not checks
  Future<dynamic> getChecks({required String endPoint}) async {
    try {
      final response = await api.get(endPoint);
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

  // general checks data
  Future<GeneralChecksDataModel> generalChecksData() async {
    try {
      final response = await api.get(EndPoints.notCashedIncomingChecks);
      return GeneralChecksDataModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      Get.snackbar(
        "error".tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

  // cashed to person or cancel
  Future<Map<String, dynamic>> cashedToPersonOrCashed({
    required bool isIncoming,
    required String checkId,
    String? sellerId,
    String? customerId,
  }) async {
    try {
      final response = await api.post(
        isIncoming
            ? sellerId != null || customerId != null
                ? EndPoints.cashIncomingCheckToPerson
                : EndPoints.cashIncomingCheck
            : sellerId != null || customerId != null
                ? EndPoints.cashOutgoingCheckToPerson
                : EndPoints.cashOutgoingCheck,
        data: {
          if (isIncoming) 'incoming_check_id': checkId,
          if (!isIncoming) 'outgoing_check_id': checkId,
          if (sellerId != null) 'seller_id': sellerId,
          if (customerId != null) 'customer_id': customerId,
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

  // Get all customers and sellers
  Future<List<SellerModel>> allCustomersSellers(
      {required String endPoint}) async {
    try {
      final response = await api.get(endPoint);
      final data =
          response.data[endPoint.split('.')[0].replaceAll('/', '_')] as List;
      final sellers = data.map((e) => SellerModel.fromJson(e)).toList();

      return sellers;
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

  // general incoming data
  Future<Map<String, dynamic>> returnCheck({
    required String checkId,
    required bool isInComing,
    required bool isCancel,
  }) async {
    try {
      final response = await api.post(
          isInComing
              ? isCancel
                  ? EndPoints.cancelIncomingCheck
                  : EndPoints.returnIncomingCheck
              : isCancel
                  ? EndPoints.cancelOutgoingCheck
                  : EndPoints.returnOutgoingCheck,
          data: {
            if (isInComing) 'incoming_check_id': checkId,
            if (!isInComing) 'outgoing_check_id': checkId,
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

  // chash to box
  Future<Map<String, dynamic>> chashToBox({
    required String checkId,
    required String boxId,
    required bool isInComing,
  }) async {
    try {
      final response = await api.post(
          isInComing
              ? EndPoints.chashIncomingCheckToBox
              : EndPoints.chashOutgoingCheckToBox,
          data: {
            'box_id': boxId,
            if (isInComing)
              'incoming_check_id': checkId
            else
              'outgoing_check_id': checkId,
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

  // edit checks
  Future<Map<String, dynamic>> editChecks({
    required bool isInComing,
    required String outgoingCheckId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  }) async {
    try {
      XFile? compressedFrontImage;
      XFile? compressedBackImage;

      if (frontImage != null && !frontImage.path.contains('http')) {
        compressedFrontImage = await compressImage(frontImage);
      } else {
        compressedFrontImage = frontImage;
      }

      if (backImage != null && !backImage.path.contains('http')) {
        compressedBackImage = await compressImage(backImage);
      } else {
        compressedBackImage = backImage;
      }
      final response = await api.post(
        isInComing ? EndPoints.editIncomingCheck : EndPoints.editOutgoingCheck,
        data: {
          if (isInComing) 'incoming_check_id': outgoingCheckId,
          if (!isInComing) 'outgoing_check_id': outgoingCheckId,
          'due_date': dueDate,
          'check_id': checkId,
          'bank_name': bankName,
          if (frontImage == null) 'img': '',
          if (compressedFrontImage != null)
            if (compressedFrontImage.path.contains('http'))
              'img': compressedFrontImage.path.split('/').last,
          if (compressedFrontImage != null)
            if (!compressedFrontImage.path.contains('http'))
              'img': await MultipartFile.fromFile(
                compressedFrontImage.path,
                filename: compressedFrontImage.path.split('/').last,
              ),
          if (frontImage == null) 'front_image': '',
          if (compressedFrontImage != null)
            if (compressedFrontImage.path.contains('http'))
              'front_image': compressedFrontImage.path.split('/').last,
          if (compressedFrontImage != null)
            if (!compressedFrontImage.path.contains('http'))
              'front_image': await MultipartFile.fromFile(
                compressedFrontImage.path,
                filename: compressedFrontImage.path.split('/').last,
              ),
          if (backImage == null) 'back_image': '',
          if (compressedBackImage != null)
            if (compressedBackImage.path.contains('http'))
              'back_image': compressedBackImage.path.split('/').last,
          if (compressedBackImage != null)
            if (!compressedBackImage.path.contains('http'))
              'back_image': await MultipartFile.fromFile(
                compressedBackImage.path,
                filename: compressedBackImage.path.split('/').last,
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

  // delete check
  Future<Map<String, dynamic>> deleteCheck(
      {required String checkId, required bool isInComing}) async {
    try {
      final response = await api.post(
        isInComing
            ? EndPoints.deleteIncomingCheck
            : EndPoints.deleteOutgoingCheck,
        data: {
          if (isInComing) 'incoming_check_id': checkId,
          if (!isInComing) 'outgoing_check_id': checkId
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

Future<XFile> compressImage(XFile file) async {
  final lower = file.path.toLowerCase();
  try {
    final tempDir = await getTemporaryDirectory();
    // 🎥 ضغط الفيديوهات
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm')) {
      final compressedVideo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality, // اختيارات: Low / Medium / High
        deleteOrigin: false,
        includeAudio: true,
      );
      if (compressedVideo != null && compressedVideo.file != null) {
        return XFile(compressedVideo.file!.path);
      } else {
        return file;
      }
    }
    // 🖼️ ضغط الصور
    String sourcePath = file.path;
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      final jpgPath = p.join(
        tempDir.path,
        'converted_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final converted = await FlutterImageCompress.compressAndGetFile(
        file.path,
        jpgPath,
        quality: 95,
        format: CompressFormat.jpeg,
      );
      if (converted != null) sourcePath = converted.path;
    }
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 85,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (compressedImage == null) return file;
    return XFile(compressedImage.path);
  } catch (e) {
    return file;
  }
}
