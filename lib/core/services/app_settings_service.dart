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
  static const _salesVarianceCacheKey =
      'app_settings_sales_daily_variance_alert_threshold';
  static const _salesMaxFloatCacheKey = 'app_settings_sales_daily_max_float';
  static const defaultAdminFabOptions = <String>{
    'newInvoice',
    'newEmployee',
    'newExpense',
    'newCustomer',
  };
  static const allAdminFabOptions = <String>{
    ...defaultAdminFabOptions,
    'createNewEmployeeTask',
    'addNewPrivateTask',
    'newSalesInvoice',
    'newCashProfit',
    'newMaintenance',
    'newFollowUp',
    'newProduct',
  };

  final RxInt subtaskBonusDefault = 5.obs;
  final RxSet<String> adminFabOptions = <String>{...defaultAdminFabOptions}.obs;
  final RxDouble salesDailyVarianceAlertThreshold = 50.0.obs;
  final RxMap<String, double> salesDailyMaxFloat = <String, double>{
    'شيكل': 500,
    'دولار': 200,
    'دينار': 200,
  }.obs;
  final RxBool shiplyEnabled = true.obs;
  final RxBool shiplyIsTestMode = true.obs;
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
    final cachedVariance = FinalClasses.getStorage.read(_salesVarianceCacheKey);
    if (cachedVariance != null) {
      final v = double.tryParse(cachedVariance.toString());
      if (v != null && v >= 0) salesDailyVarianceAlertThreshold.value = v;
    }
    final cachedMaxFloat = FinalClasses.getStorage.read(_salesMaxFloatCacheKey);
    if (cachedMaxFloat is Map) {
      _applyMaxFloatMap(cachedMaxFloat);
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
          final variance = double.tryParse(
            settings['sales_daily_variance_alert_threshold']?.toString() ?? '',
          );
          if (variance != null && variance >= 0) {
            salesDailyVarianceAlertThreshold.value = variance;
            await FinalClasses.getStorage.write(
              _salesVarianceCacheKey,
              variance,
            );
          }
          final maxFloat = settings['sales_daily_max_float'];
          if (maxFloat is Map) {
            _applyMaxFloatMap(maxFloat);
            await FinalClasses.getStorage
                .write(_salesMaxFloatCacheKey, maxFloat);
          }
          final shiply = settings['shiply'];
          if (shiply is Map) {
            shiplyEnabled.value = shiply['shiply_enabled'] == true;
            shiplyIsTestMode.value = shiply['shiply_is_test'] != false &&
                (shiply['shiply_mode']?.toString() != 'live');
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

  Future<bool> updateSalesDailySettings({
    required double varianceAlertThreshold,
    required Map<String, double> maxFloat,
  }) async {
    final api = _api;
    if (api == null) return false;

    try {
      final response = await api.put(
        EndPoints.appSettings,
        data: {
          'employee_task_subtask_bonus_default': subtaskBonusDefault.value,
          'sales_daily_variance_alert_threshold': varianceAlertThreshold,
          'sales_daily_max_float': maxFloat,
        },
      );
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        salesDailyVarianceAlertThreshold.value = varianceAlertThreshold;
        salesDailyMaxFloat.assignAll(maxFloat);
        await FinalClasses.getStorage.write(
          _salesVarianceCacheKey,
          varianceAlertThreshold,
        );
        await FinalClasses.getStorage.write(_salesMaxFloatCacheKey, maxFloat);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateShiplySettings({
    required bool enabled,
    required bool testMode,
  }) async {
    final api = _api;
    if (api == null) return false;

    try {
      final response = await api.put(
        EndPoints.appSettings,
        data: {
          'shiply': {
            'shiply_enabled': enabled,
            'shiply_mode': testMode ? 'test' : 'live',
          },
        },
      );
      final data = _responseData(response);
      if (data is Map && data['status']?.toString() == 'success') {
        shiplyEnabled.value = enabled;
        shiplyIsTestMode.value = testMode;
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _applyMaxFloatMap(Map<dynamic, dynamic> raw) {
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = double.tryParse(entry.value.toString());
      if (value != null && value >= 0) {
        salesDailyMaxFloat[key] = value;
      }
    }
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
