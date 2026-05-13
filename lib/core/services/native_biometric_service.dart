import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

class NativeBiometricResult {
  const NativeBiometricResult({
    required this.success,
    required this.available,
    this.code,
    this.codeText,
    this.message,
    this.mode,
  });

  final bool success;
  final bool available;
  final int? code;
  final String? codeText;
  final String? message;
  final String? mode;

  factory NativeBiometricResult.fromMap(Map<dynamic, dynamic> map) {
    final rawCode = map['code'];
    return NativeBiometricResult(
      success: map['success'] == true,
      available: map['available'] == true,
      code: rawCode is int ? rawCode : int.tryParse('$rawCode'),
      codeText: rawCode?.toString(),
      message: map['message']?.toString(),
      mode: map['mode']?.toString(),
    );
  }
}

class NativeBiometricService {
  NativeBiometricService._();

  static final NativeBiometricService instance = NativeBiometricService._();

  static const MethodChannel _channel = MethodChannel('dr_bike/biometric');

  Future<NativeBiometricResult> isAvailable() async {
    if (kIsWeb) {
      return const NativeBiometricResult(
        success: false,
        available: false,
        message: 'الدخول بالبصمة غير متاح على الويب',
      );
    }

    final response = await _channel.invokeMethod<dynamic>('isAvailable');
    if (response is Map) return NativeBiometricResult.fromMap(response);
    return const NativeBiometricResult(
      success: false,
      available: false,
      message: 'تعذر التحقق من توفر البصمة',
    );
  }

  Future<NativeBiometricResult> authenticate({
    String method = 'authenticate',
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (kIsWeb) {
      return const NativeBiometricResult(
        success: false,
        available: false,
        message: 'الدخول بالبصمة غير متاح على الويب',
      );
    }

    try {
      debugPrint('Native biometric call: method=$method');
      final response = await _channel.invokeMethod<dynamic>(method).timeout(
        timeout,
        onTimeout: () {
          debugPrint('Native biometric timeout: method=$method');
          throw TimeoutException('native_biometric_timeout_$method');
        },
      );
      if (response is Map) return NativeBiometricResult.fromMap(response);
      return const NativeBiometricResult(
        success: false,
        available: true,
        message: 'تعذر قراءة نتيجة التحقق بالبصمة',
      );
    } on TimeoutException {
      return NativeBiometricResult(
        success: false,
        available: true,
        code: -1001,
        codeText: 'timeout',
        message: 'انتهت مهلة التحقق، حاول مرة أخرى',
        mode: method,
      );
    } on MissingPluginException {
      rethrow;
    } catch (e) {
      debugPrint('Native biometric error: $e');
      return NativeBiometricResult(
        success: false,
        available: false,
        message: e.toString(),
      );
    }
  }
}
