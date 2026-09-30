import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import 'prepared_upload.dart';

class ImageUploadProfile {
  const ImageUploadProfile({
    required this.maxBytes,
    required this.quality,
    required this.maxDimension,
  });

  final int maxBytes;
  final int quality;
  final int maxDimension;

  static const profile = ImageUploadProfile(
      maxBytes: 5 * 1024 * 1024, quality: 86, maxDimension: 1600);
  static const check = ImageUploadProfile(
      maxBytes: 8 * 1024 * 1024, quality: 86, maxDimension: 2000);
  static const receipt = ImageUploadProfile(
      maxBytes: 8 * 1024 * 1024, quality: 86, maxDimension: 2000);
  static const social = ImageUploadProfile(
      maxBytes: 16 * 1024 * 1024, quality: 86, maxDimension: 2048);
  static const maintenance = ImageUploadProfile(
      maxBytes: 30 * 1024 * 1024, quality: 86, maxDimension: 2048);
  static const general = ImageUploadProfile(
      maxBytes: 30 * 1024 * 1024, quality: 86, maxDimension: 2048);
  static const salesOrder = ImageUploadProfile(
      maxBytes: 50 * 1024 * 1024, quality: 88, maxDimension: 2560);
  static const attachment = ImageUploadProfile(
      maxBytes: 100 * 1024 * 1024, quality: 88, maxDimension: 2560);
}

class MediaUploadPreparer {
  MediaUploadPreparer._();

  static final Random _random = Random.secure();

  static Future<PreparedUpload> prepareImageForUpload(
    XFile input, {
    ImageUploadProfile profile = ImageUploadProfile.general,
    bool preservePng = true,
  }) async {
    final source = File(input.path);
    await _validateReadable(source);
    final format = await _detectImageFormat(source);
    if (format == null) {
      throw const MediaPreparationException('صيغة الصورة غير مدعومة.');
    }

    final keepPng = preservePng && format == _ImageFormat.png;
    final outputExtension = keepPng ? 'png' : 'jpg';
    final outputMime = keepPng ? 'png' : 'jpeg';
    try {
      final tempPath = await _temporaryPath(outputExtension);
      final result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        tempPath,
        minWidth: profile.maxDimension,
        minHeight: profile.maxDimension,
        quality: keepPng ? 100 : profile.quality,
        format: keepPng ? CompressFormat.png : CompressFormat.jpeg,
        keepExif: false,
      );
      if (result == null) {
        throw const MediaPreparationException('تعذر تجهيز الصورة للرفع.');
      }
      final output = File(result.path);
      await _validateGenerated(output, profile.maxBytes);
      final detected = await _detectImageFormat(output);
      if ((keepPng && detected != _ImageFormat.png) ||
          (!keepPng && detected != _ImageFormat.jpeg)) {
        await _safeDelete(output);
        throw const MediaPreparationException('تعذر التحقق من الصورة المجهزة.');
      }
      return PreparedUpload(
        path: output.path,
        filename: _uniqueName(outputExtension),
        contentType: MediaType('image', outputMime),
        sizeBytes: await output.length(),
        temporary: true,
      );
    } on MediaPreparationException {
      rethrow;
    } catch (error) {
      throw MediaPreparationException(
        format == _ImageFormat.heic
            ? 'تعذر تحويل صورة HEIC/HEIF إلى JPEG.'
            : 'تعذر تجهيز الصورة للرفع.',
        cause: error,
      );
    }
  }

  static Future<PreparedUpload> prepareVideoForUpload(
    XFile input, {
    required int maxBytes,
    bool compressWhenOversize = false,
  }) async {
    var file = File(input.path);
    await _validateReadable(file);
    var extension = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    const allowed = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'avi', 'mkv'};
    if (!allowed.contains(extension)) {
      throw const MediaPreparationException('صيغة الفيديو غير مدعومة.');
    }
    var temporary = false;
    if (await file.length() > maxBytes && compressWhenOversize) {
      final compressed = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (compressed?.file == null) {
        throw const MediaPreparationException('تعذر ضغط الفيديو للرفع.');
      }
      file = compressed!.file!;
      extension = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      temporary = true;
    }
    await _validateGenerated(file, maxBytes);
    return PreparedUpload(
      path: file.path,
      filename: _uniqueName(extension),
      contentType: _videoMime(extension),
      sizeBytes: await file.length(),
      temporary: temporary,
    );
  }

  static Future<PreparedUpload> prepareDocumentForUpload(
    XFile input, {
    required Set<String> allowedExtensions,
    required int maxBytes,
  }) async {
    final file = File(input.path);
    await _validateReadable(file);
    final extension =
        p.extension(file.path).replaceFirst('.', '').toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw const MediaPreparationException('نوع الملف غير مسموح.');
    }
    await _validateGenerated(file, maxBytes);
    return PreparedUpload(
      path: file.path,
      filename: _uniqueName(extension),
      contentType: _documentMime(extension),
      sizeBytes: await file.length(),
      temporary: false,
    );
  }

  static Future<PreparedUpload> prepareAttachmentForUpload(
    XFile input, {
    required Set<String> allowedExtensions,
    required int maxBytes,
  }) async {
    final extension =
        p.extension(input.path).replaceFirst('.', '').toLowerCase();
    if ({'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'}
        .contains(extension)) {
      return prepareImageForUpload(
        input,
        profile: maxBytes <= ImageUploadProfile.social.maxBytes
            ? ImageUploadProfile.social
            : ImageUploadProfile.attachment,
      );
    }
    if ({'mp4', 'mov', 'm4v', '3gp', 'webm', 'avi', 'mkv'}
        .contains(extension)) {
      return prepareVideoForUpload(input, maxBytes: maxBytes);
    }
    return prepareDocumentForUpload(
      input,
      allowedExtensions: allowedExtensions,
      maxBytes: maxBytes,
    );
  }

  static Future<void> _validateReadable(File file) async {
    if (!await file.exists()) {
      throw const MediaPreparationException('تعذر قراءة الملف المختار.');
    }
    if (await file.length() <= 0) {
      throw const MediaPreparationException('الملف المختار فارغ أو تالف.');
    }
  }

  static Future<void> _validateGenerated(File file, int maxBytes) async {
    await _validateReadable(file);
    if (await file.length() > maxBytes) {
      if (file.path.contains('doctorbike_upload_')) await _safeDelete(file);
      throw MediaPreparationException(
        'حجم الملف أكبر من الحد المسموح (${_formatMb(maxBytes)} MB).',
      );
    }
  }

  static Future<_ImageFormat?> _detectImageFormat(File file) async {
    final handle = await file.open();
    try {
      final bytes = await handle.read(16);
      if (bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff) {
        return _ImageFormat.jpeg;
      }
      if (bytes.length >= 8 &&
          _matches(bytes, <int>[137, 80, 78, 71, 13, 10, 26, 10])) {
        return _ImageFormat.png;
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
        return _ImageFormat.webp;
      }
      if (bytes.length >= 6 &&
          String.fromCharCodes(bytes.sublist(0, 3)) == 'GIF') {
        return _ImageFormat.gif;
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
        final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
        if ({'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'}.contains(brand)) {
          return _ImageFormat.heic;
        }
      }
      return null;
    } finally {
      await handle.close();
    }
  }

  static bool _matches(Uint8List bytes, List<int> signature) {
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  static Future<String> _temporaryPath(String extension) async {
    final directory = await getTemporaryDirectory();
    return p.join(directory.path, 'doctorbike_upload_${_token()}.$extension');
  }

  static String _uniqueName(String extension) => '${_token()}.$extension';

  static String _token() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32).toRadixString(16)}';

  static String _formatMb(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(0);

  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static MediaType _videoMime(String extension) {
    switch (extension) {
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'webm':
        return MediaType('video', 'webm');
      case '3gp':
        return MediaType('video', '3gpp');
      case 'avi':
        return MediaType('video', 'x-msvideo');
      case 'mkv':
        return MediaType('video', 'x-matroska');
      default:
        return MediaType('video', 'mp4');
    }
  }

  static MediaType _documentMime(String extension) {
    switch (extension) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'txt':
        return MediaType('text', 'plain');
      case 'zip':
        return MediaType('application', 'zip');
      case 'rar':
        return MediaType('application', 'vnd.rar');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'm4a':
      case 'aac':
        return MediaType('audio', 'mp4');
      case 'ogg':
        return MediaType('audio', 'ogg');
      case 'wav':
        return MediaType('audio', 'wav');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}

enum _ImageFormat { jpeg, png, webp, gif, heic }
