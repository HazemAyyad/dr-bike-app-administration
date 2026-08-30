import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' hide Response;
import 'package:path_provider/path_provider.dart';

import '../databases/api/dio_consumer.dart';
import 'admin_notification_settings_api_service.dart';

class NotificationUploadedSoundService {
  NotificationUploadedSoundService._();

  static final instance = NotificationUploadedSoundService._();
  final AudioPlayer _player = AudioPlayer();

  /// Downloads uploaded sounds to the device and reports the exact background
  /// channel/file readiness to Laravel. Bundled sounds need no download.
  Future<void> syncForAdminDevice({
    required String fcmToken,
    required FlutterLocalNotificationsPlugin notifications,
  }) async {
    if (fcmToken.isEmpty || !Get.isRegistered<DioConsumer>()) return;

    final api = AdminNotificationSettingsApiService();
    final manifest = await api.fetchSoundManifest();
    final rows = <Map<String, dynamic>>[];

    for (final sound in manifest.where((row) => row['source'] == 'uploaded')) {
      final id = int.tryParse('${sound['id']}');
      final version = int.tryParse('${sound['version']}') ?? 1;
      if (id == null) continue;

      String? channelId;
      try {
        final filename = sound['ios_filename']?.toString() ?? '';
        final extension = filename.split('.').last.toLowerCase();
        if (!{'wav', 'mp3', 'caf', 'aiff'}.contains(extension)) {
          throw const FormatException('صيغة الصوت غير مدعومة على الجهاز');
        }
        if (Platform.isIOS && !{'wav', 'caf', 'aiff'}.contains(extension)) {
          throw const FormatException(
            'iOS يدعم WAV وCAF وAIFF كصوت إشعار بالخلفية',
          );
        }

        final file = await _download(
          id: id,
          version: version,
          extension: extension,
          url: sound['download_url']?.toString() ?? '',
          iosFilename: filename,
        );
        await _validateNotificationDuration(file);

        if (Platform.isAndroid) {
          channelId = 'dr_bike_custom_${id}_v$version';
          final soundUri =
              'content://com.application.doctorbike.notification-sounds/${file.uri.pathSegments.last}';
          final android = notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
          await android?.createNotificationChannel(
            AndroidNotificationChannel(
              channelId,
              'صوت مرفوع · ${sound['name'] ?? id}',
              description: 'صوت إشعار مرفوع من مركز تحكم Doctor Bike',
              importance: Importance.max,
              playSound: true,
              sound: UriAndroidNotificationSound(soundUri),
              enableVibration: true,
              showBadge: true,
            ),
          );
          await android?.createNotificationChannel(
            AndroidNotificationChannel(
              '${channelId}_no_vibration',
              'صوت مرفوع · ${sound['name'] ?? id} · بدون اهتزاز',
              description: 'صوت إشعار مرفوع بدون اهتزاز',
              importance: Importance.max,
              playSound: true,
              sound: UriAndroidNotificationSound(soundUri),
              enableVibration: false,
              showBadge: true,
            ),
          );
        }

        rows.add({
          'sound_id': id,
          'version': version,
          'status': 'ready',
          'channel_id': channelId,
        });
      } catch (error) {
        rows.add({
          'sound_id': id,
          'version': version,
          'status': 'failed',
          'channel_id': channelId,
          'error': error.toString(),
        });
      }
    }

    if (rows.isNotEmpty) {
      await api.syncDeviceSounds(fcmToken: fcmToken, sounds: rows);
    }
  }

  Future<bool> playForegroundIfAvailable(Map<String, dynamic> payload) async {
    final url = payload['notification_requested_sound_url']?.toString() ?? '';
    final id = payload['notification_requested_sound_id']?.toString() ?? '';
    final version =
        payload['notification_requested_sound_version']?.toString() ?? '1';
    if (url.isEmpty || id.isEmpty || !Get.isRegistered<DioConsumer>()) {
      return false;
    }

    try {
      final filename =
          payload['notification_requested_sound_filename']?.toString() ?? '';
      final extension = filename.split('.').last.toLowerCase();
      final safeExtension =
          {'wav', 'mp3', 'caf'}.contains(extension) ? extension : 'audio';
      final file = await _download(
        id: int.parse(id),
        version: int.tryParse(version) ?? 1,
        extension: safeExtension,
        url: url,
        iosFilename: filename,
      );
      await _player.stop();
      await _player.play(DeviceFileSource(file.path));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File> _download({
    required int id,
    required int version,
    required String extension,
    required String url,
    required String iosFilename,
  }) async {
    if (url.isEmpty) throw StateError('رابط تحميل الصوت غير متوفر');
    final support = await getApplicationSupportDirectory();
    final directory = Platform.isIOS
        ? Directory('${support.parent.path}/Sounds')
        : Directory('${support.path}/notification_sounds');
    if (!await directory.exists()) await directory.create(recursive: true);
    final safeIosName = iosFilename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final name = Platform.isIOS && safeIosName.isNotEmpty
        ? safeIosName
        : 'sound_${id}_v$version.$extension';
    final file = File('${directory.path}/$name');
    if (!await file.exists() || await file.length() == 0) {
      final response = await Get.find<DioConsumer>().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(
        List<int>.from(response.data as List),
        flush: true,
      );
    }
    return file;
  }

  Future<void> _validateNotificationDuration(File file) async {
    final probe = AudioPlayer();
    try {
      await probe.setSource(DeviceFileSource(file.path));
      final duration = await probe.getDuration();
      if (duration != null && duration > const Duration(seconds: 30)) {
        throw const FormatException('صوت الإشعار يجب ألا يتجاوز 30 ثانية');
      }
    } finally {
      await probe.dispose();
    }
  }
}
