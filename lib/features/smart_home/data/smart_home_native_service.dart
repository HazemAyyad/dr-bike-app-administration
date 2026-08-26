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

class SmartHomeNativeSceneResult {
  const SmartHomeNativeSceneResult({
    required this.success,
    required this.sceneId,
    required this.code,
    required this.message,
  });

  final bool success;
  final String sceneId;
  final String code;
  final String message;

  factory SmartHomeNativeSceneResult.fromMap(Map<dynamic, dynamic> map) =>
      SmartHomeNativeSceneResult(
        success: map['success'] == true,
        sceneId: map['scene_id']?.toString() ?? '',
        code: map['code']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
      );
}

class SmartHomeNativeSceneLog {
  const SmartHomeNativeSceneLog({
    required this.eventId,
    required this.sceneId,
    required this.sceneName,
    required this.status,
    required this.message,
    required this.failureCode,
    required this.failureCause,
    required this.executedAt,
    required this.runMode,
  });

  final String eventId;
  final String sceneId;
  final String sceneName;
  final String status;
  final String message;
  final String failureCode;
  final String failureCause;
  final DateTime? executedAt;
  final String runMode;

  factory SmartHomeNativeSceneLog.fromMap(Map<dynamic, dynamic> map) {
    final rawTime = int.tryParse(map['executed_at']?.toString() ?? '');
    return SmartHomeNativeSceneLog(
      eventId: map['event_id']?.toString() ?? '',
      sceneId: map['scene_id']?.toString() ?? '',
      sceneName: map['scene_name']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      failureCode: map['failure_code']?.toString() ?? '',
      failureCause: map['failure_cause']?.toString() ?? '',
      executedAt: rawTime == null || rawTime <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(rawTime).toLocal(),
      runMode: map['run_mode']?.toString() ?? '',
    );
  }
}

class SmartHomeNativeSceneLogsResult {
  const SmartHomeNativeSceneLogsResult({
    required this.success,
    required this.code,
    required this.message,
    required this.logs,
  });

  final bool success;
  final String code;
  final String message;
  final List<SmartHomeNativeSceneLog> logs;

  factory SmartHomeNativeSceneLogsResult.fromMap(Map<dynamic, dynamic> map) {
    final rawLogs = map['logs'];
    return SmartHomeNativeSceneLogsResult(
      success: map['success'] == true,
      code: map['code']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      logs: rawLogs is List
          ? rawLogs
              .whereType<Map>()
              .map((item) => SmartHomeNativeSceneLog.fromMap(item))
              .toList(growable: false)
          : const <SmartHomeNativeSceneLog>[],
    );
  }
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

  Future<SmartHomeNativeLoginResult> saveDeviceSchedule({
    required String tuyaDeviceId,
    required String taskName,
    required String aliasName,
    required String dpId,
    required dynamic value,
    required String time,
    required String loops,
    required bool enabled,
    required bool replace,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'saveDeviceSchedule',
        {
          'tuyaDeviceId': tuyaDeviceId,
          'taskName': taskName,
          'aliasName': aliasName,
          'dpId': dpId,
          'value': value,
          'time': time,
          'loops': loops,
          'enabled': enabled,
          'replace': replace,
        },
      );
      return SmartHomeNativeLoginResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeLoginResult(
        success: false,
        uid: '',
        code: 'missing_plugin',
        message: 'Tuya schedules are not available on this platform',
      );
    } on PlatformException catch (error) {
      return SmartHomeNativeLoginResult(
        success: false,
        uid: '',
        code: error.code,
        message: error.message ?? 'Tuya schedule failed',
      );
    }
  }

  Future<SmartHomeNativeLoginResult> deleteDeviceSchedule({
    required String tuyaDeviceId,
    required String taskName,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'deleteDeviceSchedule',
        {'tuyaDeviceId': tuyaDeviceId, 'taskName': taskName},
      );
      return SmartHomeNativeLoginResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeLoginResult(
        success: false,
        uid: '',
        code: 'missing_plugin',
        message: 'Tuya schedules are not available on this platform',
      );
    } on PlatformException catch (error) {
      return SmartHomeNativeLoginResult(
        success: false,
        uid: '',
        code: error.code,
        message: error.message ?? 'Tuya schedule deletion failed',
      );
    }
  }

  Future<SmartHomeNativeSceneResult> saveScene({
    required String tuyaHomeId,
    required String name,
    required String previousSceneId,
    required String matchType,
    required List<Map<String, dynamic>> conditions,
    required List<Map<String, dynamic>> actions,
  }) =>
      _sceneCall('saveScene', {
        'tuyaHomeId': tuyaHomeId,
        'name': name,
        'previousSceneId': previousSceneId,
        'matchType': matchType,
        'conditions': conditions,
        'actions': actions,
      });

  Future<SmartHomeNativeSceneResult> executeScene(String sceneId) =>
      _sceneCall('executeScene', {'sceneId': sceneId});

  Future<SmartHomeNativeSceneLogsResult> getSceneLogs({
    required String tuyaHomeId,
    int days = 30,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getSceneLogs',
        {'tuyaHomeId': tuyaHomeId, 'days': days},
      );
      return SmartHomeNativeSceneLogsResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeSceneLogsResult(
        success: false,
        code: 'missing_plugin',
        message: 'Tuya scene logs are not available on this platform',
        logs: [],
      );
    } on PlatformException catch (error) {
      return SmartHomeNativeSceneLogsResult(
        success: false,
        code: error.code,
        message: error.message ?? 'Tuya scene logs failed',
        logs: const [],
      );
    }
  }

  Future<SmartHomeNativeSceneResult> deleteScene(String sceneId) =>
      _sceneCall('deleteScene', {'sceneId': sceneId});

  Future<SmartHomeNativeSceneResult> setSceneEnabled({
    required String sceneId,
    required bool enabled,
  }) =>
      _sceneCall('setSceneEnabled', {'sceneId': sceneId, 'enabled': enabled});

  Future<SmartHomeNativeSceneResult> _sceneCall(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        method,
        arguments,
      );
      return SmartHomeNativeSceneResult.fromMap(result ?? const {});
    } on MissingPluginException {
      return const SmartHomeNativeSceneResult(
        success: false,
        sceneId: '',
        code: 'missing_plugin',
        message: 'Tuya scenes are not available on this platform',
      );
    } on PlatformException catch (error) {
      return SmartHomeNativeSceneResult(
        success: false,
        sceneId: '',
        code: error.code,
        message: error.message ?? 'Tuya scene operation failed',
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
    String? tuyaHomeId,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'getDeviceStatus',
        {
          'tuyaDeviceId': tuyaDeviceId,
          if (tuyaHomeId != null && tuyaHomeId.isNotEmpty)
            'tuyaHomeId': tuyaHomeId,
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
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => <dynamic, dynamic>{
          'success': false,
          'code': 'rename_timeout',
          'message': 'Tuya device rename timed out',
          'device': <String, dynamic>{},
          'dps': <String, dynamic>{},
          'online': false,
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
        message: e.message ?? 'Tuya device rename failed',
        device: const <String, dynamic>{},
        dps: const <String, dynamic>{},
        online: false,
      );
    }
  }

  Future<SmartHomeNativeDeviceResult> removeDevice({
    required String tuyaDeviceId,
    String? tuyaHomeId,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        'removeDevice',
        {
          'tuyaDeviceId': tuyaDeviceId,
          if (tuyaHomeId != null && tuyaHomeId.isNotEmpty)
            'tuyaHomeId': tuyaHomeId,
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
        message: e.message ?? 'Tuya device remove failed',
        device: const <String, dynamic>{},
        dps: const <String, dynamic>{},
        online: false,
      );
    }
  }

  Future<SmartHomeNativeDeviceResult> publishDps({
    required String tuyaDeviceId,
    String? tuyaHomeId,
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
          if (tuyaHomeId != null && tuyaHomeId.isNotEmpty)
            'tuyaHomeId': tuyaHomeId,
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
