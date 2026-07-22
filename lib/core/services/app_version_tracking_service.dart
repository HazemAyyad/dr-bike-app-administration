import 'dart:math';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';
import 'final_classes.dart';
import 'user_data.dart';

class AppVersionTrackingService with WidgetsBindingObserver {
  AppVersionTrackingService._();

  static final AppVersionTrackingService instance =
      AppVersionTrackingService._();

  static const _deviceKeyStorageKey = 'app_version_device_key';
  static const _minSyncInterval = Duration(minutes: 15);

  bool _observerRegistered = false;
  bool _syncing = false;
  DateTime? _lastSyncAt;

  void start() {
    if (kIsWeb || _observerRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _observerRegistered = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sync(source: 'resume');
    }
  }

  Future<void> sync({required String source, bool force = false}) async {
    if (kIsWeb || _syncing) return;

    final platform = _currentPlatform();
    if (platform == null) return;

    final token = await UserData.getUserToken();
    if (token.isEmpty) return;

    final now = DateTime.now();
    if (!force &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!) < _minSyncInterval) {
      return;
    }

    if (!Get.isRegistered<DioConsumer>()) return;

    _syncing = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final build = int.tryParse(packageInfo.buildNumber) ?? 0;
      final fcmToken =
          FinalClasses.getStorage.read('fcmToken')?.toString().trim() ?? '';

      final response = await Get.find<DioConsumer>().post(
        EndPoints.appVersionSeen,
        data: {
          'app': 'admin',
          'platform': platform,
          'device_key': _deviceKey(),
          'device_name': _deviceName(platform),
          'version': packageInfo.version,
          'build': build,
          if (fcmToken.isNotEmpty && fcmToken != 'no_token')
            'fcm_token': fcmToken,
        },
      ).timeout(const Duration(seconds: 8));

      final data = _responseData(response);
      if (data is Map && data['status'] == 'success') {
        _lastSyncAt = now;
        debugPrint('[AppVersion] sync OK ($source)');
      }
    } catch (e) {
      debugPrint('[AppVersion] sync failed ($source): $e');
    } finally {
      _syncing = false;
    }
  }

  String? _currentPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return null;
  }

  String _deviceName(String platform) =>
      platform == 'android' ? 'Android' : 'iOS';

  String _deviceKey() {
    final existing = FinalClasses.getStorage.read(_deviceKeyStorageKey);
    if (existing != null && existing.toString().trim().isNotEmpty) {
      return existing.toString();
    }

    final random = Random.secure().nextInt(1 << 32);
    final generated =
        '${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}-${random.toRadixString(16)}';
    FinalClasses.getStorage.write(_deviceKeyStorageKey, generated);
    return generated;
  }

  dynamic _responseData(dynamic response) {
    if (response is dio.Response) return response.data;
    return response;
  }
}
