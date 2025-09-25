// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/product_development_model.dart';

class ProductManagementDatasource {
  final ApiConsumer api;

  ProductManagementDatasource({required this.api});

  Future<List<ProductDevelopmentModel>> getProductDevelopments() async {
    try {
      final response = await api.get(EndPoints.getAllProductDevelopments);
      final data = response.data['product_developments'] as List;
      return data.map((e) => ProductDevelopmentModel.fromJson(e)).toList();
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

  // creatProductDevelopment
  Future<Map<String, dynamic>> createProductDevelopment({
    required String productId,
    required String description,
    required String step,
  }) async {
    try {
      final response = await api.post(
        step.isEmpty
            ? EndPoints.createProductDevelopment
            : EndPoints.updateProductDevelopment,
        data: FormData.fromMap({
          if (step.isEmpty) 'product_id': productId,
          if (step.isEmpty) 'description': description,
          if (step.isNotEmpty) 'step': step,
          if (step.isNotEmpty) 'product_development_id': productId
        }),
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
}
