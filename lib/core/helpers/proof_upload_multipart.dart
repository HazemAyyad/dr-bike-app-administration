import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../media/media_upload_preparer.dart';
import 'task_media_paths.dart';

/// Builds multipart proof file: images compressed, videos sent as-is (no re-encode).
Future<MultipartFile> proofFileToMultipart(File file) async {
  if (localFileIsVideo(file.path)) {
    final prepared = await MediaUploadPreparer.prepareVideoForUpload(
      XFile(file.path),
      maxBytes: 50 * 1024 * 1024,
    );
    return prepared.toMultipartFile();
  }
  final prepared = await MediaUploadPreparer.prepareImageForUpload(
    XFile(file.path),
    profile: ImageUploadProfile.general,
  );
  return prepared.toMultipartFile();
}
