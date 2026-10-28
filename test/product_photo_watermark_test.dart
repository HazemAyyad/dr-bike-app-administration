import 'dart:io';

import 'package:doctorbike/core/media/product_photo_watermark.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/product_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'captured photo contains real logo in bottom right with unchanged center',
      () async {
    final source = img.Image(width: 1000, height: 800);
    img.fill(source, color: img.ColorRgb8(40, 60, 80));
    final bytes = Uint8List.fromList(img.encodePng(source));
    final logo =
        await rootBundle.load('assets/images/product_camera_watermark.png');
    final result = renderProductPhotoWatermark({
      'photo': bytes,
      'logo': logo.buffer.asUint8List(logo.offsetInBytes, logo.lengthInBytes),
    });
    final photo = img.decodeJpg(result)!;
    expect(photo.width, 1000);
    expect(photo.height, 800);
    expect(photo.getPixel(500, 400).r, closeTo(40, 3));
    expect(photo.getPixel(500, 400).g, closeTo(60, 3));
    expect(photo.getPixel(850, 644).r, closeTo(40, 5));
    var changedPixels = 0;
    for (var y = 640; y < 784; y++) {
      for (var x = 848; x < 984; x++) {
        if ((photo.getPixel(x, y).r - 40).abs() > 15) changedPixels++;
      }
    }
    expect(changedPixels, greaterThan(1000));
    // Margin remains outside the watermark and the input was not modified.
    expect(photo.getPixel(990, 790).r, closeTo(40, 5));
    expect(img.decodePng(bytes)!.getPixel(850, 644).r, 40);
    final dir = Directory('build/stock_camera_preview')
      ..createSync(recursive: true);
    File('${dir.path}/watermark.jpg').writeAsBytesSync(result);
  });

  test('portrait camera orientation is baked before positioning watermark',
      () async {
    final source = img.Image(width: 600, height: 400);
    img.fill(source, color: img.ColorRgb8(30, 70, 100));
    source.exif.imageIfd.orientation = 6;
    final logo =
        await rootBundle.load('assets/images/product_camera_watermark.png');
    final result = renderProductPhotoWatermark({
      'photo': Uint8List.fromList(img.encodeJpg(source)),
      'logo': logo.buffer.asUint8List(logo.offsetInBytes, logo.lengthInBytes),
    });
    final photo = img.decodeJpg(result)!;
    expect(photo.width, 400);
    expect(photo.height, 600);
    expect(photo.exif.imageIfd.orientation, anyOf(isNull, 1));
  });

  test('transparent logo preserves a light photo around and inside its bounds',
      () async {
    final source = img.Image(width: 1000, height: 800);
    img.fill(source, color: img.ColorRgb8(240, 235, 225));
    final logo =
        await rootBundle.load('assets/images/product_camera_watermark.png');
    final result = renderProductPhotoWatermark({
      'photo': Uint8List.fromList(img.encodePng(source)),
      'logo': logo.buffer.asUint8List(logo.offsetInBytes, logo.lengthInBytes),
    });
    final photo = img.decodeJpg(result)!;
    // This point lies inside the logo rectangle but outside its visible pixels.
    final transparentCorner = photo.getPixel(850, 644);
    expect(transparentCorner.r, closeTo(240, 5));
    expect(transparentCorner.g, closeTo(235, 5));
    expect(transparentCorner.b, closeTo(225, 5));
    expect(photo.getPixel(990, 790).r, closeTo(240, 5));
    var darkPixels = 0;
    for (var y = 640; y < 784; y++) {
      for (var x = 848; x < 984; x++) {
        if (photo.getPixel(x, y).r < 180) darkPixels++;
      }
    }
    expect(darkPixels, greaterThan(1000));
    File('build/stock_camera_preview/watermark_light.jpg')
        .writeAsBytesSync(result);
  });

  test('invalid image is rejected instead of uploading an unmarked capture',
      () {
    expect(
        () => renderProductPhotoWatermark({
              'photo': Uint8List.fromList([0, 1, 2]),
              'logo': Uint8List.fromList([0]),
            }),
        throwsFormatException);
  });

  for (final source in ProductPhotoSource.values) {
    final label = source == ProductPhotoSource.camera ? 'camera' : 'gallery';
    testWidgets('product image source sheet offers $label', (tester) async {
      ProductPhotoSource? selected;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              selected = await showProductPhotoSourceSheet(context);
            },
            child: const Text('open')),
      ))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('الكاميرا'), findsOneWidget);
      expect(find.text('المعرض'), findsOneWidget);
      await tester.tap(find
          .text(source == ProductPhotoSource.camera ? 'الكاميرا' : 'المعرض'));
      await tester.pumpAndSettle();
      expect(selected, source);
      expect(find.byType(BottomSheet), findsNothing);
    });
  }
}
