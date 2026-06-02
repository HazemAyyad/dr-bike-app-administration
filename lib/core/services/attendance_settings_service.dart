import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

import '../databases/api/api_consumer.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';

class AttendanceSettingsService {
  AttendanceSettingsService._();

  static final AttendanceSettingsService instance = AttendanceSettingsService._();

  ApiConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  final RxBool qrEnabled = true.obs;
  final RxBool fingerprintEnabled = false.obs;
  final RxString fingerprintSyncMode = 'disabled'.obs; // disabled|pull|push
  final RxnInt defaultDeviceId = RxnInt();
  final RxInt syncIntervalMinutes = 5.obs;
  final RxBool autoCreateUnknownUsers = false.obs;
  final RxInt deduplicateMinutes = 2.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  bool _loaded = false;

  Future<void> ensureLoaded({bool force = false}) async {
    if (_loaded && !force) return;
    final api = _api;
    if (api == null) {
      _loaded = true;
      return;
    }

    isLoading.value = true;
    try {
      final response = await api.get(EndPoints.attendanceSettings);
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        final s = data['settings'];
        if (s is Map) {
          qrEnabled.value = _asBool(s['attendance_qr_enabled'], true);
          fingerprintEnabled.value =
              _asBool(s['attendance_fingerprint_enabled'], false);
          final mode = (s['fingerprint_sync_mode']?.toString() ?? 'disabled')
              .trim()
              .toLowerCase();
          fingerprintSyncMode.value =
              (mode == 'pull' || mode == 'push') ? mode : 'disabled';
          defaultDeviceId.value = _asNullableInt(s['fingerprint_default_device_id']);
          syncIntervalMinutes.value = _asInt(s['fingerprint_sync_interval_minutes'], 5);
          autoCreateUnknownUsers.value =
              _asBool(s['fingerprint_auto_create_unknown_users'], false);
          deduplicateMinutes.value = _asInt(s['fingerprint_deduplicate_minutes'], 2);
        }
      }
      _loaded = true;
    } catch (_) {
      _loaded = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save() async {
    final api = _api;
    if (api == null) return false;

    isSaving.value = true;
    try {
      final response = await api.post(
        EndPoints.attendanceSettings,
        data: {
          'attendance_qr_enabled': qrEnabled.value,
          'attendance_fingerprint_enabled': fingerprintEnabled.value,
          'fingerprint_sync_mode': fingerprintSyncMode.value,
          'fingerprint_default_device_id': defaultDeviceId.value,
          'fingerprint_sync_interval_minutes': syncIntervalMinutes.value,
          'fingerprint_auto_create_unknown_users': autoCreateUnknownUsers.value,
          'fingerprint_deduplicate_minutes': deduplicateMinutes.value,
        },
      );
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        final s = data['settings'];
        if (s is Map) {
          qrEnabled.value = _asBool(s['attendance_qr_enabled'], qrEnabled.value);
          fingerprintEnabled.value = _asBool(
            s['attendance_fingerprint_enabled'],
            fingerprintEnabled.value,
          );
          final mode = (s['fingerprint_sync_mode']?.toString() ?? 'disabled')
              .trim()
              .toLowerCase();
          fingerprintSyncMode.value =
              (mode == 'pull' || mode == 'push') ? mode : 'disabled';
          defaultDeviceId.value = _asNullableInt(s['fingerprint_default_device_id']);
          syncIntervalMinutes.value = _asInt(
            s['fingerprint_sync_interval_minutes'],
            syncIntervalMinutes.value,
          );
          autoCreateUnknownUsers.value = _asBool(
            s['fingerprint_auto_create_unknown_users'],
            autoCreateUnknownUsers.value,
          );
          deduplicateMinutes.value = _asInt(
            s['fingerprint_deduplicate_minutes'],
            deduplicateMinutes.value,
          );
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  dynamic _responseData(dynamic response) {
    if (response is dio.Response) return response.data;
    return response;
  }

  bool _asBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    final s = v?.toString().trim().toLowerCase();
    if (s == null || s.isEmpty) return fallback;
    return s == '1' || s == 'true' || s == 'yes' || s == 'on';
  }

  int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    final n = int.tryParse(v?.toString() ?? '');
    return n ?? fallback;
  }

  int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    return n;
  }
}

