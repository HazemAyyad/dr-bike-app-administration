import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../models/maintenance_activity_log_model.dart';
import '../models/maintenance_invoice_model.dart';
import '../datasources/maintenance_datasource.dart';
import '../models/maintenance_product_model.dart';

class MaintenanceImplement implements MaintenanceRepository {
  final MaintenanceDatasource maintenanceDatasource;
  final NetworkInfo networkInfo;

  MaintenanceImplement(
      {required this.maintenanceDatasource, required this.networkInfo});

  @override
  Future<dynamic> getMaintenances({required int tab}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await maintenanceDatasource.getMaintenances(tab: tab);
        return result;
      } on ServerException catch (e) {
        Get.snackbar(
          "error".tr,
          e.errorModel.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> creatMaintenance({
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
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await maintenanceDatasource.creatMaintenance(
        maintenanceId: maintenanceId,
        customerId: customerId,
        sellerId: sellerId,
        description: description,
        receipDate: receipDate,
        receiptTime: receiptTime,
        files: files,
        status: status,
        laborCost: laborCost,
        discount: discount,
      );
      if (result['status'] == 'success') {
        return Right({
          'message': result['message']?.toString() ?? '',
          'maintenance_id':
              result['maintenance_id']?.toString() ?? maintenanceId ?? '',
        });
      } else {
        return Left(
          ValidationFailure(
            result['message'] ?? 'Unknown error',
            result,
          ),
        );
      }
    } on DioException catch (e) {
      Get.snackbar(
        "error".tr,
        e.message ?? 'error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return Left(ServerFailure(e.message ?? 'error'.tr, {}));
    }
  }

  @override
  Future getMaintenancesDetails({required String maintenanceId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await maintenanceDatasource.getMaintenancesDetails(
          maintenanceId: maintenanceId,
        );
        return result;
      } on ServerException catch (e) {
        Get.snackbar(
          "error".tr,
          e.errorModel.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  @override
  Future<Either<Failure, MaintenanceBillingModel>> syncMaintenanceProducts({
    required String maintenanceId,
    required List<MaintenanceProductModel> products,
    double? laborCost,
    double? discount,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await maintenanceDatasource.syncMaintenanceProducts(
        maintenanceId: maintenanceId,
        products: products,
        laborCost: laborCost,
        discount: discount,
      );
      if (result['status'] == 'success') {
        return Right(
          MaintenanceBillingModel.fromJson(
            Map<String, dynamic>.from(result['billing'] ?? {}),
          ),
        );
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'error'.tr, {}));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> deliverMaintenance({
    required String maintenanceId,
    double? laborCost,
    double? discount,
    double? paymentAmount,
    int? paymentBoxId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await maintenanceDatasource.deliverMaintenance(
        maintenanceId: maintenanceId,
        laborCost: laborCost,
        discount: discount,
        paymentAmount: paymentAmount,
        paymentBoxId: paymentBoxId,
      );
      if (result['status'] == 'success') {
        return Right(Map<String, dynamic>.from(result));
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'error'.tr, {}));
    }
  }

  @override
  Future<Either<Failure, List<MaintenanceActivityLogModel>>> getActivityLog({
    required String maintenanceId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      return Right(
        await maintenanceDatasource.getActivityLog(
          maintenanceId: maintenanceId,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, MaintenanceInvoiceModel>> getMaintenanceInvoice({
    required String maintenanceId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      return Right(
        await maintenanceDatasource.getMaintenanceInvoice(
          maintenanceId: maintenanceId,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
