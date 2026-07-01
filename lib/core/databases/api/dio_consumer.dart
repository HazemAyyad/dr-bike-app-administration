import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

import '../../helpers/api_error_message.dart';
import '../../errors/error_model.dart';
import '../../errors/expentions.dart';
import '../../services/languague_service.dart';
import '../../services/session_service.dart';
import '../../services/user_data.dart';
import 'api_consumer.dart';
import 'end_points.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    dio.options.baseUrl = EndPoints.baserUrl;
    // بعض الخيارات الافتراضية
    dio.options.connectTimeout = const Duration(seconds: 120);
    dio.options.sendTimeout = const Duration(seconds: 120);
    dio.options.receiveTimeout = const Duration(seconds: 120);
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
        onResponse: (response, handler) async {
          final authHeader =
              response.requestOptions.headers['Authorization']?.toString() ??
                  '';
          if (authHeader.isNotEmpty) {
            await SessionService.handleAuthFailureIfNeeded(
              response.data,
              response.statusCode,
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          await SessionService.handleDioAuthFailure(error);
          return handler.next(error);
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
      Future.delayed(const Duration(milliseconds: 1500), () {
        getx.Get.closeAllSnackbars();
      });
      return response; // إعادة الكائن الكامل
    } on DioException catch (e) {
      // print('==========Test================$e');
      final data = e.response?.data;

      String errorMessage;
      int statusCode = e.response?.statusCode ?? 500;

      if (statusCode == 429 ||
          (data is Map && data['message'] == "Too Many Attempts.")) {
        // رسالة مخصصة للمستخدم
        errorMessage = "لقد قمت بمحاولات كثيرة، برجاء المحاولة بعد قليل.";
      } else if (statusCode == 503 || statusCode == 502 || statusCode == 504) {
        errorMessage =
            'السيرفر غير متاح حالياً. تحقق من الاتصال أو جرّب بعد قليل.';
      } else {
        final dynamic rawMsg = (data is Map && data['message'] != null)
            ? data['message']
            : e.message;
        errorMessage = apiErrorMessageFromPayload(
          rawMsg,
          fallback: 'حدث خطأ غير معروف',
        );
      }

      throw ServerException(
        ErrorModel(
          errorMessage: errorMessage,
          status: _resolveErrorStatus(data, statusCode),
          data: (data is Map) ? (data['errors'] ?? data['data'] ?? data) : {},
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
      Future.delayed(const Duration(milliseconds: 1000), () {
        getx.Get.closeAllSnackbars();
      });
      return response;
    } on DioException catch (e) {
      // print('==========Test================$e');
      final data = e.response?.data;

      String errorMessage;
      int statusCode = e.response?.statusCode ?? 500;

      if (statusCode == 429 ||
          (data is Map && data['message'] == "Too Many Attempts.")) {
        // رسالة مخصصة للمستخدم
        errorMessage = "لقد قمت بمحاولات كثيرة، برجاء المحاولة بعد قليل.";
      } else if (statusCode == 503 || statusCode == 502 || statusCode == 504) {
        errorMessage =
            'السيرفر غير متاح حالياً. تحقق من الاتصال أو جرّب بعد قليل.';
      } else {
        final dynamic rawMsg = (data is Map && data['message'] != null)
            ? data['message']
            : e.message;
        errorMessage = apiErrorMessageFromPayload(
          rawMsg,
          fallback: 'حدث خطأ غير معروف',
        );
      }
      throw ServerException(
        ErrorModel(
          errorMessage: errorMessage,
          status: _resolveErrorStatus(data, statusCode),
          data: (data is Map) ? (data['errors'] ?? data['data'] ?? data) : {},
        ),
      );
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
      handleDioException(e);
      rethrow;
    }
  }

  //!PUT
  @override
  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    try {
      final response = await dio.put(
        path,
        options: options,
        data: isFormData && data is Map<String, dynamic>
            ? FormData.fromMap(data)
            : data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      final data = e.response?.data;

      String errorMessage;
      int statusCode = e.response?.statusCode ?? 500;

      if (statusCode == 429 ||
          (data is Map && data['message'] == "Too Many Attempts.")) {
        errorMessage = "لقد قمت بمحاولات كثيرة، برجاء المحاولة بعد قليل.";
      } else {
        final dynamic rawMsg = (data is Map && data['message'] != null)
            ? data['message']
            : e.message;
        errorMessage = apiErrorMessageFromPayload(
          rawMsg,
          fallback: 'حدث خطأ غير معروف',
        );
      }

      throw ServerException(
        ErrorModel(
          errorMessage: errorMessage,
          status: _resolveErrorStatus(data, statusCode),
          data: (data is Map && data['data'] != null) ? data['data'] : {},
        ),
      );
    }
  }

  static int _resolveErrorStatus(dynamic data, int httpStatusCode) {
    if (data is! Map) return httpStatusCode;
    final value = data['status'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? httpStatusCode;
  }
}
