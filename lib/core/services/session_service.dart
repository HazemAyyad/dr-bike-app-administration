import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

import '../../features/auth/data/models/login_response_parser.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import 'biometric_auth_service.dart';
import 'initial_bindings.dart';
import 'user_data.dart';

const _loginRoutes = <String>{
  AppRoutes.LOGINORSIGNUPSCREEN,
  AppRoutes.LOGINSCREEN,
};

class SessionValidationResult {
  const SessionValidationResult({
    required this.isValid,
    required this.isAuthFailure,
  });

  final bool isValid;
  final bool isAuthFailure;
}

/// Session restore, validation, and forced logout when the API rejects auth.
class SessionService {
  static bool _redirectingToLogin = false;

  /// فشل جلسة مؤكد (انتهاء توكن / غير مصادق) — لا يُستخدم لأخطاء الشبكة.
  static bool isDefiniteAuthFailure(dynamic data, int? statusCode) {
    if (statusCode == 401) return true;
    if (data is! Map) return false;

    final message = data['message']?.toString().trim() ?? '';
    if (message.isEmpty) return false;

    const exactMatches = {
      'Unauthenticated.',
      'Token expired',
      'تحتاج لتسجيل الدخول',
      'you need to login',
    };
    if (exactMatches.contains(message)) return true;

    final lower = message.toLowerCase();
    return lower.contains('unauthenticated') ||
        (lower.contains('token') && lower.contains('expired'));
  }

  static Future<void> hydrateToken() async {
    UserData.userToken = await UserData.getUserToken();
  }

  static Future<void> restoreGlobalsFromStorage() async {
    final userdata = await UserData.getSavedUser();
    if (userdata == null) return;

    employeePermissions
      ..clear()
      ..addAll(userdata.employeePermissions.map((p) => p.permissionId));
    syncSessionIdentity(
      type: userdata.user.type,
      name: userdata.user.name,
      permissionIds:
          userdata.employeePermissions.map((p) => p.permissionId).toList(),
    );
    userName = userdata.user.name;
  }

  static Future<SessionValidationResult> validateAndRefreshSession() async {
    await hydrateToken();
    if (UserData.userToken.isEmpty) {
      return const SessionValidationResult(
        isValid: false,
        isAuthFailure: false,
      );
    }

    try {
      final api = Get.find<DioConsumer>();
      final response = await api.post(EndPoints.me);
      final data = response.data;
      if (data is! Map) {
        return const SessionValidationResult(
          isValid: false,
          isAuthFailure: false,
        );
      }

      final map = Map<String, dynamic>.from(data);
      if (isDefiniteAuthFailure(map, response.statusCode)) {
        return const SessionValidationResult(
          isValid: false,
          isAuthFailure: true,
        );
      }

      if (!isLoginSuccessStatus(map['status'])) {
        return const SessionValidationResult(
          isValid: false,
          isAuthFailure: false,
        );
      }

      final user = UserModel.fromJson(map);
      await UserData.saveUser(user);
      await restoreGlobalsFromStorage();
      return const SessionValidationResult(isValid: true, isAuthFailure: false);
    } on DioException catch (e) {
      if (isDefiniteAuthFailure(e.response?.data, e.response?.statusCode)) {
        return const SessionValidationResult(
          isValid: false,
          isAuthFailure: true,
        );
      }
      return const SessionValidationResult(
        isValid: false,
        isAuthFailure: false,
      );
    } catch (_) {
      return const SessionValidationResult(
        isValid: false,
        isAuthFailure: false,
      );
    }
  }

  static Future<void> clearSessionAndGoToLogin({bool showMessage = true}) async {
    if (_redirectingToLogin) return;
    if (_loginRoutes.contains(Get.currentRoute)) return;

    _redirectingToLogin = true;
    try {
      await DefaultCacheManager().emptyCache();
      await UserData.clearAllUserData();
      if (!kIsWeb) {
        await BiometricAuthService.instance.setBiometricLoginEnabled(false);
        await BiometricAuthService.instance.clearLoginData();
      }
      Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
      if (showMessage) {
        Get.snackbar(
          'error'.tr,
          'لقد انتهت مهلة الأتصال، برجاء تسجيل الدخول مرة أخرى',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      _redirectingToLogin = false;
    }
  }

  static Future<void> handleAuthFailureIfNeeded(
    dynamic data,
    int? statusCode,
  ) async {
    if (isDefiniteAuthFailure(data, statusCode)) {
      await clearSessionAndGoToLogin();
    }
  }

  static Future<void> handleDioAuthFailure(DioException e) async {
    await handleAuthFailureIfNeeded(
      e.response?.data,
      e.response?.statusCode,
    );
  }
}
