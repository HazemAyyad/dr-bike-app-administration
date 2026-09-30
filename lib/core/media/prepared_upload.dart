import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../errors/error_model.dart';
import '../errors/expentions.dart';

class PreparedUpload {
  PreparedUpload({
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
  Uint8List? _temporaryBytes;

  Future<MultipartFile> toMultipartFile() async {
    if (!temporary) {
      return MultipartFile.fromFile(
        path,
        filename: filename,
        contentType: contentType,
      );
    }

    final file = File(path);
    try {
      _temporaryBytes ??= await file.readAsBytes();
      return MultipartFile.fromBytes(
        _temporaryBytes!,
        filename: filename,
        contentType: contentType,
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> deleteTemporaryCopy() async {
    if (!temporary) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class MediaPreparationException extends ServerException {
  MediaPreparationException(this.userMessage, {this.cause})
      : super(
          ErrorModel(
            status: 422,
            errorMessage: userMessage,
            data: {'message': userMessage},
          ),
        );

  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}
