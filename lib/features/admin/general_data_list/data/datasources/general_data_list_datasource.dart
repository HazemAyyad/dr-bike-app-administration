import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/employee_data_model.dart';

class GeneralDataListDatasource {
  final ApiConsumer api;

  GeneralDataListDatasource({required this.api});

  Future<List<GeneralDataModel>> getGeneralList(
      {bool isSellers = false}) async {
    try {
      final response = await api.get(
        isSellers ? EndPoints.mainPageSellers : EndPoints.mainPageCustomers,
      );
      List<GeneralDataModel> generalDataList = (response.data['data'] as List)
          .map((e) => GeneralDataModel.fromJson(e))
          .toList();
      return generalDataList;
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
