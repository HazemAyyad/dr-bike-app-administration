import 'dart:io';

import 'package:dio/dio.dart';

import 'proof_upload_multipart.dart';

/// Laravel expects `employee_img[]` for multipart proof uploads.
Future<FormData> buildEmployeeProofFormData({
  required Map<String, dynamic> fields,
  required List<File> files,
}) async {
  final formData = FormData.fromMap(fields);
  for (final file in files) {
    formData.files.add(
      MapEntry('employee_img[]', await proofFileToMultipart(file)),
    );
  }
  return formData;
}
