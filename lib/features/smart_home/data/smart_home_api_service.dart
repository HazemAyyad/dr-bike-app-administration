import 'dart:convert';

import 'package:get/get.dart';

import '../../../core/databases/api/dio_consumer.dart';
import '../../../core/databases/api/end_points.dart';

class SmartHomeTuyaUserModel {
  final int userId;
  final String tuyaUid;
  final String region;
  final String lastLoginAt;
  final bool linked;
  final SmartHomeUidLoginCredentials? uidLogin;

  const SmartHomeTuyaUserModel({
    required this.userId,
    required this.tuyaUid,
    required this.region,
    required this.lastLoginAt,
    required this.linked,
    required this.uidLogin,
  });

  factory SmartHomeTuyaUserModel.fromJson(Map<String, dynamic> json) {
    final rawLogin = json['uid_login'];
    return SmartHomeTuyaUserModel(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      tuyaUid: json['tuya_uid']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      lastLoginAt: json['last_login_at']?.toString() ?? '',
      linked: json['linked'] == true ||
          (json['tuya_uid']?.toString().isNotEmpty ?? false),
      uidLogin: rawLogin is Map
          ? SmartHomeUidLoginCredentials.fromJson(
              Map<String, dynamic>.from(rawLogin),
            )
          : null,
    );
  }
}

class SmartHomeUidLoginCredentials {
  final String countryCode;
  final String uid;
  final String password;

  const SmartHomeUidLoginCredentials({
    required this.countryCode,
    required this.uid,
    required this.password,
  });

  factory SmartHomeUidLoginCredentials.fromJson(Map<String, dynamic> json) =>
      SmartHomeUidLoginCredentials(
        countryCode: json['country_code']?.toString() ?? '970',
        uid: json['uid']?.toString() ?? '',
        password: json['password']?.toString() ?? '',
      );
}

class SmartHomeOwnerModel {
  final int id;
  final String name;
  final String phone;
  final String type;
  final int homesCount;
  final int devicesCount;
  final int onlineDevicesCount;

  const SmartHomeOwnerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.homesCount,
    required this.devicesCount,
    required this.onlineDevicesCount,
  });

  factory SmartHomeOwnerModel.fromJson(Map<String, dynamic> json) =>
      SmartHomeOwnerModel(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        homesCount: int.tryParse(json['homes_count']?.toString() ?? '') ?? 0,
        devicesCount:
            int.tryParse(json['devices_count']?.toString() ?? '') ?? 0,
        onlineDevicesCount:
            int.tryParse(json['online_devices_count']?.toString() ?? '') ?? 0,
      );
}

class SmartHomeModel {
  final int id;
  final String name;
  final String tuyaHomeId;
  final String type;
  final String status;
  final bool isDefault;
  final int devicesCount;
  final int onlineDevicesCount;
  final int offlineDevicesCount;

  const SmartHomeModel({
    required this.id,
    required this.name,
    required this.tuyaHomeId,
    required this.type,
    required this.status,
    required this.isDefault,
    required this.devicesCount,
    required this.onlineDevicesCount,
    required this.offlineDevicesCount,
  });

  factory SmartHomeModel.fromJson(Map<String, dynamic> json) => SmartHomeModel(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        tuyaHomeId: json['tuya_home_id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'home',
        status: json['status']?.toString() ?? 'active',
        isDefault: json['is_default'] == true,
        devicesCount:
            int.tryParse(json['devices_count']?.toString() ?? '') ?? 0,
        onlineDevicesCount:
            int.tryParse(json['online_devices_count']?.toString() ?? '') ?? 0,
        offlineDevicesCount:
            int.tryParse(json['offline_devices_count']?.toString() ?? '') ?? 0,
      );
}

class SmartRoomModel {
  final int id;
  final int smartHomeId;
  final String name;
  final int sortOrder;
  final int devicesCount;

  const SmartRoomModel({
    required this.id,
    required this.smartHomeId,
    required this.name,
    required this.sortOrder,
    required this.devicesCount,
  });

  factory SmartRoomModel.fromJson(Map<String, dynamic> json) => SmartRoomModel(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        smartHomeId: int.tryParse(json['smart_home_id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
        sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
        devicesCount:
            int.tryParse(json['devices_count']?.toString() ?? '') ?? 0,
      );
}

class SmartDeviceFunctionModel {
  final int id;
  final int smartDeviceId;
  final String dpId;
  final String code;
  final String displayName;
  final String functionType;
  final String icon;
  final int sortOrder;
  final bool isVisible;

  const SmartDeviceFunctionModel({
    required this.id,
    required this.smartDeviceId,
    required this.dpId,
    required this.code,
    required this.displayName,
    required this.functionType,
    required this.icon,
    required this.sortOrder,
    required this.isVisible,
  });

  factory SmartDeviceFunctionModel.fromJson(Map<String, dynamic> json) =>
      SmartDeviceFunctionModel(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        smartDeviceId:
            int.tryParse(json['smart_device_id']?.toString() ?? '') ?? 0,
        dpId: json['dp_id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        displayName: json['display_name']?.toString() ?? '',
        functionType: json['function_type']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
        isVisible: json['is_visible'] != false,
      );
}

class SmartDeviceModel {
  final int id;
  final int? smartHomeId;
  final int? smartRoomId;
  final String roomName;
  final String tuyaDeviceId;
  final String tuyaProductId;
  final String tuyaUuid;
  final String name;
  final String category;
  final String productName;
  final String icon;
  final String protocol;
  final bool online;
  final String model;
  final String manufacturer;
  final String primaryPowerDp;
  final bool? powerOn;
  final Map<String, dynamic> lastStatus;
  final Map<String, dynamic> rawMetadata;
  final List<SmartDeviceFunctionModel> functions;

  const SmartDeviceModel({
    required this.id,
    required this.smartHomeId,
    required this.smartRoomId,
    required this.roomName,
    required this.tuyaDeviceId,
    required this.tuyaProductId,
    required this.tuyaUuid,
    required this.name,
    required this.category,
    required this.productName,
    required this.icon,
    required this.protocol,
    required this.online,
    required this.model,
    required this.manufacturer,
    required this.primaryPowerDp,
    required this.powerOn,
    required this.lastStatus,
    required this.rawMetadata,
    required this.functions,
  });

  bool get canTogglePower => primaryPowerDp.isNotEmpty;

  SmartDeviceModel copyWith({
    Object? smartHomeId = _noValue,
    Object? smartRoomId = _noValue,
    String? name,
    bool? online,
    Object? powerOn = _noValue,
    String? primaryPowerDp,
    Map<String, dynamic>? lastStatus,
    Map<String, dynamic>? rawMetadata,
    List<SmartDeviceFunctionModel>? functions,
  }) =>
      SmartDeviceModel(
        id: id,
        smartHomeId:
            smartHomeId == _noValue ? this.smartHomeId : smartHomeId as int?,
        smartRoomId:
            smartRoomId == _noValue ? this.smartRoomId : smartRoomId as int?,
        roomName: smartRoomId == _noValue
            ? roomName
            : (smartRoomId == null ? '' : roomName),
        tuyaDeviceId: tuyaDeviceId,
        tuyaProductId: tuyaProductId,
        tuyaUuid: tuyaUuid,
        name: name ?? this.name,
        category: category,
        productName: productName,
        icon: icon,
        protocol: protocol,
        online: online ?? this.online,
        model: model,
        manufacturer: manufacturer,
        primaryPowerDp: primaryPowerDp ?? this.primaryPowerDp,
        powerOn: powerOn == _noValue ? this.powerOn : powerOn as bool?,
        lastStatus: lastStatus ?? this.lastStatus,
        rawMetadata: rawMetadata ?? this.rawMetadata,
        functions: functions ?? this.functions,
      );

  factory SmartDeviceModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['last_status'];
    final rawMetadata = json['raw_metadata'];
    final rawFunctions = json['functions'];
    final rawHomeId = json['smart_home_id'];
    final rawRoom = json['room'];
    return SmartDeviceModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      smartHomeId:
          rawHomeId == null ? null : int.tryParse(rawHomeId.toString()),
      smartRoomId: int.tryParse(json['smart_room_id']?.toString() ?? ''),
      roomName: rawRoom is Map ? rawRoom['name']?.toString() ?? '' : '',
      tuyaDeviceId: json['tuya_device_id']?.toString() ?? '',
      tuyaProductId: json['tuya_product_id']?.toString() ?? '',
      tuyaUuid: json['tuya_uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      protocol: json['protocol']?.toString() ?? '',
      online: json['online'] == true,
      model: json['model']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      primaryPowerDp: json['primary_power_dp']?.toString() ?? '',
      powerOn: json['power_on'] is bool ? json['power_on'] as bool : null,
      lastStatus: _mapFromDynamic(rawStatus),
      rawMetadata: _mapFromDynamic(rawMetadata),
      functions: rawFunctions is List
          ? rawFunctions
              .whereType<Map>()
              .map((item) => SmartDeviceFunctionModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id > 0 && item.code.isNotEmpty)
              .toList(growable: false)
          : const <SmartDeviceFunctionModel>[],
    );
  }
}

Map<String, dynamic> _mapFromDynamic(dynamic raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
  return const <String, dynamic>{};
}

class _NoValue {
  const _NoValue();
}

const _noValue = _NoValue();

class SmartHomeApiService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<void> storeEventLog({
    int? smartHomeId,
    required String event,
    required bool success,
    String? errorCode,
    String? message,
    Map<String, dynamic>? context,
  }) async {
    await _api.post(EndPoints.smartHomeEventLogs, data: {
      if (smartHomeId != null) 'smart_home_id': smartHomeId,
      'event': event,
      'success': success,
      if (errorCode != null && errorCode.isNotEmpty) 'error_code': errorCode,
      if (message != null && message.isNotEmpty) 'message': message,
      if (context != null) 'context': context,
    });
  }

  Future<SmartHomeTuyaUserModel> getTuyaUser({int? userId}) async {
    final response = await _api.get(
      EndPoints.smartTuyaUser,
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
    return SmartHomeTuyaUserModel.fromJson(
      Map<String, dynamic>.from(response.data['tuya_user'] as Map),
    );
  }

  Future<SmartHomeTuyaUserModel> updateTuyaUser({
    required String tuyaUid,
    String? region,
    Map<String, dynamic>? rawMetadata,
    int? userId,
  }) async {
    final response = await _api.put(
      EndPoints.smartTuyaUser,
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        'tuya_uid': tuyaUid,
        if (region != null && region.isNotEmpty) 'region': region,
        if (rawMetadata != null) 'raw_metadata': rawMetadata,
      },
    );
    return SmartHomeTuyaUserModel.fromJson(
      Map<String, dynamic>.from(response.data['tuya_user'] as Map),
    );
  }

  Future<List<SmartHomeOwnerModel>> getOwners() async {
    final response = await _api.get(EndPoints.smartHomeOwners);
    return _extractList(response.data, const ['owners'])
        .whereType<Map>()
        .map(
          (item) =>
              SmartHomeOwnerModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id > 0)
        .toList();
  }

  Future<List<SmartHomeModel>> getHomes({int? userId}) async {
    final response = await _api.get(
      EndPoints.smartHomes,
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
    return _extractList(response.data, const ['homes'])
        .whereType<Map>()
        .map((item) => SmartHomeModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<SmartHomeModel> createHome(
    String name, {
    String type = 'home',
    int? userId,
  }) async {
    final response = await _api.post(
      EndPoints.smartHomes,
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        'name': name,
        'type': type,
        'is_default': true,
      },
    );
    return SmartHomeModel.fromJson(
      Map<String, dynamic>.from(response.data['home'] as Map),
    );
  }

  Future<SmartHomeModel> updateHome({
    required int id,
    String? name,
    String? type,
    bool? isDefault,
    int? userId,
  }) async {
    final response = await _api.put(
      EndPoints.smartHome(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (isDefault != null) 'is_default': isDefault,
      },
    );
    return SmartHomeModel.fromJson(
      Map<String, dynamic>.from(response.data['home'] as Map),
    );
  }

  Future<void> deleteHome({required int id, int? userId}) async {
    await _api.delete(
      EndPoints.smartHome(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<SmartHomeModel> updateHomeTuyaId({
    required int homeId,
    required String tuyaHomeId,
    int? userId,
  }) async {
    final response = await _api.put(
      EndPoints.smartHome(homeId),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        'tuya_home_id': tuyaHomeId,
      },
    );
    return SmartHomeModel.fromJson(
      Map<String, dynamic>.from(response.data['home'] as Map),
    );
  }

  Future<List<SmartRoomModel>> getRooms(int homeId, {int? userId}) async {
    final response = await _api.get(
      EndPoints.smartHomeRooms(homeId),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
    return _extractList(response.data, const ['rooms'])
        .whereType<Map>()
        .map((item) => SmartRoomModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<SmartRoomModel> createRoom({
    required int homeId,
    required String name,
    int? userId,
  }) async {
    final response = await _api.post(
      EndPoints.smartHomeRooms(homeId),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {'name': name},
    );
    return SmartRoomModel.fromJson(
      Map<String, dynamic>.from(response.data['room'] as Map),
    );
  }

  Future<SmartRoomModel> updateRoom({
    required int id,
    required String name,
    int? userId,
  }) async {
    final response = await _api.put(
      EndPoints.smartRoom(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {'name': name},
    );
    return SmartRoomModel.fromJson(
      Map<String, dynamic>.from(response.data['room'] as Map),
    );
  }

  Future<void> deleteRoom({required int id, int? userId}) async {
    await _api.delete(
      EndPoints.smartRoom(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<List<SmartDeviceModel>> getDevices({
    int? homeId,
    bool unassigned = false,
    int? userId,
  }) async {
    final response = await _api.get(
      EndPoints.smartDevices,
      queryParameters: {
        if (unassigned)
          'home_id': 'unassigned'
        else if (homeId != null)
          'home_id': homeId,
        if (userId != null) 'user_id': userId,
        'include_debug': true,
      },
    );
    return _extractList(response.data, const ['devices', 'data'])
        .whereType<Map>()
        .map((item) =>
            SmartDeviceModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<SmartDeviceModel> getDevice(int id, {int? userId}) async {
    final response = await _api.get(
      EndPoints.smartDevice(id),
      queryParameters: {
        'include_debug': true,
        if (userId != null) 'user_id': userId,
      },
    );
    return SmartDeviceModel.fromJson(
      Map<String, dynamic>.from(response.data['device'] as Map),
    );
  }

  Future<SmartDeviceModel> renameDevice({
    required int id,
    required String name,
    int? userId,
  }) async {
    final response = await _api.patch(
      EndPoints.smartDevice(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        'name': name,
      },
    );
    return SmartDeviceModel.fromJson(
      Map<String, dynamic>.from(response.data['device'] as Map),
    );
  }

  Future<SmartDeviceModel> updateDeviceFunction({
    required int deviceId,
    required int functionId,
    String? displayName,
    int? sortOrder,
    bool? isVisible,
    int? userId,
  }) async {
    final response = await _api.patch(
      EndPoints.smartDeviceFunction(deviceId, functionId),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        if (displayName != null) 'display_name': displayName,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (isVisible != null) 'is_visible': isVisible,
      },
    );
    return SmartDeviceModel.fromJson(
      Map<String, dynamic>.from(response.data['device'] as Map),
    );
  }

  Future<List<SmartDeviceFunctionModel>> getDeviceFunctions({
    required int deviceId,
    int? userId,
  }) async {
    final response = await _api.get(
      EndPoints.smartDeviceFunctions(deviceId),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
    return _extractList(response.data, const ['functions'])
        .whereType<Map>()
        .map((item) =>
            SmartDeviceFunctionModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0 && item.code.isNotEmpty)
        .toList(growable: false);
  }

  Future<SmartDeviceModel> moveDevice({
    required int id,
    int? smartHomeId,
    int? smartRoomId,
    int? userId,
  }) async {
    final response = await _api.patch(
      EndPoints.smartDeviceLocation(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        'smart_home_id': smartHomeId,
        'smart_room_id': smartRoomId,
      },
    );
    return SmartDeviceModel.fromJson(
      Map<String, dynamic>.from(response.data['device'] as Map),
    );
  }

  Future<void> deleteDevice({
    required int id,
    int? userId,
  }) async {
    await _api.delete(
      EndPoints.smartDevice(id),
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<SmartDeviceModel> updateDeviceStatus({
    required int id,
    required bool online,
    required Map<String, dynamic> lastStatus,
    Map<String, dynamic>? rawMetadata,
    int? userId,
  }) async {
    final response = await _api.post(
      EndPoints.smartDeviceStatus(id),
      queryParameters: {
        'include_debug': true,
        if (userId != null) 'user_id': userId,
      },
      data: {
        'online': online,
        'last_status': lastStatus,
        if (rawMetadata != null) 'raw_metadata': rawMetadata,
      },
    );
    return SmartDeviceModel.fromJson(
      Map<String, dynamic>.from(response.data['device'] as Map),
    );
  }

  Future<SmartDeviceModel?> storeControlLog({
    required int id,
    required String commandCode,
    required Map<String, dynamic> commandValue,
    required bool success,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? lastStatus,
    bool? online,
    int? userId,
  }) async {
    final response = await _api.post(
      EndPoints.smartDeviceControlLog(id),
      queryParameters: {
        'include_debug': true,
        if (userId != null) 'user_id': userId,
      },
      data: {
        'command_code': commandCode,
        'command_value': commandValue,
        'success': success,
        if (errorCode != null && errorCode.isNotEmpty) 'error_code': errorCode,
        if (errorMessage != null && errorMessage.isNotEmpty)
          'error_message': errorMessage,
        if (lastStatus != null) 'last_status': lastStatus,
        if (online != null) 'online': online,
      },
    );
    final rawDevice = response.data['device'];
    if (rawDevice is! Map) return null;
    return SmartDeviceModel.fromJson(Map<String, dynamic>.from(rawDevice));
  }

  Future<SmartDeviceModel> registerDevice({
    required int smartHomeId,
    int? smartRoomId,
    required Map<String, dynamic> device,
    int? userId,
  }) async {
    final response = await _api.post(
      EndPoints.smartDevicesRegister,
      queryParameters: {
        if (userId != null) 'user_id': userId,
      },
      data: {
        'smart_home_id': smartHomeId,
        if (smartRoomId != null) 'smart_room_id': smartRoomId,
        'tuya_device_id': device['tuya_device_id']?.toString() ?? '',
        'tuya_product_id': device['tuya_product_id']?.toString(),
        'tuya_uuid': device['tuya_uuid']?.toString(),
        'name': device['name']?.toString().isNotEmpty == true
            ? device['name'].toString()
            : 'smartDevice'.tr,
        'category': device['category']?.toString(),
        'product_name': device['product_name']?.toString(),
        'icon': device['icon']?.toString(),
        'protocol': device['protocol']?.toString() ?? 'wifi',
        'online': device['online'] == true,
        'raw_metadata': device,
        'last_status': device['last_status'] is Map
            ? Map<String, dynamic>.from(device['last_status'] as Map)
            : <String, dynamic>{},
      },
    );
    return SmartDeviceModel.fromJson(
      Map<String, dynamic>.from(response.data['device'] as Map),
    );
  }

  List<dynamic> _extractList(dynamic data, List<String> path) {
    dynamic current = data;
    for (final key in path) {
      if (current is Map) {
        current = current[key];
      } else {
        return const [];
      }
    }
    if (current is List) return current;
    return const [];
  }
}
