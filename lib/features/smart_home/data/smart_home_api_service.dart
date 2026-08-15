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

class SmartHomeModel {
  final int id;
  final String name;
  final String tuyaHomeId;
  final String status;
  final bool isDefault;
  final int devicesCount;
  final int onlineDevicesCount;
  final int offlineDevicesCount;

  const SmartHomeModel({
    required this.id,
    required this.name,
    required this.tuyaHomeId,
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

class SmartDeviceModel {
  final int id;
  final int smartHomeId;
  final int? smartRoomId;
  final String name;
  final String category;
  final String productName;
  final String protocol;
  final bool online;
  final Map<String, dynamic> lastStatus;

  const SmartDeviceModel({
    required this.id,
    required this.smartHomeId,
    required this.smartRoomId,
    required this.name,
    required this.category,
    required this.productName,
    required this.protocol,
    required this.online,
    required this.lastStatus,
  });

  factory SmartDeviceModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['last_status'];
    return SmartDeviceModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      smartHomeId: int.tryParse(json['smart_home_id']?.toString() ?? '') ?? 0,
      smartRoomId: int.tryParse(json['smart_room_id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      protocol: json['protocol']?.toString() ?? '',
      online: json['online'] == true,
      lastStatus: rawStatus is Map
          ? Map<String, dynamic>.from(rawStatus)
          : const <String, dynamic>{},
    );
  }
}

class SmartHomeApiService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<SmartHomeTuyaUserModel> getTuyaUser() async {
    final response = await _api.get(EndPoints.smartTuyaUser);
    return SmartHomeTuyaUserModel.fromJson(
      Map<String, dynamic>.from(response.data['tuya_user'] as Map),
    );
  }

  Future<SmartHomeTuyaUserModel> updateTuyaUser({
    required String tuyaUid,
    String? region,
    Map<String, dynamic>? rawMetadata,
  }) async {
    final response = await _api.put(EndPoints.smartTuyaUser, data: {
      'tuya_uid': tuyaUid,
      if (region != null && region.isNotEmpty) 'region': region,
      if (rawMetadata != null) 'raw_metadata': rawMetadata,
    });
    return SmartHomeTuyaUserModel.fromJson(
      Map<String, dynamic>.from(response.data['tuya_user'] as Map),
    );
  }

  Future<List<SmartHomeModel>> getHomes() async {
    final response = await _api.get(EndPoints.smartHomes);
    return _extractList(response.data, const ['homes'])
        .whereType<Map>()
        .map((item) => SmartHomeModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<SmartHomeModel> createHome(String name) async {
    final response = await _api.post(EndPoints.smartHomes, data: {
      'name': name,
      'is_default': true,
    });
    return SmartHomeModel.fromJson(
      Map<String, dynamic>.from(response.data['home'] as Map),
    );
  }

  Future<SmartHomeModel> updateHomeTuyaId({
    required int homeId,
    required String tuyaHomeId,
  }) async {
    final response = await _api.put(EndPoints.smartHome(homeId), data: {
      'tuya_home_id': tuyaHomeId,
    });
    return SmartHomeModel.fromJson(
      Map<String, dynamic>.from(response.data['home'] as Map),
    );
  }

  Future<List<SmartRoomModel>> getRooms(int homeId) async {
    final response = await _api.get(EndPoints.smartHomeRooms(homeId));
    return _extractList(response.data, const ['rooms'])
        .whereType<Map>()
        .map((item) => SmartRoomModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<List<SmartDeviceModel>> getDevices({int? homeId}) async {
    final response = await _api.get(
      EndPoints.smartDevices,
      queryParameters: {
        if (homeId != null) 'home_id': homeId,
      },
    );
    return _extractList(response.data, const ['devices', 'data'])
        .whereType<Map>()
        .map((item) =>
            SmartDeviceModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<SmartDeviceModel> registerDevice({
    required int smartHomeId,
    int? smartRoomId,
    required Map<String, dynamic> device,
  }) async {
    final response = await _api.post(EndPoints.smartDevicesRegister, data: {
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
    });
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
