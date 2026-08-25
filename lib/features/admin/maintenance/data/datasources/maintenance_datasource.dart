import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../../../sales/data/models/daily_session_model.dart';
import '../models/maintenance_activity_log_model.dart';
import '../models/maintenance_invoice_model.dart';
import '../models/maintenance_product_model.dart';
import '../models/maintenance_service_model.dart';

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
                    : tab == 3
                        ? EndPoints.getDeliveredMaintenances
                        : EndPoints.getArchivedMaintenances,
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
    String? receipDate,
    String? receiptTime,
    required List<File> files,
    required String status,
    double? laborCost,
    double? discount,
    String? editReason,
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
          if (receipDate != null) 'receipt_date': receipDate,
          if (receiptTime != null) 'receipt_time': receiptTime,
          if (laborCost != null) 'labor_cost': laborCost,
          if (discount != null) 'discount': discount,
          if (editReason != null && editReason.trim().isNotEmpty)
            'edit_reason': editReason.trim(),
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

  Future<dynamic> deleteMaintenance({
    required String maintenanceId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.deleteMaintenance,
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
    String? editReason,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceSyncProducts,
        data: {
          'maintenance_id': maintenanceId,
          if (laborCost != null) 'labor_cost': laborCost,
          if (discount != null) 'discount': discount,
          if (editReason != null && editReason.trim().isNotEmpty)
            'edit_reason': editReason.trim(),
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
    List<Map<String, dynamic>> payments = const [],
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
          if (payments.isNotEmpty) 'payments': payments,
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

  Future<List<MaintenanceServiceModel>> getMaintenanceServices({
    String? search,
    bool activeOnly = false,
  }) async {
    try {
      final response = await api.get(
        EndPoints.maintenanceServices,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (activeOnly) 'active_only': 1,
        },
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        return ((data['services'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => MaintenanceServiceModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
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

  Future<List<MaintenanceServiceModel>> searchMaintenanceServices(
      String query) async {
    try {
      final response = await api.get(
        EndPoints.maintenanceServicesSearch,
        queryParameters: {'q': query, 'limit': 10},
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        return ((data['services'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => MaintenanceServiceModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      return const <MaintenanceServiceModel>[];
    } on DioException catch (_) {
      return const <MaintenanceServiceModel>[];
    }
  }

  Future<Map<String, dynamic>> saveMaintenanceService({
    int? serviceId,
    required String name,
    required String description,
    required double price,
    required bool isActive,
    required List<File> media,
    List<int> keepMediaIds = const [],
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('name', name),
        MapEntry('description', description),
        MapEntry('price', price.toString()),
        MapEntry('is_active', isActive ? '1' : '0'),
        ...keepMediaIds.map(
          (id) => MapEntry('keep_media_ids[]', id.toString()),
        ),
      ]);
      for (final file in media) {
        formData.files.add(
          MapEntry(
            'media[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await api.post(
        serviceId == null
            ? EndPoints.maintenanceServices
            : EndPoints.maintenanceService(serviceId),
        data: formData,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'تعذر رفع الوسائط')
              : 'تعذر رفع الوسائط. تحقق من حجم الملف والاتصال ثم حاول مرة أخرى.',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : const {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> deleteMaintenanceService(int serviceId) async {
    try {
      final response =
          await api.delete(EndPoints.maintenanceService(serviceId));
      return Map<String, dynamic>.from(response.data as Map);
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

  Future<dynamic> getDailySessionCurrent() async {
    try {
      final response = await api.get(EndPoints.maintenanceDailySessionCurrent);
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

  Future<dynamic> openDailySession({double openingBalance = 0}) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceDailySessionOpen,
        data: {'opening_balance': openingBalance},
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

  Future<dynamic> requestDailySessionClosing({
    String? note,
    double? physicalCount,
    double? floatToKeep,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceDailySessionRequestClosing,
        data: {
          if (note != null && note.trim().isNotEmpty) 'note': note,
          if (physicalCount != null) 'physical_count': physicalCount,
          if (floatToKeep != null) 'float_to_keep': floatToKeep,
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

  Future<dynamic> getPendingDailyClosing() async {
    try {
      final response = await api.get(EndPoints.maintenanceDailyClosingPending);
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

  Future<dynamic> getOpenDailySessions() async {
    try {
      final response = await api.get(EndPoints.maintenanceDailySessionsOpen);
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

  Future<List<DailySessionSummaryModel>> getDailySessionsHistory({
    String? fromDate,
    String? toDate,
    String? status,
  }) async {
    try {
      final response = await api.get(
        EndPoints.maintenanceDailySessions,
        queryParameters: {
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
          if (status != null && status.isNotEmpty) 'status': status,
          'per_page': 50,
        },
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        return mapList(
          data['sessions'],
          (Map<String, dynamic> m) => DailySessionSummaryModel.fromJson(m),
        );
      }
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
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

  Future<DailySessionDetailModel> getDailySessionDetail(int sessionId) async {
    try {
      final response = await api.get(
        EndPoints.maintenanceDailySessionDetail(sessionId),
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final detail = data['session_detail'];
        if (detail is Map) {
          return DailySessionDetailModel.fromJson(
            Map<String, dynamic>.from(detail),
          );
        }
      }
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
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

  Future<dynamic> directCloseDailySession({
    required int sessionId,
    int? toBoxId,
    String? reviewNote,
    double? physicalCount,
    double? floatToKeep,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceDailyClosingDirect,
        data: {
          'session_id': sessionId,
          if (toBoxId != null) 'to_box_id': toBoxId,
          if (reviewNote != null && reviewNote.trim().isNotEmpty)
            'review_note': reviewNote,
          if (physicalCount != null) 'physical_count': physicalCount,
          if (floatToKeep != null) 'float_to_keep': floatToKeep,
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

  Future<dynamic> approveDailyClosing({
    required int closingRequestId,
    int? toBoxId,
    String? reviewNote,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceDailyClosingApprove,
        data: {
          'closing_request_id': closingRequestId,
          if (toBoxId != null) 'to_box_id': toBoxId,
          if (reviewNote != null && reviewNote.trim().isNotEmpty)
            'review_note': reviewNote,
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

  Future<dynamic> rejectDailyClosing({
    required int closingRequestId,
    String? reviewNote,
  }) async {
    try {
      final response = await api.post(
        EndPoints.maintenanceDailyClosingReject,
        data: {
          'closing_request_id': closingRequestId,
          if (reviewNote != null && reviewNote.trim().isNotEmpty)
            'review_note': reviewNote,
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
