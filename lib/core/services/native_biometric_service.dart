import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

class NativeBiometricResult {
  const NativeBiometricResult({
    required this.success,
    required this.available,
    this.code,
    this.message,
  });

  final bool success;
  final bool available;
  final int? code;
  final String? message;

  factory NativeBiometricResult.fromMap(Map<dynamic, dynamic> map) {
    return NativeBiometricResult(
      success: map['success'] == true,
      available: map['available'] == true,
      code: map['code'] is int ? map['code'] as int : int.tryParse('${map['code']}'),
      message: map['message']?.toString(),
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

  Future<NativeBiometricResult> authenticate() async {
    if (kIsWeb) {
      return const NativeBiometricResult(
        success: false,
        available: false,
        message: 'الدخول بالبصمة غير متاح على الويب',
      );
    }

    try {
      final response = await _channel.invokeMethod<dynamic>('authenticate').timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('native_biometric_timeout');
        },
      );
      if (response is Map) return NativeBiometricResult.fromMap(response);
      return const NativeBiometricResult(
        success: false,
        available: true,
        message: 'تعذر قراءة نتيجة التحقق بالبصمة',
      );
    } on TimeoutException {
      return const NativeBiometricResult(
        success: false,
        available: true,
        message: 'انتهت مهلة التحقق، حاول مرة أخرى',
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
