import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

class MaintenanceDatasource {
  final ApiConsumer api;

  MaintenanceDatasource({required this.api});

  Future<dynamic> getMaintenances({required int tab}) async {
    try {
      final response = await api.get(
        tab == 0
            ? EndPoints.getNewMaintenances
            : tab == 1
                ? EndPoints.getOngoingMaintenances
                : tab == 2
                    ? EndPoints.getReadyMaintenances
                    : EndPoints.getDeliveredMaintenances,
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

  // add maintenance
  Future<dynamic> creatMaintenance({
    String? maintenanceId,
    required String customerId,
    required String sellerId,
    required String description,
    required String receipDate,
    required String receiptTime,
    required List<File> files,
    required String status,
  }) async {
    try {
      final response = await api.post(
        maintenanceId != null
            ? EndPoints.changeMaintenanceStatus
            : EndPoints.addMaintenance,
        data: {
          if (maintenanceId != null) 'maintenance_id': maintenanceId,
          'customer_id': customerId,
          'seller_id': sellerId,
          'description': description,
          'receipt_date': receipDate,
          'receipt_time': receiptTime,
          if (files.isNotEmpty)
            'files[]': await Future.wait(
              files.map((e) async {
                if (e.path.contains('http')) {
                  return e.path;
                } else {
                  return await MultipartFile.fromFile(
                    e.path,
                    filename: e.path.split('/').last,
                  );
                }
              }),
            ),
          if (status.isNotEmpty) 'status': status,
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

  // get maintenance details
  Future<dynamic> getMaintenancesDetails({
    required String maintenanceId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.showMaintenance,
        data: {'maintenance_id': maintenanceId},
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
