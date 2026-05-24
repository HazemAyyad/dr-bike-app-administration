import 'package:get/get.dart';

import '../databases/api/api_consumer.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import 'final_classes.dart';

/// Cached app-wide settings from the API (e.g. default subtask bonus points).
class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _cacheKey = 'app_settings_subtask_bonus_default';

  final RxInt subtaskBonusDefault = 5.obs;
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

    final api = _api;
    if (api == null) {
      _loaded = true;
      return;
    }

    try {
      final response = await api.get(EndPoints.appSettings);
      final data = response;
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
      final data = response;
      if (data is Map && data['status']?.toString() == 'success') {
        subtaskBonusDefault.value = value;
        await FinalClasses.getStorage.write(_cacheKey, value);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
