import 'dart:io';

import 'package:dio/dio.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

class DebtLedgerDatasource {
  final ApiConsumer api;

  DebtLedgerDatasource({required this.api});

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await api.get(EndPoints.debtLedgerSummary);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getPeople({
    required String type,
    String? search,
    String? startDate,
    String? endDate,
    String? currency,
    int? categoryId,
  }) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerPeople,
        queryParameters: {
          'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
          if (categoryId != null) 'category_id': categoryId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getPeoplePicker({
    required String type,
    String? search,
  }) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerPeoplePicker,
        queryParameters: {
          'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await api.get(EndPoints.contactCategories);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> saveCategory({
    int? id,
    required String name,
    required String color,
    List<int> customerIds = const [],
    List<int> sellerIds = const [],
  }) async {
    try {
      final response = await api.post(
        id == null
            ? EndPoints.contactCategories
            : EndPoints.contactCategoryUpdate(id),
        data: {
          'name': name,
          'color': color,
          'customer_ids': customerIds,
          'seller_ids': sellerIds,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await api.post(EndPoints.contactCategoryDelete(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> createPersonShareLink({
    int? customerId,
    int? sellerId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerPersonShareLink,
        data: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> updatePersonMeta({
    int? customerId,
    int? sellerId,
    String? notes,
    String? collectionReminderAt,
    bool clearCollectionReminder = false,
    bool updateNotes = false,
    bool updateReminder = false,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (customerId != null) 'customer_id': customerId,
        if (sellerId != null) 'seller_id': sellerId,
        if (updateNotes) 'notes': notes ?? '',
        if (updateReminder && clearCollectionReminder)
          'clear_collection_reminder': true,
        if (updateReminder &&
            !clearCollectionReminder &&
            collectionReminderAt != null)
          'collection_reminder_at': collectionReminderAt,
      };

      final response = await api.post(
        EndPoints.debtLedgerPersonMeta,
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getPerson({
    int? customerId,
    int? sellerId,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerPerson,
        queryParameters: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    int? customerId,
    int? sellerId,
    required String type,
    required String amount,
    required String transactionDate,
    String? currency,
    String? note,
    String? boxId,
    List<File>? receiptImages,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (customerId != null) 'customer_id': customerId.toString(),
        if (sellerId != null) 'seller_id': sellerId.toString(),
        'type': type,
        'amount': amount,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        'transaction_date': transactionDate,
        if (note != null && note.isNotEmpty) 'note': note,
        if (boxId != null && boxId.isNotEmpty) 'box_id': boxId,
      };

      if (receiptImages != null && receiptImages.isNotEmpty) {
        payload['receipt_images[]'] = await Future.wait(
          receiptImages.map((file) async {
            return await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(RegExp(r'[/\\]')).last,
            );
          }),
        );
      }

      final response = await api.post(
        EndPoints.debtLedgerTransaction,
        data: payload,
        isFormData: true,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getTransaction(int id) async {
    try {
      final response = await api.get(EndPoints.debtLedgerTransactionDetail(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> updateTransaction({
    required int id,
    required String type,
    required String amount,
    required String transactionDate,
    String? currency,
    String? note,
    String? boxId,
    List<File>? receiptImages,
  }) async {
    try {
      final payload = <String, dynamic>{
        'type': type,
        'amount': amount,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        'transaction_date': transactionDate,
        if (note != null && note.isNotEmpty) 'note': note,
        if (boxId != null && boxId.isNotEmpty) 'box_id': boxId,
      };

      if (receiptImages != null && receiptImages.isNotEmpty) {
        payload['receipt_images[]'] = await Future.wait(
          receiptImages.map((file) async {
            return await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(RegExp(r'[/\\]')).last,
            );
          }),
        );
      }

      final response = await api.post(
        EndPoints.debtLedgerUpdateTransaction(id),
        data: payload,
        isFormData: true,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getPersonArchive({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerPersonArchive,
        queryParameters: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getPersonDeleted({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerPersonDeleted,
        queryParameters: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> archiveTransactionsBulk(
    List<int> transactionIds,
  ) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerArchiveBulk,
        data: {'transaction_ids': transactionIds},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> restoreTransactionsBulk(
    List<int> transactionIds,
  ) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerRestoreBulk,
        data: {'transaction_ids': transactionIds},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> archiveTransaction(int id) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerArchiveTransaction(id),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> deleteTransaction(int id) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerDeleteTransaction(id),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Uint8List> downloadReport({
    int? customerId,
    int? sellerId,
    String? period,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerPersonReport,
        data: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          if (period != null) 'period': period,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
        options: Options(responseType: ResponseType.bytes),
        isFormData: true,
      );
      return response.data as Uint8List;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> generateReportJson({
    int? customerId,
    int? sellerId,
    String? period,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    try {
      final response = await api.post(
        EndPoints.debtLedgerPersonReport,
        data: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          if (period != null) 'period': period,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
          'json_response': true,
        },
        isFormData: true,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getTransactionActivity(int id) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerTransactionActivity(id),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> getPersonActivity({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async {
    try {
      final response = await api.get(
        EndPoints.debtLedgerPersonActivity,
        queryParameters: {
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  ServerException _serverException(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return ServerException(
        ErrorModel(
          errorMessage: data['message']?.toString() ?? 'Unknown error',
          status: _parseStatus(data['status']),
          data: data['data'] ?? {},
        ),
      );
    }
    return ServerException(
      ErrorModel(
        errorMessage: e.message ?? 'Unknown error',
        status: 500,
        data: {},
      ),
    );
  }

  int _parseStatus(dynamic status) {
    if (status is int) return status;
    return int.tryParse(status?.toString() ?? '') ?? 500;
  }
}
