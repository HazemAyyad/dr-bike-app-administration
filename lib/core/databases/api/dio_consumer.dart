import 'package:dio/dio.dart';

import '../../errors/error_model.dart';
import '../../errors/expentions.dart';
import '../../services/languague_service.dart';
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
      'lang': LanguageController().getLang()
    };
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
        data:
            isFormData ? FormData.fromMap(data as Map<String, dynamic>) : data,
        options: options,
        queryParameters: queryParameters,
        onSendProgress: onSendProgress,
      );
      return response; // إعادة الكائن الكامل
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'unknown_error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }
  //   print('==========Test================${e.response}');
  //   handleDioException(e);
  //   return e.response ??
  //       Response(
  //         requestOptions = RequestOptions(path: path),
  //         statusCode = 500,
  //         data = {
  //           'message': 'unknown_error',
  //         },
  //       );
  // }
  // }

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
