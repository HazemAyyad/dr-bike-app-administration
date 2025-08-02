import 'package:dio/dio.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import '../../../../core/errors/error_model.dart';
import '../../../../core/errors/expentions.dart';

class CommonDatasource {
  final ApiConsumer api;

  CommonDatasource({required this.api});

  Future<Map<String, dynamic>> userProfile({
    required String token,
    required String name,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
  }) async {
    try {
      final response = await api.post(
        EndPoints.updateProfile,
        data: {
          'name': name,
          'phone': phone,
          'sub_phone': subPhone,
          'city': city,
          'address': address,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
