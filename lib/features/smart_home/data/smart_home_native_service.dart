import 'package:flutter/services.dart';

class SmartHomeNativeStatus {
  final bool initialized;
  final String platform;
  final String message;

  const SmartHomeNativeStatus({
    required this.initialized,
    required this.platform,
    required this.message,
  });

  factory SmartHomeNativeStatus.fromMap(Map<dynamic, dynamic> map) {
    return SmartHomeNativeStatus(
      initialized: map['initialized'] == true,
      platform: map['platform']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
    );
  }
}

class SmartHomeNativeLoginResult {
  final bool success;
  final String uid;
  final String code;
  final String message;

  const SmartHomeNativeLoginResult({
    required this.success,
    required this.uid,
    required this.code,
    required this.message,
  });

  factory SmartHomeNativeLoginResult.fromMap(Map<dynamic, dynamic> map) =>
      SmartHomeNativeLoginResult(
        success: map['success'] == true,
        uid: map['uid']?.toString() ?? '',
        code: map['code']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
      );
}

class SmartHomeNativeService {
  static const MethodChannel _channel = MethodChannel('dr_bike/smart_home');

  Future<SmartHomeNativeLoginResult> loginWithUid({
    required String countryCode,
    required String uid,
    required String password,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'loginWithUid',
        {
          'countryCode': countryCode,
          'uid': uid,
          'password': password,
        },
      );
      return SmartHomeNativeLoginResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeLoginResult(
        success: false,
        uid: '',
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeLoginResult(
        success: false,
        uid: '',
        code: e.code,
        message: e.message ?? 'Tuya UID login failed',
      );
    }
  }

  Future<SmartHomeNativeStatus> getStatus() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('status');
      return SmartHomeNativeStatus.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeStatus(
        initialized: false,
        platform: 'unsupported',
        message: 'Smart Home native bridge is not available on this platform.',
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeStatus(
        initialized: false,
        platform: 'android',
        message: e.message ?? 'Smart Home native bridge failed.',
      );
    }
  }
}
