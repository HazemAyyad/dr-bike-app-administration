import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../models/maintenance_activity_log_model.dart';
import '../models/maintenance_invoice_model.dart';
import '../models/maintenance_product_model.dart';

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
    double? laborCost,
    double? discount,
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
          if (laborCost != null) 'labor_cost': laborCost,
          if (discount != null) 'discount': discount,
          if (files.isNotEmpty)
            'files[]': await Future.wait(
              files.map((e) async {
                if (e.path.contains('http')) {
                  return e.path;
                } else {
                  final compressedImg = await compressImage(XFile(e.path));
                  return await MultipartFile.fromFile(
                    compressedImg.path,
                    filename: compressedImg.path.split('/').last,
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

  Future<dynamic> syncMaintenanceProducts({
    required String maintenanceId,
    required List<MaintenanceProductModel> products,
    double? laborCost,
    double? discount,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceSyncProducts,
        data: {
          'maintenance_id': maintenanceId,
          if (laborCost != null) 'labor_cost': laborCost,
          if (discount != null) 'discount': discount,
          'products': products.map((e) => e.toApiJson()).toList(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<dynamic> deliverMaintenance({
    required String maintenanceId,
    double? laborCost,
    double? discount,
    double? paymentAmount,
    int? paymentBoxId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceDeliver,
        data: {
          'maintenance_id': maintenanceId,
          if (laborCost != null) 'labor_cost': laborCost,
          if (discount != null) 'discount': discount,
          if (paymentAmount != null) 'payment_amount': paymentAmount,
          if (paymentBoxId != null) 'payment_box_id': paymentBoxId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<List<MaintenanceActivityLogModel>> getActivityLog({
    required String maintenanceId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceActivityLog,
        data: {'maintenance_id': maintenanceId},
      );
      final data = response.data;
      if (data['status'] != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: data['message'] ?? 'Unknown error',
            status: data['status'] ?? 500,
            data: data,
          ),
        );
      }
      final logs = data['logs'];
      return logs is List
          ? logs
              .map((e) => MaintenanceActivityLogModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : <MaintenanceActivityLogModel>[];
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<MaintenanceInvoiceModel> getMaintenanceInvoice({
    required String maintenanceId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceInvoice,
        data: {'maintenance_id': maintenanceId},
      );
      final data = response.data;
      if (data['status'] != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: data['message'] ?? 'Unknown error',
            status: data['status'] ?? 500,
            data: data,
          ),
        );
      }
      return MaintenanceInvoiceModel.fromJson(
        Map<String, dynamic>.from(data['invoice'] as Map),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }
}
