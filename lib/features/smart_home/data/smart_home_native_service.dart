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

class SmartHomeNativeDeviceResult {
  final bool success;
  final String code;
  final String message;
  final Map<String, dynamic> device;
  final Map<String, dynamic> dps;
  final bool online;

  const SmartHomeNativeDeviceResult({
    required this.success,
    required this.code,
    required this.message,
    required this.device,
    required this.dps,
    required this.online,
  });

  factory SmartHomeNativeDeviceResult.fromMap(Map<dynamic, dynamic> map) {
    final rawDevice = map['device'];
    final rawDps = map['dps'];
    return SmartHomeNativeDeviceResult(
      success: map['success'] == true,
      code: map['code']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      device: rawDevice is Map
          ? Map<String, dynamic>.from(rawDevice)
          : const <String, dynamic>{},
      dps: rawDps is Map
          ? Map<String, dynamic>.from(rawDps)
          : const <String, dynamic>{},
      online: map['online'] == true,
    );
  }
}

class SmartHomeBleScanDevice {
  const SmartHomeBleScanDevice({
    required this.raw,
    required this.uuid,
    required this.name,
    required this.configType,
    required this.productId,
    required this.mac,
    required this.address,
    required this.deviceType,
    required this.rssi,
  });

  final Map<String, dynamic> raw;
  final String uuid;
  final String name;
  final String configType;
  final String productId;
  final String mac;
  final String address;
  final int deviceType;
  final int rssi;

  bool get isWifiCombo => configType == 'config_type_wifi';

  String get displayName {
    if (name.isNotEmpty) return name;
    if (productId.isNotEmpty) return productId;
    if (uuid.isNotEmpty) return uuid;
    return 'Bluetooth device';
  }

  factory SmartHomeBleScanDevice.fromMap(Map<dynamic, dynamic> map) {
    final raw = Map<String, dynamic>.from(map);
    return SmartHomeBleScanDevice(
      raw: raw,
      uuid: map['uuid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      configType: map['config_type']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      mac: map['mac']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      deviceType: map['device_type'] is int
          ? map['device_type'] as int
          : int.tryParse(map['device_type']?.toString() ?? '') ?? 0,
      rssi: map['rssi'] is int
          ? map['rssi'] as int
          : int.tryParse(map['rssi']?.toString() ?? '') ?? 0,
    );
  }
}

class SmartHomeNativeBleScanResult {
  final bool success;
  final String code;
  final String message;
  final List<SmartHomeBleScanDevice> devices;

  const SmartHomeNativeBleScanResult({
    required this.success,
    required this.code,
    required this.message,
    required this.devices,
  });

  factory SmartHomeNativeBleScanResult.fromMap(Map<dynamic, dynamic> map) {
    final rawDevices = map['devices'];
    return SmartHomeNativeBleScanResult(
      success: map['success'] == true,
      code: map['code']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      devices: rawDevices is List
          ? rawDevices
              .whereType<Map>()
              .map((item) => SmartHomeBleScanDevice.fromMap(item))
              .toList(growable: false)
          : const <SmartHomeBleScanDevice>[],
    );
  }
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

  Future<SmartHomeNativeBleScanResult> scanBluetoothDevices({
    int timeoutMs = 10000,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'scanBluetoothDevices',
        {'timeoutMs': timeoutMs},
      );
      return SmartHomeNativeBleScanResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeBleScanResult(
        success: false,
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
        devices: <SmartHomeBleScanDevice>[],
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeBleScanResult(
        success: false,
        code: e.code,
        message: e.message ?? 'Tuya Bluetooth scan failed',
        devices: const <SmartHomeBleScanDevice>[],
      );
    }
  }

  Future<SmartHomeNativePairingResult> startBluetoothPairing({
    required String tuyaHomeId,
    required SmartHomeBleScanDevice scanDevice,
    required String ssid,
    required String password,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'startBluetoothPairing',
        {
          'tuyaHomeId': tuyaHomeId,
          'scanDevice': scanDevice.raw,
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
        message: e.message ?? 'Tuya Bluetooth pairing failed',
        device: const <String, dynamic>{},
      );
    }
  }

  Future<SmartHomeNativeDeviceResult> getDeviceStatus({
    required String tuyaDeviceId,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getDeviceStatus',
        {'tuyaDeviceId': tuyaDeviceId},
      );
      return SmartHomeNativeDeviceResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeDeviceResult(
        success: false,
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
        device: <String, dynamic>{},
        dps: <String, dynamic>{},
        online: false,
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeDeviceResult(
        success: false,
        code: e.code,
        message: e.message ?? 'Tuya device status failed',
        device: const <String, dynamic>{},
        dps: const <String, dynamic>{},
        online: false,
      );
    }
  }

  Future<SmartHomeNativeDeviceResult> renameDevice({
    required String tuyaDeviceId,
    required String name,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'renameDevice',
        {'tuyaDeviceId': tuyaDeviceId, 'name': name},
      );
      return SmartHomeNativeDeviceResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeDeviceResult(
        success: false,
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
        device: <String, dynamic>{},
        dps: <String, dynamic>{},
        online: false,
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeDeviceResult(
        success: false,
        code: e.code,
        message: e.message ?? 'Tuya device rename failed',
        device: const <String, dynamic>{},
        dps: const <String, dynamic>{},
        online: false,
      );
    }
  }

  Future<SmartHomeNativeDeviceResult> publishDps({
    required String tuyaDeviceId,
    required String dpId,
    required String code,
    required String type,
    required dynamic value,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'publishDps',
        {
          'tuyaDeviceId': tuyaDeviceId,
          'dpId': dpId,
          'code': code,
          'type': type,
          'value': value,
        },
      );
      return SmartHomeNativeDeviceResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeDeviceResult(
        success: false,
        code: 'missing_plugin',
        message: 'Smart Home native bridge is not available on this platform',
        device: <String, dynamic>{},
        dps: <String, dynamic>{},
        online: false,
      );
    } on PlatformException catch (e) {
      return SmartHomeNativeDeviceResult(
        success: false,
        code: e.code,
        message: e.message ?? 'Tuya DPS command failed',
        device: const <String, dynamic>{},
        dps: const <String, dynamic>{},
        online: false,
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
