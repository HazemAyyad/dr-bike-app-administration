import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

import '../../../routes/app_routes.dart';
import '../../helpers/api_error_message.dart';
import '../../errors/error_model.dart';
import '../../errors/expentions.dart';
import '../../services/languague_service.dart';
import '../../services/user_data.dart';
import 'api_consumer.dart';
import 'end_points.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
      } else {
        final dynamic rawMsg =
            (data is Map && data['message'] != null) ? data['message'] : e.message;
        errorMessage = apiErrorMessageFromPayload(
          rawMsg,
          fallback: 'حدث خطأ غير معروف',
        );
      }

      if (data is Map && data['message'] == 'Unauthenticated.') {
        await DefaultCacheManager().emptyCache();
        UserData.clearAllUserData();
        getx.Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        getx.Get.snackbar(
          'error'.tr,
          'لقد انتهت مهلة الأتصال، برجاء تسجيل الدخول مرة أخرى',
          snackPosition: getx.SnackPosition.BOTTOM,
        );
      }
      throw ServerException(
        ErrorModel(
          errorMessage: errorMessage,
          status: (data is Map && data['status'] != null)
              ? data['status']
              : statusCode,
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
      } else {
        final dynamic rawMsg =
            (data is Map && data['message'] != null) ? data['message'] : e.message;
        errorMessage = apiErrorMessageFromPayload(
          rawMsg,
          fallback: 'حدث خطأ غير معروف',
        );
      }
      if (data is Map && data['message'] == 'Unauthenticated.') {
        await DefaultCacheManager().emptyCache();
        UserData.clearAllUserData();
        getx.Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        getx.Get.snackbar(
          'error'.tr,
          'لقد انتهت مهلة الأتصال، برجاء تسجيل الدخول مرة أخرى',
          snackPosition: getx.SnackPosition.BOTTOM,
        );
      }
      throw ServerException(
        ErrorModel(
          errorMessage: errorMessage,
          status: (data is Map && data['status'] != null)
              ? data['status']
              : statusCode,
          data: (data is Map && data['data'] != null) ? data['data'] : {},
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
}
