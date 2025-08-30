import 'package:doctorbike/core/errors/expentions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';

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
  Future<List<GeneralDataModel>> getGeneralList(
      {bool isSellers = false}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await generalDataListDatasource.getGeneralList(
          isSellers: isSellers,
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
