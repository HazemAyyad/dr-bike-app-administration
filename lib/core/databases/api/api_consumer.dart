import 'package:dio/dio.dart';

abstract class ApiConsumer {
  Future<dynamic> get(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  });
  Future<dynamic> post(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Function(int, int)? onSendProgress,
  });
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  });
  Future<dynamic> delete(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  });
}
