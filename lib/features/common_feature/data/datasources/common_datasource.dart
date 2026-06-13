import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import '../../../../core/errors/error_model.dart';
import '../../../../core/errors/expentions.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../../../core/services/user_data.dart';
import '../../../auth/data/models/user_model.dart';

class CommonDatasource {
  final ApiConsumer api;

  CommonDatasource({required this.api});

  Future<Map<String, dynamic>> userProfile({
    required String name,
    required String email,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'phone': phone.isEmpty ? null : phone,
      'sub_phone': subPhone.isEmpty ? null : subPhone,
      'city': city.isEmpty ? null : city,
      'address': address.isEmpty ? null : address,
    };

    if (kDebugMode) {
      debugPrint('[ProfileUpdate] POST ${EndPoints.updateProfile}');
      debugPrint('[ProfileUpdate] payload: $payload');
    }

    try {
      final response = await api.post(
        EndPoints.updateProfile,
        data: payload,
      );

      if (kDebugMode) {
        debugPrint(
          '[ProfileUpdate] HTTP ${response.statusCode} response: ${response.data}',
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      final raw = {'status': 'error', 'message': data?.toString() ?? 'Invalid response'};
      if (kDebugMode) {
        debugPrint('[ProfileUpdate] non-map response: $raw');
      }
      return raw;
    } on DioException catch (e) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;

      if (kDebugMode) {
        debugPrint('[ProfileUpdate] DioException status=$statusCode');
        debugPrint('[ProfileUpdate] DioException type=${e.type} message=${e.message}');
        debugPrint('[ProfileUpdate] DioException response data: $data');
      }

      throw ServerException(
        ErrorModel(
          errorMessage: data is Map && data['message'] != null
              ? data['message'].toString()
              : (e.message ?? 'Unknown error'),
          status: data is Map && data['status'] != null
              ? data['status']
              : (statusCode ?? 500),
          data: data is Map
              ? Map<String, dynamic>.from(data)
              : {
                  'status': 'error',
                  'message': data?.toString() ?? e.message,
                  'http_status': statusCode,
                },
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProfileUpdate] unexpected error: $e');
        debugPrint('[ProfileUpdate] stack: $st');
      }
      rethrow;
    }
  }

  // get user Data
  Future<UserModel> getUserData() async {
    try {
      final response = await api.post(EndPoints.me);
      final raw = response.data;
      if (raw is Map && raw['status'] != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw['message']?.toString() ?? 'فشل تحميل بيانات المستخدم',
            status: raw['status'] ?? 'error',
            data: raw,
          ),
        );
      }
      final user = UserModel.fromJson(response.data);
      await UserData.saveUser(user);
      final userdata = await UserData.getSavedUser();
      if (userdata != null) {
        final permissionIds =
            userdata.employeePermissions.map((p) => p.permissionId).toList();
        employeePermissions.addAll(permissionIds);
        userType = userdata.user.type;
      }
      return user;
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
