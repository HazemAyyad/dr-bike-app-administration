import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, Response;

import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';

class AdminNotificationSettingsApiService {
  DioConsumer get _api => Get.find<DioConsumer>();

  Future<List<Map<String, dynamic>>> fetchCatalog() async {
    final res = await _api.get(EndPoints.adminNotificationCatalog);
    return _listFrom(res.data, 'types');
  }

  Future<List<Map<String, dynamic>>> fetchSounds() async {
    final res = await _api.get(EndPoints.adminNotificationSounds);
    return _listFrom(res.data, 'sounds');
  }

  Future<List<Map<String, dynamic>>> fetchTemplates() async {
    final res = await _api.get(EndPoints.adminNotificationTemplates);
    return _listFrom(res.data, 'templates');
  }

  Future<List<Map<String, dynamic>>> fetchDevices() async {
    final res = await _api.get(EndPoints.adminNotificationDevices);
    return _listFrom(res.data, 'devices');
  }

  Future<List<Map<String, dynamic>>> fetchDeliveries() async {
    final res = await _api.get(EndPoints.adminNotificationDeliveries);
    final data = res.data;
    if (data is Map && data['deliveries'] is Map) {
      return _listFrom(data['deliveries'], 'data');
    }
    return const [];
  }

  Future<Map<String, dynamic>> updatePolicy(
    String type,
    Map<String, dynamic> values,
  ) async {
    final res = await _api.put(
      EndPoints.adminNotificationPolicy(type),
      data: values,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> resetPolicy(String type) async {
    await _api.post(EndPoints.adminNotificationPolicyReset(type));
  }

  Future<void> updateTemplate(
    String type,
    Map<String, dynamic> values,
  ) async {
    await _api.put(
      EndPoints.adminNotificationTemplate(type),
      data: values,
    );
  }

  Future<Map<String, dynamic>> uploadSound({
    required String name,
    required String filePath,
    String? category,
    int? fallbackSoundId,
  }) async {
    final res = await _api.post(
      EndPoints.adminNotificationSounds,
      isFormData: true,
      data: {
        'name': name,
        'category': category ?? 'custom',
        if (fallbackSoundId != null) 'fallback_sound_id': fallbackSoundId,
        'file': await MultipartFile.fromFile(filePath),
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> updateSound(int id, Map<String, dynamic> values) async {
    await _api.put('${EndPoints.adminNotificationSounds}/$id', data: values);
  }

  Future<void> deleteSound(int id) async {
    await _api.delete('${EndPoints.adminNotificationSounds}/$id');
  }

  Future<Uint8List> downloadSound(int id) async {
    final res = await _api.get(
      '${EndPoints.adminNotificationSounds}/$id/file',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(List<int>.from(res.data as List));
  }

  static List<Map<String, dynamic>> _listFrom(dynamic raw, String key) {
    if (raw is Map && raw[key] is List) {
      return (raw[key] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}
