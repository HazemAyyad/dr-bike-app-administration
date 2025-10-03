import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/checks_repository.dart';
import '../datasources/checks_datasource.dart';
import '../models/check_model.dart';
import '../models/general_checks_data_model.dart';

class ChecksImplement implements ChecksRepository {
  final NetworkInfo networkInfo;
  final ChecksDatasource checksDatasource;

  ChecksImplement({required this.networkInfo, required this.checksDatasource});

  // add checks
  @override
  Future<Either<Failure, String>> addChecks({
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await checksDatasource.addChecks(
        isInComing: isInComing,
        customerId: customerId,
        sellerId: sellerId,
        total: total,
        dueDate: dueDate,
        currency: currency,
        checkId: checkId,
        bankName: bankName,
        frontImage: frontImage,
        backImage: backImage,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // get not cashed
  @override
  Future<dynamic> getChecks({required String endPoint}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await checksDatasource.getChecks(endPoint: endPoint);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // general checks
  @override
  Future<GeneralChecksDataModel> generalChecksData() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await checksDatasource.generalChecksData();
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
  }

  // cashed to person or cancel
  @override
  Future<Either<Failure, String>> cashedToPersonOrCashed({
    required bool isInComing,
    required String checkId,
    String? sellerId,
    String? customerId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await checksDatasource.cashedToPersonOrCashed(
        isIncoming: isInComing,
        checkId: checkId,
        sellerId: sellerId,
        customerId: customerId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // all customers and sellers
  @override
  Future<List<SellerModel>> allCustomersSellers(
      {required String endPoint}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await checksDatasource.allCustomersSellers(endPoint: endPoint);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // @override
  // Future<dynamic> generalOutgoingData({required bool isInComing}) async {
  //   if (!await networkInfo.isConnected) {
  //     throw NoConnectionFailure();
  //   }
  //   try {
  //     final result =
  //         await checksDatasource.generalOutgoingData(isInComing: isInComing);
  //     return result;
  //   } on ServerException catch (e) {
  //     throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
  //   }
  // }

  @override
  Future<Either<Failure, String>> returnCheck({
    required String checkId,
    required bool isInComing,
    required bool isCancel,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await checksDatasource.returnCheck(
        checkId: checkId,
        isInComing: isInComing,
        isCancel: isCancel,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> chashToBox(
      {required String boxId, required String checkId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await checksDatasource.chashToBox(
        checkId: checkId,
        boxId: boxId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> editChecks({
    required bool isInComing,
    required String outgoingCheckId,
    required DateTime dueDate,
    required String checkId,
    required String bankName,
    XFile? frontImage,
    XFile? backImage,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await checksDatasource.editChecks(
        isInComing: isInComing,
        outgoingCheckId: outgoingCheckId,
        dueDate: dueDate,
        checkId: checkId,
        bankName: bankName,
        frontImage: frontImage,
        backImage: backImage,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
