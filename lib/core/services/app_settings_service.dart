import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;

import '../databases/api/api_consumer.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import 'final_classes.dart';

/// Cached app-wide settings from the API (e.g. default subtask bonus points).
class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _cacheKey = 'app_settings_subtask_bonus_default';
  static const _fabCacheKey = 'app_settings_admin_fab_options';
  static const defaultAdminFabOptions = <String>{
    'newInvoice',
    'newEmployee',
    'newExpense',
    'newCustomer',
  };
  static const allAdminFabOptions = <String>{
    ...defaultAdminFabOptions,
    'createNewEmployeeTask',
  };

  final RxInt subtaskBonusDefault = 5.obs;
  final RxSet<String> adminFabOptions = <String>{...defaultAdminFabOptions}.obs;
  bool _loaded = false;

  ApiConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  Future<void> ensureLoaded({bool force = false}) async {
    if (_loaded && !force) return;

    final cached = FinalClasses.getStorage.read(_cacheKey);
    if (cached != null) {
      final n = int.tryParse(cached.toString());
      if (n != null && n >= 0) subtaskBonusDefault.value = n;
    }
    final cachedFab = FinalClasses.getStorage.read(_fabCacheKey);
    if (cachedFab != null) {
      adminFabOptions.assignAll(_decodeFabOptions(cachedFab.toString()));
    }

    final api = _api;
    if (api == null) {
      _loaded = true;
      return;
    }

    try {
      final response = await api.get(EndPoints.appSettings);
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        final settings = data['settings'];
        if (settings is Map) {
          final v = int.tryParse(
            settings['employee_task_subtask_bonus_default']?.toString() ?? '',
          );
          if (v != null && v >= 0) {
            subtaskBonusDefault.value = v;
            await FinalClasses.getStorage.write(_cacheKey, v);
          }
          final fabRaw = settings['admin_fab_options']?.toString();
          if (fabRaw != null) {
            final options = _decodeFabOptions(fabRaw);
            adminFabOptions.assignAll(options);
            await FinalClasses.getStorage.write(_fabCacheKey, fabRaw);
          }
        }
      }
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
  }

  Future<bool> updateSubtaskBonusDefault(int value) async {
    final api = _api;
    if (api == null) return false;

    try {
      final response = await api.put(
        EndPoints.appSettings,
        data: {'employee_task_subtask_bonus_default': value},
      );
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        subtaskBonusDefault.value = value;
        await FinalClasses.getStorage.write(_cacheKey, value);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateAdminFabOptions(Set<String> options) async {
    final api = _api;
    if (api == null) return false;

    try {
      final encoded = options.join(',');
      final response = await api.put(
        EndPoints.appSettings,
        data: {
          'employee_task_subtask_bonus_default': subtaskBonusDefault.value,
          'admin_fab_options': encoded,
        },
      );
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        adminFabOptions.assignAll(options);
        await FinalClasses.getStorage.write(_fabCacheKey, encoded);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Set<String> _decodeFabOptions(String raw) {
    final values = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => allAdminFabOptions.contains(e))
        .toSet();
    return values;
  }

  dynamic _responseData(dynamic response) {
    if (response is dio.Response) return response.data;
    return response;
  }
}
