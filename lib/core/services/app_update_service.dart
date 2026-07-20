import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../databases/api/api_consumer.dart';
import '../databases/api/dio_consumer.dart';
import '../databases/api/end_points.dart';

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  bool _checking = false;
  bool _dialogShown = false;

  ApiConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  Future<void> checkForUpdate({bool force = false}) async {
    if (kIsWeb || (_checking && !force) || (_dialogShown && !force)) {
      return;
    }

    final api = _api;
    if (api == null) {
      return;
    }

    final platform = _currentPlatform();
    if (platform == null) {
      return;
    }

    _checking = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final response = await api.get(
        EndPoints.appUpdateCheck,
        queryParameters: {
          'app': 'admin',
          'platform': platform,
          'current_version': packageInfo.version,
          'current_build': buildNumber,
        },
      ).timeout(const Duration(seconds: 8));
      final data = _responseData(response);
      if (data is! Map || data['status']?.toString() != 'success') {
        return;
      }

      final hasUpdate = data['has_update'] == true;
      final updateUrl = data['url']?.toString().trim() ?? '';
      if (!hasUpdate || updateUrl.isEmpty) {
        return;
      }

      _dialogShown = true;
      await _showUpdateDialog(
        title: data['title']?.toString() ?? 'تحديث جديد متاح',
        message: data['message']?.toString() ??
            'يرجى تحديث التطبيق للحصول على آخر التحسينات.',
        url: updateUrl,
        forceUpdate: data['force_update'] == true,
      );
    } catch (e) {
      debugPrint('[AppUpdate] check failed: $e');
    } finally {
      _checking = false;
    }
  }

  String? _currentPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return null;
  }

  Future<void> _showUpdateDialog({
    required String title,
    required String message,
    required String url,
    required bool forceUpdate,
  }) async {
    if (Get.context == null) {
      _dialogShown = false;
      return;
    }

    await Get.dialog<void>(
      PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          backgroundColor: const Color(0xFFF3F4F6),
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  _dialogShown = false;
                  Get.back<void>();
                },
                child: const Text(
                  'لاحقاً',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onPressed: () => _openUpdateUrl(url),
              child: const Text('تحديث الآن'),
            ),
          ],
        ),
      ),
      barrierDismissible: !forceUpdate,
    );
  }

  Future<void> _openUpdateUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  dynamic _responseData(dynamic response) {
    if (response is dio.Response) return response.data;
    return response;
  }
}
