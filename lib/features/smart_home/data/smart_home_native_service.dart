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

  factory SmartHomeNativeStatus.fromMap(Map<dynamic, dynamic> map) =>
      SmartHomeNativeStatus(
        initialized: map['initialized'] == true,
        platform: map['platform']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
      );
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

class SmartHomeNativeHomeResult {
  final bool success;
  final String tuyaHomeId;
  final String name;
  final String code;
  final String message;

  const SmartHomeNativeHomeResult({
    required this.success,
    required this.tuyaHomeId,
    required this.name,
    required this.code,
    required this.message,
  });

  factory SmartHomeNativeHomeResult.fromMap(Map<dynamic, dynamic> map) =>
      SmartHomeNativeHomeResult(
        success: map['success'] == true,
        tuyaHomeId: map['tuya_home_id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        code: map['code']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
      );
}

class SmartHomeNativePairingResult {
  final bool success;
  final String code;
  final String message;
  final Map<String, dynamic> device;

  const SmartHomeNativePairingResult({
    required this.success,
    required this.code,
    required this.message,
    required this.device,
  });

  factory SmartHomeNativePairingResult.fromMap(Map<dynamic, dynamic> map) =>
      SmartHomeNativePairingResult(
        success: map['success'] == true,
        code: map['code']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
        device: map['device'] is Map
            ? Map<String, dynamic>.from(map['device'] as Map)
            : const <String, dynamic>{},
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

  Future<SmartHomeNativeHomeResult> createHome({required String name}) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'createHome',
        {'name': name},
      );
      return SmartHomeNativeHomeResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeHomeResult(
        success: false,
        tuyaHomeId: '',
        name: '',
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeHomeResult(
        success: false,
        tuyaHomeId: '',
        name: '',
        code: e.code,
        message: e.message ?? 'Tuya home creation failed',
      );
    }
  }

  Future<SmartHomeNativePairingResult> startWifiPairing({
    required String tuyaHomeId,
    required String ssid,
    required String password,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'startWifiPairing',
        {
          'tuyaHomeId': tuyaHomeId,
          'ssid': ssid,
          'password': password,
        },
      );
      return SmartHomeNativePairingResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativePairingResult(
        success: false,
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
        device: <String, dynamic>{},
      );
    } on PlatformException catch (e) {
      return SmartHomeNativePairingResult(
        success: false,
        code: e.code,
        message: e.message ?? 'Tuya WiFi pairing failed',
        device: const <String, dynamic>{},
      );
    }
  }

  Future<void> stopPairing() async {
    try {
      await _channel.invokeMethod<void>('stopPairing');
    } on MissingPluginException {
      return;
    }
  }

  Future<SmartHomeNativeStatus> getStatus() async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('status');
      return SmartHomeNativeStatus.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeStatus(
        initialized: false,
        platform: '',
        message: 'Smart Home native bridge is not available on this platform',
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeStatus(
        initialized: false,
        platform: '',
        message: e.message ?? 'Failed to read Smart Home native status',
      );
    }
  }
}
