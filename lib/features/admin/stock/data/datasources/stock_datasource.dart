// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../../../core/databases/api/api_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../core/errors/error_model.dart';
import '../../../../../../core/errors/expentions.dart';

class StockDataSource {
  final ApiConsumer api;

  StockDataSource({required this.api});

  Future<Map<String, dynamic>> getAllStock({required int page}) async {
    try {
      final response = await api
          .get(EndPoints.getProductsList, queryParameters: {'page': page});
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
