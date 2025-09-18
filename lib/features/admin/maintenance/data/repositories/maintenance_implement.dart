import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_datasource.dart';

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
  Future<Either<Failure, String>> creatMaintenance({
    String? maintenanceId,
    required String customerId,
    required String sellerId,
    required String description,
    required String receipDate,
    required String receiptTime,
    required List<File> files,
    required String status,
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
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
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
      throw ServerFailure(e.message ?? 'error'.tr, {});
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
}
