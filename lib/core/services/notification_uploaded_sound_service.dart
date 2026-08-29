import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:path_provider/path_provider.dart';

import '../databases/api/dio_consumer.dart';

class NotificationUploadedSoundService {
  NotificationUploadedSoundService._();

  static final instance = NotificationUploadedSoundService._();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> playForegroundIfAvailable(Map<String, dynamic> payload) async {
    final url = payload['notification_requested_sound_url']?.toString() ?? '';
    final id = payload['notification_requested_sound_id']?.toString() ?? '';
    final version =
        payload['notification_requested_sound_version']?.toString() ?? '1';
    if (url.isEmpty || id.isEmpty || !Get.isRegistered<DioConsumer>()) {
      return false;
    }

    try {
      final directory = await getApplicationSupportDirectory();
      final soundDirectory = Directory('${directory.path}/notification_sounds');
      if (!await soundDirectory.exists()) {
        await soundDirectory.create(recursive: true);
      }
      final filename =
          payload['notification_requested_sound_filename']?.toString() ?? '';
      final extension = filename.split('.').last.toLowerCase();
      final safeExtension =
          {'wav', 'mp3', 'caf'}.contains(extension) ? extension : 'audio';
      final file =
          File('${soundDirectory.path}/sound_${id}_v$version.$safeExtension');
      if (!await file.exists() || await file.length() == 0) {
        final response = await Get.find<DioConsumer>().get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        await file.writeAsBytes(List<int>.from(response.data as List),
            flush: true);
      }
      await _player.stop();
      await _player.play(DeviceFileSource(file.path));
      return true;
    } catch (_) {
      return false;
    }
  }
}
