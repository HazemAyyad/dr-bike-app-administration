import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doctorbike/core/media/media_upload_preparer.dart';
import 'package:doctorbike/core/media/prepared_upload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('doctorbike_media_test_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('rejects a zero-byte document before upload', () async {
    final file = File('${directory.path}/empty.pdf');
    await file.create();

    expect(
      () => MediaUploadPreparer.prepareDocumentForUpload(
        XFile(file.path),
        allowedExtensions: const {'pdf'},
        maxBytes: 1024,
      ),
      throwsA(isA<MediaPreparationException>()),
    );
  });

  test('rejects a document extension not allowed by the endpoint', () async {
    final file = File('${directory.path}/arabic name.exe');
    await file.writeAsBytes(<int>[1, 2, 3]);

    expect(
      () => MediaUploadPreparer.prepareDocumentForUpload(
        XFile(file.path),
        allowedExtensions: const {'pdf', 'docx'},
        maxBytes: 1024,
      ),
      throwsA(isA<MediaPreparationException>()),
    );
  });

  test('document output uses a safe unique name and explicit MIME', () async {
    final file = File('${directory.path}/فاتورة مكررة.pdf');
    await file.writeAsBytes(<int>[37, 80, 68, 70, 45]);

    final prepared = await MediaUploadPreparer.prepareDocumentForUpload(
      XFile(file.path),
      allowedExtensions: const {'pdf'},
      maxBytes: 1024,
    );

    expect(prepared.filename, endsWith('.pdf'));
    expect(prepared.filename, isNot(contains('فاتورة')));
    expect(prepared.contentType.toString(), 'application/pdf');
    expect(prepared.temporary, isFalse);
  });

  test('failed HEIC conversion never returns the unsupported original',
      () async {
    final file = File('${directory.path}/iphone.heic');
    await file.writeAsBytes(<int>[
      0,
      0,
      0,
      24,
      102,
      116,
      121,
      112,
      104,
      101,
      105,
      99,
      0,
      0,
      0,
      0,
    ]);

    expect(
      () => MediaUploadPreparer.prepareImageForUpload(XFile(file.path)),
      throwsA(
        isA<MediaPreparationException>().having(
          (error) => error.userMessage,
          'message',
          contains('HEIC'),
        ),
      ),
    );
  });
}
