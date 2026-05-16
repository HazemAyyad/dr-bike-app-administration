// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../../presentation/controllers/payment_controller.dart';

class PaymentDatasource {
  final ApiConsumer api;

  PaymentDatasource({required this.api});

  Future<Map<String, dynamic>> addPayment({
    required String type,
    required String customerId,
    required String sellerId,
    required String boxId,
    required String boxValue,
    required List<PaymentModel> checks,
    String? boxLogNote,
  }) async {
    try {
      final checksMap = <String, dynamic>{};
      checksMap.addAll({
        'type': type,
        if (customerId.isNotEmpty) 'customer_id': customerId,
        if (sellerId.isNotEmpty) 'seller_id': sellerId,
        if (boxId.isNotEmpty) 'box_id': boxId,
        if (boxValue.isNotEmpty) 'box_value': boxValue,
        if (boxLogNote != null && boxLogNote.trim().isNotEmpty)
          'box_log_note': boxLogNote.trim(),
      });

      for (int i = 0; i < checks.length; i++) {
        if (checks[i].checkValue.text.isNotEmpty) {
          checksMap['checks[$i][check_value]'] = checks[i].checkValue.text;
          if (checks[i].dueDate.text.trim().isNotEmpty) {
            checksMap['checks[$i][due_date]'] = checks[i].dueDate.text.trim();
          }
          checksMap['checks[$i][check_currency]'] = checks[i].currency.text;
          checksMap['checks[$i][check_id]'] = checks[i].checkNumber.text;
          checksMap['checks[$i][bank_name]'] = checks[i].bankName.text;
          if (checks[i].selectedFile.value != null) {
            final compressedImg =
                await compressImage(XFile(checks[i].selectedFile.value!.path));
            checksMap['checks[$i][img]'] = await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }
        }
        if (checks[i].debtValue.text.isNotEmpty) {
          checksMap['debts[$i][total]'] = checks[i].debtValue.text;
          if (checks[i].dueDate.text.trim().isNotEmpty) {
            checksMap['debts[$i][due_date]'] = checks[i].dueDate.text.trim();
          }
          if (boxId.isNotEmpty) {
            checksMap['debts[$i][box_id]'] = boxId;
          }
        }
      }
      final response = await api.post(
        EndPoints.addTransaction,
        data: checksMap,
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map
          ? (data['message']?.toString() ?? 'Unknown error')
          : (data?.toString() ?? e.message ?? 'Unknown error');
      throw ServerException(
        ErrorModel(
          errorMessage: message,
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }
}
