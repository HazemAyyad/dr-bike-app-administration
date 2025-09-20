import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/my_orders_model_model.dart';

class MyOrdersDatasource {
  final ApiConsumer api;

  MyOrdersDatasource({required this.api});

  Future<List<MyOrdersModel>> getMyOrders() async {
    try {
      final response = await api.get(EndPoints.getMyOrders);
      final data = response.data['orders'] as List;
      return data.map((e) => MyOrdersModel.fromJson(e)).toList();
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
