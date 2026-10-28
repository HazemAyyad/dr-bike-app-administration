import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// The returned copy carries the mark through preview, compression and upload.
Future<XFile> watermarkProductCameraPhoto(String path) async {
  final logo =
      await rootBundle.load('assets/images/product_camera_watermark.png');
  final bytes = await compute(renderProductPhotoWatermark, {
    'photo': await File(path).readAsBytes(),
    'logo': logo.buffer.asUint8List(logo.offsetInBytes, logo.lengthInBytes),
  });
  final dir = await getTemporaryDirectory();
  final output = File(
      '${dir.path}/doctorbike_product_${DateTime.now().microsecondsSinceEpoch}.jpg');
  await output.writeAsBytes(bytes, flush: true);
  return XFile(output.path, mimeType: 'image/jpeg');
}

Uint8List renderProductPhotoWatermark(Map<String, Uint8List> input) {
  img.Image? decoded;
  img.Image? logo;
  try {
    decoded = img.decodeImage(input['photo']!);
    logo = img.decodeImage(input['logo']!);
  } catch (_) {
    throw const FormatException('تعذر قراءة صورة المنتج أو الشعار.');
  }
  if (decoded == null || logo == null) {
    throw const FormatException('تعذر قراءة صورة المنتج أو الشعار.');
  }
  // The supplied transparent logo has wide empty margins. Trim alpha bounds
  // before sizing, while preserving the original brand pixels and transparency.
  var left = logo.width;
  var top = logo.height;
  var right = -1;
  var bottom = -1;
  for (final pixel in logo) {
    if (pixel.a > 0) {
      left = math.min(left, pixel.x);
      right = math.max(right, pixel.x);
      top = math.min(top, pixel.y);
      bottom = math.max(bottom, pixel.y);
    }
  }
  if (right < left || bottom < top) {
    throw const FormatException('ملف الشعار فارغ.');
  }
  logo = img.copyCrop(logo,
      x: left, y: top, width: right - left + 1, height: bottom - top + 1);
  var photo = img.bakeOrientation(decoded);
  if (math.max(photo.width, photo.height) > 2560) {
    photo = img.copyResize(photo,
        width: photo.width >= photo.height ? 2560 : null,
        height: photo.height > photo.width ? 2560 : null,
        interpolation: img.Interpolation.average);
  }
  final shortEdge = math.min(photo.width, photo.height);
  final margin = math.max(1, (shortEdge * 0.02).round());
  final width = math.max(1, (shortEdge * 0.17).round());
  final mark = img.copyResize(logo,
      width: width, interpolation: img.Interpolation.average);
  img.compositeImage(photo, mark,
      dstX: math.max(0, photo.width - mark.width - margin),
      dstY: math.max(0, photo.height - mark.height - margin));
  return Uint8List.fromList(img.encodeJpg(photo, quality: 92));
}
