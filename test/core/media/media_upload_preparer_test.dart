import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:doctorbike/core/media/media_upload_preparer.dart';
import 'package:doctorbike/core/media/prepared_upload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final originalCompressor = FlutterImageCompressPlatform.instance;

  setUpAll(() {
    FlutterImageCompressPlatform.instance = _FakeImageCompressor();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('doctorbike_media_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async =>
          call.method == 'getTemporaryDirectory' ? directory.path : null,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  tearDownAll(() {
    FlutterImageCompressPlatform.instance = originalCompressor;
  });

  test('JPEG input becomes a safe JPEG upload without upscaling', () async {
    final sourceImage = img.Image(width: 24, height: 12);
    final file = File('${directory.path}/camera.jpeg');
    await file.writeAsBytes(img.encodeJpg(sourceImage));

    final prepared = await MediaUploadPreparer.prepareImageForUpload(
      XFile(file.path),
      profile: const ImageUploadProfile(
        maxBytes: 1024 * 1024,
        quality: 86,
        maxDimension: 1600,
      ),
    );

    final output = img.decodeImage(await File(prepared.path).readAsBytes());
    expect(prepared.filename, endsWith('.jpg'));
    expect(prepared.contentType.toString(), 'image/jpeg');
    expect(prepared.temporary, isTrue);
    expect(output?.width, 24);
    expect(output?.height, 12);
    final multipart = await prepared.toMultipartFile();
    expect(multipart.contentType.toString(), 'image/jpeg');
    expect(await File(prepared.path).exists(), isFalse);
  });

  test('small PNG preserves its bytes, dimensions and transparency format',
      () async {
    final sourceImage = img.Image(width: 18, height: 9, numChannels: 4);
    final bytes = img.encodePng(sourceImage);
    final file = File('${directory.path}/transparent.png');
    await file.writeAsBytes(bytes);

    final prepared = await MediaUploadPreparer.prepareImageForUpload(
      XFile(file.path),
      profile: const ImageUploadProfile(
        maxBytes: 1024 * 1024,
        quality: 86,
        maxDimension: 1600,
      ),
    );

    expect(prepared.path, file.path);
    expect(prepared.filename, endsWith('.png'));
    expect(prepared.contentType.toString(), 'image/png');
    expect(prepared.temporary, isFalse);
    expect(await File(prepared.path).readAsBytes(), bytes);
  });

  test('rejects invalid image bytes', () async {
    final file = File('${directory.path}/broken.jpg');
    await file.writeAsBytes(<int>[1, 2, 3, 4]);

    expect(
      () => MediaUploadPreparer.prepareImageForUpload(XFile(file.path)),
      throwsA(isA<MediaPreparationException>()),
    );
  });

  test('rejects a generated upload over the endpoint size limit', () async {
    final file = File('${directory.path}/large.gif');
    await file.writeAsBytes(<int>[
      ...'GIF89a'.codeUnits,
      ...List<int>.filled(1024, 0),
    ]);

    expect(
      () => MediaUploadPreparer.prepareImageForUpload(
        XFile(file.path),
        profile: const ImageUploadProfile(
          maxBytes: 128,
          quality: 86,
          maxDimension: 1600,
        ),
      ),
      throwsA(isA<MediaPreparationException>()),
    );
  });

  test('dimension fitting never enlarges a small image', () {
    final small = MediaUploadPreparer.fitWithinDimensions(320, 200, 1600);
    final large = MediaUploadPreparer.fitWithinDimensions(4000, 2000, 1600);

    expect(small.width, 320);
    expect(small.height, 200);
    expect(large.width, 1600);
    expect(large.height, 800);
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

class _FakeImageCompressor extends FlutterImageCompressPlatform {
  @override
  FlutterImageCompressValidator get validator => throw UnimplementedError();

  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    final decoded = img.decodeImage(await File(path).readAsBytes());
    if (decoded == null) return null;
    final resized = decoded.width == minWidth && decoded.height == minHeight
        ? decoded
        : img.copyResize(decoded, width: minWidth, height: minHeight);
    final bytes = format == CompressFormat.png
        ? img.encodePng(resized)
        : img.encodeJpg(resized, quality: quality);
    await File(targetPath).writeAsBytes(bytes);
    return XFile(targetPath);
  }

  @override
  Future<Uint8List?> compressAssetImage(
    String assetName, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async =>
      null;

  @override
  Future<Uint8List?> compressWithFile(
    String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async =>
      null;

  @override
  Future<Uint8List> compressWithList(
    Uint8List image, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async =>
      image;

  @override
  void ignoreCheckSupportPlatform(bool value) {}

  @override
  Future<void> showNativeLog(bool value) async {}
}
