import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/person_data_model.dart';
import 'package:doctorbike/features/admin/general_data_list/domain/entity/add_person_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/general_data_list_repository.dart';
import '../datasources/general_data_list_datasource.dart';
import '../models/employee_data_model.dart';

class GeneralDataListImplement implements GeneralDataListRepository {
  final GeneralDataListDatasource generalDataListDatasource;
  final NetworkInfo networkInfo;

  GeneralDataListImplement(
      {required this.generalDataListDatasource, required this.networkInfo});

  // get employee list
  @override
  Future<List<GeneralDataModel>> getGeneralList({required int tab}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await generalDataListDatasource.getGeneralList(tab: tab);
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
  Future<Either<Failure, String>> addPerson({
    required AddPersonEntity data,
    required String customerId,
    required String sellerId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await generalDataListDatasource.addPerson(
        data: data,
        customerId: customerId,
        sellerId: sellerId,
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
  Future<PersonDataModel> getPersonData(
      {required String customerId, required String sellerId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await generalDataListDatasource.getPersonData(
          customerId: customerId,
          sellerId: sellerId,
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
