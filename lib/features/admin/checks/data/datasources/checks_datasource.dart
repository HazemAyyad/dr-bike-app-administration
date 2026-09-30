import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/check_model.dart';
import '../models/general_checks_data_model.dart';
import '../../domain/repositories/checks_repository.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/media/media_upload_preparer.dart';
import '../../../../../core/media/prepared_upload.dart';

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
    final preparedUploads = <PreparedUpload>[];
    try {
      PreparedUpload? preparedFrontImage;
      PreparedUpload? preparedBackImage;

      if (frontImage != null) {
        preparedFrontImage = await _prepareCheckImage(frontImage);
        preparedUploads.add(preparedFrontImage);
      }

      if (backImage != null) {
        preparedBackImage = await _prepareCheckImage(backImage);
        preparedUploads.add(preparedBackImage);
      }

      final response = await api.post(
        isInComing ? EndPoints.addIncomingCheck : EndPoints.addOutgoingCheck,
        data: {
          if (isInComing && customerId != null) 'from_customer': customerId,
          if (isInComing && sellerId != null) 'from_seller': sellerId,
          if (!isInComing && customerId != null) 'customer_id': customerId,
          if (!isInComing && sellerId != null) 'seller_id': sellerId,
          'total': total,
          'due_date': dueDate,
          'currency': currency,
          'check_id': checkId,
          'bank_name': bankName,
          // if (isInComing)
          if (preparedFrontImage != null)
            'img': await preparedFrontImage.toMultipartFile(),
          if (preparedFrontImage != null)
            'front_image': await preparedFrontImage.toMultipartFile(),
          if (preparedBackImage != null)
            'back_image': await preparedBackImage.toMultipartFile(),
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
    } finally {
      await _cleanupPrepared(preparedUploads);
    }
  }

  Future<Map<String, dynamic>> addIncomingChecksBatch({
    required bool isIncoming,
    String? customerId,
    String? sellerId,
    required DateTime receivedAt,
    required List<IncomingCheckBatchItem> checks,
  }) async {
    final preparedUploads = <PreparedUpload>[];
    try {
      final rows = <Map<String, dynamic>>[];

      for (final check in checks) {
        final preparedFrontImage = check.frontImage == null
            ? null
            : await _prepareCheckImage(check.frontImage!);
        final preparedBackImage = check.backImage == null
            ? null
            : await _prepareCheckImage(check.backImage!);
        if (preparedFrontImage != null) preparedUploads.add(preparedFrontImage);
        if (preparedBackImage != null) preparedUploads.add(preparedBackImage);

        rows.add({
          'total': check.total,
          'due_date': check.dueDate.toIso8601String(),
          'currency': check.currency,
          'check_id': check.checkId,
          'bank_name': check.bankName,
          'notes': check.notes,
          if (preparedFrontImage != null)
            'front_image': await preparedFrontImage.toMultipartFile(),
          if (preparedBackImage != null)
            'back_image': await preparedBackImage.toMultipartFile(),
        });
      }

      final response = await api.post(
        isIncoming
            ? EndPoints.addIncomingChecksBatch
            : EndPoints.addOutgoingChecksBatch,
        data: {
          if (isIncoming && customerId != null) 'from_customer': customerId,
          if (isIncoming && sellerId != null) 'from_seller': sellerId,
          if (!isIncoming && customerId != null) 'customer_id': customerId,
          if (!isIncoming && sellerId != null) 'seller_id': sellerId,
          if (isIncoming) 'received_at': receivedAt.toIso8601String(),
          'checks': rows,
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
      AppFailureNotice.show(
        title: "error".tr,
        message: e.toString(),
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
    String? customerId,
    String? sellerId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    String? total,
    String? currency,
    XFile? frontImage,
    XFile? backImage,
    required String notes,
  }) async {
    final preparedUploads = <PreparedUpload>[];
    try {
      PreparedUpload? preparedFrontImage;
      PreparedUpload? preparedBackImage;

      if (frontImage != null && !frontImage.path.contains('http')) {
        preparedFrontImage = await _prepareCheckImage(frontImage);
        preparedUploads.add(preparedFrontImage);
      }

      if (backImage != null && !backImage.path.contains('http')) {
        preparedBackImage = await _prepareCheckImage(backImage);
        preparedUploads.add(preparedBackImage);
      }
      final response = await api.post(
        isInComing ? EndPoints.editIncomingCheck : EndPoints.editOutgoingCheck,
        data: {
          if (isInComing) 'incoming_check_id': outgoingCheckId,
          if (!isInComing) 'outgoing_check_id': outgoingCheckId,
          if (isInComing && customerId != null) 'from_customer': customerId,
          if (isInComing && sellerId != null) 'from_seller': sellerId,
          if (!isInComing && customerId != null) 'customer_id': customerId,
          if (!isInComing && sellerId != null) 'seller_id': sellerId,
          if (!isInComing && total != null) 'total': total,
          if (!isInComing && currency != null) 'currency': currency,
          'due_date': dueDate,
          'check_id': checkId,
          'bank_name': bankName,
          if (frontImage == null) 'img': '',
          if (frontImage != null && frontImage.path.contains('http'))
            'img': frontImage.path.split('/').last,
          if (preparedFrontImage != null)
            'img': await preparedFrontImage.toMultipartFile(),
          if (frontImage == null) 'front_image': '',
          if (frontImage != null && frontImage.path.contains('http'))
            'front_image': frontImage.path.split('/').last,
          if (preparedFrontImage != null)
            'front_image': await preparedFrontImage.toMultipartFile(),
          if (backImage == null) 'back_image': '',
          if (backImage != null && backImage.path.contains('http'))
            'back_image': backImage.path.split('/').last,
          if (preparedBackImage != null)
            'back_image': await preparedBackImage.toMultipartFile(),
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
    } finally {
      await _cleanupPrepared(preparedUploads);
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

Future<PreparedUpload> _prepareCheckImage(XFile file) {
  return MediaUploadPreparer.prepareImageForUpload(
    file,
    profile: ImageUploadProfile.check,
  );
}

Future<void> _cleanupPrepared(Iterable<PreparedUpload> uploads) async {
  for (final upload in uploads) {
    await upload.deleteTemporaryCopy();
  }
}
