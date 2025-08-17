import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

import '../../errors/error_model.dart';
import '../../errors/expentions.dart';
import '../../services/languague_service.dart';
import '../../services/user_data.dart';
import 'api_consumer.dart';
import 'end_points.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    dio.options.baseUrl = EndPoints.baserUrl;
    // بعض الخيارات الافتراضية
    dio.options.connectTimeout = Duration(seconds: 5);
    dio.options.receiveTimeout = Duration(seconds: 5);
    dio.options.headers = {
      'Accept': 'application/json',
      'lang': getx.Get.find<LanguageController>().getLang(),
    };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await UserData.getUserToken();
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  //!POST
  @override
  Future<Response> post(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: isFormData && data is Map<String, dynamic>
            ? FormData.fromMap(data)
            : data,
        options: options,
        queryParameters: queryParameters,
        onSendProgress: onSendProgress,
      );
      return response; // إعادة الكائن الكامل
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: (data is Map && data['message'] != null)
              ? data['message']
              : 'unknown_error',
          status: (data is Map && data['status'] != null)
              ? data['status']
              : e.response?.statusCode ?? 500,
          data: (data is Map && data['data'] != null) ? data['data'] : {},
        ),
      );
    }
  }

  //!GET
  @override
  Future<Response> get(
    String path, {
    Options? options,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        path,
        options: options,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      print('==========Test================${e.response}');
      handleDioException(e);
      rethrow;
    }
  }

  //!DELETE
  @override
  Future<Response> delete(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: data,
        options: options,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      print('==========Test================${e.response}');
      handleDioException(e);
      rethrow;
    }
  }

  //!PATCH
  @override
  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.patch(
        path,
        options: options,
        data: isFormData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      print('==========Test================${e.response}');
      handleDioException(e);
      rethrow;
    }
  }
}
