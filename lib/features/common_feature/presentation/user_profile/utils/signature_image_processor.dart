import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

Future<Uint8List> processSignatureImage(Uint8List bytes) =>
    compute(_processSignatureImage, bytes);

Uint8List _processSignatureImage(Uint8List bytes) {
  var source = img.decodeImage(bytes);
  if (source == null) throw const FormatException('تعذر قراءة صورة التوقيع');
  if (math.max(source.width, source.height) > 1600) {
    final scale = 1600 / math.max(source.width, source.height);
    source = img.copyResize(
      source,
      width: math.max(1, (source.width * scale).round()),
      height: math.max(1, (source.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  final corners = <img.Pixel>[
    source.getPixel(1, 1),
    source.getPixel(source.width - 2, 1),
    source.getPixel(1, source.height - 2),
    source.getPixel(source.width - 2, source.height - 2),
  ];
  final bgR = corners.fold<double>(0, (sum, p) => sum + p.r) / 4;
  final bgG = corners.fold<double>(0, (sum, p) => sum + p.g) / 4;
  final bgB = corners.fold<double>(0, (sum, p) => sum + p.b) / 4;
  final bgLuma = .299 * bgR + .587 * bgG + .114 * bgB;
  final transparentBackground = corners.where((p) => p.a < 40).length >= 2;
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  var minX = source.width;
  var minY = source.height;
  var maxX = -1;
  var maxY = -1;
  var inkPixels = 0;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      final distance = math.sqrt(
        math.pow(r - bgR, 2) + math.pow(g - bgG, 2) + math.pow(b - bgB, 2),
      );
      final luma = .299 * r + .587 * g + .114 * b;
      final strength = transparentBackground
          ? pixel.a.toDouble()
          : math.max(distance * 3.2, math.max(0, bgLuma - luma) * 4.2);
      if (strength < 34) {
        output.setPixelRgba(x, y, 255, 255, 255, 0);
        continue;
      }
      final alpha = strength.clamp(40, 255).round();
      output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
      inkPixels++;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
  }
  if (inkPixels < 80 || maxX < minX || maxY < minY) {
    throw const FormatException('لم يتم اكتشاف توقيع واضح في الصورة');
  }
  const margin = 18;
  minX = math.max(0, minX - margin);
  minY = math.max(0, minY - margin);
  maxX = math.min(output.width - 1, maxX + margin);
  maxY = math.min(output.height - 1, maxY + margin);
  final cropped = img.copyCrop(
    output,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
  return Uint8List.fromList(img.encodePng(cropped, level: 6));
}
