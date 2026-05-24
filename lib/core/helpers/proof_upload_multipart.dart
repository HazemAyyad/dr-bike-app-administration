import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../features/admin/checks/data/datasources/checks_datasource.dart';
import 'task_media_paths.dart';

/// Builds multipart proof file: images compressed, videos sent as-is (no re-encode).
Future<MultipartFile> proofFileToMultipart(File file) async {
  final name = p.basename(file.path);
  if (localFileIsVideo(file.path)) {
    return MultipartFile.fromFile(file.path, filename: name);
  }
  final compressed = await compressImage(XFile(file.path));
  return MultipartFile.fromFile(
    compressed.path,
    filename: p.basename(compressed.path),
  );
}
