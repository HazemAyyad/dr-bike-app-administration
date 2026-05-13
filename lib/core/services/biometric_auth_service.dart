import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'final_classes.dart';

class BiometricLoginData {
  const BiometricLoginData({
    required this.email,
    required this.password,
    this.token,
    this.userDataJson,
  });

  final String email;
  final String password;
  final String? token;
  final String? userDataJson;

  bool get hasCredentials => email.isNotEmpty && password.isNotEmpty;
  bool get hasToken => token != null && token!.isNotEmpty;
  bool get hasLoginData => hasCredentials || hasToken;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (token != null) 'token': token,
        if (userDataJson != null) 'userDataJson': userDataJson,
      };

  factory BiometricLoginData.fromJson(Map<String, dynamic> json) {
    return BiometricLoginData(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      token: json['token']?.toString(),
      userDataJson: json['userDataJson']?.toString(),
    );
  }
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.success,
    this.message,
    this.cancelled = false,
  });

  final bool success;
  final String? message;
  final bool cancelled;
}

class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static const _enabledKey = 'biometric_login_enabled';
  static const _loginDataKey = 'biometric_login_data';

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return const [];
    try {
      return _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  Future<BiometricAuthResult> authenticate() async {
    if (kIsWeb) {
      return const BiometricAuthResult(
        success: false,
        message: 'الدخول بالبصمة غير متاح على الويب',
      );
    }

    final isSupported = await isDeviceSupported();
    if (!isSupported) {
      return const BiometricAuthResult(
        success: false,
        message: 'جهازك لا يدعم البصمة أو التعرف على الوجه',
      );
    }

    final canCheck = await canCheckBiometrics();
    final available = await getAvailableBiometrics();
    if (!canCheck || available.isEmpty) {
      return const BiometricAuthResult(
        success: false,
        message: 'يرجى تفعيل البصمة أو الوجه من إعدادات الجهاز أولاً',
      );
    }

    try {
      final success = await _auth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك باستخدام البصمة أو الوجه',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      return BiometricAuthResult(
        success: success,
        cancelled: !success,
        message: success ? null : 'تم إلغاء المصادقة بالبصمة',
      );
    } on LocalAuthException catch (e) {
      return BiometricAuthResult(
        success: false,
        cancelled: e.code == LocalAuthExceptionCode.userCanceled ||
            e.code == LocalAuthExceptionCode.systemCanceled ||
            e.code == LocalAuthExceptionCode.timeout ||
            e.code == LocalAuthExceptionCode.userRequestedFallback,
        message: _messageForLocalAuthException(e),
      );
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        success: false,
        cancelled: true,
        message: e.message ?? 'تم إلغاء المصادقة بالبصمة',
      );
    } catch (_) {
      return const BiometricAuthResult(
        success: false,
        message: 'تعذر تشغيل الدخول بالبصمة حالياً',
      );
    }
  }

  Future<bool> isBiometricLoginEnabled() async {
    if (kIsWeb) return false;
    final value =
        await FinalClasses.secureStorage.read(key: _enabledKey) ?? 'false';
    return value == 'true';
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    if (kIsWeb) return;
    await FinalClasses.secureStorage.write(
      key: _enabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<void> saveLoginData({
    required String email,
    required String password,
    String? token,
    String? userDataJson,
  }) async {
    if (kIsWeb) return;
    final data = BiometricLoginData(
      email: email,
      password: password,
      token: token,
      userDataJson: userDataJson,
    );
    await FinalClasses.secureStorage.write(
      key: _loginDataKey,
      value: jsonEncode(data.toJson()),
    );
  }

  Future<void> clearLoginData() async {
    if (kIsWeb) return;
    await FinalClasses.secureStorage.delete(key: _loginDataKey);
  }

  Future<BiometricLoginData?> getSavedLoginData() async {
    if (kIsWeb) return null;
    final jsonString = await FinalClasses.secureStorage.read(key: _loginDataKey);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final jsonData = jsonDecode(jsonString);
      if (jsonData is! Map) return null;
      final data = BiometricLoginData.fromJson(
        Map<String, dynamic>.from(jsonData),
      );
      return data.hasLoginData ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSavedLoginData() async {
    final data = await getSavedLoginData();
    return data != null && data.hasLoginData;
  }

  String _messageForLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
        return 'جهازك لا يدعم البصمة أو التعرف على الوجه';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'يرجى تفعيل البصمة أو الوجه من إعدادات الجهاز أولاً';
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return 'محاولات كثيرة غير ناجحة، حاول لاحقاً';
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.userRequestedFallback:
        return 'تم إلغاء المصادقة بالبصمة';
      default:
        final message = e.description;
        if (message != null && message.trim().isNotEmpty) return message;
        return 'تعذر تشغيل الدخول بالبصمة حالياً';
    }
  }
}
