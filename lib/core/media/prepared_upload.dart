import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class PreparedUpload {
  const PreparedUpload({
    required this.path,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.temporary,
  });

  final String path;
  final String filename;
  final MediaType contentType;
  final int sizeBytes;
  final bool temporary;

  Future<MultipartFile> toMultipartFile() => MultipartFile.fromFile(
        path,
        filename: filename,
        contentType: contentType,
      );

  Future<void> deleteTemporaryCopy() async {
    if (!temporary) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class MediaPreparationException implements Exception {
  const MediaPreparationException(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}
