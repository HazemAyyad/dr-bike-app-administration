// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

class ScanQrCodeDatasource {
  final ApiConsumer api;

  ScanQrCodeDatasource({required this.api});

  // scan QR code
  Future<Map<String, dynamic>> qrScan({required String qrData}) async {
    try {
      final response =
          await api.post(EndPoints.qrScan, data: {'qr_data': qrData});
      final data = response.data;
      // print('Response data: $response');
      return data;
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
